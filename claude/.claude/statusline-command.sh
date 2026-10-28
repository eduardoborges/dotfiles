#!/usr/bin/env bash
shopt -s extglob
input=$(cat)

# Emoji icons
I_DIR='📁'
I_BRANCH='🌿'
I_NODE='⬢'
I_MODEL='🤖'
I_CTX='🧠'
I_5H='⏱️'
I_7D='📅'
I_EFFORT='⚡️'
I_TODO='📋'

# Every input field in one jq call; \x1f keeps empty fields in place (tab is whitespace and would collapse)
IFS=$'\x1f' read -r cwd model used_pct five_hour_pct five_hour_reset seven_day_pct seven_day_reset effort session_id \
  cc_version fast_mode sess_name transcript cost dur_ms c_new c_write c_read ctx_size <<<"$(echo "$input" | jq -r '
  (.context_window.current_usage // {}) as $u
  | [(.workspace.current_dir // .cwd), (.model.display_name // "" | gsub(" *\\([^)]*\\)"; "")),
     .context_window.used_percentage, .rate_limits.five_hour.used_percentage, .rate_limits.five_hour.resets_at,
     .rate_limits.seven_day.used_percentage, .rate_limits.seven_day.resets_at, .effort.level, .session_id,
     .version, (.fast_mode // false), .session_name, .transcript_path,
     .cost.total_cost_usd, .cost.total_duration_ms, ($u.input_tokens // 0), ($u.cache_creation_input_tokens // 0),
     ($u.cache_read_input_tokens // 0), (.context_window.context_window_size // 0)]
  | map(. // "" | tostring) | join("\u001f")')"

# abtop reads rate limits from this file; `abtop --setup` would want the statusLine slot for itself
[ -n "$five_hour_pct$seven_day_pct" ] && echo "$input" | jq -c '{source: "claude", updated_at: (now | floor)}
  + (.rate_limits | {five_hour, seven_day} | with_entries(select(.value)) | map_values({used_percentage, resets_at}))' \
  > "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/abtop-rate-limits.json"

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
    [ "$untracked" -gt 0 ] && git_status+=" \033[35m?${untracked}\033[0m"
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
  # Divergence from the default branch, for feature branches and worktrees
  default_ref=$(git -C "$cwd" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
  if [ -n "$default_ref" ] && [ "$branch" != "${default_ref#origin/}" ]; then
    read -r base_ahead base_behind <<<"$(git -C "$cwd" rev-list --left-right --count "HEAD...$default_ref" 2>/dev/null)"
  fi
  stash_count=$(git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
  last_commit=$(git -C "$cwd" log -1 --format=%ct 2>/dev/null)
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
  local pct=$1 width=${2:-10}
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

# Claude Code indents the statusline 2 cols and cuts it 2 cols short of the right edge, plus 1 col of slack
W=$(( ${COLUMNS:-80} - 5 ))

# Columns a part takes: its text plus one emoji (1 char, 2 cols); U+FE0F and bar markers take none
seg_width() {
  local s=${1//$'\e['*([0-9;])m/}
  s=${s//@BAR:*([0-9])@/}
  s=${s//$'\xef\xb8\x8f'/}
  REPLY=$(( ${#s} + 1 ))
}

# Wraps part widths into $W columns with " | " between them, breaking where the next part won't fit.
# Sets brk (1 where a part starts a line), n_lines and max_w
layout() {
  local w=0 x
  brk=() n_lines=0 max_w=0
  for x in "$@"; do
    if [ "$n_lines" -gt 0 ] && [ $((w + 3 + x)) -le "$W" ]; then
      w=$((w + 3 + x)); brk+=(0)
    else
      w=$x; n_lines=$((n_lines + 1)); brk+=(1)
    fi
    [ "$w" -gt "$max_w" ] && max_w=$w
  done
}

# join_parts, wrapped at $W
wrap_parts() {
  local p i=0 ws=()
  for p in "$@"; do seg_width "$p"; ws+=("$REPLY"); done
  layout "${ws[@]}"
  for p in "$@"; do
    if [ "${brk[i]}" = 0 ]; then
      printf ' \033[2m|\033[0m %s' "$p"
    else
      [ "$i" -gt 0 ] && printf '\n'
      printf '%s' "$p"
    fi
    i=$((i + 1))
  done
}

# Swaps the @BAR:<pct>@ marker in a part for a bar $2 cells wide
fill_bar() {
  if [[ $1 =~ @BAR:([0-9]+)@ ]]; then
    printf '%s' "${1/@BAR:${BASH_REMATCH[1]}@/$(progress_bar "${BASH_REMATCH[1]}" "$2")}"
  else
    printf '%s' "$1"
  fi
}

# Line 1 — project info
line1=("$(printf '\033[34m%s %s\033[0m' "$I_DIR" "$display_cwd")")
[ -n "$proj" ] && line1+=("$(printf '\033[36m📦 %s\033[0m' "$proj")")
[ -n "$node_version" ] && line1+=("$(printf '\033[32m%s %s\033[0m' "$I_NODE" "$node_version")")
[ -n "$pkg_mgr" ] && line1+=("$(printf '\033[2m%s\033[0m' "$pkg_mgr")")
[ -n "$mise_seg" ] && line1+=("$mise_seg")
[ -n "$cc_version" ] && line1+=("$(printf '\033[2mv%s\033[0m' "$cc_version")")
[ -n "$sess_name" ] && line1+=("$(printf '\033[1;37m🏷️ %s\033[0m' "$sess_name")")

# Git line — worktree, branch with tree counts and upstream, default branch divergence, stash, last commit
line_git=()
if [ -n "$in_worktree" ]; then
  line_git+=("$(printf '\033[33m🌳 %s\033[0m \033[2m⇠ %s · %d wt\033[0m' "$(basename "$cur_toplevel")" "$repo_name" "$wt_count")")
fi
[ -n "$branch" ] && line_git+=("$(printf "\033[35m%s %s\033[0m${git_status}" "$I_BRANCH" "$branch")")
if [ -n "$base_ahead" ] && [ $((base_ahead + base_behind)) -gt 0 ]; then
  base_seg=$(printf '\033[2m🎯 %s\033[0m' "${default_ref#origin/}")
  [ "$base_ahead" -gt 0 ] && base_seg+=$(printf ' \033[36m+%d\033[0m' "$base_ahead")
  [ "$base_behind" -gt 0 ] && base_seg+=$(printf ' \033[31m-%d\033[0m' "$base_behind")
  line_git+=("$base_seg")
fi
[ "${stash_count:-0}" -gt 0 ] && line_git+=("$(printf '\033[33m🗃️ %d\033[0m' "$stash_count")")
if [ -n "$last_commit" ]; then
  age=$(( $(date +%s) - last_commit ))
  if [ "$age" -lt 3600 ]; then age="$((age / 60))m"
  elif [ "$age" -lt 86400 ]; then age="$((age / 3600))h"
  else age="$((age / 86400))d"; fi
  line_git+=("$(printf '\033[2m🕐 %s\033[0m' "$age")")
fi
[ -z "$in_worktree" ] && [ "${wt_count:-0}" -gt 0 ] && line_git+=("$(printf '\033[33m🌳 %d wt\033[0m' "$wt_count")")

# Model line — model, effort and session settings
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
[ "$fast_mode" = true ] && line2+=("$(printf '\033[93m🚀 fast\033[0m')")

# Usage line — cost, session time, rate limits, credits. Bars stay as @BAR:<pct>@ until the layout picks their width
line_usage=()

# Context — bar split into base / conversation / free, then the tokens used; joins the model line
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  if [ "$used_int" -ge 75 ]; then color='\033[31m'
  elif [ "$used_int" -ge 50 ]; then color='\033[33m'
  else color='\033[32m'; fi
  ctx_used=$((c_new + c_write + c_read))
  # Base = context of the session's first response: system prompt, tools, memory files and the first prompt.
  # ponytail: estimate measured once per session; /context has the real split but the statusline doesn't get it
  base_cache="${TMPDIR:-/tmp}/claude-ctx-base-$session_id"
  base=$(cat "$base_cache" 2>/dev/null)
  if [ -z "$base" ]; then
    base=$(grep '"isSidechain":false' "$transcript" 2>/dev/null | grep -m1 '"role":"assistant"' \
      | jq -r '.message.usage | (.input_tokens//0) + (.cache_creation_input_tokens//0) + (.cache_read_input_tokens//0)')
    [ -n "$base" ] && echo "$base" > "$base_cache"
  fi
  : "${base:=0}"
  [ "$base" -gt "$ctx_used" ] && base=$ctx_used
  if [ "$ctx_size" -gt 0 ]; then
    t_used=$(awk -v n="$ctx_used" 'BEGIN{print (n>=1e6?sprintf("%.1fM",n/1e6):n>=1e3?sprintf("%.1fk",n/1e3):n)}')
    ctx_color=$color
  fi
fi

[ -n "$cost" ] && line_usage+=("$(printf '\033[36m🪙 $%.2f\033[0m' "$cost")")

if [ -n "$dur_ms" ] && [ "$dur_ms" -gt 0 ] 2>/dev/null; then
  dur_s=$((dur_ms / 1000))
  line_usage+=("$(printf '\033[37m⏳ %dh%02d\033[0m' $((dur_s / 3600)) $(((dur_s % 3600) / 60)))")
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
  line_usage+=("$(printf "${color}%s @BAR:%d@ %d%%%s\033[0m" "$I_5H" "$five_int" "$five_int" "$reset_suffix")")
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
  line_usage+=("$(printf "${color}%s @BAR:%d@ %d%%%s\033[0m" "$I_7D" "$week_int" "$week_int" "$reset_suffix")")
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
        spent=$(awk "BEGIN{printf \"%.2f\", $used / 100}")
        total=$(awk "BEGIN{printf \"%.0f\", $limit / 100}")
        if [ "$pct" -ge 75 ]; then color='\033[31m'
        elif [ "$pct" -ge 50 ]; then color='\033[33m'
        else color='\033[32m'; fi
        seg=$(printf "${color}💳 @BAR:%d@ %d%% \$%s/\$%s\033[0m" "$pct" "$pct" "$spent" "$total")
      elif [ "$enabled" = "true" ]; then
        seg=$(printf '\033[32m💳 $%s used\033[0m' "$(awk -v x="$used" 'BEGIN{printf "%.2f", x / 100}')")
      else
        # no per-member allocation exposed: fall back to org prepaid balance if this seat can read it
        org=$(jq -r '.oauthAccount.organizationUuid // empty' "$CLAUDE_CONFIG_DIR/.claude.json" 2>/dev/null)
        if [ -n "$org" ]; then
          amt=$(curl -sf -m 4 -H "Authorization: Bearer $tok" -H "anthropic-beta: oauth-2025-04-20" \
            "https://api.anthropic.com/api/oauth/organizations/$org/prepaid/credits" | jq -r '.amount // empty')
          [ -n "$amt" ] && seg=$(printf '\033[32m💳 $%s org\033[0m' "$(awk -v x="$amt" 'BEGIN{printf "%.2f", x / 100}')")
        fi
      fi
    fi
    mkdir -p "${cred_cache%/*}" && printf '%s' "$seg" > "$cred_cache"
  fi
  credits_seg=$(cat "$cred_cache" 2>/dev/null)
  [ -n "$credits_seg" ] && line_usage+=("$credits_seg")
fi

# Todos for this session — header only, Claude Code already lists the items
todo_header=""
taskdir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/tasks/$session_id"
if [ -n "$session_id" ] && [ -d "$taskdir" ]; then
  read -r done total <<<"$(find "$taskdir" -maxdepth 1 -name '*.json' -exec cat {} + 2>/dev/null \
    | jq -rs 'map(select(.status)) | "\(map(select(.status == "completed")) | length) \(length)"')"
  [ "${total:-0}" -gt 0 ] && todo_header="$(printf '\033[36m%s %s %d/%d\033[0m' "$I_TODO" "$(progress_bar $(( done * 100 / total )))" "$done" "$total")"
fi

# Usage bars: the widest from 10 down to 4 cells that keeps the fewest lines
usage_w=0
if [ "${#line_usage[@]}" -gt 0 ]; then
  base_w=() has_bar=()
  for p in "${line_usage[@]}"; do
    seg_width "$p"; base_w+=("$REPLY")
    case $p in *@BAR:*) has_bar+=(1) ;; *) has_bar+=(0) ;; esac
  done
  best=99
  for ((bw = 10; bw >= 4; bw--)); do
    ws=()
    for i in "${!base_w[@]}"; do ws+=($(( base_w[i] + has_bar[i] * bw ))); done
    layout "${ws[@]}"
    [ "$n_lines" -lt "$best" ] && best=$n_lines && usage_bw=$bw && usage_w=$max_w
  done
  for i in "${!line_usage[@]}"; do line_usage[i]=$(fill_bar "${line_usage[i]}" "$usage_bw"); done
fi

# Context bar — ends in the same column as the usage line, or moves to its own line when it would get under 10 cells beside the model
if [ -n "$t_used" ]; then
  head_w=-3
  for p in "${line2[@]}"; do seg_width "$p"; head_w=$((head_w + 3 + REPLY)); done
  # 🧠 and a space each side of the bar
  fixed=$(( 4 + ${#t_used} ))
  target=$usage_w
  [ "$target" -eq 0 ] && target=$(( head_w + 3 + fixed + 31 ))
  bar_width=$(( target - head_w - 3 - fixed ))
  [ "$bar_width" -lt 10 ] && bar_width=10
  if [ $(( head_w + 3 + fixed + bar_width )) -gt "$W" ]; then
    bar_width=$(( (target < W ? target : W) - fixed ))
    [ "$bar_width" -lt 10 ] && bar_width=10
  fi
  used_cells=$(( (ctx_used * bar_width + ctx_size / 2) / ctx_size ))
  base_cells=$(( (base * bar_width + ctx_size / 2) / ctx_size ))
  [ "$base" -gt 0 ] && [ "$base_cells" -eq 0 ] && [ "$used_cells" -gt 0 ] && base_cells=1
  rep() { local i; for ((i = 0; i < $2; i++)); do printf '%s' "$1"; done; }
  line2+=("$(printf "%s \033[34m%s${ctx_color}%s\033[2m%s\033[0m ${ctx_color}%s\033[0m" \
    "$I_CTX" "$(rep ⣿ "$base_cells")" "$(rep ⣿ $((used_cells - base_cells)))" "$(rep ⣀ $((bar_width - used_cells)))" "$t_used")")
fi

join_parts "${line1[@]}"
if [ "${#line_git[@]}" -gt 0 ]; then
  printf '\n'
  join_parts "${line_git[@]}"
fi
printf '\n'
wrap_parts "${line2[@]}"
if [ "${#line_usage[@]}" -gt 0 ]; then
  printf '\n'
  wrap_parts "${line_usage[@]}"
fi
[ -n "$todo_header" ] && printf '\n%s' "$todo_header"
printf '\n'
