---
name: relatorio
description: Daily, weekly or monthly report built from the Obsidian journal and git history, keeping work and personal apart. Triggers include "relatorio", "relatório", "report", "/relatorio dia|semana|mes".
---

# Relatório

Argument: `dia` (default), `semana` or `mes`, optionally followed by `trabalho` or `pessoal` to limit the scope. Talk and write in pt-BR.

Vault: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notas`.

## 1. Period

`dia` is today. `semana` goes from Monday to today, `mes` from the 1st to today.

## 2. Gather

Do this for each scope in play (both by default).

The journal is the notes in `<Escopo>/Diario/` within the period. They hold the session lines (`▶` for a start, `■` for commits) and the tagged entries from `/diario`.

Git is the ground truth for what got done. `Trabalho` means every repo under `~/Projects/wc` and `Pessoal` every other repo under `~/Projects`. Per repo, run `git log --all --no-merges --since=<start> --author="$(git config user.email)" --format='%h %ad %s' --date=short` and skip the ones with no commits.

The journal only has what someone logged. If git shows work the journal never mentions, report it anyway.

## 3. Write

Save one file per scope to `<Escopo>/Relatorios/<periodo>-<start date>.md`, e.g. `semana-2026-09-21.md`. A file never mixes the two scopes. Frontmatter: `periodo`, `inicio`, `fim`, `escopo`.

```markdown
# Semana de 21/09 · Trabalho

## Entregas
Per project, the features and fixes that got done, not a commit list. Link [[projeto]] and [[TICKET]].

## Decisões
The #decisao entries and their reasons.

## Importante e bloqueios
The #importante and #bloqueio entries that still matter.

## Números
Commits per project, tickets touched.
```

For `dia`, drop the empty sections. Show the report in the chat as well.
