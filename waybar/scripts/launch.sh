#!/usr/bin/env bash
# restart waybar
killall waybar 2>/dev/null
sleep 0.2
waybar & disown
