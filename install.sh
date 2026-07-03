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
VSCODE_EXTENSIONS_FILE="$DOTFILES_DIR/extensions/vscode.txt"
BREWFILE="$DOTFILES_DIR/Brewfile"

# ------------------------------------------------------------------------------
# OS detection: macOS and Linux share most configs, but some packages
# (Hyprland, waybar, wireplumber, system modprobe) only make sense on Linux.
# ------------------------------------------------------------------------------
case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *)      OS=unknown ;;
esac

# Packages stowed on every OS
COMMON_PACKAGES=(zsh starship alacritty ghostty zed vscode agent-skills agent-instructions claude git)
# Packages stowed only on macOS
MACOS_PACKAGES=(skhd yabai borders)
# Packages stowed only on Linux (Hyprland desktop stack + audio tweaks)
LINUX_PACKAGES=(hypr waybar wireplumber)

if [[ "$OS" == "linux" ]]; then
  PACKAGES=("${COMMON_PACKAGES[@]}" "${LINUX_PACKAGES[@]}")
elif [[ "$OS" == "macos" ]]; then
  PACKAGES=("${COMMON_PACKAGES[@]}" "${MACOS_PACKAGES[@]}")
else
  PACKAGES=("${COMMON_PACKAGES[@]}")
fi

# Paths we back up (relative to $HOME); same list used for restore
BACKUP_PATHS=(
  .zshrc
  .skhdrc
  .yabairc
  .config/git/config
  .config/starship.toml
  .config/hypr
  .config/waybar
  .config/alacritty
  .config/ghostty
  .config/zed/keymap.json
  Library/Application Support/Code/User/settings.json
  .agents
  .codex/AGENTS.md
  .claude/CLAUDE.md
  .claude/settings.json
  .claude/statusline-command.sh
  .config/wireplumber/wireplumber.conf.d/51-disable-analog-audio-suspend.conf
)

backup_extensions() {
  local cli="$1"
  local backup_file="$2"
  local label="$3"

  if ! command -v "$cli" &>/dev/null; then
    echo "  skipping $label extensions backup ($cli not found)"
    return 0
  fi

  mkdir -p "$(dirname "$backup_file")"
  "$cli" --list-extensions | sort -u >"$backup_file"
  echo "  saved $label extensions -> $backup_file"
}

save_vscode_extensions() {
  local output_file="$1"

  if command -v code &>/dev/null; then
    backup_extensions code "$output_file" "VS Code"
    return 0
  fi

  echo "  skipping VS Code extensions backup (code not found)"
}

# ------------------------------------------------------------------------------
# Homebrew and Brewfile (macOS only)
# ------------------------------------------------------------------------------
load_homebrew_environment() {
  local brew_bin=""

  if command -v brew &>/dev/null; then
    brew_bin="$(command -v brew)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin="/opt/homebrew/bin/brew"
  elif [[ -x /usr/local/bin/brew ]]; then
    brew_bin="/usr/local/bin/brew"
  fi

  if [[ -n "$brew_bin" ]]; then
    eval "$("$brew_bin" shellenv)"
  fi
}

ensure_homebrew() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  load_homebrew_environment
  if command -v brew &>/dev/null; then
    return 0
  fi

  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew_environment

  if ! command -v brew &>/dev/null; then
    echo "Homebrew installation finished but brew is not available in PATH."
    exit 1
  fi
}

install_homebrew_bundle() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi
  if [[ ! -f "$BREWFILE" ]]; then
    echo "Brewfile not found: $BREWFILE"
    return 1
  fi

  echo ""
  echo "Installing Homebrew packages from $BREWFILE..."
  brew bundle install --no-upgrade --file="$BREWFILE"
}

save_homebrew_bundle() {
  if [[ "$OS" != "macos" ]]; then
    echo "Brewfile inventory is only supported on macOS."
    return 1
  fi

  ensure_homebrew
  brew bundle dump --force --file="$BREWFILE"
  echo "Saved Homebrew inventory to $BREWFILE"
}

# ------------------------------------------------------------------------------
# dependency: stow
# ------------------------------------------------------------------------------
need_stow() {
  if ! command -v stow &>/dev/null; then
    echo "GNU Stow is not installed."
    if command -v brew &>/dev/null; then
      echo "Installing with: brew install stow"
      brew install stow
    elif command -v pacman &>/dev/null; then
      echo "Installing with: sudo pacman -S stow"
      sudo pacman -S --noconfirm stow
    else
      echo "Install the 'stow' package and run this script again."
      exit 1
    fi
  fi
}

