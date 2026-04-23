from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Optional

from .config import HarnessConfig


class GitError(RuntimeError):
    pass


def _run(cmd: list[str], cwd: Path) -> str:
    result = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)
    if result.returncode != 0:
        raise GitError(f"cmd {' '.join(cmd)} failed in {cwd}: {result.stderr.strip()}")
    return result.stdout.strip()


def ensure_repo(config: HarnessConfig) -> None:
    repo = config.ios_root
    if not (repo / ".git").exists():
        raise GitError(f"ios_root {repo} is not a git repo. Run `git init` there first.")


def create_worktree(config: HarnessConfig, task_id: str, branch: Optional[str] = None) -> Path:
    ensure_repo(config)
    branch = branch or f"feature/{task_id}"
    worktree_path = config.worktree_path(task_id)
    worktree_path.parent.mkdir(parents=True, exist_ok=True)
    if worktree_path.exists():
        return worktree_path
    # Check if branch exists
    existing = _run(["git", "branch", "--list", branch], cwd=config.ios_root)
    if existing:
        _run(["git", "worktree", "add", str(worktree_path), branch], cwd=config.ios_root)
    else:
        _run(
            ["git", "worktree", "add", "-b", branch, str(worktree_path), config.main_branch],
            cwd=config.ios_root,
        )
    return worktree_path


def remove_worktree(config: HarnessConfig, task_id: str, delete_branch: bool = False) -> None:
    ensure_repo(config)
    worktree_path = config.worktree_path(task_id)
    if worktree_path.exists():
        try:
            _run(["git", "worktree", "remove", "--force", str(worktree_path)], cwd=config.ios_root)
        except GitError:
            pass
    if delete_branch:
        branch = f"feature/{task_id}"
        try:
            _run(["git", "branch", "-D", branch], cwd=config.ios_root)
        except GitError:
            pass


def worktree_branch(task_id: str) -> str:
    return f"feature/{task_id}"
