from __future__ import annotations

import asyncio
from contextlib import asynccontextmanager
from dataclasses import asdict
from typing import Literal, Optional

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from . import state as S
from . import pipeline as P
from . import worktree as W
from .config import load_config
from .events import bus, emit
from .watcher import start_watcher


config = load_config()
_running_pipelines: dict[str, asyncio.Task] = {}
PAUSABLE_STATES = ("planning", "plan_review", "implementing", "impl_review", "publishing")


def _pipeline_is_running(task_id: str) -> bool:
    task = _running_pipelines.get(task_id)
    if task is None:
        return False
    if task.done():
        _running_pipelines.pop(task_id, None)
        return False
    return True


def _launch_pipeline_task(task_id: str, req: "StartPipelineReq") -> asyncio.Task:
    P._acquire_wake_lock()
    task = asyncio.create_task(
        P.run_pipeline(
            config,
            task_id,
            max_plan_retries=req.max_plan_retries,
            max_impl_retries=req.max_impl_retries,
            worktree_base=req.worktree_base or "local",
            resume_from=req.resume_from,
        )
    )
    _running_pipelines[task_id] = task

    def _cleanup(done_task: asyncio.Task) -> None:
        if _running_pipelines.get(task_id) is done_task:
            _running_pipelines.pop(task_id, None)
        P._release_wake_lock()
        try:
            done_task.exception()
        except asyncio.CancelledError:
            pass

    task.add_done_callback(_cleanup)
    return task


@asynccontextmanager
async def lifespan(app: FastAPI):
    loop = asyncio.get_event_loop()
    observer = start_watcher(config, loop)
    try:
        yield
    finally:
        observer.stop()
        observer.join(timeout=3)


