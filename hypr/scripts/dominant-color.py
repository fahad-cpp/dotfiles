#!/usr/bin/env python3
"""
dominant-color.py <image>

Prints a source colour for matugen, chosen the way a human would: "what colour is this wallpaper?"

matugen's built-in image scoring throws away dark / low-saturation pixels and falls back to
Google-blue when nothing scores well. That's why black-ish and dark-green wallpapers came out blue.
Here we look at the hue histogram instead (weighted by saturation, ignoring pure black/white),
take the strongest hue, and hand matugen a clean, saturated colour with that hue.

Output:  "#rrggbb"            normal image
         "#rrggbb neutral"    (almost) grayscale image -> use scheme-neutral

Env:  SOURCE_SAT  saturation (0-1) of the colour handed to matugen, default 0.60
Needs one of: python-pillow, ImageMagick (magick/convert), ffmpeg.
"""
import colorsys, math, os, shutil, subprocess, sys

SIZE = 64


def load_pixels(path):
    try:
        from PIL import Image
        im = Image.open(path).convert("RGB").resize((SIZE, SIZE))
        raw = im.tobytes()
        return [tuple(raw[i:i + 3]) for i in range(0, len(raw), 3)]
    except ImportError:
        pass
    cmds = []
    for tool in ("magick", "convert"):
        if shutil.which(tool):
            cmds.append([tool, f"{path}[0]", "-resize", f"{SIZE}x{SIZE}!", "-depth", "8", "rgb:-"])
            break
    if shutil.which("ffmpeg"):
        cmds.append(["ffmpeg", "-v", "error", "-i", path, "-vf", f"scale={SIZE}:{SIZE}",
                     "-frames:v", "1", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"])
    for cmd in cmds:
        try:
            raw = subprocess.run(cmd, capture_output=True, timeout=30, check=True).stdout
        except Exception:
            continue
        if len(raw) >= SIZE * SIZE * 3:
            raw = raw[:SIZE * SIZE * 3]
            return [tuple(raw[i:i + 3]) for i in range(0, len(raw), 3)]
    return None


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: dominant-color.py <image>")
    px = load_pixels(sys.argv[1])
    if not px:
        sys.exit("no image loader available (install python-pillow, imagemagick or ffmpeg)")

    bins = [0.0] * 36
    items = []                       # (hue_deg, weight, sat)
    total_w = 0.0
    sum_r = sum_g = sum_b = 0
    for r, g, b in px:
        sum_r += r; sum_g += g; sum_b += b
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        if v < 0.035 or s < 0.10:     # near-black or near-gray: hue is meaningless
            continue
        w = (s ** 1.3) * (0.4 + min(v, 0.8))
        hd = h * 360
        bins[int(hd // 10) % 36] += w
        items.append((hd, w, s))
        total_w += w

    n = len(px)
    # almost no colourful pixels -> grayscale-ish wallpaper
    if total_w < n * 0.01:
        mr, mg, mb = sum_r // n, sum_g // n, sum_b // n
        print("#%02x%02x%02x neutral" % (mr, mg, mb))
        return

    smooth = [bins[(i - 1) % 36] + 2 * bins[i] + bins[(i + 1) % 36] for i in range(36)]
    peak = max(range(36), key=lambda i: smooth[i]) * 10 + 5

    x = y = ws = sat_acc = 0.0
    for hd, w, s in items:
        d = abs((hd - peak + 180) % 360 - 180)
        if d <= 30:
            x += math.cos(math.radians(hd)) * w
            y += math.sin(math.radians(hd)) * w
            sat_acc += s * w
            ws += w
    hue = (math.degrees(math.atan2(y, x)) % 360) / 360
    avg_sat = sat_acc / ws if ws else 0.6

    out_sat = float(os.environ.get("SOURCE_SAT", 0)) or max(0.5, min(0.85, avg_sat * 1.15))
    r, g, b = colorsys.hsv_to_rgb(hue, out_sat, 0.78)
    print("#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255)))


if __name__ == "__main__":
    main()
