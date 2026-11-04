#!/usr/bin/env bash
# Adjust audio volume / mute, show a mako toast, and play a quiet feedback click.
# Usage: volume.sh up|down|mute

SINK="@DEFAULT_AUDIO_SINK@"
SOUND="$HOME/.config/hypr/audio.wav"

case "$1" in
    up)   wpctl set-volume -l 1.5 "$SINK" 5%+ ;;
    down) wpctl set-volume "$SINK" 5%- ;;
    mute) wpctl set-mute "$SINK" toggle ;;
esac

# Read back current state -> "Volume: 0.45" or "Volume: 0.45 [MUTED]"
read -r _ vol muted < <(wpctl get-volume "$SINK")
perc=$(awk -v v="$vol" 'BEGIN { printf "%d", v * 100 + 0.5 }')

if [[ "$muted" == "[MUTED]" ]]; then
    icon="󰝟"
    text="Muted"
elif (( perc == 0 )); then
    icon="󰝟"; text="0%"
elif (( perc < 34 )); then
    icon="󰕿"; text="${perc}%"
elif (( perc < 67 )); then
    icon="󰖀"; text="${perc}%"
else
    icon="󰕾"; text="${perc}%"
fi

# Instant toast (replaces the previous volume toast instead of stacking).
notify-send -t 1000 \
    -h string:x-canonical-private-synchronous:volume \
    -h "int:value:${perc}" \
    "${icon}  ${text}"

# Quiet feedback click (was 0.4, now 0.2 = 50% lower).
pw-play --volume 0.2 "$SOUND"
