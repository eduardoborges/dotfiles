#!/usr/bin/env bash
input=$(cat)

# Emoji icons
I_DIR='📁'
I_BRANCH='🌿'
I_NODE='⬢'
I_MODEL='🤖'
I_CTX='🧠'
I_5H='⏱️'
I_7D='📅'
I_EFFORT='⚡'
I_TODO='📋'
I_DONE='✅'
I_PROG='🔄'
I_PEND='⬜'

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty' | sed -E 's/ *\([^)]*\)//g')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# Path relative to home
home="${HOME:-/home/$(id -un)}"
if [ "$cwd" = "$home" ]; then
  display_cwd="~"
elif [ "${cwd#$home/}" != "$cwd" ]; then
  display_cwd="~/${cwd#$home/}"
else
  display_cwd="$cwd"
fi

# Git branch + status (skip locks to avoid race conditions)
branch=""
git_status=""
if git_dir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null); then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  # Working tree counts: staged / modified / untracked
  porcelain=$(git -C "$cwd" status --porcelain 2>/dev/null)
  if [ -n "$porcelain" ]; then
    staged=$(echo "$porcelain" | grep -c '^[MADRC]')
    modified=$(echo "$porcelain" | grep -c '^.[MD]')
    untracked=$(echo "$porcelain" | grep -c '^??')
    git_status+=" \033[33m✗\033[0m"
    [ "$staged" -gt 0 ] && git_status+=" \033[32m●${staged}\033[0m"
    [ "$modified" -gt 0 ] && git_status+=" \033[33m~${modified}\033[0m"
    [ "$untracked" -gt 0 ] && git_status+=" \033[2m?${untracked}\033[0m"
  else
    git_status+=" \033[32m✓\033[0m"
  fi
  # Worktrees: current worktree info + count of linked worktrees
  cur_toplevel=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
  common_dir=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  abs_git_dir=$(git -C "$cwd" rev-parse --path-format=absolute --git-dir 2>/dev/null)
  in_worktree=""
  repo_name=""
  if [ -n "$common_dir" ] && [ "$abs_git_dir" != "$common_dir" ]; then
    in_worktree=1
    repo_name=$(basename "$(dirname "$common_dir")")
  fi
  wt_count=$(git -C "$cwd" worktree list --porcelain 2>/dev/null | grep -c '^worktree ')
  wt_count=$((wt_count - 1))
  # Ahead/behind upstream
  if upstream=$(git -C "$cwd" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null); then
    counts=$(git -C "$cwd" rev-list --left-right --count "HEAD...$upstream" 2>/dev/null)
    ahead=$(echo "$counts" | awk '{print $1}')
    behind=$(echo "$counts" | awk '{print $2}')
    [ -n "$ahead" ] && [ "$ahead" -gt 0 ] && git_status+=" \033[36m↑${ahead}\033[0m"
    [ -n "$behind" ] && [ "$behind" -gt 0 ] && git_status+=" \033[31m↓${behind}\033[0m"
  fi
fi

# Mise: are the current dir's tools installed and in sync?
mise_seg=""
if command -v mise >/dev/null 2>&1; then
  mise_json=$(mise -C "$cwd" ls --current --json 2>/dev/null)
  if [ -n "$mise_json" ] && [ "$mise_json" != "{}" ]; then
    missing=$(echo "$mise_json" | jq '[.[][] | select(.installed == false)] | length' 2>/dev/null)
    if [ "$missing" = "0" ]; then
      mise_seg="$(printf '\033[32m🧰 mise ✓\033[0m')"
    elif [ -n "$missing" ]; then
      missing_names=$(echo "$mise_json" | jq -r '[to_entries[] | select(.value[] | .installed == false) | .key] | join(",")' 2>/dev/null)
      mise_seg="$(printf '\033[31m🧰 mise ✗ %s\033[0m' "$missing_names")"
    fi
  fi
fi

# Project info: name@version, runtime, package manager
proj=""
node_version=""
pkg_mgr=""
if [ -f "$cwd/package.json" ]; then
  node_version=$(node --version 2>/dev/null)
  if   [ -f "$cwd/bun.lock" ] || [ -f "$cwd/bun.lockb" ]; then pkg_mgr="bun"
  elif [ -f "$cwd/pnpm-lock.yaml" ]; then pkg_mgr="pnpm"
  elif [ -f "$cwd/yarn.lock" ]; then pkg_mgr="yarn"
  elif [ -f "$cwd/package-lock.json" ]; then pkg_mgr="npm"
  fi
