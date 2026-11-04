#!/usr/bin/env bash
# Cycle keyboard layout us -> se -> jp and report the active one.
#
# Reading active_keymap back *immediately* after `hyprctl switchxkblayout` is
# racy: the change can take a few hundred ms to show up in `hyprctl devices`,
# which made the notification and the waybar box lag one step behind (they only
# caught up on waybar's next poll — i.e. "when I start typing"). So:
#   1. compute the next layout from the current one  -> instant, correct toast
#   2. wait until the switch actually lands           -> then refresh waybar
#
# NOTE: this list must match `kb_layout` in hyprland.conf (us,se,jp).
layouts=("English (US)" "Swedish" "Japanese")

current=$(hyprctl devices -j | jq -r 'first(.keyboards[] | select(.main) | .active_keymap)')

idx=0
for i in "${!layouts[@]}"; do
    [[ "$current" == "${layouts[$i]}"* ]] && idx=$i && break
done
next=$(( (idx + 1) % ${#layouts[@]} ))

# Switch every keyboard to that absolute index (keeps them in lockstep).
hyprctl switchxkblayout all "$next" >/dev/null

# Instant, race-free notification (replaces the previous toast via mako hint).
notify-send -t 1200 \
    -h string:x-canonical-private-synchronous:kb-layout \
    "󰌌  ${layouts[$next]}"

# Wait (up to ~1s) for the switch to actually propagate, then refresh waybar so
# the top box flips to the real new layout instead of flashing the old one.
for _ in $(seq 1 50); do
    now=$(hyprctl devices -j | jq -r 'first(.keyboards[] | select(.main) | .active_keymap)')
    [ "$now" != "$current" ] && break
    sleep 0.02
done
pkill -RTMIN+9 waybar
