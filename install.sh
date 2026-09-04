#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# eduardo's dotfiles installer. macOS only.
#
# Everything in $HOME is a symlink back into this repo, made with GNU Stow.
# Run ./install.sh --help for the commands; the steps live in lib/*.sh.
#
# If something breaks: ./install.sh --unstow <package>, or --restore to put a
# backup back.
# ------------------------------------------------------------------------------

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
VSCODE_EXTENSIONS_FILE="$DOTFILES_DIR/extensions/vscode.txt"
BREWFILE="$DOTFILES_DIR/Brewfile"

for lib in ui packages homebrew stow backup editor window-manager diagnostics; do
  # shellcheck source=/dev/null
  source "$DOTFILES_DIR/lib/$lib.sh"
done

usage() {
  cat <<USAGE
Usage: $0 [install]        - install dotfiles (stow), with optional backup
       $0 --restore         - restore a previous set of configs from a backup
       $0 --list-backups    - list backup directories
       $0 --unstow <pkg>    - unstow a single package (e.g. yabai, alacritty)
       $0 --save-extensions - update extensions/vscode.txt from VS Code
       $0 --save-brewfile   - refresh the Brewfile from installed Homebrew packages
       $0 --diagnose        - check the yabai/skhd setup

Packages: ${PACKAGES[*]}
Backups are stored in ~/.dotfiles-backup-YYYYMMDD-HHMMSS
USAGE
}

run_install() {
  banner

  ensure_homebrew
  install_homebrew_bundle
  ensure_code
  ensure_claude_code

  need_stow
  do_backup
  run_stow
  link_skills

  apply_macos_defaults
  setup_window_manager
  install_editor_extensions
  configure_default_editor

  sleep 1 # give the services a moment before we ask them anything
  run_macos_diagnostics
}

main() {
  case "${1:-install}" in
    install|"")             run_install ;;
    --restore|-r)           run_restore ;;
    --list-backups|-l)      run_list_backups ;;
    --unstow|-u)            run_unstow "${2:-}" ;;
    --save-extensions)      save_editor_extensions ;;
    --save-brewfile)        save_homebrew_bundle ;;
    --diagnose)             run_macos_diagnostics ;;
    -h|--help)              usage ;;
    *)                      echo "Unknown option: $1"; usage; exit 1 ;;
  esac
}

main "$@"
