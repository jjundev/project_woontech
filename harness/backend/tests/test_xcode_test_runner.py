from __future__ import annotations

import importlib.util
import json
import subprocess
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

    monkeypatch.setattr(runner, "preflight_check", lambda **kw: None)
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

    def fake_persist(kind, bundle, target_dir, *, exit_code=0, simulator_udid=None, preflight_failure=None):
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

    monkeypatch.setattr(runner, "preflight_check", lambda **kw: None)
    monkeypatch.setattr(
        runner,
        "resolve_simulator",
        lambda *, ui: runner.SimulatorDevice("iPhone", "UI-SIM", "runtime", "type", "Booted"),
    )
    monkeypatch.setattr(runner, "reset_simulator", lambda udid: None)
    monkeypatch.setattr(runner, "boot_simulator", lambda udid: None)

    def fake_run(args, *, simulator_udid, derived_data_path, result_bundle_path=None):
        return 7  # non-zero so persist will see a failing UI run

    def fake_persist(kind, bundle, target_dir, *, exit_code=0, simulator_udid=None, preflight_failure=None):
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


def test_run_test_persists_placeholder_when_resolve_simulator_raises(monkeypatch, tmp_path):
    """run_test() must always leave a last-{mode}-summary.txt behind.

    If `resolve_simulator` raises before xcodebuild starts (UI sim missing,
    simctl crash, etc.), the harness would otherwise see no summary file and
    escalate as `diagnostic_infra_missing`, masking the real failure. The
    finally-block placeholder keeps the diagnostic visible.
    """
    monkeypatch.setattr(runner, "DERIVED_DATA_ROOT", tmp_path / "derived")
    monkeypatch.setenv(runner.ENV_WORKTREE_DIR, str(tmp_path / "worktree"))
    monkeypatch.setattr(runner, "preflight_check", lambda **kw: None)

    def boom(*, ui):
        raise runner.RunnerError("no UI simulator available")

    monkeypatch.setattr(runner, "resolve_simulator", boom)

    with pytest.raises(runner.RunnerError):
        runner.run_test("WoontechUITests", ui=True, xcodebuild_args=[])

    out_dir = tmp_path / "worktree" / runner.TEST_ARTIFACTS_SUBDIR
    summary = out_dir / "last-ui-summary.txt"
    failures = out_dir / "last-ui-failures.txt"
    assert summary.exists(), "summary placeholder must be written even on early failure"
    assert failures.exists()
    assert "no xcresult bundle found" in summary.read_text()


# ---------------------------------------------------------------------------
# preflight_check tests
# ---------------------------------------------------------------------------


class _FakeCompleted:
    def __init__(self, returncode: int = 0, stdout: str = "", stderr: str = ""):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr


def _healthy_devices_json() -> str:
    return json.dumps(
        {
            "devices": {
                "com.apple.CoreSimulator.SimRuntime.iOS-26-4": [
                    {
                        "name": "iPhone 17 Pro",
                        "udid": "HEALTHY-UDID",
                        "isAvailable": True,
                        "deviceTypeIdentifier": runner.DEFAULT_DEVICE_TYPE_ID,
                        "state": "Shutdown",
                    }
                ]
            }
        }
    )


def _healthy_runtimes_json() -> str:
    return json.dumps(
        {
            "runtimes": [
                {
                    "platform": "iOS",
                    "isAvailable": True,
                    "version": "26.4",
                    "buildversion": "23E254a",
                    "identifier": "iOS-26-4",
                    "supportedDeviceTypes": [
                        {"identifier": runner.DEFAULT_DEVICE_TYPE_ID}
                    ],
                }
            ]
        }
    )


def _make_subprocess_router(handlers):
    """Build a subprocess.run replacement that dispatches by command prefix.

    `handlers` is a list of (predicate, response_or_exception) pairs. The first
    matching predicate wins. Tracks calls in `.calls` for assertions.
    """

    calls: list[list[str]] = []

    def fake_run(cmd, **_kwargs):
        calls.append(list(cmd))
        for predicate, response in handlers:
            if predicate(cmd):
                if isinstance(response, Exception):
                    raise response
                if callable(response):
                    return response(cmd)
                return response
        raise AssertionError(f"unexpected subprocess call: {cmd}")

    fake_run.calls = calls  # type: ignore[attr-defined]
    return fake_run


