#!/bin/bash
if [ "$1" = "wifi" ]; then
    if nmcli radio wifi | grep -q "enabled"; then echo "on"; else echo "off"; fi
elif [ "$1" = "bluetooth" ]; then
    if bluetoothctl show | grep -q "Powered: yes"; then echo "on"; else echo "off"; fi
fi