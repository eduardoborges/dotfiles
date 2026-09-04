# ------------------------------------------------------------------------------
# Backup and restore. Both walk package_targets, so whatever the packages own
# today is exactly what gets saved and put back.
# ------------------------------------------------------------------------------
backup_dirs() {
  find "$HOME" -maxdepth 1 -type d -name '.dotfiles-backup-*' | sort -r
}

# the backup mirrors the absolute path: $BACKUP_DIR/Users/<me>/.zshrc
backup_if_exists() {
  local path="$1"
  local backup_path="${BACKUP_DIR}${path}"

  # symlinks are ours already; there is nothing of the user's to save
  [[ -e "$path" && ! -L "$path" ]] || return 0

  info "backup: $path"
  mkdir -p "$(dirname "$backup_path")"
  cp -a "$path" "$backup_path"
}

do_backup() {
  local answer path
  echo ""
  read -r -p "Back up current configs before installing? (y/N) " answer
  case "${answer:-n}" in
    y|Y) ;;
    *) info "skipping backup."; return 0 ;;
  esac

  section "Backing up to $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  while IFS= read -r path; do
    backup_if_exists "$HOME/$path"
  done < <(package_targets)
  save_editor_extensions "$BACKUP_DIR/vscode-extensions.txt"
}

# ------------------------------------------------------------------------------
# restore: unstow everything, then copy a backup back over $HOME
# ------------------------------------------------------------------------------
choose_backup() {
  local -a backups=()
  local dir choice i
  while IFS= read -r dir; do
    backups+=("$dir")
  done < <(backup_dirs)

  [[ ${#backups[@]} -gt 0 ]] || die "No backups found in $HOME (expected .dotfiles-backup-YYYYMMDD-HHMMSS)"

  echo "Available backups:" >&2
  for i in "${!backups[@]}"; do
    echo "  $((i + 1))) ${backups[$i]##*/}" >&2
  done
  echo "  0) Cancel" >&2
  echo "" >&2
  read -r -p "Restore which backup? (1-${#backups[@]}, or 0 to cancel) " choice

  [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 0 && choice <= ${#backups[@]})) || die "Invalid choice."
  [[ "$choice" -eq 0 ]] && { info "Cancelled." >&2; return 1; }

  echo "${backups[$((choice - 1))]}"
}

run_restore() {
  local restore_dir confirm pkg path src dest
  restore_dir="$(choose_backup)" || return 0

  echo ""
  echo "Restoring from: $restore_dir"
  echo "This unstows every package and copies the backup back into your home."
  read -r -p "Continue? (y/N) " confirm
  case "${confirm:-n}" in
    y|Y) ;;
    *) info "Cancelled."; return 0 ;;
  esac

  need_stow
  remove_yabai_login_bootstrap

  section "Unstowing packages"
  for pkg in "${PACKAGES[@]}"; do
    [[ -d "$(package_dir "$pkg")" ]] || continue
    "${STOW[@]}" -D "$pkg" 2>/dev/null || true
  done

  section "Copying files from the backup"
  while IFS= read -r path; do
    src="$restore_dir$HOME/$path"
    dest="$HOME/$path"
    [[ -e "$src" ]] || continue
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    info "restored: $path"
  done < <(package_targets)

  ok "Your previous configs are back; dotfiles are no longer symlinked."
}

run_list_backups() {
  local dir found=0
  echo "Backups in $HOME:"
  while IFS= read -r dir; do
    found=1
    info "${dir##*/}"
  done < <(backup_dirs)
  [[ "$found" -eq 1 ]] || info "none yet."
}
