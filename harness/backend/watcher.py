from __future__ import annotations

import asyncio
from pathlib import Path

from watchdog.events import FileSystemEvent, FileSystemEventHandler
from watchdog.observers import Observer

from .config import HarnessConfig
from .events import emit


class _Handler(FileSystemEventHandler):
    def __init__(self, loop: asyncio.AbstractEventLoop, config: HarnessConfig) -> None:
        super().__init__()
        self._loop = loop
        self._config = config

    def _emit(self, event_type: str, src_path: str) -> None:
        try:
            rel = Path(src_path).resolve().relative_to(self._config.ios_root.resolve())
        except ValueError:
            return
        parts = rel.parts
        if len(parts) < 2 or parts[0] not in ("todo", "ongoing", "done"):
            return
        task_id = parts[1]
        asyncio.run_coroutine_threadsafe(
            emit("file_changed", task_id=task_id, path=str(rel), change=event_type),
            self._loop,
        )

    def on_modified(self, event: FileSystemEvent) -> None:
        if not event.is_directory:
            self._emit("modified", event.src_path)

    def on_created(self, event: FileSystemEvent) -> None:
        if not event.is_directory:
            self._emit("created", event.src_path)

    def on_deleted(self, event: FileSystemEvent) -> None:
        if not event.is_directory:
            self._emit("deleted", event.src_path)


def start_watcher(config: HarnessConfig, loop: asyncio.AbstractEventLoop) -> Observer:
    observer = Observer()
    handler = _Handler(loop, config)
    for folder in (config.todo_dir, config.ongoing_dir, config.done_dir):
        folder.mkdir(parents=True, exist_ok=True)
        observer.schedule(handler, str(folder), recursive=True)
    observer.start()
    return observer
