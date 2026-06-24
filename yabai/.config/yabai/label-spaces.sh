#!/usr/bin/env bash
set -euo pipefail

# Give normal macOS Spaces stable labels without touching native-fullscreen
# Spaces. Existing labels are preserved; new Spaces receive the first free
# ws-N label.

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
used_labels="$(
  jq -r '.[] | select(."is-native-fullscreen" == false) | .label' <<<"$spaces" |
    grep -E '^ws-[1-9]$' || true
)"

while IFS= read -r space_index; do
  [[ -n "$space_index" ]] || continue

  for number in {1..9}; do
    label="ws-$number"
    if ! grep -qx "$label" <<<"$used_labels"; then
      if yabai -m space "$space_index" --label "$label" 2>/dev/null; then
        used_labels="${used_labels}${used_labels:+$'\n'}${label}"
      fi
      break
    fi
  done
done < <(
  jq -r '
    .[]
    | select(."is-native-fullscreen" == false and .label == "")
    | .index
  ' <<<"$spaces"
)
