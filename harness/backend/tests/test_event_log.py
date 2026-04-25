from __future__ import annotations

from backend.event_log import _belongs_to_impl_phase


def _evt(*, type: str = "agent_tool_call", agent: str | None = None, payload: dict | None = None) -> dict:
    return {
        "type": type,
        "task_id": "T",
        "run_id": "R",
        "agent": agent,
        "iteration": None,
        "payload": payload or {},
    }


def test_implementor_events_are_logged():
    assert _belongs_to_impl_phase(_evt(agent="implementor"))


def test_implement_reviewer_events_are_logged():
    # Regression: the agent's actual name uses a hyphen ("implement-reviewer").
    # An earlier `IMPL_AGENT_NAMES` entry used an underscore and silently dropped
    # every reviewer event from impl-phase.jsonl, making `diagnostic_infra_missing`
    # escalations un-debuggable.
    assert _belongs_to_impl_phase(_evt(agent="implement-reviewer"))


def test_unrelated_agent_events_are_dropped():
    assert not _belongs_to_impl_phase(_evt(agent="planner"))


def test_phase_tagged_payload_is_logged():
    assert _belongs_to_impl_phase(_evt(payload={"phase": "impl_review"}))


def test_state_tagged_payload_is_logged():
    assert _belongs_to_impl_phase(_evt(type="state_changed", payload={"state": "implementing"}))


def test_always_log_types_pass_through():
    for t in ("pipeline_started", "pipeline_resuming", "pipeline_done", "escalation"):
        assert _belongs_to_impl_phase(_evt(type=t))
