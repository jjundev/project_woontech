from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import os
import yaml


DEFAULT_CONFIG_PATH = Path(__file__).resolve().parent.parent / "harness.config.yaml"


@dataclass
class HarnessConfig:
    ios_root: Path
    worktrees_dir: Path
    build_cmd: str
    unit_test_cmd: str
    ui_test_cmd: str
    default_max_plan_retries: int = 3
    default_max_impl_retries: int = 3
    github_repo: Optional[str] = None
    main_branch: str = "main"
    host: str = "127.0.0.1"
    port: int = 8765
    agent_models: dict[str, Optional[str]] = field(default_factory=dict)
    always_ui_test_classes: list[str] = field(default_factory=list)

    @property
    def todo_dir(self) -> Path:
        return self.ios_root / "todo"

    @property
    def ongoing_dir(self) -> Path:
        return self.ios_root / "ongoing"

    @property
    def done_dir(self) -> Path:
        return self.ios_root / "done"

    def state_dir(self, state: str) -> Path:
        mapping = {
            "todo": self.todo_dir,
            "ongoing": self.ongoing_dir,
            "done": self.done_dir,
        }
        if state not in mapping:
            raise ValueError(f"Unknown state folder: {state}")
        return mapping[state]

    def worktree_path(self, task_id: str) -> Path:
        return self.worktrees_dir / task_id


def load_config(path: Optional[Path] = None) -> HarnessConfig:
    path = path or Path(os.environ.get("HARNESS_CONFIG", str(DEFAULT_CONFIG_PATH)))
    if not path.exists():
        raise FileNotFoundError(f"Harness config not found at {path}")
    data = yaml.safe_load(path.read_text())

    base = path.parent
    ios_root = (base / data["ios_root"]).resolve()
    worktrees_dir = (base / data.get("worktrees_dir", f"{data['ios_root']}/worktrees")).resolve()

    agents_raw = data.get("agents") or {}
    agent_models: dict[str, Optional[str]] = {}
    for name, entry in agents_raw.items():
        if entry is None:
            agent_models[name] = None
        elif isinstance(entry, dict):
            agent_models[name] = entry.get("model")
        else:
            raise ValueError(f"agents.{name} must be a mapping, got {type(entry).__name__}")

    always_ui_raw = data.get("always_ui_test_classes") or []
    if not isinstance(always_ui_raw, list) or not all(isinstance(item, str) for item in always_ui_raw):
        raise ValueError("always_ui_test_classes must be a list of strings")
    always_ui_test_classes = list(always_ui_raw)

    return HarnessConfig(
        ios_root=ios_root,
        worktrees_dir=worktrees_dir,
        build_cmd=data["build_cmd"],
        unit_test_cmd=data["unit_test_cmd"],
        ui_test_cmd=data["ui_test_cmd"],
        default_max_plan_retries=data.get("default_max_plan_retries", 3),
        default_max_impl_retries=data.get("default_max_impl_retries", 3),
        github_repo=data.get("github_repo"),
        main_branch=data.get("main_branch", "main"),
        host=data.get("host", "127.0.0.1"),
        port=data.get("port", 8765),
        agent_models=agent_models,
        always_ui_test_classes=always_ui_test_classes,
    )
