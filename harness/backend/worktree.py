from __future__ import annotations

import shlex
import shutil
import subprocess
from dataclasses import dataclass
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


def repo_root(config: HarnessConfig) -> Path:
    try:
        return Path(_run(["git", "rev-parse", "--show-toplevel"], cwd=config.ios_root)).resolve()
    except GitError as exc:
        raise GitError(
            f"No git repo found at or above ios_root {config.ios_root}. "
            "Initialize or clone the parent repository first."
        ) from exc


def project_relpath(config: HarnessConfig) -> Path:
    repo = repo_root(config)
    ios_root = config.ios_root.resolve()
    try:
        return ios_root.relative_to(repo)
    except ValueError as exc:
        raise GitError(f"ios_root {ios_root} is outside detected git repo {repo}.") from exc


def project_worktree_path(config: HarnessConfig, task_id: str) -> Path:
    rel = project_relpath(config)
    root = config.worktree_path(task_id)
    return root if rel == Path(".") else root / rel


def ensure_repo(config: HarnessConfig) -> None:
    repo_root(config)


def create_worktree(
    config: HarnessConfig,
    task_id: str,
    branch: Optional[str] = None,
    base: str = "local",
) -> Path:
    ensure_repo(config)
    branch = branch or f"feature/{task_id}"
    repo = repo_root(config)
    worktree_path = config.worktree_path(task_id)
    worktree_path.parent.mkdir(parents=True, exist_ok=True)
    if worktree_path.exists():
        return project_worktree_path(config, task_id)
    # 디스크에서 사라진 prunable 워크트리 등록을 정리해, 브랜치가 다른 경로에
    # "사용 중"으로 남아있는 상태로 인한 `git worktree add` 실패를 방지한다.
    try:
        _run(["git", "worktree", "prune"], cwd=repo)
    except GitError:
        pass
    # Check if branch exists
    existing = _run(["git", "branch", "--list", branch], cwd=repo)
    if existing:
        _run(["git", "worktree", "add", str(worktree_path), branch], cwd=repo)
    else:
        if base == "remote":
            # 최신 원격 상태 보장
            _run(["git", "fetch", "origin", config.main_branch], cwd=repo)
            base_ref = f"origin/{config.main_branch}"
        else:
            base_ref = config.main_branch
        _run(
            ["git", "worktree", "add", "-b", branch, str(worktree_path), base_ref],
            cwd=repo,
        )
    return project_worktree_path(config, task_id)


def worktree_is_reusable(config: HarnessConfig, task_id: str) -> bool:
    worktree_path = project_worktree_path(config, task_id)
    if not worktree_path.exists():
        return False
    try:
        _run(["git", "rev-parse", "--show-toplevel"], cwd=worktree_path)
        return True
    except GitError:
        return False


def cleanup_orphaned_worktree(config: HarnessConfig, task_id: str) -> None:
    """Best-effort cleanup for a leftover worktree directory.

    This is intended for stale directories that should not be treated as a
    resumable worktree. If `git worktree remove` cannot clean it up, fall back
    to removing the filesystem path so a fresh worktree can be created.
    """
    ensure_repo(config)
    repo = repo_root(config)
    worktree_path = config.worktree_path(task_id)
    if not worktree_path.exists():
        return
    try:
        _run(["git", "worktree", "remove", "--force", str(worktree_path)], cwd=repo)
    except GitError:
        pass
    if worktree_path.exists():
        if worktree_path.is_dir():
            shutil.rmtree(worktree_path)
        else:
            worktree_path.unlink()


def remove_worktree(config: HarnessConfig, task_id: str, delete_branch: bool = False) -> None:
    ensure_repo(config)
    repo = repo_root(config)
    worktree_path = config.worktree_path(task_id)
    if worktree_path.exists():
        try:
            _run(["git", "worktree", "remove", "--force", str(worktree_path)], cwd=repo)
        except GitError:
            pass
    if delete_branch:
        branch = f"feature/{task_id}"
        try:
            _run(["git", "branch", "-D", branch], cwd=repo)
        except GitError:
            pass


def worktree_branch(task_id: str) -> str:
    return f"feature/{task_id}"


# ---------------------------------------------------------------------------
# PreToolUse path guard
# ---------------------------------------------------------------------------

WRITE_TOOL_NAMES = {"Write", "Edit", "MultiEdit", "NotebookEdit"}
BASH_TOOL_NAME = "Bash"
BASH_DIR_COMMANDS = {"cd", "pushd", "popd"}


@dataclass(frozen=True)
class BashPolicy:
    allowed_exact: tuple[tuple[str, ...], ...] = ()
    allowed_prefixes: tuple[tuple[str, ...], ...] = ()
    deny_shell_metachars: bool = True
    deny_parent_traversal: bool = True


