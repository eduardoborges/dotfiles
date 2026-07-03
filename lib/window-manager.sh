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