# ------------------------------------------------------------------------------
# macOS dependency: skhd
# ------------------------------------------------------------------------------
ensure_skhd() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  if ! command -v skhd &>/dev/null; then
    if ! command -v brew &>/dev/null; then
      echo "skhd is not installed and Homebrew is unavailable."
      echo "Install Homebrew, then run: brew install asmvik/formulae/skhd"
      return 1
    fi

    echo "Installing skhd..."
    brew install asmvik/formulae/skhd
  fi

  echo "Starting/restarting skhd..."
  if ! skhd --restart-service 2>/dev/null; then
    if ! skhd --start-service 2>/dev/null; then
      echo "  warning: skhd service did not start; check Accessibility permission."
    fi
  fi
}

# ------------------------------------------------------------------------------
# macOS default editor: VS Code
# ------------------------------------------------------------------------------
ensure_claude_code() {
  if command -v claude &>/dev/null; then
    return 0
  fi

  echo "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
}

ensure_code() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  if command -v code &>/dev/null; then
    return 0
  fi

  if ! command -v brew &>/dev/null; then
    echo "VS Code is not installed and Homebrew is unavailable."
    return 1
  fi

  echo "Installing VS Code..."
  brew install --cask visual-studio-code
}

remove_vscodium() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi
  if ! command -v brew &>/dev/null; then
    return 0
  fi

  if brew list --cask vscodium@insiders &>/dev/null; then
    echo "Removing VSCodium Insiders..."
    brew uninstall --cask vscodium@insiders
  fi
  if brew list --cask vscodium &>/dev/null; then
    echo "Removing VSCodium..."
    brew uninstall --cask vscodium
  fi
  if brew list --cask visual-studio-code@insiders &>/dev/null; then
    echo "Removing VS Code Insiders..."
    brew uninstall --cask visual-studio-code@insiders
  fi
}

ensure_borders() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  if ! command -v borders &>/dev/null; then
    echo "  skipping borders service (borders not installed)"
    return 0
  fi

  if brew services list | awk '$1 == "borders" && $2 == "started" { found=1 } END { exit !found }'; then
    borders >/dev/null 2>&1 || true
  else
    brew services start borders
  fi
}

# ------------------------------------------------------------------------------
# macOS dependency: yabai
# ------------------------------------------------------------------------------
ensure_yabai() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  if ! command -v yabai &>/dev/null; then
    if ! command -v brew &>/dev/null; then
      echo "yabai is not installed and Homebrew is unavailable."
      echo "Install Homebrew, then run: brew install asmvik/formulae/yabai"
      return 1
    fi

    echo "Installing yabai..."
    brew install asmvik/formulae/yabai
  fi

  echo "Starting/restarting yabai..."
  if ! yabai --restart-service 2>/dev/null; then
    if ! yabai --start-service 2>/dev/null; then
      echo "  warning: yabai service did not start; check Accessibility permission."
    fi
  fi
}

configure_yabai_scripting_addition() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  local installer="$HOME/.config/yabai/install-scripting-addition.sh"
  local sip_status
  sip_status="$(csrutil status 2>/dev/null || true)"

  if [[ "$sip_status" != *"Filesystem Protections: disabled"* ]]; then
    echo "  scripting addition skipped: required SIP protections are still enabled."
    return 0
  fi

  if [[ "$(sysctl -n kern.bootargs 2>/dev/null || true)" != *"-arm64e_preview_abi"* ]]; then
    echo "  scripting addition pending: reboot to activate -arm64e_preview_abi."
    return 0
  fi

  if sudo -n yabai --load-sa 2>/dev/null; then
    echo "  yabai scripting addition loaded."
    return 0
  fi

  if [[ ! -x "$installer" ]]; then
    echo "  warning: scripting-addition installer is missing."
    return 1
  fi

  "$installer"
}

configure_macos_window_manager_defaults() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  "$DOTFILES_DIR/system/macos/apply-defaults.sh"
}

