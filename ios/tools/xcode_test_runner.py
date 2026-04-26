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
ENV_WORKTREE_DIR = "WOONTECH_WORKTREE_DIR"
ENV_CLAUDE_PROJECT_DIR = "CLAUDE_PROJECT_DIR"
ENV_PREFLIGHT_SKIP = "WOONTECH_PREFLIGHT_SKIP"
PREFLIGHT_LOCK_PATH = DERIVED_DATA_ROOT / ".preflight.lock"
TEST_ARTIFACTS_SUBDIR = Path(".harness") / "test-results"
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
class PreflightFailure:
    check: str
    detail: str
    remediation: str


class PreflightError(RunnerError):
    def __init__(self, failure: PreflightFailure):
        self.failure = failure
        super().__init__(f"preflight {failure.check} failed: {failure.detail}")


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


def worktree_dir(cli_worktree_dir: str | None = None) -> Path:
    if cli_worktree_dir:
        return Path(cli_worktree_dir)
    for env_name in (ENV_WORKTREE_DIR, ENV_CLAUDE_PROJECT_DIR):
        override = os.environ.get(env_name)
        if override:
            return Path(override)
    return ios_root()


def _capture_xcresulttool(bundle: Path, *args: str) -> str:
    cmd = ["xcrun", "xcresulttool", *args, "--path", str(bundle)]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except (subprocess.TimeoutExpired, OSError) as exc:
        return f"[xcresulttool invocation failed]\ncommand: {' '.join(cmd)}\nerror: {exc}\n"
    body = (result.stdout or "") + (result.stderr or "")
    if not body.strip():
        body = f"[xcresulttool returned empty output]\ncommand: {' '.join(cmd)}\nexit: {result.returncode}\n"
    return body


def _format_failed_tests(tests_output: str) -> str:
    try:
        payload = json.loads(tests_output)
    except json.JSONDecodeError as exc:
        raw = tests_output if tests_output.strip() else "[empty xcresulttool tests output]\n"
        return (
            "[failed to parse xcresult tests JSON]\n"
            f"error: {exc}\n\n"
            "[raw xcresulttool tests output]\n"
            f"{raw}"
        )

    lines: list[str] = []

    def visit(node: dict[str, Any], path: list[str]) -> None:
        name = str(node.get("name") or "<unnamed>")
        node_type = str(node.get("nodeType") or "")
        result = str(node.get("result") or "")
        details = str(node.get("details") or "")
        current_path = [*path, name]
        if result == "Failed" or node_type == "Failure Message":
            lines.append(f"- {' > '.join(current_path)}")
            if node_type:
                lines.append(f"  type: {node_type}")
            if result:
                lines.append(f"  result: {result}")
            if details:
                lines.append("  details:")
                for detail_line in details.splitlines():
                    lines.append(f"    {detail_line}")
        for child in node.get("children") or []:
            if isinstance(child, dict):
                visit(child, current_path)

    for root in payload.get("testNodes") or []:
        if isinstance(root, dict):
            visit(root, [])

    if not lines:
        return "[no failed tests found]\n"
    return "\n".join(lines) + "\n"


def _result_bundle_path(derived_data_path: Path, test_kind: str) -> Path:
    stamp = time.strftime("%Y%m%d-%H%M%S")
    unique = time.time_ns()
    return (
        derived_data_path
        / "ResultBundles"
        / f"Test-Woontech-{test_kind}-{stamp}-{os.getpid()}-{unique}.xcresult"
    )


