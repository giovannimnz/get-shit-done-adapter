# Manual de Uso - GSD Adapter para Qoder

## Indice

1. [Pre-requisitos](#pre-requisitos)
2. [Instalacao](#instalacao)
3. [Configuracao](#configuracao)
4. [Uso Basico](#uso-basico)
5. [Uso Avancado](#uso-avancado)
6. [Troubleshooting](#troubleshooting)

---

## Pre-requisitos

Antes de comecar, verifique se voce tem instalado:

- **Qoder CLI** - `qodercli` ou `qoder` (ambos funcionam)
- **Node.js** v14+ - Para executar scripts .mjs
- **Bash** - Para executar scripts .sh
- **Git** - Para versionamento

### Verificacao

```bash
# Verificar Qoder (qualquer um dos dois)
qodercli --version
qoder --version

# Verificar Node.js
node --version
```

---

## Instalacao

### Passo 1: Clonar o Repositorio

```bash
git clone https://github.com/giovannimnz/get-shit-done-adapter.git
cd get-shit-done-adapter
```

### Passo 2: Instalar o Adapter

Execute o script de setup automatico:

```bash
./scripts/gsd-auto-setup.sh --start-watch
```

Este comando faz:

1. Cria links simbolicos em `~/.local/bin` e `~/bin` (incluindo `gsd-adapter`)
2. Adiciona PATH ao `~/.zshrc` (e `~/.bashrc` se existir)
3. Instala hooks Git para sincronizacao automatica
4. Inicia o watcher em background
5. Configura override transparente para `qoder` e `qodercli`

### Passo 3: Abrir novo terminal

```bash
# Ou recarregar o shell atual:
source ~/.zshrc
```

### Passo 4: Verificar Instalacao

```bash
# Verificar se gsd-adapter esta disponivel
which gsd-adapter

# Verificar status do watcher
gsd-watch-status
```

---

## Configuracao

### PATH

O setup automatico ja adiciona o PATH ao `.zshrc`. Se precisar adicionar manualmente:

```bash
# Para Bash (~/.bashrc)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Para Zsh (~/.zshrc)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## Uso Basico

### gsd-adapter (recomendado)

Entre na pasta de qualquer projeto e rode:

```bash
cd /caminho/do/projeto
gsd-adapter
```

Isso automaticamente:
1. Instala o GSD na `.claude/` do projeto
2. Sincroniza agentes e comandos do adapter
3. Abre o Qoder com GSD ativo

Opcoes:

```bash
gsd-adapter --no-qoder   # So instala, nao abre Qoder
gsd-adapter --force       # Reinstala mesmo se ja existe
gsd-adapter --help        # Mostra ajuda
```

### Com Qoder diretamente

Apos o setup, tanto `qoder` quanto `qodercli` carregam GSD automaticamente:

```bash
# Ambos funcionam (o adapter intercepta os dois)
qodercli -w /caminho/do/projeto
qoder -w /caminho/do/projeto

# O wrapper automaticamente:
# 1. Sincroniza GSD
# 2. Inicia Qoder com --with-claude-config
```

### Sincronizacao Manual

```bash
# Sincronizar GSD
./scripts/gsd-sync-clis.sh

# Atualizar GSD da fonte + sincronizar
./scripts/gsd-sync-clis.sh --update-source
```

---

## Uso Avancado

### Comandos GSD Disponiveis

Apos a instalacao, voce pode usar comandos GSD no Qoder:

#### Comandos Principais

```bash
# Criar novo projeto
gsd-new-project

# Criar nova milestone
gsd-new-milestone

# Planejar fase
gsd-plan-phase

# Executar fase
gsd-execute-phase

# Verificar fase
gsd-verify-phase

# Code review
gsd-code-review

# Documentacao
gsd-docs-update
```

#### Workflows

```bash
# Modo autonomo
gsd-autonomous

# Explorar codebase
gsd-explore

# Verificar saude
gsd-health

# Progresso
gsd-progress

# Estatisticas
gsd-stats
```

### Browser Headless

```bash
# Executar GSD Browser em modo headless
./scripts/gsd-browser-headless.sh

# Ou apos setup
gsd-browser  # Automaticamente usa --no-open
```

---

## Watcher

O watcher monitora mudancas em `.claude/` e pode disparar sync automatico:

```bash
# Iniciar watcher
./scripts/gsd-watch-start.sh
# ou
gsd-watch-start

# Verificar status
./scripts/gsd-watch-status.sh
# ou
gsd-watch-status

# Parar watcher
./scripts/gsd-watch-stop.sh
# ou
gsd-watch-stop
```

### Hooks Git

O setup instala hooks Git que disparam sincronizacao automaticamente:

- `post-merge` - Apos pull
- `post-checkout` - Apos checkout de branch
- `post-rewrite` - Apos rebase/amend

---

## Troubleshooting

### Problema: Comando nao encontrado

```bash
# Verificar PATH
echo $PATH | grep -o ".local/bin"

# Se nao encontrar, adicionar ao PATH
export PATH="$HOME/.local/bin:$PATH"
```

### Problema: Watcher nao inicia

```bash
# Verificar se Node.js esta instalado
node --version

# Verificar permissoes
chmod +x scripts/gsd-watch-*.sh scripts/gsd-watch-*.mjs

# Verificar processos existentes
ps aux | grep gsd-watch
```

### Problema: Qoder nao carrega GSD

```bash
# Verificar se Qoder esta instalado
qodercli --version

# Verificar se o override esta ativo (deve apontar para qoder-gsd.sh)
which qodercli
which qoder
ls -la ~/bin/qodercli ~/bin/qoder
```

---

## Logs e Debug

### Verificar Logs do Watcher

```bash
cat .gsd/gsd-watch.log
```

---

## Reinstalacao

Se precisar reinstalar:

```bash
# Parar watcher
./scripts/gsd-watch-stop.sh

# Remover links
rm -f ~/.local/bin/qoder-gsd ~/.local/bin/qoder ~/.local/bin/qodercli
rm -f ~/.local/bin/gsd-*
rm -f ~/bin/qoder-gsd ~/bin/qoder ~/bin/qodercli
rm -f ~/bin/gsd-*

# Remover hooks
rm -f .git/hooks/post-merge .git/hooks/post-checkout .git/hooks/post-rewrite

# Reinstalar
./scripts/gsd-auto-setup.sh --start-watch
```

---

## Suporte

Para problemas ou duvidas:

1. Verifique este manual
2. Consulte [GSD-QODER.md](GSD-QODER.md)
3. Abra uma issue no repositorio

---

## Atualizacao

Para atualizar o adapter:

```bash
cd get-shit-done-adapter
git pull origin main
./scripts/gsd-auto-setup.sh --start-watch
```
