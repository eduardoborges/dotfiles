#!/usr/bin/env sh

# Rex's menus are separate AXSystemDialog windows that close when they lose
# focus, and autofocus hands focus back to the Rex window under the cursor.
# Turn autofocus off while a menu has focus and back on for any other Rex window.

window="$(yabai -m query --windows --window "$YABAI_WINDOW_ID")" || exit 0

if [ "$(echo "$window" | jq -r .subrole)" = AXSystemDialog ]; then
  yabai -m config focus_follows_mouse off
else
  yabai -m config focus_follows_mouse autofocus
fi
