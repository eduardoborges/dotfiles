backup_extensions() {
  local cli="$1"
  local backup_file="$2"
  local label="$3"

  if ! command -v "$cli" &>/dev/null; then
    echo "  skipping $label extensions backup ($cli not found)"
    return 0
  fi

  mkdir -p "$(dirname "$backup_file")"
  "$cli" --list-extensions | sort -u >"$backup_file"
  echo "  saved $label extensions -> $backup_file"
}

save_vscode_extensions() {
  local output_file="$1"

  if command -v code &>/dev/null; then
    backup_extensions code "$output_file" "VS Code"
    return 0
  fi

  echo "  skipping VS Code extensions backup (code not found)"
}

save_editor_extensions() {
  echo ""
  echo "Saving the shared editor extension list from VS Code..."
  save_vscode_extensions "$VSCODE_EXTENSIONS_FILE"
  echo "Done."
}

install_extensions_from_file() {
  local cli="$1"
  local file="$2"
  local label="$3"
  local installed=0
  local failed=0
  local extension

  if ! command -v "$cli" &>/dev/null; then
    echo "  skipping $label extensions install ($cli not found)"
    return 0
  fi
  if [[ ! -f "$file" ]]; then
    echo "  skipping $label extensions install ($file not found)"
    return 0
  fi

  echo "  installing $label extensions from $file"
  while IFS= read -r extension; do
    [[ -z "$extension" ]] && continue
    [[ "$extension" == \#* ]] && continue
    if "$cli" --install-extension "$extension" --force &>/dev/null; then
      ((installed += 1))
    else
      echo "    failed: $extension"
      ((failed += 1))
    fi
  done <"$file"

  echo "    installed/updated: $installed | failed: $failed"
}

install_editor_extensions() {
  echo ""
  echo "Installing editor extensions from dotfiles..."
  install_extensions_from_file code "$VSCODE_EXTENSIONS_FILE" "VS Code"
}

# ------------------------------------------------------------------------------
# macOS default editor: VS Code
# ------------------------------------------------------------------------------
ensure_claude_code() {
  if command -v claude &>/dev/null; then
    return 0
  fi

  echo "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
}

ensure_code() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  if command -v code &>/dev/null; then
    return 0
  fi

  if ! command -v brew &>/dev/null; then
    echo "VS Code is not installed and Homebrew is unavailable."
    return 1
  fi

  echo "Installing VS Code..."
  brew install --cask visual-studio-code
}

remove_vscodium() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi
  if ! command -v brew &>/dev/null; then
    return 0
  fi

  if brew list --cask vscodium@insiders &>/dev/null; then
    echo "Removing VSCodium Insiders..."
    brew uninstall --cask vscodium@insiders
  fi
  if brew list --cask vscodium &>/dev/null; then
    echo "Removing VSCodium..."
    brew uninstall --cask vscodium
  fi
  if brew list --cask visual-studio-code@insiders &>/dev/null; then
    echo "Removing VS Code Insiders..."
    brew uninstall --cask visual-studio-code@insiders
  fi
}

configure_macos_default_editor() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  if ! command -v code &>/dev/null; then
    echo "  skipping default editor setup (code not found)"
    return 0
  fi

  if ! command -v duti &>/dev/null; then
    if ! command -v brew &>/dev/null; then
      echo "  skipping macOS file associations (duti/Homebrew not found)"
      return 0
    fi
    echo "Installing duti for macOS file associations..."
    brew install duti
  fi

  local bundle_id="com.microsoft.VSCode"
  local failed=0
  local type
  for type in \
    .txt \
    .md \
    .json \
    .js \
    .jsx \
    .ts \
    .tsx \
    .sh \
    .zsh \
    .yaml \
    .yml \
    .xml \
    .csv; do
    if ! duti -s "$bundle_id" "$type" all; then
      echo "  warning: could not set VS Code as handler for $type"
      ((failed += 1))
    fi
  done

  if [[ "$failed" -eq 0 ]]; then
    echo "  VS Code configured as the default text/code editor."
  else
    echo "  VS Code file association setup finished with $failed warning(s)."
  fi
}
