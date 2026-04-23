from __future__ import annotations

import asyncio
from pathlib import Path

import pytest

from backend import spector_session as SS


class _FakeClient:
    """Fake ClaudeSDKClient with configurable behavior on receive_response."""

    def __init__(self, options=None, *, hang: bool = False, raise_exc: Exception | None = None):
        self.options = options
        self._hang = hang
        self._raise = raise_exc
        self.connected = False
        self.disconnected = False

    async def connect(self):
        self.connected = True

    async def disconnect(self):
        self.disconnected = True

    async def query(self, text: str):
        return None

    async def receive_response(self):
        if self._raise is not None:
            raise self._raise
        if self._hang:
            await asyncio.sleep(60)  # longer than any test timeout
        return
        yield  # pragma: no cover — make this an async generator


def _run(coro):
    return asyncio.run(coro)


def test_send_times_out_and_drops_session(monkeypatch, tmp_path: Path):
    monkeypatch.setattr(SS, "SPECTOR_TIMEOUT_SECS", 0.2)

    def make(options=None):
        return _FakeClient(options=options, hang=True)

    monkeypatch.setattr(SS, "ClaudeSDKClient", make)

    registry = SS.SpectorRegistry()
    task_dir = tmp_path / "task"
    task_dir.mkdir()

    with pytest.raises(asyncio.TimeoutError):
        _run(registry.send("t1", task_dir, "hello"))

    # session dropped so the next attempt starts fresh
    assert "t1" not in registry._sessions


def test_send_reraises_and_drops_on_exception(monkeypatch, tmp_path: Path):
    monkeypatch.setattr(SS, "SPECTOR_TIMEOUT_SECS", 5.0)

    boom = RuntimeError("kaboom")

    def make(options=None):
        return _FakeClient(options=options, raise_exc=boom)

    monkeypatch.setattr(SS, "ClaudeSDKClient", make)

    registry = SS.SpectorRegistry()
    task_dir = tmp_path / "task"
    task_dir.mkdir()

    with pytest.raises(RuntimeError, match="kaboom"):
        _run(registry.send("t2", task_dir, "hello"))

    assert "t2" not in registry._sessions
