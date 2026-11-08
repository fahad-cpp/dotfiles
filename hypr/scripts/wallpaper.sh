#!/usr/bin/env bash
# wallpaper.sh [image | directory]
#   no argument  -> random picture from $WALLPAPER_DIR (default ~/Pictures/wallpapers)
#   directory    -> random picture from that directory
#   image file   -> use exactly that picture
#
# 1. dominant-color.py works out the wallpaper's real hue (matugen's own image scoring falls back to
#    blue on dark / greenish pictures)
# 2. awww sets the wallpaper
# 3. matugen builds the Material You palette from that colour and re-renders every template
#
# Optional env:
#   MATUGEN_MODE=dark|light
#   MATUGEN_SCHEME=scheme-tonal-spot|scheme-fidelity|scheme-content|scheme-vibrant|scheme-expressive|...
#       (scheme-fidelity / scheme-content stay closest to the wallpaper's own colours)
#   SOURCE_SAT=0.0-1.0   saturation of the colour handed to matugen (default: auto)
#   COLOR_PICK=matugen   use matugen's built-in image scoring instead of dominant-color.py
#   MATUGEN_INDEX=0|1|2  (COLOR_PICK=matugen only) which extracted colour to use
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
MODE="${MATUGEN_MODE:-dark}"
SCHEME="${MATUGEN_SCHEME:-scheme-content}"
TARGET="${1:-$DIR}"
COLOR_PICK=matugen

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

# the wallpaper daemon has to be up before awww is called
if ! pgrep -x awww-daemon >/dev/null; then
    (awww-daemon >/dev/null 2>&1 &)
    sleep 0.6
fi

SOURCE=""; HINT=""
if [[ "${COLOR_PICK:-auto}" != "matugen" ]]; then
    if out=$(python3 "$HERE/dominant-color.py" "$WALLPAPER" 2>/dev/null); then
        SOURCE="${out%% *}"
        [[ "$out" == *neutral* ]] && HINT="neutral"
    fi
fi

if [[ -n "$SOURCE" ]]; then
    # grayscale wallpapers: keep the palette calm instead of inventing a colour
    [[ "$HINT" == "neutral" && "$SCHEME" == "scheme-tonal-spot" ]] && SCHEME="scheme-neutral"

    awww img "$WALLPAPER" --transition-type grow --transition-pos 0.5,0.5 \
        --transition-duration 1.4 --transition-fps 60 >/dev/null 2>&1 || true
    # </dev/null: never wait for an interactive prompt
    matugen color hex "$SOURCE" -m "$MODE" -t "$SCHEME" </dev/null
else
    # fallback: matugen picks the colour itself (and sets the wallpaper via [config.wallpaper])
    # shellcheck disable=SC2086
    matugen image "$WALLPAPER" -m "$MODE" -t "$SCHEME" \
        --source-color-index "${MATUGEN_INDEX:-0}" ${MATUGEN_EXTRA:-} </dev/null
fi

mkdir -p "$HOME/.cache"
printf "%s\n" "$WALLPAPER" > "$HOME/.cache/current_wallpaper"

# restart eww so it picks up the new colors.scss (runs detached; log: ~/.cache/eww-reload.log)
bash "$HOME/.config/matugen/scripts/reload-eww.sh" || true

notify-send -a Wallpaper -i "$WALLPAPER" "Theme updated" "$(basename "$WALLPAPER")  ${SOURCE:+·  $SOURCE}" 2>/dev/null || true
