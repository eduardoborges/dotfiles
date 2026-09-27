#!/usr/bin/env bash
set -euo pipefail

# Label the Nth normal Space ws-N, the same position the number shortcuts use.
# Native-fullscreen Spaces are skipped and lose any label they picked up.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

spaces=""
for _attempt in {1..30}; do
  candidate="$(yabai -m query --spaces 2>/dev/null || true)"
  if jq -e 'type == "array"' >/dev/null 2>&1 <<<"$candidate"; then
    spaces="$candidate"
    break
  fi
  sleep 1
done

[[ -n "$spaces" ]] || exit 1

# index, current label, wanted label. Fullscreen Spaces want no label.
plan="$(jq -r '
  [.[] | select(."is-native-fullscreen" == false)] as $normal
  | .[]
  | . as $s
  | ($normal | map(.index) | index($s.index)) as $pos
  | [.index, .label, (if $pos == null then "" else "ws-\($pos + 1)" end)]
  | join("|")
' <<<"$spaces")"

# Clear wrong labels before setting any, so two Spaces never share one.
while IFS='|' read -r index label want; do
  if [[ -n "$label" && "$label" != "$want" ]]; then
    yabai -m space "$index" --label "" 2>/dev/null || true
  fi
done <<<"$plan"
while IFS='|' read -r index label want; do
  if [[ -n "$want" && "$label" != "$want" ]]; then
    yabai -m space "$index" --label "$want" 2>/dev/null || true
  fi
done <<<"$plan"
