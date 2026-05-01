#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# eduardo's dotfiles installer using GNU Stow to symlink everything into your $HOME
#
# Usage:
#   ./install.sh [install]         - install dotfiles (stow), with optional backup
#   ./install.sh --restore          - list backups and restore a previous set of configs
#   ./install.sh --list-backups     - list backup directories (no restore)
#   ./install.sh --unstow <pkg>     - unstow a single package
#
# Backups are stored in ~/.dotfiles-backup-YYYYMMDD-HHMMSS
#
# If something breaks, you can unstow a package with `stow -t ~ -D <package>` and, if you have a backup, copy the files back from the backup folder.
# ------------------------------------------------------------------------------

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Packages we're going to stow (each becomes a set of symlinks)
PACKAGES=(zsh starship hypr waybar alacritty ghostty zed agent-skills)

# Paths we back up (relative to $HOME); same list used for restore
BACKUP_PATHS=(
  .zshrc
  .config/starship.toml
  .config/hypr
  .config/waybar
  .config/alacritty
  .config/ghostty
  .config/zed/keymap.json
  .agents
)

# ------------------------------------------------------------------------------
# dependency: stow
# ------------------------------------------------------------------------------
need_stow() {
  if ! command -v stow &>/dev/null; then
    echo "GNU Stow is not installed."
    if command -v pacman &>/dev/null; then
      echo "Installing with: sudo pacman -S stow"
      sudo pacman -S --noconfirm stow
    else
      echo "Install the 'stow' package and run this script again."
      exit 1
    fi
  fi
}

# ------------------------------------------------------------------------------
# optional backup of files that would be overwritten
# ------------------------------------------------------------------------------
backup_if_exists() {
  local path="$1"
  local backup_path="${BACKUP_DIR}${path}"
  if [[ -e "$path" && ! -L "$path" ]]; then
    echo "  backup: $path -> $backup_path"
    mkdir -p "$(dirname "$backup_path")"
    cp -a "$path" "$backup_path"
  fi
}

do_backup() {
  echo ""
  read -r -p "Back up current configs before installing? (y/N) " answer
  case "${answer:-n}" in
    y|Y)
      echo "Creating backup at: $BACKUP_DIR"
      mkdir -p "$BACKUP_DIR"
      for path in "${BACKUP_PATHS[@]}"; do
        backup_if_exists "$HOME/$path"
      done
      echo "Backup done."
      ;;
    *)
      echo "Skipping backup."
      ;;
  esac
}

# ------------------------------------------------------------------------------
# hypr: hyprland.conf and hyprlock.conf are NOT in this repo - they come from Omarchy.
# We need them to exist as regular files before stow, or stow would replace the whole dir.
# ------------------------------------------------------------------------------
ensure_hypr_base_config() {
  local hypr_dir="$HOME/.config/hypr"
  local omarchy_hypr="${HOME}/.local/share/omarchy/config/hypr"

  if [[ -d "$omarchy_hypr" ]]; then
    mkdir -p "$hypr_dir"
    if [[ ! -f "$hypr_dir/hyprland.conf" ]]; then
      echo "  creating $hypr_dir/hyprland.conf from Omarchy"
      cp "$omarchy_hypr/hyprland.conf" "$hypr_dir/hyprland.conf"
    fi
    if [[ ! -f "$hypr_dir/hyprlock.conf" ]]; then
      echo "  creating $hypr_dir/hyprlock.conf from Omarchy"
      cp "$omarchy_hypr/hyprlock.conf" "$hypr_dir/hyprlock.conf"
    fi
  else
    echo "  warning: Omarchy not found at ~/.local/share/omarchy - hyprland.conf/hyprlock.conf were not created."
    echo "  If you use Hyprland with Omarchy, install Omarchy first or create those files manually."
  fi
}

