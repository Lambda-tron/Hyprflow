#!/usr/bin/env bash
# Battery readout for hyprlock — Catppuccin Mocha themed pango markup

bat=$(find /sys/class/power_supply -maxdepth 1 -iname 'BAT*' -print -quit)

if [[ -z "$bat" ]]; then
    exit 0
fi

capacity=$(<"$bat/capacity")
status=$(<"$bat/status")

if [[ "$status" == "Charging" ]]; then
    icon="󰂄"
    color="a6e3a1" # Green
elif (( capacity <= 15 )); then
    icon="󰁻"
    color="f38ba8" # Red
elif (( capacity <= 40 )); then
    icon="󰁽"
    color="f9e2af" # Yellow
else
    icon="󰁹"
    color="89b4fa" # Blue
fi

printf '<span foreground="#%s">%s</span>  <span foreground="#cdd6f4">%s%%</span>\n' "$color" "$icon" "$capacity"
