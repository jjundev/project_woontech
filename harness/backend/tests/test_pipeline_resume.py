from __future__ import annotations

import asyncio

import pytest

from backend import pipeline as P
from backend import state as S
from backend import worktree as W
from backend.events import bus


def _make_task(tmp_config, task_id: str, state_name: S.StateName, escalation: str | None = None):
    task_dir = tmp_config.todo_dir / task_id
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "spec.md").write_text("# test\n", encoding="utf-8")
    task_dir = S.transition(tmp_config, task_id, state_name)
    state = S.read_state(task_dir)
    state.escalation = escalation
    S.write_state(task_dir, state)
    return task_dir


@pytest.mark.parametrize(
    ("state_name", "escalation", "expected"),
    [
        ("planning", None, 0),
        ("plan_review", None, 0),
        ("todo", None, 0),
        ("draft", None, 0),
        ("implementing", None, 1),
        ("impl_review", None, 1),
        ("publishing", None, 2),
        ("needs_attention", "plan_review_exhausted", 0),
        ("needs_attention", "impl_review_exhausted", 1),
        ("needs_attention", "publish_failed", 2),
        ("needs_attention", None, 0),
        ("needs_attention", "something_new", 0),
    ],
)
def test_resume_phase_index_mapping(state_name, escalation, expected):
    state = S.TaskState(id="WF1", state=state_name, escalation=escalation)
    assert P._resume_phase_index(state) == expected


@pytest.mark.parametrize(
    ("paused_from", "expected"),
    [
        ("planning", 0),
        ("plan_review", 0),
        ("implementing", 1),
        ("impl_review", 1),
        ("publishing", 2),
        (None, 0),
    ],
)
def test_resume_phase_index_mapping_for_paused_state(paused_from, expected):
    state = S.TaskState(id="WF1", state="paused", paused_from=paused_from)
    assert P._resume_phase_index(state) == expected


def test_step_markers_are_only_extracted_for_implementor():
    from backend.agents.base import step_markers_for_agent

    text = "Reviewing the plan:\nSTEP: 1. Do the work\n"
    assert step_markers_for_agent("plan-reviewer", text) == []
    assert step_markers_for_agent("implementor", text) == ["1. Do the work"]


@pytest.mark.asyncio
async def test_run_pipeline_resumes_from_impl_state(tmp_config, monkeypatch):
    _make_task(tmp_config, "resume-impl", "implementing")
    tmp_config.worktree_path("resume-impl").mkdir(parents=True, exist_ok=True)

    calls: list[tuple[str, str, str | None]] = []

    async def fake_plan(*args, **kwargs):
        calls.append(("plan", "", None))
        return True

    async def fake_impl(config, task_id, task_dir, worktree_dir, max_retries, **kwargs):
        state = S.read_state(task_dir)
        calls.append(("impl", state.state, state.escalation))
        return True

    async def fake_publish(config, task_id, task_dir, worktree_dir):
        state = S.read_state(task_dir)
        calls.append(("publish", state.state, state.escalation))
        return True

    monkeypatch.setattr(P, "run_plan_phase", fake_plan)
    monkeypatch.setattr(P, "run_impl_phase", fake_impl)
    monkeypatch.setattr(P, "run_publish_phase", fake_publish)
    monkeypatch.setattr(P.W, "remove_worktree", lambda *args, **kwargs: None)

    await P.run_pipeline(tmp_config, "resume-impl")

    assert calls == [
        ("impl", "implementing", None),
        ("publish", "publishing", None),
    ]