# ------------------------------------------------------------------------------
# remove only what we're going to replace with symlinks (don't touch hyprland.conf/hyprlock.conf)
# ------------------------------------------------------------------------------
remove_targets_for_stow() {
  echo "Removing files/dirs that will be replaced by symlinks..."
  rm -f "$HOME/.zshrc"
  rm -f "$HOME/.config/starship.toml"
  rm -rf "$HOME/.config/waybar"
  rm -rf "$HOME/.config/alacritty"
  rm -rf "$HOME/.config/ghostty"
  rm -f "$HOME/.config/zed/keymap.json"
  rm -rf "$HOME/.agents"

  # hypr: only remove the dir if it's a symlink; if it's a real dir, remove only the files that are in the repo
  if [[ -L "$HOME/.config/hypr" ]]; then
    rm -f "$HOME/.config/hypr"
  elif [[ -d "$HOME/.config/hypr" ]]; then
    for f in autostart.conf bindings.conf hypridle.conf hyprsunset.conf input.conf looknfeel.conf monitors.conf xdph.conf; do
      rm -f "$HOME/.config/hypr/$f"
    done
  else
    mkdir -p "$HOME/.config/hypr"
  fi

  ensure_hypr_base_config
}

# ------------------------------------------------------------------------------
# stow
# ------------------------------------------------------------------------------
run_stow() {
  echo ""
  echo "Running stow from $DOTFILES_DIR to $HOME"
  for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
      echo "  stow $pkg"
      stow -d "$DOTFILES_DIR" -t "$HOME" "$pkg"
    else
      echo "  (skipping $pkg - directory does not exist)"
    fi
  done
  echo ""
  echo "Done. Configs installed via symlinks."
}

