# ------------------------------------------------------------------------------
# Terminal output. Every step talks through these, so the log looks the same
# no matter which lib printed the line.
# ------------------------------------------------------------------------------
if [[ -t 1 ]] && command -v tput &>/dev/null; then
  UI_BOLD="$(tput bold 2>/dev/null || true)"
  UI_DIM="$(tput dim 2>/dev/null || true)"
  UI_CYAN="$(tput setaf 6 2>/dev/null || true)"
  UI_RESET="$(tput sgr0 2>/dev/null || true)"
else
  UI_BOLD="" UI_DIM="" UI_CYAN="" UI_RESET=""
fi

# a new step in the install; everything below it is indented
section() {
  echo ""
  echo "${UI_BOLD}$*${UI_RESET}"
}

info() { echo "  $*"; }
ok()   { echo "  ✓ $*"; }
warn() { echo "  ⚠ $*"; }
die()  { echo "  ✗ $*" >&2; exit 1; }

banner() {
  echo ""
  echo "${UI_BOLD}${UI_CYAN}  ┌──────────────────────────────────────┐${UI_RESET}"
  echo "${UI_BOLD}${UI_CYAN}  │  eduardo's dotfiles  ·  install       │${UI_RESET}"
  echo "${UI_BOLD}${UI_CYAN}  └──────────────────────────────────────┘${UI_RESET}"
  echo "  ${UI_DIM}directory${UI_RESET}  $DOTFILES_DIR"
  echo "  ${UI_DIM}home${UI_RESET}       $HOME"
}
