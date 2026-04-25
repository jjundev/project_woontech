from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

import pytest


RUNNER_PATH = Path(__file__).resolve().parents[3] / "ios" / "tools" / "xcode_test_runner.py"
SPEC = importlib.util.spec_from_file_location("xcode_test_runner", RUNNER_PATH)
assert SPEC is not None and SPEC.loader is not None
runner = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = runner
SPEC.loader.exec_module(runner)


def _device(name: str, udid: str, device_type: str = runner.DEFAULT_DEVICE_TYPE_ID) -> dict[str, object]:
    return {
        "name": name,
        "udid": udid,
        "isAvailable": True,
        "deviceTypeIdentifier": device_type,
        "state": "Shutdown",
    }


def test_choose_device_prefers_latest_exact_iphone_17_pro():
    devices_json = {
        "devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-26-3": [
                _device("iPhone 17 Pro", "old-exact"),
            ],
            "com.apple.CoreSimulator.SimRuntime.iOS-26-4": [
                _device("iPhone 17 Pro Max", "new-family"),
                _device("iPhone 17 Pro", "new-exact"),
            ],
        }
    }

    selected = runner.choose_device(devices_json)

    assert selected.udid == "new-exact"


def test_choose_device_uses_udid_override():
    devices_json = {
        "devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-26-4": [
                _device("iPhone 17 Pro", "default"),
                _device("iPhone 17", "override"),
            ],
        }
    }

    selected = runner.choose_device(devices_json, override_udid="override")

    assert selected.name == "iPhone 17"


def test_choose_device_rejects_missing_udid_override():
    devices_json = {
        "devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-26-4": [
                _device("iPhone 17 Pro", "default"),
            ],
        }
    }

    with pytest.raises(runner.RunnerError, match=runner.ENV_SIMULATOR_UDID):
        runner.choose_device(devices_json, override_udid="missing")


def test_choose_runtime_for_device_type_picks_latest_supported_ios_runtime():
    runtimes_json = {
        "runtimes": [
            {
                "platform": "iOS",
                "isAvailable": True,
                "version": "26.3.1",
                "buildversion": "23D8133",
                "identifier": "old-runtime",
                "supportedDeviceTypes": [{"identifier": runner.DEFAULT_DEVICE_TYPE_ID}],
            },
            {
                "platform": "iOS",
                "isAvailable": True,
                "version": "26.4",
                "buildversion": "23E254a",
                "identifier": "new-runtime",
                "supportedDeviceTypes": [{"identifier": runner.DEFAULT_DEVICE_TYPE_ID}],
            },
            {
                "platform": "tvOS",
                "isAvailable": True,
                "version": "99.0",
                "buildversion": "99Z999",
                "identifier": "wrong-platform",
                "supportedDeviceTypes": [{"identifier": runner.DEFAULT_DEVICE_TYPE_ID}],
            },
        ]
    }

    assert runner.choose_runtime_for_device_type(runtimes_json) == "new-runtime"


@pytest.mark.parametrize(
    "output",
    [
        "DebuggerLLDB.DebuggerVersionStore.StoreError error 0",
        "IDELaunchParametersSnapshot: no debugger version",
        "IDELaunchParametersSnapshot: The operation could not be completed",
        "Failed to install or launch the test runner. Mach error -308 - (ipc/mig) server died",
    ],
)
def test_environment_launch_failure_signatures(output: str):
    assert runner.is_environment_launch_failure(output)


def test_environment_launch_failure_does_not_match_regular_assertion_failure():
    output = "XCTAssertEqual failed: expected Home, got Dashboard"

    assert not runner.is_environment_launch_failure(output)


def test_persist_test_artifacts_writes_no_bundle_marker_when_bundle_missing(tmp_path):
    bundle = tmp_path / "missing.xcresult"
    worktree = tmp_path / "worktree"
    worktree.mkdir()

    runner._persist_test_artifacts("ui", bundle, worktree)

    out_dir = worktree / runner.TEST_ARTIFACTS_SUBDIR
    summary = (out_dir / "last-ui-summary.txt").read_text()
    failures = (out_dir / "last-ui-failures.txt").read_text()
    assert summary.startswith("[no xcresult bundle found]")
    assert failures.startswith("[no xcresult bundle found]")
    assert not (out_dir / "last-ui.xcresult").exists()