def test_preflight_passes_on_healthy_environment(monkeypatch, tmp_path):
    derived = tmp_path / "derived"
    monkeypatch.setattr(runner, "PREFLIGHT_LOCK_PATH", tmp_path / "preflight.lock")

    handlers = [
        (lambda c: c[:2] == ["xcode-select", "-p"], _FakeCompleted(0, "/Applications/Xcode.app/Contents/Developer\n")),
        (
            lambda c: c[:4] == ["xcrun", "simctl", "list", "devices"],
            _FakeCompleted(0, _healthy_devices_json()),
        ),
        (
            lambda c: c[:4] == ["xcrun", "simctl", "list", "runtimes"],
            _FakeCompleted(0, _healthy_runtimes_json()),
        ),
    ]
    fake_run = _make_subprocess_router(handlers)
    monkeypatch.setattr(runner.subprocess, "run", fake_run)

    monkeypatch.setattr(
        runner,
        "resolve_simulator",
        lambda *, ui: runner.SimulatorDevice("iPhone 17 Pro", "HEALTHY-UDID", "iOS-26-4", runner.DEFAULT_DEVICE_TYPE_ID, "Shutdown"),
    )

    repair_calls: list[dict] = []
    monkeypatch.setattr(
        runner,
        "repair_environment",
        lambda **kw: repair_calls.append(kw),
    )

    runner.preflight_check(ui=True, derived_data_path=derived)

    assert repair_calls == []
    assert derived.is_dir()


def test_preflight_fails_when_xcode_select_missing(monkeypatch, tmp_path):
    derived = tmp_path / "derived"
    monkeypatch.setattr(runner, "PREFLIGHT_LOCK_PATH", tmp_path / "preflight.lock")

    handlers = [
        (
            lambda c: c[:2] == ["xcode-select", "-p"],
            _FakeCompleted(1, "", "xcode-select: error: ..."),
        ),
    ]
    monkeypatch.setattr(runner.subprocess, "run", _make_subprocess_router(handlers))

    repair_calls: list[dict] = []
    monkeypatch.setattr(
        runner, "repair_environment", lambda **kw: repair_calls.append(kw)
    )

    with pytest.raises(runner.PreflightError) as excinfo:
        runner.preflight_check(ui=False, derived_data_path=derived)

    assert excinfo.value.failure.check == "xcode_select"
    assert repair_calls == [], "xcode_select failure must not trigger repair_environment"


def test_preflight_remediates_simctl_timeout_then_succeeds(monkeypatch, tmp_path):
    derived = tmp_path / "derived"
    monkeypatch.setattr(runner, "PREFLIGHT_LOCK_PATH", tmp_path / "preflight.lock")

    simctl_devices_calls = {"n": 0}

    def simctl_devices_handler(cmd):
        simctl_devices_calls["n"] += 1
        if simctl_devices_calls["n"] == 1:
            raise subprocess.TimeoutExpired(cmd=cmd, timeout=4)
        return _FakeCompleted(0, _healthy_devices_json())

    handlers = [
        (lambda c: c[:2] == ["xcode-select", "-p"], _FakeCompleted(0, "/Applications/Xcode.app/Contents/Developer\n")),
        (lambda c: c[:4] == ["xcrun", "simctl", "list", "devices"], simctl_devices_handler),
        (
            lambda c: c[:4] == ["xcrun", "simctl", "list", "runtimes"],
            _FakeCompleted(0, _healthy_runtimes_json()),
        ),
    ]
    monkeypatch.setattr(runner.subprocess, "run", _make_subprocess_router(handlers))

    monkeypatch.setattr(
        runner,
        "resolve_simulator",
        lambda *, ui: runner.SimulatorDevice("iPhone 17 Pro", "HEALTHY-UDID", "iOS-26-4", runner.DEFAULT_DEVICE_TYPE_ID, "Shutdown"),
    )

    repair_calls: list[dict] = []
    monkeypatch.setattr(
        runner, "repair_environment", lambda **kw: repair_calls.append(kw)
    )

    runner.preflight_check(ui=False, derived_data_path=derived)

    assert simctl_devices_calls["n"] == 2, "simctl list devices should be retried once"
    assert len(repair_calls) == 1, "repair_environment should fire exactly once on simctl timeout"


