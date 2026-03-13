#!/usr/bin/env bash
# Mostra a próxima reunião do Google Calendar na Waybar (usa meetfy).

set -e

json=$(meetfy next --json 2>/dev/null) || true

if [[ -z "$json" ]]; then
  echo '{"text": "", "tooltip": "meetfy: sem resposta (rode meetfy auth?)"}'
  exit 0
fi

# Verifica sucesso e se há reunião
success=$(echo "$json" | jq -r '.success // false')
if [[ "$success" != "true" ]]; then
  err=$(echo "$json" | jq -r '.error // "erro desconhecido"')
  echo "{\"text\": \"\", \"tooltip\": \"meetfy: $err\"}"
  exit 0
fi

meeting=$(echo "$json" | jq -r '.meeting')
if [[ "$meeting" == "null" ]] || [[ -z "$meeting" ]]; then
  echo '{"text": "", "tooltip": "Nenhuma reunião próxima"}'
  exit 0
fi

title=$(echo "$json" | jq -r '.meeting.title // "Sem título"')
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
  local hora=$(date -d "@$epoch" +%H:%M)

  if [[ "$meeting_date" == "$today" ]]; then
    echo "hoje às $hora"
  elif [[ "$meeting_date" == "$tomorrow" ]]; then
    echo "amanhã às $hora"
  else
    echo "$(date -d "@$epoch" +%d/%m) às $hora"
  fi
}

fmt_hora() {
  local raw="${1//,/}"
  [[ -z "$raw" ]] && return
  date -d "$raw" +%H:%M 2>/dev/null
}

start_fmt=$(fmt_relative "$start_raw")
start_hora=$(fmt_hora "$start_raw")
end_hora=$(fmt_hora "$end_raw")

short="${title:0:35}"
[[ ${#title} -gt 35 ]] && short="${short}…"
[[ -n "$start_fmt" ]] && short="$short — $start_fmt"

tooltip="$title"
[[ -n "$start_hora" ]] && tooltip="$tooltip\n󰅐 $start_fmt – $end_hora"
[[ -n "$hangout" ]] && tooltip="$tooltip\n󰗋 $hangout"
[[ -n "$location" ]] && tooltip="$tooltip\n󰍎 $location"

# Escapa para JSON
escape_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}
text_escaped=$(escape_json "󰃭 $short")
tooltip_escaped=$(escape_json "$tooltip")

echo "{\"text\": \"$text_escaped\", \"tooltip\": \"$tooltip_escaped\"}"