def test_persist_test_artifacts_uses_exact_bundle_and_writes_filtered_failures(tmp_path, monkeypatch):
    derived = tmp_path / "derived"
    stale = derived / "Logs" / "Test" / "Test-Woontech-stale.xcresult"
    stale.mkdir(parents=True)
    (stale / "Info.plist").write_text("stale")
    current = derived / "ResultBundles" / "current.xcresult"
    current.mkdir(parents=True)
    (current / "Info.plist").write_text("current")

    captured: list[tuple[str, ...]] = []

    def fake_capture(bundle, *args):
        captured.append((str(bundle),) + args)
        if args[-1:] == ("--compact",):
            return json.dumps(
                {
                    "testNodes": [
                        {
                            "nodeType": "Test Case",
                            "name": "PassingTests/test_passes()",
                            "result": "Passed",
                        },
                        {
                            "nodeType": "Test Case",
                            "name": "FailingTests/test_fails()",
                            "result": "Failed",
                            "children": [
                                {
                                    "nodeType": "Failure Message",
                                    "name": "XCTAssertEqual failed",
                                    "details": "expected Home, got Dashboard",
                                }
                            ],
                        },
                    ]
                }
            )
        return "<summary output>"

    monkeypatch.setattr(runner, "_capture_xcresulttool", fake_capture)

    worktree = tmp_path / "worktree"
    worktree.mkdir()

    runner._persist_test_artifacts("unit", current, worktree)

    out_dir = worktree / runner.TEST_ARTIFACTS_SUBDIR
    summary = (out_dir / "last-unit-summary.txt").read_text()
    failures = (out_dir / "last-unit-failures.txt").read_text()
    bundle_copy = out_dir / "last-unit.xcresult"

    assert "<summary output>" in summary
    assert "FailingTests/test_fails()" in failures
    assert "XCTAssertEqual failed" in failures
    assert "expected Home, got Dashboard" in failures
    assert "PassingTests/test_passes()" not in failures
    assert str(current) in summary
    assert bundle_copy.is_dir()
    assert (bundle_copy / "Info.plist").read_text() == "current"
    assert all(str(current) == row[0] for row in captured)


def test_persist_test_artifacts_overwrites_previous_mirror(tmp_path, monkeypatch):
    bundle = tmp_path / "Test-Woontech-A.xcresult"
    bundle.mkdir(parents=True)
    (bundle / "stamp").write_text("v1")

    def fake_capture(bundle, *args):
        if args[-1:] == ("--compact",):
            return json.dumps({"testNodes": []})
        return "ok"

    monkeypatch.setattr(runner, "_capture_xcresulttool", fake_capture)

    worktree = tmp_path / "worktree"
    worktree.mkdir()

    runner._persist_test_artifacts("ui", bundle, worktree)
    # Replace the source bundle with new content and re-run.
    (bundle / "stamp").write_text("v2")
    runner._persist_test_artifacts("ui", bundle, worktree)

    mirror = worktree / runner.TEST_ARTIFACTS_SUBDIR / "last-ui.xcresult"
    assert (mirror / "stamp").read_text() == "v2"


def test_persist_test_artifacts_records_failure_parser_error(tmp_path, monkeypatch):
    bundle = tmp_path / "current.xcresult"
    bundle.mkdir()
    worktree = tmp_path / "worktree"
    worktree.mkdir()

    def fake_capture(bundle, *args):
        if args[-1:] == ("--compact",):
            return "{not json"
        return "summary"

    monkeypatch.setattr(runner, "_capture_xcresulttool", fake_capture)

    runner._persist_test_artifacts("ui", bundle, worktree)

    failures = (
        worktree / runner.TEST_ARTIFACTS_SUBDIR / "last-ui-failures.txt"
    ).read_text()
    assert "[failed to parse xcresult tests JSON]" in failures
    assert "{not json" in failures


