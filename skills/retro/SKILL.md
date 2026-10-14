---
name: retro
description: What the user shipped at work since the last retro, grouped by feature and ready to present to the team. Covers only ~/Projects/wc. Triggers include "retro", "retrospectiva", "/retro".
---

# Retro

The team holds a retro every two weeks, usually on a Tuesday, and the user presents what they shipped. Only work counts, meaning the repos under `~/Projects/wc`. Personal projects never appear here. Talk and write in pt-BR.

Vault: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notas`.

## 1. Period

It starts at the date of the latest `💼 Trabalho/📊 Relatorios/retro-*.md` and ends today. With no previous retro, use the last 14 days. An argument like `21d` or a date overrides this.

## 2. Gather, in parallel

- Git is the source of truth. For each repo under `~/Projects/wc`, run `git log --all --no-merges --since="<start> 00:00" --author="$(git config user.email)" --format='%h %ad %D %s%n%b' --date=short`. Ticket keys (PUB-123) show up in the messages and branch names.
- Jira (Atlassian MCP): `assignee = currentUser() AND status CHANGED AFTER "<start>"`. Summary, status and resolution only.
- PRs merged or opened in the period, through `bkt` for the Bitbucket repos and `gh` for the GitHub ones. Title and state.
- The journal notes in `💼 Trabalho/📓 Diario/` for the period. Their **Decisão** and **Resultado** entries explain the why.
- Evidence: the files in `💼 Trabalho/📸 Evidencias/<TICKET>/` for each ticket in the period, and the embeds in the journal.

If a source is not connected, skip it without comment. Git alone is enough.

## 3. Group

Group by feature. A ticket that touched three repos is one item, not three. Give each one or two sentences on what it does for users or the team, so a teammate who never opened the ticket follows it. Mark its state: em produção, mergeado, em review or em andamento.

Leave out chores, version bumps and lint fixes unless someone would notice their impact.

## 4. Write

Save to `💼 Trabalho/📊 Relatorios/retro-<today>.md` with frontmatter `inicio`, `fim`, `escopo: Trabalho`.

```markdown
# Retro 29/09 · 15/09 a 29/09

## Entregas
### <Funcionalidade> · [[PUB-123]] · em produção
What it does and why it matters.

## Em andamento
## Decisões que valem compartilhar
## Bloqueios e pontos pra discutir
```

Embed each deliverable's evidence under it.

Show it in the chat. The user presents it, so never post it anywhere.

## 5. Slides

When I ask for slides, build them as a Slides artifact: run the Artifact `quickstart` with intent `slides` and use the design system it lists. Name the deck `Retro · <period>`.

1. Write the slides in English, since the team works in English, and run the copy through the humanizer.
2. A feature with evidence gets its own slide. Upload its files from `📸 Evidencias` to the artifact's asset store and reference each one by the url the upload returns.
