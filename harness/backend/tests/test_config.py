from __future__ import annotations

from pathlib import Path
from textwrap import dedent

import pytest
import yaml

from backend import agents as A
from backend.agents import PUBLISHER, PLANNER
from backend.config import HarnessConfig, load_config


def _write_config(tmp_path: Path, extra: str) -> Path:
    ios_root = tmp_path / "ios"
    ios_root.mkdir()
    base = dedent(
        f"""\
        ios_root: {ios_root}
        worktrees_dir: {ios_root}/worktrees
        build_cmd: "echo build"
        unit_test_cmd: "echo unit"
        ui_test_cmd: "echo ui"
        """
    )
    path = tmp_path / "harness.config.yaml"
    path.write_text(base + extra)
    return path


def test_load_config_parses_agent_models(tmp_path: Path):
    path = _write_config(
        tmp_path,
        dedent(
            """\
            agents:
              publisher: { model: claude-haiku-4-5-20251001 }
              planner:   { model: null }
            """
        ),
    )

    config = load_config(path)

    assert config.agent_models["publisher"] == "claude-haiku-4-5-20251001"
    assert config.agent_models["planner"] is None


def test_load_config_missing_agents_block_yields_empty_dict(tmp_path: Path):
    path = _write_config(tmp_path, "")

    config = load_config(path)

    assert config.agent_models == {}


def test_load_config_rejects_non_mapping_agent_entry(tmp_path: Path):
    path = _write_config(
        tmp_path,
        dedent(
            """\
            agents:
              publisher: "claude-haiku-4-5-20251001"
            """
        ),
    )

    with pytest.raises(ValueError, match="agents.publisher"):
        load_config(path)


def test_resolve_agent_applies_override():
    config = HarnessConfig(
        ios_root=Path("."),
        worktrees_dir=Path("."),
        build_cmd="",
        unit_test_cmd="",
        ui_test_cmd="",
        agent_models={"publisher": "claude-haiku-4-5-20251001"},
    )

    resolved = A.resolve_agent(PUBLISHER, config)

    assert resolved.model == "claude-haiku-4-5-20251001"
    # Unrelated fields preserved
    assert resolved.name == PUBLISHER.name
    assert resolved.system_prompt == PUBLISHER.system_prompt
    assert resolved.allowed_tools == PUBLISHER.allowed_tools
    # Original spec untouched (immutability via dataclasses.replace)
    assert PUBLISHER.model is None


def test_resolve_agent_leaves_spec_unchanged_when_override_missing():
    config = HarnessConfig(
        ios_root=Path("."),
        worktrees_dir=Path("."),
        build_cmd="",
        unit_test_cmd="",
        ui_test_cmd="",
        agent_models={},
    )

    resolved = A.resolve_agent(PLANNER, config)

    assert resolved is PLANNER


def test_resolve_agent_treats_null_override_as_default():
    config = HarnessConfig(
        ios_root=Path("."),
        worktrees_dir=Path("."),
        build_cmd="",
        unit_test_cmd="",
        ui_test_cmd="",
        agent_models={"planner": None},
    )

    resolved = A.resolve_agent(PLANNER, config)

    assert resolved is PLANNER


def test_packaged_config_yaml_has_expected_overrides():
    """The shipped harness.config.yaml should downgrade publisher only."""
    root = Path(__file__).resolve().parents[2] / "harness.config.yaml"
    data = yaml.safe_load(root.read_text())

    agents = data.get("agents") or {}
    assert agents.get("publisher", {}).get("model") == "claude-haiku-4-5-20251001"
    # spector is removed from the harness; no override should be declared for it.
    assert "spector" not in agents
    # Core reasoning roles must stay on the default (Opus).
    for role in ("planner", "plan-reviewer", "implementor", "implement-reviewer"):
        assert agents.get(role, {}).get("model") is None, role


def test_packaged_config_yaml_uses_only_testing_tokens():
    """Test commands must be templates so pipeline.py can inject -only-testing:."""
    root = Path(__file__).resolve().parents[2] / "harness.config.yaml"
    data = yaml.safe_load(root.read_text())

    assert "{only_testing:WoontechTests}" in data["unit_test_cmd"]
    assert "{only_testing:WoontechUITests}" in data["ui_test_cmd"]


def test_load_config_parses_always_ui_test_classes(tmp_path: Path):
    path = _write_config(
        tmp_path,
        dedent(
            """\
            always_ui_test_classes:
              - AppLaunchContractUITests
              - AnotherSmokeUITests
            """
        ),
    )

    config = load_config(path)

    assert config.always_ui_test_classes == [
        "AppLaunchContractUITests",
        "AnotherSmokeUITests",
    ]


def test_load_config_missing_always_ui_yields_empty_list(tmp_path: Path):
    path = _write_config(tmp_path, "")

    config = load_config(path)

    assert config.always_ui_test_classes == []


def test_load_config_rejects_non_string_always_ui_entries(tmp_path: Path):
    path = _write_config(
        tmp_path,
        dedent(
            """\
            always_ui_test_classes:
              - 42
            """
        ),
    )

    with pytest.raises(ValueError, match="always_ui_test_classes"):
        load_config(path)


def test_packaged_config_yaml_includes_launch_contract_smoke():
    """The shipped config must keep AppLaunchContractUITests in the always-run set."""
    root = Path(__file__).resolve().parents[2] / "harness.config.yaml"
    data = yaml.safe_load(root.read_text())

    assert "AppLaunchContractUITests" in (data.get("always_ui_test_classes") or [])


def test_packaged_config_yaml_uses_xcode_test_runner_wrapper():
    """Build/test commands should use the local wrapper, not raw xcodebuild."""
    root = Path(__file__).resolve().parents[2] / "harness.config.yaml"
    data = yaml.safe_load(root.read_text())

    assert data["build_cmd"] == "python3 tools/xcode_test_runner.py build"
    assert data["unit_test_cmd"] == (
        "python3 tools/xcode_test_runner.py test --target WoontechTests "
        "{only_testing:WoontechTests}"
    )
    assert data["ui_test_cmd"] == (
        "python3 tools/xcode_test_runner.py test --target WoontechUITests --ui "
        "{only_testing:WoontechUITests}"
    )
