---
name: worktree-gc
description: Find stale git worktrees (branch merged or deleted on the remote) and propose removing them, worktree and local branch. Triggers include "worktree-gc", "clean worktrees", "limpar worktrees", "/worktree-gc".
metadata:
  short-description: Remove worktrees whose branch is merged or gone
  compatibility: claude-code
---

# Worktree GC

Run in the current repo. Talk to the user in pt-BR.

## 1. Detect stale worktrees

```bash
git fetch --prune origin
git worktree list --porcelain
```

For each linked worktree (skip the main checkout), the branch is stale when any of:

- Deleted on the remote: upstream is gone (`git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads` shows `[gone]`).
- Merged into the base branch: `git branch --merged origin/<base>` contains it, or `gh pr view <branch> --json state` says MERGED.

Also flag, separately, worktrees with uncommitted changes or unpushed commits — these are NEVER auto-removed.

## 2. Propose

```markdown
## Worktrees

| Worktree | Branch | Estado | Ação proposta |
|---|---|---|---|
| PROJ-123-export | PROJ-123/... | PR merged | remover |
| PROJ-200-fix | PROJ-200/... | mudanças não commitadas | manter (avisar) |
```

Ask which to remove (AskUserQuestion, multiSelect). Default recommendation: all the merged/gone ones with clean trees.

## 3. Remove

For each approved worktree:

```bash
git worktree remove <path>
git branch -d <branch>
```

Use `-d`, not `-D`; if `-d` refuses, the branch is not fully merged — report it instead of forcing. Never remove a worktree with uncommitted or unpushed work, even if asked in bulk; call it out individually first.
