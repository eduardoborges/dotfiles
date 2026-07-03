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
