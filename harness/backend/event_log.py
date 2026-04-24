"""Persist implementation-phase events to a per-task JSONL log file.

Subscribes to the global event bus and writes matching events to
`<task_dir>/logs/impl-phase.jsonl`. Started by `run_pipeline` at task start
and cancelled at task end via `try/finally`.

Filter policy: keep events whose `task_id` matches AND that belong to the
implementation phase (state set, agent set, or phase-tagged payload).
"""
from __future__ import annotations

import asyncio
import json
from dataclasses import asdict
from pathlib import Path
from typing import Optional

from .events import bus


IMPL_AGENT_NAMES = {"implementor", "implement_reviewer"}
IMPL_PHASE_NAMES = {"implementing", "impl_review", "impl_rework"}
IMPL_STATE_NAMES = {"implementing", "impl_review"}
ALWAYS_LOG_TYPES = {"pipeline_started", "pipeline_resuming", "pipeline_done", "escalation"}


def _belongs_to_impl_phase(event_dict: dict) -> bool:
    if event_dict.get("type") in ALWAYS_LOG_TYPES:
        return True
    agent = event_dict.get("agent")
    if agent and agent in IMPL_AGENT_NAMES:
        return True
    payload = event_dict.get("payload") or {}
    phase = payload.get("phase")
    if phase and phase in IMPL_PHASE_NAMES:
        return True
    state = payload.get("state")
    if state and state in IMPL_STATE_NAMES:
        return True
    return False


class ImplPhaseEventLogger:
    """Background task that drains events from the bus into a JSONL file.

    Use as `async with ImplPhaseEventLogger(task_id, task_dir): ...` so the
    subscription is unwound and the file is closed even if the pipeline
    raises or is cancelled.
    """

    def __init__(self, task_id: str, task_dir: Path) -> None:
        self.task_id = task_id
        self.task_dir = task_dir
        self.log_path: Path = task_dir / "logs" / "impl-phase.jsonl"
        self._task: Optional[asyncio.Task] = None
        self._queue: Optional[asyncio.Queue] = None

    async def __aenter__(self) -> "ImplPhaseEventLogger":
        self.log_path.parent.mkdir(parents=True, exist_ok=True)
        self._queue = await bus.subscribe()
        self._task = asyncio.create_task(self._run(), name=f"event-log:{self.task_id}")
        return self

    async def __aexit__(self, exc_type, exc, tb) -> None:
        if self._task is not None:
            self._task.cancel()
            try:
                await self._task
            except (asyncio.CancelledError, Exception):
                pass
            self._task = None
        if self._queue is not None:
            await bus.unsubscribe(self._queue)
            self._queue = None

    async def _run(self) -> None:
        assert self._queue is not None
        try:
            with self.log_path.open("a", encoding="utf-8") as fh:
                while True:
                    event = await self._queue.get()
                    event_dict = asdict(event)
                    if event_dict.get("task_id") != self.task_id:
                        continue
                    if not _belongs_to_impl_phase(event_dict):
                        continue
                    fh.write(json.dumps(event_dict, ensure_ascii=False) + "\n")
                    fh.flush()
        except asyncio.CancelledError:
            raise
        except Exception:
            # Logging is best-effort; never break the pipeline because the
            # log file failed to write.
            return


__all__ = ("ImplPhaseEventLogger",)
