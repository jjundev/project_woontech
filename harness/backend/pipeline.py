"""Pipeline orchestration with GAN loops for plan-review and implement-review."""
from __future__ import annotations

import re
import shlex
import subprocess
import sys
import time
import uuid
from pathlib import Path
from typing import Optional

from . import agents as A
from . import state as S
from . import worktree as W
from .config import HarnessConfig
from .event_log import ImplPhaseEventLogger
from .events import emit, reset_current_run_id, set_current_run_id
from .plan_parser import parse_plan_file


# Reference-counted macOS wake lock: while any pipeline runs, keep `caffeinate -i`
# alive so agent subprocesses don't get suspended when the machine would sleep.
_caffeinate_proc: Optional[subprocess.Popen] = None
_caffeinate_refs = 0


def _acquire_wake_lock() -> None:
    global _caffeinate_proc, _caffeinate_refs
    _caffeinate_refs += 1
    if _caffeinate_proc is None and sys.platform == "darwin":
        try:
            _caffeinate_proc = subprocess.Popen(["caffeinate", "-i"])
        except (OSError, FileNotFoundError):
            _caffeinate_proc = None


def _release_wake_lock() -> None:
    global _caffeinate_proc, _caffeinate_refs
    _caffeinate_refs = max(0, _caffeinate_refs - 1)
    if _caffeinate_refs == 0 and _caffeinate_proc is not None:
        try:
            _caffeinate_proc.terminate()
        except Exception:
            pass
        _caffeinate_proc = None


CLASS_RE = re.compile(r"class\s+(\w+)\s*:\s*[^\{]*XCTestCase")
ONLY_TESTING_TOKEN_RE = re.compile(r"\{only_testing:(\w+)\}")
PROJECT_SWIFT_ROOTS = ("Woontech", "WoontechTests", "WoontechUITests")
PHASE_NAMES = ("plan", "impl", "ui_verify", "publish")
TEST_ARTIFACTS_SUBDIR = Path(".harness") / "test-results"
UNEXPECTED_ESCALATIONS = {
    "plan": "plan_unexpected_error",
    "impl": "impl_unexpected_error",
    "ui_verify": "ui_verify_unexpected_error",
    "publish": "publish_unexpected_error",
}


def _feedback_version(path: Path) -> int:
    match = re.search(r"version-(\d+)", path.name)
    return int(match.group(1)) if match else -1


def _all_plan_feedback(task_dir: Path) -> list[Path]:
    return sorted(task_dir.glob("plan-feedback-version-*.md"), key=_feedback_version)


def _all_impl_feedback(task_dir: Path) -> list[Path]:
    return sorted(task_dir.glob("implement-feedback-version-*.md"), key=_feedback_version)


def _format_feedback_paths(paths: list[Path]) -> str:
    if not paths:
        return "NONE"
    return "\n".join(f"- {path}" for path in paths)


def _format_text_list(values: list[str]) -> str:
    if not values:
        return "NONE"
    return "\n".join(f"- {value}" for value in values)


def _latest_feedback(paths: list[Path]) -> list[Path]:
    """Return only the most recent feedback file. Reviewers should use it as a
    rolling ledger: each new feedback file carries forward the unresolved items
    from prior iterations. Keeps prompt size O(1) instead of O(iterations)."""
    return paths[-1:] if paths else []


def _next_impl_feedback_version(task_dir: Path) -> int:
    versions = [_feedback_version(path) for path in _all_impl_feedback(task_dir)]
    return max(versions, default=0) + 1


_DIAG_MISSING_RE = re.compile(
    r"DIAGNOSTIC_INFRASTRUCTURE_MISSING:\s*(\S[^\r\n]*)",
)


def _diagnostic_infra_signal(task_dir: Path) -> Optional[str]:
    """Return the path the reviewer flagged as unreadable, or None.

    The reviewer system prompt emits `DIAGNOSTIC_INFRASTRUCTURE_MISSING: <path>`
    when it cannot read test failure summaries from `.harness/test-results/`.
    This short-circuits the retry loop so we don't burn iterations on
    hypothesis-based fixes when the diagnostic infrastructure itself is broken.
    """
    feedback = _latest_feedback(_all_impl_feedback(task_dir))
    if not feedback:
        return None
    try:
        body = feedback[0].read_text()
    except OSError:
        return None
    match = _DIAG_MISSING_RE.search(body)
    return match.group(1).strip() if match else None


class DiagnosticInfrastructureError(RuntimeError):
    def __init__(self, path: Path, reason: str) -> None:
        self.path = path
        self.reason = reason
        super().__init__(
            "test artifact persistence broken — refusing to invoke reviewer blind "
            f"({reason}: {path})"
        )


def _test_artifact_paths(worktree_dir: Path, kind: str) -> tuple[Path, Path]:
    base = worktree_dir / TEST_ARTIFACTS_SUBDIR
    return base / f"last-{kind}-summary.txt", base / f"last-{kind}-failures.txt"


def _assert_test_artifacts_visible(
    worktree_dir: Path,
    kinds: set[str],
    since: float,
) -> None:
    for kind in sorted(kinds):
        for path in _test_artifact_paths(worktree_dir, kind):
            if not path.exists():
                raise DiagnosticInfrastructureError(path, "missing")
            try:
                stat = path.stat()
            except OSError as exc:
                raise DiagnosticInfrastructureError(path, f"unreadable: {exc}") from exc
            if stat.st_size == 0:
                raise DiagnosticInfrastructureError(path, "empty")
            if stat.st_mtime < since - 2:
                raise DiagnosticInfrastructureError(path, "stale")


def _test_kind_from_bash_command(command: str) -> Optional[str]:
    try:
        tokens = _tokenize_command(command)
    except ValueError:
        return None
    if tokens[:3] != ("python3", "tools/xcode_test_runner.py", "test"):
        return None
    target: Optional[str] = None
    for index, token in enumerate(tokens):
        if token == "--target" and index + 1 < len(tokens):
            target = tokens[index + 1]
            break
    if target == "WoontechUITests" or "--ui" in tokens:
        return "ui"
    if target == "WoontechTests":
        return "unit"
    return None


def _test_kinds_from_tool_uses(tool_uses: list[dict[str, object]]) -> set[str]:
    kinds: set[str] = set()
    for use in tool_uses:
        if use.get("name") != "Bash":
            continue
        tool_input = use.get("input")
        if not isinstance(tool_input, dict):
            continue
        command = tool_input.get("command") or tool_input.get("cmd")
        if not isinstance(command, str):
            continue
        kind = _test_kind_from_bash_command(command)
        if kind is not None:
            kinds.add(kind)
    return kinds


async def _record_diagnostic_infra_missing(
    task_dir: Path,
    task_id: str,
    phase: str,
    error: DiagnosticInfrastructureError,
    *,
    iteration: Optional[int] = None,
) -> None:
    state = S.read_state(task_dir)
    if iteration is not None:
        state.impl_retries = iteration
        state.impl_version = iteration + 1
    state.escalation = "diagnostic_infra_missing"
    S.write_state(task_dir, state)
    await emit(
        "diagnostic_infra_missing",
        task_id=task_id,
        phase=phase,
        iteration=iteration,
        missing_path=str(error.path),
        reason=error.reason,
    )


