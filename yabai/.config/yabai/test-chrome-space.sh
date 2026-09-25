#!/usr/bin/env bash
set -euo pipefail

# Keep the chrome-devtools MCP browser (the test automation profile) on ws-7,
# away from the personal Chrome that shares the same app name. With a window id
# it moves that window; without one it sweeps every window of the test browser.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

PROFILE_MARK="chrome-devtools-mcp/chrome-profile"
TARGET_SPACE="ws-7"

move_if_test_chrome() {
  local id="$1" pid
  pid="$(yabai -m query --windows --window "$id" 2>/dev/null | jq -r '.pid // empty')" || return 0
  [[ -n "$pid" ]] || return 0
  ps -o command= -p "$pid" 2>/dev/null | grep -q -- "$PROFILE_MARK" || return 0
  yabai -m window "$id" --space "$TARGET_SPACE" 2>/dev/null || true
}

window_id="${1:-${YABAI_WINDOW_ID:-}}"
if [[ -n "$window_id" ]]; then
  move_if_test_chrome "$window_id"
else
  yabai -m query --windows | jq -r '.[] | select(.app == "Google Chrome") | .id' |
    while read -r id; do move_if_test_chrome "$id"; done
fi
