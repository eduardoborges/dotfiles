# Dotfiles

My daily configs for zsh, starship, yabai, skhd, JankyBorders, Alacritty, Ghostty, herdr, tmux, VS Code, and agent skills.

**macOS only.** `yabai` and `skhd` handle tiling and hotkeys, and the Brewfile tracks everything installed through Homebrew.

Everything is symlinked into your home via [GNU Stow](https://www.gnu.org/software/stow/).

## Docs

- [Ghostty](docs/ghostty.md): terminal config and every shortcut it keeps or hands to herdr.
- [herdr](docs/herdr.md): multiplexer shortcuts for tabs, panes, and workspaces, plus who owns the number row.
- [macOS window management](docs/macos-window-management.md): yabai and skhd shortcuts, Spaces, and troubleshooting.

## Install

The installer bootstraps Homebrew when necessary and installs the tracked
formulas and applications from [`Brewfile`](Brewfile), `stow` included. Then:

```bash
./install.sh
```

The script will ask if you want to back up your current configs first (recommended). After that it unstows any existing links, sets up the symlinks, and installs editor extensions from `extensions/vscode.txt` into VS Code.

The Brewfile restores the command-line tools and desktop apps,
including VS Code, Ghostty, Chrome, Docker, yabai, and skhd. The
installer then starts the window-manager launchd services and configures
VS Code as the default text/code editor. Grant yabai and skhd access
in **System Settings → Privacy & Security → Accessibility**.

Imperative macOS defaults live in `system/macos/apply-defaults.sh`. The normal
installer runs it automatically, and you can re-apply those settings directly:

```bash
./system/macos/apply-defaults.sh
```

## Homebrew inventory

All explicitly installed formulas, casks, and taps are tracked in `Brewfile`.
To refresh it after installing or removing software:

```bash
./install.sh --save-brewfile
```

The normal installation command runs:

```bash
brew bundle install --no-upgrade --file=./Brewfile
```

It installs missing items without upgrading existing packages and does not
remove unrelated software.

The tracked yabai setup provides BSP tiling, directional focus and movement, resizing, dynamic Spaces, stacking, sticky/PiP windows, scratchpads, opacity, animations, layers, and layout controls. Its advanced profile uses yabai's scripting addition when System Integrity Protection is partially disabled.

See [docs/macos-window-management.md](docs/macos-window-management.md) for the complete shortcut reference and troubleshooting commands. The number row is shared with herdr; [docs/herdr.md](docs/herdr.md) has the split.

## MCP servers

The user-scoped servers are tracked in `mcp-servers.json`. Claude Code keeps
them in `~/.claude.json`, which also holds session history and OAuth tokens, so
that file is not stowed. The installer reads the tracked list and puts each
server back with `claude mcp add-json`. Home paths are written as `~/...` and
expanded on the way in.

To refresh the list after adding or removing a server:

```bash
./install.sh --save-mcp
```

Project-scoped servers are not tracked here. They belong in a `.mcp.json` in
the project that uses them.

## Extensions (VS Code)

The shared extension list is tracked in:

- `extensions/vscode.txt`

VS Code installs from this file. When saving the list, the
`code` CLI is used.
To refresh it:

```bash
./install.sh --save-extensions
```

## Restore

To put a previous backup back (unstow and copy files from backup):

```bash
./install.sh --restore
```

Backups are stored in `~/.dotfiles-backup-YYYYMMDD-HHMMSS`. You pick one from the list and the script does the rest.

## Stow commands

- Re-apply everything: `./install.sh`
- Unstow one package: `stow -t ~ -D <package>`
- Update editor extension lists: `./install.sh --save-extensions`
- Update the Homebrew inventory: `./install.sh --save-brewfile`
- Update the MCP server list: `./install.sh --save-mcp`