def _capture_ui_failure_environment(
    out_dir: Path, test_kind: str, simulator_udid: str | None
) -> None:
    """On UI test failure, drop a screenshot of the simulator and a snapshot
    of installed apps so reviewers can tell at a glance what the screen
    actually looked like (e.g. onboarding vs. home for a launch-arg regression)
    without having to rerun the test locally.
    """
    if not simulator_udid:
        return
    screenshot_path = out_dir / f"last-{test_kind}-screenshot.png"
    env_path = out_dir / f"last-{test_kind}-environment.txt"

    try:
        result = subprocess.run(
            ["xcrun", "simctl", "io", simulator_udid, "screenshot", str(screenshot_path)],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != 0:
            print(
                f"warning: simctl screenshot exit {result.returncode}: "
                f"{(result.stderr or result.stdout).strip()}",
                file=sys.stderr,
            )
    except (subprocess.TimeoutExpired, OSError) as exc:
        print(f"warning: simctl screenshot failed: {exc}", file=sys.stderr)

    try:
        listapps = subprocess.run(
            ["xcrun", "simctl", "listapps", simulator_udid],
            capture_output=True,
            text=True,
            timeout=30,
        )
        env_lines = [
            f"# UI failure environment for {test_kind}",
            f"simulator_udid: {simulator_udid}",
            "",
            "[xcrun simctl listapps]",
            f"exit: {listapps.returncode}",
            listapps.stdout or "",
            listapps.stderr or "",
        ]
        env_path.write_text("\n".join(env_lines))
    except (subprocess.TimeoutExpired, OSError) as exc:
        env_path.write_text(
            f"# UI failure environment for {test_kind}\n"
            f"simulator_udid: {simulator_udid}\n"
            f"simctl listapps failed: {exc}\n"
        )


def _persist_test_artifacts(
    test_kind: str,
    bundle: Path,
    target_dir: Path,
    *,
    exit_code: int = 0,
    simulator_udid: str | None = None,
    preflight_failure: PreflightFailure | None = None,
) -> None:
    """Mirror the current xcresult bundle and human-readable summaries into the worktree.

    The harness PreToolUse hook denies absolute paths outside the worktree, so the
    Reviewer agent cannot read xcresult bundles directly under DERIVED_DATA_ROOT.
    Persisting summaries inside the worktree keeps failure diagnostics visible via
    the Read tool without weakening the bash policy.

    When `preflight_failure` is provided, the placeholder body is prepended with a
    structured `preflight_failed:` line so the reviewer agent can key off that prefix
    instead of seeing an opaque "no xcresult bundle found" message.
    """
    out_dir = target_dir / TEST_ARTIFACTS_SUBDIR
    try:
        out_dir.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        print(f"warning: could not create {out_dir}: {exc}", file=sys.stderr)
        return

    summary_path = out_dir / f"last-{test_kind}-summary.txt"
    failures_path = out_dir / f"last-{test_kind}-failures.txt"
    bundle_dest = out_dir / f"last-{test_kind}.xcresult"

    if not bundle.is_dir():
        prefix = ""
        if preflight_failure is not None:
            prefix = (
                f"preflight_failed: {preflight_failure.check}: "
                f"{preflight_failure.detail} "
                f"(remediation: {preflight_failure.remediation})\n"
            )
        message = prefix + (
            f"[no xcresult bundle found]\n"
            f"expected_bundle: {bundle}\n"
            f"This usually means xcodebuild failed before producing a result bundle "
            f"(e.g. a build error). Check the build output streamed during the run.\n"
        )
        summary_path.write_text(message)
        failures_path.write_text(message)
        if exit_code != 0 and test_kind == "ui":
            _capture_ui_failure_environment(out_dir, test_kind, simulator_udid)
        return

    summary = _capture_xcresulttool(bundle, "get", "test-results", "summary")
    tests = _capture_xcresulttool(bundle, "get", "test-results", "tests", "--compact")
    failures = _format_failed_tests(tests)
    header = f"# xcresult {test_kind} ({{section}})\nbundle: {bundle}\n\n"
    summary_path.write_text(header.format(section="summary") + summary)
    failures_path.write_text(header.format(section="tests") + failures)

    if bundle_dest.exists():
        shutil.rmtree(bundle_dest, ignore_errors=True)
    try:
        shutil.copytree(bundle, bundle_dest)
    except OSError as exc:
        (out_dir / f"last-{test_kind}-bundle-copy-error.txt").write_text(
            f"failed to copy {bundle} -> {bundle_dest}: {exc}\n"
        )

    if exit_code != 0 and test_kind == "ui":
        _capture_ui_failure_environment(out_dir, test_kind, simulator_udid)


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


BOOT_TIMEOUT_SECONDS = 120
BOOT_COMMAND_TIMEOUT_SECONDS = 30


class SimulatorBootError(RunnerError):
    """Raised when explicit simulator boot or bootstatus fails — distinct from
    a generic RunnerError so callers can route boot races into the structured
    placeholder summary instead of letting xcodebuild see an under-prepared
    simulator.
    """


def boot_simulator(udid: str, *, timeout: int = BOOT_TIMEOUT_SECONDS) -> None:
    """Bring the simulator to a fully-ready state synchronously, so xcodebuild
    can install the test runner the moment it starts.

    Steps:
      1. `xcrun simctl boot <udid>` — idempotent (no-op if already Booted).
      2. `xcrun simctl bootstatus <udid> -b` — blocks until SpringBoard and
         attendant services are up; returns 0 immediately when already booted.

    On timeout or non-zero exit, raises `SimulatorBootError`. The caller
    (`run_test`) routes that into the existing placeholder-summary path so
    the harness reviewer sees a structured `preflight_failed: simulator_boot`
    marker rather than an opaque "Failed to install or launch the test runner"
    crash from xcodebuild.
    """
    print(f"[boot] xcrun simctl boot {udid}", flush=True)
    try:
        boot_result = subprocess.run(
            ["xcrun", "simctl", "boot", udid],
            cwd=str(ios_root()),
            capture_output=True,
            text=True,
            timeout=BOOT_COMMAND_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        raise SimulatorBootError(
            f"simctl boot {udid} did not complete within "
            f"{BOOT_COMMAND_TIMEOUT_SECONDS}s"
        )
    # "Unable to boot device in current state: Booted" is a benign no-op that
    # simctl signals via a non-zero exit. Treat that one phrase as success;
    # any other non-zero exit is a real failure.
    if boot_result.returncode != 0:
        combined = (boot_result.stderr or "") + (boot_result.stdout or "")
        if "current state: Booted" not in combined:
            raise SimulatorBootError(
                f"simctl boot {udid} exit {boot_result.returncode}: "
                f"{_shorten_detail(combined)}"
            )

    print(
        f"[boot] xcrun simctl bootstatus {udid} -b (timeout {timeout}s)",
        flush=True,
    )
    try:
        status = subprocess.run(
            ["xcrun", "simctl", "bootstatus", udid, "-b"],
            cwd=str(ios_root()),
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        raise SimulatorBootError(
            f"simctl bootstatus {udid} did not complete within {timeout}s"
        )
    if status.returncode != 0:
        combined = (status.stderr or "") + (status.stdout or "")
        raise SimulatorBootError(
            f"simctl bootstatus {udid} exit {status.returncode}: "
            f"{_shorten_detail(combined)}"
        )
    print(f"[boot] simulator {udid} ready", flush=True)


def _remove_path(path: Path) -> None:
    shutil.rmtree(path, ignore_errors=True)


def repair_environment(*, simulator_udid: str | None, derived_data_path: Path) -> None:
    print("Detected Xcode/LLDB/CoreSimulator launch infrastructure failure; repairing environment.", flush=True)
    if simulator_udid:
        _run_quiet(["xcrun", "simctl", "shutdown", simulator_udid])
    _run_quiet(["killall", "-9", "com.apple.CoreSimulator.CoreSimulatorService"])
    # simdiskimaged is a separate launchd-managed daemon that frequently crashes
    # alongside (or independently of) CoreSimulatorService. launchd will revive
    # it, but only after the corrupt state goes away.
    _run_quiet(["killall", "-9", "simdiskimaged"])
    time.sleep(2)
    # The CoreSimulator caches (disk images, runtime metadata) commonly carry
    # the corruption forward across daemon restarts; clear them every repair.
    # The heavier Xcode/DerivedData caches stay behind WOONTECH_XCODE_DEEP_REPAIR
    # because wiping them triples cold-build time.
    _remove_path(Path.home() / "Library/Developer/CoreSimulator/Caches")
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


def _preflight_log(message: str) -> None:
    print(f"[preflight] {message}", flush=True)


_PREFLIGHT_LOCK_UNAVAILABLE = object()


def _try_acquire_preflight_lock() -> Any:
    """Best-effort exclusive lock so concurrent test runs don't kill each other's
    CoreSimulatorService during remediation.

    Returns:
        - a locked file handle when the lock was acquired
        - None when another process currently holds the lock (skip remediation)
        - `_PREFLIGHT_LOCK_UNAVAILABLE` when the lock file path is unwritable in
          the current sandbox (proceed with remediation; locking is unavailable
          here and we'd rather repair than refuse).
    """
    import fcntl

    try:
        PREFLIGHT_LOCK_PATH.parent.mkdir(parents=True, exist_ok=True)
        handle = open(PREFLIGHT_LOCK_PATH, "w")
    except OSError:
        return _PREFLIGHT_LOCK_UNAVAILABLE
    try:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        return handle
    except BlockingIOError:
        try:
            handle.close()
        except Exception:
            pass
        return None
    except OSError:
        try:
            handle.close()
        except Exception:
            pass
        return _PREFLIGHT_LOCK_UNAVAILABLE


def _shorten_detail(text: str, *, limit: int = 200) -> str:
    """Collapse multi-line subprocess output to a single short line so log lines
    and placeholder summaries stay scannable. Long stderr from `simctl` etc. is
    informative as a stream but useless in a one-line failure detail.
    """
    first = ""
    for line in text.splitlines():
        stripped = line.strip()
        if stripped:
            first = stripped
            break
    if not first:
        first = text.strip()
    if len(first) > limit:
        first = first[: limit - 1] + "…"
    return first


def preflight_check(*, ui: bool, derived_data_path: Path) -> None:
    """Verify Xcode toolchain, simctl responsiveness, target simulator availability,
    and writable derived-data path before xcodebuild is invoked. Each check has its
    own remediation policy (one retry max). Raises `PreflightError` on terminal
    failure so `run_test()`'s `finally` block can write a placeholder summary file
    visible to the harness reviewer.

    Honors `WOONTECH_PREFLIGHT_SKIP=1` for CI/headless escape and
    `WOONTECH_SIMULATOR_UDID` via the existing `resolve_simulator()` path.
    """
    if os.environ.get(ENV_PREFLIGHT_SKIP) == "1":
        _preflight_log("skipped (WOONTECH_PREFLIGHT_SKIP=1)")
        return

    started = time.monotonic()

    def _check_xcode_select() -> None:
        try:
            result = subprocess.run(
                ["xcode-select", "-p"],
                capture_output=True,
                text=True,
                timeout=4,
            )
        except (subprocess.TimeoutExpired, OSError) as exc:
            raise PreflightError(
                PreflightFailure("xcode_select", f"xcode-select -p failed: {exc}", "none")
            )
        if result.returncode != 0:
            raise PreflightError(
                PreflightFailure(
                    "xcode_select",
                    _shorten_detail(
                        f"xcode-select -p exit {result.returncode}: "
                        f"{result.stderr or result.stdout}"
                    ),
                    "none — run: sudo xcode-select -s /Applications/Xcode.app",
                )
            )
        path = (result.stdout or "").strip()
        if not path or "/Contents/Developer" not in path:
            raise PreflightError(
                PreflightFailure(
                    "xcode_select",
                    f"unexpected developer dir: {path!r}",
                    "none — run: sudo xcode-select -s /Applications/Xcode.app",
                )
            )

    def _check_simctl_responsive() -> dict[str, Any]:
        try:
            result = subprocess.run(
                ["xcrun", "simctl", "list", "devices", "available", "--json"],
                capture_output=True,
                text=True,
                timeout=4,
            )
        except subprocess.TimeoutExpired:
            raise PreflightError(
                PreflightFailure(
                    "simctl_responsive",
                    "xcrun simctl list devices timed out after 4s",
                    "none",
                )
            )
        except OSError as exc:
            raise PreflightError(
                PreflightFailure("simctl_responsive", f"xcrun invocation failed: {exc}", "none")
            )
        if result.returncode != 0:
            raise PreflightError(
                PreflightFailure(
                    "simctl_responsive",
                    _shorten_detail(
                        f"xcrun simctl exit {result.returncode}: "
                        f"{result.stderr or result.stdout}"
                    ),
                    "none",
                )
            )
        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            raise PreflightError(
                PreflightFailure("simctl_responsive", f"simctl output not JSON: {exc}", "none")
            )

    def _check_simdiskimaged_responsive() -> None:
        # simdiskimaged is a separate launchd daemon. simctl can answer
        # `list devices` even when simdiskimaged is dead, so we look for the
        # specific failure signatures that show up in stderr/stdout when the
        # daemon is unresponsive. `pgrep simdiskimaged` is unreliable because
        # launchd revives a zombie shell process even when the service XPC is
        # dead.
        try:
            result = subprocess.run(
                ["xcrun", "simctl", "list", "runtimes", "--json"],
                capture_output=True,
                text=True,
                timeout=4,
            )
        except (subprocess.TimeoutExpired, OSError) as exc:
            raise PreflightError(
                PreflightFailure(
                    "simdiskimaged_responsive",
                    f"xcrun simctl list runtimes failed: {exc}",
                    "none",
                )
            )
        combined = (result.stderr or "") + "\n" + (result.stdout or "")
        bad_signatures = (
            "simdiskimaged crashed",
            "simdiskimaged returned error",
            "Could not kickstart simdiskimaged",
            "service used to manage runtime disk images",
        )
        for sig in bad_signatures:
            if sig in combined:
                raise PreflightError(
                    PreflightFailure(
                        "simdiskimaged_responsive",
                        _shorten_detail(f"simdiskimaged unhealthy: {combined}"),
                        "none",
                    )
                )

    def _check_runtimes_available() -> None:
        try:
            result = subprocess.run(
                ["xcrun", "simctl", "list", "runtimes", "--json"],
                capture_output=True,
                text=True,
                timeout=4,
            )
        except (subprocess.TimeoutExpired, OSError) as exc:
            raise PreflightError(
                PreflightFailure(
                    "coresim_runtime_available",
                    f"xcrun simctl list runtimes failed: {exc}",
                    "none",
                )
            )
        if result.returncode != 0:
            raise PreflightError(
                PreflightFailure(
                    "coresim_runtime_available",
                    _shorten_detail(
                        f"exit {result.returncode}: {result.stderr or result.stdout}"
                    ),
                    "none",
                )
            )
        try:
            payload = json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            raise PreflightError(
                PreflightFailure(
                    "coresim_runtime_available", f"runtimes output not JSON: {exc}", "none"
                )
            )
        if not payload.get("runtimes"):
            raise PreflightError(
                PreflightFailure(
                    "coresim_runtime_available", "no runtimes returned by simctl", "none"
                )
            )

    def _check_target_simulator(devices_json: dict[str, Any]) -> SimulatorDevice:
        if not flatten_available_devices(devices_json):
            raise PreflightError(
                PreflightFailure(
                    "no_simulators_installed",
                    "no available iOS simulators on this host",
                    "none — install simulator runtimes via Xcode",
                )
            )
        try:
            return resolve_simulator(ui=ui)
        except RunnerError as exc:
            raise PreflightError(
                PreflightFailure("target_simulator_resolvable", str(exc), "none")
            )

    def _check_simulator_bootable(udid: str) -> None:
        try:
            result = subprocess.run(
                ["xcrun", "simctl", "listapps", udid],
                capture_output=True,
                text=True,
                timeout=4,
            )
        except (subprocess.TimeoutExpired, OSError) as exc:
            raise PreflightError(
                PreflightFailure(
                    "simulator_bootable", f"simctl listapps {udid} failed: {exc}", "none"
                )
            )
        if result.returncode != 0:
            raise PreflightError(
                PreflightFailure(
                    "simulator_bootable",
                    _shorten_detail(
                        f"simctl listapps exit {result.returncode}: "
                        f"{result.stderr or result.stdout}"
                    ),
                    "none",
                )
            )

    def _check_derived_data_writable() -> None:
        try:
            derived_data_path.mkdir(parents=True, exist_ok=True)
            probe = derived_data_path / ".preflight"
            probe.write_text("ok")
            probe.unlink()
        except OSError as exc:
            raise PreflightError(
                PreflightFailure(
                    "derived_data_writable",
                    f"cannot write {derived_data_path}: {exc}",
                    "none",
                )
            )

    def _remediate_with_repair(reason: str) -> str:
        lock = _try_acquire_preflight_lock()
        if lock is None:
            return "skipped (lock held by concurrent test run)"
        held = lock is not _PREFLIGHT_LOCK_UNAVAILABLE
        try:
            note = "" if held else " (lock unavailable in sandbox)"
            _preflight_log(
                f"remediating ({reason}): repair_environment (kill CoreSim + erase){note}"
            )
            repair_environment(simulator_udid=None, derived_data_path=derived_data_path)
            return "repair_environment" if held else "repair_environment (no lock)"
        finally:
            if held:
                try:
                    lock.close()
                except Exception:
                    pass

    def _run_with_remediation(
        name: str, fn, remediation_fn=None
    ) -> Any:
        check_started = time.monotonic()
        try:
            value = fn()
            elapsed_ms = int((time.monotonic() - check_started) * 1000)
            _preflight_log(f"{name} ... ok ({elapsed_ms}ms)")
            return value
        except PreflightError as exc:
            _preflight_log(f"{name} ... FAIL: {exc.failure.detail}")
            if remediation_fn is None:
                raise
            remediation = remediation_fn(name)
            try:
                value = fn()
            except PreflightError as retry_exc:
                _preflight_log(
                    f"{name} (retry) ... FAIL: {retry_exc.failure.detail}"
                )
                raise PreflightError(
                    PreflightFailure(
                        retry_exc.failure.check,
                        retry_exc.failure.detail,
                        remediation,
                    )
                )
            elapsed_ms = int((time.monotonic() - check_started) * 1000)
            _preflight_log(f"{name} (retry) ... ok ({elapsed_ms}ms)")
            return value

    try:
        _run_with_remediation("xcode_select", _check_xcode_select)
        devices_json = _run_with_remediation(
            "simctl_responsive",
            _check_simctl_responsive,
            remediation_fn=lambda _name: _remediate_with_repair("simctl_responsive"),
        )
        _run_with_remediation(
            "simdiskimaged_responsive",
            _check_simdiskimaged_responsive,
            remediation_fn=lambda _name: _remediate_with_repair("simdiskimaged_responsive"),
        )
        _run_with_remediation(
            "coresim_runtime_available",
            _check_runtimes_available,
            remediation_fn=lambda _name: _remediate_with_repair("coresim_runtime_available"),
        )
        simulator = _run_with_remediation(
            "target_simulator_resolvable",
            lambda: _check_target_simulator(devices_json),
            remediation_fn=lambda _name: _remediate_with_repair("target_simulator_resolvable"),
        )
        if ui and simulator.state == "Booted":
            _run_with_remediation(
                "simulator_bootable",
                lambda: _check_simulator_bootable(simulator.udid),
                remediation_fn=lambda _name: (
                    reset_simulator(simulator.udid) or "reset_simulator"
                ),
            )
        _run_with_remediation(
            "derived_data_writable",
            _check_derived_data_writable,
            remediation_fn=lambda _name: (_remove_path(derived_data_path) or "remove_derived_data"),
        )
    except PreflightError as exc:
        _preflight_log(
            f"ABORT check={exc.failure.check} detail={exc.failure.detail!r} "
            f"remediation_attempted={exc.failure.remediation!r}"
        )
        raise

    elapsed = time.monotonic() - started
    _preflight_log(f"passed in {elapsed:.1f}s")


def run_with_optional_repair(
    args: Sequence[str],
    *,
    simulator_udid: str | None,
    derived_data_path: Path,
    result_bundle_path: Path | None = None,
) -> int:
    for attempt in range(2):
        if result_bundle_path is not None:
            _remove_path(result_bundle_path)
            result_bundle_path.parent.mkdir(parents=True, exist_ok=True)
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


def run_test(
    target: str,
    *,
    ui: bool,
    xcodebuild_args: Sequence[str],
    worktree_dir_override: str | None = None,
) -> int:
    # Compute outputs up-front so the harness-visible summary file is written
    # via the `finally` block even if simulator resolution/reset raises before
    # xcodebuild starts. The harness treats a missing summary as
    # `diagnostic_infra_missing` and stops the run; persisting a placeholder
    # keeps the failure visible to the reviewer instead.
    mode = "ui" if ui else "unit"
    derived_data_path = DERIVED_DATA_ROOT / mode
    result_bundle_path = _result_bundle_path(derived_data_path, mode)
    target_worktree = worktree_dir(worktree_dir_override)
    simulator_udid: str | None = None
    pre_failure: PreflightFailure | None = None
    code = 1
    try:
        try:
            preflight_check(ui=ui, derived_data_path=derived_data_path)
        except PreflightError as exc:
            pre_failure = exc.failure
            raise
        simulator = resolve_simulator(ui=ui)
        simulator_udid = simulator.udid
        if ui:
            reset_simulator(simulator.udid)
            try:
                boot_simulator(simulator.udid)
            except SimulatorBootError as exc:
                # Surface boot failures through the same structured prefix the
                # reviewer agent already keys off (`preflight_failed:`), so a
                # boot race produces a readable placeholder summary instead of
                # crashing inside xcodebuild with an opaque test-runner launch
                # error.
                pre_failure = PreflightFailure(
                    check="simulator_boot",
                    detail=str(exc),
                    remediation="none",
                )
                raise
        selection_args = list(xcodebuild_args)
        if not any(arg.startswith("-only-testing:") for arg in selection_args):
            selection_args.insert(0, f"-only-testing:{target}")
        args = _xcodebuild_base(derived_data_path) + [
            "-destination",
            f"id={simulator.udid}",
            "-resultBundlePath",
            str(result_bundle_path),
            "test",
            *selection_args,
        ]
        code = run_with_optional_repair(
            args,
            simulator_udid=simulator.udid,
            derived_data_path=derived_data_path,
            result_bundle_path=result_bundle_path,
        )
        return code
    finally:
        try:
            _persist_test_artifacts(
                mode,
                result_bundle_path,
                target_worktree,
                exit_code=code,
                simulator_udid=simulator_udid if ui else None,
                preflight_failure=pre_failure,
            )
        except Exception as exc:  # noqa: BLE001 — never let persist break the runner
            print(
                f"warning: _persist_test_artifacts failed for {mode}: {exc}",
                file=sys.stderr,
            )


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run Woontech xcodebuild commands with simulator repair.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("build", help="Build the app for a generic iOS simulator destination.")

    test_parser = subparsers.add_parser("test", help="Run unit or UI tests on a concrete simulator UUID.")
    test_parser.add_argument("--target", required=True, choices=("WoontechTests", "WoontechUITests"))
    test_parser.add_argument("--ui", action="store_true", help="Use the dedicated UI-test simulator and reset it first.")
    test_parser.add_argument("--worktree-dir", help="Directory where .harness/test-results should be written.")

    namespace, unknown = parser.parse_known_args(argv)
    namespace.xcodebuild_args = unknown
    return namespace


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    try:
        if args.command == "build":
            return run_build()
        if args.command == "test":
            return run_test(
                args.target,
                ui=args.ui,
                xcodebuild_args=args.xcodebuild_args,
                worktree_dir_override=args.worktree_dir,
            )
        raise RunnerError(f"Unknown command: {args.command}")
    except RunnerError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