def test_preflight_gives_up_after_one_remediation(monkeypatch, tmp_path):
    derived = tmp_path / "derived"
    monkeypatch.setattr(runner, "PREFLIGHT_LOCK_PATH", tmp_path / "preflight.lock")

    def always_timeout(cmd):
        raise subprocess.TimeoutExpired(cmd=cmd, timeout=4)

    handlers = [
        (lambda c: c[:2] == ["xcode-select", "-p"], _FakeCompleted(0, "/Applications/Xcode.app/Contents/Developer\n")),
        (lambda c: c[:4] == ["xcrun", "simctl", "list", "devices"], always_timeout),
    ]
    monkeypatch.setattr(runner.subprocess, "run", _make_subprocess_router(handlers))

    repair_calls: list[dict] = []
    monkeypatch.setattr(
        runner, "repair_environment", lambda **kw: repair_calls.append(kw)
    )

    with pytest.raises(runner.PreflightError) as excinfo:
        runner.preflight_check(ui=False, derived_data_path=derived)

    assert excinfo.value.failure.check == "simctl_responsive"
    assert len(repair_calls) == 1, "remediation must run exactly once before giving up"


def test_preflight_skips_when_env_set(monkeypatch, tmp_path):
    monkeypatch.setenv(runner.ENV_PREFLIGHT_SKIP, "1")

    def boom(*args, **kwargs):
        raise AssertionError("subprocess.run must not be called when preflight is skipped")

    monkeypatch.setattr(runner.subprocess, "run", boom)
    repair_calls: list[dict] = []
    monkeypatch.setattr(
        runner, "repair_environment", lambda **kw: repair_calls.append(kw)
    )

    runner.preflight_check(ui=True, derived_data_path=tmp_path / "derived")

    assert repair_calls == []


def test_run_test_writes_preflight_marker_to_summary_on_failure(monkeypatch, tmp_path):
    """When preflight raises, the placeholder summary must start with
    `preflight_failed:` so the harness reviewer keys off the structured prefix.
    """
    monkeypatch.setattr(runner, "DERIVED_DATA_ROOT", tmp_path / "derived")
    monkeypatch.setenv(runner.ENV_WORKTREE_DIR, str(tmp_path / "worktree"))

    def fake_preflight(*, ui, derived_data_path):
        raise runner.PreflightError(
            runner.PreflightFailure(
                check="simctl_responsive",
                detail="xcrun simctl list devices timed out after 4s",
                remediation="repair_environment",
            )
        )

    monkeypatch.setattr(runner, "preflight_check", fake_preflight)

    with pytest.raises(runner.PreflightError):
        runner.run_test("WoontechUITests", ui=True, xcodebuild_args=[])

    summary_path = (
        tmp_path / "worktree" / runner.TEST_ARTIFACTS_SUBDIR / "last-ui-summary.txt"
    )
    failures_path = (
        tmp_path / "worktree" / runner.TEST_ARTIFACTS_SUBDIR / "last-ui-failures.txt"
    )
    assert summary_path.exists()
    summary = summary_path.read_text()
    assert summary.startswith(
        "preflight_failed: simctl_responsive: xcrun simctl list devices timed out after 4s "
        "(remediation: repair_environment)"
    )
    assert "no xcresult bundle found" in summary
    assert failures_path.read_text().startswith("preflight_failed: simctl_responsive:")


