#!/usr/bin/env bash
# Screenshot the hyprlock lock screen.
# Schedules a delayed grim capture, then locks. When grim fires the lock
# screen is already up, so it ends up in the shot. Unlock normally afterward.
#
# Usage: screenshot-lock.sh [delay_seconds] [output_file]

delay="${1:-3}"
out="${2:-$HOME/lockscreen-$(date +%Y%m%d-%H%M%S).png}"

(sleep "$delay" && grim "$out" && notify-send "Lock screenshot saved" "$out" 2>/dev/null) &
hyprlock
