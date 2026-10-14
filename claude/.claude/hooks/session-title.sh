#!/usr/bin/env bash
# SessionStart: title an unnamed session after the ticket code in the git branch,
# e.g. feature/ABC-123-auth-refactor -> "ABC-123 auth-refactor"
input=$(cat)
IFS=$'\x1f' read -r cwd title <<<"$(echo "$input" | jq -r '[.cwd // "", .session_title // ""] | join("\u001f")')"
[ -n "$title" ] && exit 0

branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
ticket=$(printf '%s' "$branch" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -1)
[ -z "$ticket" ] && exit 0

rest=${branch##*/}
rest=${rest/$ticket/}
rest=$(printf '%s' "$rest" | sed -E 's/^[-_]+|[-_]+$//g')
jq -n --arg t "$ticket${rest:+ $rest}" '{hookSpecificOutput: {hookEventName: "SessionStart", sessionTitle: $t}}'
