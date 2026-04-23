from __future__ import annotations

from backend import state as S


def test_create_and_transition(tmp_config):
    created = S.create_task(tmp_config, "Add dark mode")
    assert created.state == "todo"
    assert (tmp_config.todo_dir / created.id / "state.json").exists()

    # transition todo -> planning (moves to ongoing)
    target = S.transition(tmp_config, created.id, "planning")
    assert target.parent == tmp_config.ongoing_dir
    assert target.name == created.id
    assert not (tmp_config.todo_dir / created.id).exists()

    # transition -> done
    target = S.transition(tmp_config, created.id, "done")
    assert target.parent == tmp_config.done_dir
    state = S.read_state(target)
    assert state.state == "done"


def test_list_tasks(tmp_config):
    t1 = S.create_task(tmp_config, "First")
    t2 = S.create_task(tmp_config, "Second")
    S.transition(tmp_config, t2.id, "planning")
    tasks = S.list_tasks(tmp_config)
    ids = {t.id for t in tasks}
    assert {t1.id, t2.id} <= ids


def test_find_task_dir(tmp_config):
    t = S.create_task(tmp_config, "Find me")
    found = S.find_task_dir(tmp_config, t.id)
    assert found.name == t.id
    S.transition(tmp_config, t.id, "implementing")
    found = S.find_task_dir(tmp_config, t.id)
    assert found.parent == tmp_config.ongoing_dir
