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
        """Route a filesystem event to a task id if the path is recognizable.

        Sources:
          - `ios/todo/<id>/spec.md` — user-authored input in the root tree.
          - `worktrees/<id>/**` — pipeline-managed workspace + code inside the worktree.
        """
        resolved = Path(src_path).resolve()

        # 1. Root todo folder (input).
        try:
            rel = resolved.relative_to(self._config.todo_dir.resolve())
            if rel.parts:
                task_id = rel.parts[0]
                self._dispatch(event_type, task_id, f"todo/{rel}")
                return
        except ValueError:
            pass

        # 2. Worktree tree.
        try:
            rel = resolved.relative_to(self._config.worktrees_dir.resolve())
        except ValueError:
            return
        if not rel.parts:
            return
        task_id = rel.parts[0]
        self._dispatch(event_type, task_id, f"worktrees/{rel}")

    def _dispatch(self, event_type: str, task_id: str, rel: str) -> None:
        asyncio.run_coroutine_threadsafe(
            emit("file_changed", task_id=task_id, path=rel, change=event_type),
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
    config.todo_dir.mkdir(parents=True, exist_ok=True)
    config.worktrees_dir.mkdir(parents=True, exist_ok=True)
    observer.schedule(handler, str(config.todo_dir), recursive=True)
    observer.schedule(handler, str(config.worktrees_dir), recursive=True)
    observer.start()
    return observer