async def _record_ui_verify_diagnostic_infra_missing(
    task_dir: Path,
    task_id: str,
    phase: str,
    error: DiagnosticInfrastructureError,
    *,
    iteration: Optional[int] = None,
) -> None:
    state = S.read_state(task_dir)
    if iteration is not None:
        state.ui_review_retries = iteration
    state.escalation = "ui_verify_diagnostic_infra_missing"
    S.write_state(task_dir, state)
    await emit(
        "diagnostic_infra_missing",
        task_id=task_id,
        phase=phase,
        iteration=iteration,
        missing_path=str(error.path),
        reason=error.reason,
    )


_TOKEN_DECORATION_RE = re.compile(r"[^\w\s]+")


def _has_token(text: str, token: str) -> bool:
    """Whether an agent's response ends any line with `token`.

    Strips markdown/punctuation decorations, splits into words, and accepts the
    line if the final word equals `token`. This allows common LLM closings like
    `Decision: IMPLEMENT_REWORK_REQUIRED`, `**PLAN_PASS**`, `Verdict — PLAN_FAIL.`
    while still rejecting prose where the token is mentioned mid-sentence
    (`I may mention PLAN_PASS in passing`).
    """
    for line in text.splitlines():
        words = _TOKEN_DECORATION_RE.sub(" ", line).split()
        if words and words[-1] == token:
            return True
    return False


def _find_terminal_token(text: str, candidates: tuple[str, ...]) -> Optional[str]:
    """Return the latest-occurring `candidate` that ends a line in `text`.

    Needed because an agent's response may reference earlier decisions in prose
    before committing to the final one. Scanning top-to-bottom and keeping the
    last match picks the final decision, not the first thing mentioned.
    """
    last: Optional[str] = None
    for line in text.splitlines():
        words = _TOKEN_DECORATION_RE.sub(" ", line).split()
        if not words:
            continue
        tail = words[-1]
        if tail in candidates:
            last = tail
    return last


def _text_tail(text: str, limit: int = 400) -> str:
    """Last `limit` chars of `text`, for surfacing in ambiguous-event payloads."""
    return text[-limit:] if len(text) > limit else text


async def _set_state(config: HarnessConfig, task_id: str, new_state: str) -> Path:
    task_dir = S.transition(config, task_id, new_state)  # type: ignore[arg-type]
    await emit("state_changed", task_id=task_id, state=new_state)
    return task_dir


def _git_commit_workspace(worktree_project: Path, message: str) -> None:
    """Commit any workspace changes inside the project worktree. Best-effort."""
    try:
        subprocess.run(
            ["git", "add", "-A"], cwd=str(worktree_project), check=True, capture_output=True
        )
        subprocess.run(
            ["git", "commit", "-m", message, "--allow-empty"],
            cwd=str(worktree_project),
            check=True,
            capture_output=True,
        )
    except subprocess.CalledProcessError:
        pass


def _head_sha(worktree_project: Path) -> Optional[str]:
    r = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=str(worktree_project),
        capture_output=True,
        text=True,
    )
    return r.stdout.strip() if r.returncode == 0 else None


def _maybe_auto_commit_worktree(worktree_project: Path, label: str) -> bool:
    """If the worktree has uncommitted changes, commit them on behalf of the agent.

    Exists because an implementor that hits max_turns mid-flight never reaches
    its own `git commit`. Without this, files written to disk stay untracked,
    the reviewer sees no new commits, and the next iteration starts from stale
    state. Returns True if a commit was actually made.
    """
    status = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=str(worktree_project),
        capture_output=True,
        text=True,
    )
    if status.returncode != 0 or not status.stdout.strip():
        return False
    add = subprocess.run(
        ["git", "add", "-A"],
        cwd=str(worktree_project),
        capture_output=True,
        text=True,
    )
    if add.returncode != 0:
        return False
    commit = subprocess.run(
        ["git", "commit", "-m", f"Auto-commit: {label}"],
        cwd=str(worktree_project),
        capture_output=True,
        text=True,
    )
    return commit.returncode == 0


def _short_sha(sha: Optional[str]) -> Optional[str]:
    return sha[:8] if sha else None


def _tokenize_command(command: str) -> tuple[str, ...]:
    return tuple(shlex.split(command, posix=True))


def _only_testing_prefix(command: str) -> Optional[tuple[str, ...]]:
    match = ONLY_TESTING_TOKEN_RE.search(command)
    if not match:
        return None
    suffix = command[match.end() :].strip()
    if suffix:
        return None
    prefix = command[: match.start()].strip()
    return _tokenize_command(prefix) if prefix else None


def _common_git_bash_policy() -> W.BashPolicy:
    return W.BashPolicy(
        allowed_exact=(
            _tokenize_command("pwd"),
            _tokenize_command("ls"),
            _tokenize_command("ls -la"),
            _tokenize_command("git status"),
            _tokenize_command("git diff"),
            _tokenize_command("git add -A"),
            _tokenize_command("git add ."),
        ),
        allowed_prefixes=(
            _tokenize_command("ls"),
            _tokenize_command("git rev-parse"),
            _tokenize_command("git add"),
            _tokenize_command("git commit -m"),
        ),
    )


def _merge_bash_policy(base: W.BashPolicy, *, exact: tuple[tuple[str, ...], ...] = (), prefixes: tuple[tuple[str, ...], ...] = ()) -> W.BashPolicy:
    return W.BashPolicy(
        allowed_exact=base.allowed_exact + exact,
        allowed_prefixes=base.allowed_prefixes + prefixes,
        deny_shell_metachars=base.deny_shell_metachars,
        deny_parent_traversal=base.deny_parent_traversal,
    )


def _implementor_bash_policy(config: HarnessConfig) -> W.BashPolicy:
    exact = (_tokenize_command(config.build_cmd),)
    prefixes: tuple[tuple[str, ...], ...] = ()
    unit_prefix = _only_testing_prefix(config.unit_test_cmd)
    if unit_prefix is not None:
        prefixes += (unit_prefix,)
    else:
        exact += (_tokenize_command(config.unit_test_cmd),)
    return _merge_bash_policy(_common_git_bash_policy(), exact=exact, prefixes=prefixes)


def _reviewer_bash_policy(config: HarnessConfig, unit_cmd: str) -> W.BashPolicy:
    return _merge_bash_policy(
        _common_git_bash_policy(),
        exact=(
            _tokenize_command(config.build_cmd),
            _tokenize_command(unit_cmd),
        ),
    )


def _ui_reviewer_bash_policy(
    config: HarnessConfig, unit_cmd: str, ui_cmd: str
) -> W.BashPolicy:
    """Bash policy for the reviewer when invoked from the ui_verify gate.

    Adds the resolved `ui_cmd` to the allowlist so the reviewer can re-run
    UI tests after applying a localized patch. Skips `echo SKIP: ...`
    placeholders that signal "no resolvable tests in this worktree".
    """
    exact_cmds: list[tuple[str, ...]] = [_tokenize_command(config.build_cmd)]
    if not unit_cmd.lstrip().startswith("echo"):
        exact_cmds.append(_tokenize_command(unit_cmd))
    if not ui_cmd.lstrip().startswith("echo"):
        exact_cmds.append(_tokenize_command(ui_cmd))
    return _merge_bash_policy(
        _common_git_bash_policy(),
        exact=tuple(exact_cmds),
    )


def _publish_bash_policy(task_id: str) -> W.BashPolicy:
    branch = W.worktree_branch(task_id)
    return W.BashPolicy(
        allowed_exact=(
            _tokenize_command("git status"),
            _tokenize_command(f"git push -u origin {branch}"),
        ),
        allowed_prefixes=(
            _tokenize_command("git rev-parse"),
            _tokenize_command("gh pr create"),
        ),
    )


