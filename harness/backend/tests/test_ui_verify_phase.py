from __future__ import annotations

import subprocess as _real_subprocess
from pathlib import Path

import pytest

from backend import agents as A
from backend import pipeline as P
from backend import state as S
from backend import worktree as W


def _make_subprocess_run_stub(rc_sequence: list[int]):
    """Build a `subprocess.run` replacement that intercepts only UI-test calls.

    `discover_new_swift_files` (called from inside `_run_ui_reviewer`) shells out
    to `git` via `subprocess.run(..., capture_output=True)`. We pass those
    through to the real implementation and only rig non-git invocations using
    `rc_sequence` (one return code per scripted call).
    """
    real_run = _real_subprocess.run
    counter = {"n": 0}

    def fake_run(argv, cwd=None, **kwargs):
        if argv and argv[0] == "git":
            return real_run(argv, cwd=cwd, **kwargs)
        idx = counter["n"]
        counter["n"] += 1
        rc = rc_sequence[idx] if idx < len(rc_sequence) else rc_sequence[-1]

        class _R:
            returncode = rc

        return _R()

    return fake_run, counter


def _setup_task(tmp_config, task_id: str, *, max_ui_review_iters: int = 1):
    """Create a task with bootstrapped workspace and worktree, leave it at ui_verify state.

    Defaults `max_ui_review_iters=1` so the reviewer loop is disabled — tests
    that exercise the legacy single-shot gate behavior keep working unchanged.
    Tests that exercise the reviewer loop pass `max_ui_review_iters=2` (or more).
    """
    todo_dir = tmp_config.todo_dir / task_id
    todo_dir.mkdir(parents=True, exist_ok=True)
    (todo_dir / "spec.md").write_text("# ui verify gate\n", encoding="utf-8")
    task_dir = S.transition(tmp_config, task_id, "ui_verify")
    W.create_worktree(tmp_config, task_id)
    worktree_dir = W.project_worktree_path(tmp_config, task_id)
    state = S.read_state(task_dir)
    state.max_ui_review_iters = max_ui_review_iters
    S.write_state(task_dir, state)
    return task_dir, worktree_dir


def _write_ui_artifacts(worktree_dir: Path, body: str = "ui ok\n") -> None:
    artifacts = worktree_dir / ".harness" / "test-results"
    artifacts.mkdir(parents=True, exist_ok=True)
    (artifacts / "last-ui-summary.txt").write_text(body)
    (artifacts / "last-ui-failures.txt").write_text(body)


def _make_reviewer_stub(
    decisions: list[str],
    *,
    patch_on_fail: bool = False,
    tool_uses: list[dict[str, object]] | None = None,
    capture: dict[str, object] | None = None,
):
    """Return a fake `A.run_agent` that yields the given decision tokens in order.

    Each call consumes one decision; if the queue empties, the stub raises so
    a runaway loop fails loudly instead of silently producing the wrong token.
    """
    queue = list(decisions)
    calls = {"n": 0}

    async def fake_run_agent(spec, prompt, **kwargs):
        if not queue:
            raise AssertionError("reviewer stub called more times than expected")
        calls["n"] += 1
        if capture is not None:
            capture["prompt"] = prompt
            capture["kwargs"] = kwargs
        token = queue.pop(0)
        if patch_on_fail and token == "IMPLEMENT_FAIL":
            cwd = Path(kwargs["cwd"])
            (cwd / f"ui-reviewer-patch-{calls['n']}.txt").write_text(
                f"patch {calls['n']}\n",
                encoding="utf-8",
            )
        text = f"some reasoning\n{token}\n" if token else "no decision here\n"
        return A.AgentResult(
            text=text,
            tool_uses=list(tool_uses or []),
            stop_reason="end_turn",
        )

    return fake_run_agent, queue


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
    # Chat visibility: subprocess lifecycle events bracket the test run so the
    # frontend can render a live "Running UI tests…" status pill.
    started = [(t, p) for t, p in events if t == "ui_tests_started"]
    finished = [(t, p) for t, p in events if t == "ui_tests_finished"]
    assert len(started) == 1
    assert len(finished) == 1
    assert started[0][1].get("iteration") == 1
    assert started[0][1].get("command") == "true"
    assert finished[0][1].get("exit_code") == 0
    assert finished[0][1].get("iteration") == 1
    assert isinstance(finished[0][1].get("duration_s"), float)
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
    for esc in (
        "ui_verification_failed",
        "ui_verify_diagnostic_infra_missing",
        "ui_verify_review_exhausted",
        "ui_verify_rework_required",
        "ui_verify_review_ambiguous",
        "ui_verify_review_stalled",
    ):
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


