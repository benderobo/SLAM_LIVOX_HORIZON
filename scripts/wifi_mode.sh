#!/bin/bash

MODE=$1
SSID="wi-2.4-fi"

start_hotspot() {
    echo "Starting HOTSPOT..."

    sudo systemctl stop NetworkManager
    sudo systemctl stop wpa_supplicant

    sudo ip link set wlan0 down
    sudo ip addr flush dev wlan0
    sudo ip addr add 192.168.77.1/24 dev wlan0
    sudo ip link set wlan0 up

    sudo systemctl start dnsmasq
    sudo hostapd /etc/hostapd/hostapd.conf -B

    echo "HOTSPOT ACTIVE"
}

start_client() {
    echo "Starting CLIENT WIFI..."

    sudo pkill hostapd
    sudo systemctl stop dnsmasq

    sudo ip addr flush dev wlan0

    sudo systemctl start NetworkManager
    sudo systemctl restart wpa_supplicant

    sudo nmcli connection up "$SSID"

    echo "CLIENT MODE ACTIVE"
}

if [ "$MODE" = "ap" ]; then
    start_hotspot

elif [ "$MODE" = "client" ]; then
    start_client

elif [ "$MODE" = "auto" ]; then
    echo "AUTO MODE..."

    if nmcli -t -f ACTIVE,SSID dev wifi | grep -q "^yes:$SSID"; then
        echo "WiFi found → CLIENT"
        start_client
    else
        echo "WiFi not found → HOTSPOT"
        start_hotspot
    fi

else
    echo "Usage:"
    echo "wifi_mode.sh client"
    echo "wifi_mode.sh ap"
    echo "wifi_mode.sh auto"
fi
