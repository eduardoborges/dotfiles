#!/usr/bin/env bash
set -euo pipefail

state_file="${XDG_RUNTIME_DIR:-/tmp}/waybar-network-speed"
iface="$(ip route show default 2>/dev/null | awk '{ print $5; exit }')"

format_rate() {
  local bytes="$1"
  awk -v bytes="$bytes" 'BEGIN {
    if (bytes >= 1048576) printf "%.1fMB/s", bytes / 1048576
    else if (bytes >= 1024) printf "%.0fKB/s", bytes / 1024
    else printf "%.0fB/s", bytes
  }'
}

if [[ -z "$iface" || ! -r "/sys/class/net/$iface/statistics/rx_bytes" ]]; then
  printf '{"text":"󰤮","tooltip":"Disconnected"}\n'
  exit 0
fi

rx="$(cat "/sys/class/net/$iface/statistics/rx_bytes")"
tx="$(cat "/sys/class/net/$iface/statistics/tx_bytes")"
now="$(date +%s)"

prev_rx="$rx"
prev_tx="$tx"
prev_now="$now"
if [[ -r "$state_file" ]]; then
  read -r prev_iface prev_rx prev_tx prev_now < "$state_file" || true
  if [[ "$prev_iface" != "$iface" ]]; then
    prev_rx="$rx"
    prev_tx="$tx"
    prev_now="$now"
  fi
fi

printf '%s %s %s %s\n' "$iface" "$rx" "$tx" "$now" > "$state_file"

elapsed=$((now - prev_now))
if (( elapsed <= 0 )); then
  elapsed=1
fi

rx_rate=$(((rx - prev_rx) / elapsed))
tx_rate=$(((tx - prev_tx) / elapsed))
if (( rx_rate < 0 )); then rx_rate=0; fi
if (( tx_rate < 0 )); then tx_rate=0; fi

icon="󰀂"
if [[ -d "/sys/class/net/$iface/wireless" ]]; then
  icon="󰤨"
fi

down="$(format_rate "$rx_rate")"
up="$(format_rate "$tx_rate")"

printf '{"text":"%s","tooltip":"%s\\nDownload: %s\\nUpload: %s"}\n' "$icon" "$iface" "$down" "$up"
