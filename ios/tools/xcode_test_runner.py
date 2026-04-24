#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Sequence


SCHEME = "Woontech"
PROJECT_NAME = "Woontech.xcodeproj"
DEFAULT_DEVICE_NAME = "iPhone 17 Pro"
DEFAULT_DEVICE_TYPE_ID = "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
UI_SIMULATOR_NAME = "Woontech UI Test iPhone 17 Pro"
DERIVED_DATA_ROOT = Path("/tmp/woontech-derived-data")
ENV_SIMULATOR_UDID = "WOONTECH_SIMULATOR_UDID"
ENV_DEEP_REPAIR = "WOONTECH_XCODE_DEEP_REPAIR"
LLDB_ENV_FAILURE_SIGNATURES = (
    "DebuggerVersionStore",
    "no debugger version",
    "IDELaunchParametersSnapshot",
)
CORESIM_ENV_FAILURE_SIGNATURES = (
    "CoreSimulatorService connection became invalid",
    "Cannot talk to the service used to manage runtime disk images",
    "Failed to install or launch the test runner",
    "IDELaunchiPhoneSimulatorLauncher",
    "Mach error -308",
    "NSMachErrorDomain",
    "simdiskimaged",
)


class RunnerError(RuntimeError):
    pass


@dataclass(frozen=True)
class SimulatorDevice:
    name: str
    udid: str
    runtime_id: str
    device_type_id: str
    state: str


def ios_root() -> Path:
    return Path(__file__).resolve().parents[1]


def project_path() -> Path:
    return ios_root() / PROJECT_NAME


