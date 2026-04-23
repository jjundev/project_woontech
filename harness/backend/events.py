from __future__ import annotations

import asyncio
import json
import time
from dataclasses import dataclass, field, asdict
from typing import Any, Optional


@dataclass
class Event:
    type: str
    task_id: Optional[str] = None
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


async def emit(
    type: str,
    *,
    task_id: Optional[str] = None,
    agent: Optional[str] = None,
    iteration: Optional[int] = None,
    **payload: Any,
) -> None:
    await bus.emit(Event(type=type, task_id=task_id, agent=agent, iteration=iteration, payload=payload))