def test_run_test_adds_result_bundle_path_and_persists_exact_bundle(monkeypatch, tmp_path):
    captured: dict[str, object] = {}

    monkeypatch.setattr(
        runner,
        "resolve_simulator",
        lambda *, ui: runner.SimulatorDevice("iPhone", "SIM", "runtime", "type", "Booted"),
    )
    monkeypatch.setattr(runner, "reset_simulator", lambda udid: None)

    def fake_run(args, *, simulator_udid, derived_data_path, result_bundle_path=None):
        captured["args"] = list(args)
        captured["simulator_udid"] = simulator_udid
        captured["derived_data_path"] = derived_data_path
        captured["result_bundle_path"] = result_bundle_path
        return 0

    def fake_persist(kind, bundle, target_dir, *, exit_code=0, simulator_udid=None):
        captured["persist"] = (kind, bundle, target_dir, exit_code, simulator_udid)

    monkeypatch.setattr(runner, "run_with_optional_repair", fake_run)
    monkeypatch.setattr(runner, "_persist_test_artifacts", fake_persist)

    code = runner.run_test(
        "WoontechTests",
        ui=False,
        xcodebuild_args=["-only-testing:WoontechTests/FooTests"],
        worktree_dir_override=str(tmp_path),
    )

    args = captured["args"]
    result_bundle_path = captured["result_bundle_path"]
    assert code == 0
    assert "-resultBundlePath" in args
    assert args[args.index("-resultBundlePath") + 1] == str(result_bundle_path)
    # Unit runs do not pass a simulator_udid (UI-failure-only diagnostics).
    assert captured["persist"] == ("unit", result_bundle_path, tmp_path, 0, None)


def test_run_test_passes_simulator_udid_for_ui_runs(monkeypatch, tmp_path):
    captured: dict[str, object] = {}

    monkeypatch.setattr(
        runner,
        "resolve_simulator",
        lambda *, ui: runner.SimulatorDevice("iPhone", "UI-SIM", "runtime", "type", "Booted"),
    )
    monkeypatch.setattr(runner, "reset_simulator", lambda udid: None)

    def fake_run(args, *, simulator_udid, derived_data_path, result_bundle_path=None):
        return 7  # non-zero so persist will see a failing UI run

    def fake_persist(kind, bundle, target_dir, *, exit_code=0, simulator_udid=None):
        captured["persist"] = (kind, exit_code, simulator_udid)

    monkeypatch.setattr(runner, "run_with_optional_repair", fake_run)
    monkeypatch.setattr(runner, "_persist_test_artifacts", fake_persist)

    code = runner.run_test(
        "WoontechUITests",
        ui=True,
        xcodebuild_args=["-only-testing:WoontechUITests/AppLaunchContractUITests"],
        worktree_dir_override=str(tmp_path),
    )

    assert code == 7
    assert captured["persist"] == ("ui", 7, "UI-SIM")