# ------------------------------------------------------------------------------
# macOS login bootstrap: repair startup races after Dock/WindowServer are ready
# ------------------------------------------------------------------------------
ensure_yabai_login_bootstrap() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  local label="com.eduardo.yabai-bootstrap"
  local domain="gui/$(id -u)"
  local plist="$HOME/Library/LaunchAgents/$label.plist"

  if [[ ! -f "$plist" ]]; then
    echo "  warning: yabai login bootstrap plist is missing."
    return 1
  fi

  if launchctl print "$domain/$label" &>/dev/null; then
    launchctl bootout "$domain/$label" 2>/dev/null || true
  fi

  launchctl bootstrap "$domain" "$plist"
  launchctl kickstart -k "$domain/$label"
  echo "  yabai login bootstrap installed."
}

remove_yabai_login_bootstrap() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  launchctl bootout \
    "gui/$(id -u)/com.eduardo.yabai-bootstrap" 2>/dev/null || true
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
      if command -v code &>/dev/null; then
        backup_extensions code "$BACKUP_DIR/vscode-extensions.txt" "VS Code"
      fi
      echo "Backup done."
      ;;
    *)
      echo "Skipping backup."
      ;;
  esac
}

save_editor_extensions() {
  echo ""
  echo "Saving the shared editor extension list from VS Code..."
  save_vscode_extensions "$VSCODE_EXTENSIONS_FILE"
  echo "Done."
}

