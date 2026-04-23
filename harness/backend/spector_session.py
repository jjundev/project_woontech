"""Interactive spector chat sessions keyed by task_id."""
from __future__ import annotations

import asyncio
import logging
import os
from dataclasses import dataclass, field
from pathlib import Path

from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    ClaudeSDKClient,
    ResultMessage,
    TextBlock,
    ToolUseBlock,
)

from .agents.spector import SPECTOR
from .config import HarnessConfig
from .events import emit


log = logging.getLogger("harness.spector")


def _default_timeout() -> float:
    raw = os.environ.get("SPECTOR_TIMEOUT_SECS", "180")
    try:
        return float(raw)
    except ValueError:
        return 180.0


SPECTOR_TIMEOUT_SECS: float = _default_timeout()


@dataclass
class SpectorSession:
    task_id: str
    task_dir: Path
    client: ClaudeSDKClient
    lock: asyncio.Lock = field(default_factory=asyncio.Lock)
    confirmed: bool = False


class SpectorRegistry:
    def __init__(self) -> None:
        self._sessions: dict[str, SpectorSession] = {}
        self._lock = asyncio.Lock()
        self._config: HarnessConfig | None = None

    def set_config(self, config: HarnessConfig) -> None:
        """Install the runtime config so spector picks up the per-agent model
        override from `harness.config.yaml`. Called once at server startup."""
        self._config = config

    async def get_or_create(self, task_id: str, task_dir: Path) -> SpectorSession:
        async with self._lock:
            sess = self._sessions.get(task_id)
            if sess is not None:
                return sess
            model = SPECTOR.model
            if self._config is not None:
                override = self._config.agent_models.get(SPECTOR.name)
                if override is not None:
                    model = override
            options = ClaudeAgentOptions(
                system_prompt=SPECTOR.system_prompt,
                allowed_tools=SPECTOR.allowed_tools,
                cwd=str(task_dir),
                permission_mode=SPECTOR.permission_mode,
                max_turns=SPECTOR.max_turns,
                **({"model": model} if model else {}),
            )
            client = ClaudeSDKClient(options=options)
            await client.connect()
            sess = SpectorSession(task_id=task_id, task_dir=task_dir, client=client)
            self._sessions[task_id] = sess
            return sess

    async def _drop(self, task_id: str) -> None:
        async with self._lock:
            sess = self._sessions.pop(task_id, None)
        if sess is not None:
            try:
                await sess.client.disconnect()
            except Exception:
                log.exception("spector[%s] disconnect failed", task_id)

    async def send(self, task_id: str, task_dir: Path, text: str) -> str:
        sess = await self.get_or_create(task_id, task_dir)
        async with sess.lock:
            log.info("spector[%s] send start (%d chars)", task_id, len(text))
            await emit("agent_started", task_id=task_id, agent="spector")
            reply: list[str] = []
            try:
                text_out = await asyncio.wait_for(
                    self._run_turn(sess, text, reply),
                    timeout=SPECTOR_TIMEOUT_SECS,
                )
            except asyncio.TimeoutError:
                log.warning("spector[%s] timed out after %ss", task_id, SPECTOR_TIMEOUT_SECS)
                await emit(
                    "agent_error",
                    task_id=task_id,
                    agent="spector",
                    reason="timeout",
                    timeout_secs=SPECTOR_TIMEOUT_SECS,
                )
                await self._drop(task_id)
                raise
            except Exception as e:
                log.exception("spector[%s] failed", task_id)
                await emit(
                    "agent_error",
                    task_id=task_id,
                    agent="spector",
                    reason=str(e) or e.__class__.__name__,
                )
                await self._drop(task_id)
                raise
            if any(line.strip() == "SPEC_CONFIRMED" for line in text_out.splitlines()):
                sess.confirmed = True
            await emit(
                "agent_finished",
                task_id=task_id,
                agent="spector",
                confirmed=sess.confirmed,
            )
            log.info("spector[%s] send done (%d chars reply)", task_id, len(text_out))
            return text_out

    async def _run_turn(
        self,
        sess: SpectorSession,
        text: str,
        reply: list[str],
    ) -> str:
        await sess.client.query(text)
        async for msg in sess.client.receive_response():
            if isinstance(msg, AssistantMessage):
                for block in msg.content:
                    if isinstance(block, TextBlock):
                        reply.append(block.text)
                        await emit(
                            "agent_text",
                            task_id=sess.task_id,
                            agent="spector",
                            text=block.text,
                        )
                    elif isinstance(block, ToolUseBlock):
                        await emit(
                            "agent_tool_call",
                            task_id=sess.task_id,
                            agent="spector",
                            tool=block.name,
                            input=block.input,
                        )
            elif isinstance(msg, ResultMessage):
                break
        return "".join(reply)

    async def close(self, task_id: str) -> None:
        await self._drop(task_id)


registry = SpectorRegistry()
