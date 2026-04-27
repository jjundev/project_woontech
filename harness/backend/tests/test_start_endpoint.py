"""Integration test for POST /api/tasks/{id}/start and GET /api/tasks endpoints.

Validates the folder-discovery flow:
  1. Dashboard lists folders that contain spec.md
  2. /start 404s for an unknown id
  3. /start 400s when spec.md is missing from an existing folder
  4. /start 200s when spec.md is present and rejects double starts with 409
"""
from __future__ import annotations

import asyncio
import time

import pytest


@pytest.fixture
def client(tmp_config, monkeypatch):
    """Fresh FastAPI TestClient bound to a throwaway HarnessConfig.

    The server module loads config at import time, so we swap it out before
    TestClient is constructed. Pipeline execution and the file-watcher are
    stubbed so no real work fires.
    """
    from backend import server, pipeline

    monkeypatch.setattr(server, "config", tmp_config, raising=True)
    pipeline_invocations: list[dict[str, object]] = []

    async def fake_pipeline(config, task_id, **kwargs):
        task_dir = server.S.find_task_dir(config, task_id)
        state_name = None
        escalation = None
        paused_from = None
        if (task_dir / "state.json").exists():
            state = server.S.read_state(task_dir)
            state_name = state.state
            escalation = state.escalation
            paused_from = state.paused_from
        pipeline_invocations.append(
            {
                "task_id": task_id,
                "state": state_name,
                "escalation": escalation,
                "paused_from": paused_from,
                "kwargs": kwargs,
            }
        )
        await asyncio.sleep(2)

    monkeypatch.setattr(pipeline, "run_pipeline", fake_pipeline)
    monkeypatch.setattr(server.P, "run_pipeline", fake_pipeline)

    server._running_pipelines.clear()
    server.app.state.pipeline_invocations = pipeline_invocations

    from contextlib import asynccontextmanager

    @asynccontextmanager
    async def noop_lifespan(app):
        yield

    monkeypatch.setattr(server, "lifespan", noop_lifespan)
    server.app.router.lifespan_context = noop_lifespan

    from fastapi.testclient import TestClient

    with TestClient(server.app) as c:
        yield c


def _make_folder(tmp_config, task_id: str, *, with_spec: bool):
    d = tmp_config.todo_dir / task_id
    d.mkdir(parents=True)
    if with_spec:
        (d / "spec.md").write_text("# test\n", encoding="utf-8")
    return d


def test_list_tasks_discovers_folders_with_spec(client, tmp_config):
    _make_folder(tmp_config, "WF1", with_spec=True)
    _make_folder(tmp_config, "WF2-no-spec", with_spec=False)

    r = client.get("/api/tasks")
    assert r.status_code == 200
    ids = {t["id"] for t in r.json()}
    assert ids == {"WF1"}


def test_start_without_spec_returns_400(client, tmp_config):
    _make_folder(tmp_config, "no-spec", with_spec=False)

    r = client.post("/api/tasks/no-spec/start", json={})
    assert r.status_code == 400
    assert "spec.md" in r.json()["detail"]


def test_start_missing_task_returns_404(client):
    r = client.post("/api/tasks/does-not-exist/start", json={})
    assert r.status_code == 404


def test_start_with_spec_succeeds_and_rejects_double_start(client, tmp_config):
    _make_folder(tmp_config, "ready", with_spec=True)

    r = client.post("/api/tasks/ready/start", json={})
    assert r.status_code == 200, r.text
    assert r.json() == {"ok": True}

    # Second call while the fake pipeline is still "running" → 409.
    r = client.post("/api/tasks/ready/start", json={})
    assert r.status_code == 409
    assert "already running" in r.json()["detail"]


def test_get_plan_steps_returns_current_plan(client, tmp_config):
    from backend import state as S

    _make_folder(tmp_config, "with-plan", with_spec=True)
    task_dir = S.transition(tmp_config, "with-plan", "implementing")
    (task_dir / "implement-plan.md").write_text(
        "# Plan\n\n## Implementation steps\n1. First step\n2. Second step\n",
        encoding="utf-8",
    )

    r = client.get("/api/tasks/with-plan/plan-steps")
    assert r.status_code == 200, r.text
    assert r.json() == {
        "steps": [
            {"index": 1, "title": "First step"},
            {"index": 2, "title": "Second step"},
        ]
    }


