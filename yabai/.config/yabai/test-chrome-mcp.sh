#!/usr/bin/env bash
set -uo pipefail

# Launch wrapper for the chrome-devtools MCP. A Chrome started by the MCP itself
# never registers with the accessibility API, so yabai cannot move its windows.
# This script opens Chrome for Testing through LaunchServices instead, and the
# ws-7 signal in .yabairc picks up its windows. It is a separate app from the
# personal Chrome, so clicking Chrome in the Dock never lands on the test
# profile. The script keeps Chrome running while the MCP is up and points the
# MCP at it with --browserUrl.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

PORT="${TEST_CHROME_PORT:-9223}"
URL="http://127.0.0.1:$PORT"
PROFILE="${TEST_CHROME_PROFILE:-$HOME/.cache/chrome-devtools-mcp/chrome-profile}"
LOG="$HOME/.cache/chrome-devtools-mcp/test-chrome.log"
CFT_DIR="$HOME/.cache/chrome-for-testing"
mkdir -p "$PROFILE"

# Installed once and never updated. Delete $CFT_DIR to get the current stable.
cft_app() { compgen -G "$CFT_DIR/chrome/*/*/Google Chrome for Testing.app" | tail -1; }

chrome_up() { curl -fs "$URL/json/version" >/dev/null 2>&1; }

start_chrome() {
  chrome_up && return 0
  # A Chrome left on this profile without the debug port (the old pipe launch)
  # holds the profile lock and would swallow the new launch.
  if pkill -f -- "--user-data-dir=$PROFILE( |$)"; then sleep 1; fi
  [[ -n "$(cft_app)" ]] || npx -y @puppeteer/browsers install chrome@stable --path "$CFT_DIR"
  open -gna "$(cft_app)" --args --user-data-dir="$PROFILE" --remote-debugging-port="$PORT" \
    --no-first-run --no-default-browser-check about:blank
  for _ in $(seq 1 40); do chrome_up && return 0; sleep 0.25; done
  echo "test Chrome did not answer on $URL"
  return 1
}

start_chrome </dev/null >>"$LOG" 2>&1

# Reopen Chrome if it dies or gets updated mid-session; the MCP reconnects on its
# next call. Nothing here may write to stdout, which is the MCP's protocol channel.
(while sleep 5; do chrome_up || start_chrome; done) </dev/null >>"$LOG" 2>&1 &
supervisor=$!
trap 'kill "$supervisor" 2>/dev/null' EXIT

npx -y chrome-devtools-mcp@latest --browserUrl "$URL" "$@"
