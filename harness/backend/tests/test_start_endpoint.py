"""Integration test for POST /api/tasks/{id}/start endpoint.

Validates the three branches exercised by the new "click todo card to start" flow:
  1. spec.md missing       → 400
  2. spec.md present       → 200 + pipeline kicked off
  3. pipeline already busy → 409
"""
from __future__ import annotations

import asyncio
from typing import AsyncIterator

import pytest


@pytest.fixture
def client(tmp_config, monkeypatch):
    """Fresh FastAPI TestClient bound to a throwaway HarnessConfig.

    The server module loads config at import time, so we swap it out before
    TestClient is constructed. We also stub out pipeline execution and the
    file-watcher / spector-registry side effects that would otherwise fire.
    """
    from backend import server, pipeline, spector_session

    # Route all server-side references to our tmp_config.
    monkeypatch.setattr(server, "config", tmp_config, raising=True)
    monkeypatch.setattr(server.spector_registry, "_config", tmp_config, raising=False)

    # Replace pipeline.run_pipeline with a slow no-op so the "already running"
    # race is observable. Holding for 2s is plenty for the second POST.
    async def fake_pipeline(config, task_id, **kwargs):
        await asyncio.sleep(2)

    monkeypatch.setattr(pipeline, "run_pipeline", fake_pipeline)
    monkeypatch.setattr(server.P, "run_pipeline", fake_pipeline)

    # spector_registry.close is awaited inside /start; make it a no-op.
    async def fake_close(task_id):
        return None

    monkeypatch.setattr(spector_session.registry, "close", fake_close)
    monkeypatch.setattr(server.spector_registry, "close", fake_close)

    # Reset any leftover running pipelines between tests.
    server._running_pipelines.clear()

    # Disable the file-watcher lifespan so we don't spawn a real observer.
    from contextlib import asynccontextmanager

    @asynccontextmanager
    async def noop_lifespan(app):
        yield

    monkeypatch.setattr(server, "lifespan", noop_lifespan)
    server.app.router.lifespan_context = noop_lifespan

    from fastapi.testclient import TestClient

    with TestClient(server.app) as c:
        yield c


def test_start_without_spec_returns_400(client, tmp_config):
    r = client.post("/api/tasks", json={"title": "No spec"})
    assert r.status_code == 200
    task_id = r.json()["id"]

    r = client.post(f"/api/tasks/{task_id}/start", json={})
    assert r.status_code == 400
    assert "spec.md" in r.json()["detail"]


def test_start_with_spec_succeeds_and_rejects_double_start(client, tmp_config):
    r = client.post("/api/tasks", json={"title": "Has spec"})
    task_id = r.json()["id"]

    # Drop spec.md into the task folder.
    spec = tmp_config.todo_dir / task_id / "spec.md"
    spec.write_text("# spec\n")

    r = client.post(f"/api/tasks/{task_id}/start", json={})
    assert r.status_code == 200, r.text
    assert r.json() == {"ok": True}

    # Second call while the fake pipeline is still "running" → 409.
    r = client.post(f"/api/tasks/{task_id}/start", json={})
    assert r.status_code == 409
    assert "already running" in r.json()["detail"]


def test_start_missing_task_returns_404(client):
    r = client.post("/api/tasks/does-not-exist/start", json={})
    assert r.status_code == 404
