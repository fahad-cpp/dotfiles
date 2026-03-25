#!/bin/bash

WALLPAPER="$1"

if [ -z "$WALLPAPER" ]; then
	WALLPAPER=$(find ~/Pictures/wallpapers -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)
fi

awww query || awww init

awww img "$WALLPAPER" --transition-type wipe --transition-angle 45 --transition-duration 1.5
wal -i "$WALLPAPER" -n

hyprctl reload

pkill -SIGUSR2 waybar 2>/dev/null
