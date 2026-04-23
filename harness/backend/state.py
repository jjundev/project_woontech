from __future__ import annotations

import json
import shutil
import time
import uuid
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
]

FOLDER_FOR_STATE: dict[str, str] = {
    "todo": "todo",
    "planning": "ongoing",
    "plan_review": "ongoing",
    "implementing": "ongoing",
    "impl_review": "ongoing",
    "publishing": "ongoing",
    "needs_attention": "ongoing",
    "done": "done",
}


@dataclass
class TaskState:
    id: str
    state: StateName = "todo"
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


def new_task_id(title: str) -> str:
    slug = "".join(c if c.isalnum() else "-" for c in title.lower()).strip("-")[:40] or "task"
    return f"{int(time.time())}-{slug}-{uuid.uuid4().hex[:6]}"


def find_task_dir(config: HarnessConfig, task_id: str) -> Path:
    for folder in ("todo", "ongoing", "done"):
        candidate = config.state_dir(folder) / task_id
        if candidate.exists():
            return candidate
    raise FileNotFoundError(f"Task {task_id} not found in any state folder")


def create_task(config: HarnessConfig, title: str) -> TaskState:
    task_id = new_task_id(title)
    task_dir = config.todo_dir / task_id
    task_dir.mkdir(parents=True, exist_ok=False)
    state = TaskState(
        id=task_id,
        state="todo",
        title=title,
        max_plan_retries=config.default_max_plan_retries,
        max_impl_retries=config.default_max_impl_retries,
    )
    write_state(task_dir, state)
    return state


def transition(config: HarnessConfig, task_id: str, new_state: StateName) -> Path:
    """Move task folder to the directory corresponding to new_state and update state.json."""
    current = find_task_dir(config, task_id)
    state = read_state(current)
    target_folder = FOLDER_FOR_STATE[new_state]
    target_dir = config.state_dir(target_folder) / task_id
    if current != target_dir:
        target_dir.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(current), str(target_dir))
    state.state = new_state
    write_state(target_dir, state)
    return target_dir


def list_tasks(config: HarnessConfig) -> list[TaskState]:
    out: list[TaskState] = []
    for folder in ("todo", "ongoing", "done"):
        for task_dir in sorted(config.state_dir(folder).glob("*/")):
            state_file = _state_file(task_dir)
            if state_file.exists():
                try:
                    out.append(read_state(task_dir))
                except Exception:
                    continue
    return out
