from __future__ import annotations

from pathlib import Path

from backend import pipeline as P
from backend.agents.implementor import IMPLEMENTOR
from backend.agents.implement_reviewer import IMPLEMENT_REVIEWER
from backend.agents.plan_reviewer import PLAN_REVIEWER


def test_implement_reviewer_prompt_has_patch_guardrails():
    prompt = IMPLEMENT_REVIEWER.system_prompt

    assert "public API" in prompt
    assert "data model" in prompt
    assert "dependency" in prompt
    assert "## Patch applied" in prompt
    assert "## Remaining risk" in prompt
    assert "IMPLEMENT_REWORK_REQUIRED" in prompt
    assert "read ONLY" not in prompt
    assert "ignore older feedbacks" not in prompt
    # Ledger invariant: each feedback file must carry forward unresolved items
    # from prior iterations so the reviewer does not need to read older files.
    assert "## Still outstanding from prior iterations" in prompt
    assert "## Resolved since previous iteration" in prompt


def test_pbxproj_membership_prompts_use_grep_tool_not_bash():
    reviewer_prompt = IMPLEMENT_REVIEWER.system_prompt
    implementor_prompt = IMPLEMENTOR.system_prompt
    reviewer_compact = " ".join(reviewer_prompt.split())
    implementor_compact = " ".join(implementor_prompt.split())

    assert "grep -c" not in reviewer_prompt
    assert "use the Grep tool on" in reviewer_compact
    assert "do not use Bash for this check" in reviewer_compact
    assert "PBXFileReference" in reviewer_prompt
    assert "PBXBuildFile" in reviewer_prompt
    assert "<FileName>.swift in Sources" in reviewer_prompt

    assert "use the Grep and Read tools on `Woontech.xcodeproj/project.pbxproj`" in implementor_compact
    assert "PBXFileReference" in implementor_prompt
    assert "PBXBuildFile" in implementor_prompt
    assert "<FileName>.swift in Sources" in implementor_prompt
    assert "do not use Bash for this check" in implementor_compact


def test_plan_reviewer_prompt_prevents_scope_changes():
    prompt = PLAN_REVIEWER.system_prompt
    compact_prompt = " ".join(prompt.split())

    # Ledger invariant: the latest feedback file is the authoritative record.
    assert "most recent `plan-feedback-version-*.md`" in prompt
    assert "rolling ledger" in prompt
    assert "## Still outstanding from prior iterations" in prompt
    assert "## Resolved since previous iteration" in prompt
    assert "does not change the meaning of `spec.md`" in compact_prompt
    assert "alter acceptance criteria" in compact_prompt
    assert "expand scope" in compact_prompt


def test_feedback_helpers_return_all_feedback_in_version_order(tmp_path: Path):
    for name in (
        "implement-feedback-version-10.md",
        "implement-feedback-version-1.md",
        "implement-feedback-version-2.md",
        "plan-feedback-version-3.md",
        "plan-feedback-version-1.md",
    ):
        (tmp_path / name).write_text("# feedback\n")

    assert [path.name for path in P._all_impl_feedback(tmp_path)] == [
        "implement-feedback-version-1.md",
        "implement-feedback-version-2.md",
        "implement-feedback-version-10.md",
    ]
    assert [path.name for path in P._all_plan_feedback(tmp_path)] == [
        "plan-feedback-version-1.md",
        "plan-feedback-version-3.md",
    ]


def test_pipeline_prompts_pass_only_latest_feedback_as_ledger():
    source = Path(P.__file__).read_text()

    # Prompts now pass the single latest feedback file. The "carries forward
    # unresolved items" phrasing signals to the reviewer that it's a ledger.
    assert "Latest implement-feedback file" in source
    assert "Latest plan-feedback file" in source
    assert "carries forward unresolved items" in source
    # Guardrail against accidental regression to "trust only the latest"
    # without the ledger contract.
    assert "use ONLY this one" not in source
    assert "ignore older feedbacks" not in source


def test_latest_feedback_returns_only_last_version(tmp_path: Path):
    for name in (
        "implement-feedback-version-1.md",
        "implement-feedback-version-2.md",
        "implement-feedback-version-10.md",
    ):
        (tmp_path / name).write_text("# feedback\n")

    latest = P._latest_feedback(P._all_impl_feedback(tmp_path))

    assert [p.name for p in latest] == ["implement-feedback-version-10.md"]
    assert P._latest_feedback([]) == []


def test_feedback_path_formatter_lists_every_file(tmp_path: Path):
    paths = [tmp_path / "implement-feedback-version-1.md", tmp_path / "implement-feedback-version-2.md"]

    formatted = P._format_feedback_paths(paths)

    assert str(paths[0]) in formatted
    assert str(paths[1]) in formatted
    assert formatted.startswith("- ")
    assert P._format_feedback_paths([]) == "NONE"


import pytest


@pytest.mark.parametrize(
    "text",
    [
        "PLAN_PASS",
        "  PLAN_PASS  ",
        "**PLAN_PASS**",
        "`PLAN_PASS`",
        "- PLAN_PASS",
        "> PLAN_PASS",
        '"PLAN_PASS"',
        "PLAN_PASS.",
        "## PLAN_PASS",
        "Review complete.\n\n**PLAN_PASS**\n",
        "Decision: PLAN_PASS",
        "Final verdict — PLAN_PASS.",
        "Response: PLAN_PASS",
        "최종 판정: PLAN_PASS",
    ],
)
def test_has_token_matches_common_markdown_wrappings(text: str):
    assert P._has_token(text, "PLAN_PASS")


@pytest.mark.parametrize(
    "text",
    [
        "",
        "PLAN_FAIL",                                # different token
        "PLAN PASS",                                # space instead of underscore
        "planning",                                 # substring of unrelated word
        "PLAN_PASSES",                              # superstring should not match
        "Result: PLAN_PASS achieved",               # token not last word
        "I may mention PLAN_PASS in passing only",  # prose continues after token
    ],
)
def test_has_token_rejects_non_matching_lines(text: str):
    assert not P._has_token(text, "PLAN_PASS")


def test_has_token_picks_up_token_anywhere_in_text():
    text = "Some analysis line.\nAnother line.\nPLAN_FAIL\nTrailing commentary."
    assert P._has_token(text, "PLAN_FAIL")
    assert not P._has_token(text, "PLAN_PASS")


def test_find_terminal_token_picks_last_occurrence():
    text = (
        "Initially I considered IMPLEMENT_PASS.\n"
        "But after reviewing the tests failed.\n"
        "Decision: IMPLEMENT_REWORK_REQUIRED\n"
    )
    candidates = ("IMPLEMENT_PASS", "IMPLEMENT_FAIL", "IMPLEMENT_REWORK_REQUIRED")
    assert P._find_terminal_token(text, candidates) == "IMPLEMENT_REWORK_REQUIRED"


def test_find_terminal_token_returns_none_when_no_candidate_matches():
    text = "I thought about it but never committed to a decision."
    assert P._find_terminal_token(text, ("IMPLEMENT_PASS", "IMPLEMENT_FAIL")) is None


def test_find_terminal_token_handles_markdown_wrappings():
    text = "Running tests…\n**IMPLEMENT_FAIL**\nPatch applied."
    assert (
        P._find_terminal_token(text, ("IMPLEMENT_PASS", "IMPLEMENT_FAIL"))
        == "IMPLEMENT_FAIL"
    )


def test_text_tail_truncates_to_limit():
    text = "x" * 1000
    assert P._text_tail(text, limit=50) == "x" * 50
    assert P._text_tail("short") == "short"