@pytest.mark.asyncio
async def test_run_pipeline_reemits_plan_steps_when_resuming_impl(tmp_config, monkeypatch):
    task_dir = _make_task(tmp_config, "resume-plan-steps", "implementing")
    (task_dir / "implement-plan.md").write_text(
        "# Plan\n\n## Implementation steps\n1. Keep state scoped\n2. Render scrollably\n",
        encoding="utf-8",
    )
    tmp_config.worktree_path("resume-plan-steps").mkdir(parents=True, exist_ok=True)

    events: list[tuple[str, dict[str, object]]] = []

    async def fake_emit(event_type: str, *, task_id=None, agent=None, iteration=None, **payload):
        events.append((event_type, payload))

    async def fake_plan(*args, **kwargs):
        raise AssertionError("plan phase should be skipped when resuming implementation")

    async def fake_impl(*args, **kwargs):
        return True

    async def fake_publish(*args, **kwargs):
        return True

    monkeypatch.setattr(P, "emit", fake_emit)
    monkeypatch.setattr(P, "run_plan_phase", fake_plan)
    monkeypatch.setattr(P, "run_impl_phase", fake_impl)
    monkeypatch.setattr(P, "run_publish_phase", fake_publish)

    await P.run_pipeline(tmp_config, "resume-plan-steps")

    plan_events = [payload for event_type, payload in events if event_type == "plan_steps"]
    assert plan_events == [
        {
            "steps": [
                {"index": 1, "title": "Keep state scoped"},
                {"index": 2, "title": "Render scrollably"},
            ]
        }
    ]


@pytest.mark.asyncio
async def test_run_pipeline_events_include_run_id(tmp_config, monkeypatch):
    task_id = "run-id"
    task_dir = tmp_config.todo_dir / task_id
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "spec.md").write_text("# run id\n", encoding="utf-8")

    async def ok_plan(*args, **kwargs):
        return True

    async def ok_impl(*args, **kwargs):
        return True

    async def ok_publish(*args, **kwargs):
        return True

    monkeypatch.setattr(P, "run_plan_phase", ok_plan)
    monkeypatch.setattr(P, "run_impl_phase", ok_impl)
    monkeypatch.setattr(P, "run_publish_phase", ok_publish)

    queue = await bus.subscribe()
    try:
        await P.run_pipeline(tmp_config, task_id)
        emitted = []
        while not queue.empty():
            emitted.append(queue.get_nowait())
    finally:
        await bus.unsubscribe(queue)

    task_events = [event for event in emitted if event.task_id == task_id]
    started = next(event for event in task_events if event.type == "pipeline_started")
    assert started.run_id
    assert {
        event.run_id
        for event in task_events
        if event.type in {"pipeline_started", "state_changed", "pipeline_done"}
    } == {started.run_id}


@pytest.mark.asyncio
async def test_run_pipeline_resumes_impl_from_needs_attention(tmp_config, monkeypatch):
    _make_task(tmp_config, "resume-needs-impl", "needs_attention", escalation="impl_review_exhausted")
    tmp_config.worktree_path("resume-needs-impl").mkdir(parents=True, exist_ok=True)

    calls: list[tuple[str, str, str | None]] = []

    async def fake_plan(*args, **kwargs):
        calls.append(("plan", "", None))
        return True

    async def fake_impl(config, task_id, task_dir, worktree_dir, max_retries, **kwargs):
        state = S.read_state(task_dir)
        calls.append(("impl", state.state, state.escalation))
        return True

    async def fake_publish(config, task_id, task_dir, worktree_dir):
        state = S.read_state(task_dir)
        calls.append(("publish", state.state, state.escalation))
        return True

    monkeypatch.setattr(P, "run_plan_phase", fake_plan)
    monkeypatch.setattr(P, "run_impl_phase", fake_impl)
    monkeypatch.setattr(P, "run_publish_phase", fake_publish)
    monkeypatch.setattr(P.W, "remove_worktree", lambda *args, **kwargs: None)

    await P.run_pipeline(tmp_config, "resume-needs-impl")

    assert calls == [
        ("impl", "implementing", None),
        ("publish", "publishing", None),
    ]


@pytest.mark.asyncio
async def test_run_pipeline_resumes_publish_from_needs_attention(tmp_config, monkeypatch):
    _make_task(tmp_config, "resume-needs-publish", "needs_attention", escalation="publish_failed")
    tmp_config.worktree_path("resume-needs-publish").mkdir(parents=True, exist_ok=True)

    calls: list[tuple[str, str, str | None]] = []

    async def fake_plan(*args, **kwargs):
        calls.append(("plan", "", None))
        return True

    async def fake_impl(*args, **kwargs):
        calls.append(("impl", "", None))
        return True

    async def fake_publish(config, task_id, task_dir, worktree_dir):
        state = S.read_state(task_dir)
        calls.append(("publish", state.state, state.escalation))
        return True

    monkeypatch.setattr(P, "run_plan_phase", fake_plan)
    monkeypatch.setattr(P, "run_impl_phase", fake_impl)
    monkeypatch.setattr(P, "run_publish_phase", fake_publish)
    monkeypatch.setattr(P.W, "remove_worktree", lambda *args, **kwargs: None)

    await P.run_pipeline(tmp_config, "resume-needs-publish")

    assert calls == [
        ("publish", "publishing", None),
    ]


