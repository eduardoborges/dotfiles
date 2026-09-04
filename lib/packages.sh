# ------------------------------------------------------------------------------
# The stow packages and the $HOME paths they own.
#
# Each package mirrors $HOME: dotfiles/<pkg>/<path> is linked to $HOME/<path>.
# That mapping is the only source of truth for what gets backed up, replaced and
# restored, so no step keeps a hand-written path list that can go stale.
# ------------------------------------------------------------------------------
PACKAGES=(
  agent-instructions
  alacritty
  borders
  claude
  ghostty
  git
  herdr
  skhd
  starship
  tmux
  vscode
  yabai
  zed
  zsh
)

package_dir() { echo "$DOTFILES_DIR/$1"; }

# every $HOME-relative path the packages own, one per line
package_targets() {
  local pkg dir
  for pkg in "${PACKAGES[@]}"; do
    dir="$(package_dir "$pkg")"
    [[ -d "$dir" ]] || continue
    find "$dir" \( -type f -o -type l \) -print | sed "s|^$dir/||"
  done
}
