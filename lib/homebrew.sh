# ------------------------------------------------------------------------------
# Homebrew and Brewfile (macOS only)
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

  if [[ -n "$brew_bin" ]]; then
    eval "$("$brew_bin" shellenv)"
  fi
}

ensure_homebrew() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi

  load_homebrew_environment
  if command -v brew &>/dev/null; then
    return 0
  fi

  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew_environment

  if ! command -v brew &>/dev/null; then
    echo "Homebrew installation finished but brew is not available in PATH."
    exit 1
  fi
}

install_homebrew_bundle() {
  if [[ "$OS" != "macos" ]]; then
    return 0
  fi
  if [[ ! -f "$BREWFILE" ]]; then
    echo "Brewfile not found: $BREWFILE"
    return 1
  fi

  echo ""
  echo "Installing Homebrew packages from $BREWFILE..."
  brew bundle install --no-upgrade --file="$BREWFILE"
}

save_homebrew_bundle() {
  if [[ "$OS" != "macos" ]]; then
    echo "Brewfile inventory is only supported on macOS."
    return 1
  fi

  ensure_homebrew
  brew bundle dump --force --file="$BREWFILE"
  echo "Saved Homebrew inventory to $BREWFILE"
}
