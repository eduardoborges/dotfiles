#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

action="${1:-}"
direction="${2:-}"

case "$action" in
  create)
    yabai -m space --create
    sleep 0.3
    "$HOME/.config/yabai/label-spaces.sh"
    yabai -m space --focus last
    ;;
  destroy)
    yabai -m space --destroy
    "$HOME/.config/yabai/label-spaces.sh"
    ;;
  move)
    case "$direction" in
      prev|next) yabai -m space --move "$direction" ;;
      *) echo "usage: $0 move prev|next" >&2; exit 2 ;;
    esac
    ;;
  display)
    case "$direction" in
      west|east) yabai -m space --display "$direction" ;;
      *) echo "usage: $0 display west|east" >&2; exit 2 ;;
    esac
    ;;
  *)
    echo "usage: $0 create|destroy|move prev|next|display west|east" >&2
    exit 2
    ;;
esac
