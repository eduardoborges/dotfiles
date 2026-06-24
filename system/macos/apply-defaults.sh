#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS defaults are only applicable on macOS."
  exit 0
fi

restart_ui() {
  killall SystemUIServer 2>/dev/null || true
  killall Dock 2>/dev/null || true
  killall Finder 2>/dev/null || true
}

apply_window_manager_defaults() {
  defaults write com.apple.dock mru-spaces -bool false
  defaults write com.apple.spaces spans-displays -bool false
  defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
  defaults write com.apple.finder CreateDesktop -bool true
}

disable_liquid_glass() {
  # The public system knob for toning down Liquid Glass is Reduce Transparency.
  defaults write com.apple.universalaccess reduceTransparency -bool true
  defaults write NSGlobalDomain AppleReduceTransparency -bool true
}

revert_liquid_glass() {
  defaults write com.apple.universalaccess reduceTransparency -bool false
  defaults write NSGlobalDomain AppleReduceTransparency -bool false
}

usage() {
  echo "Usage: $0 [--apply|--revert-liquid-glass|--no-restart]"
}

restart=true
action=apply

for arg in "$@"; do
  case "$arg" in
    --apply)
      action=apply
      ;;
    --revert-liquid-glass)
      action=revert-liquid-glass
      ;;
    --no-restart)
      restart=false
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      usage
      exit 1
      ;;
  esac
done

case "$action" in
  apply)
    apply_window_manager_defaults
    disable_liquid_glass
    echo "macOS defaults applied."
    ;;
  revert-liquid-glass)
    revert_liquid_glass
    echo "Liquid Glass transparency defaults restored."
    ;;
esac

if [[ "$restart" == "true" ]]; then
  restart_ui
fi
