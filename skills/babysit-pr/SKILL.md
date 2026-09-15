---
name: babysit-pr
description: One watch pass over an open PR, check CI and new review comments, fix what is valid, reply warmly, report. Designed to run repeatedly via /loop. Triggers include "babysit-pr", "babysit", "watch this PR", "/babysit-pr".
metadata:
  short-description: Watch a PR, fix CI and answer review comments
  compatibility: claude-code
---

# Babysit PR

Input: a PR URL. If missing, use the PR of the current branch (`gh pr view`); if none, ask and stop.

Talk to the user in pt-BR. Everything posted (comments, commits) in English.

**Humanizer gate (never skip):** every commit message and comment reply MUST come out of a fresh call to the `humanizer` skill (Skill tool, `humanizer`) before you show it to the user or run the command that posts it. A call from an earlier pass or session does not count, and neither does applying its rules from memory. No exceptions.

This skill does ONE pass. To keep watching, run it under a loop: `/loop 45m /babysit-pr <url>`. If the user invoked it bare and wants continuous watching, start that loop yourself with the 45m interval instead of only suggesting it.

## The pass

1. **CI:** `gh pr checks` (or `bkt` equivalent). If a check failed, fetch the log, diagnose, fix in a worktree (same rules as the `ticket` skill: fetch first, fresh worktree on the PR branch, never the user's checkout), push the fix.
2. **New review comments:** anything unresolved and not yet replied. Handle exactly as the `ticket` skill's "Review comments" step: judge validity, apply valid fixes, push, draft brief/direct/warm replies through `humanizer`, no commit hashes. Show the drafted replies together and post only the ones the user approves. Under `/loop` the pass waits for that answer; never skip the question to keep the loop moving. If a comment is invalid or a big scope change, do NOT act; flag it for the user.
3. **State changes:** PR approved, merged, or changes requested — report it.

## Guardrails

- Small, obvious fixes only (lint, broken test, valid review nit). Anything structural: report and wait for the user.
- Never force-push, never rebase, never resolve someone else's thread.
- If nothing changed since the last pass, say "sem novidades" in one line and stop — no padded report.
