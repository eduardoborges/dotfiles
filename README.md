# Dotfiles

My daily configs for zsh, starship, Hyprland, waybar, yabai, skhd, JankyBorders, Alacritty, VSCodium Insiders, and agent skills.

Works on **Arch Linux** (my main setup) and **macOS**. The installer detects your OS and only stows the packages that make sense there — the Hyprland desktop stack (`hypr`, `waybar`, `wireplumber`) and the system audio tweaks are Linux-only, while `yabai` and `skhd` provide tiling and hotkeys on macOS. Shell-level differences (clipboard, Android SDK path) are handled inside `.zshrc` at runtime.

Everything is symlinked into your home via [GNU Stow](https://www.gnu.org/software/stow/).

## Install

On macOS, the installer bootstraps Homebrew when necessary and installs the
tracked formulas and applications from [`Brewfile`](Brewfile). On Arch, you
only need `stow` (`sudo pacman -S stow`; the installer can install it).
Then:

```bash
./install.sh
```

The script will ask if you want to back up your current configs first (recommended). After that it unstows any existing links, sets up the symlinks, installs editor extensions from `extensions/vscodium.txt` into VSCodium Stable and Insiders, and (on Linux) reloads Hyprland and waybar if you’re in a Hyprland session.

On macOS, the Brewfile restores the command-line tools and desktop apps,
including VSCodium Insiders, Ghostty, Chrome, Docker, yabai, and skhd. The
installer then starts the window-manager launchd services and configures
VSCodium Insiders as the default text/code editor. Grant yabai and skhd access
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

See [docs/macos-window-management.md](docs/macos-window-management.md) for the complete shortcut reference and troubleshooting commands.

## Extensions (VSCodium and VSCodium Insiders)

The shared extension list is tracked in:

- `extensions/vscodium.txt`

VSCodium Stable and VSCodium Insiders install from this file. When saving the
list, Stable is preferred if installed; otherwise the Insiders CLI is used.
To refresh it:

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

- Re-apply everything: `./install.sh`
- Unstow one package: `stow -t ~ -D <package>`
- Update editor extension lists: `./install.sh --save-extensions`
- Update the Homebrew inventory: `./install.sh --save-brewfile`
