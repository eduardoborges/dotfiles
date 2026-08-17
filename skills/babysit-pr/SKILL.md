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

**Humanizer gate:** every commit message and comment reply MUST pass through the `humanizer` skill before the command that posts it. No exceptions.

This skill does ONE pass. To keep watching, run it under a loop, e.g. `/loop 10m /babysit-pr <url>`. Suggest that to the user if they invoked it bare and want continuous watching.

## The pass

1. **CI:** `gh pr checks` (or `bkt` equivalent). If a check failed, fetch the log, diagnose, fix in a worktree (same rules as the `ticket` skill: fetch first, fresh worktree on the PR branch, never the user's checkout), push the fix.
2. **New review comments:** anything unresolved and not yet replied. Handle exactly as the `ticket` skill's "Review comments" step: judge validity, apply valid fixes, push, reply brief/direct/warm through `humanizer`, no commit hashes. If a comment is invalid or a big scope change, do NOT act; flag it for the user.
3. **State changes:** PR approved, merged, or changes requested — report it.

## Guardrails

- Small, obvious fixes only (lint, broken test, valid review nit). Anything structural: report and wait for the user.
- Never force-push, never rebase, never resolve someone else's thread.
- If nothing changed since the last pass, say "sem novidades" in one line and stop — no padded report.
