from __future__ import annotations

import asyncio
import json
import time
from contextvars import ContextVar, Token
from dataclasses import dataclass, field, asdict
from typing import Any, Optional


_current_run_id: ContextVar[Optional[str]] = ContextVar("harness_run_id", default=None)


@dataclass
class Event:
    type: str
    task_id: Optional[str] = None
    run_id: Optional[str] = None
    agent: Optional[str] = None
    iteration: Optional[int] = None
    payload: dict[str, Any] = field(default_factory=dict)
    ts: float = field(default_factory=time.time)

    def to_json(self) -> str:
        return json.dumps(asdict(self))


class EventBus:
    """Single-process pub/sub for pipeline events. Subscribers are asyncio.Queue instances."""

    def __init__(self) -> None:
        self._subscribers: set[asyncio.Queue[Event]] = set()
        self._lock = asyncio.Lock()

    async def subscribe(self) -> asyncio.Queue[Event]:
        queue: asyncio.Queue[Event] = asyncio.Queue(maxsize=1024)
        async with self._lock:
            self._subscribers.add(queue)
        return queue

    async def unsubscribe(self, queue: asyncio.Queue[Event]) -> None:
        async with self._lock:
            self._subscribers.discard(queue)

    async def emit(self, event: Event) -> None:
        async with self._lock:
            subs = list(self._subscribers)
        for q in subs:
            try:
                q.put_nowait(event)
            except asyncio.QueueFull:
                # drop oldest to make room
                try:
                    q.get_nowait()
                    q.put_nowait(event)
                except Exception:
                    pass


bus = EventBus()


def set_current_run_id(run_id: Optional[str]) -> Token[Optional[str]]:
    return _current_run_id.set(run_id)


def reset_current_run_id(token: Token[Optional[str]]) -> None:
    _current_run_id.reset(token)


async def emit(
    type: str,
    *,
    task_id: Optional[str] = None,
    run_id: Optional[str] = None,
    agent: Optional[str] = None,
    iteration: Optional[int] = None,
    **payload: Any,
) -> None:
    await bus.emit(
        Event(
            type=type,
            task_id=task_id,
            run_id=run_id if run_id is not None else _current_run_id.get(),
            agent=agent,
            iteration=iteration,
            payload=payload,
        )
    )
