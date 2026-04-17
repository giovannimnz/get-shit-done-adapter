#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_HOOKS=true
INSTALL_LINKS=true
START_WATCH=false
OVERRIDE_BASE_CMDS=true
SETUP_PATH=true

for arg in "$@"; do
  case "$arg" in
    --no-hooks) INSTALL_HOOKS=false ;;
    --no-links) INSTALL_LINKS=false ;;
    --start-watch) START_WATCH=true ;;
    --no-override) OVERRIDE_BASE_CMDS=false ;;
    --no-path) SETUP_PATH=false ;;
    *) ;;
  esac
done

ensure_hook_block() {
  local hook_file="$1"
  local marker_start="# >>> gsd-qoder-sync >>>"
  local marker_end="# <<< gsd-qoder-sync <<<"
  local block

  block=$(cat <<EOF
$marker_start
PROJECT_DIR="$ROOT_DIR"
if [ -x "\$PROJECT_DIR/scripts/gsd-sync-clis.sh" ]; then
  (cd "\$PROJECT_DIR" && GSD_SKIP_SYNC=1 "\$PROJECT_DIR/scripts/gsd-sync-clis.sh" --quiet >/dev/null 2>&1 || true)
fi
$marker_end
EOF
)

  mkdir -p "$(dirname "$hook_file")"
  if [ ! -f "$hook_file" ]; then
    printf '#!/usr/bin/env bash\nset -e\n\n%s\n' "$block" > "$hook_file"
    chmod +x "$hook_file"
    return
  fi

  # Remove old iflow-qoder-sync blocks if present
  if grep -q "# >>> gsd-iflow-qoder-sync >>>" "$hook_file"; then
    awk -v s="# >>> gsd-iflow-qoder-sync >>>" -v e="# <<< gsd-iflow-qoder-sync <<<" '
      $0==s{inblock=1; next}
      $0==e{inblock=0; next}
      !inblock{print}
    ' "$hook_file" > "$hook_file.tmp"
    mv "$hook_file.tmp" "$hook_file"
  fi

  if grep -q "$marker_start" "$hook_file"; then
    awk -v s="$marker_start" -v e="$marker_end" '
      $0==s{inblock=1; next}
      $0==e{inblock=0; next}
      !inblock{print}
    ' "$hook_file" > "$hook_file.tmp"
    mv "$hook_file.tmp" "$hook_file"
  fi

  printf '\n%s\n' "$block" >> "$hook_file"
  chmod +x "$hook_file"
}

safe_link() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [[ -e "$dst" || -L "$dst" ]]; then
    local current=""
    current="$(readlink -f "$dst" 2>/dev/null || true)"
    local desired="$(readlink -f "$src" 2>/dev/null || true)"

    if [[ -n "$current" && -n "$desired" && "$current" == "$desired" ]]; then
      return
    fi

    # Preserve unexpected existing file as backup once
    if [[ ! -L "$dst" ]]; then
      mv "$dst" "$dst.backup.$(date +%s)"
    else
      rm -f "$dst"
    fi
  fi

  ln -s "$src" "$dst"
}

# Remove old iFlow links if they exist
cleanup_old_links() {
  for old_link in iflow-gsd iflow iflow1 iflow2 iflow3; do
    for dir in "$HOME/.local/bin" "$HOME/bin"; do
      if [[ -L "$dir/$old_link" ]]; then
        rm -f "$dir/$old_link"
      fi
    done
  done
}