def test_get_plan_steps_returns_empty_without_plan(client, tmp_config):
    _make_folder(tmp_config, "without-plan", with_spec=True)

    r = client.get("/api/tasks/without-plan/plan-steps")
    assert r.status_code == 200, r.text
    assert r.json() == {"steps": []}


def test_resume_preserves_escalation_until_pipeline_starts(client, tmp_config):
    from backend import state as S

    _make_folder(tmp_config, "resume-me", with_spec=True)
    task_dir = S.transition(tmp_config, "resume-me", "needs_attention")
    state = S.read_state(task_dir)
    state.escalation = "impl_review_exhausted"
    S.write_state(task_dir, state)

    r = client.post("/api/tasks/resume-me/resume", json={})
    assert r.status_code == 200, r.text

    deadline = time.time() + 1
    while time.time() < deadline and not client.app.state.pipeline_invocations:
        time.sleep(0.01)

    assert client.app.state.pipeline_invocations
    assert client.app.state.pipeline_invocations[0]["task_id"] == "resume-me"
    assert client.app.state.pipeline_invocations[0]["state"] == "needs_attention"
    assert client.app.state.pipeline_invocations[0]["escalation"] == "impl_review_exhausted"

    resumed_state = S.read_state(S.find_task_dir(tmp_config, "resume-me"))
    assert resumed_state.state == "needs_attention"
    assert resumed_state.escalation == "impl_review_exhausted"


def test_resume_accepts_paused_state(client, tmp_config):
    from backend import state as S

    _make_folder(tmp_config, "resume-paused", with_spec=True)
    task_dir = S.transition(tmp_config, "resume-paused", "implementing")
    state = S.read_state(task_dir)
    state.state = "paused"
    state.paused_from = "implementing"
    S.write_state(task_dir, state)

    r = client.post("/api/tasks/resume-paused/resume", json={})
    assert r.status_code == 200, r.text

    deadline = time.time() + 1
    while time.time() < deadline and not client.app.state.pipeline_invocations:
        time.sleep(0.01)

    assert client.app.state.pipeline_invocations
    assert client.app.state.pipeline_invocations[0]["task_id"] == "resume-paused"
    assert client.app.state.pipeline_invocations[0]["state"] == "paused"
    assert client.app.state.pipeline_invocations[0]["paused_from"] == "implementing"


def test_resume_from_review_passes_resume_from_to_pipeline(client, tmp_config, monkeypatch):
    from backend import server
    from backend import state as S

    _make_folder(tmp_config, "resume-review", with_spec=True)
    task_dir = S.transition(tmp_config, "resume-review", "impl_review")
    state = S.read_state(task_dir)
    state.state = "paused"
    state.paused_from = "impl_review"
    S.write_state(task_dir, state)

    monkeypatch.setattr(server.W, "worktree_is_reusable", lambda config, task_id: True)
    monkeypatch.setattr(
        server.W,
        "worktree_status",
        lambda config, task_id: {"commits_ahead": 1},
    )

    r = client.post("/api/tasks/resume-review/resume", json={"resume_from": "impl_review"})
    assert r.status_code == 200, r.text

    deadline = time.time() + 1
    while time.time() < deadline and not client.app.state.pipeline_invocations:
        time.sleep(0.01)

    assert client.app.state.pipeline_invocations
    invocation = client.app.state.pipeline_invocations[0]
    assert invocation["task_id"] == "resume-review"
    assert invocation["state"] == "paused"
    assert invocation["paused_from"] == "impl_review"
    assert invocation["kwargs"]["resume_from"] == "impl_review"


