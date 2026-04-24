from __future__ import annotations

import subprocess

from backend import worktree as W


def test_create_and_remove_worktree(tmp_config):
    task_id = "1234-test-abc"
    path = W.create_worktree(tmp_config, task_id)
    assert path.exists()
    # should be on the feature branch
    branch = subprocess.run(
        ["git", "-C", str(path), "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    assert branch == f"feature/{task_id}"

    # remove
    W.remove_worktree(tmp_config, task_id, delete_branch=True)
    assert not path.exists()


def test_create_twice_is_idempotent(tmp_config):
    task_id = "dup-task-xyz"
    p1 = W.create_worktree(tmp_config, task_id)
    p2 = W.create_worktree(tmp_config, task_id)
    assert p1 == p2
    W.remove_worktree(tmp_config, task_id, delete_branch=True)


def test_create_and_remove_worktree_inside_monorepo(monorepo_config):
    task_id = "mono-task-xyz"
    path = W.create_worktree(monorepo_config, task_id)

    assert path == W.project_worktree_path(monorepo_config, task_id)
    assert path.exists()
    assert monorepo_config.worktree_path(task_id).exists()
    assert path.parent == monorepo_config.worktree_path(task_id)

    branch = subprocess.run(
        ["git", "-C", str(path), "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    assert branch == f"feature/{task_id}"

    W.remove_worktree(monorepo_config, task_id, delete_branch=True)
    assert not monorepo_config.worktree_path(task_id).exists()