# ---------------------------------------------------------------------------
# Reviewer-driven retry loop (max_ui_review_iters >= 2)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_ui_verify_reviewer_patch_then_pass(tmp_config, monkeypatch):
    """Iter 1 fails → reviewer applies a patch (IMPLEMENT_FAIL) → iter 2 passes."""
    task_dir, worktree_dir = _setup_task(
        tmp_config, "ui-reviewer-patch", max_ui_review_iters=2
    )
    _write_ui_artifacts(worktree_dir)

    fake_run, call_count = _make_subprocess_run_stub([1, 0])
    monkeypatch.setattr(P.subprocess, "run", fake_run)
    # Skip artifact freshness checks — the helper writes them once at setup.
    monkeypatch.setattr(P, "_assert_test_artifacts_visible", lambda *a, **k: None)

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "/usr/bin/false")

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    fake_run_agent, _ = _make_reviewer_stub(["IMPLEMENT_FAIL"], patch_on_fail=True)
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    events: list[tuple[str, dict]] = []

    async def fake_emit(event_type, **payload):
        events.append((event_type, payload))

    monkeypatch.setattr(P, "emit", fake_emit)

    ok = await P.run_ui_verify_phase(
        tmp_config, "ui-reviewer-patch", task_dir, worktree_dir
    )

    assert ok is True
    # The stub increments only on non-git invocations (UI test runs).
    assert call_count["n"] == 2, "UI tests should have run twice (iter 1 fail, iter 2 pass)"
    state = S.read_state(task_dir)
    assert state.escalation is None
    assert state.ui_review_retries == 1, (
        "reviewer ran on iter 1 between the two test runs"
    )
    assert any(t == "ui_verify_passed" for t, _ in events)
    assert any(
        t == "retry" and p.get("phase") == "ui_verify_review" for t, p in events
    )


@pytest.mark.asyncio
async def test_ui_verify_reviewer_rework_signals_loopback(tmp_config, monkeypatch):
    """Reviewer says rework needed and loop counter under max → returns "loopback"."""
    task_dir, worktree_dir = _setup_task(
        tmp_config, "ui-reviewer-rework", max_ui_review_iters=3
    )
    _write_ui_artifacts(worktree_dir)

    fake_run, _ = _make_subprocess_run_stub([1])
    monkeypatch.setattr(P.subprocess, "run", fake_run)
    monkeypatch.setattr(P, "_assert_test_artifacts_visible", lambda *a, **k: None)

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "/usr/bin/false")

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    fake_run_agent, _ = _make_reviewer_stub(["IMPLEMENT_REWORK_REQUIRED"])
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    events: list[tuple[str, dict]] = []

    async def fake_emit(event_type, **payload):
        events.append((event_type, payload))

    monkeypatch.setattr(P, "emit", fake_emit)

    ok = await P.run_ui_verify_phase(
        tmp_config, "ui-reviewer-rework", task_dir, worktree_dir
    )

    assert ok == "loopback"
    state = S.read_state(task_dir)
    assert state.escalation is None
    assert state.ui_to_impl_loops == 1
    assert state.ui_review_retries == 1
    assert any(t == "ui_verify_rework_loopback" for t, _ in events)