def test_run_build_does_not_call_preflight(monkeypatch):
    """run_build() targets a generic destination; it should not invoke preflight_check."""

    def boom(**kw):
        raise AssertionError("preflight_check must not be called from run_build")

    monkeypatch.setattr(runner, "preflight_check", boom)
    monkeypatch.setattr(runner, "run_with_optional_repair", lambda *args, **kwargs: 0)

    assert runner.run_build() == 0


def test_repair_environment_kills_simdiskimaged_and_clears_cache(monkeypatch, tmp_path):
    """repair_environment must kill BOTH CoreSimulatorService and simdiskimaged,
    and must wipe ~/Library/Developer/CoreSimulator/Caches every time so that
    corrupt disk-image cache state doesn't survive the daemon restart.
    """
    quiet_calls: list[list[str]] = []
    removed_paths: list[Path] = []

    monkeypatch.setattr(runner, "_run_quiet", lambda args: quiet_calls.append(list(args)))
    monkeypatch.setattr(runner, "_remove_path", lambda p: removed_paths.append(p))
    monkeypatch.setattr(runner.time, "sleep", lambda s: None)
    monkeypatch.delenv(runner.ENV_DEEP_REPAIR, raising=False)

    derived = tmp_path / "derived"
    runner.repair_environment(simulator_udid="UDID", derived_data_path=derived)

    assert ["killall", "-9", "com.apple.CoreSimulator.CoreSimulatorService"] in quiet_calls
    assert ["killall", "-9", "simdiskimaged"] in quiet_calls

    cache_path = Path.home() / "Library/Developer/CoreSimulator/Caches"
    assert cache_path in removed_paths, "CoreSimulator/Caches must be wiped on every repair"
    assert derived in removed_paths


def test_repair_environment_skips_xcode_caches_without_deep_repair(monkeypatch, tmp_path):
    """Without WOONTECH_XCODE_DEEP_REPAIR=1, the heavy Xcode/DerivedData caches
    must remain untouched (cold-build cost), even though CoreSimulator/Caches is
    always wiped.
    """
    removed_paths: list[Path] = []
    monkeypatch.setattr(runner, "_run_quiet", lambda args: None)
    monkeypatch.setattr(runner, "_remove_path", lambda p: removed_paths.append(p))
    monkeypatch.setattr(runner.time, "sleep", lambda s: None)
    monkeypatch.delenv(runner.ENV_DEEP_REPAIR, raising=False)

    runner.repair_environment(simulator_udid=None, derived_data_path=tmp_path / "derived")

    xcode_dd = Path.home() / "Library/Developer/Xcode/DerivedData"
    xcode_caches = Path.home() / "Library/Caches/com.apple.dt.Xcode"
    assert xcode_dd not in removed_paths
    assert xcode_caches not in removed_paths


def test_preflight_detects_simdiskimaged_unhealthy_signature(monkeypatch, tmp_path):
    derived = tmp_path / "derived"
    monkeypatch.setattr(runner, "PREFLIGHT_LOCK_PATH", tmp_path / "preflight.lock")

    handlers = [
        (lambda c: c[:2] == ["xcode-select", "-p"], _FakeCompleted(0, "/Applications/Xcode.app/Contents/Developer\n")),
        (
            lambda c: c[:4] == ["xcrun", "simctl", "list", "devices"],
            _FakeCompleted(0, _healthy_devices_json()),
        ),
        (
            lambda c: c[:4] == ["xcrun", "simctl", "list", "runtimes"],
            _FakeCompleted(
                0,
                _healthy_runtimes_json(),
                "The service used to manage runtime disk images (simdiskimaged) "
                "crashed or is not responding",
            ),
        ),
    ]
    monkeypatch.setattr(runner.subprocess, "run", _make_subprocess_router(handlers))
    monkeypatch.setattr(
        runner,
        "resolve_simulator",
        lambda *, ui: runner.SimulatorDevice("iPhone 17 Pro", "HEALTHY-UDID", "iOS-26-4", runner.DEFAULT_DEVICE_TYPE_ID, "Shutdown"),
    )

    repair_calls: list[dict] = []
    monkeypatch.setattr(
        runner, "repair_environment", lambda **kw: repair_calls.append(kw)
    )

    with pytest.raises(runner.PreflightError) as excinfo:
        runner.preflight_check(ui=False, derived_data_path=derived)

    assert excinfo.value.failure.check == "simdiskimaged_responsive"
    # Remediation must have run exactly once (then the same fake stderr makes the retry fail again)
    assert len(repair_calls) == 1


