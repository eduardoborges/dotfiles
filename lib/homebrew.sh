# ------------------------------------------------------------------------------
# Homebrew: the bootstrap, and the Brewfile inventory in both directions.
# ------------------------------------------------------------------------------
load_homebrew_environment() {
  local brew_bin=""

  if command -v brew &>/dev/null; then
    brew_bin="$(command -v brew)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin="/opt/homebrew/bin/brew"
  elif [[ -x /usr/local/bin/brew ]]; then
    brew_bin="/usr/local/bin/brew"
  fi

  [[ -n "$brew_bin" ]] && eval "$("$brew_bin" shellenv)"
  return 0
}

ensure_homebrew() {
  load_homebrew_environment
  command -v brew &>/dev/null && return 0

  info "installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew_environment

  command -v brew &>/dev/null || die "Homebrew was installed but brew is not in PATH."
}

install_homebrew_bundle() {
  section "Installing Homebrew packages"
  [[ -f "$BREWFILE" ]] || die "Brewfile not found: $BREWFILE"
  brew bundle install --no-upgrade --file="$BREWFILE"
}

# Descriptions come along by default; VS Code extensions are tracked in
# extensions/vscode.txt instead, so they stay out of the Brewfile
save_homebrew_bundle() {
  ensure_homebrew
  brew bundle dump --force --no-vscode --file="$BREWFILE"
  ok "saved the Homebrew inventory to $BREWFILE"
}
