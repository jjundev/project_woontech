from __future__ import annotations

import json
import re
import shutil
import subprocess
import time
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Literal, Optional

from .config import HarnessConfig


StateName = Literal[
    "draft",
    "todo",
    "planning",
    "plan_review",
    "implementing",
    "impl_review",
    "publishing",
    "done",
    "needs_attention",
    "paused",
]

# Workspace 내부 상태 폴더: 파이프라인이 워크트리 안에서 task 폴더를 ongoing→done 으로
# 이동시킨다. 루트(ios/ongoing, ios/done)는 더 이상 건드리지 않는다.
WORKSPACE_STATUS_FOR_STATE: dict[str, str] = {
    "planning": "ongoing",
    "plan_review": "ongoing",
    "implementing": "ongoing",
    "impl_review": "ongoing",
    "publishing": "ongoing",
    "needs_attention": "ongoing",
    "paused": "ongoing",
    "done": "done",
}

TASK_ID_RE = re.compile(r"^[A-Za-z0-9_.-]+$")


@dataclass
class TaskState:
    id: str
    state: StateName = "todo"
    paused_from: Optional[StateName] = None
    title: str = ""
    plan_version: int = 0
    impl_version: int = 0
    plan_retries: int = 0
    impl_retries: int = 0
    max_plan_retries: int = 3
    max_impl_retries: int = 3
    escalation: Optional[str] = None
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    branch: Optional[str] = None
    pr_url: Optional[str] = None


def _state_file(task_dir: Path) -> Path:
    return task_dir / "state.json"


def read_state(task_dir: Path) -> TaskState:
    data = json.loads(_state_file(task_dir).read_text())
    return TaskState(**data)


def write_state(task_dir: Path, state: TaskState) -> None:
    state.updated_at = time.time()
    _state_file(task_dir).write_text(json.dumps(asdict(state), indent=2))


def is_valid_task_id(name: str) -> bool:
    return bool(TASK_ID_RE.fullmatch(name))


def _title_from_spec(spec_path: Path, fallback: str) -> str:
    try:
        for line in spec_path.read_text(encoding="utf-8").splitlines():
            s = line.strip()
            if s.startswith("# "):
                return s[2:].strip()
    except OSError:
        pass
    return fallback


# ---------------------------------------------------------------------------
# Workspace paths (inside the worktree)
# ---------------------------------------------------------------------------


def _project_worktree_path(config: HarnessConfig, task_id: str) -> Path:
    """Re-derive the worktree's project root without importing worktree.py (avoids cycles)."""
    from .worktree import project_worktree_path

    return project_worktree_path(config, task_id)


def workspace_path(config: HarnessConfig, task_id: str, *, status: str) -> Path:
    """Return worktrees/<id>/<project>/<status>/<id>/.

    status ∈ {"ongoing", "done"}.
    """
    if status not in ("ongoing", "done"):
        raise ValueError(f"invalid workspace status: {status}")
    return _project_worktree_path(config, task_id) / status / task_id


def find_task_workspace(config: HarnessConfig, task_id: str) -> Optional[Path]:
    """Locate the pipeline workspace for a task, if created.

    Order: ongoing first, then done. Returns None if neither exists.
    """
    for status in ("ongoing", "done"):
        candidate = workspace_path(config, task_id, status=status)
        if candidate.exists():
            return candidate
    return None


def task_input_dir(config: HarnessConfig, task_id: str) -> Path:
    """Root `ios/todo/<id>/` — where the user places spec.md. Never modified by pipeline."""
    return config.todo_dir / task_id


def find_task_dir(config: HarnessConfig, task_id: str) -> Path:
    """Return the workspace if created, else the root todo folder.

    Callers that write/update state should always resolve to the workspace; the
    root todo folder is only for reading `spec.md` before pipeline bootstrap.
    """
    workspace = find_task_workspace(config, task_id)
    if workspace is not None:
        return workspace
    todo = task_input_dir(config, task_id)
    if todo.exists():
        return todo
    raise FileNotFoundError(f"Task {task_id} not found")


# ---------------------------------------------------------------------------
# Workspace bootstrap & transitions
# ---------------------------------------------------------------------------


