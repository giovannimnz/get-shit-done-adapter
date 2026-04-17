#!/usr/bin/env bash
set -euo pipefail

# gsd-adapter - Instala GSD + configura adapter na pasta atual para uso com Qoder
#
# Uso:
#   cd /caminho/do/projeto
#   gsd-adapter
#
# O que faz:
#   1. Instala get-shit-done na .claude/ do projeto atual
#   2. Configura o adapter para Qoder
#   3. Abre Qoder com GSD ativo

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
ADAPTER_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
TARGET_DIR="$(pwd)"

SKIP_QODER=false
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --no-qoder) SKIP_QODER=true ;;
    --force) FORCE=true ;;
    -h|--help)
      echo "gsd-adapter - Instala GSD e configura adapter para Qoder"
      echo ""
      echo "Uso: gsd-adapter [opcoes]"
      echo ""
      echo "Rode dentro da pasta do projeto onde quer instalar o GSD."
      echo ""
      echo "Opcoes:"
      echo "  --no-qoder   Nao abre o Qoder apos instalar"
      echo "  --force      Reinstala mesmo se .claude/get-shit-done ja existe"
      echo "  -h, --help   Mostra esta ajuda"
      exit 0
      ;;
    *) ;;
  esac
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " GSD Adapter para Qoder"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Projeto: $TARGET_DIR"
echo "Adapter: $ADAPTER_DIR"
echo ""

# 1. Instalar GSD na .claude/ do projeto
NPX_ARGS=(--claude --local)
if $FORCE; then
  NPX_ARGS+=(--force)
fi

if [[ -d "$TARGET_DIR/.claude/get-shit-done" ]] && ! $FORCE; then
  echo "[1/3] GSD ja instalado em .claude/get-shit-done (use --force para reinstalar)"
else
  echo "[1/3] Instalando GSD na .claude/ do projeto..."
  (cd "$TARGET_DIR" && npx -y get-shit-done-cc@latest "${NPX_ARGS[@]}")
  echo "      OK"
fi

# 2. Copiar agentes GSD do adapter para o projeto (se existirem no adapter)
if [[ -d "$ADAPTER_DIR/.claude/get-shit-done" ]]; then
  echo "[2/3] Sincronizando agentes e comandos do adapter..."

  # Copiar comandos
  if [[ -d "$ADAPTER_DIR/.claude/commands" ]]; then
    mkdir -p "$TARGET_DIR/.claude/commands"
    cp -r "$ADAPTER_DIR/.claude/commands/"* "$TARGET_DIR/.claude/commands/" 2>/dev/null || true
  fi

  # Copiar agentes
  if [[ -d "$ADAPTER_DIR/.claude/agents" ]]; then
    mkdir -p "$TARGET_DIR/.claude/agents"
    cp -r "$ADAPTER_DIR/.claude/agents/"* "$TARGET_DIR/.claude/agents/" 2>/dev/null || true
  fi

  echo "      OK"
else
  echo "[2/3] Adapter sem .claude/get-shit-done, pulando sync de agentes"
fi

# 3. Abrir Qoder
if $SKIP_QODER; then
  echo "[3/3] Instalacao concluida (--no-qoder: Qoder nao sera aberto)"
else
  echo "[3/3] Abrindo Qoder com GSD..."
  echo ""
  exec "$ADAPTER_DIR/scripts/qoder-gsd.sh" -w "$TARGET_DIR"
fi