app = FastAPI(lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class StartPipelineReq(BaseModel):
    max_plan_retries: Optional[int] = None
    max_impl_retries: Optional[int] = None
    worktree_base: Optional[Literal["local", "remote"]] = "local"
    resume_from: Optional[Literal["impl_review"]] = None


@app.get("/api/tasks")
async def list_tasks():
    return [asdict(s) for s in S.scan_task_folders(config)]


@app.get("/api/tasks/{task_id}")
async def get_task(task_id: str):
    try:
        task_dir = S.find_task_dir(config, task_id)
    except FileNotFoundError:
        raise HTTPException(404, "task not found")
    if (task_dir / "state.json").exists():
        state = S.read_state(task_dir)
    else:
        # Pre-pipeline: only spec.md in ios/todo/<id>/, no state.json yet.
        state = S.TaskState(
            id=task_id,
            state="todo",
            title=S._title_from_spec(task_dir / "spec.md", task_id),
            max_plan_retries=config.default_max_plan_retries,
            max_impl_retries=config.default_max_impl_retries,
        )
    files = sorted(p.name for p in task_dir.iterdir() if p.is_file() and p.name != "state.json")
    return {"state": asdict(state), "files": files, "task_dir": str(task_dir)}


@app.get("/api/tasks/{task_id}/files/{name}")
async def get_task_file(task_id: str, name: str):
    try:
        task_dir = S.find_task_dir(config, task_id)
    except FileNotFoundError:
        raise HTTPException(404, "task not found")
    target = (task_dir / name).resolve()
    # path traversal guard
    if task_dir.resolve() not in target.parents and target != task_dir.resolve() / name:
        raise HTTPException(400, "invalid path")
    if not target.exists():
        raise HTTPException(404, "file not found")
    return {"name": name, "content": target.read_text()}


@app.get("/api/tasks/{task_id}/worktree-status")
async def get_worktree_status(task_id: str):
    try:
        S.find_task_dir(config, task_id)
    except FileNotFoundError:
        raise HTTPException(404, "task not found")
    return W.worktree_status(config, task_id)


@app.get("/api/tasks/{task_id}/worktree-files/{path:path}")
async def get_worktree_file(task_id: str, path: str):
    try:
        S.find_task_dir(config, task_id)
    except FileNotFoundError:
        raise HTTPException(404, "task not found")
    root = W.project_worktree_path(config, task_id).resolve()
    if not root.exists():
        raise HTTPException(404, "worktree not created yet")
    target = (root / path).resolve()
    try:
        target.relative_to(root)
    except ValueError:
        raise HTTPException(400, "invalid path")
    if not target.exists() or not target.is_file():
        raise HTTPException(404, "file not found")
    try:
        return {"path": path, "content": target.read_text()}
    except UnicodeDecodeError:
        raise HTTPException(415, "binary file")


@app.post("/api/tasks/{task_id}/start")
async def start_pipeline(task_id: str, req: StartPipelineReq):
    try:
        task_dir = S.find_task_dir(config, task_id)
    except FileNotFoundError:
        raise HTTPException(404, "task not found")
    if not (task_dir / "spec.md").exists():
        raise HTTPException(400, "spec.md missing — add spec.md to the task folder first")
    if _pipeline_is_running(task_id):
        raise HTTPException(409, "pipeline already running")
    _launch_pipeline_task(task_id, req)
    return {"ok": True}


@app.post("/api/tasks/{task_id}/resume")
async def resume_pipeline(task_id: str, req: StartPipelineReq):
    try:
        task_dir = S.find_task_dir(config, task_id)
    except FileNotFoundError:
        raise HTTPException(404, "task not found")
    state = S.read_state(task_dir)
    if state.state not in ("needs_attention", "paused"):
        raise HTTPException(
            400, f"task is not in needs_attention or paused (current: {state.state})"
        )
    if req.resume_from == "impl_review":
        at_impl = (
            state.state == "impl_review"
            or state.paused_from == "impl_review"
            or (
                state.state == "needs_attention"
                and "impl" in (state.escalation or "").lower()
            )
        )
        if not at_impl:
            raise HTTPException(
                400,
                "resume_from=impl_review requires task to be at impl_review "
                f"(state={state.state}, paused_from={state.paused_from}, escalation={state.escalation})",
            )
        if not W.worktree_is_reusable(config, task_id):
            raise HTTPException(400, "resume_from=impl_review requires an existing reusable worktree")
        if W.worktree_status(config, task_id).get("commits_ahead", 0) <= 0:
            raise HTTPException(
                400,
                "resume_from=impl_review requires the worktree to have commits ahead of main",
            )
    # Preserve the persisted state so the pipeline can choose the correct resume phase.
    if _pipeline_is_running(task_id):
        raise HTTPException(409, "pipeline already running")
    _launch_pipeline_task(task_id, req)
    return {"ok": True}


@app.post("/api/tasks/{task_id}/pause")
async def pause_pipeline(task_id: str):
    try:
        task_dir = S.find_task_dir(config, task_id)
    except FileNotFoundError:
        raise HTTPException(404, "task not found")
    pipeline_task = _running_pipelines.get(task_id)
    if pipeline_task is None or pipeline_task.done():
        raise HTTPException(409, "no running pipeline")
    pipeline_task.cancel()
    try:
        await pipeline_task
    except asyncio.CancelledError:
        pass
    if (task_dir / "state.json").exists():
        st = S.read_state(task_dir)
        if st.state in PAUSABLE_STATES:
            paused_from = st.state
            st.paused_from = paused_from
            st.state = "paused"
            S.write_state(task_dir, st)
            await emit("state_changed", task_id=task_id, state="paused", paused_from=paused_from)
    return {"ok": True}


@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()
    queue = await bus.subscribe()
    try:
        while True:
            event = await queue.get()
            await ws.send_text(event.to_json())
    except WebSocketDisconnect:
        pass
    finally:
        await bus.unsubscribe(queue)


def main() -> None:
    import uvicorn

    uvicorn.run("backend.server:app", host=config.host, port=config.port, reload=False)


if __name__ == "__main__":
    main()
