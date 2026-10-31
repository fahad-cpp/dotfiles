#!/usr/bin/env bash
# Pick a wallpaper from a rofi grid with thumbnails, then theme everything from it.
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
if [[ ! -d "$DIR" ]]; then
    notify-send -a Wallpaper "Wallpaper folder missing" "$DIR"
    exit 1
fi

choice=$(
    find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort |
    while read -r f; do
        printf "%s\0icon\x1f%s\n" "${f#"$DIR"/}" "$f"
    done |
    rofi -dmenu -i -show-icons -p "Wallpaper" \
        -theme-str "window { width: 900px; } listview { columns: 4; lines: 3; spacing: 10px; } element { orientation: vertical; padding: 10px; } element-icon { size: 150px; horizontal-align: 0.5; } element-text { horizontal-align: 0.5; }"
) || exit 0

[[ -n "$choice" ]] && exec "$HOME/.config/hypr/scripts/wallpaper.sh" "$DIR/$choice"
