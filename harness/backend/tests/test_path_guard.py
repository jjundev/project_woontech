"""PreToolUse path guard tests for worktree enforcement."""
from __future__ import annotations

import asyncio
from pathlib import Path

import pytest

from backend import worktree as W


@pytest.fixture
def worktree_dir(tmp_path: Path) -> Path:
    d = tmp_path / "worktree"
    d.mkdir()
    return d


def _callback(hooks_dict):
    return hooks_dict["PreToolUse"][0].hooks[0]


def _call(cb, tool: str, file_path: str):
    return asyncio.run(
        cb({"tool_name": tool, "tool_input": {"file_path": file_path}}, None, None)
    )


def _call_bash(cb, *, command: str | None = None, cmd: str | None = None):
    tool_input: dict[str, str] = {}
    if command is not None:
        tool_input["command"] = command
    if cmd is not None:
        tool_input["cmd"] = cmd
    return asyncio.run(cb({"tool_name": "Bash", "tool_input": tool_input}, None, None))


@pytest.fixture
def bash_policy() -> W.BashPolicy:
    return W.BashPolicy(
        allowed_exact=(
            W.tokenize_command("pwd"),
            W.tokenize_command("ls"),
            W.tokenize_command("ls -la"),
            W.tokenize_command("xcodebuild build -scheme Woontech"),
            W.tokenize_command("git add -A"),
            W.tokenize_command("git add ."),
        ),
        allowed_prefixes=(
            W.tokenize_command("ls"),
            W.tokenize_command("xcodebuild test -scheme Woontech"),
            W.tokenize_command("git add"),
            W.tokenize_command("git commit -m"),
            W.tokenize_command("gh pr create"),
        ),
    )


def test_allows_writes_inside_worktree(worktree_dir: Path):
    target = worktree_dir / "Woontech" / "Foo.swift"
    target.parent.mkdir(parents=True)
    cb = _callback(W.make_path_guard(worktree_dir))
    assert _call(cb, "Write", str(target)) == {}


def test_allows_workspace_md_inside_worktree(worktree_dir: Path):
    """Workspace .md files live inside the worktree (ongoing/<id>/*.md)."""
    target = worktree_dir / "ongoing" / "T1" / "implement-plan.md"
    target.parent.mkdir(parents=True)
    cb = _callback(W.make_path_guard(worktree_dir))
    assert _call(cb, "Write", str(target)) == {}


def test_blocks_writes_outside_worktree(tmp_path: Path, worktree_dir: Path):
    cb = _callback(W.make_path_guard(worktree_dir))
    result = _call(cb, "Write", str(tmp_path / "leaked.txt"))
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


def test_blocks_writes_to_sibling_task_folder(tmp_path: Path, worktree_dir: Path):
    """Pipeline must never touch root ios/ongoing/<id>/*.md."""
    cb = _callback(W.make_path_guard(worktree_dir))
    outside = tmp_path / "ios" / "ongoing" / "T1" / "implement-plan.md"
    outside.parent.mkdir(parents=True)
    result = _call(cb, "Write", str(outside))
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


def test_notebook_edit_uses_notebook_path(tmp_path: Path, worktree_dir: Path):
    cb = _callback(W.make_path_guard(worktree_dir))
    outside = tmp_path / "other.ipynb"
    result = asyncio.run(
        cb({"tool_name": "NotebookEdit", "tool_input": {"notebook_path": str(outside)}}, None, None)
    )
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


def test_worktree_status_reports_empty_when_missing(tmp_config):
    status = W.worktree_status(tmp_config, "nonexistent")
    assert status["exists"] is False
    assert status["files"] == []


def test_bash_without_policy_is_denied(worktree_dir: Path):
    cb = _callback(W.make_path_guard(worktree_dir))
    result = _call_bash(cb, command="git status")
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


def test_bash_allows_exact_command(worktree_dir: Path, bash_policy: W.BashPolicy):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    assert _call_bash(cb, command="xcodebuild build -scheme Woontech") == {}


def test_bash_allows_cmd_fallback(worktree_dir: Path, bash_policy: W.BashPolicy):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    assert _call_bash(cb, cmd="git add -A") == {}


def test_bash_allows_git_commit_prefix(worktree_dir: Path, bash_policy: W.BashPolicy):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    assert _call_bash(cb, command='git commit -m "checkpoint"') == {}


def test_bash_with_run_in_background_is_denied(worktree_dir: Path, bash_policy: W.BashPolicy):
    """Background test runs race with the harness's post-reviewer artifact check.

    The reviewer once offloaded a UI test command with run_in_background=true and
    polled `tail -f` via Monitor while answering "tests are running"; agent
    finished before xcode_test_runner.py wrote `last-ui-summary.txt`, so the
    harness escalated as `diagnostic_infra_missing`. The hook now denies this
    even when the underlying command is otherwise allowlisted.
    """
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    result = asyncio.run(
        cb(
            {
                "tool_name": "Bash",
                "tool_input": {
                    "command": "xcodebuild build -scheme Woontech",
                    "run_in_background": True,
                },
            },
            None,
            None,
        )
    )
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert "run_in_background" in result["hookSpecificOutput"]["permissionDecisionReason"]


