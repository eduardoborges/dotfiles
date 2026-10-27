# ------------------------------------------------------------------------------
# yabai, skhd and borders: install the binaries, start the services, and repair
# the startup race at login.
# ------------------------------------------------------------------------------
YABAI_BIN="$HOME/.local/libexec/yabai"
YABAI_PLIST="$HOME/Library/LaunchAgents/com.asmvik.yabai.plist"

install_formula() {
  local name="$1" formula="$2"

  command -v "$name" &>/dev/null && return 0
  command -v brew &>/dev/null || die "$name is missing; install Homebrew, then: brew install $formula"
  info "installing $name..."
  brew install "$formula"
}

start_service() {
  local name="$1" bin="${2:-$1}"

  info "starting $name..."
  "$bin" --restart-service 2>/dev/null \
    || "$bin" --start-service 2>/dev/null \
    || warn "$name did not start; check its Accessibility permission."
}

ensure_wm_service() {
  install_formula "$1" "$2"
  start_service "$1"
}

# ------------------------------------------------------------------------------
# yabai runs from the signed copy yabai-resign makes in ~/.local/libexec, so its
# permissions and sudoers entry survive brew upgrades. Re-signing asks for sudo
# and restarts yabai, so it only runs when the copy is missing or stale, or when
# launchd starts another binary.
# ------------------------------------------------------------------------------
ensure_yabai() {
  install_formula yabai eduardoborges/tap/yabai

  if [[ ! -x "$YABAI_BIN" || "$(readlink -f "$(command -v yabai)")" -nt "$YABAI_BIN" ]] ||
    [[ "$(plutil -extract ProgramArguments.0 raw "$YABAI_PLIST" 2>/dev/null)" != "$YABAI_BIN" ]]; then
    info "copying yabai to $YABAI_BIN..."
    "$HOME/.local/bin/yabai-resign" || warn "yabai-resign failed; run it again by hand."
    return 0
  fi

  start_service yabai "$YABAI_BIN"
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
  if [[ "$(csrutil status 2>/dev/null || true)" != *"Filesystem Protections: disabled"* ]]; then
    warn "scripting addition skipped: SIP filesystem protections are still enabled."
    return 0
  fi

  if [[ "$(sysctl -n kern.bootargs 2>/dev/null || true)" != *"-arm64e_preview_abi"* ]]; then
    warn "scripting addition pending: reboot to activate -arm64e_preview_abi."
    return 0
  fi

  if sudo -n "$YABAI_BIN" --load-sa 2>/dev/null; then
    ok "yabai scripting addition loaded."
    return 0
  fi

  warn "scripting addition did not load; yabai-resign rewrites its sudoers entry."
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
  ensure_yabai
  ensure_wm_service skhd asmvik/formulae/skhd
  configure_yabai_scripting_addition
  ensure_borders
  ensure_yabai_login_bootstrap
}
