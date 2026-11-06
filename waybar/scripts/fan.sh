#!/usr/bin/env bash
# CPU package temperature (coretemp). This Fujitsu has no fan RPM sensor.
temp=""
for h in /sys/class/hwmon/hwmon*; do
    [[ "$(cat "$h/name" 2>/dev/null)" == "coretemp" ]] || continue
    temp=$(( $(cat "$h/temp1_input") / 1000 )); break
done
printf '{"text":"%s°C","tooltip":"CPU package %s°C"}\n' "${temp:-?}" "${temp:-?}"