elif [ -f "$cwd/Cargo.toml" ]; then
  proj=$(awk -F'"' '/^name *=/{n=$2} /^version *=/{v=$2} END{if(n)printf "%s@%s",n,v}' "$cwd/Cargo.toml" 2>/dev/null)
  pkg_mgr="cargo"
elif [ -f "$cwd/go.mod" ]; then
  proj=$(awk '/^module /{print $2; exit}' "$cwd/go.mod" 2>/dev/null | awk -F/ '{print $NF}')
  pkg_mgr="go"
elif [ -f "$cwd/pyproject.toml" ]; then
  proj=$(awk -F'"' '/^name *=/{n=$2} /^version *=/{v=$2} END{if(n)printf "%s@%s",n,v}' "$cwd/pyproject.toml" 2>/dev/null)
  pkg_mgr="python"
fi

# Progress bar — braille cells, 6 fill steps per cell for a smoother ramp
progress_bar() {
  local pct=$1 width=5
  local levels=(⣀ ⣄ ⣤ ⣦ ⣶ ⣷ ⣿)
  local total=$((width * 6)) filled i lvl
  filled=$(( (pct * total + 50) / 100 ))
  for ((i=0; i<width; i++)); do
    lvl=$(( filled - i*6 ))
    [ "$lvl" -lt 0 ] && lvl=0
    [ "$lvl" -gt 6 ] && lvl=6
    printf '%s' "${levels[$lvl]}"
  done
}

# Helper to join args with " | " separator
# (positional args instead of a nameref, so it works on bash 3.2 — macOS default)
join_parts() {
  [ "$#" -eq 0 ] && return
  printf '%s' "$1"
  shift
  for p in "$@"; do
    printf ' \033[2m|\033[0m %s' "$p"
  done
}

# Line 1 — project info
line1=()
if [ -n "$in_worktree" ]; then
  line1+=("$(printf '\033[33m🌳 %s\033[0m \033[2m⇠ %s · %d wt\033[0m' "$(basename "$cur_toplevel")" "$repo_name" "$wt_count")")
else
  line1+=("$(printf '\033[34m%s %s\033[0m' "$I_DIR" "$display_cwd")")
  [ "${wt_count:-0}" -gt 0 ] && line1+=("$(printf '\033[33m🌳 %d wt\033[0m' "$wt_count")")
fi
[ -n "$proj" ] && line1+=("$(printf '\033[36m📦 %s\033[0m' "$proj")")
[ -n "$node_version" ] && line1+=("$(printf '\033[32m%s %s\033[0m' "$I_NODE" "$node_version")")
[ -n "$pkg_mgr" ] && line1+=("$(printf '\033[2m%s\033[0m' "$pkg_mgr")")
[ -n "$mise_seg" ] && line1+=("$mise_seg")

