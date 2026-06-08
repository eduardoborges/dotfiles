#!/usr/bin/env bash
set -euo pipefail

gpu_usage="$(
  cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n1 ||
    nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 ||
    true
)"
gpu_usage="${gpu_usage:-"--"}"

gpu_temp="--"
gpu_temp_label="Temp"
gpu_fan="--"

for hwmon in /sys/class/hwmon/hwmon*; do
  [[ -r "$hwmon/name" ]] || continue
  name="$(cat "$hwmon/name")"
  [[ "$name" =~ (amdgpu|nvidia) ]] || continue

  for input in "$hwmon"/temp*_input; do
    [[ -r "$input" ]] || continue
    label_file="${input%_input}_label"
    label="$([[ -r "$label_file" ]] && cat "$label_file" || echo "")"
    if [[ -z "$label" || "$label" == "edge" || "$label" == "GPU" ]]; then
      gpu_temp="$(awk '{ printf "%.0f", $1 / 1000 }' "$input")"
      gpu_temp_label="${label:-Temp}"
      break
    fi
  done

  for input in "$hwmon"/fan*_input; do
    [[ -r "$input" ]] || continue
    rpm="$(cat "$input")"
    [[ "$rpm" =~ ^[0-9]+$ ]] || continue
    gpu_fan="$rpm"
    break
  done

  break
done

text="󰾲 ${gpu_usage}% ${gpu_temp}°C ${gpu_fan}RPM"
tooltip="GPU: ${gpu_usage}%\n${gpu_temp_label}: ${gpu_temp} °C\nFan: ${gpu_fan} RPM"

printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tooltip"
