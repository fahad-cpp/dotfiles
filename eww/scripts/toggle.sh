#!/bin/bash
if [ "$1" = "wifi" ]; then
    if nmcli radio wifi | grep -q "enabled"; then
        nmcli radio wifi off
    else
        nmcli radio wifi on
    fi
elif [ "$1" = "bluetooth" ]; then
    if bluetoothctl show | grep -q "Powered: yes"; then
        bluetoothctl power off
    else
        bluetoothctl power on
    fi
fi