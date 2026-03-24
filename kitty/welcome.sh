#!/bin/bash
# Minimal, clean system info for terminal launch

# Colors
CYAN="\e[36m"
GREEN="\e[32m"
RESET="\e[0m"

# ----- OS, CPU, MEM, DISK -----
OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//')
MEM=$(free -h | awk '/Mem:/ {print $3 " / " $2}')
DISK=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')

# ----- IPs (non-loopback, IPv4, UP) -----
IPs=$(
  ip -o -4 addr show up scope global 2>/dev/null \
  | awk '{gsub(/\/.*/,"",$4); printf "%s: %s%s", $2, $4, (NR==NR?ORS:"")}' ORS=", " \
  | sed 's/, $//'
)
[ -z "$IPs" ] && IPs="N/A"

# ----- Battery -----
format_hours() { # $1 = hours float -> "Xh Ym"
  awk -v h="$1" 'BEGIN{
    if (h=="" || h+0==0){print "calculating"; exit}
    total=int(h*60+0.5); hh=int(total/60); mm=total%60;
    if (hh>0 && mm>0) printf "%dh %dm", hh, mm;
    else if (hh>0) printf "%dh", hh;
    else printf "%dm", mm;
  }'
}

battery_info() {
  # Prefer upower if present
  if command -v upower >/dev/null 2>&1; then
    BAT=$(upower -e | grep -m1 BAT)
    if [ -n "$BAT" ]; then
      info=$(upower -i "$BAT")
      state=$(echo "$info" | awk -F: '/state/{gsub(/^ *| *$/,"",$2); print $2}')
      percent=$(echo "$info" | awk -F: '/percentage/{gsub(/^ *| *%$/,"",$2); print $2}')
      ttf=$(echo "$info" | awk -F: '/time to full/{gsub(/^ *| *hours?$/,"",$2); print $2}')
      tte=$(echo "$info" | awk -F: '/time to empty/{gsub(/^ *| *hours?$/,"",$2); print $2}')
      if [ "$state" = "charging" ] && [ -n "$ttf" ]; then
        echo "$percent% (charging, $(format_hours "$ttf") to full)"
        return
      elif [ "$state" = "discharging" ] && [ -n "$tte" ]; then
        echo "$percent% (discharging, ~$(format_hours "$tte") left)"
        return
      else
        echo "$percent% ($state)"
        return
      fi
    fi
  fi

  # Fallback: /sys/class/power_supply
  BDIR=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)
  if [ -n "$BDIR" ]; then
    state=$(cat "$BDIR/status" 2>/dev/null)
    percent=$(
      if [ -r "$BDIR/capacity" ]; then cat "$BDIR/capacity"; fi
    )
    # energy/power names vary (energy_* or charge_*)
    get() {
      for f in "$BDIR/$1_now" "$BDIR/$1_now"; do [ -r "$f" ] && cat "$f" && return; done
      for f in "$BDIR/${1/energy/charge}_now" "$BDIR/${1/energy/charge}_now"; do [ -r "$f" ] && cat "$f" && return; done
    }
    energy_now=$(cat "$BDIR/energy_now" 2>/dev/null || cat "$BDIR/charge_now" 2>/dev/null)
    energy_full=$(cat "$BDIR/energy_full" 2>/dev/null || cat "$BDIR/charge_full" 2>/dev/null)
    power_now=$(cat "$BDIR/power_now" 2>/dev/null || cat "$BDIR/current_now" 2>/dev/null)

    eta=""
    if [ -n "$power_now" ] && [ "$power_now" -gt 0 ] && [ -n "$energy_now" ] && [ -n "$energy_full" ]; then
      if [ "$state" = "Discharging" ]; then
        # hours = energy_now / power_now
        hours=$(awk -v e="$energy_now" -v p="$power_now" 'BEGIN{printf "%.2f", e/p}')
        eta=" (~$(format_hours "$hours") left)"
      elif [ "$state" = "Charging" ]; then
        # hours = (energy_full - energy_now) / power_now
        hours=$(awk -v f="$energy_full" -v e="$energy_now" -v p="$power_now" 'BEGIN{printf "%.2f", (f-e)/p}')
        eta=" ($(format_hours "$hours") to full)"
      fi
    fi
    [ -n "$percent" ] && percent="${percent%\%}"
    [ -z "$percent" ] && percent="?"
    echo "${percent}% ($(echo "$state" | tr '[:upper:]' '[:lower:]')$eta)"
    return
  fi

  echo "N/A"
}

BATTERY=$(battery_info)

# ----- Output -----
echo -e "${CYAN}OS:${RESET}        $OS"
echo -e "${GREEN}CPU:${RESET}       $CPU"
echo -e "${GREEN}Memory:${RESET}    $MEM"
echo -e "${GREEN}Disk:${RESET}      $DISK"
echo -e "${GREEN}Battery:${RESET}   $BATTERY"
echo -e "${GREEN}IP:${RESET}        $IPs"

