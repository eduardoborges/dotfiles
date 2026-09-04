# ------------------------------------------------------------------------------
# VS Code: the binary, its extension list, and the system file associations.
# ------------------------------------------------------------------------------
ensure_code() {
  command -v code &>/dev/null && return 0

  command -v brew &>/dev/null || die "VS Code is missing and Homebrew is unavailable."
  info "installing VS Code..."
  brew install --cask visual-studio-code
}

ensure_claude_code() {
  command -v claude &>/dev/null && return 0

  info "installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
}

save_editor_extensions() {
  local output_file="${1:-$VSCODE_EXTENSIONS_FILE}"

  if ! command -v code &>/dev/null; then
    warn "skipping extension list (code not found)"
    return 0
  fi

  mkdir -p "$(dirname "$output_file")"
  code --list-extensions | sort -u >"$output_file"
  ok "saved extensions -> $output_file"
}

install_editor_extensions() {
  local extension installed=0 failed=0

  section "Installing VS Code extensions"
  if ! command -v code &>/dev/null; then
    warn "skipping (code not found)"
    return 0
  fi
  if [[ ! -f "$VSCODE_EXTENSIONS_FILE" ]]; then
    warn "skipping ($VSCODE_EXTENSIONS_FILE not found)"
    return 0
  fi

  while IFS= read -r extension; do
    [[ -z "$extension" || "$extension" == \#* ]] && continue
    if code --install-extension "$extension" --force &>/dev/null; then
      ((installed += 1))
    else
      warn "failed: $extension"
      ((failed += 1))
    fi
  done <"$VSCODE_EXTENSIONS_FILE"

  info "installed/updated: $installed | failed: $failed"
}

# make VS Code the handler for the text formats we open all day
configure_default_editor() {
  section "Setting VS Code as the default editor"
  if ! command -v code &>/dev/null; then
    warn "skipping (code not found)"
    return 0
  fi

  if ! command -v duti &>/dev/null; then
    if ! command -v brew &>/dev/null; then
      warn "skipping file associations (duti and Homebrew not found)"
      return 0
    fi
    info "installing duti..."
    brew install duti
  fi

  local type failed=0
  for type in .txt .md .json .js .jsx .ts .tsx .sh .zsh .yaml .yml .xml .csv; do
    duti -s com.microsoft.VSCode "$type" all || ((failed += 1))
  done

  if [[ "$failed" -eq 0 ]]; then
    ok "VS Code handles text and code files."
  else
    warn "$failed file association(s) could not be set."
  fi
}