install_extensions_from_file() {
  local cli="$1"
  local file="$2"
  local label="$3"
  local installed=0
  local failed=0
  local extension

  if ! command -v "$cli" &>/dev/null; then
    echo "  skipping $label extensions install ($cli not found)"
    return 0
  fi
  if [[ ! -f "$file" ]]; then
    echo "  skipping $label extensions install ($file not found)"
    return 0
  fi

  echo "  installing $label extensions from $file"
  while IFS= read -r extension; do
    [[ -z "$extension" ]] && continue
    [[ "$extension" == \#* ]] && continue
    if "$cli" --install-extension "$extension" --force &>/dev/null; then
      ((installed += 1))
    else
      echo "    failed: $extension"
      ((failed += 1))
    fi
  done <"$file"

  echo "    installed/updated: $installed | failed: $failed"
}

install_editor_extensions() {
  echo ""
  echo "Installing editor extensions from dotfiles..."
  install_extensions_from_file code "$VSCODE_EXTENSIONS_FILE" "VS Code"
}

configure_macos_default_editor() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  if ! command -v code &>/dev/null; then
    echo "  skipping default editor setup (code not found)"
    return 0
  fi

  if ! command -v duti &>/dev/null; then
    if ! command -v brew &>/dev/null; then
      echo "  skipping macOS file associations (duti/Homebrew not found)"
      return 0
    fi
    echo "Installing duti for macOS file associations..."
    brew install duti
  fi

  local bundle_id="com.microsoft.VSCode"
  local failed=0
  local type
  for type in \
    .txt \
    .md \
    .json \
    .js \
    .jsx \
    .ts \
    .tsx \
    .sh \
    .zsh \
    .yaml \
    .yml \
    .xml \
    .csv; do
    if ! duti -s "$bundle_id" "$type" all; then
      echo "  warning: could not set VS Code as handler for $type"
      ((failed += 1))
    fi
  done

  if [[ "$failed" -eq 0 ]]; then
    echo "  VS Code configured as the default text/code editor."
  else
    echo "  VS Code file association setup finished with $failed warning(s)."
  fi
}

install_modprobe_configs() {
  # Linux-only: modprobe.d does not exist on macOS.
  if [[ "$OS" != "linux" ]]; then
    return 0
  fi

  local src="$DOTFILES_DIR/system/etc/modprobe.d/snd-hda-intel-disable-power-save.conf"
  local dest="/etc/modprobe.d/snd-hda-intel-disable-power-save.conf"

  if [[ ! -f "$src" ]]; then
    return 0
  fi

  echo ""
  echo "Installing system audio power-save config..."
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    echo "  already installed: $dest"
    return 0
  fi

  sudo install -Dm644 "$src" "$dest"
  echo "  installed: $dest"
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
  rm -f "$HOME/.config/git/config"
  rm -f "$HOME/.config/starship.toml"
  rm -rf "$HOME/.config/waybar"
  rm -rf "$HOME/.config/alacritty"
  rm -rf "$HOME/.config/ghostty"
  rm -f "$HOME/.config/zed/keymap.json"
  rm -f "$HOME/Library/Application Support/Code/User/settings.json"
  rm -f "$HOME/Library/Application Support/Code - Insiders/User/settings.json"
  rm -f "$HOME/.config/VSCodium/User/settings.json"
  rm -f "$HOME/Library/Application Support/VSCodium - Insiders/User/settings.json"
  rm -rf "$HOME/.agents"
  rm -f "$HOME/.codex/AGENTS.md"
  rm -f "$HOME/.claude/CLAUDE.md"
  rm -f "$HOME/.claude/settings.json"
  rm -f "$HOME/.claude/statusline-command.sh"
  rm -f "$HOME/.config/wireplumber/wireplumber.conf.d/51-disable-analog-audio-suspend.conf"

  # hypr base config is Linux/Hyprland-only
  if [[ "$OS" != "linux" ]]; then
    return 0
  fi

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
stow_package_safely() {
  local pkg="$1"
  local package_dir="$DOTFILES_DIR/$pkg"
  local safety_dir="$BACKUP_DIR/pre-stow/$pkg"
  local src relative dest saved
  local -a preserved_destinations=()
  local -a preserved_files=()

  # Preserve only exact file conflicts. Directories are intentionally left in
  # place because Stow can merge package trees into existing directories.
  while IFS= read -r src; do
    relative="${src#"$package_dir"/}"
    dest="$HOME/$relative"

    if [[ (-e "$dest" || -L "$dest") && ! "$src" -ef "$dest" ]]; then
      saved="$safety_dir/$relative"
      mkdir -p "$(dirname "$saved")"
      mv "$dest" "$saved"
      preserved_destinations+=("$dest")
      preserved_files+=("$saved")
      echo "    preserved conflict: $dest -> $saved"
    fi
  done < <(find "$package_dir" -type f)

  if stow -d "$DOTFILES_DIR" -t "$HOME" "$pkg"; then
    return 0
  fi

  echo "  stow $pkg failed; restoring preserved files."
  stow -d "$DOTFILES_DIR" -t "$HOME" -D "$pkg" 2>/dev/null || true

  local i
  for ((i = 0; i < ${#preserved_files[@]}; i++)); do
    mkdir -p "$(dirname "${preserved_destinations[$i]}")"
    mv "${preserved_files[$i]}" "${preserved_destinations[$i]}"
  done
  return 1
}

run_stow() {
  echo ""
  echo "Running stow from $DOTFILES_DIR to $HOME"
  for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
      echo "  stow $pkg"
      if [[ "$pkg" == "skhd" || "$pkg" == "yabai" ]]; then
        stow_package_safely "$pkg"
      else
        stow -d "$DOTFILES_DIR" -t "$HOME" "$pkg"
      fi
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
  local d
  while IFS= read -r d; do
    [[ -d "$d" ]] && backups+=("$d")
  done < <(find "$backup_base" -maxdepth 1 -type d -name '.dotfiles-backup-*' | sort -r)

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
  remove_yabai_login_bootstrap
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
  if [[ "$pkg" == "yabai" ]]; then
    remove_yabai_login_bootstrap
  fi
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
  local d
  while IFS= read -r d; do
    [[ -d "$d" ]] && backups+=("$d")
  done < <(find "$backup_base" -maxdepth 1 -type d -name '.dotfiles-backup-*' | sort -r)

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
# macOS yabai/skhd diagnostics
# ------------------------------------------------------------------------------
diagnostic_result() {
  local ok="$1"
  local success="$2"
  local failure="$3"

  if [[ "$ok" == "true" ]]; then
    echo "  ✓ $success"
  else
    echo "  ⚠ $failure"
  fi
}

run_macos_diagnostics() {
  if [[ "$OS" != "macos" ]]; then
    echo "macOS diagnostics are not applicable on this system."
    return 0
  fi

  echo ""
  echo "macOS window manager diagnostics:"

  diagnostic_result \
    "$([[ -x "$(command -v yabai 2>/dev/null || true)" ]] && echo true || echo false)" \
    "yabai installed ($(yabai --version 2>/dev/null || true))" \
    "yabai is not installed"

  diagnostic_result \
    "$([[ -x "$(command -v skhd 2>/dev/null || true)" ]] && echo true || echo false)" \
    "skhd installed ($(skhd --version 2>/dev/null || true))" \
    "skhd is not installed"

  diagnostic_result \
    "$([[ "$DOTFILES_DIR/yabai/.yabairc" -ef "$HOME/.yabairc" ]] 2>/dev/null && echo true || echo false)" \
    ".yabairc linked from dotfiles" \
    ".yabairc is not linked from dotfiles"

  diagnostic_result \
    "$([[ "$DOTFILES_DIR/skhd/.skhdrc" -ef "$HOME/.skhdrc" ]] 2>/dev/null && echo true || echo false)" \
    ".skhdrc linked from dotfiles" \
    ".skhdrc is not linked from dotfiles"

  diagnostic_result \
    "$(launchctl print "gui/$(id -u)/com.asmvik.yabai" 2>/dev/null | grep -q 'state = running' && echo true || echo false)" \
    "yabai launchd service running" \
    "yabai launchd service is not running"

  diagnostic_result \
    "$(launchctl print "gui/$(id -u)/com.koekeishiya.skhd" 2>/dev/null | grep -q 'state = running' && echo true || echo false)" \
    "skhd launchd service running" \
    "skhd launchd service is not running"

  diagnostic_result \
    "$([[ "$DOTFILES_DIR/yabai/.config/yabai/label-spaces.sh" -ef "$HOME/.config/yabai/label-spaces.sh" ]] 2>/dev/null && echo true || echo false)" \
    "Space-label helper linked from dotfiles" \
    "Space-label helper is not linked from dotfiles"

  diagnostic_result \
    "$([[ "$DOTFILES_DIR/yabai/.config/yabai/space-action.sh" -ef "$HOME/.config/yabai/space-action.sh" ]] 2>/dev/null && echo true || echo false)" \
    "dynamic Space shortcut helper linked from dotfiles" \
    "dynamic Space shortcut helper is not linked from dotfiles"

  diagnostic_result \
    "$(sudo -n yabai --load-sa &>/dev/null && echo true || echo false)" \
    "yabai scripting addition loaded" \
    "yabai scripting addition is not configured or could not load"

  diagnostic_result \
    "$([[ "$(sysctl -n kern.bootargs 2>/dev/null || true)" == *"-arm64e_preview_abi"* ]] && echo true || echo false)" \
    "arm64e boot argument active in this kernel" \
    "arm64e boot argument is stored but not active; reboot required"

  diagnostic_result \
    "$(awk -v value="$(yabai -m config window_animation_duration 2>/dev/null || echo 0)" 'BEGIN { exit !(value > 0) }' && echo true || echo false)" \
    "window animations enabled" \
    "window animations unavailable; grant Screen Recording and restart yabai"

  diagnostic_result \
    "$(pgrep -x borders &>/dev/null && echo true || echo false)" \
    "window borders running" \
    "window borders are not running"

  diagnostic_result \
    "$(launchctl print "gui/$(id -u)/com.eduardo.yabai-bootstrap" &>/dev/null && echo true || echo false)" \
    "login bootstrap registered" \
    "login bootstrap is not registered"

  local spaces labels normal_spaces layout attempt
  spaces=""
  for attempt in {1..30}; do
    spaces="$(yabai -m query --spaces 2>/dev/null || true)"
    [[ -n "$spaces" ]] && break
    sleep 1
  done
  labels="$(jq '[.[] | select(."is-native-fullscreen" == false and (.label | test("^ws-[1-9]$")))] | length' <<<"${spaces:-[]}" 2>/dev/null || echo 0)"
  normal_spaces="$(jq '[.[] | select(."is-native-fullscreen" == false)] | length' <<<"${spaces:-[]}" 2>/dev/null || echo 0)"
  layout="$(yabai -m config layout 2>/dev/null || true)"

  diagnostic_result \
    "$([[ -n "$spaces" ]] && echo true || echo false)" \
    "yabai can query windows and Spaces (Accessibility granted)" \
    "yabai cannot query Spaces; grant Accessibility permission"

  diagnostic_result \
    "$([[ "$layout" == "bsp" ]] && echo true || echo false)" \
    "BSP layout loaded" \
    "BSP layout is not active"

  diagnostic_result \
    "$([[ "${normal_spaces:-0}" -gt 0 && "$labels" -eq "$normal_spaces" ]] 2>/dev/null && echo true || echo false)" \
    "all $normal_spaces normal Spaces have stable ws-N labels" \
    "only $labels of $normal_spaces normal Spaces have stable ws-N labels"

  diagnostic_result \
    "$([[ "${normal_spaces:-0}" -ge 7 ]] 2>/dev/null && echo true || echo false)" \
    "$normal_spaces normal Spaces available" \
    "only $normal_spaces normal Spaces available; expected at least 7"

  echo ""
  echo "Shortcut reference: $DOTFILES_DIR/docs/macos-window-management.md"
}

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