def _git(args: list[str], cwd: Path) -> None:
    result = subprocess.run(["git", *args], cwd=str(cwd), capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed in {cwd}: {result.stderr.strip()}")


def ensure_workspace(config: HarnessConfig, task_id: str) -> Path:
    """Create workspace at worktrees/<id>/<project>/ongoing/<id>/ if missing.

    Copies `spec.md` from the root todo folder (if present and not already in
    workspace) so the agent can read it without touching the root tree.
    Initial state.json is NOT written here — the pipeline writes it.
    The worktree itself must already exist (created by W.create_worktree).
    """
    ws = workspace_path(config, task_id, status="ongoing")
    done_ws = workspace_path(config, task_id, status="done")
    if done_ws.exists():
        # Already completed — workspace lives under done/.
        return done_ws
    ws.mkdir(parents=True, exist_ok=True)
    spec_src = task_input_dir(config, task_id) / "spec.md"
    spec_dst = ws / "spec.md"
    if spec_src.exists() and not spec_dst.exists():
        shutil.copy2(spec_src, spec_dst)
    return ws


def transition(config: HarnessConfig, task_id: str, new_state: StateName) -> Path:
    """Update the task's state.

    - If no workspace exists yet, bootstrap it (copy spec) under `ongoing/<id>/`
      and persist state.json there.
    - Regular state changes: just overwrite state.json value. No file moves.
    - "done": move `ongoing/<id>/` → `done/<id>/` inside the worktree via
      `git mv` + commit so the transition is captured on the feature branch.

    Returns the workspace directory for `new_state`.
    """
    workspace = find_task_workspace(config, task_id)
    if workspace is None:
        workspace = ensure_workspace(config, task_id)

    sf = _state_file(workspace)
    if sf.exists():
        state = read_state(workspace)
    else:
        spec = workspace / "spec.md"
        state = TaskState(
            id=task_id,
            state=new_state,
            title=_title_from_spec(spec, task_id),
            max_plan_retries=config.default_max_plan_retries,
            max_impl_retries=config.default_max_impl_retries,
        )

    # "done" triggers git mv inside the worktree.
    if new_state == "done":
        target = workspace_path(config, task_id, status="done")
        if workspace != target:
            target.parent.mkdir(parents=True, exist_ok=True)
            _move_ongoing_to_done(config, task_id, workspace, target)
            workspace = target
    if new_state != "paused":
        state.paused_from = None
    state.state = new_state
    write_state(workspace, state)
    return workspace


def _move_ongoing_to_done(config: HarnessConfig, task_id: str, src: Path, dst: Path) -> None:
    """git mv inside the worktree so the rename is tracked on the feature branch."""
    project = _project_worktree_path(config, task_id)
    src_rel = src.relative_to(project)
    dst_rel = dst.relative_to(project)
    try:
        _git(["mv", str(src_rel), str(dst_rel)], cwd=project)
        _git(["commit", "-m", f"Move {task_id} to done", "--allow-empty"], cwd=project)
    except RuntimeError:
        # Fall back to a plain move + best-effort commit so tests without a
        # real git worktree still work.
        if src.exists() and not dst.exists():
            shutil.move(str(src), str(dst))


# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------


def scan_task_folders(config: HarnessConfig) -> list[TaskState]:
    """Discover tasks by scanning `ios/todo/<id>/spec.md`.

    For each task, the current progress is read from workspace state.json if
    a workspace exists; otherwise the task is reported as "todo".
    """
    out: list[TaskState] = []
    root = config.todo_dir
    if not root.exists():
        return out
    for task_dir in sorted(p for p in root.iterdir() if p.is_dir()):
        if not is_valid_task_id(task_dir.name):
            continue
        spec = task_dir / "spec.md"
        if not spec.exists():
            continue
        task_id = task_dir.name
        workspace = find_task_workspace(config, task_id)
        if workspace is not None and _state_file(workspace).exists():
            try:
                out.append(read_state(workspace))
                continue
            except Exception:
                pass
        out.append(
            TaskState(
                id=task_id,
                state="todo",
                title=_title_from_spec(spec, task_id),
                max_plan_retries=config.default_max_plan_retries,
                max_impl_retries=config.default_max_impl_retries,
            )
        )
    return out


def list_tasks(config: HarnessConfig) -> list[TaskState]:
    return scan_task_folders(config)
