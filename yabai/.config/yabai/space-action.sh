#!/usr/bin/env bash
set -euo pipefail

# Resolve logical Space numbers dynamically. This avoids depending on yabai
# labels, which macOS clears at login, and ignores native-fullscreen Spaces.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

action="${1:-}"
number="${2:-}"

if [[ "$action" != "focus" && "$action" != "move" ]]; then
  echo "usage: $0 focus|move 1-9" >&2
  exit 2
fi

if [[ ! "$number" =~ ^[1-9]$ ]]; then
  echo "Space number must be between 1 and 9" >&2
  exit 2
fi

spaces=""
for _attempt in {1..10}; do
  candidate="$(yabai -m query --spaces 2>/dev/null || true)"
  if jq -e 'type == "array"' >/dev/null 2>&1 <<<"$candidate"; then
    spaces="$candidate"
    break
  fi
  sleep 0.2
done

[[ -n "$spaces" ]] || exit 1

normal_count="$(
  jq '[.[] | select(."is-native-fullscreen" == false)] | length' <<<"$spaces"
)"

if [[ "$normal_count" -lt "$number" ]]; then
  "$HOME/.config/yabai/ensure-spaces.sh" "$number"
  spaces=""
  for _attempt in {1..10}; do
    candidate="$(yabai -m query --spaces 2>/dev/null || true)"
    if jq -e 'type == "array"' >/dev/null 2>&1 <<<"$candidate"; then
      spaces="$candidate"
      break
    fi
    sleep 0.2
  done
fi

[[ -n "$spaces" ]] || exit 1

target="$(
  jq -r --argjson position "$number" '
    [.[] | select(."is-native-fullscreen" == false)]
    | .[$position - 1].index // empty
  ' <<<"$spaces"
)"

[[ -n "$target" ]] || exit 1

if [[ "$action" == "focus" ]]; then
  yabai -m space --focus "$target"
else
  yabai -m window --space "$target"
  yabai -m space --focus "$target"
fi