def test_persist_test_artifacts_captures_ui_failure_environment_on_failure(
    tmp_path, monkeypatch
):
    bundle = tmp_path / "current.xcresult"
    bundle.mkdir()
    worktree = tmp_path / "worktree"
    worktree.mkdir()

    def fake_capture(bundle, *args):
        if args[-1:] == ("--compact",):
            return json.dumps({"testNodes": []})
        return "summary"

    monkeypatch.setattr(runner, "_capture_xcresulttool", fake_capture)

    calls: list[list[str]] = []

    class FakeCompleted:
        def __init__(self, returncode=0, stdout="", stderr=""):
            self.returncode = returncode
            self.stdout = stdout
            self.stderr = stderr

    def fake_subprocess_run(cmd, *, capture_output=True, text=True, timeout=None):
        calls.append(list(cmd))
        if cmd[:3] == ["xcrun", "simctl", "io"]:
            screenshot_path = Path(cmd[-1])
            screenshot_path.write_bytes(b"PNG-FAKE")
            return FakeCompleted(returncode=0)
        if cmd[:3] == ["xcrun", "simctl", "listapps"]:
            return FakeCompleted(returncode=0, stdout="apps={com.woontech.app}")
        return FakeCompleted(returncode=1, stderr="unexpected cmd")

    monkeypatch.setattr(runner.subprocess, "run", fake_subprocess_run)

    runner._persist_test_artifacts(
        "ui", bundle, worktree, exit_code=1, simulator_udid="SIM-UDID"
    )

    out_dir = worktree / runner.TEST_ARTIFACTS_SUBDIR
    assert (out_dir / "last-ui-screenshot.png").read_bytes() == b"PNG-FAKE"
    env_text = (out_dir / "last-ui-environment.txt").read_text()
    assert "simulator_udid: SIM-UDID" in env_text
    assert "apps={com.woontech.app}" in env_text
    assert any(c[:3] == ["xcrun", "simctl", "io"] for c in calls)
    assert any(c[:3] == ["xcrun", "simctl", "listapps"] for c in calls)


def test_persist_test_artifacts_skips_ui_environment_on_success(tmp_path, monkeypatch):
    bundle = tmp_path / "current.xcresult"
    bundle.mkdir()
    worktree = tmp_path / "worktree"
    worktree.mkdir()

    def fake_capture(bundle, *args):
        if args[-1:] == ("--compact",):
            return json.dumps({"testNodes": []})
        return "summary"

    monkeypatch.setattr(runner, "_capture_xcresulttool", fake_capture)

    def fake_subprocess_run(cmd, *, capture_output=True, text=True, timeout=None):
        raise AssertionError(f"simctl should not be invoked on success: {cmd}")

    monkeypatch.setattr(runner.subprocess, "run", fake_subprocess_run)

    runner._persist_test_artifacts(
        "ui", bundle, worktree, exit_code=0, simulator_udid="SIM-UDID"
    )

    out_dir = worktree / runner.TEST_ARTIFACTS_SUBDIR
    assert not (out_dir / "last-ui-screenshot.png").exists()
    assert not (out_dir / "last-ui-environment.txt").exists()


def test_parse_args_extracts_worktree_dir_from_test_command():
    args = runner.parse_args(
        [
            "test",
            "--target",
            "WoontechTests",
            "--worktree-dir",
            ".",
            "-only-testing:WoontechTests/FooTests",
        ]
    )

    assert args.worktree_dir == "."
    assert args.xcodebuild_args == ["-only-testing:WoontechTests/FooTests"]


def test_worktree_dir_honors_cli_then_env_overrides(monkeypatch, tmp_path):
    monkeypatch.setenv(runner.ENV_WORKTREE_DIR, str(tmp_path / "env"))
    monkeypatch.setenv(runner.ENV_CLAUDE_PROJECT_DIR, str(tmp_path / "claude"))
    assert runner.worktree_dir(".") == Path(".")
    assert runner.worktree_dir() == tmp_path / "env"


def test_worktree_dir_honors_claude_project_dir(monkeypatch, tmp_path):
    monkeypatch.delenv(runner.ENV_WORKTREE_DIR, raising=False)
    monkeypatch.setenv(runner.ENV_CLAUDE_PROJECT_DIR, str(tmp_path))
    assert runner.worktree_dir() == tmp_path


def test_worktree_dir_honors_env_override(monkeypatch, tmp_path):
    monkeypatch.setenv(runner.ENV_WORKTREE_DIR, str(tmp_path))
    assert runner.worktree_dir() == tmp_path


def test_worktree_dir_defaults_to_ios_root(monkeypatch):
    monkeypatch.delenv(runner.ENV_WORKTREE_DIR, raising=False)
    monkeypatch.delenv(runner.ENV_CLAUDE_PROJECT_DIR, raising=False)
    assert runner.worktree_dir() == runner.ios_root()