# ---------------------------------------------------------------------------
# Worktree-only test discovery and command injection
# ---------------------------------------------------------------------------


def _git_out(args: list[str], cwd: Path) -> str:
    r = subprocess.run(["git", *args], cwd=str(cwd), capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""


def _is_project_swift_file(relpath: str) -> bool:
    if not relpath.endswith(".swift"):
        return False
    parts = Path(relpath).parts
    return bool(parts) and parts[0] in PROJECT_SWIFT_ROOTS


def discover_new_swift_files(worktree_dir: Path, base_branch: str) -> list[str]:
    """Return project Swift files added vs {base_branch} plus untracked files.

    This is narrower than "all .swift files in the repo" on purpose: pbxproj
    membership checks are only meaningful for source/test files that belong to
    the Xcode project targets.
    """
    files: set[str] = set()
    for line in _git_out(
        ["diff", "--relative", "--name-only", "--diff-filter=A", f"{base_branch}...HEAD"],
        worktree_dir,
    ).splitlines():
        line = line.strip()
        if line:
            files.add(line)
    for line in _git_out(
        ["ls-files", "--others", "--exclude-standard"], worktree_dir
    ).splitlines():
        line = line.strip()
        if line:
            files.add(line)
    return sorted(path for path in files if _is_project_swift_file(path))


def discover_new_test_classes(worktree_dir: Path, base_branch: str) -> dict[str, list[str]]:
    """Return XCTestCase classes from changed test files per target.

    "Changed" includes files added or modified vs {base_branch}...HEAD, plus
    untracked files in the worktree. When an existing test file is modified,
    every XCTestCase class in that file is included in the scoped test run.
    """
    files: set[str] = set()
    for line in _git_out(
        ["diff", "--relative", "--name-only", "--diff-filter=AM", f"{base_branch}...HEAD"],
        worktree_dir,
    ).splitlines():
        line = line.strip()
        if line:
            files.add(line)
    # `status --porcelain` collapses untracked directories into a single entry
    # (e.g. "?? WoontechUITests/"), which hides new files underneath. Use
    # `ls-files -o --exclude-standard` to get the full list of untracked files.
    for line in _git_out(
        ["ls-files", "--others", "--exclude-standard"], worktree_dir
    ).splitlines():
        line = line.strip()
        if line:
            files.add(line)

    out: dict[str, list[str]] = {"WoontechTests": [], "WoontechUITests": []}
    for f in files:
        if not f.endswith(".swift"):
            continue
        if "WoontechUITests/" in f:
            target = "WoontechUITests"
        elif "WoontechTests/" in f:
            target = "WoontechTests"
        else:
            continue
        try:
            text = (worktree_dir / f).read_text(encoding="utf-8")
        except OSError:
            continue
        out[target].extend(CLASS_RE.findall(text))
    for k in list(out.keys()):
        seen: set[str] = set()
        out[k] = [c for c in out[k] if not (c in seen or seen.add(c))]
    return out


def inject_only_testing(cmd_template: str, classes: list[str]) -> Optional[str]:
    """Replace `{only_testing:Target}` with `-only-testing:Target/Class ...`.

    Returns None when the template contains the token but there are no classes
    (caller should skip running tests). Returns the original string unchanged
    if no token is present.
    """
    m = ONLY_TESTING_TOKEN_RE.search(cmd_template)
    if not m:
        return cmd_template
    if not classes:
        return None
    target = m.group(1)
    flags = " ".join(f"-only-testing:{target}/{c}" for c in classes)
    return ONLY_TESTING_TOKEN_RE.sub(flags, cmd_template)


async def _resolve_test_commands(
    config: HarnessConfig,
    worktree_dir: Path,
    task_id: str,
) -> tuple[str, str]:
    changed = discover_new_test_classes(worktree_dir, config.main_branch)
    unit = inject_only_testing(config.unit_test_cmd, changed.get("WoontechTests", []))
    # Always include mandatory UI smoke classes (e.g. AppLaunchContractUITests)
    # so the launch-arg routing contract is verified on every reviewer pass,
    # even when no UI test files were touched in the worktree. De-dupe while
    # preserving order: changed-first, then mandatory entries that aren't
    # already in the list.
    ui_classes = list(changed.get("WoontechUITests", []))
    for cls in config.always_ui_test_classes:
        if cls not in ui_classes:
            ui_classes.append(cls)
    ui = inject_only_testing(config.ui_test_cmd, ui_classes)
    if unit is None:
        await emit(
            "tests_skipped",
            task_id=task_id,
            target="WoontechTests",
            reason="no changed test files in this worktree",
        )
        unit = "echo 'SKIP: no changed unit test files in this worktree'"
    if ui is None:
        await emit(
            "tests_skipped",
            task_id=task_id,
            target="WoontechUITests",
            reason="no changed test files in this worktree",
        )
        ui = "echo 'SKIP: no changed ui test files in this worktree'"
    return unit, ui


# ---------------------------------------------------------------------------
# Pipeline phases
# ---------------------------------------------------------------------------


async def run_plan_phase(
    config: HarnessConfig,
    task_id: str,
    task_dir: Path,
    worktree_dir: Path,
    max_retries: int,
    *,
    skip_planner: bool = False,
) -> bool:
    """Return True on pass, False on escalation."""
    guard = W.make_path_guard(worktree_dir, task_id=task_id)
    if skip_planner:
        await emit("plan_skipped", task_id=task_id, reason="plan_already_written")
    else:
        # Planner writes v1
        await emit("phase_started", task_id=task_id, phase="planning")
        planner_prompt = f"""Task workspace: {task_dir}
Spec file: {task_dir / 'spec.md'}
Worktree (read-only reference for code structure): {worktree_dir}

Write implement-plan.md v1 in the task workspace.
"""
        await A.run_agent(
            A.resolve_agent(A.PLANNER, config),
            planner_prompt,
            cwd=task_dir,
            task_id=task_id,
            hooks=guard,
        )

    # GAN loop
    for iteration in range(1, max_retries + 1):
        await emit("phase_started", task_id=task_id, phase="plan_review", iteration=iteration)
        latest_feedback = _latest_feedback(_all_plan_feedback(task_dir))
        reviewer_prompt = f"""Task workspace: {task_dir}
Spec file: {task_dir / 'spec.md'}
Current implement-plan.md: {task_dir / 'implement-plan.md'}
Latest plan-feedback file (carries forward unresolved items from earlier iterations):
{_format_feedback_paths(latest_feedback)}
Iteration: {iteration}

Review the plan. If PASS, write implement-checklist.md and respond PLAN_PASS.
If FAIL, write plan-feedback-version-{iteration}.md, edit implement-plan.md directly, and respond PLAN_FAIL.
"""
        result = await A.run_agent(
            A.resolve_agent(A.PLAN_REVIEWER, config),
            reviewer_prompt,
            cwd=task_dir,
            task_id=task_id,
            iteration=iteration,
            hooks=guard,
        )
        decision = _find_terminal_token(result.text, ("PLAN_PASS", "PLAN_FAIL"))
        if decision == "PLAN_PASS":
            steps = parse_plan_file(task_dir / "implement-plan.md")
            if steps:
                await emit("plan_steps", task_id=task_id, steps=steps)
            return True
        if decision == "PLAN_FAIL":
            state = S.read_state(task_dir)
            state.plan_retries = iteration
            state.plan_version = iteration + 1
            S.write_state(task_dir, state)
            await emit("retry", task_id=task_id, phase="plan_review", iteration=iteration)
            continue
        # ambiguous response — treat as fail and continue
        await emit(
            "agent_ambiguous",
            task_id=task_id,
            phase="plan_review",
            iteration=iteration,
            stop_reason=result.stop_reason,
            text_tail=_text_tail(result.text),
        )
    # Exhausted
    return False


async def run_impl_phase(
    config: HarnessConfig,
    task_id: str,
    task_dir: Path,
    worktree_dir: Path,
    max_retries: int,
    *,
    skip_implementor: bool = False,
) -> bool:
    implementor_guard = W.make_path_guard(
        worktree_dir,
        task_id=task_id,
        bash_policy=_implementor_bash_policy(config),
    )
    last_implementor_test_kinds: set[str] = set()
    last_implementor_started_at = 0.0
    if skip_implementor:
        await emit(
            "impl_skipped",
            task_id=task_id,
            reason="user_resume_from_review",
            head_sha=_short_sha(_head_sha(worktree_dir)),
        )
    else:
        await emit("phase_started", task_id=task_id, phase="implementing")
        impl_prompt = f"""Task workspace: {task_dir}
Spec: {task_dir / 'spec.md'}
Plan: {task_dir / 'implement-plan.md'}
Checklist: {task_dir / 'implement-checklist.md'}
Worktree (where you write code): {worktree_dir}

Build command: {config.build_cmd}
Unit test command template: {config.unit_test_cmd}

The unit test command template contains a `{{only_testing:Target}}` token that
the harness will rewrite to run the XCTestCase classes found in the added or
modified test files in this worktree. For your own verification run, substitute
the token with `-only-testing:Target/YourClass` for each test class in the
added or modified test files you touch.

Implement the feature per the checklist. Ensure build + unit tests pass.
Write UI tests but don't run them — the harness runs them once in a dedicated
verification gate after impl review passes. Commit.
"""
        # Commit any pending workspace writes (state.json flipped to implementing
        # etc.) so the pre-implementor SHA reflects a clean tree. Without this,
        # auto-commit after the agent could bundle those harness-owned changes and
        # make the iteration look productive even when the implementor did nothing.
        _git_commit_workspace(worktree_dir, "pre-implementor workspace checkpoint")
        pre_impl_sha = _head_sha(worktree_dir)
        last_implementor_started_at = time.time()
        result = await A.run_agent(
            A.resolve_agent(A.IMPLEMENTOR, config),
            impl_prompt,
            cwd=worktree_dir,
            task_id=task_id,
            hooks=implementor_guard,
        )
        last_implementor_test_kinds = _test_kinds_from_tool_uses(result.tool_uses)
        initial_decision = _find_terminal_token(
            result.text, ("IMPLEMENT_DONE", "IMPLEMENT_BLOCKED")
        )
        if initial_decision == "IMPLEMENT_BLOCKED":
            return False
        if initial_decision != "IMPLEMENT_DONE":
            # 토큰 없음 = 중간 종료(max_turns 등) 또는 프로토콜 이탈.
            # reviewer 를 돌리면 false-pass 위험 → 즉시 escalation.
            await emit(
                "agent_ambiguous",
                task_id=task_id,
                phase="implementing",
                stop_reason=result.stop_reason,
                text_tail=_text_tail(result.text),
            )
            return False

        auto_committed = _maybe_auto_commit_worktree(worktree_dir, "implementor checkpoint")
        post_impl_sha = _head_sha(worktree_dir)
        if post_impl_sha == pre_impl_sha:
            await emit(
                "agent_stall",
                task_id=task_id,
                phase="implementing",
                head_sha=_short_sha(pre_impl_sha),
            )
            return False
        await emit(
            "iter_progress",
            task_id=task_id,
            phase="implementing",
            pre_sha=_short_sha(pre_impl_sha),
            post_sha=_short_sha(post_impl_sha),
            auto_committed=auto_committed,
        )

    for iteration in range(1, max_retries + 1):
        task_dir = await _set_state(config, task_id, "impl_review")
        await emit("phase_started", task_id=task_id, phase="impl_review", iteration=iteration)
        if last_implementor_test_kinds:
            try:
                _assert_test_artifacts_visible(
                    worktree_dir,
                    last_implementor_test_kinds,
                    last_implementor_started_at,
                )
            except DiagnosticInfrastructureError as exc:
                await _record_diagnostic_infra_missing(
                    task_dir,
                    task_id,
                    "impl_review",
                    exc,
                    iteration=iteration,
                )
                return False
        latest_feedback = _latest_feedback(_all_impl_feedback(task_dir))
        new_swift_files = discover_new_swift_files(worktree_dir, config.main_branch)
        unit_cmd, _ = await _resolve_test_commands(config, worktree_dir, task_id)
        reviewer_guard = W.make_path_guard(
            worktree_dir,
            task_id=task_id,
            bash_policy=_reviewer_bash_policy(config, unit_cmd),
        )
        reviewer_prompt = f"""Task workspace: {task_dir}
Spec: {task_dir / 'spec.md'}
Plan: {task_dir / 'implement-plan.md'}
Checklist: {task_dir / 'implement-checklist.md'}
Latest implement-feedback file (carries forward unresolved items from earlier iterations):
{_format_feedback_paths(latest_feedback)}
Worktree: {worktree_dir}
Iteration: {iteration}

Build command: {config.build_cmd}
Unit test command (scoped to XCTestCase classes in changed test files in this worktree): {unit_cmd}
New `.swift` files added in this worktree vs {config.main_branch}:
{_format_text_list(new_swift_files)}

Run the unit test command as given. If it is an `echo SKIP: ...` placeholder,
the harness has determined there are no changed unit test files in this
worktree — note the skip in your review and proceed; do not invent tests.
Do NOT run UI tests here; the harness runs them once in a dedicated
verification gate after this phase passes.

If PASS, write implement-review.md and respond IMPLEMENT_PASS.
If FAIL and reviewer patch is eligible, write implement-feedback-version-{iteration}.md, directly fix the code in the worktree, commit, and respond IMPLEMENT_FAIL.
If FAIL and reviewer patch is not eligible, write implement-feedback-version-{iteration}.md, do not edit code, and respond IMPLEMENT_REWORK_REQUIRED.

End your response with exactly one of IMPLEMENT_PASS, IMPLEMENT_FAIL, or
IMPLEMENT_REWORK_REQUIRED on its own line. If you cannot decide
confidently between FAIL (reviewer patch) and REWORK_REQUIRED, default to
IMPLEMENT_REWORK_REQUIRED — it routes the work to a fresh implementor pass
and is the safest fallback when in doubt. Leaving the response without a
terminal token forces user intervention.
"""
        reviewer_started_at = time.time()
        result = await A.run_agent(
            A.resolve_agent(A.IMPLEMENT_REVIEWER, config),
            reviewer_prompt,
            cwd=worktree_dir,
            task_id=task_id,
            iteration=iteration,
            hooks=reviewer_guard,
        )
        reviewer_test_kinds = _test_kinds_from_tool_uses(result.tool_uses)
        if reviewer_test_kinds:
            try:
                _assert_test_artifacts_visible(
                    worktree_dir,
                    reviewer_test_kinds,
                    reviewer_started_at,
                )
            except DiagnosticInfrastructureError as exc:
                await _record_diagnostic_infra_missing(
                    task_dir,
                    task_id,
                    "impl_review",
                    exc,
                    iteration=iteration,
                )
                return False
        review_decision = _find_terminal_token(
            result.text,
            ("IMPLEMENT_PASS", "IMPLEMENT_FAIL", "IMPLEMENT_REWORK_REQUIRED"),
        )
        if review_decision == "IMPLEMENT_PASS":
            return True
        if review_decision == "IMPLEMENT_FAIL":
            state = S.read_state(task_dir)
            state.impl_retries = iteration
            state.impl_version = iteration + 1
            S.write_state(task_dir, state)
            await emit("retry", task_id=task_id, phase="impl_review", iteration=iteration)
            continue
        if review_decision == "IMPLEMENT_REWORK_REQUIRED":
            state = S.read_state(task_dir)
            state.impl_retries = iteration
            state.impl_version = iteration + 1
            missing_artifact = _diagnostic_infra_signal(task_dir)
            if missing_artifact is not None:
                state.escalation = "diagnostic_infra_missing"
                S.write_state(task_dir, state)
                await emit(
                    "diagnostic_infra_missing",
                    task_id=task_id,
                    phase="impl_review",
                    iteration=iteration,
                    missing_path=missing_artifact,
                )
                return False
            S.write_state(task_dir, state)
            latest_rework_feedback = _latest_feedback(_all_impl_feedback(task_dir))
            task_dir = await _set_state(config, task_id, "implementing")
            rework_prompt = f"""Task workspace: {task_dir}
Spec: {task_dir / 'spec.md'}
Plan: {task_dir / 'implement-plan.md'}
Checklist: {task_dir / 'implement-checklist.md'}
Latest implement-feedback file (carries forward unresolved items from earlier iterations):
{_format_feedback_paths(latest_rework_feedback)}
Worktree (where you write code): {worktree_dir}

Build command: {config.build_cmd}
Unit test command template: {config.unit_test_cmd}

The unit test command template contains a `{{only_testing:Target}}` token that
the harness will rewrite to run the XCTestCase classes found in the added or
modified test files in this worktree. For your own verification run, substitute
the token with `-only-testing:Target/YourClass` for each test class in the
added or modified test files you touch.

A reviewer found issues that are not eligible for a direct reviewer patch.
Read the latest feedback and implement only the required changes in the worktree.
Ensure build + unit tests pass, and update UI tests if needed (the harness runs
UI tests once in a dedicated verification gate after this phase — do not run
them here).
Commit the rework and respond IMPLEMENT_DONE, or respond IMPLEMENT_BLOCKED if you cannot make it pass.
"""
            _git_commit_workspace(
                worktree_dir, f"pre-rework workspace checkpoint iter {iteration}"
            )
            pre_rework_sha = _head_sha(worktree_dir)
            rework_started_at = time.time()
            rework_result = await A.run_agent(
                A.resolve_agent(A.IMPLEMENTOR, config),
                rework_prompt,
                cwd=worktree_dir,
                task_id=task_id,
                iteration=iteration,
                hooks=implementor_guard,
            )
            last_implementor_test_kinds = _test_kinds_from_tool_uses(
                rework_result.tool_uses
            )
            last_implementor_started_at = rework_started_at
            rework_decision = _find_terminal_token(
                rework_result.text, ("IMPLEMENT_DONE", "IMPLEMENT_BLOCKED")
            )
            if rework_decision == "IMPLEMENT_BLOCKED":
                return False
            if rework_decision != "IMPLEMENT_DONE":
                await emit(
                    "agent_ambiguous",
                    task_id=task_id,
                    phase="impl_rework",
                    iteration=iteration,
                    stop_reason=rework_result.stop_reason,
                    text_tail=_text_tail(rework_result.text),
                )
                return False
            auto_committed = _maybe_auto_commit_worktree(
                worktree_dir, f"rework iter {iteration}"
            )
            post_rework_sha = _head_sha(worktree_dir)
            if post_rework_sha == pre_rework_sha:
                await emit(
                    "agent_stall",
                    task_id=task_id,
                    phase="impl_rework",
                    iteration=iteration,
                    head_sha=_short_sha(pre_rework_sha),
                )
                return False
            await emit(
                "iter_progress",
                task_id=task_id,
                phase="impl_rework",
                iteration=iteration,
                pre_sha=_short_sha(pre_rework_sha),
                post_sha=_short_sha(post_rework_sha),
                auto_committed=auto_committed,
            )
            await emit("retry", task_id=task_id, phase="impl_rework", iteration=iteration)
            continue
        await emit(
            "agent_ambiguous",
            task_id=task_id,
            phase="impl_review",
            iteration=iteration,
            stop_reason=result.stop_reason,
            text_tail=_text_tail(result.text),
        )
    return False


async def _run_ui_tests_once(
    task_id: str,
    task_dir: Path,
    worktree_dir: Path,
    ui_cmd: str,
) -> Optional[int]:
    """Run UI tests once via subprocess and verify diagnostic artifacts.

    Returns the subprocess exit code on a clean run (0 = pass, non-zero = fail).
    Returns None when an unparseable command or diagnostic-infrastructure
    failure has already triggered an escalation — caller should abort the phase.
    """
    started_at = time.time()
    try:
        argv = shlex.split(ui_cmd)
    except ValueError as exc:
        await emit(
            "ui_verify_failed",
            task_id=task_id,
            reason=f"unparseable ui command: {exc}",
        )
        state = S.read_state(task_dir)
        state.escalation = "ui_verification_failed"
        S.write_state(task_dir, state)
        return None

    proc = subprocess.run(argv, cwd=str(worktree_dir))

    try:
        _assert_test_artifacts_visible(worktree_dir, {"ui"}, started_at)
    except DiagnosticInfrastructureError as exc:
        # Tag the escalation as ui-verify-specific so resume routes back to the
        # gate (not back into impl_review) — same root cause, different phase.
        await _record_ui_verify_diagnostic_infra_missing(
            task_dir, task_id, "ui_verify", exc,
        )
        return None

    return proc.returncode


async def _run_ui_reviewer(
    config: HarnessConfig,
    task_id: str,
    task_dir: Path,
    worktree_dir: Path,
    iteration: int,
    unit_cmd: str,
    ui_cmd: str,
) -> tuple[Optional[str], A.AgentResult, bool]:
    """Invoke the implement-reviewer agent on a UI verification failure.

    Returns `(decision, result, diagnostics_ok)`. `decision` is one of
    IMPLEMENT_PASS / IMPLEMENT_FAIL / IMPLEMENT_REWORK_REQUIRED, or None when
    the agent's terminal token is missing or ambiguous. `diagnostics_ok` is
    False only when the reviewer ran a test command but fresh diagnostic
    artifacts were not visible.
    """
    latest_feedback = _latest_feedback(_all_impl_feedback(task_dir))
    feedback_version = _next_impl_feedback_version(task_dir)
    new_swift_files = discover_new_swift_files(worktree_dir, config.main_branch)
    reviewer_guard = W.make_path_guard(
        worktree_dir,
        task_id=task_id,
        bash_policy=_ui_reviewer_bash_policy(config, unit_cmd, ui_cmd),
    )
    reviewer_prompt = f"""Task workspace: {task_dir}
Spec: {task_dir / 'spec.md'}
Plan: {task_dir / 'implement-plan.md'}
Checklist: {task_dir / 'implement-checklist.md'}
Latest implement-feedback file (carries forward unresolved items from earlier iterations):
{_format_feedback_paths(latest_feedback)}
Worktree: {worktree_dir}
Iteration: {feedback_version}
UI retry iteration: {iteration}

The UI verification gate just failed. Unit tests already passed in
impl_review — this is specifically a UI test failure detected by the
publish-readiness gate.

Build command: {config.build_cmd}
Unit test command (already passed in impl_review; rerun only if you need to
verify a patch did not regress unit tests): {unit_cmd}
UI test command (rerun this after applying a patch to confirm the fix):
{ui_cmd}

New `.swift` files added in this worktree vs {config.main_branch}:
{_format_text_list(new_swift_files)}

Read the UI failure diagnostics first:
- .harness/test-results/last-ui-summary.txt
- .harness/test-results/last-ui-failures.txt
- .harness/test-results/last-ui-screenshot.png
- .harness/test-results/last-ui-environment.txt

If the failure is patch-eligible (small/localized — e.g. accessibility
identifiers, test selectors, scroll strategy, minor SwiftUI accessibility
tree adjustments), DIRECTLY edit the worktree to apply only the required
fix, re-run the UI test command to confirm, commit, write
implement-feedback-version-{feedback_version}.md, and respond IMPLEMENT_FAIL.

If the failure requires implementor rework (broader logic / architecture /
spec reinterpretation), do NOT edit code, write
implement-feedback-version-{feedback_version}.md describing the required changes,
and respond IMPLEMENT_REWORK_REQUIRED.

Do NOT respond IMPLEMENT_PASS — the UI tests just failed. The harness
auto-remaps any IMPLEMENT_PASS in this context to IMPLEMENT_FAIL and
re-runs UI tests in the next iteration to verify your patch.

End your response with exactly one of IMPLEMENT_FAIL or
IMPLEMENT_REWORK_REQUIRED on its own line. If you cannot decide between
the two, default to IMPLEMENT_REWORK_REQUIRED — leaving the response
without a terminal token will trigger ui_verify_review_ambiguous and
force the user to manually intervene.
"""
    reviewer_started_at = time.time()
    result = await A.run_agent(
        A.resolve_agent(A.IMPLEMENT_REVIEWER, config),
        reviewer_prompt,
        cwd=worktree_dir,
        task_id=task_id,
        iteration=feedback_version,
        hooks=reviewer_guard,
    )
    reviewer_test_kinds = _test_kinds_from_tool_uses(result.tool_uses)
    if reviewer_test_kinds:
        try:
            _assert_test_artifacts_visible(
                worktree_dir,
                reviewer_test_kinds,
                reviewer_started_at,
            )
        except DiagnosticInfrastructureError as exc:
            await _record_ui_verify_diagnostic_infra_missing(
                task_dir,
                task_id,
                "ui_verify_review",
                exc,
                iteration=iteration,
            )
            return None, result, False
    decision = _find_terminal_token(
        result.text,
        ("IMPLEMENT_PASS", "IMPLEMENT_FAIL", "IMPLEMENT_REWORK_REQUIRED"),
    )
    return decision, result, True


async def run_ui_verify_phase(
    config: HarnessConfig,
    task_id: str,
    task_dir: Path,
    worktree_dir: Path,
) -> "bool | str":
    """Run UI tests as a publish-readiness gate, with reviewer-driven retry.

    Return values:
      - True             — gate passed, proceed to publish
      - False            — gate failed, escalation written to state
      - "loopback"       — UI reviewer signaled IMPLEMENT_REWORK_REQUIRED and
                           the ui_to_impl loop counter is below max; caller
                           should re-run the impl phase. Counter and state
                           transitions are handled here.


    Pulled out of the impl_review iteration loop so UI tests don't run 1× per
    reviewer iteration. On failure, invokes the implement-reviewer agent to
    attempt a localized patch (accessibility identifiers, test selectors,
    minor SwiftUI tweaks) and retries up to `max_ui_review_iters` total
    iterations. Broader rework needs surface as a "loopback" signal so the
    pipeline re-runs the implementor phase, bounded by `max_ui_to_impl_loops`;
    once exhausted the gate escalates `ui_rework_loop_exhausted` for user
    intervention. With `max_ui_review_iters=1`, the reviewer is skipped and
    behavior matches the original single-shot gate.
    """
    await emit("phase_started", task_id=task_id, phase="ui_verify")
    unit_cmd, ui_cmd = await _resolve_test_commands(config, worktree_dir, task_id)

    if ui_cmd.lstrip().startswith("echo"):
        # No changed UI test files and no mandatory classes resolved → nothing to verify.
        await emit(
            "ui_verify_skipped",
            task_id=task_id,
            reason="no resolvable UI tests in this worktree",
        )
        return True

    state = S.read_state(task_dir)
    max_iters = max(1, state.max_ui_review_iters or config.default_max_ui_review_iters)

    for iteration in range(1, max_iters + 1):
        exit_code = await _run_ui_tests_once(task_id, task_dir, worktree_dir, ui_cmd)
        if exit_code is None:
            return False
        if exit_code == 0:
            await emit("ui_verify_passed", task_id=task_id, iteration=iteration)
            return True

        if iteration == max_iters:
            state = S.read_state(task_dir)
            state.escalation = (
                "ui_verify_review_exhausted" if iteration > 1 else "ui_verification_failed"
            )
            state.ui_review_retries = iteration
            S.write_state(task_dir, state)
            await emit(
                "ui_verify_failed",
                task_id=task_id,
                exit_code=exit_code,
                iteration=iteration,
                reason=state.escalation,
            )
            return False

        _maybe_auto_commit_worktree(
            worktree_dir, f"pre-ui-review workspace checkpoint iter {iteration}"
        )
        pre_review_sha = _head_sha(worktree_dir)
        decision, result, diagnostics_ok = await _run_ui_reviewer(
            config, task_id, task_dir, worktree_dir, iteration, unit_cmd, ui_cmd,
        )
        if not diagnostics_ok:
            return False
        if decision == "IMPLEMENT_PASS":
            # UI tests just failed but reviewer said PASS — protocol
            # violation. Remap to IMPLEMENT_FAIL so the next iteration
            # re-runs UI tests and verifies any patch the reviewer made.
            # If no patch was applied, the FAIL path's SHA check will
            # surface ui_verify_review_stalled.
            await emit(
                "agent_protocol_violation",
                task_id=task_id,
                phase="ui_verify_review",
                iteration=iteration,
                original_decision="IMPLEMENT_PASS",
                remapped_to="IMPLEMENT_FAIL",
                text_tail=_text_tail(result.text),
            )
            decision = "IMPLEMENT_FAIL"
        if decision == "IMPLEMENT_FAIL":
            auto_committed = _maybe_auto_commit_worktree(
                worktree_dir, f"ui verify reviewer patch iter {iteration}"
            )
            post_review_sha = _head_sha(worktree_dir)
            if post_review_sha == pre_review_sha:
                state = S.read_state(task_dir)
                state.escalation = "ui_verify_review_stalled"
                state.ui_review_retries = iteration
                S.write_state(task_dir, state)
                await emit(
                    "agent_stall",
                    task_id=task_id,
                    phase="ui_verify_review",
                    iteration=iteration,
                    head_sha=_short_sha(pre_review_sha),
                )
                return False
            state = S.read_state(task_dir)
            state.ui_review_retries = iteration
            S.write_state(task_dir, state)
            await emit(
                "iter_progress",
                task_id=task_id,
                phase="ui_verify_review",
                iteration=iteration,
                pre_sha=_short_sha(pre_review_sha),
                post_sha=_short_sha(post_review_sha),
                auto_committed=auto_committed,
            )
            await emit(
                "retry",
                task_id=task_id,
                phase="ui_verify_review",
                iteration=iteration,
            )
            continue
        if decision == "IMPLEMENT_REWORK_REQUIRED":
            state = S.read_state(task_dir)
            state.ui_review_retries = iteration
            max_loops = state.max_ui_to_impl_loops or config.default_max_ui_to_impl_loops
            if state.ui_to_impl_loops < max_loops:
                # Auto-route back to implementor: the UI reviewer wrote
                # implement-feedback-version-{N}.md describing the required
                # changes; run_impl_phase will pick it up. Counter prevents
                # ui→impl→ui infinite cycles.
                state.ui_to_impl_loops += 1
                state.escalation = None
                S.write_state(task_dir, state)
                await emit(
                    "ui_verify_rework_loopback",
                    task_id=task_id,
                    iteration=iteration,
                    loop=state.ui_to_impl_loops,
                    max_loops=max_loops,
                )
                return "loopback"
            state.escalation = "ui_verify_rework_loop_exhausted"
            S.write_state(task_dir, state)
            await emit(
                "ui_verify_failed",
                task_id=task_id,
                exit_code=exit_code,
                iteration=iteration,
                reason="rework_loop_exhausted",
                loop=state.ui_to_impl_loops,
            )
            return False
        # Missing token — reviewer didn't reach a decision.
        state = S.read_state(task_dir)
        state.escalation = "ui_verify_review_ambiguous"
        state.ui_review_retries = iteration
        S.write_state(task_dir, state)
        await emit(
            "agent_ambiguous",
            task_id=task_id,
            phase="ui_verify_review",
            iteration=iteration,
            stop_reason=result.stop_reason,
            text_tail=_text_tail(result.text),
        )
        return False
    return False


async def run_publish_phase(
    config: HarnessConfig,
    task_id: str,
    task_dir: Path,
    worktree_dir: Path,
) -> bool:
    guard = W.make_path_guard(
        worktree_dir,
        task_id=task_id,
        bash_policy=_publish_bash_policy(task_id),
    )
    await emit("phase_started", task_id=task_id, phase="publishing")
    branch = W.worktree_branch(task_id)
    pub_prompt = f"""Task workspace: {task_dir}
Worktree: {worktree_dir}
Feature branch: {branch}
Base branch: {config.main_branch}
GitHub repo: {config.github_repo or '(not configured — push only and skip gh)'}

Push the branch and open a PR via gh. Write pr.md in the task workspace.
Respond PUBLISH_DONE or PUBLISH_BLOCKED.
"""
    result = await A.run_agent(
        A.resolve_agent(A.PUBLISHER, config),
        pub_prompt,
        cwd=worktree_dir,
        task_id=task_id,
        hooks=guard,
    )
    decision = _find_terminal_token(result.text, ("PUBLISH_DONE", "PUBLISH_BLOCKED"))
    if decision == "PUBLISH_DONE":
        return True
    if decision is None:
        await emit(
            "agent_ambiguous",
            task_id=task_id,
            phase="publishing",
            stop_reason=result.stop_reason,
            text_tail=_text_tail(result.text),
        )
    return False


def _resume_phase_index(state: S.TaskState) -> int:
    """Returns which phase to start from: 0=plan, 1=impl, 2=ui_verify, 3=publish."""
    if state.state in ("planning", "plan_review", "todo", "draft"):
        return 0
    if state.state in ("implementing", "impl_review"):
        return 1
    if state.state == "ui_verify":
        return 2
    if state.state == "publishing":
        return 3
    if state.state == "paused":
        if state.paused_from in ("planning", "plan_review"):
            return 0
        if state.paused_from in ("implementing", "impl_review"):
            return 1
        if state.paused_from == "ui_verify":
            return 2
        if state.paused_from == "publishing":
            return 3
        return 0
    if state.state == "needs_attention":
        esc = (state.escalation or "").lower()
        if esc == "main_merge_conflict":
            if state.paused_from in ("implementing", "impl_review"):
                return 1
            if state.paused_from == "ui_verify":
                return 2
            if state.paused_from == "publishing":
                return 3
            return 0
        if "plan" in esc:
            return 0
        # ui_verify-specific escalations route back to the UI gate.
        if "ui_verif" in esc:
            return 2
        if "impl" in esc or esc == "diagnostic_infra_missing":
            return 1
        if "publish" in esc:
            return 3
        return 0
    return 0


def _clear_escalation(task_dir: Path) -> None:
    state = S.read_state(task_dir)
    if state.escalation is None:
        return
    state.escalation = None
    S.write_state(task_dir, state)


def _unexpected_escalation_token(phase: str) -> str:
    return UNEXPECTED_ESCALATIONS.get(phase, UNEXPECTED_ESCALATIONS["plan"])


async def _recover_unexpected_pipeline_error(
    config: HarnessConfig,
    task_id: str,
    phase: str,
    error: Exception,
) -> None:
    token = _unexpected_escalation_token(phase)
    try:
        workspace = S.find_task_workspace(config, task_id)
    except Exception:
        workspace = None
    if workspace is not None:
        try:
            task_dir = await _set_state(config, task_id, "needs_attention")
            state = S.read_state(task_dir)
            state.escalation = token
            S.write_state(task_dir, state)
        except Exception:
            pass
    await emit(
        "escalation",
        task_id=task_id,
        phase=phase,
        escalation=token,
        error_type=type(error).__name__,
        error_message=str(error),
    )


async def _prepare_resume_state(
    config: HarnessConfig,
    task_id: str,
    task_dir: Path,
    state: S.TaskState,
    resume_phase: int,
) -> Path:
    target_state: S.StateName = ("planning", "implementing", "ui_verify", "publishing")[resume_phase]
    if state.state != target_state:
        task_dir = await _set_state(config, task_id, target_state)
    _clear_escalation(task_dir)

    # Pull main into the worktree so resumed tasks pick up tooling/harness
    # improvements that landed after the worktree was created. Conflicts
    # escalate to needs_attention; other git failures bubble up as unexpected
    # errors handled by run_pipeline's top-level recovery path.
    try:
        result = W.sync_worktree_with_main(config, task_id)
        await emit("main_sync", task_id=task_id, result=result)
    except W.MainMergeConflictError as exc:
        await emit("main_sync_conflict", task_id=task_id, detail=str(exc))
        # S.transition clears paused_from for non-paused states, so store this
        # phase hint after moving to needs_attention. A later resume uses it to
        # return to the phase where main sync was attempted.
        task_dir = await _set_state(config, task_id, "needs_attention")
        s = S.read_state(task_dir)
        s.escalation = "main_merge_conflict"
        s.paused_from = target_state
        S.write_state(task_dir, s)
        raise

    return task_dir


async def run_pipeline(
    config: HarnessConfig,
    task_id: str,
    *,
    max_plan_retries: Optional[int] = None,
    max_impl_retries: Optional[int] = None,
    worktree_base: str = "local",
    resume_from: Optional[str] = None,
) -> None:
    """Run or resume the task pipeline.

    `resume_from` overrides which phase a resumed run enters at:
      - None              → auto-route via state.escalation / state.state
      - "impl_review"     → enter phase 1 with implementor skipped (re-run reviewer only)
      - "ui_verify"       → enter phase 2 (publish-readiness gate) regardless of state
    Both explicit values require a workspace state.json to exist; otherwise
    the pipeline aborts rather than falling through to a fresh start.
    Endpoint-level validation (worktree reusable, commits ahead of main) is
    enforced at /api/tasks/{id}/resume before this function is called.
    """
    max_plan_retries = max_plan_retries or config.default_max_plan_retries
    max_impl_retries = max_impl_retries or config.default_max_impl_retries

    run_id = str(uuid.uuid4())
    run_token = set_current_run_id(run_id)
    current_phase = PHASE_NAMES[0]
    try:
        await emit("pipeline_started", task_id=task_id)

        worktree_path = config.worktree_path(task_id)

        # 최우선: 기존 워크트리가 재사용 가능하면 그대로 사용하고,
        # 없을 때만 정리/생성한다.
        worktree_reusable = W.worktree_is_reusable(config, task_id)
        if not worktree_reusable and worktree_path.exists():
            W.cleanup_orphaned_worktree(config, task_id)
        if not worktree_reusable:
            # Fresh create. Use user-selected base; branch may exist from a prior run.
            W.create_worktree(config, task_id, base=worktree_base)

        worktree_dir = W.project_worktree_path(config, task_id)

        # Decide: resume vs fresh based on workspace state.json
        workspace = S.find_task_workspace(config, task_id)
        state_file = (workspace / "state.json") if workspace is not None else None

        is_resume = False
        if workspace is not None and state_file is not None and state_file.exists():
            state = S.read_state(workspace)
            resume_phase = _resume_phase_index(state)
            if resume_from == "ui_verify":
                # Explicit override: re-enter the publish-readiness gate even
                # if state.state would have routed elsewhere. Validation that
                # the worktree is reusable + ahead of main is enforced at the
                # /resume endpoint. Reset ui-side counters so the user's
                # manual fix gets a fresh allowance (loop counter and the
                # iteration counter both restart from 0).
                resume_phase = 2
                if state.ui_review_retries or state.ui_to_impl_loops:
                    state.ui_review_retries = 0
                    state.ui_to_impl_loops = 0
                    S.write_state(workspace, state)
            current_phase = PHASE_NAMES[resume_phase]
            await emit("pipeline_resuming", task_id=task_id, state=state.state)
            try:
                task_dir = await _prepare_resume_state(
                    config, task_id, workspace, state, resume_phase
                )
            except W.MainMergeConflictError:
                # _prepare_resume_state has already flipped state.escalation =
                # "main_merge_conflict" and set state to needs_attention. Skip
                # the rest of the pipeline; resuming after the user resolves
                # the conflict will re-enter at the same phase.
                return
            if resume_phase > 0:
                await emit(
                    "plan_steps",
                    task_id=task_id,
                    steps=parse_plan_file(task_dir / "implement-plan.md"),
                )
            is_resume = True
        else:
            # Fresh start. If the caller asked for a phase-specific resume but
            # the workspace state is gone, refuse to silently restart from
            # plan — that would discard the user's intent and rerun unrelated
            # phases.
            if resume_from is not None:
                raise RuntimeError(
                    f"resume_from={resume_from!r} requested but no workspace "
                    f"state found for task {task_id!r}; aborting instead of "
                    f"falling through to a fresh plan-phase start."
                )
            # Fresh: bootstrap workspace inside worktree, commit spec.md + state.json on feature branch.
            S.ensure_workspace(config, task_id)
            task_dir = await _set_state(config, task_id, "planning")
            state = S.read_state(task_dir)
            state.max_plan_retries = max_plan_retries
            state.max_impl_retries = max_impl_retries
            state.branch = W.worktree_branch(task_id)
            S.write_state(task_dir, state)
            _git_commit_workspace(worktree_dir, f"Bootstrap task workspace for {task_id}")
            resume_phase = 0

        async with ImplPhaseEventLogger(task_id, task_dir):
            # Plan phase
            current_phase = PHASE_NAMES[0]
            if resume_phase <= 0:
                skip_planner = is_resume and (task_dir / "implement-plan.md").exists()
                plan_ok = await run_plan_phase(
                    config, task_id, task_dir, worktree_dir, max_plan_retries,
                    skip_planner=skip_planner,
                )
                if not plan_ok:
                    s = S.read_state(task_dir)
                    s.escalation = "plan_review_exhausted"
                    S.write_state(task_dir, s)
                    await _set_state(config, task_id, "needs_attention")
                    await emit("escalation", task_id=task_id, phase="plan_review")
                    return

            # Implement + UI verify phases (with ui→impl loopback support)
            #
            # When the UI reviewer signals IMPLEMENT_REWORK_REQUIRED and the
            # ui_to_impl loop counter is below max, run_ui_verify_phase returns
            # "loopback" and we re-enter the impl phase to consume the
            # implement-feedback file written by the UI reviewer. The counter
            # caps automatic ui→impl→ui cycles before escalation.
            loop_resume = resume_phase
            while True:
                # Implement phase
                current_phase = PHASE_NAMES[1]
                if loop_resume <= 1:
                    if not (is_resume and loop_resume == 1):
                        task_dir = await _set_state(config, task_id, "implementing")
                    skip_implementor = (
                        is_resume
                        and loop_resume == 1
                        and resume_from == "impl_review"
                    )
                    if skip_implementor:
                        impl_ok = await run_impl_phase(
                            config,
                            task_id,
                            task_dir,
                            worktree_dir,
                            max_impl_retries,
                            skip_implementor=True,
                        )
                    else:
                        impl_ok = await run_impl_phase(
                            config,
                            task_id,
                            task_dir,
                            worktree_dir,
                            max_impl_retries,
                        )
                    if not impl_ok:
                        s = S.read_state(task_dir)
                        if s.escalation is None:
                            s.escalation = "impl_review_exhausted"
                            S.write_state(task_dir, s)
                        await _set_state(config, task_id, "needs_attention")
                        await emit(
                            "escalation",
                            task_id=task_id,
                            phase="impl_review",
                            escalation=s.escalation,
                        )
                        return

                # UI verify phase (publish-readiness gate; runs UI tests once)
                current_phase = PHASE_NAMES[2]
                if loop_resume <= 2:
                    if not (is_resume and loop_resume == 2):
                        task_dir = await _set_state(config, task_id, "ui_verify")
                    ui_ok = await run_ui_verify_phase(
                        config, task_id, task_dir, worktree_dir
                    )
                    if ui_ok == "loopback":
                        # run_ui_verify_phase already incremented counter and
                        # cleared escalation. Reset cycle-local resume flags so
                        # the next impl iteration runs fresh.
                        loop_resume = 1
                        is_resume = False
                        resume_from = None
                        continue
                    if not ui_ok:
                        s = S.read_state(task_dir)
                        if s.escalation is None:
                            s.escalation = "ui_verification_failed"
                            S.write_state(task_dir, s)
                        await _set_state(config, task_id, "needs_attention")
                        await emit(
                            "escalation",
                            task_id=task_id,
                            phase="ui_verify",
                            escalation=s.escalation,
                        )
                        return
                break

            # Publish phase
            current_phase = PHASE_NAMES[3]
            if resume_phase <= 3:
                if not (is_resume and resume_phase == 3):
                    task_dir = await _set_state(config, task_id, "publishing")
                pub_ok = await run_publish_phase(config, task_id, task_dir, worktree_dir)
                if not pub_ok:
                    s = S.read_state(task_dir)
                    s.escalation = "publish_failed"
                    S.write_state(task_dir, s)
                    await _set_state(config, task_id, "needs_attention")
                    await emit("escalation", task_id=task_id, phase="publishing")
                    return

            # Done — workspace is moved from ongoing/ to done/ inside the worktree.
            task_dir = await _set_state(config, task_id, "done")
            await emit("pipeline_done", task_id=task_id)
    except Exception as error:
        await _recover_unexpected_pipeline_error(config, task_id, current_phase, error)
    finally:
        reset_current_run_id(run_token)
