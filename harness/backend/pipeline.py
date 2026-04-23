"""Pipeline orchestration with GAN loops for plan-review and implement-review."""
from __future__ import annotations

import re
from pathlib import Path
from typing import Optional

from . import agents as A
from . import state as S
from . import worktree as W
from .config import HarnessConfig
from .events import emit


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


async def run_plan_phase(
    config: HarnessConfig,
    task_id: str,
    task_dir: Path,
    worktree_dir: Path,
    max_retries: int,
) -> bool:
    """Return True on pass, False on escalation."""
    # Planner writes v1
    await emit("phase_started", task_id=task_id, phase="planning")
    planner_prompt = f"""Task folder: {task_dir}
Spec file: {task_dir / 'spec.md'}
Worktree (read-only reference for code structure): {worktree_dir}

Write implement-plan.md v1 in the task folder.
"""
    await A.run_agent(A.resolve_agent(A.PLANNER, config), planner_prompt, cwd=task_dir, task_id=task_id)

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
    await emit("phase_started", task_id=task_id, phase="implementing")
    impl_prompt = f"""Task folder: {task_dir}
Spec: {task_dir / 'spec.md'}
Plan: {task_dir / 'implement-plan.md'}
Checklist: {task_dir / 'implement-checklist.md'}
Worktree (where you write code): {worktree_dir}

Build command: {config.build_cmd}
Unit test command: {config.unit_test_cmd}
UI test command (DO NOT run): {config.ui_test_cmd}

Implement the feature per the checklist. Ensure build + unit tests pass.
Write UI tests but don't run them. Commit.
"""
    result = await A.run_agent(A.resolve_agent(A.IMPLEMENTOR, config), impl_prompt, cwd=worktree_dir, task_id=task_id)
    if _has_token(result.text, "IMPLEMENT_BLOCKED"):
        return False

    for iteration in range(1, max_retries + 1):
        await emit("phase_started", task_id=task_id, phase="impl_review", iteration=iteration)
        latest_feedback = _latest_feedback(_all_impl_feedback(task_dir))
        reviewer_prompt = f"""Task folder: {task_dir}
Spec: {task_dir / 'spec.md'}
Plan: {task_dir / 'implement-plan.md'}
Checklist: {task_dir / 'implement-checklist.md'}
Latest implement-feedback file (carries forward unresolved items from earlier iterations):
{_format_feedback_paths(latest_feedback)}
Worktree: {worktree_dir}
Iteration: {iteration}

Build command: {config.build_cmd}
Unit test command: {config.unit_test_cmd}
UI test command (RUN IT): {config.ui_test_cmd}

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
Unit test command: {config.unit_test_cmd}
UI test command (DO NOT run): {config.ui_test_cmd}

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
    await emit("phase_started", task_id=task_id, phase="publishing")
    branch = W.worktree_branch(task_id)
    pub_prompt = f"""Task folder: {task_dir}
Worktree: {worktree_dir}
Feature branch: {branch}
Base branch: {config.main_branch}
GitHub repo: {config.github_repo or '(not configured — push only and skip gh)'}

Push the branch and open a PR via gh. Write pr.md. Respond PUBLISH_DONE or PUBLISH_BLOCKED.
"""
    result = await A.run_agent(A.resolve_agent(A.PUBLISHER, config), pub_prompt, cwd=worktree_dir, task_id=task_id)
    return _has_token(result.text, "PUBLISH_DONE")


async def run_pipeline(
    config: HarnessConfig,
    task_id: str,
    *,
    max_plan_retries: Optional[int] = None,
    max_impl_retries: Optional[int] = None,
) -> None:
    max_plan_retries = max_plan_retries or config.default_max_plan_retries
    max_impl_retries = max_impl_retries or config.default_max_impl_retries

    task_dir = S.find_task_dir(config, task_id)
    state = S.read_state(task_dir)
    state.max_plan_retries = max_plan_retries
    state.max_impl_retries = max_impl_retries
    S.write_state(task_dir, state)

    await emit("pipeline_started", task_id=task_id)

    # Move to ongoing + create worktree
    task_dir = await _set_state(config, task_id, "planning")
    worktree_dir = W.create_worktree(config, task_id)
    state = S.read_state(task_dir)
    state.branch = W.worktree_branch(task_id)
    S.write_state(task_dir, state)

    # Plan phase
    plan_ok = await run_plan_phase(config, task_id, task_dir, worktree_dir, max_plan_retries)
    if not plan_ok:
        s = S.read_state(task_dir)
        s.escalation = "plan_review_exhausted"
        S.write_state(task_dir, s)
        await _set_state(config, task_id, "needs_attention")
        await emit("escalation", task_id=task_id, phase="plan_review")
        return

    # Implement phase
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
