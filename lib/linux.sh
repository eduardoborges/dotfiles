install_modprobe_configs() {
  # Linux-only: modprobe.d does not exist on macOS.
  if [[ "$OS" != "linux" ]]; then
    return 0
  fi

  local src="$DOTFILES_DIR/system/etc/modprobe.d/snd-hda-intel-disable-power-save.conf"
  local dest="/etc/modprobe.d/snd-hda-intel-disable-power-save.conf"

  if [[ ! -f "$src" ]]; then
    return 0
  fi

  echo ""
  echo "Installing system audio power-save config..."
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    echo "  already installed: $dest"
    return 0
  fi

  sudo install -Dm644 "$src" "$dest"
  echo "  installed: $dest"
}

# ------------------------------------------------------------------------------
# reload Hyprland config and restart waybar (only when running inside Hyprland)
# ------------------------------------------------------------------------------
reload_hypr_and_waybar() {
  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    return 0
  fi
  if command -v hyprctl &>/dev/null; then
    echo "Reloading Hyprland..."
    hyprctl reload 2>/dev/null && echo "  Hyprland config reloaded." || true
  fi
  if command -v waybar &>/dev/null; then
    echo "Restarting waybar..."
    pkill waybar 2>/dev/null || true
    sleep 0.5
    waybar &>/dev/null &
    echo "  Waybar restarted."
  fi
}
