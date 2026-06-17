# Dotfiles

My daily configs for zsh, starship, Hyprland, waybar, Alacritty, VSCodium, Cursor, and agent skills.

Works on **Arch Linux** (my main setup) and **macOS**. The installer detects your OS and only stows the packages that make sense there — the Hyprland desktop stack (`hypr`, `waybar`, `wireplumber`) and the system audio tweaks are Linux-only and are skipped on macOS. Shell-level differences (clipboard, Android SDK path) are handled inside `.zshrc` at runtime.

Everything is symlinked into your home via [GNU Stow](https://www.gnu.org/software/stow/).

## Install

You need **stow** (`brew install stow` on macOS, `sudo pacman -S stow` on Arch). The installer will offer to install it for you via brew/pacman if it's missing. Then:

```bash
./install.sh
```

The script will ask if you want to back up your current configs first (recommended). After that it unstows any existing links, sets up the symlinks, installs editor extensions from `extensions/vscodium.txt` and `extensions/cursor.txt`, and (on Linux) reloads Hyprland and waybar if you’re in a Hyprland session.

## Extensions (VSCodium and Cursor)

Extension lists are tracked in:

- `extensions/vscodium.txt`
- `extensions/cursor.txt`

To refresh both files with your currently installed extensions:

```bash
./install.sh --save-extensions
```

## Restore

To put a previous backup back (unstow and copy files from backup):

```bash
./install.sh --restore
```

Backups are stored in `~/.dotfiles-backup-YYYYMMDD-HHMMSS`. You pick one from the list; the script does the rest and reloads Hyprland/waybar.

## Stow commands

- Re-apply everything: `./install.sh` or `stow -t ~ zsh starship hypr waybar alacritty agent-skills`
- Unstow one package: `stow -t ~ -D <package>`
- Update editor extension lists: `./install.sh --save-extensions`