@pytest.mark.asyncio
async def test_ui_verify_reviewer_rework_exhausts_after_max_loops(tmp_config, monkeypatch):
    """Once ui_to_impl_loops reaches max, REWORK escalates instead of looping."""
    task_dir, worktree_dir = _setup_task(
        tmp_config, "ui-reviewer-rework-exhausted", max_ui_review_iters=3
    )
    state = S.read_state(task_dir)
    state.ui_to_impl_loops = state.max_ui_to_impl_loops  # already at limit
    S.write_state(task_dir, state)
    _write_ui_artifacts(worktree_dir)

    fake_run, _ = _make_subprocess_run_stub([1])
    monkeypatch.setattr(P.subprocess, "run", fake_run)
    monkeypatch.setattr(P, "_assert_test_artifacts_visible", lambda *a, **k: None)

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "/usr/bin/false")

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    fake_run_agent, _ = _make_reviewer_stub(["IMPLEMENT_REWORK_REQUIRED"])
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    async def fake_emit(event_type, **payload):
        pass

    monkeypatch.setattr(P, "emit", fake_emit)

    ok = await P.run_ui_verify_phase(
        tmp_config, "ui-reviewer-rework-exhausted", task_dir, worktree_dir
    )

    assert ok is False
    state = S.read_state(task_dir)
    assert state.escalation == "ui_verify_rework_loop_exhausted"
    assert state.ui_review_retries == 1


@pytest.mark.asyncio
async def test_ui_verify_review_exhausted(tmp_config, monkeypatch):
    """All iterations fail and reviewer keeps signaling FAIL → review_exhausted."""
    task_dir, worktree_dir = _setup_task(
        tmp_config, "ui-reviewer-exhausted", max_ui_review_iters=2
    )
    _write_ui_artifacts(worktree_dir)

    fake_run, _ = _make_subprocess_run_stub([1])
    monkeypatch.setattr(P.subprocess, "run", fake_run)
    monkeypatch.setattr(P, "_assert_test_artifacts_visible", lambda *a, **k: None)

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "/usr/bin/false")

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    # Only one reviewer call expected: between iter 1 and iter 2. After iter 2
    # also fails, the loop terminates via the iteration==max_iters branch.
    fake_run_agent, _ = _make_reviewer_stub(["IMPLEMENT_FAIL"], patch_on_fail=True)
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    async def fake_emit(event_type, **payload):
        pass

    monkeypatch.setattr(P, "emit", fake_emit)

    ok = await P.run_ui_verify_phase(
        tmp_config, "ui-reviewer-exhausted", task_dir, worktree_dir
    )

    assert ok is False
    state = S.read_state(task_dir)
    assert state.escalation == "ui_verify_review_exhausted"
    assert state.ui_review_retries == 2


