# iOS Harness

GAN-loop multi-agent pipeline for automated iOS development.

## Layout

- `backend/` — Python (FastAPI + Claude Agent SDK) pipeline orchestrator
- `frontend/` — Vite + React dashboard
- `harness.config.yaml` — runtime config (build/test commands, retry defaults)

The harness operates on `../ios/` (the target iOS git repo). Task folders live in
`../ios/{todo,ongoing,done}/<task-id>/`. Git worktrees live in `../ios/worktrees/<task-id>/`.

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

## Pipeline stages

`spector` → `planner` → `plan-reviewer` (GAN loop, max N) → `implementor` →
`implement-reviewer` (GAN loop, max N) → `publisher`

Escalation (retry exhausted) leaves the task in `needs_attention` state with the
worktree preserved for manual inspection. Use the "Resume" button on the task
detail page to re-run the pipeline after manual fixes.
