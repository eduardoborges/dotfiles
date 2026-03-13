# Dotfiles

My daily configs for zsh, starship, Hyprland, waybar, Alacritty, and agent skills.

I tested this on Arch Linux BTW.

Everything is symlinked into your home via [GNU Stow](https://www.gnu.org/software/stow/).

## Install

You need **stow** (e.g. `sudo pacman -S stow` or `brew install stow`). Then:

```bash
./install.sh
```

The script will ask if you want to back up your current configs first (recommended). After that it unstows any existing links, sets up the symlinks, and reloads Hyprland and waybar if you’re in a Hyprland session.

## Restore

To put a previous backup back (unstow and copy files from backup):

```bash
./install.sh --restore
```

Backups are stored in `~/.dotfiles-backup-YYYYMMDD-HHMMSS`. You pick one from the list; the script does the rest and reloads Hyprland/waybar.

## Stow commands

- Re-apply everything: `./install.sh` or `stow -t ~ zsh starship hypr waybar alacritty agent-skills`
- Unstow one package: `stow -t ~ -D <package>`
