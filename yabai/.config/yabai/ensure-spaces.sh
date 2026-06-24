#!/usr/bin/env bash
set -euo pipefail

# Ensure there are at least N normal macOS Spaces. Native-fullscreen Spaces are
# ignored because they should not affect the logical number-row shortcuts.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

minimum="${1:-7}"

if [[ ! "$minimum" =~ ^[1-9]$ ]]; then
  echo "usage: $0 1-9" >&2
  exit 2
fi

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

query_spaces() {
  local candidate
  for _attempt in {1..10}; do
    candidate="$(yabai -m query --spaces 2>/dev/null || true)"
    if jq -e 'type == "array"' >/dev/null 2>&1 <<<"$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
    sleep 0.2
  done

  return 1
}

normal_space_count() {
  jq '[.[] | select(."is-native-fullscreen" == false)] | length'
}

spaces="$(query_spaces)" || exit 1
count="$(normal_space_count <<<"$spaces")"

while [[ "$count" -lt "$minimum" ]]; do
  yabai -m space --create >/dev/null
  sleep 0.3
  spaces="$(query_spaces)" || exit 1
  next_count="$(normal_space_count <<<"$spaces")"

  if [[ "$next_count" -le "$count" ]]; then
    echo "failed to create enough Spaces ($count/$minimum)" >&2
    exit 1
  fi

  count="$next_count"
done

"$HOME/.config/yabai/label-spaces.sh" || true