# Git line — branch, tree counts, ahead/behind
line_git=()
[ -n "$branch" ] && line_git+=("$(printf "\033[35m%s %s\033[0m${git_status}" "$I_BRANCH" "$branch")")

# Line 2 — AI info
line2=()
[ -n "$model" ] && line2+=("$(printf '\033[36m%s %s\033[0m' "$I_MODEL" "$model")")
if [ -n "$effort" ]; then
  case "$effort" in
    max) ecolor='\033[35m' ;;
    xhigh) ecolor='\033[91m' ;;
    high) ecolor='\033[31m' ;;
    medium) ecolor='\033[33m' ;;
    low) ecolor='\033[32m' ;;
    *) ecolor='\033[37m' ;;
  esac
  line2+=("$(printf "${ecolor}%s %s\033[0m" "$I_EFFORT" "$effort")")
fi

if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  if [ "$used_int" -ge 75 ]; then color='\033[31m'
  elif [ "$used_int" -ge 50 ]; then color='\033[33m'
  else color='\033[32m'; fi
  line2+=("$(printf "${color}%s %s %d%%\033[0m" "$I_CTX" "$(progress_bar "$used_int")" "$used_int")")
fi

# Session tokens: sum of usage across the transcript, input + cache + output.
# ponytail: incremental, only bytes appended since last run get parsed; main transcript only, subagents not counted
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  tok_cache="${TMPDIR:-/tmp}/claude-tokens-$session_id"
  read -r off t_in t_out t_cache last_id 2>/dev/null < "$tok_cache"
  : "${off:=0}" "${t_in:=0}" "${t_out:=0}" "${t_cache:=0}" "${last_id:=-}"
  size=$(stat -f %z "$transcript")
  [ "$size" -lt "$off" ] && off=0 t_in=0 t_out=0 t_cache=0 last_id=-
  if [ "$size" -gt "$off" ]; then
    new_off=$size
    # last line still being written: leave it for the next run
    tail -c 1 "$transcript" | read -r _ || new_off=$((size - $(tail -n 1 "$transcript" | wc -c)))
    read -r d_in d_out d_cache new_last <<<"$(tail -c +$((off + 1)) "$transcript" \
      | jq -rR 'fromjson? | select(.type=="assistant") | .message
          | [.id, (.usage.input_tokens//0), (.usage.output_tokens//0), ((.usage.cache_creation_input_tokens//0)+(.usage.cache_read_input_tokens//0))] | @tsv' \
      | awk -v p="$last_id" '$1!=p{i+=$2;o+=$3;c+=$4;p=$1} END{print i+0,o+0,c+0,p}')"
    t_in=$((t_in + d_in)); t_out=$((t_out + d_out)); t_cache=$((t_cache + d_cache)); last_id=$new_last
    printf '%s %s %s %s %s' "$new_off" "$t_in" "$t_out" "$t_cache" "$last_id" > "$tok_cache"
  fi
  total=$((t_in + t_cache + t_out))
  cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
  if [ "$total" -gt 0 ]; then
    seg=$(awk -v n="$total" 'BEGIN{if(n>=1e6)printf "%.1fM",n/1e6; else if(n>=1e3)printf "%.1fk",n/1e3; else print n}')
    [ -n "$cost" ] && seg+=$(printf ' \033[2m·\033[0m $%.2f' "$cost")
    line2+=("$(printf '\033[36m🪙 %b\033[0m' "$seg")")
  fi
fi

if [ -n "$five_hour_pct" ]; then
  five_int=$(printf '%.0f' "$five_hour_pct")
  if [ "$five_int" -ge 75 ]; then color='\033[31m'
  elif [ "$five_int" -ge 50 ]; then color='\033[33m'
  else color='\033[32m'; fi
  reset_suffix=""
  if [ -n "$five_hour_reset" ]; then
    now=$(date +%s)
    diff=$((five_hour_reset - now))
    if [ "$diff" -gt 0 ]; then
      h=$((diff / 3600))
      m=$(((diff % 3600) / 60))
      reset_suffix=$(printf " (%dh%02d)" "$h" "$m")
    fi
  fi
  line2+=("$(printf "${color}%s %s %d%%%s\033[0m" "$I_5H" "$(progress_bar "$five_int")" "$five_int" "$reset_suffix")")
fi

if [ -n "$seven_day_pct" ]; then
  week_int=$(printf '%.0f' "$seven_day_pct")
  if [ "$week_int" -ge 75 ]; then color='\033[31m'
  elif [ "$week_int" -ge 50 ]; then color='\033[33m'
  else color='\033[32m'; fi
  reset_suffix=""
  if [ -n "$seven_day_reset" ]; then
    now=$(date +%s)
    diff=$((seven_day_reset - now))
    if [ "$diff" -gt 0 ]; then
      d=$((diff / 86400))
      h=$(((diff % 86400) / 3600))
      reset_suffix=$(printf " (%dd %dh)" "$d" "$h")
    fi
  fi
  line2+=("$(printf "${color}%s %s %d%%%s\033[0m" "$I_7D" "$(progress_bar "$week_int")" "$week_int" "$reset_suffix")")
fi

# Usage credits (Enterprise work profile) — not in the statusline stdin JSON,
# so fetch from the OAuth usage API. ponytail: 5 min file cache, statusline runs every ~300ms
if [[ "$CLAUDE_CONFIG_DIR" == *claude-work* ]]; then
  cred_cache="$CLAUDE_CONFIG_DIR/cache/credits-seg"
  cred_age=$(( $(date +%s) - $(stat -f %m "$cred_cache" 2>/dev/null || echo 0) ))
  if [ "$cred_age" -gt 300 ]; then
    seg=""
    # keychain service = "Claude Code-credentials-" + sha256(config dir)[:8]
    kc_suffix=$(printf '%s' "$CLAUDE_CONFIG_DIR" | shasum -a 256 | cut -c1-8)
    tok=$(security find-generic-password -s "Claude Code-credentials-$kc_suffix" -w 2>/dev/null)
    tok=$(printf '%s' "$tok" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    if [ -n "$tok" ]; then
      usage=$(curl -sf -m 4 -H "Authorization: Bearer $tok" -H "anthropic-beta: oauth-2025-04-20" \
        https://api.anthropic.com/api/oauth/usage)
      read -r enabled limit used <<<"$(printf '%s' "$usage" \
        | jq -r '.extra_usage // {} | "\(.is_enabled // false) \(.monthly_limit // 0) \(.used_credits // 0)"')"
      if [ "$enabled" = "true" ] && awk "BEGIN{exit !($limit > 0)}"; then
        pct=$(awk "BEGIN{printf \"%d\", $used * 100 / $limit}")
        remain=$(awk "BEGIN{printf \"%.2f\", ($limit - $used) / 100}")
        if [ "$pct" -ge 75 ]; then color='\033[31m'
        elif [ "$pct" -ge 50 ]; then color='\033[33m'
        else color='\033[32m'; fi
        seg=$(printf "${color}💳 %s %d%% (\$%s left)\033[0m" "$(progress_bar "$pct")" "$pct" "$remain")
      elif [ "$enabled" = "true" ]; then
        seg=$(printf '\033[32m💳 $%s used\033[0m' "$(awk "BEGIN{printf \"%.2f\", $used / 100}")")
      else
        # no per-member allocation exposed: fall back to org prepaid balance if this seat can read it
        org=$(jq -r '.oauthAccount.organizationUuid // empty' "$CLAUDE_CONFIG_DIR/.claude.json" 2>/dev/null)
        if [ -n "$org" ]; then
          amt=$(curl -sf -m 4 -H "Authorization: Bearer $tok" -H "anthropic-beta: oauth-2025-04-20" \
            "https://api.anthropic.com/api/oauth/organizations/$org/prepaid/credits" | jq -r '.amount // empty')
          [ -n "$amt" ] && seg=$(printf '\033[32m💳 $%s org\033[0m' "$(awk "BEGIN{printf \"%.2f\", $amt / 100}")")
        fi
      fi
    fi
    mkdir -p "${cred_cache%/*}" && printf '%s' "$seg" > "$cred_cache"
  fi
  credits_seg=$(cat "$cred_cache" 2>/dev/null)
  [ -n "$credits_seg" ] && line2+=("$credits_seg")
fi

# Todos for this session (~/.claude/tasks/$session_id/*.json) — one item per line
todo_header=""
todo_items=()
taskdir="$HOME/.claude/tasks/$session_id"
if [ -n "$session_id" ] && [ -d "$taskdir" ]; then
  done=0; prog=0; pend=0
  while IFS= read -r f; do
    [ -e "$f" ] || continue
    st=$(jq -r '.status // empty' "$f" 2>/dev/null)
    case "$st" in
      completed)   done=$((done+1)); icon="\033[32m$I_DONE"; text=$(jq -r '.subject // empty' "$f" 2>/dev/null) ;;
      in_progress) prog=$((prog+1)); icon="\033[33m$I_PROG"; text=$(jq -r '.activeForm // .subject // empty' "$f" 2>/dev/null) ;;
      *)           pend=$((pend+1)); icon="\033[2m$I_PEND"; text=$(jq -r '.subject // empty' "$f" 2>/dev/null) ;;
    esac
    [ -z "$st" ] && continue
    todo_items+=("$(printf '\033[2m│\033[0m %s %s\033[0m' "$icon" "$text")")
  done < <(find "$taskdir" -maxdepth 1 -name '*.json' 2>/dev/null | sort -V)
  total=$((done+prog+pend))
  [ "$total" -gt 0 ] && todo_header="$(printf '\033[2m╭─\033[0m \033[36m%s %s %d/%d\033[0m' "$I_TODO" "$(progress_bar $(( done * 100 / total )))" "$done" "$total")"
fi

join_parts "${line1[@]}"
if [ "${#line_git[@]}" -gt 0 ]; then
  printf '\n'
  join_parts "${line_git[@]}"
fi
printf '\n'
join_parts "${line2[@]}"
if [ -n "$todo_header" ]; then
  printf '\n%b' "$todo_header"
  for item in "${todo_items[@]}"; do
    printf '\n%b' "$item"
  done
  printf '\n\033[2m╰─\033[0m'
fi
printf '\n'