@pytest.mark.asyncio
async def test_ui_verify_review_pass_remapped_when_patch_applied(tmp_config, monkeypatch):
    """Reviewer says PASS after UI failure but committed a patch — remap to FAIL.

    The next iteration re-runs UI tests; if the patch fixed things, the gate
    passes. The protocol violation is recorded via `agent_protocol_violation`.
    """
    task_dir, worktree_dir = _setup_task(
        tmp_config, "ui-reviewer-pass-with-patch", max_ui_review_iters=2
    )
    _write_ui_artifacts(worktree_dir)

    # iter 1 UI test fails; iter 2 (after remap) UI test passes.
    fake_run, call_count = _make_subprocess_run_stub([1, 0])
    monkeypatch.setattr(P.subprocess, "run", fake_run)
    monkeypatch.setattr(P, "_assert_test_artifacts_visible", lambda *a, **k: None)

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "/usr/bin/false")

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    async def fake_run_agent(spec, prompt, **kwargs):
        # Reviewer applies a patch but returns the wrong terminal token.
        cwd = Path(kwargs["cwd"])
        (cwd / "pass-token-patch.swift").write_text("// reviewer patch\n", encoding="utf-8")
        return A.AgentResult(
            text="all good\nIMPLEMENT_PASS\n",
            tool_uses=[],
            stop_reason="end_turn",
        )

    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    events: list[tuple[str, dict]] = []

    async def fake_emit(event_type, **payload):
        events.append((event_type, payload))

    monkeypatch.setattr(P, "emit", fake_emit)

    ok = await P.run_ui_verify_phase(
        tmp_config, "ui-reviewer-pass-with-patch", task_dir, worktree_dir
    )

    assert ok is True
    assert call_count["n"] == 2, "UI tests run twice (iter 1 fail, iter 2 pass)"
    state = S.read_state(task_dir)
    assert state.escalation is None
    violations = [p for t, p in events if t == "agent_protocol_violation"]
    assert len(violations) == 1
    assert violations[0]["original_decision"] == "IMPLEMENT_PASS"
    assert violations[0]["remapped_to"] == "IMPLEMENT_FAIL"
    assert violations[0]["phase"] == "ui_verify_review"
    assert any(t == "ui_verify_passed" for t, _ in events)


@pytest.mark.asyncio
async def test_ui_verify_review_pass_remapped_no_patch_stalls(tmp_config, monkeypatch):
    """Reviewer says PASS without committing a patch — remap to FAIL, then stall."""
    task_dir, worktree_dir = _setup_task(
        tmp_config, "ui-reviewer-pass-no-patch", max_ui_review_iters=2
    )
    _write_ui_artifacts(worktree_dir)

    fake_run, _ = _make_subprocess_run_stub([1])
    monkeypatch.setattr(P.subprocess, "run", fake_run)
    monkeypatch.setattr(P, "_assert_test_artifacts_visible", lambda *a, **k: None)

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "/usr/bin/false")

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    fake_run_agent, _ = _make_reviewer_stub(["IMPLEMENT_PASS"])
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    events: list[tuple[str, dict]] = []

    async def fake_emit(event_type, **payload):
        events.append((event_type, payload))

    monkeypatch.setattr(P, "emit", fake_emit)

    ok = await P.run_ui_verify_phase(
        tmp_config, "ui-reviewer-pass-no-patch", task_dir, worktree_dir
    )

    assert ok is False
    state = S.read_state(task_dir)
    assert state.escalation == "ui_verify_review_stalled"
    assert state.ui_review_retries == 1
    assert any(t == "agent_protocol_violation" for t, _ in events)
    assert any(t == "agent_stall" for t, _ in events)


@pytest.mark.asyncio
async def test_ui_verify_review_missing_token_ambiguous(tmp_config, monkeypatch):
    """Reviewer response has no terminal token at all — escalate as ambiguous."""
    task_dir, worktree_dir = _setup_task(
        tmp_config, "ui-reviewer-missing-token", max_ui_review_iters=2
    )
    _write_ui_artifacts(worktree_dir)

    fake_run, _ = _make_subprocess_run_stub([1])
    monkeypatch.setattr(P.subprocess, "run", fake_run)
    monkeypatch.setattr(P, "_assert_test_artifacts_visible", lambda *a, **k: None)

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "/usr/bin/false")

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    # Empty token → stub emits "no decision here\n" with no recognized token.
    fake_run_agent, _ = _make_reviewer_stub([""])
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    events: list[tuple[str, dict]] = []

    async def fake_emit(event_type, **payload):
        events.append((event_type, payload))

    monkeypatch.setattr(P, "emit", fake_emit)

    ok = await P.run_ui_verify_phase(
        tmp_config, "ui-reviewer-missing-token", task_dir, worktree_dir
    )

    assert ok is False
    state = S.read_state(task_dir)
    assert state.escalation == "ui_verify_review_ambiguous"
    assert state.ui_review_retries == 1
    assert any(t == "agent_ambiguous" for t, _ in events)
    assert not any(t == "agent_protocol_violation" for t, _ in events)


