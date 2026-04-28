from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Awaitable, Callable, Optional

from claude_agent_sdk import (
    AssistantMessage,
    ClaudeAgentOptions,
    ClaudeSDKClient,
    HookMatcher,
    ResultMessage,
    TextBlock,
    ToolResultBlock,
    ToolUseBlock,
    UserMessage,
)

from ..events import emit


# Lines like `STEP: 3` or `STEP: 3. Wire the share sheet` emitted by the
# implementor mark the start of a plan step. The harness consumes them to
# advance the PlanStepsPanel; they remain visible in the agent_text stream.
STEP_MARKER_RE = re.compile(r"^STEP:\s*(.+?)\s*$", re.MULTILINE)


_TOOL_RESULT_TAIL_LINES = 40


def _tool_result_tail(
    content: "str | list[dict[str, Any]] | None",
) -> list[str]:
    """Extract the last N lines of a ToolResultBlock for display in chat.

    The SDK delivers tool result content as either a plain string or a list of
    Anthropic content blocks ({"type": "text", "text": ...} | image blocks).
    We concatenate text-typed blocks, ignore non-text, and return the trailing
    lines so chat can show a useful tail without dumping multi-MB xcodebuild
    output.
    """
    if content is None:
        return []
    if isinstance(content, str):
        text = content
    else:
        chunks: list[str] = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                chunks.append(str(item.get("text", "")))
        text = "\n".join(chunks)
    if not text:
        return []
    lines = text.splitlines()
    return lines[-_TOOL_RESULT_TAIL_LINES:]


def _join_text_blocks(blocks: list[str]) -> str:
    # Newline-join, not concat: the SDK can split a single model response into
    # multiple TextBlocks. If we glue them with "" the boundary fuses adjacent
    # words ("...completesIMPLEMENT_REWORK_REQUIRED"), breaking line-based
    # token detection downstream.
    return "\n".join(blocks)


def step_markers_for_agent(agent_name: str, text: str) -> list[str]:
    if agent_name != "implementor":
        return []
    return [match.group(1) for match in STEP_MARKER_RE.finditer(text)]


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
    usage: Optional[dict[str, Any]] = None
    total_cost_usd: Optional[float] = None
    duration_ms: Optional[int] = None
    model_usage: Optional[dict[str, Any]] = None


async def run_agent(
    spec: AgentSpec,
    prompt: str,
    *,
    cwd: Path,
    task_id: Optional[str] = None,
    iteration: Optional[int] = None,
    hooks: Optional[dict[str, list[HookMatcher]]] = None,
    on_user_message: Optional[Callable[[str], Awaitable[Optional[str]]]] = None,
    inline_ui_cmd: Optional[str] = None,
) -> AgentResult:
    """
    Run an agent to completion on a single prompt.

    `hooks` is forwarded to ClaudeAgentOptions for PreToolUse/PostToolUse control —
    used by the implementor/reviewer to block Write/Edit outside the worktree.

    `inline_ui_cmd` opts in to splitting the agent's own Bash run of the UI test
    command into its own UI test card in chat. When the agent invokes Bash with
    a command equal to `inline_ui_cmd`, the corresponding `agent_tool_call` is
    tagged `inline_ui_test=true`, and the matching `ToolResultBlock` is surfaced
    as an `agent_tool_result` event so the frontend can render a standalone
    UiTestRun row instead of burying it inside the agent's chat bubble.
    """
    options = ClaudeAgentOptions(
        system_prompt=spec.system_prompt,
        allowed_tools=spec.allowed_tools,
        cwd=str(cwd),
        permission_mode=spec.permission_mode,
        max_turns=spec.max_turns,
        **({"model": spec.model} if spec.model else {}),
        **({"hooks": hooks} if hooks else {}),
    )

    text_buf: list[str] = []
    tool_uses: list[dict[str, Any]] = []
    stop_reason: Optional[str] = None
    usage: Optional[dict[str, Any]] = None
    total_cost_usd: Optional[float] = None
    duration_ms: Optional[int] = None
    model_usage: Optional[dict[str, Any]] = None
    inline_ui_tool_use_ids: set[str] = set()
    inline_ui_cmd_normalized = (inline_ui_cmd or "").strip() or None

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
                        for marker in step_markers_for_agent(spec.name, block.text):
                            await emit(
                                "plan_step_progress",
                                task_id=task_id,
                                agent=spec.name,
                                iteration=iteration,
                                marker=marker,
                            )
                    elif isinstance(block, ToolUseBlock):
                        entry = {
                            "name": block.name,
                            "input": block.input,
                        }
                        tool_uses.append(entry)
                        is_inline_ui_test = (
                            inline_ui_cmd_normalized is not None
                            and block.name == "Bash"
                            and inline_ui_cmd_normalized
                            in str(block.input.get("command", "")).strip()
                        )
                        if is_inline_ui_test:
                            inline_ui_tool_use_ids.add(block.id)
                        emit_kwargs: dict[str, Any] = dict(
                            task_id=task_id,
                            agent=spec.name,
                            iteration=iteration,
                            tool=block.name,
                            input=block.input,
                            tool_use_id=block.id,
                        )
                        if is_inline_ui_test:
                            emit_kwargs["inline_ui_test"] = True
                        await emit("agent_tool_call", **emit_kwargs)
            elif isinstance(msg, UserMessage):
                # Surface ToolResultBlocks for inline UI test runs only — those
                # are the calls whose `agent_tool_call` was already tagged for
                # the frontend to render as a standalone UiTestRun card. We
                # don't emit results for other tools to avoid flooding the
                # event stream.
                content = msg.content
                if isinstance(content, list):
                    for block in content:
                        if not isinstance(block, ToolResultBlock):
                            continue
                        if block.tool_use_id not in inline_ui_tool_use_ids:
                            continue
                        await emit(
                            "agent_tool_result",
                            task_id=task_id,
                            agent=spec.name,
                            iteration=iteration,
                            tool_use_id=block.tool_use_id,
                            inline_ui_test=True,
                            is_error=bool(block.is_error),
                            output_tail=_tool_result_tail(block.content),
                        )
            elif isinstance(msg, ResultMessage):
                stop_reason = getattr(msg, "stop_reason", None) or getattr(msg, "subtype", None)
                usage = getattr(msg, "usage", None)
                total_cost_usd = getattr(msg, "total_cost_usd", None)
                duration_ms = getattr(msg, "duration_ms", None)
                model_usage = getattr(msg, "model_usage", None)
    await emit(
        "agent_finished",
        task_id=task_id,
        agent=spec.name,
        iteration=iteration,
        stop_reason=stop_reason,
    )
    if usage is not None or total_cost_usd is not None:
        await emit(
            "agent_usage",
            task_id=task_id,
            agent=spec.name,
            iteration=iteration,
            model=spec.model,
            input_tokens=int((usage or {}).get("input_tokens", 0) or 0),
            output_tokens=int((usage or {}).get("output_tokens", 0) or 0),
            cache_creation_input_tokens=int(
                (usage or {}).get("cache_creation_input_tokens", 0) or 0
            ),
            cache_read_input_tokens=int(
                (usage or {}).get("cache_read_input_tokens", 0) or 0
            ),
            total_cost_usd=total_cost_usd,
            duration_ms=duration_ms,
            model_usage=model_usage,
        )
    return AgentResult(
        text=_join_text_blocks(text_buf),
        tool_uses=tool_uses,
        stop_reason=stop_reason,
        usage=usage,
        total_cost_usd=total_cost_usd,
        duration_ms=duration_ms,
        model_usage=model_usage,
    )
