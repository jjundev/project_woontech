from dataclasses import replace
from typing import TYPE_CHECKING

from .base import AgentSpec, run_agent, AgentResult
from .planner import PLANNER
from .plan_reviewer import PLAN_REVIEWER
from .implementor import IMPLEMENTOR
from .implement_reviewer import IMPLEMENT_REVIEWER
from .publisher import PUBLISHER

if TYPE_CHECKING:
    from ..config import HarnessConfig


def resolve_agent(spec: AgentSpec, config: "HarnessConfig") -> AgentSpec:
    """Apply per-agent model override from config, if present."""
    override = config.agent_models.get(spec.name)
    if override is None:
        return spec
    return replace(spec, model=override)


__all__ = [
    "AgentSpec",
    "AgentResult",
    "run_agent",
    "resolve_agent",
    "PLANNER",
    "PLAN_REVIEWER",
    "IMPLEMENTOR",
    "IMPLEMENT_REVIEWER",
    "PUBLISHER",
]
