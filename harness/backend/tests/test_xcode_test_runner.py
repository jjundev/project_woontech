from __future__ import annotations

import importlib.util
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
