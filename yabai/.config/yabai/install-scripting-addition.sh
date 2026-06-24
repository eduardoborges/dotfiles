#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

yabai_bin="$(command -v yabai)"
sudoers_file="/private/etc/sudoers.d/yabai"
hash="$(shasum -a 256 "$yabai_bin" | awk '{print $1}')"
target_user="${SUDO_USER:-$(stat -f '%Su' /dev/console)}"
rule="$target_user ALL=(root) NOPASSWD: sha256:$hash $yabai_bin --load-sa"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

printf '%s\n' "$rule" >"$tmp"
chmod 0440 "$tmp"

echo "Installing the yabai scripting-addition sudoers rule..."
if [[ "$(id -u)" -eq 0 ]]; then
  install -o root -g wheel -m 0440 "$tmp" "$sudoers_file"
  visudo -cf "$sudoers_file"
else
  sudo install -o root -g wheel -m 0440 "$tmp" "$sudoers_file"
  sudo visudo -cf "$sudoers_file"
fi

if [[ "$(sysctl -n kern.bootargs 2>/dev/null || true)" != *"-arm64e_preview_abi"* ]]; then
  echo "sudoers configured. Reboot once to activate -arm64e_preview_abi."
  exit 0
fi

if [[ "$(id -u)" -eq 0 ]]; then
  "$yabai_bin" --load-sa
else
  sudo "$yabai_bin" --load-sa
fi
echo "yabai scripting addition loaded."
