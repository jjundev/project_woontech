from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Awaitable, Callable, Optional

from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    ClaudeSDKClient,
    ResultMessage,
    TextBlock,
    ToolUseBlock,
    UserMessage,
)

from ..events import emit


@dataclass
class AgentSpec:
    """Declarative description of an agent role."""

    name: str
    system_prompt: str
    allowed_tools: list[str] = field(default_factory=list)
    model: Optional[str] = None  # e.g. "claude-opus-4-7", None = SDK default
    permission_mode: str = "acceptEdits"
    max_turns: Optional[int] = 40


@dataclass
class AgentResult:
    text: str
    tool_uses: list[dict[str, Any]] = field(default_factory=list)
    stop_reason: Optional[str] = None


async def run_agent(
    spec: AgentSpec,
    prompt: str,
    *,
    cwd: Path,
    task_id: Optional[str] = None,
    iteration: Optional[int] = None,
    on_user_message: Optional[Callable[[str], Awaitable[Optional[str]]]] = None,
) -> AgentResult:
    """
    Run an agent to completion on a single prompt.

    `on_user_message` is invoked when the agent produces a user-facing text turn that
    expects a reply (used by spector for interactive chat). If None, the agent runs
    non-interactively and the function returns when the model completes its response.
    """
    options = ClaudeAgentOptions(
        system_prompt=spec.system_prompt,
        allowed_tools=spec.allowed_tools,
        cwd=str(cwd),
        permission_mode=spec.permission_mode,
        max_turns=spec.max_turns,
        **({"model": spec.model} if spec.model else {}),
    )

    text_buf: list[str] = []
    tool_uses: list[dict[str, Any]] = []
    stop_reason: Optional[str] = None

    await emit("agent_started", task_id=task_id, agent=spec.name, iteration=iteration)
    async with ClaudeSDKClient(options=options) as client:
        await client.query(prompt)
        async for msg in client.receive_response():
            if isinstance(msg, AssistantMessage):
                for block in msg.content:
                    if isinstance(block, TextBlock):
                        text_buf.append(block.text)
                        await emit(
                            "agent_text",
                            task_id=task_id,
                            agent=spec.name,
                            iteration=iteration,
                            text=block.text,
                        )
                    elif isinstance(block, ToolUseBlock):
                        entry = {
                            "name": block.name,
                            "input": block.input,
                        }
                        tool_uses.append(entry)
                        await emit(
                            "agent_tool_call",
                            task_id=task_id,
                            agent=spec.name,
                            iteration=iteration,
                            tool=block.name,
                            input=block.input,
                        )
            elif isinstance(msg, ResultMessage):
                stop_reason = getattr(msg, "stop_reason", None) or getattr(msg, "subtype", None)
    await emit(
        "agent_finished",
        task_id=task_id,
        agent=spec.name,
        iteration=iteration,
        stop_reason=stop_reason,
    )
    return AgentResult(text="".join(text_buf), tool_uses=tool_uses, stop_reason=stop_reason)
