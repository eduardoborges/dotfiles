#!/usr/bin/env bash
set -uo pipefail

# Launch wrapper for the chrome-devtools MCP. It runs Chrome for Testing
# headless on a fixed port and profile, and the MCP connects with --browserUrl.
# Headless because on macOS Chrome only adds a tab to a window on the active
# Space: with a visible window parked elsewhere, every new_page opened another
# window and pulled focus to it. Chrome starts once per MCP launch, and if you
# quit it, it stays closed.
#
# To log in to a site, run this script with --login. It restarts Chrome headed
# on the same profile and exits. Quit that Chrome when you're done; the cookies
# stay in the profile.

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

HEADLESS=--headless

start_chrome() {
  chrome_up && return 0
  # A Chrome left on this profile without the debug port (the old pipe launch)
  # holds the profile lock and would swallow the new launch.
  if pkill -f -- "--user-data-dir=$PROFILE( |$)"; then sleep 1; fi
  [[ -n "$(cft_app)" ]] || npx -y @puppeteer/browsers install chrome@stable --path "$CFT_DIR"
  # --test-type=gpu is the only switch that skips the "only for automated testing"
  # infobar (chrome/browser/ui/startup/infobar_utils.cc).
  open -gna "$(cft_app)" --args --user-data-dir="$PROFILE" --remote-debugging-port="$PORT" --test-type=gpu \
    --no-first-run --no-default-browser-check $HEADLESS about:blank
  for _ in $(seq 1 40); do chrome_up && return 0; sleep 0.25; done
  echo "test Chrome did not answer on $URL"
  return 1
}

if [[ "${1:-}" == --login ]]; then
  pkill -f -- "--user-data-dir=$PROFILE( |$)" && sleep 1
  HEADLESS=
  start_chrome
  exit
fi

# Nothing here may write to stdout, which is the MCP's protocol channel.
start_chrome </dev/null >>"$LOG" 2>&1

exec npx -y chrome-devtools-mcp@latest --browserUrl "$URL" "$@"
