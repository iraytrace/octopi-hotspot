#!/bin/bash

issue_file="/etc/issue.d/iplist.issue"
ssid="(unknown)"

# Try to get SSID from active Wi-Fi connection
if nmcli -t -f active,ssid dev wifi | grep -q "^yes:"; then
    ssid=$(nmcli -t -f active,ssid dev wifi | awk -F: '/^yes:/ {print $2}')
elif nmcli -t -f NAME,TYPE connection show --active | grep -q ":wifi"; then
    ssid=$(nmcli -f 802-11-wireless.ssid connection show | awk '/ssid/ {print $2; exit}')
fi

{
    echo "🚀 OctoPrint Hotspot Info"
    echo "📶 SSID: $ssid"
    echo "🌐 Available at:"
    for intf in $(ls /sys/class/net); do
        [[ "$intf" == "lo" ]] && continue  # skip loopback
        ip=$(ip -4 addr show "$intf" | awk '/inet / {print $2}' | cut -d/ -f1)
        if [ -n "$ip" ]; then
            echo " • $intf → http://$ip"
        fi
    done
    echo " • http://octopi.lan"
} | sudo tee "$issue_file" >/dev/null


