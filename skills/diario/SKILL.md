---
name: diario
description: Log the current session to the Obsidian journal. Keeps the day's task list current and tags decisions, results, important facts and blockers under their project and ticket. Triggers include "diario", "diário", "log this", "registra no diário", "/diario".
---

# Diário

Talk to the user in pt-BR and write the entries in pt-BR.

## 1. Context

Run `~/.claude/hooks/journal.sh ctx "$PWD"`. It creates any missing notes and prints `escopo`, `projeto`, `ticket`, `branch`, `repo` and `nota` (today's note). Work and personal notes never mix, so write only to that `nota`.

If the session also touched another repo, run `ctx` for it and log that part in its own note.

## 2. Tasks

Today's note starts with `## Tarefas`, a checklist of my work with one task per line:

```markdown
- [ ] [[<projeto>]] [[<ticket>]] <the task in a few words>
- [x] [[<projeto>]] [[<ticket>]] <the task> ✅ HH:MM
```

A task is a piece of work I'd mention in a standup: implementing an endpoint, reviewing a PR, fixing a bug, answering review comments. The steps inside it, like running tests or reading a file, are not tasks.

Update the list from the session. Add the tasks that started, check off the finished ones with the time, and reword a task whose scope changed. Edit lines in place and never duplicate one. You don't need to carry open tasks to the next day: the hook copies them into the new note.

## 3. Classify

Keep only what is worth rereading a month from now:

| Tag | What goes there |
|---|---|
| `#decisao` | The choice, why, and the alternative you dropped |
| `#resultado` | Something delivered or confirmed working: PR merged, fix verified, tests green |
| `#importante` | A fact that will bite later: a trap, a limit, a contact, an environment detail |
| `#bloqueio` | What is stuck and who it waits on |

Leave out the step by step, the commands you ran and anything the commit messages already say. One line per entry.

## 4. Write

Append the entries to the end of `nota`, under `## Registro`:

```markdown
- HH:MM [[<projeto>]] [[<ticket>]]
  - #decisao ...
  - #resultado ...
```

Drop `[[<ticket>]]` when there is none. Wrap other tickets and projects that came up in `[[...]]` as well. If no task changed and nothing qualifies, tell the user and write nothing. Otherwise show them what you wrote.
