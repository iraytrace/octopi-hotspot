#!/bin/bash
set -e

# -------- Configuration --------
serial=$(cat /proc/device-tree/serial-number | tr -d '\0')
suffix="${serial: -4}"
SSID="octopi-${suffix,,}"  # SSID is unique
HOTSPOT_PASSWORD="FDMnetpwd"
WIFI_INTERFACE="wlan0"
ETH_INTERFACE="eth0"
HOSTNAME="octopi"
IP_ADDR="192.168.50.1"
CIDR="${IP_ADDR}/24"

echo "🛰️  Creating Wi-Fi AP: ${SSID}"
echo "📛 Hostname: ${HOSTNAME}"
echo "🌐 Hotspot IP: ${CIDR}"

# -------- Ensure Wi-Fi interface is up --------
echo "🔧 Bringing up ${WIFI_INTERFACE}..."
sudo rfkill unblock wifi
sudo ip link set "${WIFI_INTERFACE}" up || true
sudo nmcli radio wifi on
sudo nmcli networking on

# -------- Find Least Congested Channel --------
echo "🔍 Scanning for least congested channel..."
declare -A counts=( [1]=0 [6]=0 [11]=0 )

set +e
while read -r ch; do
    case $ch in
        1) ((counts[1]++)) 
		;;
        6) ((counts[6]++)) 
		;;
        11) ((counts[11]++)) 
		;;
    esac
done < <(sudo iwlist wlan0 scan | grep -i 'Channel:' | sed 's/\s*Channel://')
set -e
echo "FinalChannel counts: 1=${counts[1]} 6=${counts[6]} 11=${counts[11]}"

best_channel=1
if [[ ${counts[6]} -lt ${counts[best_channel]} ]]; then best_channel=6; fi
if [[ ${counts[11]} -lt ${counts[best_channel]} ]]; then best_channel=11; fi
echo "📡 Best Wi-Fi channel: ${best_channel}"

# -------- Remove previous connection if it exists --------
if nmcli connection show "octopi-hotspot" &>/dev/null; then
    echo "🔁 Removing existing connection 'octopi-hotspot'"
    sudo nmcli connection delete "octopi-hotspot"
fi

# -------- Create new hotspot connection --------
sudo nmcli connection add type wifi ifname "${WIFI_INTERFACE}" con-name "octopi-hotspot" autoconnect yes \
    ssid "${SSID}" mode ap


sudo nmcli connection modify "octopi-hotspot" \
    802-11-wireless.band bg \
    802-11-wireless.channel "${best_channel}" \
    802-11-wireless-security.key-mgmt wpa-psk \
    802-11-wireless-security.psk ${HOTSPOT_PASSWORD} \
    802-11-wireless.powersave 2 \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "${HOTSPOT_PASSWORD}" \
    ipv4.addresses "${CIDR}" \
    ipv4.gateway "${IP_ADDR}" \
    ipv4.method shared \
    connection.autoconnect-priority 100

sudo nmcli connection up "octopi-hotspot"

# -------- Set fixed hostname --------
echo "🖥️  Setting hostname to ${HOSTNAME}"
sudo hostnamectl set-hostname "${HOSTNAME}"
sudo sed -i "/127.0.1.1/c\127.0.1.1\t${HOSTNAME}" /etc/hosts

# -------- Setup local DNS for .lan resolution --------
echo "🔧 Creating local DNS rule for ${HOSTNAME}.lan → ${IP_ADDR}"
echo "address=/${HOSTNAME}.lan/${IP_ADDR}" | sudo tee /etc/NetworkManager/dnsmasq.d/octopi.conf >/dev/null
# -------- Ensure NetworkManager uses dnsmasq --------
nm_conf="/etc/NetworkManager/NetworkManager.conf"
dns_line="dns=dnsmasq"
updated_dnsmasq=false

echo "🔧 Checking NetworkManager DNS config..."
if grep -q "^\s*dns=dnsmasq" "$nm_conf"; then
    echo "✅ NetworkManager already configured to use dnsmasq"
else
    echo "🔄 Enabling dnsmasq in NetworkManager..."
    if grep -q "^\[main\]" "$nm_conf"; then
        sudo sed -i "/^\[main\]/a ${dns_line}" "$nm_conf"
    else
        echo -e "[main]\n${dns_line}" | sudo tee -a "$nm_conf" >/dev/null
    fi
    updated_dnsmasq=true
fi

sudo systemctl restart NetworkManager

# -------- Show Ethernet status --------
echo "🧷 Ethernet interface (${ETH_INTERFACE}) remains available."
nmcli device show "${ETH_INTERFACE}" | grep IP4 || echo "⚠️  Ethernet not active."

# -------- Done --------
echo "✅ Hotspot setup complete"
echo "📶 SSID: ${SSID}"
echo "🔗 Access OctoPrint at: http://${HOSTNAME}.lan or http://${IP_ADDR}"
