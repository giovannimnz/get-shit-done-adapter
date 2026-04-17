#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
UPDATE_SOURCE=false
QUIET=false

for arg in "$@"; do
  case "$arg" in
    --update-source) UPDATE_SOURCE=true ;;
    --quiet) QUIET=true ;;
    *) ;;
  esac
done

log() {
  if ! $QUIET; then
    echo "$1"
  fi
}

if $UPDATE_SOURCE; then
  log "[1/2] Atualizando GSD fonte em .claude (local)..."
  (cd "$ROOT_DIR" && npx -y get-shit-done-cc@latest --claude --local)
else
  log "[1/2] Pulando update da fonte (.claude)."
fi

log "[2/2] Qoder usa .claude diretamente com --with-claude-config"

log "Pronto."

if ! $QUIET; then
  echo ""
  echo "Uso recomendado:"
  echo "  - Qoder:  ./scripts/qoder-gsd.sh -w '$ROOT_DIR'"
fi
