#!/usr/bin/env bash
# wallpaper.sh [image | directory]
#   no argument  -> random picture from $WALLPAPER_DIR (default ~/Pictures/wallpapers)
#   directory    -> random picture from that directory
#   image file   -> use exactly that picture
# Generates a Material You palette with matugen; matugen then sets the wallpaper (awww)
# and re-renders every template listed in ~/.config/matugen/config.toml.
#
# Optional env:  MATUGEN_MODE=dark|light   MATUGEN_SCHEME=scheme-tonal-spot|scheme-vibrant|...
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
MODE="${MATUGEN_MODE:-dark}"
SCHEME="${MATUGEN_SCHEME:-scheme-tonal-spot}"
TARGET="${1:-$DIR}"

if [[ -d "$TARGET" ]]; then
    WALLPAPER=$(find "$TARGET" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)
else
    WALLPAPER="$TARGET"
fi

if [[ -z "${WALLPAPER:-}" || ! -f "$WALLPAPER" ]]; then
    notify-send -a Wallpaper "No wallpaper found" "Looked in: $TARGET" 2>/dev/null || true
    echo "no wallpaper found in $TARGET" >&2
    exit 1
fi

# the wallpaper daemon has to be up before matugen calls awww
if ! pgrep -x awww-daemon >/dev/null; then
    (awww-daemon >/dev/null 2>&1 &)
    sleep 0.6
fi

# shellcheck disable=SC2086
matugen image "$WALLPAPER" -m "$MODE" -t "$SCHEME" ${MATUGEN_EXTRA:-} --source-color-index "${MATUGEN_INDEX:-0}" ${MATUGEN_EXTRA:-} </dev/null

mkdir -p "$HOME/.cache"
printf "%s\n" "$WALLPAPER" > "$HOME/.cache/current_wallpaper"

notify-send -a Wallpaper -i "$WALLPAPER" "Theme updated" "$(basename "$WALLPAPER")" 2>/dev/null || true