def test_preflight_remediates_simdiskimaged_then_succeeds(monkeypatch, tmp_path):
    derived = tmp_path / "derived"
    monkeypatch.setattr(runner, "PREFLIGHT_LOCK_PATH", tmp_path / "preflight.lock")

    runtimes_calls = {"n": 0}

    def runtimes_handler(cmd):
        runtimes_calls["n"] += 1
        if runtimes_calls["n"] == 1:
            return _FakeCompleted(
                0,
                _healthy_runtimes_json(),
                "simdiskimaged crashed or is not responding",
            )
        return _FakeCompleted(0, _healthy_runtimes_json())

    handlers = [
        (lambda c: c[:2] == ["xcode-select", "-p"], _FakeCompleted(0, "/Applications/Xcode.app/Contents/Developer\n")),
        (
            lambda c: c[:4] == ["xcrun", "simctl", "list", "devices"],
            _FakeCompleted(0, _healthy_devices_json()),
        ),
        (lambda c: c[:4] == ["xcrun", "simctl", "list", "runtimes"], runtimes_handler),
    ]
    monkeypatch.setattr(runner.subprocess, "run", _make_subprocess_router(handlers))
    monkeypatch.setattr(
        runner,
        "resolve_simulator",
        lambda *, ui: runner.SimulatorDevice("iPhone 17 Pro", "HEALTHY-UDID", "iOS-26-4", runner.DEFAULT_DEVICE_TYPE_ID, "Shutdown"),
    )

    repair_calls: list[dict] = []
    monkeypatch.setattr(
        runner, "repair_environment", lambda **kw: repair_calls.append(kw)
    )

    runner.preflight_check(ui=False, derived_data_path=derived)

    assert runtimes_calls["n"] >= 2, "runtimes check should be retried after remediation"
    assert len(repair_calls) == 1, "repair_environment should fire exactly once"


def test_persist_test_artifacts_includes_preflight_prefix_when_provided(tmp_path):
    bundle = tmp_path / "missing.xcresult"
    worktree = tmp_path / "worktree"
    worktree.mkdir()

    failure = runner.PreflightFailure(
        check="target_simulator_resolvable",
        detail="no UI simulator available",
        remediation="repair_environment",
    )

    runner._persist_test_artifacts(
        "ui", bundle, worktree, preflight_failure=failure
    )

    summary = (
        worktree / runner.TEST_ARTIFACTS_SUBDIR / "last-ui-summary.txt"
    ).read_text()
    assert summary.startswith(
        "preflight_failed: target_simulator_resolvable: no UI simulator available "
        "(remediation: repair_environment)"
    )


# ---------------------------------------------------------------------------
# boot_simulator tests
# ---------------------------------------------------------------------------


def test_boot_simulator_runs_boot_then_bootstatus(monkeypatch):
    """The healthy path must call `simctl boot` first, then `bootstatus -b`,
    so xcodebuild sees a fully-booted simulator when it starts."""
    handlers = [
        (lambda c: c[:3] == ["xcrun", "simctl", "boot"], _FakeCompleted(0)),
        (lambda c: c[:3] == ["xcrun", "simctl", "bootstatus"], _FakeCompleted(0)),
    ]
    fake_run = _make_subprocess_router(handlers)
    monkeypatch.setattr(runner.subprocess, "run", fake_run)

    runner.boot_simulator("UDID-XYZ")

    boot_calls = [c for c in fake_run.calls if c[:3] == ["xcrun", "simctl", "boot"]]
    status_calls = [c for c in fake_run.calls if c[:3] == ["xcrun", "simctl", "bootstatus"]]
    assert len(boot_calls) == 1
    assert len(status_calls) == 1
    # boot must come before bootstatus
    assert fake_run.calls.index(boot_calls[0]) < fake_run.calls.index(status_calls[0])
    # bootstatus must include `-b` blocking flag and the udid
    assert status_calls[0] == ["xcrun", "simctl", "bootstatus", "UDID-XYZ", "-b"]


