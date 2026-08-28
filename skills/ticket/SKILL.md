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

## 2. Gather context, in order, in your own context

Read everything yourself, in the main conversation, one layer at a time. Subagents may locate and filter; they never read for you. "Which Confluence pages mention these terms" or "which files reference this endpoint" is a subagent job: the answer is a shortlist, and you then read the items on it here. "Read the epic and summarize it" is not: the summary keeps what the subagent found interesting, not what the plan will need, and the comment saying "do not touch X" is exactly the kind of thing that gets dropped. Parallel tool calls inside one turn are fine when the fetches do not depend on each other.

Every shell read goes through `rtk`: `rtk git log`, `rtk git diff`, `rtk rg`, `rtk grep`, `rtk read`, `rtk find`, `rtk tree`, `rtk gh`. The hook rewrites most calls on its own, but type it explicitly anyway. The tokens it saves are what let you read the whole picture before the context fills up.

Each layer tells you what to look for in the next one, so keep the order.

1. **The ticket.** Description, every comment, status, assignee, labels, sprint, fix version. Jira: the issue via MCP. GitHub: `rtk gh issue view --comments` or `rtk gh pr view --comments`. Bitbucket: `bkt` for the PR side, Jira flow for the issue. Write down the nouns the ticket uses (feature names, entities, endpoints); they are your search terms for the layers below.
2. **Hierarchy.** Parent and epic, full bodies, not just keys. Subtasks by title and status. The parent and epic usually carry the reason the ticket exists.
3. **Links.** Linked issues (blocks, relates to, duplicates), remote links, referenced PRs and commits. Jira: `getTeamworkGraphContext` on the issue, then `getTeamworkGraphObject` on the entities that matter (goals, projects, docs). GitHub: milestone, project, cross references in the timeline (`rtk gh api` on the timeline if the view does not show them). Read the diff of a referenced PR when it is small and touches the same area.
4. **Docs.** Confluence pages linked from the ticket, epic, or graph context: fetch the content, not the title. If nothing is linked, search Confluence (CQL) for the issue key and for the nouns from step 1. Same for repo docs: README, `/docs`, ADRs, CLAUDE.md, CONTRIBUTING.
5. **The code.** With the vocabulary from steps 1 to 4, `rtk rg` the repo for those terms, then read the files that will change. Read them, do not just list them. `rtk git log` on those files to see who touched them recently and why.
6. **Similar work.** Find the closest thing the repo already does (same layer, same kind of change, same external system) and read it: module layout, naming, error handling, how it is tested. The plan follows that pattern. A plan that invents a new pattern where one already exists is wrong.

Depth cap: full bodies for the ticket, parent, and epic. Title and status only for linked issues and epic siblings, unless one is a blocker or the summary clearly hinges on it. At most 3 Confluence pages.

### Context gate

Before writing the report, answer these for yourself:

- Why does this ticket exist? The business reason, not the title.
- What does "done" look like in terms someone could test?
- Which files will change, and have I read them (not just found them)?
- How does the repo already solve something like this?
- Is there a comment, doc, or linked issue I skimmed instead of reading?

Any answer you cannot give from the sources becomes an open question for the user in the report. It does not become a guess. No code, no branch, no worktree until every answer is in hand or explicitly flagged as unknown.

## 3. Report

Present in this order, in the user's language:

1. **TL;DR** — 2 to 4 sentences: what the task is, why it exists, what done looks like.
2. **Description** — lightly detailed: scope, affected systems, constraints, open questions found in comments/docs. Use visual elements where they clarify:
   - Diagrams for flows/architecture in plain ASCII (boxes with `┌─┐│└┘`, arrows with `-->`), inside a code fence. NEVER Mermaid in terminal output — the CLI does not render it, it prints as raw text. Mermaid is allowed only inside a PR body posted to GitHub/Bitbucket, where the web UI renders it.
   - Table for affected components, acceptance criteria, or ticket hierarchy.
   - Only add a diagram when it beats prose; skip decoration.
3. **Context map** — small table of what was fetched (epic, parent, N linked issues, Confluence pages, repo files) with links, so the user sees what informed the summary and what was missing.

## 4. Execution plan and approval

The plan is a document the user reads top to bottom, not a list of tool calls. Write it in this shape, in pt-BR:

```markdown
## Plano: TICKET-123 Título

### Objetivo
One short paragraph: what changes for the user and why. If step 6 of the context
gathering found a pattern to follow, name it here ("segue o mesmo desenho de X").

### Hoje vs depois
ASCII diagram of the flow as it is now, then the flow after the change. Two
diagrams, or one with the new pieces marked. Boxes with ┌─┐│└┘, arrows with
-->, every box and arrow labeled. Show the flow of data or calls, never a file
tree. Inside a code fence, never Mermaid.

### Passos
| # | Arquivo | Mudança | Por quê |
|---|---|---|---|
One row per file, in the order the changes land. "Por quê" ties the row back to
the ticket or to the pattern being followed.

### Verificação
How each step is checked: the test to write or run, the command, what output
means it worked. AWS pieces run through floci.

### Riscos e perguntas abertas
What could break, what is still unknown, what needs the user's call.
```

