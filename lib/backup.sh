# ------------------------------------------------------------------------------
# Paths we back up (relative to $HOME); same list used for restore
# ------------------------------------------------------------------------------
BACKUP_PATHS=(
  .zshrc
  .skhdrc
  .yabairc
  .config/git/config
  .config/starship.toml
  .config/hypr
  .config/waybar
  .config/alacritty
  .config/ghostty
  .config/zed/keymap.json
  Library/Application Support/Code/User/settings.json
  .agents
  .codex/AGENTS.md
  .claude/CLAUDE.md
  .claude/settings.json
  .claude/statusline-command.sh
  .config/wireplumber/wireplumber.conf.d/51-disable-analog-audio-suspend.conf
)

# ------------------------------------------------------------------------------
# optional backup of files that would be overwritten
# ------------------------------------------------------------------------------
backup_if_exists() {
  local path="$1"
  local backup_path="${BACKUP_DIR}${path}"
  if [[ -e "$path" && ! -L "$path" ]]; then
    echo "  backup: $path -> $backup_path"
    mkdir -p "$(dirname "$backup_path")"
    cp -a "$path" "$backup_path"
  fi
}

do_backup() {
  echo ""
  read -r -p "Back up current configs before installing? (y/N) " answer
  case "${answer:-n}" in
    y|Y)
      echo "Creating backup at: $BACKUP_DIR"
      mkdir -p "$BACKUP_DIR"
      for path in "${BACKUP_PATHS[@]}"; do
        backup_if_exists "$HOME/$path"
      done
      if command -v code &>/dev/null; then
        backup_extensions code "$BACKUP_DIR/vscode-extensions.txt" "VS Code"
      fi
      echo "Backup done."
      ;;
    *)
      echo "Skipping backup."
      ;;
  esac
}

# ------------------------------------------------------------------------------
# restore from a backup (unstow + copy backup files back)
# ------------------------------------------------------------------------------
run_restore() {
  local backup_base="$HOME"
  local backups=()
  local d
  while IFS= read -r d; do
    [[ -d "$d" ]] && backups+=("$d")
  done < <(find "$backup_base" -maxdepth 1 -type d -name '.dotfiles-backup-*' | sort -r)

  if [[ ${#backups[@]} -eq 0 ]]; then
    echo "No backups found in $backup_base (expected .dotfiles-backup-YYYYMMDD-HHMMSS)"
    exit 1
  fi

  echo "Available backups:"
  for i in "${!backups[@]}"; do
    echo "  $((i + 1))) ${backups[$i]##*/}"
  done
  echo "  0) Cancel"
  echo ""
  read -r -p "Restore which backup? (1-${#backups[@]}, or 0 to cancel) " choice

  if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 0 ]] || [[ "$choice" -gt ${#backups[@]} ]]; then
    echo "Invalid choice. Exiting."
    exit 1
  fi
  if [[ "$choice" -eq 0 ]]; then
    echo "Cancelled."
    exit 0
  fi

  local restore_dir="${backups[$((choice - 1))]}"
  echo ""
  echo "Restoring from: $restore_dir"
  echo "This will unstow all packages and copy files from the backup back to your home."
  read -r -p "Continue? (y/N) " confirm
  case "${confirm:-n}" in
    y|Y) ;;
    *) echo "Cancelled."; exit 0 ;;
  esac

  need_stow
  remove_yabai_login_bootstrap
  echo "Unstowing packages..."
  for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
      stow -d "$DOTFILES_DIR" -t "$HOME" -D "$pkg" 2>/dev/null || true
    fi
  done

  echo "Copying files from backup..."
  for path in "${BACKUP_PATHS[@]}"; do
    local src="$restore_dir/$path"
    local dest="$HOME/$path"
    if [[ -e "$src" ]]; then
      mkdir -p "$(dirname "$dest")"
      cp -a "$src" "$dest"
      echo "  restored: $path"
    fi
  done

  echo ""
  echo "Restore done. Your previous configs are back; dotfiles are no longer symlinked."
  reload_hypr_and_waybar
}

# ------------------------------------------------------------------------------
# list backup directories
# ------------------------------------------------------------------------------
run_list_backups() {
  local backup_base="$HOME"
  local backups=()
  local d
  while IFS= read -r d; do
    [[ -d "$d" ]] && backups+=("$d")
  done < <(find "$backup_base" -maxdepth 1 -type d -name '.dotfiles-backup-*' | sort -r)

  if [[ ${#backups[@]} -eq 0 ]]; then
    echo "No backups found in $backup_base (expected .dotfiles-backup-YYYYMMDD-HHMMSS)"
    return 0
  fi

  echo "Backups in $backup_base:"
  for i in "${!backups[@]}"; do
    echo "  $((i + 1))) ${backups[$i]##*/}"
  done
}