if $INSTALL_LINKS; then
  mkdir -p "$HOME/.local/bin" "$HOME/bin"

  # Clean up old iFlow links
  cleanup_old_links

  # Qoder commands
  safe_link "$ROOT_DIR/scripts/qoder-gsd.sh" "$HOME/.local/bin/qoder-gsd"
  safe_link "$ROOT_DIR/scripts/gsd-adapter.sh" "$HOME/.local/bin/gsd-adapter"
  safe_link "$ROOT_DIR/scripts/gsd-sync-clis.sh" "$HOME/.local/bin/gsd-sync-clis"
  safe_link "$ROOT_DIR/scripts/gsd-watch-start.sh" "$HOME/.local/bin/gsd-watch-start"
  safe_link "$ROOT_DIR/scripts/gsd-watch-stop.sh" "$HOME/.local/bin/gsd-watch-stop"
  safe_link "$ROOT_DIR/scripts/gsd-watch-status.sh" "$HOME/.local/bin/gsd-watch-status"
  safe_link "$ROOT_DIR/scripts/gsd-browser-headless.sh" "$HOME/.local/bin/gsd-browser"

  safe_link "$ROOT_DIR/scripts/qoder-gsd.sh" "$HOME/bin/qoder-gsd"
  safe_link "$ROOT_DIR/scripts/gsd-adapter.sh" "$HOME/bin/gsd-adapter"
  safe_link "$ROOT_DIR/scripts/gsd-sync-clis.sh" "$HOME/bin/gsd-sync-clis"
  safe_link "$ROOT_DIR/scripts/gsd-watch-start.sh" "$HOME/bin/gsd-watch-start"
  safe_link "$ROOT_DIR/scripts/gsd-watch-stop.sh" "$HOME/bin/gsd-watch-stop"
  safe_link "$ROOT_DIR/scripts/gsd-watch-status.sh" "$HOME/bin/gsd-watch-status"
  safe_link "$ROOT_DIR/scripts/gsd-browser-headless.sh" "$HOME/bin/gsd-browser"

  # Seamless override: plain qoder/qodercli runs through sync wrapper.
  if $OVERRIDE_BASE_CMDS; then
    safe_link "$ROOT_DIR/scripts/qoder-gsd.sh" "$HOME/bin/qoder"
    safe_link "$ROOT_DIR/scripts/qoder-gsd.sh" "$HOME/bin/qodercli"
    echo "[ok] override automatico de qoder e qodercli ativado via ~/bin"
  fi

  echo "[ok] links em ~/.local/bin e ~/bin criados/atualizados"
fi

# Ensure ~/.local/bin is in PATH via .zshrc (and .bashrc as fallback)
if $SETUP_PATH; then
  PATH_LINE='export PATH="$HOME/.local/bin:$HOME/bin:$PATH"'
  PATH_MARKER="# >>> gsd-adapter-path >>>"
  PATH_MARKER_END="# <<< gsd-adapter-path <<<"

  ensure_path_block() {
    local rc_file="$1"
    [[ -f "$rc_file" ]] || return 0

    # Already has our block
    if grep -q "$PATH_MARKER" "$rc_file" 2>/dev/null; then
      return 0
    fi

    # PATH already set by user manually (uncommented line) - skip
    if grep -v '^\s*#' "$rc_file" 2>/dev/null | grep -q 'HOME/.local/bin'; then
      return 0
    fi

    printf '\n%s\n%s\n%s\n' "$PATH_MARKER" "$PATH_LINE" "$PATH_MARKER_END" >> "$rc_file"
    echo "[ok] PATH adicionado em $rc_file"
  }

  # Detect current shell config
  if [[ -f "$HOME/.zshrc" ]]; then
    ensure_path_block "$HOME/.zshrc"
  fi
  if [[ -f "$HOME/.bashrc" ]]; then
    ensure_path_block "$HOME/.bashrc"
  fi

  # If neither exists, create .zshrc block
  if [[ ! -f "$HOME/.zshrc" && ! -f "$HOME/.bashrc" ]]; then
    printf '\n%s\n%s\n%s\n' "$PATH_MARKER" "$PATH_LINE" "$PATH_MARKER_END" >> "$HOME/.zshrc"
    echo "[ok] PATH adicionado em ~/.zshrc (criado)"
  fi
fi

if $INSTALL_HOOKS; then
  if git -C "$ROOT_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
    GIT_ROOT="$(git -C "$ROOT_DIR" rev-parse --show-toplevel)"
    ensure_hook_block "$GIT_ROOT/.git/hooks/post-merge"
    ensure_hook_block "$GIT_ROOT/.git/hooks/post-checkout"
    ensure_hook_block "$GIT_ROOT/.git/hooks/post-rewrite"
    echo "[ok] hooks git instalados em: $GIT_ROOT/.git/hooks"
  else
    echo "[warn] diretorio nao esta em um repositorio git; hooks ignorados"
  fi
fi

if $START_WATCH; then
  "$ROOT_DIR/scripts/gsd-watch-start.sh"
fi

echo ""
echo "Concluido."
echo ""
echo "Uso:"
echo "  cd /pasta/do/projeto && gsd-adapter     # instala GSD + abre Qoder"
echo "  cd /pasta/do/projeto && gsd-adapter --no-qoder  # so instala GSD"
echo "  qoder -w /pasta/do/projeto              # abre Qoder com GSD"
echo ""
echo "Se acabou de instalar, abra um novo terminal ou rode:"
echo "  source ~/.zshrc"
