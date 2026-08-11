---
name: ticket
description: Given a ticket URL (Jira, GitHub issue/PR, Bitbucket), pull maximum context from every available connector (Atlassian MCP, bkt CLI, gh CLI, repo docs), then produce a TL;DR, an illustrated description, and an execution plan for approval. Triggers include "ticket", a pasted Jira/GitHub/Bitbucket URL, "/ticket".
metadata:
  short-description: Ticket URL to full context, summary, and execution plan
  compatibility: claude-code
---

# Ticket

Input: a ticket URL passed as the argument. If no URL was given, ask for it and stop.

**Language:** talk to the user in pt-BR (reports, questions, plan). All artifacts are in English: branch names, commit messages, PR titles and bodies, ticket comments.

## 1. Detect the platform

| URL contains | Platform | Tooling |
|---|---|---|
| `atlassian.net/browse`, `/jira/` | Jira | Atlassian MCP tools |
| `github.com/.../issues/`, `/pull/` | GitHub | `gh` CLI |
| `bitbucket.org`, Bitbucket DC host | Bitbucket | `bkt` skill + Atlassian MCP |

If the Atlassian MCP tools are deferred, load them with ToolSearch first. For Bitbucket, load the `bkt` skill.

## 2. Gather context — go wide, in parallel

Fetch everything the connectors can give. Run independent fetches concurrently (parallel tool calls or subagents).

**Jira:**
- The issue itself: description, comments, status, assignee, labels, sprint, fix version.
- Hierarchy: parent task, epic, subtasks. Fetch the parent and epic bodies too, not just their keys.
- Linked issues (blocks, relates to, duplicates) and remote links.
- `getTeamworkGraphContext` on the issue, then `getTeamworkGraphObject` on the key linked entities (goals, projects, docs).
- Confluence: any page linked from the issue, epic, or graph context. Fetch page content, not just titles. If nothing is linked, search Confluence (CQL) for the issue key and the feature name.

**GitHub:**
- `gh issue view` / `gh pr view` with comments (`--comments`).
- Milestone, project, labels, linked issues/PRs (cross-references in the timeline: `gh api` on the issue timeline if needed).
- Referenced commits and PRs; read their diffs if small and relevant.

**Bitbucket:**
- `bkt` for the PR/repo side; Jira flow above for the linked issue.

**Local repo (always, if cwd is the relevant repo):**
- Search the codebase for files, modules, and docs (README, /docs, ADRs) touching the ticket's subject.
- Recent git history on those files.

Do not stop at the first fetch. A ticket body alone is not context; the parent, epic, and linked docs usually carry the real intent.

**Depth cap:** fetch full bodies only for the ticket, its parent, and its epic. For linked issues and epic siblings, fetch title + status only; go deeper only on blockers or when the summary clearly depends on one. Cap Confluence at the 3 most relevant pages.

## 3. Report

Present in this order, in the user's language:

1. **TL;DR** — 2 to 4 sentences: what the task is, why it exists, what done looks like.
2. **Description** — lightly detailed: scope, affected systems, constraints, open questions found in comments/docs. Use visual elements where they clarify:
   - Mermaid flowchart or sequence diagram for flows/architecture.
   - Table for affected components, acceptance criteria, or ticket hierarchy.
   - Only add a diagram when it beats prose; skip decoration.
3. **Context map** — small table of what was fetched (epic, parent, N linked issues, Confluence pages, repo files) with links, so the user sees what informed the summary and what was missing.

## 4. Execution plan and approval

Before drafting the plan, study how the repo already implements similar things: existing modules touching the same area, naming, layering, error handling, test structure, and any conventions in CLAUDE.md/CONTRIBUTING/ADRs. The plan must follow those patterns, not invent new ones.

Draft a step-by-step execution plan (files to touch, order of changes, how to verify). Then STOP and ask for approval before touching any code:

- If plan mode is available, use EnterPlanMode / ExitPlanMode so approval is native.
- Otherwise, present the plan and ask explicitly: approve to execute, or adjust.

Never start implementing without the approval.

## 5. Status transitions

Keep the ticket status in sync with the work:

- **On approval (before implementing):** check `git status` and the current branch first. If not on the base branch (main/master/develop, whatever the repo uses) or the workspace is dirty, ASK before acting (AskUserQuestion): switch to base and pull? stash/commit the dirty changes? or branch from where we are? Never switch branches or discard/stash work silently. Once on the base branch, pull latest. Then create a branch named `<ticket>/<title-with-dashes-lowercase>` (e.g. `PROJ-123/add-export-endpoint`, or `123/add-export-endpoint` for GitHub). Then move the ticket to "In Progress" or the closest equivalent. Jira: `getTransitionsForJiraIssue` to list available transitions, then `transitionJiraIssue` with the best match. GitHub: assign yourself/the user if unassigned; move the project item to "In Progress" if the issue is on a project board (`gh project item-edit`).
- **When implementation is done:** ask if you may open the PR as a draft. Title format is `feat|fix|chore(<ticket>): title` (e.g. `feat(PROJ-123): add export endpoint`). The PR body follows this structure (English; omit a section only if truly empty, e.g. no screenshots for backend-only changes):

  ```markdown
  ## TL;DR
  ## Description
  ## Why
  ## How
  ## Testing
  ## Screenshots and Evidences
  ## Related
  ```

  "Related" lists the ticket, epic, and any linked issues/PRs/docs. For "Screenshots and Evidences", capture real evidence when the change is visible or runnable: web UI via Chrome DevTools MCP (or similar browser tooling), mobile/desktop apps via the `agent-device` skill, CLI/backend via command output or test results. Run the app, exercise the changed flow, and attach the captures. Run the body through the `humanizer` skill, then open as draft (`gh pr create --draft`; Bitbucket: draft via bkt if supported). Link the PR to the ticket (Jira: the issue key is already in the title/branch; GitHub: "Closes #N" in the PR body). Do NOT touch the ticket status yet.
- **After the user reviews the draft and approves:** mark the PR ready (`gh pr ready`) and move the ticket to "In Review" / "Code Review" or the closest equivalent.

If no matching transition exists, say which transitions were available and ask which to use instead of guessing.
