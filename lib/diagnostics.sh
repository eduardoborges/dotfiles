# ------------------------------------------------------------------------------
# Post-install health check for the window manager.
# Each check prints a line; nothing here changes the system.
# ------------------------------------------------------------------------------
check() {
  local success="$1" failure="$2"
  shift 2

  if "$@" &>/dev/null; then
    ok "$success"
  else
    warn "$failure"
  fi
}

linked()          { [[ "$DOTFILES_DIR/$1" -ef "$HOME/$2" ]]; }
service_running() { launchctl print "gui/$(id -u)/$1" 2>/dev/null | grep -q 'state = running'; }
service_loaded()  { launchctl print "gui/$(id -u)/$1"; }
boot_arg_active() { [[ "$(sysctl -n kern.bootargs 2>/dev/null || true)" == *"$1"* ]]; }
animations_on()   { awk -v v="$(yabai -m config window_animation_duration 2>/dev/null || echo 0)" 'BEGIN { exit !(v > 0) }'; }

# yabai answers queries only once Accessibility is granted and the service is up
wait_for_yabai_spaces() {
  local attempt spaces=""
  for attempt in {1..30}; do
    spaces="$(yabai -m query --spaces 2>/dev/null || true)"
    [[ -n "$spaces" ]] && break
    sleep 1
  done
  echo "${spaces:-[]}"
}

run_macos_diagnostics() {
  section "Window manager diagnostics"

  check "yabai installed ($(yabai --version 2>/dev/null || true))" "yabai is not installed" \
    command -v yabai
  check "skhd installed ($(skhd --version 2>/dev/null || true))" "skhd is not installed" \
    command -v skhd

  check ".yabairc linked from dotfiles" ".yabairc is not linked from dotfiles" \
    linked yabai/.yabairc .yabairc
  check ".skhdrc linked from dotfiles" ".skhdrc is not linked from dotfiles" \
    linked skhd/.skhdrc .skhdrc
  check "Space-label helper linked from dotfiles" "Space-label helper is not linked from dotfiles" \
    linked yabai/.config/yabai/label-spaces.sh .config/yabai/label-spaces.sh
  check "dynamic Space shortcut helper linked from dotfiles" "dynamic Space shortcut helper is not linked from dotfiles" \
    linked yabai/.config/yabai/space-action.sh .config/yabai/space-action.sh

  check "yabai launchd service running" "yabai launchd service is not running" \
    service_running com.asmvik.yabai
  check "skhd launchd service running" "skhd launchd service is not running" \
    service_running com.koekeishiya.skhd
  check "login bootstrap registered" "login bootstrap is not registered" \
    service_loaded "$YABAI_BOOTSTRAP_LABEL"

  check "yabai scripting addition loaded" "yabai scripting addition is not configured or could not load" \
    sudo -n yabai --load-sa
  check "arm64e boot argument active in this kernel" "arm64e boot argument is stored but not active; reboot required" \
    boot_arg_active -arm64e_preview_abi
  check "window animations enabled" "window animations unavailable; grant Screen Recording and restart yabai" \
    animations_on
  check "window borders running" "window borders are not running" \
    pgrep -x borders

  local spaces labels normal_spaces
  spaces="$(wait_for_yabai_spaces)"
  labels="$(jq '[.[] | select(."is-native-fullscreen" == false and (.label | test("^ws-[1-9]$")))] | length' <<<"$spaces" 2>/dev/null || echo 0)"
  normal_spaces="$(jq '[.[] | select(."is-native-fullscreen" == false)] | length' <<<"$spaces" 2>/dev/null || echo 0)"

  check "yabai can query windows and Spaces (Accessibility granted)" "yabai cannot query Spaces; grant Accessibility permission" \
    test "$spaces" != "[]"
  check "BSP layout loaded" "BSP layout is not active" \
    test "$(yabai -m config layout 2>/dev/null || true)" = bsp
  check "all $normal_spaces normal Spaces have stable ws-N labels" "only $labels of $normal_spaces normal Spaces have stable ws-N labels" \
    test "$normal_spaces" -gt 0 -a "$labels" -eq "$normal_spaces"
  check "$normal_spaces normal Spaces available" "only $normal_spaces normal Spaces available; expected at least 7" \
    test "$normal_spaces" -ge 7

  echo ""
  info "Shortcut reference: $DOTFILES_DIR/docs/macos-window-management.md"
}
