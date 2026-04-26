from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

from backend import worktree as W


def _git(repo: Path, *args: str) -> str:
    """Run a git command and return stdout, raising on failure."""
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def _set_origin_main(repo: Path) -> None:
    """Wire `origin` as a self-pointing remote so `git fetch origin main`
    actually succeeds — sync_worktree_with_main now refuses to merge when
    fetch fails, so we need a working origin in the test fixture. Pointing
    `origin` at the same repo works because all our test commits go through
    the local main branch, which fetch-via-self picks up correctly."""
    subprocess.run(
        ["git", "-C", str(repo), "remote", "add", "origin", str(repo)],
        check=True,
    )
    subprocess.run(
        ["git", "-C", str(repo), "fetch", "-q", "origin", "main"],
        check=True,
    )


def _advance_origin_main(repo: Path, file_path: Path, content: str, message: str) -> str:
    """Make a commit on the main branch. The next `git fetch origin main`
    (driven by sync_worktree_with_main) will pick it up automatically since
    origin points at this same repo."""
    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_text(content, encoding="utf-8")
    subprocess.run(["git", "-C", str(repo), "add", "-A"], check=True)
    subprocess.run(["git", "-C", str(repo), "commit", "-q", "-m", message], check=True)
    return _git(repo, "rev-parse", "HEAD")


@pytest.fixture
def synced_worktree(tmp_config):
    """A tmp_config plus an existing worktree on its feature branch and an
    origin/main ref. Returns (config, task_id, worktree_path)."""
    task_id = "sync-task-abc"
    worktree_path = W.create_worktree(tmp_config, task_id)
    _set_origin_main(tmp_config.ios_root)
    return tmp_config, task_id, worktree_path


def test_sync_returns_up_to_date_when_main_already_merged(synced_worktree):
    config, task_id, _ = synced_worktree

    result = W.sync_worktree_with_main(config, task_id)

    assert result == "up-to-date"


def test_sync_fast_forwards_clean_merge(synced_worktree):
    config, task_id, worktree_path = synced_worktree
    repo = config.ios_root

    # main moves forward by adding a brand-new file the worktree never touched.
    _advance_origin_main(
        repo,
        repo / "tools" / "new_runner_helper.py",
        "# added on main\n",
        "Add helper on main",
    )

    # Worktree branch makes its own change to a different file.
    (worktree_path / "feature_only.txt").write_text("worktree-side change\n", encoding="utf-8")
    subprocess.run(["git", "-C", str(worktree_path), "add", "-A"], check=True)
    subprocess.run(
        ["git", "-C", str(worktree_path), "commit", "-q", "-m", "feature side change"],
        check=True,
    )

    result = W.sync_worktree_with_main(config, task_id)

    assert result.startswith("merged: ")
    # Both changes must be present after the merge.
    assert (worktree_path / "tools" / "new_runner_helper.py").exists()
    assert (worktree_path / "feature_only.txt").exists()
    # Latest commit message should be the auto-merge subject.
    head_msg = _git(worktree_path, "log", "-1", "--pretty=%s")
    assert head_msg.startswith("Auto-merge origin/main into worktree branch")


def test_sync_aborts_and_raises_on_conflict(synced_worktree):
    config, task_id, worktree_path = synced_worktree
    repo = config.ios_root

    # main edits a shared file.
    shared = repo / "shared.txt"
    _advance_origin_main(repo, shared, "main version\n", "main edits shared")

    # Worktree edits the same file at the same lines, divergently.
    (worktree_path / "shared.txt").write_text("worktree version\n", encoding="utf-8")
    subprocess.run(["git", "-C", str(worktree_path), "add", "-A"], check=True)
    subprocess.run(
        ["git", "-C", str(worktree_path), "commit", "-q", "-m", "worktree edits shared"],
        check=True,
    )

    with pytest.raises(W.MainMergeConflictError):
        W.sync_worktree_with_main(config, task_id)

    # Abort restored a clean state — no MERGE_HEAD, no UU markers.
    assert not (worktree_path / ".git" / "MERGE_HEAD").exists()
    status_out = _git(worktree_path, "status", "--porcelain")
    assert not any(
        line[:2] in W._CONFLICT_STATUS_PREFIXES for line in status_out.splitlines()
    )


def test_sync_treats_fetch_failure_as_warning_and_continues(synced_worktree, monkeypatch, capsys):
    config, task_id, _ = synced_worktree

    real_run = W._run

    def selective_fail(cmd, cwd):
        if cmd[:2] == ["git", "fetch"]:
            raise W.GitError("simulated network failure")
        return real_run(cmd, cwd)

    monkeypatch.setattr(W, "_run", selective_fail)

    result = W.sync_worktree_with_main(config, task_id)

    # Fetch failure: skip the merge attempt entirely (will retry next resume).
    assert result == "skipped: fetch failed"
    captured = capsys.readouterr()
    assert "fetch origin main failed" in captured.out


def test_sync_aborts_preexisting_merge_state(synced_worktree):
    config, task_id, worktree_path = synced_worktree

    # Forge an in-progress merge by writing MERGE_HEAD directly. We point it at
    # HEAD itself so `git rev-parse --verify MERGE_HEAD` succeeds.
    head = _git(worktree_path, "rev-parse", "HEAD")
    git_dir = Path(_git(worktree_path, "rev-parse", "--git-dir"))
    if not git_dir.is_absolute():
        git_dir = (worktree_path / git_dir).resolve()
    (git_dir / "MERGE_HEAD").write_text(head + "\n", encoding="utf-8")

    with pytest.raises(W.MainMergeConflictError):
        W.sync_worktree_with_main(config, task_id)

    # `git merge --abort` should have cleared MERGE_HEAD.
    assert not (git_dir / "MERGE_HEAD").exists()


def test_sync_auto_commits_pending_changes_first(synced_worktree):
    config, task_id, worktree_path = synced_worktree
    repo = config.ios_root

    # Put origin/main ahead with a non-conflicting change so a merge actually
    # runs after the auto-commit.
    _advance_origin_main(
        repo,
        repo / "main_only.txt",
        "from main\n",
        "main adds main_only.txt",
    )

    # Leave an uncommitted change in the worktree.
    pending = worktree_path / "pending_change.txt"
    pending.write_text("uncommitted work\n", encoding="utf-8")

    result = W.sync_worktree_with_main(config, task_id)

    assert result.startswith("merged: ")
    # The pending file must still be on disk and tracked, not dropped.
    assert pending.exists()
    tracked = _git(worktree_path, "ls-files", "pending_change.txt")
    assert tracked == "pending_change.txt"
    # Worktree must be clean (auto-commit picked up the change).
    assert _git(worktree_path, "status", "--porcelain") == ""
