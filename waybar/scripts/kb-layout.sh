#!/usr/bin/env bash
# Short label for the MAIN keyboard's active layout.
# Reads only the device flagged main=true, so non-keyboard HID devices such as
# bluetooth earbuds (which register as "keyboards" with their own layout) can't
# hijack or blank the waybar language box. Always prints a non-empty value.

layout=$(hyprctl devices -j 2>/dev/null \
    | jq -r 'first(.keyboards[] | select(.main) | .active_keymap) // empty')

case "$layout" in
    "English (US)"*) echo "US" ;;
    Swedish*)        echo "SE" ;;
    Japanese*)       echo "JP" ;;
    "")              echo "--" ;;   # Hyprland not ready / no main keyboard
    *)               echo "${layout:0:2}" ;;  # fallback: first 2 chars
esac
