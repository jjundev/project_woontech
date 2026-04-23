from __future__ import annotations

import asyncio
import json
from contextlib import asynccontextmanager
from dataclasses import asdict
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from . import state as S
from . import pipeline as P
from .config import load_config
from .events import bus
from .spector_session import registry as spector_registry
from .watcher import start_watcher


config = load_config()
spector_registry.set_config(config)
_running_pipelines: dict[str, asyncio.Task] = {}


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


class CreateTaskReq(BaseModel):
    title: str


class SpectorMessageReq(BaseModel):
    text: str


class StartPipelineReq(BaseModel):
    max_plan_retries: Optional[int] = None
    max_impl_retries: Optional[int] = None


@app.get("/api/tasks")
async def list_tasks():
    return [asdict(s) for s in S.list_tasks(config)]


@app.post("/api/tasks")
async def create_task(req: CreateTaskReq):
    state = S.create_task(config, req.title)
    return asdict(state)


@app.get("/api/tasks/{task_id}")
async def get_task(task_id: str):
    try:
        task_dir = S.find_task_dir(config, task_id)
    except FileNotFoundError:
        raise HTTPException(404, "task not found")
    state = S.read_state(task_dir)
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


@app.post("/api/tasks/{task_id}/spector/message")
async def spector_message(task_id: str, req: SpectorMessageReq):
    try:
        task_dir = S.find_task_dir(config, task_id)
    except FileNotFoundError:
        raise HTTPException(404, "task not found")
    try:
        reply = await spector_registry.send(task_id, task_dir, req.text)
    except asyncio.TimeoutError:
        raise HTTPException(504, "spector timed out — session was reset, please retry")
    except Exception as e:
        raise HTTPException(502, f"spector error: {e or e.__class__.__name__}")
    return {"reply": reply, "confirmed": (task_dir / "spec.md").exists()}


@app.post("/api/tasks/{task_id}/spector/close")
async def spector_close(task_id: str):
    await spector_registry.close(task_id)
    return {"ok": True}


@app.post("/api/tasks/{task_id}/start")
async def start_pipeline(task_id: str, req: StartPipelineReq):
    try:
        task_dir = S.find_task_dir(config, task_id)
    except FileNotFoundError:
        raise HTTPException(404, "task not found")
    if not (task_dir / "spec.md").exists():
        raise HTTPException(400, "spec.md missing — run spector first")
    if task_id in _running_pipelines and not _running_pipelines[task_id].done():
        raise HTTPException(409, "pipeline already running")
    await spector_registry.close(task_id)
    task = asyncio.create_task(
        P.run_pipeline(
            config,
            task_id,
            max_plan_retries=req.max_plan_retries,
            max_impl_retries=req.max_impl_retries,
        )
    )
    _running_pipelines[task_id] = task
    return {"ok": True}


@app.post("/api/tasks/{task_id}/resume")
async def resume_pipeline(task_id: str, req: StartPipelineReq):
    try:
        task_dir = S.find_task_dir(config, task_id)
    except FileNotFoundError:
        raise HTTPException(404, "task not found")
    state = S.read_state(task_dir)
    if state.state != "needs_attention":
        raise HTTPException(400, f"task is not in needs_attention (current: {state.state})")
    # Clear escalation; re-run the appropriate phase. For v1 we re-run the whole pipeline from planning.
    state.escalation = None
    S.write_state(task_dir, state)
    if task_id in _running_pipelines and not _running_pipelines[task_id].done():
        raise HTTPException(409, "pipeline already running")
    task = asyncio.create_task(
        P.run_pipeline(
            config,
            task_id,
            max_plan_retries=req.max_plan_retries,
            max_impl_retries=req.max_impl_retries,
        )
    )
    _running_pipelines[task_id] = task
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
