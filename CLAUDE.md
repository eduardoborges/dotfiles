# Dotfiles

Personal macOS dotfiles. Everything in `$HOME` is a symlink into this repo, made by GNU Stow with `--no-folding`, so each file is linked on its own instead of a whole directory.

English for anything that lands in the repo: commit messages, docs, comments, code. We talk in pt-BR.

## Layout

| Path | What it is |
|---|---|
| `<package>/` | One stow package per tool, mirroring its path under `$HOME`, as in `ghostty/.config/ghostty/config` |
| `lib/packages.sh` | The list of packages `install.sh` stows |
| `docs/` | Ghostty, herdr, Rex and the macOS window manager setup, including who owns which shortcut |
| `skills/` | Agent skills. Not a stow package: it is linked whole into `~/.claude/skills` |
| `skills-lock.json` | The skills that come from someone else's repo |
| `mcp-servers.json` | The user-scoped MCP servers, merged into `~/.claude.json` by `lib/mcp.sh` |

`./install.sh` stows everything and takes `--unstow <pkg>`, `--restore`, `--list-backups`, `--save-extensions`, `--save-brewfile`, `--save-mcp` and `--diagnose`. Files it would overwrite go to `~/.dotfiles-backup-<timestamp>` first.

## Traps

There are two kinds of borrowed skills in `skills/`. The ones in `skills-lock.json` (agent-device, image and video from `smixs/visual-skills`, and ten from `elevenlabs/skills`) are managed by the `skills` CLI, and an update overwrites local edits. The ones below were installed globally, which the CLI records nowhere, so this table is the only place their origin lives:

| Source | Skills |
|---|---|
| `mcollina/skills` | init, node, nodejs-core, typescript-magician |
| `rorkai/app-store-connect-cli-skills` | asc-* (25 skills) |
| `mattpocock/skills` | code-review, domain-modeling, grill-me, grill-with-docs, grilling |
| `Tejashmakwana/motionmaxxing` | motionmaxxing |
| `cloudflare/security-audit-skill` | security-audit |

Update one of those with `npx skills add <source>@<skill> -g -a claude-code --copy -y`, or just `<source>` when the repo holds a single skill. The command prints a PromptScript failure at the end and the files land in `skills/` anyway. Everything else in `skills/` is ours. That includes `show-me` and `i-have-adhd`, which we took out of the lock to edit. `show-me` came from `humanlayer/skills` and renders Mermaid as text. `i-have-adhd` came from `ayghri/i-have-adhd`, and the model can invoke it without the slash command. Don't reinstall either from there. `skills/init-docs` is a symlink to the public repo `eduardoborges/lean-docs`, which has to be cloned at `~/Projects/lean-docs`: edit the skill there and push from there.

`npx skills update` reinstalls as symlinks, not copies: global skills point into `~/.agents/skills`, project ones into a new `.agents/skills` at the repo root, with a `.claude/skills` beside it. After an update, copy each linked skill over its symlink, then delete `.agents/` and `.claude/skills/` from the repo. `skills/init-docs` is the only symlink that belongs there.

Claude Code rewrites `claude/.claude/settings.json` on its own, and that write sometimes replaces the symlink with a plain file. When the repo copy falls behind: copy the live file over the repo one, delete `~/.claude/settings.json`, then stow the `claude` package again.

The hook commands in that file use absolute paths on purpose. `$HOME` there broke the herdr rename. herdr installs its own script in `~/.claude/hooks`, and that one is not tracked here.
