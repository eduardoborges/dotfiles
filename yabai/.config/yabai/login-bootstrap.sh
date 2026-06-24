#!/usr/bin/env bash
set -u

# launchd runs this shortly after login. Homebrew's services normally start
# yabai/skhd themselves; this bootstrap repairs startup races and prepares
# dynamic Space metadata after Dock/WindowServer are ready.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
uid="$(id -u)"
log="/tmp/yabai-login-bootstrap_${USER}.log"

exec >>"$log" 2>&1
echo "[$(date '+%Y-%m-%d %H:%M:%S')] bootstrap starting"

for _attempt in {1..30}; do
  if pgrep -x Dock >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! yabai -m query --spaces >/dev/null 2>&1; then
  launchctl kickstart -k "gui/$uid/com.asmvik.yabai" 2>/dev/null || true
fi

sudo -n yabai --load-sa 2>/dev/null || true

if ! launchctl print "gui/$uid/com.koekeishiya.skhd" 2>/dev/null |
  grep -q 'state = running'; then
  launchctl kickstart -k "gui/$uid/com.koekeishiya.skhd" 2>/dev/null || true
fi

for _attempt in {1..30}; do
  if yabai -m query --spaces >/dev/null 2>&1; then
    sudo -n yabai --load-sa 2>/dev/null || true
    "$HOME/.config/yabai/ensure-spaces.sh" 7 || true
    "$HOME/.config/yabai/label-spaces.sh" || true
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] bootstrap complete"
    exit 0
  fi
  sleep 1
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] yabai unavailable after timeout"
exit 1
