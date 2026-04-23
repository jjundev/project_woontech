from __future__ import annotations

from backend import state as S


def _seed_folder(tmp_config, folder: str, task_id: str, *, spec: str | None = "# default title\n"):
    d = tmp_config.state_dir(folder) / task_id
    d.mkdir(parents=True)
    if spec is not None:
        (d / "spec.md").write_text(spec, encoding="utf-8")
    return d


def test_scan_discovers_folders_with_spec(tmp_config):
    _seed_folder(tmp_config, "todo", "WF1-onboarding", spec="# Onboarding flow\n")
    _seed_folder(tmp_config, "todo", "WF2-saju-input", spec="# Saju input\n")
    tasks = {t.id: t for t in S.scan_task_folders(tmp_config)}
    assert set(tasks) == {"WF1-onboarding", "WF2-saju-input"}
    assert tasks["WF1-onboarding"].title == "Onboarding flow"
    assert tasks["WF1-onboarding"].state == "todo"


def test_scan_skips_folders_without_spec(tmp_config):
    _seed_folder(tmp_config, "todo", "no-spec", spec=None)
    _seed_folder(tmp_config, "todo", "valid", spec="# ok\n")
    ids = {t.id for t in S.scan_task_folders(tmp_config)}
    assert ids == {"valid"}


def test_scan_skips_invalid_task_ids(tmp_config):
    _seed_folder(tmp_config, "todo", "bad name with spaces")
    _seed_folder(tmp_config, "todo", "valid_id-1")
    ids = {t.id for t in S.scan_task_folders(tmp_config)}
    assert ids == {"valid_id-1"}


def test_scan_reads_persisted_state_when_available(tmp_config):
    d = _seed_folder(tmp_config, "ongoing", "has-state")
    S.write_state(d, S.TaskState(id="has-state", state="implementing", title="Custom"))
    tasks = {t.id: t for t in S.scan_task_folders(tmp_config)}
    assert tasks["has-state"].state == "implementing"
    assert tasks["has-state"].title == "Custom"


def test_transition_materializes_state_json_on_first_entry(tmp_config):
    _seed_folder(tmp_config, "todo", "fresh", spec="# Fresh task\n")
    assert not (tmp_config.todo_dir / "fresh" / "state.json").exists()
    target = S.transition(tmp_config, "fresh", "planning")
    assert target.parent == tmp_config.ongoing_dir
    state = S.read_state(target)
    assert state.state == "planning"
    assert state.title == "Fresh task"


def test_transition_moves_folder_and_updates_state(tmp_config):
    d = _seed_folder(tmp_config, "todo", "move-me")
    S.write_state(d, S.TaskState(id="move-me", state="todo", title="Move"))
    target = S.transition(tmp_config, "move-me", "done")
    assert target.parent == tmp_config.done_dir
    assert not (tmp_config.todo_dir / "move-me").exists()
    assert S.read_state(target).state == "done"


def test_find_task_dir_searches_all_state_folders(tmp_config):
    _seed_folder(tmp_config, "ongoing", "T1")
    _seed_folder(tmp_config, "done", "T2")
    assert S.find_task_dir(tmp_config, "T1").parent == tmp_config.ongoing_dir
    assert S.find_task_dir(tmp_config, "T2").parent == tmp_config.done_dir