def _run_capture(args: Sequence[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(args, cwd=str(ios_root()), capture_output=True, text=True)
    if check and result.returncode != 0:
        output = (result.stdout + result.stderr).strip()
        raise RunnerError(f"{' '.join(args)} failed with exit {result.returncode}:\n{output}")
    return result


def _load_json(args: Sequence[str]) -> dict[str, Any]:
    result = _run_capture(args)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RunnerError(f"{' '.join(args)} did not return valid JSON") from exc


def _version_key(text: str) -> tuple[int, ...]:
    numbers = re.findall(r"\d+", text)
    return tuple(int(n) for n in numbers)


def flatten_available_devices(devices_json: dict[str, Any]) -> list[SimulatorDevice]:
    devices: list[SimulatorDevice] = []
    for runtime_id, entries in devices_json.get("devices", {}).items():
        if ".SimRuntime.iOS-" not in runtime_id:
            continue
        for entry in entries:
            if not entry.get("isAvailable", True):
                continue
            udid = entry.get("udid")
            name = entry.get("name")
            device_type_id = entry.get("deviceTypeIdentifier")
            if not udid or not name or not device_type_id:
                continue
            devices.append(
                SimulatorDevice(
                    name=name,
                    udid=udid,
                    runtime_id=runtime_id,
                    device_type_id=device_type_id,
                    state=entry.get("state", ""),
                )
            )
    return devices


def choose_device(
    devices_json: dict[str, Any],
    *,
    preferred_name: str = DEFAULT_DEVICE_NAME,
    override_udid: str | None = None,
) -> SimulatorDevice:
    devices = flatten_available_devices(devices_json)
    if override_udid:
        for device in devices:
            if device.udid == override_udid:
                return device
        raise RunnerError(f"{ENV_SIMULATOR_UDID}={override_udid} is not an available iOS simulator")

    exact = [d for d in devices if d.name == preferred_name]
    preferred_family = [d for d in devices if d.name.startswith(preferred_name)]
    iphone = [d for d in devices if d.name.startswith("iPhone")]
    candidates = exact or preferred_family or iphone
    if not candidates:
        raise RunnerError(f"No available iOS simulator found for {preferred_name}")

    def sort_key(device: SimulatorDevice) -> tuple[tuple[int, ...], int, int]:
        exact_rank = 1 if device.name == preferred_name else 0
        booted_rank = 1 if device.state == "Booted" else 0
        return (_version_key(device.runtime_id), exact_rank, booted_rank)

    return max(candidates, key=sort_key)


def choose_runtime_for_device_type(
    runtimes_json: dict[str, Any],
    device_type_id: str = DEFAULT_DEVICE_TYPE_ID,
) -> str:
    candidates: list[dict[str, Any]] = []
    for runtime in runtimes_json.get("runtimes", []):
        if runtime.get("platform") != "iOS" or not runtime.get("isAvailable", False):
            continue
        supported = runtime.get("supportedDeviceTypes", [])
        if any(item.get("identifier") == device_type_id for item in supported):
            candidates.append(runtime)
    if not candidates:
        raise RunnerError(f"No available iOS runtime supports {device_type_id}")

    def sort_key(runtime: dict[str, Any]) -> tuple[tuple[int, ...], str]:
        return (_version_key(str(runtime.get("version", ""))), str(runtime.get("buildversion", "")))

    selected = max(candidates, key=sort_key)
    identifier = selected.get("identifier")
    if not identifier:
        raise RunnerError("Selected runtime is missing an identifier")
    return identifier


def is_environment_launch_failure(output: str) -> bool:
    haystack = output.lower()
    return any(signature.lower() in haystack for signature in LLDB_ENV_FAILURE_SIGNATURES + CORESIM_ENV_FAILURE_SIGNATURES)


def _current_devices_json() -> dict[str, Any]:
    return _load_json(["xcrun", "simctl", "list", "devices", "available", "--json"])


def _current_runtimes_json() -> dict[str, Any]:
    return _load_json(["xcrun", "simctl", "list", "runtimes", "--json"])


def _find_device_by_name(name: str) -> SimulatorDevice | None:
    matches = [device for device in flatten_available_devices(_current_devices_json()) if device.name == name]
    if not matches:
        return None
    return max(matches, key=lambda device: _version_key(device.runtime_id))


def _create_ui_simulator() -> SimulatorDevice:
    runtime_id = choose_runtime_for_device_type(_current_runtimes_json())
    result = _run_capture(
        [
            "xcrun",
            "simctl",
            "create",
            UI_SIMULATOR_NAME,
            DEFAULT_DEVICE_TYPE_ID,
            runtime_id,
        ]
    )
    udid = result.stdout.strip()
    if not udid:
        raise RunnerError("simctl create did not return a simulator UDID")
    return choose_device(_current_devices_json(), override_udid=udid)


def resolve_simulator(*, ui: bool) -> SimulatorDevice:
    override_udid = os.environ.get(ENV_SIMULATOR_UDID)
    if override_udid:
        return choose_device(_current_devices_json(), override_udid=override_udid)
    if ui:
        return _find_device_by_name(UI_SIMULATOR_NAME) or _create_ui_simulator()
    return choose_device(_current_devices_json())


def _run_quiet(args: Sequence[str]) -> None:
    subprocess.run(args, cwd=str(ios_root()), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def reset_simulator(udid: str) -> None:
    _run_quiet(["xcrun", "simctl", "shutdown", udid])
    _run_quiet(["xcrun", "simctl", "erase", udid])


def _remove_path(path: Path) -> None:
    shutil.rmtree(path, ignore_errors=True)


def repair_environment(*, simulator_udid: str | None, derived_data_path: Path) -> None:
    print("Detected Xcode/LLDB/CoreSimulator launch infrastructure failure; repairing environment.", flush=True)
    if simulator_udid:
        _run_quiet(["xcrun", "simctl", "shutdown", simulator_udid])
    _run_quiet(["killall", "-9", "com.apple.CoreSimulator.CoreSimulatorService"])
    time.sleep(2)
    if simulator_udid:
        _run_quiet(["xcrun", "simctl", "erase", simulator_udid])
    _remove_path(derived_data_path)
    if os.environ.get(ENV_DEEP_REPAIR) == "1":
        _remove_path(Path.home() / "Library/Developer/Xcode/DerivedData")
        _remove_path(Path.home() / "Library/Caches/com.apple.dt.Xcode")


def _run_streaming(args: Sequence[str]) -> tuple[int, str]:
    proc = subprocess.Popen(
        args,
        cwd=str(ios_root()),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    output_parts: list[str] = []
    assert proc.stdout is not None
    for line in proc.stdout:
        output_parts.append(line)
        print(line, end="")
    return proc.wait(), "".join(output_parts)


def _xcodebuild_base(derived_data_path: Path) -> list[str]:
    return [
        "xcodebuild",
        "-quiet",
        "-project",
        str(project_path()),
        "-scheme",
        SCHEME,
        "-derivedDataPath",
        str(derived_data_path),
    ]


def run_with_optional_repair(
    args: Sequence[str],
    *,
    simulator_udid: str | None,
    derived_data_path: Path,
) -> int:
    for attempt in range(2):
        code, output = _run_streaming(args)
        if code == 0:
            return 0
        if attempt == 0 and is_environment_launch_failure(output):
            repair_environment(simulator_udid=simulator_udid, derived_data_path=derived_data_path)
            continue
        return code
    return 1


def run_build() -> int:
    derived_data_path = DERIVED_DATA_ROOT / "build"
    args = _xcodebuild_base(derived_data_path) + [
        "-destination",
        "generic/platform=iOS Simulator",
        "build",
    ]
    return run_with_optional_repair(args, simulator_udid=None, derived_data_path=derived_data_path)


def run_test(target: str, *, ui: bool, xcodebuild_args: Sequence[str]) -> int:
    simulator = resolve_simulator(ui=ui)
    if ui:
        reset_simulator(simulator.udid)
    mode = "ui" if ui else "unit"
    derived_data_path = DERIVED_DATA_ROOT / mode
    selection_args = list(xcodebuild_args)
    if not any(arg.startswith("-only-testing:") for arg in selection_args):
        selection_args.insert(0, f"-only-testing:{target}")
    args = _xcodebuild_base(derived_data_path) + [
        "-destination",
        f"id={simulator.udid}",
        "test",
        *selection_args,
    ]
    return run_with_optional_repair(args, simulator_udid=simulator.udid, derived_data_path=derived_data_path)


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run Woontech xcodebuild commands with simulator repair.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("build", help="Build the app for a generic iOS simulator destination.")

    test_parser = subparsers.add_parser("test", help="Run unit or UI tests on a concrete simulator UUID.")
    test_parser.add_argument("--target", required=True, choices=("WoontechTests", "WoontechUITests"))
    test_parser.add_argument("--ui", action="store_true", help="Use the dedicated UI-test simulator and reset it first.")

    namespace, unknown = parser.parse_known_args(argv)
    namespace.xcodebuild_args = unknown
    return namespace


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    try:
        if args.command == "build":
            return run_build()
        if args.command == "test":
            return run_test(args.target, ui=args.ui, xcodebuild_args=args.xcodebuild_args)
        raise RunnerError(f"Unknown command: {args.command}")
    except RunnerError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
