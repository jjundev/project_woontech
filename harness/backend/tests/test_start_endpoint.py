"""Integration test for POST /api/tasks/{id}/start and GET /api/tasks endpoints.

Validates the folder-discovery flow:
  1. Dashboard lists folders that contain spec.md
  2. /start 404s for an unknown id
  3. /start 400s when spec.md is missing from an existing folder
  4. /start 200s when spec.md is present and rejects double starts with 409
"""
from __future__ import annotations

import asyncio

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

    async def fake_pipeline(config, task_id, **kwargs):
        await asyncio.sleep(2)

    monkeypatch.setattr(pipeline, "run_pipeline", fake_pipeline)
    monkeypatch.setattr(server.P, "run_pipeline", fake_pipeline)

    server._running_pipelines.clear()

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