@pytest.mark.asyncio
async def test_run_pipeline_unknown_needs_attention_restarts_from_plan(tmp_config, monkeypatch):
    _make_task(tmp_config, "resume-unknown", "needs_attention", escalation="something_new")
    tmp_config.worktree_path("resume-unknown").mkdir(parents=True, exist_ok=True)

    calls: list[tuple[str, str, str | None]] = []

    async def fake_plan(config, task_id, task_dir, worktree_dir, max_retries):
        state = S.read_state(task_dir)
        calls.append(("plan", state.state, state.escalation))
        return False

    async def fake_impl(*args, **kwargs):
        calls.append(("impl", "", None))
        return True

    async def fake_publish(*args, **kwargs):
        calls.append(("publish", "", None))
        return True

    monkeypatch.setattr(P, "run_plan_phase", fake_plan)
    monkeypatch.setattr(P, "run_impl_phase", fake_impl)
    monkeypatch.setattr(P, "run_publish_phase", fake_publish)
    monkeypatch.setattr(P.W, "remove_worktree", lambda *args, **kwargs: None)

    await P.run_pipeline(tmp_config, "resume-unknown")

    assert calls == [
        ("plan", "planning", None),
    ]


@pytest.mark.asyncio
async def test_run_pipeline_clears_stale_escalation_after_resume(tmp_config, monkeypatch):
    _make_task(tmp_config, "resume-clears", "needs_attention", escalation="impl_review_exhausted")
    tmp_config.worktree_path("resume-clears").mkdir(parents=True, exist_ok=True)

    async def fake_plan(*args, **kwargs):
        return True

    async def fake_impl(config, task_id, task_dir, worktree_dir, max_retries, **kwargs):
        state = S.read_state(task_dir)
        assert state.state == "implementing"
        assert state.escalation is None
        return True

    async def fake_publish(config, task_id, task_dir, worktree_dir):
        state = S.read_state(task_dir)
        assert state.state == "publishing"
        assert state.escalation is None
        return True

    monkeypatch.setattr(P, "run_plan_phase", fake_plan)
    monkeypatch.setattr(P, "run_impl_phase", fake_impl)
    monkeypatch.setattr(P, "run_publish_phase", fake_publish)
    monkeypatch.setattr(P.W, "remove_worktree", lambda *args, **kwargs: None)

    await P.run_pipeline(tmp_config, "resume-clears")

    final_state = S.read_state(S.find_task_dir(tmp_config, "resume-clears"))
    assert final_state.state == "done"
    assert final_state.escalation is None


