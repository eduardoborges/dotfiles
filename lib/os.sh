# ------------------------------------------------------------------------------
# OS detection: macOS and Linux share most configs, but some packages
# (Hyprland, waybar, wireplumber, system modprobe) only make sense on Linux.
# ------------------------------------------------------------------------------
case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *)      OS=unknown ;;
esac

# Packages stowed on every OS
COMMON_PACKAGES=(zsh starship alacritty ghostty zed vscode agent-skills agent-instructions claude git)
# Packages stowed only on macOS
MACOS_PACKAGES=(skhd yabai borders)
# Packages stowed only on Linux (Hyprland desktop stack + audio tweaks)
LINUX_PACKAGES=(hypr waybar wireplumber)

if [[ "$OS" == "linux" ]]; then
  PACKAGES=("${COMMON_PACKAGES[@]}" "${LINUX_PACKAGES[@]}")
elif [[ "$OS" == "macos" ]]; then
  PACKAGES=("${COMMON_PACKAGES[@]}" "${MACOS_PACKAGES[@]}")
else
  PACKAGES=("${COMMON_PACKAGES[@]}")
fi
