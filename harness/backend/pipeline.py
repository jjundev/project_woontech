"""Pipeline orchestration with GAN loops for plan-review and implement-review."""
from __future__ import annotations

import re
import subprocess
from pathlib import Path
from typing import Optional

from . import agents as A
from . import state as S
from . import worktree as W
from .config import HarnessConfig
from .events import emit


CLASS_RE = re.compile(r"class\s+(\w+)\s*:\s*[^\{]*XCTestCase")
ONLY_TESTING_TOKEN_RE = re.compile(r"\{only_testing:(\w+)\}")


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


def _latest_feedback(paths: list[Path]) -> list[Path]:
    """Return only the most recent feedback file. Reviewers should use it as a
    rolling ledger: each new feedback file carries forward the unresolved items
    from prior iterations. Keeps prompt size O(1) instead of O(iterations)."""
    return paths[-1:] if paths else []


def _has_token(text: str, token: str) -> bool:
    return any(line.strip() == token for line in text.splitlines())


async def _set_state(config: HarnessConfig, task_id: str, new_state: str) -> Path:
    task_dir = S.transition(config, task_id, new_state)  # type: ignore[arg-type]
    await emit("state_changed", task_id=task_id, state=new_state)
    return task_dir


# ---------------------------------------------------------------------------
# Worktree-only test discovery and command injection
# ---------------------------------------------------------------------------


