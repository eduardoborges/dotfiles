# ------------------------------------------------------------------------------
# dependency: stow
# ------------------------------------------------------------------------------
need_stow() {
  if ! command -v stow &>/dev/null; then
    echo "GNU Stow is not installed."
    if command -v brew &>/dev/null; then
      echo "Installing with: brew install stow"
      brew install stow
    else
      echo "Install the 'stow' package and run this script again."
      exit 1
    fi
  fi
}

# ------------------------------------------------------------------------------
# remove only what we're going to replace with symlinks
# ------------------------------------------------------------------------------
remove_targets_for_stow() {
  echo "Removing files/dirs that will be replaced by symlinks..."
  rm -f "$HOME/.zshrc"
  rm -f "$HOME/.config/git/config"
  rm -f "$HOME/.config/starship.toml"
  rm -rf "$HOME/.config/alacritty"
  rm -rf "$HOME/.config/ghostty"
  rm -f "$HOME/.config/zed/keymap.json"
  rm -f "$HOME/Library/Application Support/Code/User/settings.json"
  rm -f "$HOME/Library/Application Support/Code - Insiders/User/settings.json"
  rm -f "$HOME/Library/Application Support/VSCodium - Insiders/User/settings.json"
  rm -rf "$HOME/.agents"
  rm -f "$HOME/.codex/AGENTS.md"
  rm -f "$HOME/.claude/CLAUDE.md"
  rm -f "$HOME/.claude/settings.json"
  rm -f "$HOME/.claude/statusline-command.sh"
}

# ------------------------------------------------------------------------------
# stow
# ------------------------------------------------------------------------------
stow_package_safely() {
  local pkg="$1"
  local package_dir="$DOTFILES_DIR/$pkg"
  local safety_dir="$BACKUP_DIR/pre-stow/$pkg"
  local src relative dest saved
  local -a preserved_destinations=()
  local -a preserved_files=()

  # Preserve only exact file conflicts. Directories are intentionally left in
  # place because Stow can merge package trees into existing directories.
  while IFS= read -r src; do
    relative="${src#"$package_dir"/}"
    dest="$HOME/$relative"

    if [[ (-e "$dest" || -L "$dest") && ! "$src" -ef "$dest" ]]; then
      saved="$safety_dir/$relative"
      mkdir -p "$(dirname "$saved")"
      mv "$dest" "$saved"
      preserved_destinations+=("$dest")
      preserved_files+=("$saved")
      echo "    preserved conflict: $dest -> $saved"
    fi
  done < <(find "$package_dir" -type f)

  if stow -d "$DOTFILES_DIR" -t "$HOME" "$pkg"; then
    return 0
  fi

  echo "  stow $pkg failed; restoring preserved files."
  stow -d "$DOTFILES_DIR" -t "$HOME" -D "$pkg" 2>/dev/null || true

  local i
  for ((i = 0; i < ${#preserved_files[@]}; i++)); do
    mkdir -p "$(dirname "${preserved_destinations[$i]}")"
    mv "${preserved_files[$i]}" "${preserved_destinations[$i]}"
  done
  return 1
}

run_stow() {
  echo ""
  echo "Running stow from $DOTFILES_DIR to $HOME"
  for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
      echo "  stow $pkg"
      if [[ "$pkg" == "skhd" || "$pkg" == "yabai" ]]; then
        stow_package_safely "$pkg"
      else
        stow -d "$DOTFILES_DIR" -t "$HOME" "$pkg"
      fi
    else
      echo "  (skipping $pkg - directory does not exist)"
    fi
  done
  echo ""
  echo "Done. Configs installed via symlinks."
}

# ------------------------------------------------------------------------------
# unstow a single package
# ------------------------------------------------------------------------------
run_unstow() {
  local pkg="${1:-}"
  if [[ -z "$pkg" ]]; then
    echo "Available packages: ${PACKAGES[*]}"
    echo "Usage: $0 --unstow <package>"
    exit 1
  fi
  if [[ ! -d "$DOTFILES_DIR/$pkg" ]]; then
    echo "Unknown package: $pkg (directory $DOTFILES_DIR/$pkg does not exist)"
    echo "Available packages: ${PACKAGES[*]}"
    exit 1
  fi
  need_stow
  echo "Unstowing $pkg..."
  stow -d "$DOTFILES_DIR" -t "$HOME" -D "$pkg"
  echo "Done. $pkg has been unstowed."
  if [[ "$pkg" == "yabai" ]]; then
    remove_yabai_login_bootstrap
  fi
}

# skills/ is not a stow package: it is linked wholesale into each agent's skills dir
link_skills() {
  for target in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
    mkdir -p "$(dirname "$target")"
    if [[ -e "$target" && ! -L "$target" ]]; then
      echo "  (skipping $target - exists and is not a symlink)"
      continue
    fi
    ln -sfn "$DOTFILES_DIR/skills" "$target"
    echo "  link $target -> $DOTFILES_DIR/skills"
  done
}
