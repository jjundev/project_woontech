from __future__ import annotations

import pytest

from backend import pipeline as P
from backend import state as S


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


@pytest.mark.asyncio
async def test_run_pipeline_resumes_from_impl_state(tmp_config, monkeypatch):
    _make_task(tmp_config, "resume-impl", "implementing")
    tmp_config.worktree_path("resume-impl").mkdir(parents=True, exist_ok=True)

    calls: list[tuple[str, str, str | None]] = []

    async def fake_plan(*args, **kwargs):
        calls.append(("plan", "", None))
        return True

    async def fake_impl(config, task_id, task_dir, worktree_dir, max_retries):
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
async def test_run_pipeline_resumes_impl_from_needs_attention(tmp_config, monkeypatch):
    _make_task(tmp_config, "resume-needs-impl", "needs_attention", escalation="impl_review_exhausted")
    tmp_config.worktree_path("resume-needs-impl").mkdir(parents=True, exist_ok=True)

    calls: list[tuple[str, str, str | None]] = []

    async def fake_plan(*args, **kwargs):
        calls.append(("plan", "", None))
        return True

    async def fake_impl(config, task_id, task_dir, worktree_dir, max_retries):
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

    async def fake_impl(config, task_id, task_dir, worktree_dir, max_retries):
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
