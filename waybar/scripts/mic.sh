#!/usr/bin/env bash
# Microphone status for Waybar (JSON output)
raw=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
vol=$(awk '{printf "%d", $2*100}' <<<"$raw")

if grep -q MUTED <<<"$raw"; then
    printf '{"text":"󰍭","tooltip":"Microphone muted","class":"muted"}\n'
else
    printf '{"text":"󰍬 %s%%","tooltip":"Microphone %s%%","class":"unmuted"}\n' "$vol" "$vol"
fi