Skip the diagram only when the change does not touch any flow (a copy change, a config flip) and say why. A diagram that only repeats the steps table is decoration; cut it.

Then STOP and ask for approval before touching any code:

- If plan mode is available, use EnterPlanMode / ExitPlanMode so approval is native.
- Otherwise, present the plan and ask explicitly: approve to execute, or adjust.

Never start implementing without the approval.

**AWS:** anything that touches AWS (Lambda, S3, SQS, DynamoDB, and friends) is tested locally with the `floci` skill. Load it before writing the verification steps, never against a real account.

## 5. Status transitions

Keep the ticket status in sync with the work:

- **On approval (before implementing):** work in a git worktree, never in the user's checkout — other agents may be working there in parallel. `git fetch origin` first, then create the worktree from the base branch (main/master/develop, whatever the repo uses) with the branch named `<ticket>/<title-with-dashes-lowercase>` (e.g. `PROJ-123/add-export-endpoint`, or `123/add-export-endpoint` for GitHub). Use the harness's EnterWorktree tool if available; otherwise `git worktree add <path> -b <branch> origin/<base>`. If the user explicitly asks to work in the current checkout instead, only then apply the old rules: ask before switching branches or touching a dirty workspace. Then, without asking:
  - Assign the ticket to the user. Jira: `atlassianUserInfo` for the accountId, then `editJiraIssue` with that assignee. GitHub: `gh issue edit <N> --add-assignee @me`.
  - Move it to "In Progress" or the closest equivalent. Jira: `getTransitionsForJiraIssue`, then `transitionJiraIssue` with the best match. GitHub: move the project item with `gh project item-edit` if the issue is on a board.
- **When implementation is done:** open the PR as a draft right away, never ask permission. Title: `feat|fix|chore(<ticket>): title`. Body in English, sections below. TL;DR is always there; drop any other section that would be empty. Run title and body through `humanizer` first. `gh pr create --draft`, Bitbucket `bkt pr create --draft`. Link it to the ticket (Jira: the key is already in title and branch; GitHub: "Closes #N"). Leave the ticket status alone.

  ```markdown
  ## TL;DR
  ## What changed
  ## Technical notes
  ## Testing
  ## Screenshots and Evidences
  ## Related
  ```

  Write it from the product side: what the user gets, not how the code does it. The diff already shows the code.

  - **TL;DR:** one or two sentences, never omitted.
  - **What changed:** what is being delivered and what behaviour is different now. Short bullets.
  - **Technical notes:** only decisions a reviewer could not guess from the diff (a tradeoff, a migration, a dependency, a known limitation). Nothing to say, cut the section.
  - **Testing:** how it was verified. AWS pieces run locally through `floci`.
  - **Screenshots and Evidences:** capture real evidence — web UI via Chrome DevTools MCP, mobile/desktop via the `agent-device` skill, CLI/backend via command output or test results. The CLIs cannot upload images, so when the evidence is visual, put `> TODO: upload images` in that section and tell the user to attach the captures in the PR.
  - **Related:** ticket, epic, linked issues/PRs/docs.

  Never in the body: file lists, function or variable names, code snippets, a walkthrough of the diff, or padding sentences that restate the title.
- **After the user reviews the draft and approves:** mark the PR ready (`gh pr ready`, Bitbucket `bkt pr publish`), add the repo's default reviewers (GitHub: CODEOWNERS or the team's usual reviewers, `gh pr edit --add-reviewer`; Bitbucket: default reviewers are usually auto-added, verify via bkt), and move the ticket to "In Review" / "Code Review" or the closest equivalent. If no default reviewers can be determined, ask who to add.

If no matching transition exists, say which transitions were available and ask which to use instead of guessing.

## 6. Updates and review comments

When the user asks how the ticket or PR is doing, or reports new comments, do both checks below in the same pass and report them together.

**Conflicts with the base branch.** `rtk git fetch origin` first. GitHub: `rtk gh pr view --json mergeable,mergeStateStatus`; `CONFLICTING` means there are conflicts. Anywhere else: `git merge-tree --write-tree origin/<base> HEAD`, a non-zero exit means conflicts. If there are any, rebase the branch onto the base inside the worktree, resolve them (the `resolving-merge-conflicts` skill if available), run the tests, and push with `--force-with-lease`. Tell the user which files conflicted and what you kept from each side.

**Review comments.** Fetch them and for each one:

1. Judge if it is valid. If not, say why to the user before pushing back on the reviewer.
2. If valid, apply the fix and push.
3. Reply to the comment: brief, direct, and warm (e.g. "Good catch, fixed!"). No commit hashes or references. Run replies through the `humanizer` skill. No essays, no over-explaining.
