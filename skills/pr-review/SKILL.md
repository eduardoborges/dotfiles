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
- If you need the PR's code checked out (to run tests or navigate it), never use the user's checkout — other agents may be working there in parallel. `git fetch origin` first, then check out the PR's head branch in a fresh worktree: `git worktree add <path> origin/<pr-branch>` (or EnterWorktree + `gh pr checkout` inside it). A fresh worktree from the fetched ref is guaranteed clean and in sync with the remote.

The point: judge the diff against what the ticket asked for and how this repo does things, not against generic taste.

## 3. Run it before judging it

Before reviewing the code, verify it works — when possible/applicable:

- Check out the PR branch in the worktree (as above) and run the repo's checks: tests, lint, typecheck, build (whatever the repo defines).
- If the change is runnable (UI, endpoint, CLI), start the app and exercise the changed flow (Chrome DevTools MCP for web, `agent-device` for apps, direct commands for CLI).
- Skip what does not apply (docs-only PR, no local env, missing secrets) and say so in the report instead of pretending it ran.

Failures found here are review findings, usually the highest-severity ones.

## 4. Review

Look for issues that matter:

- Bugs, broken edge cases, race conditions.
- Diff does not match what the ticket asked for (missing scope, silent extra scope).
- Security, data loss, breaking API changes.
- Violations of the repo's own established patterns.
- Missing tests for non-trivial new logic.

**Filter hard.** Drop anything irrelevant: style nits a formatter would catch, subjective preferences, "you could also", restating the diff, comments for the sake of commenting. If the PR is fine, say so and post nothing. A short list of real issues beats a wall of noise.

## 5. Propose to the user

Present a structured report in pt-BR before posting anything. Format:

```markdown
# Review: <PR title>

| | |
|---|---|
| PR | <link> |
| Ticket | <key + link> |
| CI | <status> |
| Veredito proposto | REQUEST_CHANGES ou COMMENT |

## Resumo
<2-3 frases: o que o PR faz e o estado geral.>

## Issues

### 1. <título curto do problema>
**Onde:** `arquivo:linha` · **Severidade:** alta/média/baixa

<explicação do problema e por que importa, 2-4 frases>

**Comentário sugerido (EN):**
> <o comentário como será postado>

### 2. ...

## Descartados
| O que | Por que não vale comentário |
|---|---|
```

The "Descartados" table shows what you chose NOT to comment on (nits, subjective stuff), so the user sees the filtering happened. Keep it short.

Comments are brief, direct, and friendly. No essays, no lecturing, no commit hashes. Run every comment through the `humanizer` skill before showing it. Ask which to post: all, some (pick), or none.

## 6. Post

Post only what the user approved. Never post anything the user did not approve.

Submit everything as ONE review, not N loose comments (one notification for the author, not a flood). On GitHub, `gh pr review --comment` cannot do inline comments; use the reviews API with the comments array:

```bash
gh api repos/{owner}/{repo}/pulls/{n}/reviews \
  -f event=REQUEST_CHANGES \
  -f body="<summary>" \
  --input - <<< '{"comments":[{"path":"src/x.ts","line":42,"body":"..."}]}'
```

(Build the full JSON payload with event, body, and comments together. Bitbucket: equivalent via `bkt` or its API.)

Pick the event by severity of the approved findings:

- Any real issue (bug, security, wrong scope, broken pattern) → `REQUEST_CHANGES`.
- Only minor/unimportant details → `COMMENT`.