@pytest.mark.asyncio
async def test_run_pipeline_handles_stale_worktree_on_fresh_start(tmp_config, monkeypatch):
    task_dir = tmp_config.todo_dir / "stale-fresh"
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "spec.md").write_text("# stale fresh\n", encoding="utf-8")
    tmp_config.worktree_path("stale-fresh").mkdir(parents=True, exist_ok=True)

    calls: list[str] = []

    async def fake_plan(config, task_id, task_dir, worktree_dir, max_retries):
        calls.append("plan")
        assert S.read_state(task_dir).state == "planning"
        return True

    async def fake_impl(config, task_id, task_dir, worktree_dir, max_retries, **kwargs):
        calls.append("impl")
        return True

    async def fake_publish(config, task_id, task_dir, worktree_dir):
        calls.append("publish")
        return True

    monkeypatch.setattr(P, "run_plan_phase", fake_plan)
    monkeypatch.setattr(P, "run_impl_phase", fake_impl)
    monkeypatch.setattr(P, "run_publish_phase", fake_publish)
    monkeypatch.setattr(P.W, "remove_worktree", lambda *args, **kwargs: None)

    await P.run_pipeline(tmp_config, "stale-fresh")

    final_state = S.read_state(S.find_task_dir(tmp_config, "stale-fresh"))
    assert calls == ["plan", "impl", "publish"]
    assert final_state.state == "done"
    assert tmp_config.worktree_path("stale-fresh").exists()


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("phase_name", "failing_attr", "token"),
    [
        ("plan", "run_plan_phase", "plan_unexpected_error"),
        ("impl", "run_impl_phase", "impl_unexpected_error"),
        ("publish", "run_publish_phase", "publish_unexpected_error"),
    ],
)
async def test_run_pipeline_converts_unexpected_errors_to_needs_attention(
    tmp_config,
    monkeypatch,
    phase_name,
    failing_attr,
    token,
):
    task_id = f"unexpected-{phase_name}"
    task_dir = tmp_config.todo_dir / task_id
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "spec.md").write_text("# unexpected\n", encoding="utf-8")

    events: list[tuple[str, dict[str, object]]] = []

    async def fake_emit(event_type: str, *, task_id=None, agent=None, iteration=None, **payload):
        events.append((event_type, payload))

    async def ok_plan(*args, **kwargs):
        return True

    async def ok_impl(*args, **kwargs):
        return True

    async def ok_publish(*args, **kwargs):
        return True

    async def boom(*args, **kwargs):
        raise RuntimeError(f"{phase_name} exploded")

    monkeypatch.setattr(P, "emit", fake_emit)
    monkeypatch.setattr(P, "run_plan_phase", boom if failing_attr == "run_plan_phase" else ok_plan)
    monkeypatch.setattr(P, "run_impl_phase", boom if failing_attr == "run_impl_phase" else ok_impl)
    monkeypatch.setattr(P, "run_publish_phase", boom if failing_attr == "run_publish_phase" else ok_publish)

    await P.run_pipeline(tmp_config, task_id)

    final_state = S.read_state(S.find_task_dir(tmp_config, task_id))
    assert final_state.state == "needs_attention"
    assert final_state.escalation == token
    assert tmp_config.worktree_path(task_id).exists()
    assert ("escalation", {
        "phase": phase_name,
        "escalation": token,
        "error_type": "RuntimeError",
        "error_message": f"{phase_name} exploded",
    }) in events


@pytest.mark.asyncio
async def test_run_pipeline_uses_project_subdir_for_monorepo_phases(monorepo_config, monkeypatch):
    task_id = "mono-fresh"
    task_dir = monorepo_config.todo_dir / task_id
    task_dir.mkdir(parents=True, exist_ok=True)
    (task_dir / "spec.md").write_text("# mono fresh\n", encoding="utf-8")

    expected = W.project_worktree_path(monorepo_config, task_id)
    calls: list[tuple[str, str]] = []

    async def fake_plan(config, task_id, task_dir, worktree_dir, max_retries):
        calls.append(("plan", str(worktree_dir)))
        assert worktree_dir == expected
        assert worktree_dir.exists()
        return True

    async def fake_impl(config, task_id, task_dir, worktree_dir, max_retries, **kwargs):
        calls.append(("impl", str(worktree_dir)))
        assert worktree_dir == expected
        return True

    async def fake_publish(config, task_id, task_dir, worktree_dir):
        calls.append(("publish", str(worktree_dir)))
        assert worktree_dir == expected
        return True

    monkeypatch.setattr(P, "run_plan_phase", fake_plan)
    monkeypatch.setattr(P, "run_impl_phase", fake_impl)
    monkeypatch.setattr(P, "run_publish_phase", fake_publish)
    monkeypatch.setattr(P.W, "remove_worktree", lambda *args, **kwargs: None)

    await P.run_pipeline(monorepo_config, task_id)

    assert calls == [
        ("plan", str(expected)),
        ("impl", str(expected)),
        ("publish", str(expected)),
    ]