def test_resume_from_review_rejects_non_review_pause(client, tmp_config):
    from backend import state as S

    _make_folder(tmp_config, "resume-wrong-phase", with_spec=True)
    task_dir = S.transition(tmp_config, "resume-wrong-phase", "implementing")
    state = S.read_state(task_dir)
    state.state = "paused"
    state.paused_from = "implementing"
    S.write_state(task_dir, state)

    r = client.post(
        "/api/tasks/resume-wrong-phase/resume",
        json={"resume_from": "impl_review"},
    )

    assert r.status_code == 400
    assert "requires task to be at impl_review" in r.json()["detail"]


def test_resume_from_ui_verify_passes_resume_from_to_pipeline(client, tmp_config, monkeypatch):
    from backend import server
    from backend import state as S

    _make_folder(tmp_config, "resume-ui", with_spec=True)
    task_dir = S.transition(tmp_config, "resume-ui", "ui_verify")
    state = S.read_state(task_dir)
    state.state = "needs_attention"
    state.escalation = "ui_verify_review_ambiguous"
    S.write_state(task_dir, state)

    monkeypatch.setattr(server.W, "worktree_is_reusable", lambda config, task_id: True)
    monkeypatch.setattr(
        server.W,
        "worktree_status",
        lambda config, task_id: {"commits_ahead": 1},
    )

    r = client.post("/api/tasks/resume-ui/resume", json={"resume_from": "ui_verify"})
    assert r.status_code == 200, r.text

    deadline = time.time() + 1
    while time.time() < deadline and not client.app.state.pipeline_invocations:
        time.sleep(0.01)

    assert client.app.state.pipeline_invocations
    invocation = client.app.state.pipeline_invocations[0]
    assert invocation["task_id"] == "resume-ui"
    assert invocation["kwargs"]["resume_from"] == "ui_verify"


def test_resume_from_ui_verify_allows_non_ui_escalation(client, tmp_config, monkeypatch):
    """ui_verify resume only requires worktree+commits, not a specific state.

    User may want to force a UI re-verification even from a task that paused
    on a different escalation.
    """
    from backend import server
    from backend import state as S

    _make_folder(tmp_config, "resume-ui-from-impl", with_spec=True)
    task_dir = S.transition(tmp_config, "resume-ui-from-impl", "needs_attention")
    state = S.read_state(task_dir)
    state.escalation = "impl_review_exhausted"
    S.write_state(task_dir, state)

    monkeypatch.setattr(server.W, "worktree_is_reusable", lambda config, task_id: True)
    monkeypatch.setattr(
        server.W,
        "worktree_status",
        lambda config, task_id: {"commits_ahead": 3},
    )

    r = client.post(
        "/api/tasks/resume-ui-from-impl/resume",
        json={"resume_from": "ui_verify"},
    )
    assert r.status_code == 200, r.text


def test_resume_from_ui_verify_rejects_no_worktree(client, tmp_config, monkeypatch):
    from backend import server
    from backend import state as S

    _make_folder(tmp_config, "resume-ui-no-worktree", with_spec=True)
    task_dir = S.transition(tmp_config, "resume-ui-no-worktree", "needs_attention")
    state = S.read_state(task_dir)
    state.escalation = "ui_verify_review_ambiguous"
    S.write_state(task_dir, state)

    monkeypatch.setattr(server.W, "worktree_is_reusable", lambda config, task_id: False)

    r = client.post(
        "/api/tasks/resume-ui-no-worktree/resume",
        json={"resume_from": "ui_verify"},
    )
    assert r.status_code == 400
    assert "reusable worktree" in r.json()["detail"]


def test_resume_from_ui_verify_rejects_no_commits_ahead(client, tmp_config, monkeypatch):
    from backend import server
    from backend import state as S

    _make_folder(tmp_config, "resume-ui-no-commits", with_spec=True)
    task_dir = S.transition(tmp_config, "resume-ui-no-commits", "needs_attention")
    state = S.read_state(task_dir)
    state.escalation = "ui_verify_review_ambiguous"
    S.write_state(task_dir, state)

    monkeypatch.setattr(server.W, "worktree_is_reusable", lambda config, task_id: True)
    monkeypatch.setattr(
        server.W,
        "worktree_status",
        lambda config, task_id: {"commits_ahead": 0},
    )

    r = client.post(
        "/api/tasks/resume-ui-no-commits/resume",
        json={"resume_from": "ui_verify"},
    )
    assert r.status_code == 400
    assert "commits ahead" in r.json()["detail"]


