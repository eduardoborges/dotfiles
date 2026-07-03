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
#
# Implementation lives in lib/*.sh, sourced below in dependency order (os.sh
# first, since it sets OS/PACKAGES that later modules rely on).
# ------------------------------------------------------------------------------

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
VSCODE_EXTENSIONS_FILE="$DOTFILES_DIR/extensions/vscode.txt"
BREWFILE="$DOTFILES_DIR/Brewfile"

for lib in os homebrew stow backup editor window-manager linux diagnostics; do
  # shellcheck source=/dev/null
  source "$DOTFILES_DIR/lib/$lib.sh"
done

# ------------------------------------------------------------------------------
# usage
# ------------------------------------------------------------------------------
usage() {
  echo "Usage: $0 [install]        - install dotfiles (stow), with optional backup"
  echo "       $0 --restore         - list backups and restore a previous set of configs"
  echo "       $0 --list-backups    - list backup directories (no restore)"
  echo "       $0 --unstow <pkg>   - unstow a single package (e.g. waybar, alacritty)"
  echo "       $0 --save-extensions - update the shared editor list from VS Code"
  echo "       $0 --save-brewfile   - refresh Brewfile from installed Homebrew packages"
  echo "       $0 --diagnose        - check the macOS yabai/skhd setup"
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
    --save-extensions|save-extensions)
      save_editor_extensions
      return
      ;;
    --save-brewfile|save-brewfile)
      save_homebrew_bundle
      return
      ;;
    --diagnose|diagnose)
      run_macos_diagnostics
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
  ensure_homebrew
  install_homebrew_bundle
  ensure_claude_code
  need_stow
  do_backup
  remove_targets_for_stow
  run_stow
  configure_macos_window_manager_defaults
  ensure_code
  remove_vscodium
  ensure_yabai
  configure_yabai_scripting_addition
  ensure_skhd
  ensure_borders
  ensure_yabai_login_bootstrap
  install_modprobe_configs
  install_editor_extensions
  configure_macos_default_editor
  reload_hypr_and_waybar
  sleep 1
  run_macos_diagnostics
}

main "$@"
