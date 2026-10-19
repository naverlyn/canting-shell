#!/usr/bin/env python3
"""
harmonize_palette.py

Intelligent wallpaper palette engine:
1. Extracts colors from wallust and ImageMagick (if image is provided).
2. Derives a signature primary accent capturing the wallpaper's aesthetic.
3. Correctly maps true semantic colors (Cyan, Green, Orange, Red) according
   to their actual color families, gracefully synthesizing balanced pastel
   accents when the wallpaper lacks a specific hue.
4. Generates a clean, deep dark surface hierarchy with subtle undertones,
   preventing muddy, over-saturated purple or harsh high-contrast borders.
"""

import sys
import json
import colorsys
import os
import subprocess
import re

def hex_to_rgb(h):
    h = h.strip().lstrip("#")
    if len(h) != 6:
        return (0.1, 0.1, 0.1)
    return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))

def rgb_to_hex(r, g, b):
    r = max(0.0, min(1.0, r))
    g = max(0.0, min(1.0, g))
    b = max(0.0, min(1.0, b))
    return f"#{int(round(r*255)):02x}{int(round(g*255)):02x}{int(round(b*255)):02x}"

def clamp_color(h, target_l, target_s):
    h = h % 1.0
    target_l = max(0.0, min(1.0, target_l))
    target_s = max(0.0, min(1.0, target_s))
    nr, ng, nb = colorsys.hls_to_rgb(h, target_l, target_s)
    return rgb_to_hex(nr, ng, nb)

def extract_image_colors(img_path):
    if not img_path or not os.path.isfile(img_path):
        return []
    try:
        cmd = ["magick", img_path, "-resize", "120x120", "-colors", "16", "-format", "%c\\n", "histogram:info:"]
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, timeout=4).decode("utf-8", errors="ignore")
        hexes = re.findall(r"#[0-9A-Fa-f]{6}", out)
        return list(dict.fromkeys(hexes))
    except Exception:
        return []

def harmonize(json_path, img_path=None):
    if not os.path.exists(json_path):
        return

    try:
        with open(json_path, "r", encoding="utf-8") as f:
            d = json.load(f)
    except Exception as e:
        print(f"harmonize_palette: failed to load {json_path}: {e}", file=sys.stderr)
        return

    # Collect all candidate hex colors from input JSON and image
    raw_hexes = []
    for k, v in d.items():
        if isinstance(v, str) and v.startswith("#") and len(v.strip()) == 7:
            raw_hexes.append(v.strip())

    if img_path:
        img_hexes = extract_image_colors(img_path)
        raw_hexes.extend(img_hexes)

    # Convert to HLS records: (hex, h_ratio, l, s)
    candidates = []
    seen = set()
    for hx in raw_hexes:
        hx_norm = hx.upper()
        if hx_norm in seen:
            continue
        seen.add(hx_norm)
        try:
            r, g, b = hex_to_rgb(hx_norm)
            h, l, s = colorsys.rgb_to_hls(r, g, b)
            candidates.append((hx_norm, h, l, s))
        except Exception:
            continue

    # 1. Determine Signature Primary Accent
    # Vitality prefers colors that are vibrant and comfortable for UI reading (L ~ 0.55-0.75, S >= 0.25)
    vibrant = [c for c in candidates if c[3] >= 0.20 and 0.30 <= c[2] <= 0.88]
    if vibrant:
        # Score by saturation and proximity to ideal lightness (0.65)
        best_prim = max(vibrant, key=lambda c: c[3] * 1.5 * (1.0 - abs(c[2] - 0.65) * 1.2))
        primary_h = best_prim[1]
        accent_primary = clamp_color(primary_h, max(0.62, min(0.72, best_prim[2])), min(0.65, max(0.48, best_prim[3])))
    else:
        primary_h = 220.0 / 360.0
        accent_primary = "#7aa2f7"

    # 2. Semantic Color Matching / Synthesis
    def find_or_synth(h_min, h_max, fallback_h, target_l=0.68, target_s=0.52):
        matches = []
        for c, h, l, s in candidates:
            h_deg = (h * 360.0) % 360.0
            in_range = False
            if h_min <= h_max:
                in_range = (h_min <= h_deg <= h_max)
            else: # Wrap around 360 (e.g. 340 to 20 for red)
                in_range = (h_deg >= h_min or h_deg <= h_max)
            if in_range and s >= 0.16 and 0.25 <= l <= 0.90:
                matches.append((c, h, l, s))

        if matches:
            best = max(matches, key=lambda x: x[3])
            adj_s = min(0.65, max(0.45, best[3]))
            adj_l = max(0.62, min(0.72, best[2]))
            return clamp_color(best[1], adj_l, adj_s)
        else:
            return clamp_color(fallback_h / 360.0, target_l, target_s)

    # True semantic colors:
    # Cyan:   165° - 220° (fallback: 190° pastel cyan)
    # Green:  75° - 155°  (fallback: 125° pastel green)
    # Orange: 25° - 60°   (fallback: 35° warm amber/orange)
    # Red:    340° - 20°  (fallback: 355° pastel rose/red)
    accent_cyan   = find_or_synth(165, 220, 190, target_l=0.68, target_s=0.50)
    accent_green  = find_or_synth(75, 155, 125, target_l=0.68, target_s=0.48)
    accent_orange = find_or_synth(25, 60, 35, target_l=0.68, target_s=0.60)
    accent_red    = find_or_synth(340, 20, 355, target_l=0.66, target_s=0.62)

    # 3. Clean Dark Surface Hierarchy (subtle undertone derived from wallpaper, saturation strictly <= 0.07)
    bg_base     = clamp_color(primary_h, 0.08, 0.06)
    bg_surface  = clamp_color(primary_h, 0.13, 0.06)
    bg_hover    = clamp_color(primary_h, 0.18, 0.07)
    bg_selected = clamp_color(primary_h, 0.23, 0.08)
    bg_border   = clamp_color(primary_h, 0.19, 0.04)

    text_primary   = clamp_color(primary_h, 0.92, 0.03)
    text_secondary = clamp_color(primary_h, 0.72, 0.04)
    text_muted     = clamp_color(primary_h, 0.48, 0.05)

    refined = {
        "name": "Wallpaper",
        "family": "Dynamic",
        "bgBase": bg_base,
        "bgSurface": bg_surface,
        "bgHover": bg_hover,
        "bgSelected": bg_selected,
        "bgBorder": bg_border,
        "textPrimary": text_primary,
        "textSecondary": text_secondary,
        "textMuted": text_muted,
        "accentPrimary": accent_primary,
        "accentCyan": accent_cyan,
        "accentGreen": accent_green,
        "accentOrange": accent_orange,
        "accentRed": accent_red
    }

    try:
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(refined, f, indent=2)
            f.write("\n")
    except Exception as e:
        print(f"harmonize_palette: failed to write {json_path}: {e}", file=sys.stderr)

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.config/quickshell/ThemeSwitcher/wallpaper-theme.json")
    img = sys.argv[2] if len(sys.argv) > 2 else None
    harmonize(target, img)