def test_boot_simulator_treats_already_booted_as_success(monkeypatch):
    """`simctl boot` on an already-booted device exits non-zero with a specific
    'current state: Booted' message — that's a benign no-op, not a failure.
    bootstatus must still run after."""
    handlers = [
        (
            lambda c: c[:3] == ["xcrun", "simctl", "boot"],
            _FakeCompleted(
                149,
                "",
                "Unable to boot device in current state: Booted",
            ),
        ),
        (lambda c: c[:3] == ["xcrun", "simctl", "bootstatus"], _FakeCompleted(0)),
    ]
    fake_run = _make_subprocess_router(handlers)
    monkeypatch.setattr(runner.subprocess, "run", fake_run)

    # Should not raise.
    runner.boot_simulator("UDID-ALREADY-BOOTED")

    assert any(c[:3] == ["xcrun", "simctl", "bootstatus"] for c in fake_run.calls)


def test_boot_simulator_raises_on_bootstatus_timeout(monkeypatch):
    """If bootstatus -b doesn't return within the timeout, raise
    SimulatorBootError with the timeout duration in the message so the
    placeholder summary makes the wait-time obvious."""

    def boot_handler(cmd):
        return _FakeCompleted(0)

    def bootstatus_handler(cmd):
        raise subprocess.TimeoutExpired(cmd=cmd, timeout=5)

    handlers = [
        (lambda c: c[:3] == ["xcrun", "simctl", "boot"], boot_handler),
        (lambda c: c[:3] == ["xcrun", "simctl", "bootstatus"], bootstatus_handler),
    ]
    monkeypatch.setattr(runner.subprocess, "run", _make_subprocess_router(handlers))

    with pytest.raises(runner.SimulatorBootError) as excinfo:
        runner.boot_simulator("UDID-SLOW", timeout=5)

    assert "did not complete within 5s" in str(excinfo.value)


def test_run_test_writes_simulator_boot_marker_when_boot_fails(monkeypatch, tmp_path):
    """When boot_simulator raises, the placeholder summary must start with
    `preflight_failed: simulator_boot:` so the reviewer agent uses the same
    structured prefix it already keys off for preflight failures."""
    monkeypatch.setattr(runner, "DERIVED_DATA_ROOT", tmp_path / "derived")
    monkeypatch.setenv(runner.ENV_WORKTREE_DIR, str(tmp_path / "worktree"))
    monkeypatch.setattr(runner, "preflight_check", lambda **kw: None)
    monkeypatch.setattr(
        runner,
        "resolve_simulator",
        lambda *, ui: runner.SimulatorDevice("iPhone", "UI-SIM", "runtime", "type", "Shutdown"),
    )
    monkeypatch.setattr(runner, "reset_simulator", lambda udid: None)

    def fake_boot(udid, *, timeout=runner.BOOT_TIMEOUT_SECONDS):
        raise runner.SimulatorBootError(
            f"simctl bootstatus {udid} did not complete within 120s"
        )

    monkeypatch.setattr(runner, "boot_simulator", fake_boot)

    with pytest.raises(runner.SimulatorBootError):
        runner.run_test("WoontechUITests", ui=True, xcodebuild_args=[])

    summary = (
        tmp_path / "worktree" / runner.TEST_ARTIFACTS_SUBDIR / "last-ui-summary.txt"
    ).read_text()
    assert summary.startswith(
        "preflight_failed: simulator_boot: simctl bootstatus UI-SIM "
        "did not complete within 120s"
    )
