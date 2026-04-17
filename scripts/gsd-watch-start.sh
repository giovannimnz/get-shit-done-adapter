#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
GSD_DIR="$ROOT_DIR/.gsd"
PID_FILE="$GSD_DIR/gsd-watch.pid"
LOG_FILE="$GSD_DIR/gsd-watch.log"

mkdir -p "$GSD_DIR"

if [[ -f "$PID_FILE" ]]; then
  PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${PID:-}" ]] && kill -0 "$PID" 2>/dev/null; then
    echo "Watcher ja esta rodando (pid=$PID)."
    exit 0
  fi
fi

nohup node "$ROOT_DIR/scripts/gsd-watch-sync.mjs" >>"$LOG_FILE" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"

echo "Watcher iniciado (pid=$PID)."
echo "Log: $LOG_FILE"
