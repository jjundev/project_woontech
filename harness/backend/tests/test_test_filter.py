"""Tests for the changed-test scoping filter in pipeline.py."""
from __future__ import annotations

import subprocess
from pathlib import Path
from types import SimpleNamespace

import pytest
from backend import pipeline as P


def _git(args: list[str], cwd: Path) -> str:
    return subprocess.run(
        ["git", *args], cwd=str(cwd), capture_output=True, text=True, check=True
    ).stdout


def _init_ios_repo(tmp_path: Path) -> Path:
    repo = tmp_path / "ios"
    repo.mkdir()
    subprocess.run(["git", "init", "-q", str(repo)], check=True)
    subprocess.run(["git", "-C", str(repo), "config", "user.email", "t@t.t"], check=True)
    subprocess.run(["git", "-C", str(repo), "config", "user.name", "t"], check=True)
    (repo / "WoontechTests").mkdir()
    (repo / "WoontechUITests").mkdir()
    (repo / "WoontechTests" / "ExistingTests.swift").write_text(
        "import XCTest\nclass ExistingTests: XCTestCase {}\n"
    )
    subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
    subprocess.run(["git", "-C", str(repo), "commit", "-qm", "initial"], check=True)
    subprocess.run(["git", "-C", str(repo), "branch", "-M", "main"], check=True)
    subprocess.run(
        ["git", "-C", str(repo), "checkout", "-qb", "feature/test"], check=True
    )
    return repo


def _init_monorepo_ios_repo(tmp_path: Path) -> Path:
    repo_root = tmp_path / "repo"
    repo_root.mkdir()
    ios_root = repo_root / "ios"
    (ios_root / "WoontechTests").mkdir(parents=True)
    (ios_root / "WoontechUITests").mkdir(parents=True)
    subprocess.run(["git", "init", "-q", str(repo_root)], check=True)
    subprocess.run(["git", "-C", str(repo_root), "config", "user.email", "t@t.t"], check=True)
    subprocess.run(["git", "-C", str(repo_root), "config", "user.name", "t"], check=True)
    (ios_root / "WoontechTests" / "ExistingTests.swift").write_text(
        "import XCTest\nclass ExistingTests: XCTestCase {}\n"
    )
    subprocess.run(["git", "-C", str(repo_root), "add", "."], check=True)
    subprocess.run(["git", "-C", str(repo_root), "commit", "-qm", "initial"], check=True)
    subprocess.run(["git", "-C", str(repo_root), "branch", "-M", "main"], check=True)
    subprocess.run(
        ["git", "-C", str(repo_root), "checkout", "-qb", "feature/test"], check=True
    )
    return ios_root


def test_discover_finds_committed_new_test_classes(tmp_path: Path):
    repo = _init_ios_repo(tmp_path)
    new_file = repo / "WoontechTests" / "FooTests.swift"
    new_file.write_text(
        "import XCTest\nclass FooTests: XCTestCase {}\nclass BarTests: XCTestCase {}\n"
    )
    subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
    subprocess.run(["git", "-C", str(repo), "commit", "-qm", "add foo"], check=True)

    result = P.discover_new_test_classes(repo, "main")
    assert result["WoontechTests"] == ["FooTests", "BarTests"]
    assert result["WoontechUITests"] == []


def test_discover_finds_untracked_new_tests(tmp_path: Path):
    repo = _init_ios_repo(tmp_path)
    (repo / "WoontechUITests" / "NewUITests.swift").write_text(
        "import XCTest\nclass NewUITests: XCTestCase {}\n"
    )

    result = P.discover_new_test_classes(repo, "main")
    assert result["WoontechUITests"] == ["NewUITests"]


def test_discover_includes_all_classes_from_modified_existing_test_files(tmp_path: Path):
    repo = _init_ios_repo(tmp_path)
    existing = repo / "WoontechTests" / "ExistingTests.swift"
    # A modified existing test file contributes all of its XCTestCase classes.
    existing.write_text(
        "import XCTest\nclass ExistingTests: XCTestCase {}\nclass SneakyTests: XCTestCase {}\n"
    )
    subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
    subprocess.run(["git", "-C", str(repo), "commit", "-qm", "modify"], check=True)

    result = P.discover_new_test_classes(repo, "main")
    assert result["WoontechTests"] == ["ExistingTests", "SneakyTests"]


