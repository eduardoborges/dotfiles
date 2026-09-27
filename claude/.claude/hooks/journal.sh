#!/usr/bin/env bash
# Logs Claude Code sessions to the Obsidian vault.
#   journal.sh start|end   hook mode, reads the hook JSON on stdin
#   journal.sh ctx [dir]   prints scope, project, ticket and today's note, for skills
set -uo pipefail

VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notas"
STATE="$HOME/.cache/journal"

context() {
  local common
  # A worktree resolves to its main repo, so herdr and claude worktrees land in the right project.
  if common=$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
    root=$(dirname "$common")
    branch=$(git -C "$1" branch --show-current 2>/dev/null)
  else
    root=$1 branch=
  fi
  project=$(basename "$root")
  ticket=$(grep -oE '[A-Z][A-Z0-9]+-[0-9]+' <<<"$branch" | head -1)
  case "$root/" in
    "$HOME/Projects/wc/"*) scope=Trabalho dir="💼 Trabalho" ;;
    *) scope=Pessoal dir="🏠 Pessoal" ;;
  esac
  note="$VAULT/$dir/📓 Diario/$(date +%F).md"
}

create() {
  [[ -e $1 ]] && return
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" >"$1"
}

notes() {
  local kind=trabalho remote prev open=
  if [[ ! -e $note ]]; then
    # Carry the open tasks over from the last day that has a note.
    prev=$(ls "$(dirname "$note")"/*.md 2>/dev/null | tail -1)
    [[ -n $prev ]] && open=$(grep -E '^- \[ \] ' "$prev")
  fi
  create "$note" "$(printf -- '---\ndata: %s\nescopo: %s\nprojetos: []\ntickets: []\n---\n# %s\n\n## Tarefas\n%s\n\n## Registro\n\n## Commits' \
    "$(date +%F)" "$scope" "$(title)" "$open")"
  if [[ $scope == Pessoal && ! -e "$VAULT/$dir/📁 Projetos/$project.md" ]]; then
    remote=$(git -C "$root" remote get-url origin 2>/dev/null)
    kind=privado
    [[ $(gh repo view "$remote" --json visibility -q .visibility 2>/dev/null) == PUBLIC ]] && kind=oss
  fi
  create "$VAULT/$dir/📁 Projetos/$project.md" "$(printf -- '---\nescopo: %s\ntipo: %s\npath: %s\n---' "$scope" "$kind" "$root")"
  [[ -n $ticket ]] && create "$VAULT/$dir/🎫 Tickets/$ticket.md" "$(printf -- '---\nprojeto: "[[%s]]"\n---' "$project")"
}

title() {
  local t
  t=$(LC_ALL=pt_BR.UTF-8 date '+%A, %-d de %B')
  echo "$(tr '[:lower:]' '[:upper:]' <<<"${t:0:1}")${t:1}"
}

# Adds a wikilink to a frontmatter list (projetos, tickets) once per day.
remember() {
  local key=$1 value="\"[[$2]]\""
  [[ -n $2 ]] || return 0
  grep -E "^$key:" "$note" | grep -qF "$value" && return
  sed -i '' -e "s/^$key: \[\]$/$key: [$value]/" -e t -e "s/^$key: \[\(.*\)\]$/$key: [\1, $value]/" "$note"
}

case ${1:-} in
  ctx)
    context "${2:-$PWD}"
    notes
    printf 'escopo=%s\nprojeto=%s\nticket=%s\nbranch=%s\nrepo=%s\nnota=%s\nevidencias=%s\n' "$scope" "$project" "$ticket" "$branch" "$root" "$note" "$VAULT/$dir/📸 Evidencias/${ticket:-$project}"
    ;;
  start | end)
    IFS=$'\t' read -r cwd sid < <(jq -r '[.cwd, .session_id] | @tsv')
    context "$cwd"
    # Log only projects under ~/Projects; sessions in $HOME or /tmp are noise.
    [[ $root == "$HOME/Projects/"* ]] || exit 0
    mkdir -p "$STATE"
    if [[ $1 == start ]]; then
      [[ -e $STATE/$sid ]] || date +%s >"$STATE/$sid"
      notes
      remember projetos "$project"
      remember tickets "$ticket"
    else
      since=$(cat "$STATE/$sid" 2>/dev/null) || exit 0
      rm -f "$STATE/$sid"
      notes
      remember tickets "$ticket"
      # Overlapping sessions see the same commits, so each hash is logged once.
      git -C "$cwd" log --all --no-merges --since="@$since" --author="$(git -C "$cwd" config user.email)" \
        --reverse --format='%h%x09%s' 2>/dev/null | while IFS=$'\t' read -r hash subject; do
        grep -qF "\`$hash\`" "$note" || echo "- [[$project]] · $subject \`$hash\`" >>"$note"
      done
    fi
    ;;
  *) echo "usage: $0 start|end|ctx [dir]" >&2; exit 1 ;;
esac
