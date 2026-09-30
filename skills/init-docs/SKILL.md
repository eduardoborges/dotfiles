---
name: init-docs
description: Prepare a repo's docs for agents. The code stays the source of truth, and docs keep only what it can't say (decisions, traps, domain terms, asset licenses). Measures what agents load every session, deletes docs that duplicate code, turns prose rules into lint, sets up a two-level memory (index plus Decisions / Traps / Reference per theme, each item linked to its commit), a glossary and asset catalogs. Triggers include "init-docs", "prepare the docs", "enxugar os docs", "delete most of your docs", "/init-docs".
metadata:
  short-description: Docs that only say what the code can't
  compatibility: claude-code
---

# Init docs

Talk to the user in pt-BR. Write docs in the language the repo already uses.

The idea: a markdown layer that explains the code costs tokens and drifts, because nothing tests it. When the doc and the code disagree, the agent doesn't know which one to trust. So the code is the source of truth, and docs keep only what it can't carry:

| Keep | Delete |
|---|---|
| Why a decision was made, and what lost | Maps of routes, folders, commands or versions that exist in code or config |
| Traps: silent failures, non-obvious causes, limits, measured numbers | Descriptions of what the code does |
| Domain terms and the name each one has in code | Rules a linter or type can enforce |
| Origin and license of third-party assets | History of states that were replaced |

Each step ends in its own commit, so any of them can be reverted alone. Don't push without asking.

## 1. Measure

List what an agent loads in every session: `AGENTS.md`, `CLAUDE.md` and every file they import with `@`. Measure their size in bytes and in tokens (bytes / 4 is close enough). Then measure the docs read on demand (`docs/`, READMEs inside apps). Show a table. Keep it: step 8 compares against it.

## 2. Find docs that duplicate the code

Look for:

- Route or URL maps, folder trees, command lists, version pins, env var lists written in prose.
- Comment blocks that copy a config right below them.
- Generated docs committed to the repo (OpenAPI generators write one `.md` per model). They pollute every grep an agent runs.

For each duplicate, prove the drift when you can: diff the doc against the code. A doc that is already wrong makes the case for deleting it. Delete it, and leave one line pointing to the file that is the source. For generated docs, turn them off in the generator config and regenerate. Check that no code file changed.

## 3. Turn prose rules into tooling

Find rules written as "never", "always", "mandatory" in the agent files. For each one, ask whether a lint rule, a type or a test can enforce it (`no-restricted-imports`, `no-restricted-syntax`, a custom rule).

Before adding a rule, count the current violations:

- Zero or a few real ones: add the rule, fix what breaks, and prove it fires with a throwaway file that breaks it.
- Many, and most are legitimate: skip the rule and say why. A rule that needs a disable on every other line is noise.

Once a rule is enforced, shorten its prose in the agent file to one line saying the lint covers it.

## 4. Trim the agent file

Run the `init` skill's discoverability filter over `AGENTS.md` / `CLAUDE.md`. What survives is what the repo can't tell: production constraints, workflows, landmines, and pointers to the files below.

## 5. Memory in two levels

Agents need decisions and traps, and those don't fit in code. But a single memory file grows until it eats the context window. Use two levels:

- `docs/MEMORY.md`: only the index, one row per theme with a summary good enough to decide whether to open the file. The agent file imports it with `@`. It changes only when a theme is born or a summary stops describing its file.
- `docs/memory/<theme>.md`: the content, read on demand.

Each theme file has this shape:

```markdown
# <Theme>

<one or two lines on what the file covers>

## Decisions

### <decision in a few words> (YYYY-MM)
[abc1234](https://github.com/<owner>/<repo>/commit/abc1234)

**Decision:** what was chosen. **Why:** the reason. **Dropped:** the real alternative and why it lost, only when there was one.

## Traps

### <short symptom>
[abc1234](https://github.com/<owner>/<repo>/commit/abc1234)

One paragraph: symptom, cause, and what to do or where the fix lives.

## Reference

Only when the theme needs it: runbooks, ids, commands.
```

The commit link points to the commit that made the decision or fixed the trap. Find it with `git log --oneline --grep=<term>` or `git log --oneline -S<symbol> -- <path>`. If you can't find it, leave the item without a link. Never guess a hash, and check each one with `git cat-file -e <hash>^{commit}` before committing.

When a decision changes, rewrite the item with the current state instead of stacking a new one under it. The file describes the present, and git keeps the history. Write this rule, and the format above, into the agent file's memory section so future entries follow it.

### Compacting an existing memory

If the repo already has memory written as a diary, compact it into this format. What stays and what goes:

- Stays: the why, the dropped alternative, silent failures, measured numbers, ids, upstream issue and PR links, and whatever is crooked on purpose, with the reason.
- Goes: how it was discovered (unless that changes what the next person does), implementation step by step, lists of files created, old states that were replaced (unless they still bite, like old clients hitting the API or data already in production), and anything the agent file already says.
- Before keeping an entry that names a file, function or component, grep for it. If it's gone, fix the reference or drop the entry.
- When in doubt, keep it in one line. Never invent facts.

Expect 40 to 60% of the original size. A file that is already dense may barely shrink.

With many theme files, compact them in parallel: one subagent per group of files, balanced by size. Subagents only edit their files: no git, no files outside their group, except fixing links to anchors they renamed. You review each file (size, dashes if the user bans them, hashes, links), commit one theme per commit, and update the index rows whose summary went stale.

## 6. Glossary

If the repo has a `CONTEXT.md` (the `domain-modeling` skill's format), the glossary goes there. Otherwise create `docs/GLOSSARY.md` (in the repo's language).

Build it from the data model: the schema's models and enums, with their doc comments, and the shared validation schemas. One table per area:

| In the UI | In the code | What it is |
|---|---|---|

Check every row against the code. When the same word means two things (a "series" that is a workout set and also a recurring booking), say so in the row, and pick a distinct UI term for one of them. Business rules stay in code. The glossary only ties names to the place where they live.

## 7. Asset catalogs

Binary assets the code can't describe need a catalog: third-party audio, music, 3D models, fonts, stock photos and videos. One table per kind, next to the assets or in `docs/`:

| File | Origin | License | Size or duration | Used in |
|---|---|---|---|---|

Check the catalog against the disk both ways: every file in the table exists, and every file on disk is in the table. Measure the durations and sizes; don't copy them from old notes. Find where each asset is used with grep. Mark the license as unconfirmed when nobody recorded it, and call it out: an asset without a license shouldn't go into anything published.

## 8. Wire it up

The agent file points to the glossary, the memory index and the catalogs, one line each. Nothing else is repeated there.

Finish with the table from step 1 filled in with the after numbers, the list of commits, and what was left open (rules skipped and why, unconfirmed licenses, entries the user may want to review).
