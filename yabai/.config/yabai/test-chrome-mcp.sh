#!/usr/bin/env bash
set -uo pipefail

# Launch wrapper for the chrome-devtools MCP. A Chrome started by the MCP itself
# never registers with the accessibility API, so yabai can't move its windows.
# This script opens Chrome for Testing through LaunchServices instead, and the
# test_chrome_ws7 signal in .yabairc moves its windows to ws-7. Every MCP
# connects to that one Chrome with --browserUrl. An MCP launch starts Chrome if
# it isn't running. Quit it and it stays closed until the next one.
#
# A foreground new_page activates Chrome, and macOS jumps to ws-7. A PreToolUse
# hook in settings.json forces background: true so that doesn't happen.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

PORT="${TEST_CHROME_PORT:-9223}"
URL="http://127.0.0.1:$PORT"
PROFILE="${TEST_CHROME_PROFILE:-$HOME/.cache/chrome-devtools-mcp/chrome-profile}"
LOG="$HOME/.cache/chrome-devtools-mcp/test-chrome.log"
LOCK="$HOME/.cache/chrome-devtools-mcp/launch.lock"
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
  # --test-type=gpu is the only switch that skips the "only for automated testing"
  # infobar (chrome/browser/ui/startup/infobar_utils.cc). The other three keep
  # Chrome painting pages in the windows parked on ws-7, so screenshots work
  # while I'm on another Space.
  open -gna "$(cft_app)" --args --user-data-dir="$PROFILE" --remote-debugging-port="$PORT" --test-type=gpu \
    --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-background-timer-throttling \
    --no-first-run --no-default-browser-check about:blank
  for _ in $(seq 1 40); do chrome_up && return 0; sleep 0.25; done
  echo "test Chrome did not answer on $URL"
  return 1
}

if [[ "${1:-}" == --start ]]; then
  start_chrome
  exit
fi

# Two sessions starting together would both find Chrome down, and the second
# would kill the Chrome the first had just opened. The lock makes them take turns.
# Nothing here may write to stdout, which is the MCP's protocol channel.
lockf -k -t 30 "$LOCK" "$0" --start </dev/null >>"$LOG" 2>&1

exec npx -y chrome-devtools-mcp@latest --browserUrl "$URL" "$@"
