from __future__ import annotations

import re
import subprocess
from pathlib import Path
from typing import Any, Optional

from claude_agent_sdk import HookMatcher

from .config import HarnessConfig
from .events import emit


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


# ---------------------------------------------------------------------------
# PreToolUse path guard
# ---------------------------------------------------------------------------

ALLOWED_TASK_FILES: set[str] = {
    "implement-plan.md",
    "implement-checklist.md",
    "implement-review.md",
    "pr.md",
}
ALLOWED_TASK_PATTERN = re.compile(r"^(implement|plan)-feedback-version-\d+\.md$")


def _under(target: str, root: Path) -> bool:
    try:
        return Path(target).resolve().is_relative_to(root.resolve())
    except (OSError, ValueError):
        return False


def make_path_guard(
    worktree_dir: Path,
    task_dir: Path,
    *,
    task_id: Optional[str] = None,
) -> dict[str, list[HookMatcher]]:
    """Build a PreToolUse hook that denies Write/Edit outside the worktree.

    Task-folder writes are permitted only for the handful of plan/feedback/review
    markdown files the pipeline expects agents to author.
    """

    async def pre_tool(input: dict[str, Any], tool_use_id: Optional[str], context: Any) -> dict[str, Any]:
        ti = input.get("tool_input") or {}
        fp = ti.get("file_path") or ti.get("notebook_path")
        if not fp:
            return {}
        if _under(fp, worktree_dir):
            return {}
        if _under(fp, task_dir):
            name = Path(fp).name
            if name in ALLOWED_TASK_FILES or ALLOWED_TASK_PATTERN.match(name):
                return {}
        reason = (
            f"Edits restricted to worktree {worktree_dir} "
            f"(or feedback/plan/review markdown in {task_dir}). Got: {fp}"
        )
        await emit(
            "agent_blocked",
            task_id=task_id,
            tool=input.get("tool_name"),
            path=str(fp),
            reason=reason,
        )
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }

    return {
        "PreToolUse": [
            HookMatcher(
                matcher="Write|Edit|MultiEdit|NotebookEdit",
                hooks=[pre_tool],
            )
        ]
    }


# ---------------------------------------------------------------------------
# Worktree status (for real-time monitoring panel)
# ---------------------------------------------------------------------------

_STATUS_CHANGE_MAP = {
    "M": "modified",
    "A": "added",
    "D": "deleted",
    "R": "renamed",
    "C": "copied",
    "U": "unmerged",
    "?": "untracked",
    "!": "ignored",
}


def _parse_status_line(line: str) -> dict[str, str]:
    if not line:
        return {}
    xy = line[:2]
    path = line[3:].strip()
    code = xy.strip()[:1] or " "
    change = _STATUS_CHANGE_MAP.get(code, code)
    return {"path": path, "change": change}


def worktree_status(config: HarnessConfig, task_id: str) -> dict[str, Any]:
    """Return a lightweight summary of the worktree state for the UI."""
    worktree_path = config.worktree_path(task_id)
    if not worktree_path.exists():
        return {
            "exists": False,
            "branch": None,
            "files": [],
            "commits_ahead": 0,
        }
    try:
        branch = _run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=worktree_path)
    except GitError:
        branch = None
    files: list[dict[str, str]] = []
    try:
        raw = _run(["git", "status", "--porcelain"], cwd=worktree_path)
        for line in raw.splitlines():
            parsed = _parse_status_line(line)
            if parsed:
                files.append(parsed)
    except GitError:
        pass
    commits_ahead = 0
    try:
        raw = _run(
            ["git", "rev-list", "--count", f"{config.main_branch}..HEAD"],
            cwd=worktree_path,
        )
        commits_ahead = int(raw or "0")
    except (GitError, ValueError):
        pass
    return {
        "exists": True,
        "branch": branch,
        "files": files,
        "commits_ahead": commits_ahead,
    }