@pytest.mark.asyncio
async def test_ui_reviewer_runtime_prompt_has_default_to_rework_clause(
    tmp_config, monkeypatch
):
    """UI verify reviewer prompt must state the default-to-REWORK fallback."""
    task_dir, worktree_dir = _setup_task(
        tmp_config, "ui-reviewer-prompt-rework-clause", max_ui_review_iters=2
    )

    capture: dict[str, object] = {}
    fake_run_agent, _ = _make_reviewer_stub(
        ["IMPLEMENT_REWORK_REQUIRED"],
        capture=capture,
    )
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    await P._run_ui_reviewer(
        tmp_config,
        "ui-reviewer-prompt-rework-clause",
        task_dir,
        worktree_dir,
        1,
        "echo unit",
        "/usr/bin/false",
    )

    prompt = str(capture["prompt"])
    compact = " ".join(prompt.split())
    # PASS-block guidance (existing, kept for regression)
    assert "Do NOT respond IMPLEMENT_PASS" in prompt
    assert "auto-remaps any IMPLEMENT_PASS" in compact
    # New: explicit default-to-REWORK fallback + ambiguous cost
    assert "default to IMPLEMENT_REWORK_REQUIRED" in compact
    assert "ui_verify_review_ambiguous" in prompt


@pytest.mark.asyncio
async def test_ui_reviewer_uses_next_feedback_version(tmp_config, monkeypatch):
    """UI reviewer must not overwrite feedback generated during impl_review."""
    task_dir, worktree_dir = _setup_task(
        tmp_config, "ui-reviewer-feedback-version", max_ui_review_iters=2
    )
    (task_dir / "implement-feedback-version-1.md").write_text(
        "# existing feedback\n",
        encoding="utf-8",
    )

    capture: dict[str, object] = {}
    fake_run_agent, _ = _make_reviewer_stub(
        ["IMPLEMENT_REWORK_REQUIRED"],
        capture=capture,
    )
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    decision, _result, diagnostics_ok = await P._run_ui_reviewer(
        tmp_config,
        "ui-reviewer-feedback-version",
        task_dir,
        worktree_dir,
        1,
        "echo unit",
        "/usr/bin/false",
    )

    assert diagnostics_ok is True
    assert decision == "IMPLEMENT_REWORK_REQUIRED"
    prompt = str(capture["prompt"])
    kwargs = capture["kwargs"]
    assert "Iteration: 2" in prompt
    assert "UI retry iteration: 1" in prompt
    assert "implement-feedback-version-2.md" in prompt
    assert isinstance(kwargs, dict)
    assert kwargs["iteration"] == 2


@pytest.mark.asyncio
async def test_ui_verify_auto_commits_reviewer_dirty_patch(tmp_config, monkeypatch):
    """Reviewer patches that are left dirty must be committed before retry/publish."""
    task_dir, worktree_dir = _setup_task(
        tmp_config, "ui-reviewer-autocommit", max_ui_review_iters=2
    )
    _write_ui_artifacts(worktree_dir)

    fake_run, _ = _make_subprocess_run_stub([1, 0])
    monkeypatch.setattr(P.subprocess, "run", fake_run)
    monkeypatch.setattr(P, "_assert_test_artifacts_visible", lambda *a, **k: None)

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "/usr/bin/false")

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    async def fake_run_agent(spec, prompt, **kwargs):
        patch = Path(kwargs["cwd"]) / "LocalizedPatch.swift"
        patch.write_text("// reviewer patch\n", encoding="utf-8")
        return A.AgentResult(
            text="patched\nIMPLEMENT_FAIL\n",
            tool_uses=[],
            stop_reason="end_turn",
        )

    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    async def fake_emit(event_type, **payload):
        pass

    monkeypatch.setattr(P, "emit", fake_emit)

    ok = await P.run_ui_verify_phase(
        tmp_config, "ui-reviewer-autocommit", task_dir, worktree_dir
    )

    assert ok is True
    show = _real_subprocess.run(
        ["git", "show", "--name-only", "--format=%s", "HEAD"],
        cwd=worktree_dir,
        capture_output=True,
        text=True,
        check=True,
    )
    assert "Auto-commit: ui verify reviewer patch iter 1" in show.stdout
    assert "LocalizedPatch.swift" in show.stdout


