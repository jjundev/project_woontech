#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_URL="${HARNESS_BACKEND_URL:-http://127.0.0.1:8765}"
FRONTEND_URL="${HARNESS_FRONTEND_URL:-http://127.0.0.1:5173}"
FRONTEND_HOST="${HARNESS_FRONTEND_HOST:-127.0.0.1}"

cd "$SCRIPT_DIR"

if [[ -x ".venv/bin/python" ]]; then
  PYTHON_CMD="$SCRIPT_DIR/.venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_CMD="python"
else
  echo "Python was not found. Install Python 3.11+ or create harness/.venv first."
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm was not found. Install Node.js 20+ first."
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl was not found. Install curl first."
  exit 1
fi

if [[ ! -d "frontend/node_modules" ]]; then
  echo "frontend/node_modules was not found. Installing frontend dependencies..."
  (cd frontend && npm install)
fi

url_ready() {
  curl -fsS "$1" >/dev/null 2>&1
}

wait_for_url() {
  local url="$1"
  local name="$2"
  local max_attempts="${3:-60}"

  for ((attempt = 1; attempt <= max_attempts; attempt++)); do
    if url_ready "$url"; then
      return 0
    fi
    sleep 1
  done

  echo "$name did not become ready at $url within ${max_attempts}s."
  return 1
}

open_url() {
  local url="$1"

  if command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 || true
  elif command -v cmd.exe >/dev/null 2>&1; then
    cmd.exe /c start "" "$url" >/dev/null 2>&1 || true
  else
    echo "Open this URL in your browser: $url"
  fi
}

BACKEND_PID=""
FRONTEND_PID=""

cleanup() {
  if [[ -n "$FRONTEND_PID" ]]; then
    kill "$FRONTEND_PID" >/dev/null 2>&1 || true
  fi
  if [[ -n "$BACKEND_PID" ]]; then
    kill "$BACKEND_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

if url_ready "$BACKEND_URL/api/tasks"; then
  echo "Backend is already running at $BACKEND_URL."
else
  echo "Starting backend at $BACKEND_URL..."
  "$PYTHON_CMD" -m backend.server &
  BACKEND_PID="$!"
  wait_for_url "$BACKEND_URL/api/tasks" "Backend" 60
fi

if url_ready "$FRONTEND_URL"; then
  echo "Frontend is already running at $FRONTEND_URL."
else
  echo "Starting frontend at $FRONTEND_URL..."
  (cd frontend && exec npm run dev -- --host "$FRONTEND_HOST") &
  FRONTEND_PID="$!"
  wait_for_url "$FRONTEND_URL" "Frontend" 60
fi

open_url "$FRONTEND_URL"

echo
echo "Harness dashboard is ready."
echo "Backend:  $BACKEND_URL"
echo "Frontend: $FRONTEND_URL"

if [[ -n "$FRONTEND_PID" ]]; then
  echo "Press Ctrl+C to stop the servers started by this script."
  wait "$FRONTEND_PID"
elif [[ -n "$BACKEND_PID" ]]; then
  echo "Frontend was already running. Press Ctrl+C to stop the backend started by this script."
  wait "$BACKEND_PID"
else
  echo "Both servers were already running."
fi