def test_discover_new_swift_files_finds_added_and_untracked_project_files(tmp_path: Path):
    repo = _init_ios_repo(tmp_path)
    (repo / "Woontech").mkdir()

    committed_new = repo / "Woontech" / "NewFeature.swift"
    committed_new.write_text("struct NewFeature {}\n")
    subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
    subprocess.run(["git", "-C", str(repo), "commit", "-qm", "add feature"], check=True)

    (repo / "WoontechUITests" / "NewUITests.swift").write_text("import XCTest\n")
    existing = repo / "WoontechTests" / "ExistingTests.swift"
    existing.write_text("import XCTest\nclass ExistingTests: XCTestCase {}\n// touched\n")
    (repo / "Package.swift").write_text("// not an Xcode target source file\n")

    result = P.discover_new_swift_files(repo, "main")

    assert result == [
        "Woontech/NewFeature.swift",
        "WoontechUITests/NewUITests.swift",
    ]


def test_inject_only_testing_replaces_token(tmp_path: Path):
    tpl = "xcodebuild test -scheme Woontech {only_testing:WoontechTests}"
    out = P.inject_only_testing(tpl, ["FooTests", "BarTests"])
    assert out == (
        "xcodebuild test -scheme Woontech "
        "-only-testing:WoontechTests/FooTests -only-testing:WoontechTests/BarTests"
    )


def test_inject_only_testing_returns_none_when_no_classes():
    tpl = "xcodebuild test {only_testing:WoontechTests}"
    assert P.inject_only_testing(tpl, []) is None


def test_inject_only_testing_passes_through_when_no_token():
    assert P.inject_only_testing("echo hi", ["X"]) == "echo hi"


@pytest.mark.asyncio
async def test_resolve_test_commands_reports_changed_test_file_skip_reason(tmp_path: Path, monkeypatch):
    repo = _init_ios_repo(tmp_path)
    events: list[tuple[str, dict[str, object]]] = []

    async def fake_emit(event_type: str, **payload):
        events.append((event_type, payload))

    monkeypatch.setattr(P, "emit", fake_emit)
    config = SimpleNamespace(
        main_branch="main",
        unit_test_cmd="xcodebuild test {only_testing:WoontechTests}",
        ui_test_cmd="xcodebuild test {only_testing:WoontechUITests}",
    )

    unit_cmd, ui_cmd = await P._resolve_test_commands(config, repo, "WF1")

    assert unit_cmd == "echo 'SKIP: no changed unit test files in this worktree'"
    assert ui_cmd == "echo 'SKIP: no changed ui test files in this worktree'"
    assert events == [
        (
            "tests_skipped",
            {
                "task_id": "WF1",
                "target": "WoontechTests",
                "reason": "no changed test files in this worktree",
            },
        ),
        (
            "tests_skipped",
            {
                "task_id": "WF1",
                "target": "WoontechUITests",
                "reason": "no changed test files in this worktree",
            },
        ),
    ]


def test_discover_finds_committed_new_test_classes_in_monorepo(tmp_path: Path):
    repo = _init_monorepo_ios_repo(tmp_path)
    new_file = repo / "WoontechTests" / "FooTests.swift"
    new_file.write_text(
        "import XCTest\nclass FooTests: XCTestCase {}\nclass BarTests: XCTestCase {}\n"
    )
    subprocess.run(["git", "-C", str(repo.parent), "add", "."], check=True)
    subprocess.run(["git", "-C", str(repo.parent), "commit", "-qm", "add foo"], check=True)

    result = P.discover_new_test_classes(repo, "main")
    assert result["WoontechTests"] == ["FooTests", "BarTests"]
    assert result["WoontechUITests"] == []


def test_discover_finds_untracked_new_tests_in_monorepo(tmp_path: Path):
    repo = _init_monorepo_ios_repo(tmp_path)
    (repo / "WoontechUITests" / "NewUITests.swift").write_text(
        "import XCTest\nclass NewUITests: XCTestCase {}\n"
    )

    result = P.discover_new_test_classes(repo, "main")
    assert result["WoontechUITests"] == ["NewUITests"]
