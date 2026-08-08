#!/bin/bash
# Battery low/critical notifier — polls every 60s and warns once per threshold.

LOW=20
CRITICAL=10
BAT="BAT0"

LOW_SENT=0
CRITICAL_SENT=0

while true; do
    percent=$(cat "/sys/class/power_supply/$BAT/capacity" 2>/dev/null)
    status=$(cat "/sys/class/power_supply/$BAT/status" 2>/dev/null)

    if [ "$status" = "Discharging" ]; then

        if [ "$percent" -le "$CRITICAL" ] && [ "$CRITICAL_SENT" -eq 0 ]; then
            notify-send \
                -u critical \
                -i battery-empty \
                "🪫 Battery Critical" \
                "Only ${percent}% remaining!\n\nPlug in your charger NOW."

            CRITICAL_SENT=1

        elif [ "$percent" -le "$LOW" ] && [ "$LOW_SENT" -eq 0 ]; then
            notify-send \
                -u normal \
                -i battery-caution \
                "🔋 Low Battery" \
                "Battery at ${percent}%\n\n⚡ Connect your charger soon."

            LOW_SENT=1
        fi

    else
        LOW_SENT=0
        CRITICAL_SENT=0
    fi

    sleep 60
done
