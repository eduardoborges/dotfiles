---
name: diario
description: Log the current session to the Obsidian journal. Keeps the day's task list current, tags decisions, results, important facts and blockers under their project and ticket, and keeps each ticket's note up to date. Triggers include "diario", "diário", "log this", "registra no diário", "/diario".
---

# Diário

Talk to the user in pt-BR and write the entries in pt-BR.

## 1. Context

Run `~/.claude/hooks/journal.sh ctx "$PWD"`. It creates any missing notes and prints `escopo`, `projeto`, `ticket`, `branch`, `repo`, `nota` (today's note) and `evidencias`. Work and personal notes never mix, so write only to that `nota`.

If the session also touched another repo, run `ctx` for it and log that part in its own note.

## 2. Tasks

Today's note starts with `## Tarefas`, a checklist of my work with one task per line:

```markdown
- [ ] [[<projeto>]] [[<ticket>]] <the task in a few words>
- [x] [[<projeto>]] [[<ticket>]] <the task> ✅ HH:MM
```

A task is a piece of work I'd mention in a standup: implementing an endpoint, reviewing a PR, fixing a bug, answering review comments. The steps inside it, like running tests or reading a file, are not tasks.

Update the list from the session. Add the tasks that started, check off the finished ones with the time, and reword a task whose scope changed. Edit lines in place and never duplicate one. You don't need to carry open tasks to the next day: the hook copies them into the new note.

## 3. Evidence

Keep the proof of the work when there is any: screenshots, screen recordings, GIFs. It comes from files the session produced (a browser or simulator screenshot, a recording) or files I point at. macOS saves my screenshots and recordings to `~/Desktop`, so "the print I just took" means the newest one there.

Copy each file to `evidencias` as `YYYY-MM-DD-<short-slug>.<ext>`, and never move or delete the original. Embed it under the entry it proves:

```markdown
- **Resultado** · status change blocks the user in Auth0
  ![[2026-09-25-staff-block-auth0.png]]
```

A file that no entry points to gets lost, so always tie it to a line.

## 4. Classify

Keep only what is worth rereading a month from now, under one of four labels:

| Label | What goes there |
|---|---|
| **Decisão** | The choice, why, and the alternative you dropped |
| **Resultado** | Something delivered or confirmed working: PR merged, fix verified, tests green |
| **Importante** | A fact that will bite later: a trap, a limit, a contact, an environment detail |
| **Bloqueio** | What is stuck and who it waits on |

Leave out the step by step, the commands you ran and anything the commit messages already say. One line per entry.

## 5. Write

Under `## Registro`, find the heading for the project and ticket, `### [[<projeto>]] · [[<ticket>]]` (just `### [[<projeto>]]` when there is no ticket), and append the entries below it. If it is missing, add it at the end of `## Registro`. `## Commits` stays last; the hook writes it.

Each entry is one line: `- **Decisão** · <text>`. Wrap other tickets and projects that came up in `[[...]]` as well. If no task changed and nothing qualifies, tell the user and write nothing. Otherwise show them what you wrote.

## 6. Ticket note

When `ctx` prints a `ticket`, keep that ticket's note current too: `🎫 Tickets/<ticket>.md`, on the same side of the vault as `nota` (the folder next to `📓 Diario/`). The hook creates it with only a `projeto` field, so fill it on the first entry for the ticket and update it on every entry after.

The daily note is the log. The ticket note is the current state, so rewrite its sections in place instead of appending to them:

- `# <ticket> · <title>`
- `## Objetivo`: why the ticket exists, in two or three lines.
- `## Estado`: each PR with its link and status, the merge order, and the Jira status.
- `## Decisões`: only the ones still standing. Drop a reversed decision or say what replaced it.
- `## Importante`: traps that still apply.
- `## Pendências`: what's open and who it waits on, as plain bullets. No `- [ ]`, so it doesn't duplicate the day's task list.
- `## Linha do tempo`: one line per day, with a `[[YYYY-MM-DD]]` link and what moved.

When a later fact corrects an earlier entry, fix the ticket note and leave the daily note as it was written. Keep the hook's `projeto` field and list every repo the ticket touched in `projetos`.
