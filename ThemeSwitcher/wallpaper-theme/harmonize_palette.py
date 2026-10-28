#!/usr/bin/env python3
"""
harmonize_palette.py

Intelligent wallpaper palette engine:
1. Extracts a 32-color weighted pixel histogram directly from the wallpaper
   via ImageMagick.
2. Derives the signature primary accent strictly from the image's true pixel-area
   hue dominance (ignoring Wallust's area-blind k-means slots so tiny high-chroma
   details like a ribbon/necktie cannot hijack Primary).
3. Maps semantic colors (Cyan, Green, Orange, Red) according to their true color
   families while keeping them visually distinct from Primary.
4. Generates a clean, deep dark surface hierarchy with subtle undertones.
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


def hue_dist_deg(h1_deg, h2_deg):
    d = abs(h1_deg - h2_deg) % 360.0
    return 360.0 - d if d > 180.0 else d


def extract_image_histogram(img_path):
    """Return list of (hex_color, pixel_fraction) extracted from the image histogram."""
    if not img_path or not os.path.isfile(img_path):
        return []
    try:
        cmd = [
            "magick", img_path,
            "-resize", "150x150",
            "-colors", "32",
            "-format", "%c\n",
            "histogram:info:"
        ]
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, timeout=4).decode("utf-8", errors="ignore")
        records = []
        total = 0
        for line in out.splitlines():
            m = re.search(r"^\s*(\d+):.*?#([0-9A-Fa-f]{6})", line)
            if m:
                cnt = int(m.group(1))
                hx = "#" + m.group(2).upper()
                records.append((hx, cnt))
                total += cnt
        if total > 0:
            merged = {}
            for hx, cnt in records:
                merged[hx] = merged.get(hx, 0) + cnt
            return [(hx, cnt / total) for hx, cnt in merged.items()]
        hexes = re.findall(r"#[0-9A-Fa-f]{6}", out)
        uniq = list(dict.fromkeys(h.upper() for h in hexes))
        return [(hx, 1.0 / max(1, len(uniq))) for hx in uniq]
    except Exception:
        return []


def write_hyprlock_palette(refined):
    """Write a complete Hyprlock color palette (both wallust $color0..15 and semantic $accent/$blue/$surface0/$text)
    from the harmonized wallpaper theme so hyprlock dynamically adapts to wallpaper changes."""
    def strip_hash(hx):
        return hx.lstrip("#").lower()

    p_hex = strip_hash(refined["accentPrimary"])
    c_hex = strip_hash(refined["accentCyan"])
    g_hex = strip_hash(refined["accentGreen"])
    o_hex = strip_hash(refined["accentOrange"])
    r_hex = strip_hash(refined["accentRed"])
    bg_base = strip_hash(refined["bgBase"])
    bg_surf = strip_hash(refined["bgSurface"])
    bg_hov  = strip_hash(refined["bgHover"])
    bg_sel  = strip_hash(refined["bgSelected"])
    bg_bdr  = strip_hash(refined["bgBorder"])
    txt_pri = strip_hash(refined["textPrimary"])
    txt_sec = strip_hash(refined["textSecondary"])
    txt_mut = strip_hash(refined["textMuted"])

    lines = [
        "# Dynamic Hyprlock palette generated from wallpaper-theme.json",
        f"$background = rgb({bg_base})",
        f"$foreground = rgb({txt_pri})",
        f"$color0 = rgb({bg_surf})",
        f"$color1 = rgb({r_hex})",
        f"$color2 = rgb({g_hex})",
        f"$color3 = rgb({o_hex})",
        f"$color4 = rgb({c_hex})",
        f"$color5 = rgb({p_hex})",
        f"$color6 = rgb({c_hex})",
        f"$color7 = rgb({txt_sec})",
        f"$color8 = rgb({txt_mut})",
        f"$color9 = rgb({r_hex})",
        f"$color10 = rgb({txt_sec})",
        f"$color11 = rgb({o_hex})",
        f"$color12 = rgb({c_hex})",
        f"$color13 = rgb({p_hex})",
        f"$color14 = rgb({g_hex})",
        f"$color15 = rgb({txt_pri})",
        "",
        "# Semantic & Catppuccin variable aliases mapped to dynamic wallpaper palette",
        f"$accent = rgb({p_hex})",
        f"$accentAlpha = {p_hex}",
        f"$accentPrimary = rgb({p_hex})",
        f"$mauve = rgb({p_hex})",
        f"$mauveAlpha = {p_hex}",
        f"$blue = rgb({c_hex})",
        f"$blueAlpha = {c_hex}",
        f"$sapphire = rgb({c_hex})",
        f"$sapphireAlpha = {c_hex}",
        f"$sky = rgb({c_hex})",
        f"$skyAlpha = {c_hex}",
        f"$teal = rgb({g_hex})",
        f"$tealAlpha = {g_hex}",
        f"$green = rgb({g_hex})",
        f"$greenAlpha = {g_hex}",
        f"$yellow = rgb({o_hex})",
        f"$yellowAlpha = {o_hex}",
        f"$peach = rgb({o_hex})",
        f"$peachAlpha = {o_hex}",
        f"$maroon = rgb({r_hex})",
        f"$maroonAlpha = {r_hex}",
        f"$red = rgb({r_hex})",
        f"$redAlpha = {r_hex}",
        f"$pink = rgb({p_hex})",
        f"$pinkAlpha = {p_hex}",
        f"$flamingo = rgb({r_hex})",
        f"$flamingoAlpha = {r_hex}",
        f"$rosewater = rgb({txt_pri})",
        f"$rosewaterAlpha = {txt_pri}",
        f"$lavender = rgb({c_hex})",
        f"$lavenderAlpha = {c_hex}",
        f"$text = rgb({txt_pri})",
        f"$textAlpha = {txt_pri}",
        f"$subtext1 = rgb({txt_sec})",
        f"$subtext1Alpha = {txt_sec}",
        f"$subtext0 = rgb({txt_mut})",
        f"$subtext0Alpha = {txt_mut}",
        f"$overlay2 = rgb({txt_mut})",
        f"$overlay2Alpha = {txt_mut}",
        f"$overlay1 = rgb({bg_sel})",
        f"$overlay1Alpha = {bg_sel}",
        f"$overlay0 = rgb({bg_hov})",
        f"$overlay0Alpha = {bg_hov}",
        f"$surface2 = rgb({bg_sel})",
        f"$surface2Alpha = {bg_sel}",
        f"$surface1 = rgb({bg_hov})",
        f"$surface1Alpha = {bg_hov}",
        f"$surface0 = rgb({bg_surf})",
        f"$surface0Alpha = {bg_surf}",
        f"$base = rgb({bg_base})",
        f"$baseAlpha = {bg_base}",
        f"$mantle = rgb({bg_base})",
        f"$mantleAlpha = {bg_base}",
        f"$crust = rgb({bg_base})",
        f"$crustAlpha = {bg_base}",
        ""
    ]
    content = "\n".join(lines)
    targets = [
        os.path.expanduser("~/.config/quickshell/Settings/scripts/wallust-hyprlock.conf"),
        os.path.expanduser("~/.config/hypr/wallust/wallust-hyprland.conf"),
        os.path.expanduser("~/.config/hypr/mocha.conf")
    ]
    for t in targets:
        try:
            os.makedirs(os.path.dirname(t), exist_ok=True)
            with open(t, "w", encoding="utf-8") as f:
                f.write(content)
        except Exception:
            pass


def build_candidate(hx_norm, w):
    r, g, b = hex_to_rgb(hx_norm)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    chroma = max(r, g, b) - min(r, g, b)
    h_deg = (h * 360.0) % 360.0
    if chroma >= 0.09 and 0.12 <= l <= 0.84:
        # Penalize warm pale skin tones so character skin doesn't beat hair/clothes/scenery
        skin_penalty = 0.20 if ((h_deg <= 38.0 or h_deg >= 345.0) and l > 0.68 and chroma < 0.24) else 1.0
        # Strictly linear pixel area weight * capped chroma so tiny 0.3% details cannot beat 20% dominant colors
        area_score = w * min(0.35, chroma) * skin_penalty
    else:
        area_score = 0.0
    return {
        "hex": hx_norm,
        "h": h,
        "h_deg": h_deg,
        "l": l,
        "s": s,
        "chroma": chroma,
        "w": w,
        "area_score": area_score,
        "total_score": 0.0
    }


def harmonize(json_path, img_path=None):
    raw_staging = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".raw-palette.json")
    source_path = raw_staging if (img_path and os.path.exists(raw_staging)) else json_path

    d = {}
    if os.path.exists(source_path):
        try:
            with open(source_path, "r", encoding="utf-8") as f:
                d = json.load(f)
        except Exception as e:
            print(f"harmonize_palette: failed to load {source_path}: {e}", file=sys.stderr)
            if not img_path:
                return
    elif not img_path:
        return

    # If already harmonized and no new image was passed, just sync the hyprlock palette directly
    if not img_path and "color0" not in d and "accentPrimary" in d and "bgSurface" in d:
        write_hyprlock_palette(d)
        return

    img_hist = extract_image_histogram(img_path) if img_path else []

    # Deduplicated JSON colors from Wallust/Matugen
    json_hexes = []
    for k, v in d.items():
        if isinstance(v, str) and v.startswith("#") and len(v.strip()) == 7:
            hx_norm = v.strip().upper()
            if hx_norm not in json_hexes:
                json_hexes.append(hx_norm)

    # Primary candidates come strictly from the true image histogram when available,
    # so Wallust's area-blind k-means slots never distort pixel dominance.
    if img_hist:
        primary_candidates = [build_candidate(hx, w) for hx, w in img_hist]
    else:
        eq_w = 1.0 / max(1, len(json_hexes))
        primary_candidates = [build_candidate(hx, eq_w) for hx in json_hexes]

    # 1. Determine Signature Primary Accent via Linear Area Hue-Clustering (±35°)
    for c in primary_candidates:
        cluster_score = 0.0
        for other in primary_candidates:
            dist = hue_dist_deg(c["h_deg"], other["h_deg"])
            if dist <= 35.0:
                cluster_score += other["area_score"] * (1.0 - (dist / 45.0))
        c["total_score"] = (
            cluster_score * (0.5 + 0.5 * min(0.35, c["chroma"]) / 0.35)
            if c["area_score"] > 0.0 else 0.0
        )

    chromatic = [c for c in primary_candidates if c["total_score"] > 0.0]
    if chromatic:
        best_prim = max(chromatic, key=lambda c: c["total_score"])
        primary_h = best_prim["h"]
        target_l = max(0.64, min(0.72, best_prim["l"]))
        target_s = min(0.68, max(0.55, best_prim["s"] * 1.4))
        accent_primary = clamp_color(primary_h, target_l, target_s)
    else:
        primary_h = 220.0 / 360.0
        accent_primary = "#7aa2f7"

    prim_deg = (primary_h * 360.0) % 360.0

    # Pool for secondary semantic colors (image histogram + tiny-weight fallback from JSON)
    semantic_candidates = list(primary_candidates)
    seen_hexes = {c["hex"] for c in semantic_candidates}
    for hx in json_hexes:
        if hx not in seen_hexes:
            semantic_candidates.append(build_candidate(hx, 0.002))
            seen_hexes.add(hx)

    # 2. Semantic Color Matching / Synthesis
    def find_or_synth(h_min, h_max, fallback_h, target_l=0.68, target_s=0.55, avoid_h_deg=None):
        matches = []
        for c in semantic_candidates:
            h_deg = c["h_deg"]
            if h_min <= h_max:
                in_range = (h_min <= h_deg <= h_max)
            else:  # Wrap around 360 (e.g. 340 to 20 for red)
                in_range = (h_deg >= h_min or h_deg <= h_max)
            if in_range and c["chroma"] >= 0.14 and 0.22 <= c["l"] <= 0.84:
                if avoid_h_deg is not None and hue_dist_deg(h_deg, avoid_h_deg) < 12.0:
                    continue
                matches.append(c)

        if matches:
            best = max(matches, key=lambda x: x["chroma"] * (x["w"] ** 0.35))
            adj_s = min(0.65, max(0.48, best["s"] * 1.25))
            adj_l = max(0.64, min(0.72, best["l"]))
            return clamp_color(best["h"], adj_l, adj_s)
        else:
            return clamp_color(fallback_h / 360.0, target_l, target_s)

    # True semantic colors (kept distinct from Primary so swatches don't duplicate):
    cyan_fallback = 192.0 if hue_dist_deg(prim_deg, 192.0) >= 14.0 else 212.0
    accent_cyan   = find_or_synth(165, 206, cyan_fallback, target_l=0.68, target_s=0.55, avoid_h_deg=prim_deg)
    accent_green  = find_or_synth(75, 155, 135, target_l=0.68, target_s=0.50, avoid_h_deg=prim_deg)
    accent_orange = find_or_synth(25, 60, 35, target_l=0.68, target_s=0.60, avoid_h_deg=prim_deg)
    accent_red    = find_or_synth(340, 20, 355, target_l=0.67, target_s=0.62, avoid_h_deg=prim_deg)

    # 3. Clean Dark Surface Hierarchy (subtle undertone derived from wallpaper primary hue)
    bg_base     = clamp_color(primary_h, 0.08, 0.07)
    bg_surface  = clamp_color(primary_h, 0.13, 0.07)
    bg_hover    = clamp_color(primary_h, 0.18, 0.08)
    bg_selected = clamp_color(primary_h, 0.23, 0.09)
    bg_border   = clamp_color(primary_h, 0.19, 0.05)

    text_primary   = clamp_color(primary_h, 0.92, 0.04)
    text_secondary = clamp_color(primary_h, 0.72, 0.05)
    text_muted     = clamp_color(primary_h, 0.48, 0.06)

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

    write_hyprlock_palette(refined)


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.config/quickshell/ThemeSwitcher/wallpaper-theme.json")
    img = sys.argv[2] if len(sys.argv) > 2 else None
    harmonize(target, img)
