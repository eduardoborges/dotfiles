# ------------------------------------------------------------------------------
# yabai, skhd and borders: install the binaries, start the services, and repair
# the startup race at login.
# ------------------------------------------------------------------------------
ensure_wm_service() {
  local name="$1" formula="$2"

  if ! command -v "$name" &>/dev/null; then
    command -v brew &>/dev/null || die "$name is missing; install Homebrew, then: brew install $formula"
    info "installing $name..."
    brew install "$formula"
  fi

  info "starting $name..."
  "$name" --restart-service 2>/dev/null \
    || "$name" --start-service 2>/dev/null \
    || warn "$name did not start; check its Accessibility permission."
}

ensure_borders() {
  if ! command -v borders &>/dev/null; then
    warn "skipping borders (not installed)"
    return 0
  fi

  if brew services list | awk '$1 == "borders" && $2 == "started" { found = 1 } END { exit !found }'; then
    borders >/dev/null 2>&1 || true
  else
    brew services start borders
  fi
}

# ------------------------------------------------------------------------------
# The scripting addition needs SIP partially disabled and the arm64e boot arg,
# so every precondition is reported instead of failing the install.
# ------------------------------------------------------------------------------
configure_yabai_scripting_addition() {
  local installer="$HOME/.config/yabai/install-scripting-addition.sh"

  if [[ "$(csrutil status 2>/dev/null || true)" != *"Filesystem Protections: disabled"* ]]; then
    warn "scripting addition skipped: SIP filesystem protections are still enabled."
    return 0
  fi

  if [[ "$(sysctl -n kern.bootargs 2>/dev/null || true)" != *"-arm64e_preview_abi"* ]]; then
    warn "scripting addition pending: reboot to activate -arm64e_preview_abi."
    return 0
  fi

  if sudo -n yabai --load-sa 2>/dev/null; then
    ok "yabai scripting addition loaded."
    return 0
  fi

  [[ -x "$installer" ]] || die "scripting-addition installer is missing: $installer"
  "$installer"
}

apply_macos_defaults() {
  section "Applying macOS defaults"
  "$DOTFILES_DIR/system/macos/apply-defaults.sh"
}

# ------------------------------------------------------------------------------
# login bootstrap: reloads yabai once Dock and WindowServer are ready
# ------------------------------------------------------------------------------
YABAI_BOOTSTRAP_LABEL="com.eduardo.yabai-bootstrap"

ensure_yabai_login_bootstrap() {
  local domain="gui/$(id -u)"
  local plist="$HOME/Library/LaunchAgents/$YABAI_BOOTSTRAP_LABEL.plist"

  [[ -f "$plist" ]] || die "yabai login bootstrap plist is missing: $plist"

  if launchctl print "$domain/$YABAI_BOOTSTRAP_LABEL" &>/dev/null; then
    launchctl bootout "$domain/$YABAI_BOOTSTRAP_LABEL" 2>/dev/null || true
  fi

  launchctl bootstrap "$domain" "$plist"
  launchctl kickstart -k "$domain/$YABAI_BOOTSTRAP_LABEL"
  ok "yabai login bootstrap installed."
}

remove_yabai_login_bootstrap() {
  launchctl bootout "gui/$(id -u)/$YABAI_BOOTSTRAP_LABEL" 2>/dev/null || true
}

setup_window_manager() {
  section "Setting up the window manager"
  ensure_wm_service yabai asmvik/formulae/yabai
  ensure_wm_service skhd asmvik/formulae/skhd
  configure_yabai_scripting_addition
  ensure_borders
  ensure_yabai_login_bootstrap
}