@pytest.mark.asyncio
async def test_impl_phase_escalates_when_implementor_returns_no_token(
    tmp_config,
    monkeypatch,
):
    """A max_turns cutoff leaves the implementor response with no recognizable
    token. The phase must abort instead of silently dropping into reviewer, which
    would risk a false-pass against a half-built tree."""
    from backend import agents as A

    _make_task(tmp_config, "no-token-impl", "implementing")
    task_dir = S.find_task_workspace(tmp_config, "no-token-impl")
    assert task_dir is not None
    tmp_config.worktree_path("no-token-impl").mkdir(parents=True, exist_ok=True)
    worktree_dir = W.project_worktree_path(tmp_config, "no-token-impl")

    events: list[tuple[str, dict[str, object]]] = []

    async def fake_emit(event_type, *, task_id=None, agent=None, iteration=None, **payload):
        events.append((event_type, payload))

    async def fake_run_agent(spec, prompt, *, cwd, task_id=None, iteration=None, hooks=None, **kw):
        return A.AgentResult(
            text="Started editing but ran out of turns.",
            tool_uses=[],
            stop_reason="tool_use",
        )

    monkeypatch.setattr(P, "emit", fake_emit)
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    ok = await P.run_impl_phase(tmp_config, "no-token-impl", task_dir, worktree_dir, 3)

    assert ok is False
    assert any(
        t == "agent_ambiguous" and p.get("phase") == "implementing"
        for t, p in events
    )


@pytest.mark.asyncio
async def test_impl_phase_stalls_when_implementor_done_without_progress(
    tmp_config,
    monkeypatch,
):
    """Implementor returns IMPLEMENT_DONE but the worktree is byte-identical.
    This is the observed WF2 failure mode (files written but never committed,
    or no files written at all). Harness must emit agent_stall + escalate
    instead of letting the reviewer run again on stale state."""
    from backend import agents as A

    _make_task(tmp_config, "stall-impl", "implementing")
    task_dir = S.find_task_workspace(tmp_config, "stall-impl")
    assert task_dir is not None
    W.create_worktree(tmp_config, "stall-impl")
    worktree_dir = W.project_worktree_path(tmp_config, "stall-impl")

    events: list[tuple[str, dict[str, object]]] = []

    async def fake_emit(event_type, *, task_id=None, agent=None, iteration=None, **payload):
        events.append((event_type, payload))

    async def fake_run_agent(spec, prompt, *, cwd, task_id=None, iteration=None, hooks=None, **kw):
        return A.AgentResult(
            text="I did nothing but declare done.\nIMPLEMENT_DONE\n",
            tool_uses=[],
            stop_reason="end_turn",
        )

    monkeypatch.setattr(P, "emit", fake_emit)
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    ok = await P.run_impl_phase(tmp_config, "stall-impl", task_dir, worktree_dir, 3)

    assert ok is False
    assert any(
        t == "agent_stall" and p.get("phase") == "implementing"
        for t, p in events
    )


@pytest.mark.asyncio
async def test_impl_phase_auto_commits_dirty_worktree_on_done(
    tmp_config,
    monkeypatch,
):
    """Implementor writes a file but forgets to commit. Harness should
    auto-commit so HEAD advances and the reviewer sees the work."""
    from backend import agents as A

    _make_task(tmp_config, "auto-commit", "implementing")
    task_dir = S.find_task_workspace(tmp_config, "auto-commit")
    assert task_dir is not None
    W.create_worktree(tmp_config, "auto-commit")
    worktree_dir = W.project_worktree_path(tmp_config, "auto-commit")

    events: list[tuple[str, dict[str, object]]] = []

    async def fake_emit(event_type, *, task_id=None, agent=None, iteration=None, **payload):
        events.append((event_type, payload))

    async def fake_run_agent(spec, prompt, *, cwd, task_id=None, iteration=None, hooks=None, **kw):
        if spec.name == "implementor":
            # Simulate implementor writing a file but NOT committing.
            (worktree_dir / "NewFile.swift").write_text("// generated\n", encoding="utf-8")
            return A.AgentResult(
                text="Wrote NewFile.swift.\nIMPLEMENT_DONE\n",
                tool_uses=[],
                stop_reason="end_turn",
            )
        return A.AgentResult(
            text="Looks good.\nIMPLEMENT_PASS\n",
            tool_uses=[],
            stop_reason="end_turn",
        )

    monkeypatch.setattr(P, "emit", fake_emit)
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    async def fake_resolve_test_commands(config, worktree_dir, task_id):
        return "echo unit", "echo ui"

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve_test_commands)

    ok = await P.run_impl_phase(tmp_config, "auto-commit", task_dir, worktree_dir, 3)

    assert ok is True
    progress = [p for t, p in events if t == "iter_progress" and p.get("phase") == "implementing"]
    assert progress, "iter_progress event expected for implementing phase"
    assert progress[0].get("auto_committed") is True
    assert progress[0].get("pre_sha") != progress[0].get("post_sha")


