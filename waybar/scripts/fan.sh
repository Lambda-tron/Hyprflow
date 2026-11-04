#!/usr/bin/env bash
# ThinkPad fan speed as an approximate percentage.
# The EC pins pwm1 at 255, so it's useless for a real duty cycle; instead we
# scale the measured RPM against a typical ThinkPad max. Tune MAX_RPM if your
# fan tops out higher/lower (watch `sensors` under full load). The tooltip shows
# the honest RPM figure.
MAX_RPM=5000

name_file=$(grep -l thinkpad /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1)
rpm=0
if [ -n "$name_file" ]; then
    dir=$(dirname "$name_file")
    rpm=$(cat "$dir/fan1_input" 2>/dev/null || echo 0)
fi

pct=$(( rpm * 100 / MAX_RPM ))
(( pct > 100 )) && pct=100

printf '{"text":"%d%%","tooltip":"Fan: %d RPM"}\n' "$pct" "$rpm"
