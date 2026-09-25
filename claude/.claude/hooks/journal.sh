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
    "$HOME/Projects/wc/"*) scope=Trabalho ;;
    *) scope=Pessoal ;;
  esac
  note="$VAULT/$scope/Diario/$(date +%F).md"
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
  create "$note" "$(printf -- '---\ndata: %s\nescopo: %s\n---\n## Tarefas\n%s\n\n## Registro' "$(date +%F)" "$scope" "$open")"
  if [[ $scope == Pessoal && ! -e "$VAULT/$scope/Projetos/$project.md" ]]; then
    remote=$(git -C "$root" remote get-url origin 2>/dev/null)
    kind=privado
    [[ $(gh repo view "$remote" --json visibility -q .visibility 2>/dev/null) == PUBLIC ]] && kind=oss
  fi
  create "$VAULT/$scope/Projetos/$project.md" "$(printf -- '---\nescopo: %s\ntipo: %s\npath: %s\n---' "$scope" "$kind" "$root")"
  [[ -n $ticket ]] && create "$VAULT/$scope/Tickets/$ticket.md" "$(printf -- '---\nprojeto: "[[%s]]"\n---' "$project")"
}

links() { echo "[[$project]]${ticket:+ [[$ticket]]}"; }

case ${1:-} in
  ctx)
    context "${2:-$PWD}"
    notes
    printf 'escopo=%s\nprojeto=%s\nticket=%s\nbranch=%s\nrepo=%s\nnota=%s\nevidencias=%s\n' "$scope" "$project" "$ticket" "$branch" "$root" "$note" "$VAULT/$scope/Evidencias/${ticket:-$project}"
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
      echo "- $(date +%H:%M) ▶ $(links)${branch:+ \`$branch\`}" >>"$note"
    else
      since=$(cat "$STATE/$sid" 2>/dev/null) || exit 0
      rm -f "$STATE/$sid"
      commits=$(git -C "$cwd" log --all --no-merges --since="@$since" \
        --author="$(git -C "$cwd" config user.email)" --format='  - `%h` %s' 2>/dev/null)
      [[ -n $commits ]] || exit 0
      notes
      printf -- '- %s ■ %s\n%s\n' "$(date +%H:%M)" "$(links)" "$commits" >>"$note"
    fi
    ;;
  *) echo "usage: $0 start|end|ctx [dir]" >&2; exit 1 ;;
esac