def test_maybe_auto_commit_worktree_commits_dirty_changes(tmp_path):
    """Direct unit test of the auto-commit helper."""
    import subprocess

    worktree = tmp_path / "repo"
    worktree.mkdir()
    subprocess.run(["git", "init", "-q", str(worktree)], check=True)
    subprocess.run(["git", "-C", str(worktree), "config", "user.email", "t@t.t"], check=True)
    subprocess.run(["git", "-C", str(worktree), "config", "user.name", "t"], check=True)
    (worktree / "seed.txt").write_text("seed\n")
    subprocess.run(["git", "-C", str(worktree), "add", "-A"], check=True)
    subprocess.run(
        ["git", "-C", str(worktree), "commit", "-q", "-m", "seed"], check=True
    )

    # Clean tree → no commit.
    assert P._maybe_auto_commit_worktree(worktree, "noop") is False

    # Dirty tree → commit.
    (worktree / "new.txt").write_text("new\n")
    sha_before = P._head_sha(worktree)
    assert P._maybe_auto_commit_worktree(worktree, "test") is True
    sha_after = P._head_sha(worktree)
    assert sha_before != sha_after


@pytest.mark.asyncio
async def test_impl_phase_proceeds_past_implementor_on_done_token(
    tmp_config,
    monkeypatch,
):
    """With a clean IMPLEMENT_DONE and real progress, the phase should enter
    the reviewer loop."""
    from backend import agents as A

    _make_task(tmp_config, "done-impl", "implementing")
    task_dir = S.find_task_workspace(tmp_config, "done-impl")
    assert task_dir is not None
    W.create_worktree(tmp_config, "done-impl")
    worktree_dir = W.project_worktree_path(tmp_config, "done-impl")

    call_log: list[str] = []

    async def fake_emit(event_type, **payload):
        pass

    async def fake_run_agent(spec, prompt, *, cwd, task_id=None, iteration=None, hooks=None, **kw):
        call_log.append(spec.name)
        if spec.name == "implementor":
            # Simulate real progress so stall detection doesn't short-circuit.
            (worktree_dir / "Progress.swift").write_text("// work\n", encoding="utf-8")
            return A.AgentResult(text="All good.\nIMPLEMENT_DONE\n", tool_uses=[], stop_reason="end_turn")
        # reviewer
        assert S.read_state(task_dir).state == "impl_review"
        return A.AgentResult(text="Looks good.\nIMPLEMENT_PASS\n", tool_uses=[], stop_reason="end_turn")

    monkeypatch.setattr(P, "emit", fake_emit)
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    async def fake_resolve_test_commands(config, worktree_dir, task_id):
        return "echo unit", "echo ui"

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve_test_commands)

    ok = await P.run_impl_phase(tmp_config, "done-impl", task_dir, worktree_dir, 3)

    assert ok is True
    assert call_log[0] == "implementor"
    assert call_log[1] == "implement-reviewer"


