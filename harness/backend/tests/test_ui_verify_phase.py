from __future__ import annotations

from pathlib import Path

import pytest

from backend import pipeline as P
from backend import state as S
from backend import worktree as W


def _setup_task(tmp_config, task_id: str):
    """Create a task with bootstrapped workspace and worktree, leave it at ui_verify state."""
    todo_dir = tmp_config.todo_dir / task_id
    todo_dir.mkdir(parents=True, exist_ok=True)
    (todo_dir / "spec.md").write_text("# ui verify gate\n", encoding="utf-8")
    task_dir = S.transition(tmp_config, task_id, "ui_verify")
    W.create_worktree(tmp_config, task_id)
    worktree_dir = W.project_worktree_path(tmp_config, task_id)
    return task_dir, worktree_dir


def _write_ui_artifacts(worktree_dir: Path, body: str = "ui ok\n") -> None:
    artifacts = worktree_dir / ".harness" / "test-results"
    artifacts.mkdir(parents=True, exist_ok=True)
    (artifacts / "last-ui-summary.txt").write_text(body)
    (artifacts / "last-ui-failures.txt").write_text(body)


@pytest.mark.asyncio
async def test_ui_verify_skips_when_command_is_echo_placeholder(tmp_config, monkeypatch):
    task_dir, worktree_dir = _setup_task(tmp_config, "ui-verify-skip")

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "echo 'SKIP: no changed ui test files in this worktree'")

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    events: list[tuple[str, dict]] = []

    async def fake_emit(event_type, **payload):
        events.append((event_type, payload))

    monkeypatch.setattr(P, "emit", fake_emit)

    ok = await P.run_ui_verify_phase(tmp_config, "ui-verify-skip", task_dir, worktree_dir)

    assert ok is True
    assert any(t == "ui_verify_skipped" for t, _ in events)


@pytest.mark.asyncio
async def test_ui_verify_passes_when_command_succeeds_and_artifacts_visible(
    tmp_config, monkeypatch
):
    task_dir, worktree_dir = _setup_task(tmp_config, "ui-verify-pass")

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "true")  # /usr/bin/true returns 0

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    events: list[tuple[str, dict]] = []

    async def fake_emit(event_type, **payload):
        events.append((event_type, payload))

    monkeypatch.setattr(P, "emit", fake_emit)

    # Pre-write artifacts since `true` won't write any.
    _write_ui_artifacts(worktree_dir)

    ok = await P.run_ui_verify_phase(tmp_config, "ui-verify-pass", task_dir, worktree_dir)

    assert ok is True
    assert any(t == "ui_verify_passed" for t, _ in events)
    state = S.read_state(task_dir)
    assert state.escalation is None


@pytest.mark.asyncio
async def test_ui_verify_fails_with_distinct_escalation_when_command_nonzero(
    tmp_config, monkeypatch
):
    task_dir, worktree_dir = _setup_task(tmp_config, "ui-verify-fail")

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "false")  # /usr/bin/false returns 1

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    events: list[tuple[str, dict]] = []

    async def fake_emit(event_type, **payload):
        events.append((event_type, payload))

    monkeypatch.setattr(P, "emit", fake_emit)

    _write_ui_artifacts(worktree_dir)

    ok = await P.run_ui_verify_phase(tmp_config, "ui-verify-fail", task_dir, worktree_dir)

    assert ok is False
    state = S.read_state(task_dir)
    assert state.escalation == "ui_verification_failed"
    assert any(t == "ui_verify_failed" for t, _ in events)


@pytest.mark.asyncio
async def test_ui_verify_flags_diagnostic_infra_when_artifacts_missing(
    tmp_config, monkeypatch
):
    task_dir, worktree_dir = _setup_task(tmp_config, "ui-verify-noartifacts")

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "true")

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    events: list[tuple[str, dict]] = []

    async def fake_emit(event_type, **payload):
        events.append((event_type, payload))

    monkeypatch.setattr(P, "emit", fake_emit)

    # Don't write artifacts → DiagnosticInfrastructureError path.
    ok = await P.run_ui_verify_phase(tmp_config, "ui-verify-noartifacts", task_dir, worktree_dir)

    assert ok is False
    state = S.read_state(task_dir)
    # Distinct from impl-phase diagnostic_infra_missing so resume routes back to ui_verify.
    assert state.escalation == "ui_verify_diagnostic_infra_missing"
    assert any(
        t == "diagnostic_infra_missing" and p.get("phase") == "ui_verify"
        for t, p in events
    )


def test_ui_verify_specific_escalations_route_back_to_ui_verify_phase():
    """Resume index for ui_verify-flavored escalations must be 2 (not 1 = impl)."""
    for esc in ("ui_verification_failed", "ui_verify_diagnostic_infra_missing"):
        state = S.TaskState(id="t", state="needs_attention", escalation=esc)
        assert P._resume_phase_index(state) == 2, (
            f"escalation {esc!r} must route back to the UI verification gate"
        )


def test_implement_reviewer_prompt_has_no_ui_test_command_line():
    """The reviewer prompt must not surface a UI test command anymore — UI tests
    run only in the dedicated ui_verify gate. This test guards against accidental
    re-introduction of per-iteration UI test invocation."""
    source = Path(P.__file__).read_text()

    # Reviewer prompt template lives near the impl_review iteration loop.
    assert "UI test command (scoped" not in source
    assert "RUN IT" not in source


def test_reviewer_bash_policy_signature_drops_ui_cmd():
    """Compile-time guard that the reviewer bash policy no longer takes ui_cmd."""
    import inspect

    sig = inspect.signature(P._reviewer_bash_policy)
    assert list(sig.parameters.keys()) == ["config", "unit_cmd"]


@pytest.mark.asyncio
async def test_run_pipeline_surfaces_ui_verify_failure_as_needs_attention(
    tmp_config, monkeypatch
):
    """End-to-end: when ui_verify gate returns False, pipeline must escalate to
    needs_attention with the ui_verification_failed token and never advance to
    publish."""
    task_id = "pipeline-ui-fail"
    todo = tmp_config.todo_dir / task_id
    todo.mkdir(parents=True, exist_ok=True)
    (todo / "spec.md").write_text("# fail gate\n", encoding="utf-8")

    async def ok_plan(*args, **kwargs):
        return True

    async def ok_impl(*args, **kwargs):
        return True

    async def failing_ui_verify(config, task_id, task_dir, worktree_dir):
        state = S.read_state(task_dir)
        state.escalation = "ui_verification_failed"
        S.write_state(task_dir, state)
        return False

    async def fail_publish(*args, **kwargs):
        raise AssertionError("publish must not run after ui_verify failure")

    monkeypatch.setattr(P, "run_plan_phase", ok_plan)
    monkeypatch.setattr(P, "run_impl_phase", ok_impl)
    monkeypatch.setattr(P, "run_ui_verify_phase", failing_ui_verify)
    monkeypatch.setattr(P, "run_publish_phase", fail_publish)
    monkeypatch.setattr(P.W, "remove_worktree", lambda *args, **kwargs: None)

    await P.run_pipeline(tmp_config, task_id)

    workspace = S.find_task_workspace(tmp_config, task_id)
    assert workspace is not None
    final_state = S.read_state(workspace)
    assert final_state.state == "needs_attention"
    assert final_state.escalation == "ui_verification_failed"
