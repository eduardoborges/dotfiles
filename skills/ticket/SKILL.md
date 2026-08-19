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

**Session title:** as soon as the ticket is identified, set the terminal/session title to `{TICKET-ID} - {Title}` (e.g. `PROJ-123 - Add export endpoint`): `printf '\033]0;PROJ-123 - Add export endpoint\007'`.

**Humanizer gate:** NOTHING leaves this skill as posted text without passing through the `humanizer` skill first. Commit messages, PR title, PR body, ticket comments, review replies — invoke `humanizer` on the drafted text BEFORE the command that posts it, every time. If you are about to run `git commit`, `gh pr create`, `gh api`, or a bkt/Jira write and the text did not go through humanizer, stop and run it.

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
   - Diagrams for flows/architecture in plain ASCII (boxes with `┌─┐│└┘`, arrows with `-->`), inside a code fence. NEVER Mermaid in terminal output — the CLI does not render it, it prints as raw text. Mermaid is allowed only inside a PR body posted to GitHub/Bitbucket, where the web UI renders it.
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

- **On approval (before implementing):** work in a git worktree, never in the user's checkout — other agents may be working there in parallel. `git fetch origin` first, then create the worktree from the base branch (main/master/develop, whatever the repo uses) with the branch named `<ticket>/<title-with-dashes-lowercase>` (e.g. `PROJ-123/add-export-endpoint`, or `123/add-export-endpoint` for GitHub). Use the harness's EnterWorktree tool if available; otherwise `git worktree add <path> -b <branch> origin/<base>`. If the user explicitly asks to work in the current checkout instead, only then apply the old rules: ask before switching branches or touching a dirty workspace. Then move the ticket to "In Progress" or the closest equivalent. Jira: `getTransitionsForJiraIssue` to list available transitions, then `transitionJiraIssue` with the best match. GitHub: assign yourself/the user if unassigned; move the project item to "In Progress" if the issue is on a project board (`gh project item-edit`).
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

  "Related" lists the ticket, epic, and any linked issues/PRs/docs. For "Screenshots and Evidences", capture real evidence when the change is visible or runnable: web UI via Chrome DevTools MCP (or similar browser tooling), mobile/desktop apps via the `agent-device` skill, CLI/backend via command output or test results. Run the app, exercise the changed flow, and attach the captures. Run the title and body through the `humanizer` skill, then open as draft (`gh pr create --draft`; Bitbucket: draft via bkt if supported). Link the PR to the ticket (Jira: the issue key is already in the title/branch; GitHub: "Closes #N" in the PR body). Do NOT touch the ticket status yet.
- **After the user reviews the draft and approves:** mark the PR ready (`gh pr ready`), add the repo's default reviewers (GitHub: CODEOWNERS or the team's usual reviewers, `gh pr edit --add-reviewer`; Bitbucket: default reviewers are usually auto-added, verify via bkt), and move the ticket to "In Review" / "Code Review" or the closest equivalent. If no default reviewers can be determined, ask who to add.

If no matching transition exists, say which transitions were available and ask which to use instead of guessing.

## 6. Review comments

When the user reports new comments on the PR, fetch them and for each one:

1. Judge if it is valid. If not, say why to the user before pushing back on the reviewer.
2. If valid, apply the fix and push.
3. Reply to the comment: brief, direct, and warm (e.g. "Good catch, fixed!"). No commit hashes or references. Run replies through the `humanizer` skill. No essays, no over-explaining.
