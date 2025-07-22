#!/bin/bash

issue_file="/etc/issue.d/iplist.issue"
ssid="(unknown)"


pwd=$(sudo awk -F= '/psk=/ {print $2}' /etc/NetworkManager/system-connections/octopi-hotspot.nmconnection)

# Try to get SSID from active Wi-Fi connection
if nmcli -t -f active,ssid dev wifi | grep -q "^yes:"; then
    ssid=$(nmcli -t -f active,ssid dev wifi | awk -F: '/^yes:/ {print $2}')
elif nmcli -t -f NAME,TYPE connection show --active | grep -q ":wifi"; then
    ssid=$(nmcli -f 802-11-wireless.ssid connection show | awk '/ssid/ {print $2; exit}')
fi

{
    echo "OctoPrint SSID: $ssid  PWD:$pwd"
    echo " • http://octopi.lan"
    for intf in $(ls /sys/class/net); do
        [[ "$intf" == "lo" ]] && continue  # skip loopback
        ip=$(ip -4 addr show "$intf" | awk '/inet / {print $2}' | cut -d/ -f1)
        if [ -n "$ip" ]; then
            echo " • $intf → http://$ip"
        fi
    done
    echo ""
} | sudo tee "$issue_file" >/dev/null


