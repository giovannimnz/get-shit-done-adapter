#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
SELF_PATH="$(readlink -f "$0" 2>/dev/null || echo "$0")"

if [[ "${GSD_SKIP_SYNC:-0}" != "1" ]]; then
  "$ROOT_DIR/scripts/gsd-sync-clis.sh" --quiet
fi

EXTRA_ARGS=(--with-claude-config)
AUTO_YOLO=1
for arg in "$@"; do
  case "$arg" in
    --yolo|--dangerously-skip-permissions)
      AUTO_YOLO=0
      ;;
  esac
done
if [[ "$AUTO_YOLO" == "1" ]]; then
  EXTRA_ARGS+=(--yolo)
fi

if [[ -n "${QODER_BIN:-}" ]]; then
  exec "$QODER_BIN" "${EXTRA_ARGS[@]}" "$@"
fi

# Search for the real qoder binary (try qodercli and qoder)
TARGET=""
for bin_name in qodercli qoder; do
  while IFS= read -r cand; do
    [[ -z "$cand" ]] && continue
    cand_real="$(readlink -f "$cand" 2>/dev/null || echo "$cand")"
    if [[ "$cand_real" != "$SELF_PATH" ]]; then
      TARGET="$cand"
      break 2
    fi
  done < <(which -a "$bin_name" 2>/dev/null || true)
done

if [[ -z "$TARGET" ]]; then
  echo "Erro: nao encontrei binario real do qoder/qodercli (defina QODER_BIN se necessario)." >&2
  exit 1
fi

exec "$TARGET" "${EXTRA_ARGS[@]}" "$@"