@pytest.mark.asyncio
async def test_ui_verify_stalls_when_reviewer_fail_without_patch(tmp_config, monkeypatch):
    """IMPLEMENT_FAIL with no commit/change is protocol drift, not a retry signal."""
    task_dir, worktree_dir = _setup_task(
        tmp_config, "ui-reviewer-stalled", max_ui_review_iters=2
    )
    _write_ui_artifacts(worktree_dir)

    fake_run, _ = _make_subprocess_run_stub([1])
    monkeypatch.setattr(P.subprocess, "run", fake_run)
    monkeypatch.setattr(P, "_assert_test_artifacts_visible", lambda *a, **k: None)

    async def fake_resolve(config, worktree_dir, task_id):
        return ("echo unit", "/usr/bin/false")

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    fake_run_agent, _ = _make_reviewer_stub(["IMPLEMENT_FAIL"])
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    async def fake_emit(event_type, **payload):
        pass

    monkeypatch.setattr(P, "emit", fake_emit)

    ok = await P.run_ui_verify_phase(
        tmp_config, "ui-reviewer-stalled", task_dir, worktree_dir
    )

    assert ok is False
    state = S.read_state(task_dir)
    assert state.escalation == "ui_verify_review_stalled"
    assert state.ui_review_retries == 1


@pytest.mark.asyncio
async def test_ui_reviewer_test_run_requires_fresh_artifacts(tmp_config, monkeypatch):
    """Reviewer-run tests use the same diagnostic freshness guard as impl_review."""
    task_dir, worktree_dir = _setup_task(
        tmp_config, "ui-reviewer-artifacts", max_ui_review_iters=2
    )
    _write_ui_artifacts(worktree_dir)

    fake_run, _ = _make_subprocess_run_stub([1])
    monkeypatch.setattr(P.subprocess, "run", fake_run)

    calls: list[set[str]] = []

    def fake_assert(worktree_dir, kinds, since):
        calls.append(set(kinds))
        if len(calls) == 2:
            raise P.DiagnosticInfrastructureError(
                worktree_dir / ".harness" / "test-results" / "last-ui-summary.txt",
                "stale",
            )

    monkeypatch.setattr(P, "_assert_test_artifacts_visible", fake_assert)

    async def fake_resolve(config, worktree_dir, task_id):
        return (
            "echo unit",
            "python3 tools/xcode_test_runner.py test --target WoontechUITests --ui",
        )

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve)

    fake_run_agent, _ = _make_reviewer_stub(
        ["IMPLEMENT_FAIL"],
        tool_uses=[
            {
                "name": "Bash",
                "input": {
                    "command": (
                        "python3 tools/xcode_test_runner.py test "
                        "--target WoontechUITests --ui"
                    )
                },
            }
        ],
    )
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    async def fake_emit(event_type, **payload):
        pass

    monkeypatch.setattr(P, "emit", fake_emit)

    ok = await P.run_ui_verify_phase(
        tmp_config, "ui-reviewer-artifacts", task_dir, worktree_dir
    )

    assert ok is False
    assert calls == [{"ui"}, {"ui"}]
    state = S.read_state(task_dir)
    assert state.escalation == "ui_verify_diagnostic_infra_missing"
    assert state.ui_review_retries == 1