@pytest.mark.asyncio
async def test_resume_from_review_rework_restores_implementing_state_and_guard(
    tmp_config,
    monkeypatch,
):
    """Reviewer-only resume can still route back through implementor rework."""
    from backend import agents as A

    _make_task(tmp_config, "review-rework", "impl_review")
    task_dir = S.find_task_workspace(tmp_config, "review-rework")
    assert task_dir is not None
    W.create_worktree(tmp_config, "review-rework")
    worktree_dir = W.project_worktree_path(tmp_config, "review-rework")

    reviewer_calls = 0
    rework_hooks: list[object] = []

    async def fake_emit(event_type, **payload):
        pass

    async def fake_run_agent(spec, prompt, *, cwd, task_id=None, iteration=None, hooks=None, **kw):
        nonlocal reviewer_calls
        if spec.name == "implement-reviewer":
            reviewer_calls += 1
            assert S.read_state(task_dir).state == "impl_review"
            if reviewer_calls == 1:
                return A.AgentResult(
                    text="Needs implementor rework.\nIMPLEMENT_REWORK_REQUIRED\n",
                    tool_uses=[],
                    stop_reason="end_turn",
                )
            return A.AgentResult(text="Looks good.\nIMPLEMENT_PASS\n", tool_uses=[], stop_reason="end_turn")

        assert spec.name == "implementor"
        assert S.read_state(task_dir).state == "implementing"
        rework_hooks.append(hooks)
        (worktree_dir / "Rework.swift").write_text("// rework\n", encoding="utf-8")
        return A.AgentResult(text="Reworked.\nIMPLEMENT_DONE\n", tool_uses=[], stop_reason="end_turn")

    monkeypatch.setattr(P, "emit", fake_emit)
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    async def fake_resolve_test_commands(config, worktree_dir, task_id):
        return "echo unit", "echo ui"

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve_test_commands)

    ok = await P.run_impl_phase(
        tmp_config,
        "review-rework",
        task_dir,
        worktree_dir,
        3,
        skip_implementor=True,
    )

    assert ok is True
    assert reviewer_calls == 2
    assert rework_hooks and rework_hooks[0] is not None


@pytest.mark.asyncio
async def test_impl_phase_passes_new_swift_file_list_to_reviewer_prompt(
    tmp_config,
    monkeypatch,
):
    import subprocess

    from backend import agents as A

    task_id = "reviewer-prompt-swift-list"
    task_input = tmp_config.todo_dir / task_id
    task_input.mkdir(parents=True, exist_ok=True)
    (task_input / "spec.md").write_text("# prompt list\n", encoding="utf-8")
    W.create_worktree(tmp_config, task_id)
    task_dir = S.transition(tmp_config, task_id, "implementing")
    worktree_dir = W.project_worktree_path(tmp_config, task_id)

    seeded_new_file = worktree_dir / "Woontech" / "NewFile.swift"
    seeded_new_file.parent.mkdir(parents=True, exist_ok=True)
    seeded_new_file.write_text("// seeded\n", encoding="utf-8")
    subprocess.run(["git", "-C", str(worktree_dir), "add", "-A"], check=True)
    subprocess.run(
        ["git", "-C", str(worktree_dir), "commit", "-m", "seed new swift file"],
        check=True,
        capture_output=True,
        text=True,
    )

    reviewer_prompts: list[str] = []

    async def fake_emit(event_type, **payload):
        pass

    async def fake_run_agent(spec, prompt, *, cwd, task_id=None, iteration=None, hooks=None, **kw):
        if spec.name == "implementor":
            seeded_new_file.write_text("// seeded\n// touched\n", encoding="utf-8")
            return A.AgentResult(text="Implemented.\nIMPLEMENT_DONE\n", tool_uses=[], stop_reason="end_turn")
        reviewer_prompts.append(prompt)
        return A.AgentResult(text="Looks good.\nIMPLEMENT_PASS\n", tool_uses=[], stop_reason="end_turn")

    monkeypatch.setattr(P, "emit", fake_emit)
    monkeypatch.setattr(P.A, "run_agent", fake_run_agent)

    async def fake_resolve_test_commands(config, worktree_dir, task_id):
        return "echo unit", "echo ui"

    monkeypatch.setattr(P, "_resolve_test_commands", fake_resolve_test_commands)

    ok = await P.run_impl_phase(
        tmp_config,
        task_id,
        task_dir,
        worktree_dir,
        3,
    )

    assert ok is True
    assert reviewer_prompts
    assert f"New `.swift` files added in this worktree vs {tmp_config.main_branch}:" in reviewer_prompts[0]
    assert "- Woontech/NewFile.swift" in reviewer_prompts[0]


