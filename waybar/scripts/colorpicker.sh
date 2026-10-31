#!/usr/bin/env bash
# Colour picker for waybar (needs hyprpicker + wl-clipboard)
#   colorpicker.sh      -> pick a colour, copy hex to clipboard, notify
#   colorpicker.sh -j   -> print the waybar JSON for the module
if [[ "${1:-}" == "-j" ]]; then
    printf '{"text":"󰈋","tooltip":"Pick a colour","class":"colorpicker"}\n'
    exit 0
fi

command -v hyprpicker >/dev/null || { notify-send -a Waybar "hyprpicker is not installed"; exit 1; }
color=$(hyprpicker -a -f hex 2>/dev/null) || exit 0
[[ -n "$color" ]] && notify-send -a Waybar "Colour copied" "$color"
