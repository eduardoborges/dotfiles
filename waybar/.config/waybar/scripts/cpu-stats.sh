#!/usr/bin/env bash
set -euo pipefail

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
total_a=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_a=$((idle + iowait))

sleep 0.2

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
total_b=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_b=$((idle + iowait))

total_delta=$((total_b - total_a))
idle_delta=$((idle_b - idle_a))
cpu_usage="--"
if (( total_delta > 0 )); then
  cpu_usage=$(((100 * (total_delta - idle_delta) + total_delta / 2) / total_delta))
fi

cpu_temp="--"
for hwmon in /sys/class/hwmon/hwmon*; do
  [[ -r "$hwmon/name" ]] || continue
  [[ "$(cat "$hwmon/name")" == "k10temp" ]] || continue

  for input in "$hwmon"/temp*_input; do
    [[ -r "$input" ]] || continue
    label="${input%_input}_label"
    if [[ ! -r "$label" || "$(cat "$label")" == "Tctl" ]]; then
      cpu_temp="$(awk '{ printf "%.0f", $1 / 1000 }' "$input")"
      break 2
    fi
  done
done

cpu_fan="--"
for hwmon in /sys/class/hwmon/hwmon*; do
  [[ -r "$hwmon/name" ]] || continue
  name="$(cat "$hwmon/name")"
  [[ "$name" =~ (nct|cpu|asus|it87|thinkpad|dell|gigabyte|msi|nzxt|corsair) ]] || continue

  if [[ "$name" =~ nct && -r "$hwmon/fan2_input" ]]; then
    rpm="$(cat "$hwmon/fan2_input")"
    if [[ "$rpm" =~ ^[0-9]+$ && "$rpm" -gt 0 ]]; then
      cpu_fan="$rpm"
      break
    fi
  fi

  for input in "$hwmon"/fan*_input; do
    [[ -r "$input" ]] || continue
    rpm="$(cat "$input")"
    [[ "$rpm" =~ ^[0-9]+$ ]] || continue
    cpu_fan="$rpm"
    break 2
  done
done

text="󰍛 ${cpu_usage}% ${cpu_temp}°C ${cpu_fan}RPM"
tooltip="CPU: ${cpu_usage}%\nTemp: ${cpu_temp} °C\nFan: ${cpu_fan} RPM"

printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tooltip"
