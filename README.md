# Get Shit Done (GSD) - Adapter para Qoder

Este repositorio contem o adapter que permite usar o **Get Shit Done (GSD)** no **Qoder CLI** (qodercli).

## O que e este adapter?

O GSD e um sistema de workflows e comandos para automacao de desenvolvimento de software. Este adapter permite:

- Usar GSD com Qoder CLI
- Pasta `.claude/` como fonte unica dos comandos e agentes GSD
- Qoder le `.claude` diretamente com `--with-claude-config`

## Estrutura

```
get-shit-done-adapter/
├── scripts/              # Scripts de automacao
│   ├── gsd-adapter.sh            # Instala GSD + abre Qoder em qualquer pasta
│   ├── qoder-gsd.sh              # Launcher do Qoder com GSD
│   ├── gsd-sync-clis.sh          # Atualiza fonte GSD
│   ├── gsd-auto-setup.sh         # Setup automatico (links, PATH, hooks)
│   ├── gsd-watch-*.sh/mjs        # Watcher para sync automatico
│   ├── gsd-browser-headless.sh   # Browser headless
│   └── start-gsd-browser.sh      # Quick start do browser
├── .claude/              # Fonte unica do GSD
│   └── get-shit-done/    # Comandos, agentes, workflows
├── .gsd/                 # Dados do watcher (pid, log)
├── GSD-QODER.md          # Documentacao tecnica
└── MANUAL.md             # Manual de uso passo a passo
```

## Instalacao Rapida

```bash
# 1. Clone este repositorio
git clone https://github.com/giovannimnz/get-shit-done-adapter.git
cd get-shit-done-adapter

# 2. Execute o setup (instala links, PATH no .zshrc, hooks git)
./scripts/gsd-auto-setup.sh --start-watch

# 3. Abra um novo terminal (ou: source ~/.zshrc)
```

## Uso

### gsd-adapter (recomendado)

Entre na pasta de qualquer projeto e rode:

```bash
cd /caminho/do/projeto
gsd-adapter
```

Isso automaticamente:
1. Instala o GSD na `.claude/` do projeto (`npx get-shit-done-cc@latest --claude --local`)
2. Sincroniza agentes e comandos do adapter
3. Abre o Qoder com GSD ativo

Para so instalar sem abrir o Qoder:

```bash
gsd-adapter --no-qoder
```

### Metodo alternativo

```bash
qoder -w /caminho/do/projeto
```

## Pre-requisitos

- **Qoder CLI** instalado
- **Node.js** (para scripts .mjs e npx)
- **Bash** (para scripts .sh)

## Documentacao

- [MANUAL.md](MANUAL.md) - Manual completo de uso
- [GSD-QODER.md](GSD-QODER.md) - Documentacao tecnica

## Licenca

Este adapter e distribuido sob a mesma licenca do projeto GSD original.
