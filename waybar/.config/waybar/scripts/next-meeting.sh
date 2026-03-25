#!/usr/bin/env bash
# Next Google Calendar event on Waybar (meetfy).

set -e

# Escape for JSON (used by early exits and main output)
escape_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

json=$(meetfy next --json 2>/dev/null) || true

if [[ -z "$json" ]]; then
  echo '{"text": "", "tooltip": "meetfy: no response (run meetfy auth?)"}'
  exit 0
fi

# Check success and whether a meeting exists
success=$(echo "$json" | jq -r '.success // false')
if [[ "$success" != "true" ]]; then
  err=$(echo "$json" | jq -r '.error // "unknown error"')
  echo "{\"text\": \"\", \"tooltip\": \"meetfy: $err\"}"
  exit 0
fi

meeting=$(echo "$json" | jq -r '.meeting')
if [[ "$meeting" == "null" ]] || [[ -z "$meeting" ]]; then
  : > /tmp/waybar-next-meeting-link
  empty_msg="No events today"
  empty_tip="No upcoming events in the period meetfy searches"
  text_escaped=$(escape_json "$empty_msg")
  tooltip_escaped=$(escape_json "$empty_tip")
  echo "{\"text\": \"$text_escaped\", \"tooltip\": \"$tooltip_escaped\"}"
  exit 0
fi

title=$(echo "$json" | jq -r '.meeting.title // "Untitled"')
start_raw=$(echo "$json" | jq -r '.meeting.startTime // ""')
end_raw=$(echo "$json" | jq -r '.meeting.endTime // ""')
hangout=$(echo "$json" | jq -r '.meeting.hangoutLink // ""')
location=$(echo "$json" | jq -r '.meeting.location // ""')

link="${hangout:-$location}"
echo -n "$link" > /tmp/waybar-next-meeting-link

fmt_relative() {
  local raw="${1//,/}"
  [[ -z "$raw" ]] && return
  local epoch=$(date -d "$raw" +%s 2>/dev/null) || return
  local today=$(date +%Y-%m-%d)
  local tomorrow=$(date -d "+1 day" +%Y-%m-%d)
  local meeting_date=$(date -d "@$epoch" +%Y-%m-%d)
  local clock=$(date -d "@$epoch" +%H:%M)

  if [[ "$meeting_date" == "$today" ]]; then
    echo "today at $clock"
  elif [[ "$meeting_date" == "$tomorrow" ]]; then
    echo "tomorrow at $clock"
  else
    echo "$(date -d "@$epoch" +%d/%m) at $clock"
  fi
}

# Short label: "in X min", "in X h", "in X h Y min", "in N days" (until start).
fmt_in_time() {
  local raw="${1//,/}"
  [[ -z "$raw" ]] && return
  local start_epoch
  start_epoch=$(date -d "$raw" +%s 2>/dev/null) || return
  local now
  now=$(date +%s)
  local diff=$((start_epoch - now))

  if [[ $diff -le 0 ]]; then
    echo "now"
    return
  fi

  local days=$((diff / 86400))
  if [[ $days -ge 2 ]]; then
    echo "in $days days"
    return
  fi
  if [[ $days -eq 1 ]]; then
    echo "in 1 day"
    return
  fi

  local mins_ceiling=$(( (diff + 59) / 60 ))
  if [[ $mins_ceiling -ge 60 ]]; then
    local h=$((mins_ceiling / 60))
    local m=$((mins_ceiling % 60))
    if [[ $m -eq 0 ]]; then
      echo "in ${h} h"
    else
      echo "in ${h}h ${m}min"
    fi
    return
  fi

  if [[ $mins_ceiling -le 1 ]]; then
    echo "soon"
  else
    echo "in ${mins_ceiling}min"
  fi
}

fmt_clock() {
  local raw="${1//,/}"
  [[ -z "$raw" ]] && return
  date -d "$raw" +%H:%M 2>/dev/null
}

start_fmt=$(fmt_relative "$start_raw")
in_time=$(fmt_in_time "$start_raw")
start_clock=$(fmt_clock "$start_raw")
end_clock=$(fmt_clock "$end_raw")

short="${title:0:35}"
[[ ${#title} -gt 35 ]] && short="${short}…"
[[ -n "$in_time" ]] && short="$short $in_time"

# Waybar tooltips treat \n as literal; use carriage return for line breaks (see Waybar wiki / issues).
tooltip="$title"
[[ -n "$start_clock" ]] && tooltip+=$'\r'"󰅐 $start_fmt - $end_clock"
[[ -n "$hangout" ]] && tooltip+=$'\r'"󰗋 $hangout"
[[ -n "$location" ]] && tooltip+=$'\r'"󰍎 $location"

text_escaped=$(escape_json "$short")
tooltip_escaped=$(escape_json "$tooltip")

echo "{\"text\": \"$text_escaped\", \"tooltip\": \"$tooltip_escaped\"}"
