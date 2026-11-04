#!/usr/bin/env bash
# Rofi WiFi menu for NetworkManager.
# Scans nearby networks, shows a clickable list, prompts for a password
# when needed, and connects. Also toggles WiFi on/off and disconnects.

set -euo pipefail

notify() { command -v notify-send >/dev/null 2>&1 && notify-send "WiFi" "$1" || true; }

# rofi wrappers (tweak -theme-str to taste)
rofi_menu() {
    rofi -dmenu -i -p "WiFi" -theme-str 'window {width: 480px;}' "$@"
}
rofi_pass() {
    # $1 = SSID shown in the prompt message so the window is never blank
    rofi -dmenu -password -p "Password" \
        -mesg "Password for $1" \
        -theme-str 'window {width: 400px;} listview {enabled: false;}'
}

# Full NetworkManager dialog for networks the simple flow can't handle
# (enterprise/eduroam, hidden SSIDs, per-network certs, static IP, etc.)
open_editor() {
    if command -v nm-connection-editor >/dev/null 2>&1; then
        setsid nm-connection-editor >/dev/null 2>&1 &
    elif command -v nmtui >/dev/null 2>&1; then
        setsid kitty -e nmtui >/dev/null 2>&1 &
    fi
    notify "Opening advanced network setup"
}

# WiFi radio state
wifi_state=$(nmcli -t -f WIFI radio)

if [[ "$wifi_state" == "disabled" ]]; then
    choice=$(printf '󰖪  Enable WiFi\n󰅖  Cancel' | rofi_menu)
    [[ "$choice" == *"Enable WiFi"* ]] && { nmcli radio wifi on; notify "WiFi enabled"; }
    exit 0
fi

# Trigger a fresh scan (don't fail if it's rate-limited)
nmcli device wifi rescan >/dev/null 2>&1 || true

# Currently active SSID (if any)
active=$(nmcli -t -f ACTIVE,SSID device wifi | awk -F: '$1=="yes"{print $2; exit}')

# Build the network list: "<signal-icon> <lock> SSID"
# Dedupe by SSID, skip empty SSIDs, mark the connected one.
list=$(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list \
    | awk -F: '
        $4 == "" { next }
        seen[$4]++ { next }
        {
            sig=$2
            if (sig >= 75)      icon="󰤨"
            else if (sig >= 50) icon="󰤥"
            else if (sig >= 25) icon="󰤢"
            else                icon="󰤟"
            lock = ($3 == "" || $3 == "--") ? "󰲝" : "󰌾"
            mark = ($1 == "*") ? "  ●" : ""
            printf "%s %s  %s%s\n", icon, lock, $4, mark
        }')

menu="$list
──────────────
󰒓  Other / enterprise network…
󰖪  Disable WiFi
󰑐  Rescan"

[[ -n "$active" ]] && menu="󰅖  Disconnect ($active)
$menu"

choice=$(printf '%s' "$menu" | rofi_menu)
[[ -z "$choice" ]] && exit 0

case "$choice" in
    "──────────────") exit 0 ;;
    *"Other / enterprise"*) open_editor; exit 0 ;;
    *"Disable WiFi"*)  nmcli radio wifi off; notify "WiFi disabled"; exit 0 ;;
    *"Rescan"*)        exec "$0" ;;
    *"Disconnect ("*)
        con=$(nmcli -t -f NAME,DEVICE connection show --active \
              | awk -F: 'NR==1{print $1}')
        [[ -n "$con" ]] && { nmcli connection down "$con"; notify "Disconnected"; }
        exit 0 ;;
esac

# Extract SSID: strip leading icons, trailing "  ●" marker.
ssid=$(printf '%s' "$choice" | sed -E 's/^[^ ]+ [^ ]+  //; s/  ●$//')
[[ -z "$ssid" ]] && exit 0

# Already connected to this one? Offer nothing more.
[[ "$ssid" == "$active" ]] && { notify "Already connected to $ssid"; exit 0; }

# Try a known/saved connection first (no password prompt needed).
if nmcli -t -f NAME connection show | grep -qxF "$ssid"; then
    if nmcli connection up id "$ssid" >/dev/null 2>&1; then
        notify "Connected to $ssid"; exit 0
    fi
fi

# Is the network secured? What kind?
security=$(nmcli -t -f SSID,SECURITY device wifi list \
          | awk -F: -v s="$ssid" '$1==s{print $2; exit}')

# Enterprise (802.1X, e.g. eduroam): needs username + EAP method + maybe a
# cert — a single password won't do. Hand it to the full NM dialog.
if [[ "$security" == *802.1X* ]]; then
    notify "$ssid is an enterprise network — opening advanced setup"
    open_editor
    exit 0
fi

if [[ -z "$security" || "$security" == "--" ]]; then
    # Open network
    if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
        notify "Connected to $ssid"
    else
        notify "Failed to connect to $ssid"
    fi
    exit 0
fi

# Secured with a simple password (WPA/WPA2-PSK): prompt inline.
password=$(rofi_pass "$ssid" </dev/null)
[[ -z "$password" ]] && exit 0

if nmcli device wifi connect "$ssid" password "$password" >/dev/null 2>&1; then
    notify "Connected to $ssid"
else
    notify "Failed to connect to $ssid (wrong password?)"
fi
