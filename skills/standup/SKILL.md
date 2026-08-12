---
name: standup
description: Morning briefing pulled from every connector, Jira tickets in progress, open PRs and their CI, review comments waiting for a reply. Triggers include "standup", "briefing", "what's on my plate", "/standup".
metadata:
  short-description: Daily briefing from Jira, GitHub, and Bitbucket
  compatibility: claude-code
---

# Standup

No input needed. Talk to the user in pt-BR.

## 1. Gather, in parallel

Use whatever connectors are available; skip silently what is not connected.

- **Jira** (Atlassian MCP): `searchJiraIssuesUsingJql` for issues assigned to the current user (`assignee = currentUser()`) that are In Progress, In Review, or Blocked. Title + status + last update only; no deep fetches.
- **GitHub** (`gh`): open PRs authored by the user (`gh search prs --author=@me --state=open`), plus PRs where their review is requested. For each: CI status and unresolved review threads.
- **Bitbucket** (`bkt`, if configured): same two lists, authored PRs and PRs awaiting their review.

Depth cap: this is a briefing, not an investigation. Lists and statuses only. Never fetch epic bodies, Confluence pages, or diffs here.

## 2. Report

Structured, short, pt-BR:

```markdown
# Standup <data>

## Precisa de você agora
<coisas bloqueando outros: reviews pedidos, comentários sem resposta, CI quebrado>

## Em andamento
| Ticket/PR | Status | Última atividade |
|---|---|---|

## Parado / suspeito
<tickets in progress sem atividade há dias, PRs abertos há muito tempo>
```

Lead with what needs action. If a PR has new comments, offer to handle them via the `ticket` skill's review-comments flow. If everything is quiet, say so in one line, do not pad the report.
