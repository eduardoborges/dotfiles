# Dotfiles

Personal macOS dotfiles. Everything in `$HOME` is a symlink into this repo, made by GNU Stow with `--no-folding`, so each file is linked on its own instead of a whole directory.

English for anything that lands in the repo: commit messages, docs, comments, code. We talk in pt-BR.

## Layout

| Path | What it is |
|---|---|
| `<package>/` | One stow package per tool, mirroring its path under `$HOME`, as in `ghostty/.config/ghostty/config` |
| `lib/packages.sh` | The list of packages `install.sh` stows |
| `docs/` | Ghostty, herdr and the macOS window manager setup, including who owns which shortcut |
| `skills/` | Agent skills. Not a stow package: it is linked whole into `~/.claude/skills` and `~/.agents/skills` |
| `skills-lock.json` | The skills that come from someone else's repo |
| `mcp-servers.json` | The user-scoped MCP servers, merged into `~/.claude.json` by `lib/mcp.sh` |

`./install.sh` stows everything and takes `--unstow <pkg>`, `--restore`, `--list-backups`, `--save-extensions`, `--save-brewfile`, `--save-mcp` and `--diagnose`. Files it would overwrite go to `~/.dotfiles-backup-<timestamp>` first.

## Traps

`agent-instructions/.agents/AGENTS.md` is the only real file in that package. `.claude/CLAUDE.md` and `.codex/AGENTS.md` are symlinks to it, so edit the AGENTS.md path.

There are two kinds of borrowed skills in `skills/`. The ones in `skills-lock.json` (Lightpanda, agent-device, figma-build, figma-codegen, goldie, i-have-adhd, show-me) are managed by the `skills` CLI, and an update overwrites local edits. The ones below were installed globally, which the CLI records nowhere, so this table is the only place their origin lives:

| Source | Skills |
|---|---|
| `mcollina/skills` | documentation, fastify-best-practices, init, linting-neostandard-eslint9, node, nodejs-core, oauth, octocat, skill-optimizer, snipgrapher, typescript-magician |
| `rorkai/app-store-connect-cli-skills` | asc-* (25 skills) |

Update one of those with `npx skills add mcollina/skills@<skill> -g -y`. The command prints a PromptScript failure at the end and the files land in `skills/` anyway. Everything else in `skills/` is ours.

Claude Code rewrites `claude/.claude/settings.json` on its own, and that write sometimes replaces the symlink with a plain file. When the repo copy falls behind: copy the live file over the repo one, delete `~/.claude/settings.json`, then stow the `claude` package again.

The hook commands in that file use absolute paths on purpose. `$HOME` there broke Claude Status Bar and the herdr rename. The scripts they call live in `~/.claude/statusbar` and `~/.claude/hooks`, installed by those apps and not tracked here.