# ------------------------------------------------------------------------------
# restore from a backup (unstow + copy backup files back)
# ------------------------------------------------------------------------------
run_restore() {
  local backup_base="$HOME"
  local backups=()
  for d in "$backup_base"/.dotfiles-backup-*; do
    [[ -d "$d" ]] && backups+=("$d")
  done
  mapfile -t backups < <(printf '%s\n' "${backups[@]}" | sort -r)

  if [[ ${#backups[@]} -eq 0 ]]; then
    echo "No backups found in $backup_base (expected .dotfiles-backup-YYYYMMDD-HHMMSS)"
    exit 1
  fi

  echo "Available backups:"
  for i in "${!backups[@]}"; do
    echo "  $((i + 1))) ${backups[$i]##*/}"
  done
  echo "  0) Cancel"
  echo ""
  read -r -p "Restore which backup? (1-${#backups[@]}, or 0 to cancel) " choice

  if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 0 ]] || [[ "$choice" -gt ${#backups[@]} ]]; then
    echo "Invalid choice. Exiting."
    exit 1
  fi
  if [[ "$choice" -eq 0 ]]; then
    echo "Cancelled."
    exit 0
  fi

  local restore_dir="${backups[$((choice - 1))]}"
  echo ""
  echo "Restoring from: $restore_dir"
  echo "This will unstow all packages and copy files from the backup back to your home."
  read -r -p "Continue? (y/N) " confirm
  case "${confirm:-n}" in
    y|Y) ;;
    *) echo "Cancelled."; exit 0 ;;
  esac

  need_stow
  echo "Unstowing packages..."
  for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
      stow -d "$DOTFILES_DIR" -t "$HOME" -D "$pkg" 2>/dev/null || true
    fi
  done

  echo "Copying files from backup..."
  for path in "${BACKUP_PATHS[@]}"; do
    local src="$restore_dir/$path"
    local dest="$HOME/$path"
    if [[ -e "$src" ]]; then
      mkdir -p "$(dirname "$dest")"
      cp -a "$src" "$dest"
      echo "  restored: $path"
    fi
  done

  echo ""
  echo "Restore done. Your previous configs are back; dotfiles are no longer symlinked."
  reload_hypr_and_waybar
}

# ------------------------------------------------------------------------------
# reload Hyprland config and restart waybar (only when running inside Hyprland)
# ------------------------------------------------------------------------------
reload_hypr_and_waybar() {
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    return 0
  fi
  if command -v hyprctl &>/dev/null; then
    echo "Reloading Hyprland..."
    hyprctl reload 2>/dev/null && echo "  Hyprland config reloaded." || true
  fi
  if command -v waybar &>/dev/null; then
    echo "Restarting waybar..."
    pkill waybar 2>/dev/null || true
    sleep 0.5
    waybar &>/dev/null &
    echo "  Waybar restarted."
  fi
}

# ------------------------------------------------------------------------------
# unstow a single package
# ------------------------------------------------------------------------------
run_unstow() {
  local pkg="${1:-}"
  if [[ -z "$pkg" ]]; then
    echo "Available packages: ${PACKAGES[*]}"
    echo "Usage: $0 --unstow <package>"
    exit 1
  fi
  if [[ ! -d "$DOTFILES_DIR/$pkg" ]]; then
    echo "Unknown package: $pkg (directory $DOTFILES_DIR/$pkg does not exist)"
    echo "Available packages: ${PACKAGES[*]}"
    exit 1
  fi
  need_stow
  echo "Unstowing $pkg..."
  stow -d "$DOTFILES_DIR" -t "$HOME" -D "$pkg"
  echo "Done. $pkg has been unstowed."
  if [[ "$pkg" == "hypr" ]] || [[ "$pkg" == "waybar" ]]; then
    reload_hypr_and_waybar
  fi
}

# ------------------------------------------------------------------------------
# list backup directories
# ------------------------------------------------------------------------------
run_list_backups() {
  local backup_base="$HOME"
  local backups=()
  for d in "$backup_base"/.dotfiles-backup-*; do
    [[ -d "$d" ]] && backups+=("$d")
  done
  mapfile -t backups < <(printf '%s\n' "${backups[@]}" | sort -r)

  if [[ ${#backups[@]} -eq 0 ]]; then
    echo "No backups found in $backup_base (expected .dotfiles-backup-YYYYMMDD-HHMMSS)"
    return 0
  fi

  echo "Backups in $backup_base:"
  for i in "${!backups[@]}"; do
    echo "  $((i + 1))) ${backups[$i]##*/}"
  done
}

# ------------------------------------------------------------------------------
# usage
# ------------------------------------------------------------------------------
usage() {
  echo "Usage: $0 [install]        - install dotfiles (stow), with optional backup"
  echo "       $0 --restore         - list backups and restore a previous set of configs"
  echo "       $0 --list-backups    - list backup directories (no restore)"
  echo "       $0 --unstow <pkg>   - unstow a single package (e.g. waybar, alacritty)"
  echo ""
  echo "Packages: ${PACKAGES[*]}"
  echo "Backups are stored in ~/.dotfiles-backup-YYYYMMDD-HHMMSS"
}

# ------------------------------------------------------------------------------
# main
# ------------------------------------------------------------------------------
main() {
  case "${1:-install}" in
    --restore|-r|restore)
      run_restore
      return
      ;;
    --list-backups|-l)
      run_list_backups
      return
      ;;
    --unstow|-u)
      run_unstow "${2:-}"
      return
      ;;
    install|"")
      ;;
    -h|--help)
      usage
      return 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac

  # Fancy banner (colors only if terminal supports it)
  if [[ -t 1 ]] && command -v tput &>/dev/null; then
    bold=$(tput bold 2>/dev/null || true)
    dim=$(tput dim 2>/dev/null || true)
    cyan=$(tput setaf 6 2>/dev/null || true)
    reset=$(tput sgr0 2>/dev/null || true)
  else
    bold= dim= cyan= reset=
  fi


  echo ""
  echo "${bold}${cyan}  ┌──────────────────────────────────────┐${reset}"
  echo "${bold}${cyan}  │  eduardo's dotfiles  —  install      │${reset}"
  echo "${bold}${cyan}  └──────────────────────────────────────┘${reset}"
  echo "  ${dim}directory${reset}  $DOTFILES_DIR"
  echo "  ${dim}home${reset}       $HOME"
  echo ""
  need_stow
  do_backup
  remove_targets_for_stow
  run_stow
  reload_hypr_and_waybar
}

main "$@"