def tokenize_command(command: str) -> tuple[str, ...]:
    return tuple(shlex.split(command, posix=True))


def _contains_shell_operator(command: str) -> bool:
    """Return True when command contains an active shell operator.

    The guard should reject real pipes/redirection/chaining while allowing
    literal characters inside quoted arguments, such as grep regex alternation.
    """
    in_single = False
    in_double = False
    escaped = False
    for index, char in enumerate(command):
        if char in ("\n", "\r"):
            return True
        if escaped:
            escaped = False
            continue
        if char == "\\" and not in_single:
            escaped = True
            continue
        if char == "'" and not in_double:
            in_single = not in_single
            continue
        if char == '"' and not in_single:
            in_double = not in_double
            continue
        if in_single:
            continue
        if char == "`":
            return True
        if char == "$" and command[index + 1 : index + 2] == "(":
            return True
        if not in_double and char in (";", "|", "&", ">", "<"):
            return True
    return False


def _under(target: str, root: Path) -> bool:
    try:
        return Path(target).resolve().is_relative_to(root.resolve())
    except (OSError, ValueError):
        return False


def _path_like_token(token: str) -> bool:
    if token in (".", ".."):
        return True
    if token.startswith(("/", "./", "../", "~")):
        return True
    if "/" in token and not token.startswith(("http://", "https://")):
        return True
    return False


def _contains_parent_traversal(token: str) -> bool:
    return token == ".." or token.startswith("../") or "/../" in token or token.endswith("/..")


def _git_add_args_allowed(args: tuple[str, ...]) -> bool:
    if args in (("-A",), (".",)):
        return True
    return bool(args) and all(arg and not arg.startswith(("/", "-")) and arg != "." for arg in args)


def _git_commit_args_allowed(args: tuple[str, ...]) -> bool:
    messages = 0
    index = 0
    while index < len(args):
        arg = args[index]
        if arg == "-m":
            if index + 1 >= len(args) or not args[index + 1].strip():
                return False
            messages += 1
            index += 2
            continue
        if arg == "--allow-empty":
            index += 1
            continue
        return False
    return messages > 0


def _only_testing_tail_allowed(tail: tuple[str, ...]) -> bool:
    return bool(tail) and all(arg.startswith("-only-testing:") for arg in tail)


def _ls_args_allowed(args: tuple[str, ...]) -> bool:
    seen_option = False
    for arg in args:
        if not arg.startswith("-"):
            continue
        if arg not in {"-a", "-l", "-la", "-al"} or seen_option:
            return False
        seen_option = True
    return True


def _matches_bash_policy(tokens: tuple[str, ...], policy: BashPolicy) -> bool:
    if tokens in policy.allowed_exact:
        return True
    for prefix in policy.allowed_prefixes:
        if len(tokens) <= len(prefix) or tokens[: len(prefix)] != prefix:
            continue
        tail = tokens[len(prefix) :]
        if prefix == ("git", "add"):
            return _git_add_args_allowed(tail)
        if prefix == ("git", "commit", "-m"):
            return _git_commit_args_allowed(("-m",) + tail)
        if prefix == ("gh", "pr", "create"):
            return True
        if prefix == ("ls",):
            return _ls_args_allowed(tail)
        if prefix and prefix[0] == "xcodebuild":
            return _only_testing_tail_allowed(tail)
        return True
    return False


def _deny_command(command: str, *, task_id: Optional[str], reason: str) -> tuple[dict[str, Any], dict[str, Any]]:
    payload = {
        "task_id": task_id,
        "tool": BASH_TOOL_NAME,
        "path": command,
        "reason": reason,
        "command": command,
    }
    response = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }
    return payload, response


