#!/usr/bin/env bash

LINK_FILE="/tmp/waybar-next-meeting-link"
link=$(cat "$LINK_FILE" 2>/dev/null)

options="󰃭  Abrir Google Calendar"
if [[ -n "$link" ]]; then
  options="󰗋  Entrar na reunião\n  Copiar link\n${options}"
fi

choice=$(echo -e "$options" | walker --dmenu --placeholder "Próxima reunião")

case "$choice" in
  *"Entrar na reunião"*)   xdg-open "$link" ;;
  *"Copiar link"*)         echo -n "$link" | wl-copy ;;
  *"Google Calendar"*)     xdg-open "https://calendar.google.com" ;;
esac
