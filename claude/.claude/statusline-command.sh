#!/usr/bin/env bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
effort=$(echo "$input" | jq -r '.effort_level // .effortLevel // empty')
[ -z "$effort" ] && effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)

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
  # Dirty working tree?
  if [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then
    git_status+=" \033[33m✗\033[0m"
  else
    git_status+=" \033[32m✓\033[0m"
  fi
  # Ahead/behind upstream
  if upstream=$(git -C "$cwd" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null); then
    counts=$(git -C "$cwd" rev-list --left-right --count "HEAD...$upstream" 2>/dev/null)
    ahead=$(echo "$counts" | awk '{print $1}')
    behind=$(echo "$counts" | awk '{print $2}')
    [ -n "$ahead" ] && [ "$ahead" -gt 0 ] && git_status+=" \033[36m↑${ahead}\033[0m"
    [ -n "$behind" ] && [ "$behind" -gt 0 ] && git_status+=" \033[31m↓${behind}\033[0m"
  fi
fi

# Node version (only when project looks like Node)
node_version=""
if [ -f "$cwd/package.json" ] || [ -f "$cwd/.nvmrc" ] || [ -f "$cwd/.node-version" ]; then
  node_version=$(node --version 2>/dev/null)
fi

# Progress bar — 10 cells, filled proportional to percentage
progress_bar() {
  local pct=$1 width=5 filled i
  filled=$(( (pct * width + 50) / 100 ))
  [ "$filled" -gt "$width" ] && filled=$width
  [ "$filled" -lt 0 ] && filled=0
  for ((i=0; i<filled; i++)); do printf '█'; done
  for ((i=filled; i<width; i++)); do printf '░'; done
}

# Helper to join array with " | " separator
join_parts() {
  local -n arr=$1
  [ ${#arr[@]} -eq 0 ] && return
  printf '%s' "${arr[0]}"
  for p in "${arr[@]:1}"; do
    printf ' \033[2m|\033[0m %s' "$p"
  done
}

# Line 1 — project info
line1=()
line1+=("$(printf '\033[34m📁 %s\033[0m' "$display_cwd")")
[ -n "$branch" ] && line1+=("$(printf "\033[35m %s\033[0m${git_status}" "$branch")")
[ -n "$node_version" ] && line1+=("$(printf '\033[32m⬢ %s\033[0m' "$node_version")")

# Line 2 — AI info
line2=()
[ -n "$model" ] && line2+=("$(printf '\033[36m🤖 %s\033[0m' "$model")")
if [ -n "$effort" ]; then
  case "$effort" in
    high) ecolor='\033[31m' ;;
    medium) ecolor='\033[33m' ;;
    low) ecolor='\033[32m' ;;
    *) ecolor='\033[37m' ;;
  esac
  line2+=("$(printf "${ecolor}⚡ %s\033[0m" "$effort")")
fi

if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  if [ "$used_int" -ge 75 ]; then color='\033[31m'
  elif [ "$used_int" -ge 50 ]; then color='\033[33m'
  else color='\033[32m'; fi
  line2+=("$(printf "${color}🧠 %s %d%%\033[0m" "$(progress_bar "$used_int")" "$used_int")")
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
  line2+=("$(printf "${color}⏰ %s %d%%%s\033[0m" "$(progress_bar "$five_int")" "$five_int" "$reset_suffix")")
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
  line2+=("$(printf "${color}📅 %s %d%%%s\033[0m" "$(progress_bar "$week_int")" "$week_int" "$reset_suffix")")
fi

join_parts line1
printf '\n'
join_parts line2
printf '\n'
