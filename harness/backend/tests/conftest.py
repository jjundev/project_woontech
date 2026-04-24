from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

from backend.config import HarnessConfig


def _init_git_repo(root: Path) -> None:
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    subprocess.run(["git", "-C", str(root), "config", "user.email", "t@t.t"], check=True)
    subprocess.run(["git", "-C", str(root), "config", "user.name", "t"], check=True)
    subprocess.run(["git", "-C", str(root), "add", "."], check=True)
    subprocess.run(["git", "-C", str(root), "commit", "--allow-empty", "-m", "init", "-q"], check=True)
    subprocess.run(["git", "-C", str(root), "branch", "-M", "main"], check=True)


@pytest.fixture
def tmp_config(tmp_path: Path) -> HarnessConfig:
    ios_root = tmp_path / "ios"
    worktrees = ios_root / "worktrees"
    for folder in ("todo", "ongoing", "done"):
        (ios_root / folder).mkdir(parents=True, exist_ok=True)
    worktrees.mkdir(parents=True, exist_ok=True)
    _init_git_repo(ios_root)

    return HarnessConfig(
        ios_root=ios_root,
        worktrees_dir=worktrees,
        build_cmd="echo build",
        unit_test_cmd="echo unit",
        ui_test_cmd="echo ui",
    )


@pytest.fixture
def monorepo_config(tmp_path: Path) -> HarnessConfig:
    repo_root = tmp_path / "repo"
    ios_root = repo_root / "ios"
    worktrees = ios_root / "worktrees"
    for folder in ("todo", "ongoing", "done"):
        (ios_root / folder).mkdir(parents=True, exist_ok=True)
    worktrees.mkdir(parents=True, exist_ok=True)
    (ios_root / "README.md").write_text("# iOS app\n", encoding="utf-8")
    _init_git_repo(repo_root)

    return HarnessConfig(
        ios_root=ios_root,
        worktrees_dir=worktrees,
        build_cmd="echo build",
        unit_test_cmd="echo unit",
        ui_test_cmd="echo ui",
    )
