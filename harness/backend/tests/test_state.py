from __future__ import annotations

from backend import state as S


def _seed_todo(tmp_config, task_id: str, *, spec: str | None = "# default title\n"):
    d = tmp_config.todo_dir / task_id
    d.mkdir(parents=True)
    if spec is not None:
        (d / "spec.md").write_text(spec, encoding="utf-8")
    return d


def _seed_workspace(tmp_config, task_id: str, *, status: str = "ongoing"):
    """Simulate pipeline bootstrap: workspace dir with spec.md under the worktree path."""
    _seed_todo(tmp_config, task_id)
    ws = S.workspace_path(tmp_config, task_id, status=status)
    ws.mkdir(parents=True, exist_ok=True)
    (ws / "spec.md").write_text("# default title\n", encoding="utf-8")
    return ws


def test_scan_discovers_folders_with_spec(tmp_config):
    _seed_todo(tmp_config, "WF1-onboarding", spec="# Onboarding flow\n")
    _seed_todo(tmp_config, "WF2-saju-input", spec="# Saju input\n")
    tasks = {t.id: t for t in S.scan_task_folders(tmp_config)}
    assert set(tasks) == {"WF1-onboarding", "WF2-saju-input"}
    assert tasks["WF1-onboarding"].title == "Onboarding flow"
    assert tasks["WF1-onboarding"].state == "todo"


def test_scan_skips_folders_without_spec(tmp_config):
    _seed_todo(tmp_config, "no-spec", spec=None)
    _seed_todo(tmp_config, "valid", spec="# ok\n")
    ids = {t.id for t in S.scan_task_folders(tmp_config)}
    assert ids == {"valid"}


def test_scan_skips_invalid_task_ids(tmp_config):
    _seed_todo(tmp_config, "bad name with spaces")
    _seed_todo(tmp_config, "valid_id-1")
    ids = {t.id for t in S.scan_task_folders(tmp_config)}
    assert ids == {"valid_id-1"}


def test_scan_reads_persisted_state_from_workspace(tmp_config):
    ws = _seed_workspace(tmp_config, "has-state")
    S.write_state(ws, S.TaskState(id="has-state", state="implementing", title="Custom"))
    tasks = {t.id: t for t in S.scan_task_folders(tmp_config)}
    assert tasks["has-state"].state == "implementing"
    assert tasks["has-state"].title == "Custom"


def test_transition_materializes_state_json_in_workspace(tmp_config):
    _seed_todo(tmp_config, "fresh", spec="# Fresh task\n")
    expected = S.workspace_path(tmp_config, "fresh", status="ongoing")
    assert not (expected / "state.json").exists()

    target = S.transition(tmp_config, "fresh", "planning")
    assert target == expected
    assert (target / "spec.md").exists()  # copied from root
    # Root input folder untouched.
    assert (tmp_config.todo_dir / "fresh" / "spec.md").exists()

    state = S.read_state(target)
    assert state.state == "planning"
    assert state.title == "Fresh task"


def test_transition_to_done_moves_workspace_inside_worktree(tmp_config):
    _seed_todo(tmp_config, "finish-me")
    ws_ongoing = S.transition(tmp_config, "finish-me", "planning")
    S.write_state(ws_ongoing, S.TaskState(id="finish-me", state="planning", title="Move"))

    target = S.transition(tmp_config, "finish-me", "done")
    expected = S.workspace_path(tmp_config, "finish-me", status="done")
    assert target == expected
    assert not ws_ongoing.exists()
    assert S.read_state(target).state == "done"
    # Root input folder still untouched.
    assert (tmp_config.todo_dir / "finish-me").exists()


def test_transition_clears_stale_paused_from(tmp_config):
    _seed_todo(tmp_config, "resume-clean")
    ws = S.transition(tmp_config, "resume-clean", "implementing")
    state = S.read_state(ws)
    state.state = "paused"
    state.paused_from = "implementing"
    S.write_state(ws, state)

    target = S.transition(tmp_config, "resume-clean", "publishing")

    resumed = S.read_state(target)
    assert resumed.state == "publishing"
    assert resumed.paused_from is None


def test_find_task_dir_returns_workspace_when_present(tmp_config):
    ws = _seed_workspace(tmp_config, "T1")
    assert S.find_task_dir(tmp_config, "T1") == ws


def test_find_task_dir_falls_back_to_todo(tmp_config):
    d = _seed_todo(tmp_config, "T2")
    assert S.find_task_dir(tmp_config, "T2") == d