def test_resume_requires_needs_attention(client, tmp_config):
    from backend import state as S

    _make_folder(tmp_config, "not-paused", with_spec=True)
    S.transition(tmp_config, "not-paused", "planning")

    r = client.post("/api/tasks/not-paused/resume", json={})
    assert r.status_code == 400
    assert "needs_attention" in r.json()["detail"]


def test_pause_persists_paused_from_and_emits_state(client, tmp_config, monkeypatch):
    from backend import server
    from backend import state as S

    events: list[tuple[str, str | None, dict[str, object]]] = []

    async def fake_emit(event_type: str, *, task_id=None, agent=None, iteration=None, **payload):
        events.append((event_type, task_id, payload))

    monkeypatch.setattr(server, "emit", fake_emit)

    _make_folder(tmp_config, "pause-me", with_spec=True)
    S.transition(tmp_config, "pause-me", "implementing")

    r = client.post("/api/tasks/pause-me/start", json={})
    assert r.status_code == 200, r.text

    r = client.post("/api/tasks/pause-me/pause")
    assert r.status_code == 200, r.text

    paused = S.read_state(S.find_task_dir(tmp_config, "pause-me"))
    assert paused.state == "paused"
    assert paused.paused_from == "implementing"
    assert ("state_changed", "pause-me", {"state": "paused", "paused_from": "implementing"}) in events


def test_pause_persists_impl_review_as_paused_from(client, tmp_config, monkeypatch):
    from backend import server
    from backend import state as S

    events: list[tuple[str, str | None, dict[str, object]]] = []

    async def fake_emit(event_type: str, *, task_id=None, agent=None, iteration=None, **payload):
        events.append((event_type, task_id, payload))

    monkeypatch.setattr(server, "emit", fake_emit)

    _make_folder(tmp_config, "pause-review", with_spec=True)
    S.transition(tmp_config, "pause-review", "impl_review")

    r = client.post("/api/tasks/pause-review/start", json={})
    assert r.status_code == 200, r.text

    r = client.post("/api/tasks/pause-review/pause")
    assert r.status_code == 200, r.text

    paused = S.read_state(S.find_task_dir(tmp_config, "pause-review"))
    assert paused.state == "paused"
    assert paused.paused_from == "impl_review"
    assert ("state_changed", "pause-review", {"state": "paused", "paused_from": "impl_review"}) in events


def test_list_tasks_includes_paused_task(client, tmp_config):
    from backend import state as S

    _make_folder(tmp_config, "paused-task", with_spec=True)
    task_dir = S.transition(tmp_config, "paused-task", "publishing")
    state = S.read_state(task_dir)
    state.state = "paused"
    state.paused_from = "publishing"
    S.write_state(task_dir, state)

    r = client.get("/api/tasks")
    assert r.status_code == 200
    tasks = {t["id"]: t for t in r.json()}
    assert tasks["paused-task"]["state"] == "paused"
    assert tasks["paused-task"]["paused_from"] == "publishing"


@pytest.mark.asyncio
async def test_launch_pipeline_task_cleans_up_finished_registry_entry(tmp_config, monkeypatch):
    from backend import server, pipeline

    monkeypatch.setattr(server, "config", tmp_config, raising=True)
    server._running_pipelines.clear()

    async def quick_pipeline(config, task_id, **kwargs):
        await asyncio.sleep(0)

    monkeypatch.setattr(pipeline, "run_pipeline", quick_pipeline)
    monkeypatch.setattr(server.P, "run_pipeline", quick_pipeline)

    task = server._launch_pipeline_task("cleanup-me", server.StartPipelineReq())
    assert server._running_pipelines["cleanup-me"] is task

    await task
    await asyncio.sleep(0)

    assert "cleanup-me" not in server._running_pipelines