def _validate_bash_command(
    command: str,
    worktree_dir: Path,
    *,
    task_id: Optional[str],
    bash_policy: Optional[BashPolicy],
) -> tuple[dict[str, Any], dict[str, Any]] | None:
    if bash_policy is None:
        return _deny_command(
            command,
            task_id=task_id,
            reason=f"Bash is disabled for this phase; command must not run outside worktree {worktree_dir}. Got: {command}",
        )
    if bash_policy.deny_shell_metachars and _contains_shell_operator(command):
        return _deny_command(
            command,
            task_id=task_id,
            reason=f"Bash command must be a single command without shell chaining/redirection. Got: {command}",
        )
    try:
        tokens = tokenize_command(command)
    except ValueError:
        return _deny_command(
            command,
            task_id=task_id,
            reason=f"Bash command could not be parsed safely. Got: {command}",
        )
    if not tokens:
        return _deny_command(
            command,
            task_id=task_id,
            reason="Bash command is missing or empty.",
        )
    if tokens[0] in BASH_DIR_COMMANDS:
        return _deny_command(
            command,
            task_id=task_id,
            reason=f"Bash directory changes are not allowed; cwd is already the worktree {worktree_dir}. Got: {command}",
        )
    if any(token == "tee" for token in tokens):
        return _deny_command(
            command,
            task_id=task_id,
            reason=f"Bash command may not use tee because it can write outside the worktree. Got: {command}",
        )
    for token in tokens:
        if not _path_like_token(token):
            continue
        if bash_policy.deny_parent_traversal and _contains_parent_traversal(token):
            return _deny_command(
                command,
                task_id=task_id,
                reason=f"Bash command may not use parent-directory traversal outside worktree {worktree_dir}. Got: {command}",
            )
        target = str(Path(token).expanduser()) if token.startswith("~") else token
        if (target.startswith("/") or token.startswith("~")) and not _under(target, worktree_dir):
            return _deny_command(
                command,
                task_id=task_id,
                reason=f"Bash command may only reference absolute paths inside worktree {worktree_dir}. Got: {command}",
            )
    if not _matches_bash_policy(tokens, bash_policy):
        return _deny_command(
            command,
            task_id=task_id,
            reason=f"Bash command is not in the allowlist for worktree {worktree_dir}. Got: {command}",
        )
    return None


def make_path_guard(
    worktree_dir: Path,
    *,
    task_id: Optional[str] = None,
    bash_policy: Optional[BashPolicy] = None,
) -> dict[str, list[HookMatcher]]:
    """Build a PreToolUse hook that denies writes outside the worktree.

    All pipeline artifacts (code + task .md + state.json) live inside the
    worktree. File edits anywhere else are blocked, and Bash is fail-closed:
    only single allowlisted commands may run.
    """

    async def pre_tool(input: dict[str, Any], tool_use_id: Optional[str], context: Any) -> dict[str, Any]:
        tool_name = input.get("tool_name")
        ti = input.get("tool_input") or {}
        if tool_name == BASH_TOOL_NAME:
            command = ti.get("command")
            if not isinstance(command, str) or not command.strip():
                command = ti.get("cmd")
            if not isinstance(command, str) or not command.strip():
                payload, response = _deny_command(
                    "<missing command>",
                    task_id=task_id,
                    reason="Bash command is missing from tool_input; expected `command` or `cmd`.",
                )
                await emit("agent_blocked", **payload)
                return response
            result = _validate_bash_command(
                command.strip(),
                worktree_dir,
                task_id=task_id,
                bash_policy=bash_policy,
            )
            if result is None:
                return {}
            payload, response = result
            await emit("agent_blocked", **payload)
            return response
        if tool_name not in WRITE_TOOL_NAMES:
            return {}
        fp = ti.get("file_path") or ti.get("notebook_path")
        if not fp:
            return {}
        if _under(fp, worktree_dir):
            return {}
        reason = f"Edits restricted to worktree {worktree_dir}. Got: {fp}"
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
                matcher="Write|Edit|MultiEdit|NotebookEdit|Bash",
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


def _normalize_project_relative_path(path: str, rel: Path) -> str:
    rel_text = rel.as_posix()
    if rel_text in ("", "."):
        return path
    if " -> " in path:
        old, new = path.split(" -> ", 1)
        return (
            f"{_normalize_project_relative_path(old, rel)}"
            f" -> {_normalize_project_relative_path(new, rel)}"
        )
    prefix = f"{rel_text}/"
    if path.startswith(prefix):
        return path[len(prefix):]
    return path


def worktree_status(config: HarnessConfig, task_id: str) -> dict[str, Any]:
    """Return a lightweight summary of the worktree state for the UI."""
    worktree_path = project_worktree_path(config, task_id)
    if not worktree_path.exists():
        return {
            "exists": False,
            "branch": None,
            "files": [],
            "commits_ahead": 0,
        }
    rel = project_relpath(config)
    try:
        branch = _run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=worktree_path)
    except GitError:
        branch = None
    files: list[dict[str, str]] = []
    try:
        raw = _run(["git", "status", "--porcelain", "--untracked-files=no"], cwd=worktree_path)
        for line in raw.splitlines():
            parsed = _parse_status_line(line)
            if parsed:
                parsed["path"] = _normalize_project_relative_path(parsed["path"], rel)
                files.append(parsed)
    except GitError:
        pass
    try:
        raw = _run(["git", "ls-files", "--others", "--exclude-standard"], cwd=worktree_path)
        for line in raw.splitlines():
            path = line.strip()
            if path:
                files.append({"path": path, "change": "untracked"})
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
