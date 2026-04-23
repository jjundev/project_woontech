"""PreToolUse path guard tests for worktree enforcement."""
from __future__ import annotations

import asyncio
from pathlib import Path

import pytest

from backend import worktree as W


@pytest.fixture
def tree(tmp_path: Path):
    worktree = tmp_path / "worktree"
    task = tmp_path / "task"
    worktree.mkdir()
    task.mkdir()
    return worktree, task


def _callback(hooks_dict):
    return hooks_dict["PreToolUse"][0].hooks[0]


def _call(cb, tool: str, file_path: str):
    return asyncio.run(
        cb({"tool_name": tool, "tool_input": {"file_path": file_path}}, None, None)
    )


def test_allows_writes_inside_worktree(tree):
    worktree, task = tree
    target = worktree / "Woontech" / "Foo.swift"
    target.parent.mkdir(parents=True)
    cb = _callback(W.make_path_guard(worktree, task))
    assert _call(cb, "Write", str(target)) == {}


def test_blocks_writes_outside_worktree(tmp_path: Path, tree):
    worktree, task = tree
    cb = _callback(W.make_path_guard(worktree, task))
    result = _call(cb, "Write", str(tmp_path / "leaked.txt"))
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


def test_allows_review_markdown_inside_task_folder(tree):
    worktree, task = tree
    cb = _callback(W.make_path_guard(worktree, task))
    for name in (
        "implement-plan.md",
        "implement-checklist.md",
        "implement-review.md",
        "pr.md",
        "implement-feedback-version-1.md",
        "plan-feedback-version-3.md",
    ):
        assert _call(cb, "Write", str(task / name)) == {}, name


def test_blocks_arbitrary_task_folder_writes(tree):
    worktree, task = tree
    cb = _callback(W.make_path_guard(worktree, task))
    result = _call(cb, "Write", str(task / "secret.md"))
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


def test_notebook_edit_uses_notebook_path(tree):
    worktree, task = tree
    cb = _callback(W.make_path_guard(worktree, task))
    outside = task.parent / "other.ipynb"
    result = asyncio.run(
        cb({"tool_name": "NotebookEdit", "tool_input": {"notebook_path": str(outside)}}, None, None)
    )
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


def test_worktree_status_reports_empty_when_missing(tmp_config):
    status = W.worktree_status(tmp_config, "nonexistent")
    assert status["exists"] is False
    assert status["files"] == []
