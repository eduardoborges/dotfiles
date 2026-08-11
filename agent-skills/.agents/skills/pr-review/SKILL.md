---
name: pr-review
description: Review a pull request (GitHub or Bitbucket) with full ticket context. Finds only relevant issues, proposes brief and friendly comments for approval, then posts them. Triggers include "pr-review", "review this PR", a pasted PR URL with review intent, "/pr-review".
metadata:
  short-description: Review a PR, propose comments, post after approval
  compatibility: claude-code
---

# PR Review

Input: a PR URL passed as the argument. If no URL was given, ask for it and stop.

**Language:** talk to the user in pt-BR (findings, questions). All posted comments are ALWAYS in English, even when the conversation is in pt-BR.

## 1. Detect the platform

| URL contains | Platform | Tooling |
|---|---|---|
| `github.com/.../pull/` | GitHub | `gh` CLI |
| `bitbucket.org`, Bitbucket DC host | Bitbucket | `bkt` skill |

## 2. Gather context

Same approach as the `ticket` skill: go wide, in parallel, with a depth cap.

- The PR itself: description, diff, existing comments and review threads (don't repeat what a reviewer already said), CI status.
- The linked ticket (from branch name, title, or body): full body of ticket, parent, and epic via Atlassian MCP or `gh`. Linked issues title + status only.
- Linked Confluence/docs pages (cap at 3 most relevant).
- Local repo, if cwd is the relevant repo: the surrounding code of changed files, repo conventions (CLAUDE.md, CONTRIBUTING, ADRs), recent history of the touched files.

The point: judge the diff against what the ticket asked for and how this repo does things, not against generic taste.

## 3. Review

Look for issues that matter:

- Bugs, broken edge cases, race conditions.
- Diff does not match what the ticket asked for (missing scope, silent extra scope).
- Security, data loss, breaking API changes.
- Violations of the repo's own established patterns.
- Missing tests for non-trivial new logic.

**Filter hard.** Drop anything irrelevant: style nits a formatter would catch, subjective preferences, "you could also", restating the diff, comments for the sake of commenting. If the PR is fine, say so and post nothing. A short list of real issues beats a wall of noise.

## 4. Propose to the user

Show every candidate comment in a table, in pt-BR, before posting anything:

| Arquivo:linha | Problema | Comentário sugerido (EN) |
|---|---|---|

Comments are brief, direct, and friendly. No essays, no lecturing, no commit hashes. Run every comment through the `humanizer` skill before showing it. Ask which to post: all, some (pick), or none.

## 5. Post

Post only what the user approved, as inline comments on the right file/line (`gh pr review --comment` with line comments, or the Bitbucket equivalent via `bkt`). If an overall verdict was approved too, post it as the review summary. Never post anything the user did not approve.