@pytest.mark.asyncio
async def test_run_pipeline_resumes_plan_unexpected_error_into_monorepo_project_dir(
    monorepo_config,
    monkeypatch,
):
    task_id = "WF2-saju-input"
    _make_task(monorepo_config, task_id, "needs_attention", escalation="plan_unexpected_error")

    expected = W.project_worktree_path(monorepo_config, task_id)
    plan_calls: list[tuple[str, str | None, str]] = []

    async def fake_plan(config, task_id, task_dir, worktree_dir, max_retries):
        state = S.read_state(task_dir)
        plan_calls.append((state.state, state.escalation, str(worktree_dir)))
        assert worktree_dir == expected
        assert worktree_dir.exists()
        return True

    async def fake_impl(*args, **kwargs):
        return True

    async def fake_publish(*args, **kwargs):
        return True

    monkeypatch.setattr(P, "run_plan_phase", fake_plan)
    monkeypatch.setattr(P, "run_impl_phase", fake_impl)
    monkeypatch.setattr(P, "run_publish_phase", fake_publish)
    monkeypatch.setattr(P.W, "remove_worktree", lambda *args, **kwargs: None)

    await P.run_pipeline(monorepo_config, task_id)

    assert plan_calls == [("planning", None, str(expected))]


def _bash_callback(worktree_dir, *, bash_policy):
    return W.make_path_guard(worktree_dir, bash_policy=bash_policy)["PreToolUse"][0].hooks[0]


def _bash_result(callback, command: str):
    return asyncio.run(
        callback({"tool_name": "Bash", "tool_input": {"command": command}}, None, None)
    )


def test_reviewer_bash_policy_allows_exact_resolved_test_commands(tmp_config):
    unit_cmd = "xcodebuild test -scheme Woontech -only-testing:WoontechTests/FooTests"
    ui_cmd = "echo 'SKIP: no changed ui test files in this worktree'"
    policy = P._reviewer_bash_policy(tmp_config, unit_cmd, ui_cmd)
    callback = _bash_callback(tmp_config.worktree_path("review-guard"), bash_policy=policy)

    assert _bash_result(callback, unit_cmd) == {}
    assert _bash_result(callback, ui_cmd) == {}


def test_common_bash_policy_allows_pwd_and_ls_diagnostics(tmp_config):
    worktree_dir = tmp_config.worktree_path("common-guard")
    worktree_dir.mkdir(parents=True)
    policy = P._common_git_bash_policy()
    callback = _bash_callback(worktree_dir, bash_policy=policy)

    assert _bash_result(callback, "pwd") == {}
    assert _bash_result(callback, "ls") == {}
    assert _bash_result(callback, "ls -la") == {}
    assert _bash_result(callback, f"ls -la {worktree_dir}") == {}


def test_reviewer_bash_policy_denies_pbxproj_grep_check(tmp_config):
    unit_cmd = "xcodebuild test -scheme Woontech -only-testing:WoontechTests/FooTests"
    ui_cmd = "echo 'SKIP: no changed ui test files in this worktree'"
    policy = P._reviewer_bash_policy(tmp_config, unit_cmd, ui_cmd)
    callback = _bash_callback(tmp_config.worktree_path("review-guard-deny"), bash_policy=policy)

    denied = _bash_result(callback, "grep -c Foo.swift Woontech.xcodeproj/project.pbxproj")

    assert denied["hookSpecificOutput"]["permissionDecision"] == "deny"


def test_publish_bash_policy_allows_push_and_pr_only(tmp_config):
    task_id = "publish-guard"
    policy = P._publish_bash_policy(task_id)
    callback = _bash_callback(tmp_config.worktree_path(task_id), bash_policy=policy)

    assert _bash_result(callback, f"git push -u origin {W.worktree_branch(task_id)}") == {}
    assert (
        _bash_result(
            callback,
            'gh pr create --title "T" --body "B" --base main --head feature/publish-guard',
        )
        == {}
    )
    denied = _bash_result(callback, "git fetch origin main")
    assert denied["hookSpecificOutput"]["permissionDecision"] == "deny"
