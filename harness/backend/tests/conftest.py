from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

from backend.config import HarnessConfig


@pytest.fixture
def tmp_config(tmp_path: Path) -> HarnessConfig:
    ios_root = tmp_path / "ios"
    worktrees = ios_root / "worktrees"
    for folder in ("todo", "ongoing", "done"):
        (ios_root / folder).mkdir(parents=True, exist_ok=True)
    worktrees.mkdir(parents=True, exist_ok=True)
    # init git for worktree tests
    subprocess.run(["git", "init", "-q", str(ios_root)], check=True)
    subprocess.run(["git", "-C", str(ios_root), "config", "user.email", "t@t.t"], check=True)
    subprocess.run(["git", "-C", str(ios_root), "config", "user.name", "t"], check=True)
    subprocess.run(["git", "-C", str(ios_root), "commit", "--allow-empty", "-m", "init", "-q"], check=True)
    subprocess.run(["git", "-C", str(ios_root), "branch", "-M", "main"], check=True)

    return HarnessConfig(
        ios_root=ios_root,
        worktrees_dir=worktrees,
        build_cmd="echo build",
        unit_test_cmd="echo unit",
        ui_test_cmd="echo ui",
    )
