from __future__ import annotations

import json
import re
import shutil
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

STATE_FROM_FOLDER: dict[str, StateName] = {
    "todo": "todo",
    "ongoing": "planning",
    "done": "done",
}

TASK_ID_RE = re.compile(r"^[A-Za-z0-9_.-]+$")


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


def find_task_dir(config: HarnessConfig, task_id: str) -> Path:
    for folder in ("todo", "ongoing", "done"):
        candidate = config.state_dir(folder) / task_id
        if candidate.exists():
            return candidate
    raise FileNotFoundError(f"Task {task_id} not found in any state folder")


def scan_task_folders(config: HarnessConfig) -> list[TaskState]:
    """Discover task folders under todo/ongoing/done that contain a spec.md.

    If state.json exists the persisted TaskState is returned; otherwise a
    synthetic TaskState is produced with id=folder_name, title=first H1 of
    spec.md (or folder name), and state derived from the parent folder.
    """
    out: list[TaskState] = []
    for folder in ("todo", "ongoing", "done"):
        root = config.state_dir(folder)
        if not root.exists():
            continue
        for task_dir in sorted(p for p in root.iterdir() if p.is_dir()):
            if not is_valid_task_id(task_dir.name):
                continue
            if not (task_dir / "spec.md").exists():
                continue
            sf = _state_file(task_dir)
            if sf.exists():
                try:
                    out.append(read_state(task_dir))
                    continue
                except Exception:
                    pass
            out.append(
                TaskState(
                    id=task_dir.name,
                    state=STATE_FROM_FOLDER[folder],
                    title=_title_from_spec(task_dir / "spec.md", task_dir.name),
                    max_plan_retries=config.default_max_plan_retries,
                    max_impl_retries=config.default_max_impl_retries,
                )
            )
    return out


def transition(config: HarnessConfig, task_id: str, new_state: StateName) -> Path:
    """Move task folder to the directory corresponding to new_state and update state.json.

    If state.json does not exist yet (task was discovered from a folder with
    only spec.md), it is materialized here using defaults + spec.md H1.
    """
    current = find_task_dir(config, task_id)
    target_folder = FOLDER_FOR_STATE[new_state]
    target_dir = config.state_dir(target_folder) / task_id
    if current != target_dir:
        target_dir.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(current), str(target_dir))

    sf = _state_file(target_dir)
    if sf.exists():
        state = read_state(target_dir)
    else:
        state = TaskState(
            id=task_id,
            state=new_state,
            title=_title_from_spec(target_dir / "spec.md", task_id),
            max_plan_retries=config.default_max_plan_retries,
            max_impl_retries=config.default_max_impl_retries,
        )
    state.state = new_state
    write_state(target_dir, state)
    return target_dir


def list_tasks(config: HarnessConfig) -> list[TaskState]:
    return scan_task_folders(config)