def _git_out(args: list[str], cwd: Path) -> str:
    r = subprocess.run(["git", *args], cwd=str(cwd), capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""


def discover_new_test_classes(worktree_dir: Path, base_branch: str) -> dict[str, list[str]]:
    """Return newly-added XCTestCase classes per target.

    "Newly added" = files added (not merely modified) vs {base_branch}...HEAD,
    plus untracked (`?? ...`) files in the worktree. Pre-existing test files
    that were merely modified are NOT included — their classes should not run.
    """
    files: set[str] = set()
    for line in _git_out(
        ["diff", "--name-only", "--diff-filter=A", f"{base_branch}...HEAD"],
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
    new = discover_new_test_classes(worktree_dir, config.main_branch)
    unit = inject_only_testing(config.unit_test_cmd, new.get("WoontechTests", []))
    ui = inject_only_testing(config.ui_test_cmd, new.get("WoontechUITests", []))
    if unit is None:
        await emit(
            "tests_skipped",
            task_id=task_id,
            target="WoontechTests",
            reason="no new tests in this worktree",
        )
        unit = "echo 'SKIP: no new unit tests in this worktree'"
    if ui is None:
        await emit(
            "tests_skipped",
            task_id=task_id,
            target="WoontechUITests",
            reason="no new tests in this worktree",
        )
        ui = "echo 'SKIP: no new ui tests in this worktree'"
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
    guard = W.make_path_guard(worktree_dir, task_dir, task_id=task_id)
    # Planner writes v1
    await emit("phase_started", task_id=task_id, phase="planning")
    planner_prompt = f"""Task folder: {task_dir}
Spec file: {task_dir / 'spec.md'}
Worktree (read-only reference for code structure): {worktree_dir}

Write implement-plan.md v1 in the task folder.
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
        reviewer_prompt = f"""Task folder: {task_dir}
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
        if _has_token(result.text, "PLAN_PASS"):
            return True
        if _has_token(result.text, "PLAN_FAIL"):
            state = S.read_state(task_dir)
            state.plan_retries = iteration
            state.plan_version = iteration + 1
            S.write_state(task_dir, state)
            await emit("retry", task_id=task_id, phase="plan_review", iteration=iteration)
            continue
        # ambiguous response — treat as fail and continue
        await emit("agent_ambiguous", task_id=task_id, phase="plan_review", iteration=iteration)
    # Exhausted
    return False


async def run_impl_phase(
    config: HarnessConfig,
    task_id: str,
    task_dir: Path,
    worktree_dir: Path,
    max_retries: int,
) -> bool:
    guard = W.make_path_guard(worktree_dir, task_dir, task_id=task_id)
    await emit("phase_started", task_id=task_id, phase="implementing")
    impl_prompt = f"""Task folder: {task_dir}
Spec: {task_dir / 'spec.md'}
Plan: {task_dir / 'implement-plan.md'}
Checklist: {task_dir / 'implement-checklist.md'}
Worktree (where you write code): {worktree_dir}

Build command: {config.build_cmd}
Unit test command template: {config.unit_test_cmd}
UI test command template (DO NOT run): {config.ui_test_cmd}

The test command templates contain a `{{only_testing:Target}}` token that the
harness will rewrite to run only the new test classes you author. For your own
verification run, substitute the token with `-only-testing:Target/YourClass`
for each new test class you add.

Implement the feature per the checklist. Ensure build + unit tests pass.
Write UI tests but don't run them. Commit.
"""
    result = await A.run_agent(
        A.resolve_agent(A.IMPLEMENTOR, config),
        impl_prompt,
        cwd=worktree_dir,
        task_id=task_id,
        hooks=guard,
    )
    if _has_token(result.text, "IMPLEMENT_BLOCKED"):
        return False

    for iteration in range(1, max_retries + 1):
        await emit("phase_started", task_id=task_id, phase="impl_review", iteration=iteration)
        latest_feedback = _latest_feedback(_all_impl_feedback(task_dir))
        unit_cmd, ui_cmd = await _resolve_test_commands(config, worktree_dir, task_id)
        reviewer_prompt = f"""Task folder: {task_dir}
Spec: {task_dir / 'spec.md'}
Plan: {task_dir / 'implement-plan.md'}
Checklist: {task_dir / 'implement-checklist.md'}
Latest implement-feedback file (carries forward unresolved items from earlier iterations):
{_format_feedback_paths(latest_feedback)}
Worktree: {worktree_dir}
Iteration: {iteration}

Build command: {config.build_cmd}
Unit test command (scoped to tests created in this worktree): {unit_cmd}
UI test command (scoped to tests created in this worktree; RUN IT): {ui_cmd}

Run the commands as given. If the command is an `echo SKIP: ...` placeholder,
the harness has determined there are no newly-authored tests for that target —
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
            hooks=guard,
        )
        if _has_token(result.text, "IMPLEMENT_PASS"):
            return True
        if _has_token(result.text, "IMPLEMENT_FAIL"):
            state = S.read_state(task_dir)
            state.impl_retries = iteration
            state.impl_version = iteration + 1
            S.write_state(task_dir, state)
            await emit("retry", task_id=task_id, phase="impl_review", iteration=iteration)
            continue
        if _has_token(result.text, "IMPLEMENT_REWORK_REQUIRED"):
            state = S.read_state(task_dir)
            state.impl_retries = iteration
            state.impl_version = iteration + 1
            S.write_state(task_dir, state)
            latest_rework_feedback = _latest_feedback(_all_impl_feedback(task_dir))
            rework_prompt = f"""Task folder: {task_dir}
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
harness will rewrite to run only the new test classes you author. For your own
verification run, substitute the token with `-only-testing:Target/YourClass`
for each new test class you add.

A reviewer found issues that are not eligible for a direct reviewer patch.
Read the latest feedback and implement only the required changes in the worktree.
Ensure build + unit tests pass, update UI tests if needed, but do not run UI tests.
Commit the rework and respond IMPLEMENT_DONE, or respond IMPLEMENT_BLOCKED if you cannot make it pass.
"""
            rework_result = await A.run_agent(
                A.resolve_agent(A.IMPLEMENTOR, config),
                rework_prompt,
                cwd=worktree_dir,
                task_id=task_id,
                iteration=iteration,
                hooks=guard,
            )
            if _has_token(rework_result.text, "IMPLEMENT_BLOCKED"):
                return False
            await emit("retry", task_id=task_id, phase="impl_rework", iteration=iteration)
            continue
        await emit("agent_ambiguous", task_id=task_id, phase="impl_review", iteration=iteration)
    return False


async def run_publish_phase(
    config: HarnessConfig,
    task_id: str,
    task_dir: Path,
    worktree_dir: Path,
) -> bool:
    guard = W.make_path_guard(worktree_dir, task_dir, task_id=task_id)
    await emit("phase_started", task_id=task_id, phase="publishing")
    branch = W.worktree_branch(task_id)
    pub_prompt = f"""Task folder: {task_dir}
Worktree: {worktree_dir}
Feature branch: {branch}
Base branch: {config.main_branch}
GitHub repo: {config.github_repo or '(not configured — push only and skip gh)'}

Push the branch and open a PR via gh. Write pr.md. Respond PUBLISH_DONE or PUBLISH_BLOCKED.
"""
    result = await A.run_agent(
        A.resolve_agent(A.PUBLISHER, config),
        pub_prompt,
        cwd=worktree_dir,
        task_id=task_id,
        hooks=guard,
    )
    return _has_token(result.text, "PUBLISH_DONE")


def _resume_phase_index(state: S.TaskState) -> int:
    """Returns which phase to start from: 0=plan, 1=impl, 2=publish."""
    if state.state in ("planning", "plan_review", "todo", "draft"):
        return 0
    if state.state in ("implementing", "impl_review"):
        return 1
    if state.state == "publishing":
        return 2
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
) -> None:
    max_plan_retries = max_plan_retries or config.default_max_plan_retries
    max_impl_retries = max_impl_retries or config.default_max_impl_retries

    await emit("pipeline_started", task_id=task_id)

    worktree_path = config.worktree_path(task_id)
    is_resume = False
    if worktree_path.exists():
        # Worktree already exists — read persisted state and resume from the right phase.
        task_dir = S.find_task_dir(config, task_id)
        state = S.read_state(task_dir)
        resume_phase = _resume_phase_index(state)
        await emit("pipeline_resuming", task_id=task_id, state=state.state)
        task_dir = await _prepare_resume_state(config, task_id, task_dir, state, resume_phase)
        is_resume = True
    else:
        # Fresh start: move to ongoing, materialize state.json, and create worktree.
        task_dir = await _set_state(config, task_id, "planning")
        state = S.read_state(task_dir)
        state.max_plan_retries = max_plan_retries
        state.max_impl_retries = max_impl_retries
        S.write_state(task_dir, state)
        W.create_worktree(config, task_id)
        state = S.read_state(task_dir)
        state.branch = W.worktree_branch(task_id)
        S.write_state(task_dir, state)
        resume_phase = 0

    worktree_dir = worktree_path

    # Plan phase
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
    if resume_phase <= 1:
        if not (is_resume and resume_phase == 1):
            task_dir = await _set_state(config, task_id, "implementing")
        impl_ok = await run_impl_phase(config, task_id, task_dir, worktree_dir, max_impl_retries)
        if not impl_ok:
            s = S.read_state(task_dir)
            s.escalation = "impl_review_exhausted"
            S.write_state(task_dir, s)
            await _set_state(config, task_id, "needs_attention")
            await emit("escalation", task_id=task_id, phase="impl_review")
            return

    # Publish phase
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

    # Done
    task_dir = await _set_state(config, task_id, "done")
    W.remove_worktree(config, task_id, delete_branch=False)
    await emit("pipeline_done", task_id=task_id)