def test_bash_with_run_in_background_false_still_validates(worktree_dir: Path, bash_policy: W.BashPolicy):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    result = asyncio.run(
        cb(
            {
                "tool_name": "Bash",
                "tool_input": {
                    "command": "xcodebuild build -scheme Woontech",
                    "run_in_background": False,
                },
            },
            None,
            None,
        )
    )
    assert result == {}


@pytest.mark.parametrize("tool", ["Monitor", "BashOutput", "KillShell"])
def test_background_tools_are_denied(worktree_dir: Path, bash_policy: W.BashPolicy, tool: str):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    result = asyncio.run(
        cb({"tool_name": tool, "tool_input": {}}, None, None)
    )
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert tool in result["hookSpecificOutput"]["permissionDecisionReason"]


def test_bash_allows_git_commit_multiple_message_parts(worktree_dir: Path, bash_policy: W.BashPolicy):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    assert (
        _call_bash(
            cb,
            command='git commit -m "Implement WF2 saju flow" -m "Adds result screens and tests."',
        )
        == {}
    )


def test_bash_allows_git_commit_quoted_email_text(worktree_dir: Path, bash_policy: W.BashPolicy):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    assert (
        _call_bash(
            cb,
            command='git commit -m "Implement flow Co-Authored-By: Claude <noreply@anthropic.com>"',
        )
        == {}
    )


def test_bash_allows_git_add_relative_path(worktree_dir: Path, bash_policy: W.BashPolicy):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    assert _call_bash(cb, command="git add Sources/Foo.swift") == {}


def test_bash_allows_only_testing_tail(worktree_dir: Path, bash_policy: W.BashPolicy):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    assert (
        _call_bash(
            cb,
            command="xcodebuild test -scheme Woontech -only-testing:WoontechTests/FooTests",
        )
        == {}
    )


def test_bash_allows_xcode_test_runner_only_testing_tail(worktree_dir: Path):
    policy = W.BashPolicy(
        allowed_prefixes=(
            W.tokenize_command("python3 tools/xcode_test_runner.py test --target WoontechTests"),
        )
    )
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=policy))

    assert (
        _call_bash(
            cb,
            command=(
                "python3 tools/xcode_test_runner.py test --target WoontechTests "
                "-only-testing:WoontechTests/FooTests"
            ),
        )
        == {}
    )


def test_bash_blocks_xcode_test_runner_non_only_testing_tail(worktree_dir: Path):
    policy = W.BashPolicy(
        allowed_prefixes=(
            W.tokenize_command("python3 tools/xcode_test_runner.py test --target WoontechTests"),
        )
    )
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=policy))
    result = _call_bash(
        cb,
        command="python3 tools/xcode_test_runner.py test --target WoontechTests --foo",
    )

    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


def test_bash_blocks_real_pipe_and_redirection(worktree_dir: Path, bash_policy: W.BashPolicy):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    result = _call_bash(
        cb,
        command="xcodebuild build -scheme Woontech 2>&1 | tail -100",
    )

    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert "single command" in result["hookSpecificOutput"]["permissionDecisionReason"]


def test_bash_quoted_regex_pipe_is_not_shell_chaining(worktree_dir: Path, bash_policy: W.BashPolicy):
    log_file = worktree_dir / "build.log"
    log_file.write_text("warning: example\n", encoding="utf-8")
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    result = _call_bash(
        cb,
        command=f'grep -E "error:|warning:" {log_file}',
    )

    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert "allowlist" in result["hookSpecificOutput"]["permissionDecisionReason"]


def test_bash_allows_ls_inside_worktree_absolute_path(worktree_dir: Path, bash_policy: W.BashPolicy):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))

    assert _call_bash(cb, command=f"ls -la {worktree_dir}") == {}


def test_bash_blocks_ls_outside_worktree(worktree_dir: Path, bash_policy: W.BashPolicy):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    result = _call_bash(cb, command="ls -la /tmp")

    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


def test_bash_blocks_tool_results_outside_worktree(tmp_path: Path, worktree_dir: Path, bash_policy: W.BashPolicy):
    tool_result = tmp_path / ".claude" / "projects" / "p" / "tool-results" / "out.txt"
    tool_result.parent.mkdir(parents=True)
    tool_result.write_text("log\n", encoding="utf-8")
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    result = _call_bash(cb, command=f"ls -la {tool_result}")

    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


@pytest.mark.parametrize(
    "command",
    [
        "echo x > /repo/ios/todo/T1/spec.md",
        "tee /repo/ios/done/T1/pr.md",
        "cd /repo/ios",
        "git add ../ios/todo/T1/spec.md",
        "python -c 'open(\"/tmp/x\", \"w\")'",
        "git status && touch /tmp/leak",
        "cp foo ../bar",
        "ls -la ../outside",
    ],
)
def test_bash_blocks_disallowed_commands(worktree_dir: Path, bash_policy: W.BashPolicy, command: str):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    result = _call_bash(cb, command=command)
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"


def test_bash_blocks_missing_command_key(worktree_dir: Path, bash_policy: W.BashPolicy):
    cb = _callback(W.make_path_guard(worktree_dir, bash_policy=bash_policy))
    result = _call_bash(cb)
    assert result["hookSpecificOutput"]["permissionDecision"] == "deny"
