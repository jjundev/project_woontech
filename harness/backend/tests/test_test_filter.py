"""Tests for the 'run only new tests' filter in pipeline.py."""
from __future__ import annotations

import subprocess
from pathlib import Path

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


def test_discover_ignores_modified_existing_test_files(tmp_path: Path):
    repo = _init_ios_repo(tmp_path)
    existing = repo / "WoontechTests" / "ExistingTests.swift"
    # Modify an existing test file — adding a class here must NOT be picked up.
    existing.write_text(
        "import XCTest\nclass ExistingTests: XCTestCase {}\nclass SneakyTests: XCTestCase {}\n"
    )
    subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
    subprocess.run(["git", "-C", str(repo), "commit", "-qm", "modify"], check=True)

    result = P.discover_new_test_classes(repo, "main")
    assert result["WoontechTests"] == []


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
