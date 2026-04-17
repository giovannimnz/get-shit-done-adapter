# GSD - Adapter para Qoder

Este projeto usa `.claude/` como **fonte unica** do GSD.

## Arquitetura

- **Fonte unica:** `.claude/` (comandos, agentes, workflows do GSD)
- **Qoder:** le `.claude` diretamente com `--with-claude-config`

---

## Scripts disponiveis

- `scripts/gsd-adapter.sh`
  - Comando principal: instala GSD na pasta atual + abre Qoder
  - `--no-qoder`: so instala, nao abre Qoder
  - `--force`: reinstala mesmo se ja existe

- `scripts/qoder-gsd.sh`
  - Faz sync silencioso e inicia Qoder com `--with-claude-config`

- `scripts/gsd-sync-clis.sh`
  - Atualiza GSD da fonte `.claude`
  - `--update-source`: atualiza GSD da `.claude` antes
  - `--quiet`: saida reduzida (bom para wrappers/hooks)

- `scripts/gsd-auto-setup.sh`
  - Instala automacoes (links, PATH no .zshrc, hooks git)
  - `--no-path`: nao adiciona PATH ao .zshrc

- `scripts/gsd-watch-sync.mjs`
  - Watcher (escuta mudancas em `.claude`) e dispara sync automatico

- `scripts/gsd-watch-start.sh`
  - Inicia watcher em background

- `scripts/gsd-watch-stop.sh`
  - Para watcher

- `scripts/gsd-watch-status.sh`
  - Status do watcher

- `scripts/gsd-browser-headless.sh`
  - Wrapper do `gsd-browser` com `--no-open` automatico (headless por padrao)

---

## Fluxo rapido com gsd-adapter (recomendado)

```bash
cd /pasta/do/projeto
gsd-adapter
```

Isso instala GSD + abre Qoder. Simples.

---

## Fluxo manual

```bash
./scripts/gsd-sync-clis.sh --update-source
```

### Abrir Qoder com GSD da `.claude`

```bash
./scripts/qoder-gsd.sh -w /home/ubuntu/docker/AtiusCapital
```

---

## Fluxo 100% automatico (recomendado)

### 1) Instalar automacao

```bash
./scripts/gsd-auto-setup.sh --start-watch
```

Isso faz:
- cria links em `~/.local/bin` e `~/bin`:
  - `gsd-adapter`, `qoder-gsd`, `gsd-sync-clis`, `gsd-watch-start`, `gsd-watch-stop`, `gsd-watch-status`, `gsd-browser`
- adiciona PATH ao `~/.zshrc` e `~/.bashrc`
- instala hooks git (`post-merge`, `post-checkout`, `post-rewrite`) para re-sync automatico
- inicia watcher em background
- override transparente:
  - `qoder` -> wrapper com sync + `--with-claude-config`
  - `gsd-browser` -> wrapper headless (`--no-open` por padrao)

### 2) Uso diario

Apos o setup, voce pode usar **sem mudar habito**:

```bash
cd /pasta/do/projeto && gsd-adapter
```

Ou diretamente:

```bash
qoder -w /home/ubuntu/docker/AtiusCapital
```

Tambem funciona o comando de compatibilidade:

```bash
qoder-gsd -w /home/ubuntu/docker/AtiusCapital
```

### 3) Controle do watcher

```bash
gsd-watch-status
gsd-watch-stop
gsd-watch-start
```

---

## Observacoes

- O comportamento do comando GSD e definido pelo arquivo fonte da `.claude`.
- Se voce adicionar/remover comandos ou agentes GSD, o watcher/hooks/sync cuidam da atualizacao.
- Se `~/.local/bin` nao estiver no PATH, o setup ja adiciona ao `.zshrc` automaticamente.
- Para pular a configuracao de PATH: `./scripts/gsd-auto-setup.sh --no-path`
