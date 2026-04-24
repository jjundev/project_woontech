# iOS Harness

GAN-loop multi-agent pipeline for automated iOS development.

## Layout

- `backend/` — Python (FastAPI + Claude Agent SDK) pipeline orchestrator
- `frontend/` — Vite + React dashboard
- `harness.config.yaml` — runtime config (build/test commands, retry defaults)

The harness operates on `../ios/` as the iOS project root. `ios_root` may
be the git repo root itself or a subdirectory inside a larger monorepo.

Task **input** lives at `../ios/todo/<task-id>/spec.md` — user-authored and
never modified by the pipeline. Once a pipeline starts it performs ALL work
inside the linked worktree:

- `../worktrees/<task-id>/` — linked git worktree (entire repo checkout).
- `../worktrees/<task-id>/ios/` — agent-facing iOS project directory.
- `../worktrees/<task-id>/ios/ongoing/<task-id>/` — pipeline workspace:
  `state.json`, `implement-plan.md`, `implement-checklist.md`,
  `plan-feedback-version-*.md`, `implement-feedback-version-*.md`,
  `implement-review.md`, `pr.md`. `spec.md` is copied in from the root todo
  folder at start.
- When the pipeline completes, the workspace is moved (inside the worktree)
  to `../worktrees/<task-id>/ios/done/<task-id>/` and committed on the
  feature branch, so the PR diff includes both code changes and task
  artifacts.

The root ios/ checkout is never written to during pipeline execution — a
PreToolUse hook enforces that all Write/Edit calls land inside the worktree.

## Setup

Backend (Python 3.11+):
```
cd harness
python -m venv .venv
source .venv/bin/activate
pip install -r backend/requirements.txt
```

Frontend (Node 20+):
```
cd harness/frontend
npm install
```

## Running

In two terminals:
```
# Terminal A — backend
cd harness
source .venv/bin/activate
python -m backend.server
```
```
# Terminal B — frontend
cd harness/frontend
npm run dev
```

Dashboard: http://127.0.0.1:5173

## Testing

```
cd harness
pytest backend/tests -v
```

## Task folders

Create a task by dropping a folder under `../ios/todo/<task-id>/` with a
`spec.md` inside (write it by hand, from another Claude Code session, or
however you like). The dashboard auto-discovers every folder that contains
`spec.md`. Folder name must match `^[A-Za-z0-9_.-]+$` and becomes the task id.

## Pipeline stages

`planner` → `plan-reviewer` (GAN loop, max N) → `implementor` →
`implement-reviewer` (GAN loop, max N) → `publisher`

When the pipeline starts, a linked worktree is created at `../worktrees/<id>/`
and the pipeline workspace is bootstrapped at
`../worktrees/<id>/ios/ongoing/<id>/` (spec.md copied from the root todo
folder; `state.json` + generated `.md` files written there by agents). The
root `ios/todo/<id>/` is left untouched for the duration of the pipeline.

A PreToolUse hook denies every Write/Edit outside the worktree. The
reviewer's test command is rewritten to only run XCTestCase classes from
test files added or modified in the worktree (vs. `main`); if none exist the
test step is skipped with a `tests_skipped` event.

On successful completion the workspace is moved inside the worktree from
`ongoing/<id>/` to `done/<id>/` via a tracked rename, and the final state is
committed on the feature branch before the publisher opens a PR.

Escalation (retry exhausted) leaves the task in `needs_attention` state with
the worktree preserved for manual inspection. Use the "Resume" button on the
task detail page to re-run the pipeline after manual fixes.
