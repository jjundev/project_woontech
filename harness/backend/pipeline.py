"""Pipeline orchestration with GAN loops for plan-review and implement-review."""
from __future__ import annotations

import re
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Optional

from . import agents as A
from . import state as S
from . import worktree as W
from .config import HarnessConfig
from .event_log import ImplPhaseEventLogger
from .events import emit
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
PHASE_NAMES = ("plan", "impl", "publish")
UNEXPECTED_ESCALATIONS = {
    "plan": "plan_unexpected_error",
    "impl": "impl_unexpected_error",
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


def _reviewer_bash_policy(config: HarnessConfig, unit_cmd: str, ui_cmd: str) -> W.BashPolicy:
    return _merge_bash_policy(
        _common_git_bash_policy(),
        exact=(
            _tokenize_command(config.build_cmd),
            _tokenize_command(unit_cmd),
            _tokenize_command(ui_cmd),
        ),
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
    ui = inject_only_testing(config.ui_test_cmd, changed.get("WoontechUITests", []))
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
) -> bool:
    """Return True on pass, False on escalation."""
    guard = W.make_path_guard(worktree_dir, task_id=task_id)
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
    if skip_implementor:
        await emit(
            "impl_skipped",
            task_id=task_id,
            reason="user_resume_from_review",
            head_sha=_short_sha(_head_sha(worktree_dir)),
        )
    else:
        implementor_guard = W.make_path_guard(
            worktree_dir,
            task_id=task_id,
            bash_policy=_implementor_bash_policy(config),
        )
        await emit("phase_started", task_id=task_id, phase="implementing")
        impl_prompt = f"""Task workspace: {task_dir}
Spec: {task_dir / 'spec.md'}
Plan: {task_dir / 'implement-plan.md'}
Checklist: {task_dir / 'implement-checklist.md'}
Worktree (where you write code): {worktree_dir}

Build command: {config.build_cmd}
Unit test command template: {config.unit_test_cmd}
UI test command template (DO NOT run): {config.ui_test_cmd}

The test command templates contain a `{{only_testing:Target}}` token that the
harness will rewrite to run the XCTestCase classes found in the added or
modified test files in this worktree. For your own verification run, substitute
the token with `-only-testing:Target/YourClass` for each test class in the
added or modified test files you touch.

Implement the feature per the checklist. Ensure build + unit tests pass.
Write UI tests but don't run them. Commit.
"""
        # Commit any pending workspace writes (state.json flipped to implementing
        # etc.) so the pre-implementor SHA reflects a clean tree. Without this,
        # auto-commit after the agent could bundle those harness-owned changes and
        # make the iteration look productive even when the implementor did nothing.
        _git_commit_workspace(worktree_dir, "pre-implementor workspace checkpoint")
        pre_impl_sha = _head_sha(worktree_dir)
        result = await A.run_agent(
            A.resolve_agent(A.IMPLEMENTOR, config),
            impl_prompt,
            cwd=worktree_dir,
            task_id=task_id,
            hooks=implementor_guard,
        )
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
        await emit("phase_started", task_id=task_id, phase="impl_review", iteration=iteration)
        latest_feedback = _latest_feedback(_all_impl_feedback(task_dir))
        new_swift_files = discover_new_swift_files(worktree_dir, config.main_branch)
        unit_cmd, ui_cmd = await _resolve_test_commands(config, worktree_dir, task_id)
        reviewer_guard = W.make_path_guard(
            worktree_dir,
            task_id=task_id,
            bash_policy=_reviewer_bash_policy(config, unit_cmd, ui_cmd),
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
UI test command (scoped to XCTestCase classes in changed test files in this worktree; RUN IT): {ui_cmd}
New `.swift` files added in this worktree vs {config.main_branch}:
{_format_text_list(new_swift_files)}

Run the commands as given. If the command is an `echo SKIP: ...` placeholder,
the harness has determined there are no changed test files for that target in
this worktree —
note the skip in your review and proceed; do not invent tests.

If PASS, write implement-review.md and respond IMPLEMENT_PASS.
If FAIL and reviewer patch is eligible, write implement-feedback-version-{iteration}.md, directly fix the code in the worktree, commit, and respond IMPLEMENT_FAIL.
If FAIL and reviewer patch is not eligible, write implement-feedback-version-{iteration}.md, do not edit code, and respond IMPLEMENT_REWORK_REQUIRED.
"""
        result = await A.run_agent(
            A.resolve_agent(A.IMPLEMENT_REVIEWER, config),
            reviewer_prompt,
            cwd=worktree_dir,
            task_id=task_id,
            iteration=iteration,
            hooks=reviewer_guard,
        )
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
            S.write_state(task_dir, state)
            latest_rework_feedback = _latest_feedback(_all_impl_feedback(task_dir))
            rework_prompt = f"""Task workspace: {task_dir}
Spec: {task_dir / 'spec.md'}
Plan: {task_dir / 'implement-plan.md'}
Checklist: {task_dir / 'implement-checklist.md'}
Latest implement-feedback file (carries forward unresolved items from earlier iterations):
{_format_feedback_paths(latest_rework_feedback)}
Worktree (where you write code): {worktree_dir}

Build command: {config.build_cmd}
Unit test command template: {config.unit_test_cmd}
UI test command template (DO NOT run): {config.ui_test_cmd}

The test command templates contain a `{{only_testing:Target}}` token that the
harness will rewrite to run the XCTestCase classes found in the added or
modified test files in this worktree. For your own verification run, substitute
the token with `-only-testing:Target/YourClass` for each test class in the
added or modified test files you touch.

A reviewer found issues that are not eligible for a direct reviewer patch.
Read the latest feedback and implement only the required changes in the worktree.
Ensure build + unit tests pass, update UI tests if needed, but do not run UI tests.
Commit the rework and respond IMPLEMENT_DONE, or respond IMPLEMENT_BLOCKED if you cannot make it pass.
"""
            _git_commit_workspace(
                worktree_dir, f"pre-rework workspace checkpoint iter {iteration}"
            )
            pre_rework_sha = _head_sha(worktree_dir)
            rework_result = await A.run_agent(
                A.resolve_agent(A.IMPLEMENTOR, config),
                rework_prompt,
                cwd=worktree_dir,
                task_id=task_id,
                iteration=iteration,
                hooks=implementor_guard,
            )
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
    """Returns which phase to start from: 0=plan, 1=impl, 2=publish."""
    if state.state in ("planning", "plan_review", "todo", "draft"):
        return 0
    if state.state in ("implementing", "impl_review"):
        return 1
    if state.state == "publishing":
        return 2
    if state.state == "paused":
        if state.paused_from in ("planning", "plan_review"):
            return 0
        if state.paused_from in ("implementing", "impl_review"):
            return 1
        if state.paused_from == "publishing":
            return 2
        return 0
    if state.state == "needs_attention":
        esc = (state.escalation or "").lower()
        if "plan" in esc:
            return 0
        if "impl" in esc:
            return 1
        if "publish" in esc:
            return 2
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
    target_state = ("planning", "implementing", "publishing")[resume_phase]
    if state.state != target_state:
        task_dir = await _set_state(config, task_id, target_state)
    _clear_escalation(task_dir)
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
    max_plan_retries = max_plan_retries or config.default_max_plan_retries
    max_impl_retries = max_impl_retries or config.default_max_impl_retries

    await emit("pipeline_started", task_id=task_id)

    current_phase = PHASE_NAMES[0]
    try:
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
            current_phase = PHASE_NAMES[resume_phase]
            await emit("pipeline_resuming", task_id=task_id, state=state.state)
            task_dir = await _prepare_resume_state(config, task_id, workspace, state, resume_phase)
            is_resume = True
        else:
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
                plan_ok = await run_plan_phase(config, task_id, task_dir, worktree_dir, max_plan_retries)
                if not plan_ok:
                    s = S.read_state(task_dir)
                    s.escalation = "plan_review_exhausted"
                    S.write_state(task_dir, s)
                    await _set_state(config, task_id, "needs_attention")
                    await emit("escalation", task_id=task_id, phase="plan_review")
                    return

            # Implement phase
            current_phase = PHASE_NAMES[1]
            if resume_phase <= 1:
                if not (is_resume and resume_phase == 1):
                    task_dir = await _set_state(config, task_id, "implementing")
                skip_implementor = (
                    is_resume and resume_phase == 1 and resume_from == "impl_review"
                )
                impl_ok = await run_impl_phase(
                    config,
                    task_id,
                    task_dir,
                    worktree_dir,
                    max_impl_retries,
                    skip_implementor=skip_implementor,
                )
                if not impl_ok:
                    s = S.read_state(task_dir)
                    s.escalation = "impl_review_exhausted"
                    S.write_state(task_dir, s)
                    await _set_state(config, task_id, "needs_attention")
                    await emit("escalation", task_id=task_id, phase="impl_review")
                    return

            # Publish phase
            current_phase = PHASE_NAMES[2]
            if resume_phase <= 2:
                if not (is_resume and resume_phase == 2):
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
