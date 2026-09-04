# ------------------------------------------------------------------------------
# Symlinking: stow the packages into $HOME, and link the shared skills dir.
#
# Conflicting files are never deleted. They are moved into the backup dir before
# stow runs, and moved back if stow fails.
#
# --no-folding everywhere: without it stow links a whole directory when $HOME
# has no counterpart yet, and anything later written into that directory lands
# inside this repo instead of in $HOME.
# ------------------------------------------------------------------------------
STOW=(stow --no-folding -d "$DOTFILES_DIR" -t "$HOME")
need_stow() {
  command -v stow &>/dev/null && return 0

  command -v brew &>/dev/null || die "GNU Stow is missing and Homebrew is unavailable."
  info "installing stow..."
  brew install stow
}

# move aside the files stow would collide with, so it never fails on a conflict
preserve_conflicts() {
  local pkg="$1"
  local dir target relative dest saved
  dir="$(package_dir "$pkg")"

  while IFS= read -r target; do
    relative="${target#"$dir"/}"
    dest="$HOME/$relative"

    # already our symlink, or nothing there: leave it alone
    [[ -e "$dest" || -L "$dest" ]] || continue
    [[ "$target" -ef "$dest" ]] && continue

    saved="$BACKUP_DIR/pre-stow/$pkg/$relative"
    mkdir -p "$(dirname "$saved")"
    mv "$dest" "$saved"
    PRESERVED_DESTINATIONS+=("$dest")
    PRESERVED_FILES+=("$saved")
    info "preserved conflict: $dest -> $saved"
  done < <(find "$dir" -type f)
}

restore_conflicts() {
  local i
  for ((i = 0; i < ${#PRESERVED_FILES[@]}; i++)); do
    mkdir -p "$(dirname "${PRESERVED_DESTINATIONS[$i]}")"
    mv "${PRESERVED_FILES[$i]}" "${PRESERVED_DESTINATIONS[$i]}"
  done
}

stow_package() {
  local pkg="$1"
  local -a PRESERVED_DESTINATIONS=() PRESERVED_FILES=()

  preserve_conflicts "$pkg"
  "${STOW[@]}" "$pkg" && return 0

  warn "stow $pkg failed; restoring preserved files."
  "${STOW[@]}" -D "$pkg" 2>/dev/null || true
  restore_conflicts
  return 1
}

run_stow() {
  section "Linking packages into $HOME"
  local pkg
  for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$(package_dir "$pkg")" ]]; then
      info "stow $pkg"
      stow_package "$pkg"
    else
      warn "skipping $pkg (directory does not exist)"
    fi
  done
}

run_unstow() {
  local pkg="${1:-}"
  if [[ -z "$pkg" || ! -d "$(package_dir "$pkg")" ]]; then
    echo "Usage: $0 --unstow <package>"
    echo "Packages: ${PACKAGES[*]}"
    exit 1
  fi

  need_stow
  section "Unstowing $pkg"
  "${STOW[@]}" -D "$pkg"
  [[ "$pkg" == "yabai" ]] && remove_yabai_login_bootstrap
  ok "$pkg has been unstowed."
}

# skills/ is not a stow package: it is linked wholesale into each agent's dir
link_skills() {
  section "Linking agent skills"
  local target
  for target in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
    mkdir -p "$(dirname "$target")"
    if [[ -e "$target" && ! -L "$target" ]]; then
      warn "skipping $target (exists and is not a symlink)"
      continue
    fi
    ln -sfn "$DOTFILES_DIR/skills" "$target"
    info "$target -> $DOTFILES_DIR/skills"
  done
}
