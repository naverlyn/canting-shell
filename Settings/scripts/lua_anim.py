#!/usr/bin/env python3
"""
lua_anim.py — convert a hyprlang animation preset (.conf) to Hyprland Lua.

    lua_anim.py <preset.conf> <out.lua>

hyprlang:  bezier = NAME, X1, Y1, X2, Y2
           animation = LEAF, ONOFF, SPEED, CURVE[, STYLE]
Lua:       hl.curve("NAME", { type = "bezier", points = { {X1, Y1}, {X2, Y2} } })
           hl.animation({ leaf = "LEAF", enabled = true, speed = S, bezier = "CURVE", style = "STYLE" })

The output is a standalone file (custom_animations.lua) required *after* the user's
own configs, so preset curves/animations override the defaults without touching them.
"""
import re
import sys


def q(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def convert(text):
    out = ["-- Animation preset managed by Quickshell Settings (generated, do not edit by hand)",
           "-- Converted from hyprlang preset; re-apply a preset to regenerate.", ""]
    enabled = True
    curves, anims = [], []
    for raw in text.splitlines():
        line = re.sub(r"#.*$", "", raw).strip()
        m = re.match(r"^(\w+)\s*=\s*(.+)$", line)
        if not m:
            continue
        key, val = m.group(1).lower(), m.group(2).strip()
        parts = [p.strip() for p in val.split(",")]
        if key == "enabled":
            enabled = val.lower() in ("yes", "true", "1", "on")
        elif key == "bezier" and len(parts) >= 5:
            n, x1, y1, x2, y2 = parts[:5]
            curves.append(f'hl.curve({q(n)}, {{ type = "bezier", points = {{ {{{x1}, {y1}}}, {{{x2}, {y2}}} }} }})')
        elif key == "animation" and len(parts) >= 2:
            leaf, on = parts[0], parts[1] in ("1", "yes", "true", "on")
            fields = [f"leaf = {q(leaf)}", f"enabled = {'true' if on else 'false'}"]
            if on and len(parts) >= 3 and parts[2]:
                try:
                    spd = min(100.0, max(0.01, float(parts[2])))
                    spd_str = str(int(spd)) if spd.is_integer() else str(spd)
                except ValueError:
                    spd_str = parts[2]
                fields.append(f"speed = {spd_str}")
            if on and len(parts) >= 4 and parts[3]:
                fields.append(f"bezier = {q(parts[3])}")
            if on and len(parts) >= 5 and parts[4]:
                fields.append(f"style = {q(', '.join(parts[4:]))}")
            anims.append("hl.animation({ " + ", ".join(fields) + " })")
    # animations.enabled is deliberately NOT written here: the Settings master toggle owns it
    # (it lives in the user's own config). The caller reads it from preset_enabled().
    out += curves
    if curves:
        out.append("")
    out += anims
    return "\n".join(out) + "\n"


def preset_enabled(text):
    m = re.search(r"^\s*enabled\s*=\s*(\w+)", text, re.MULTILINE)
    return not m or m.group(1).lower() in ("yes", "true", "1", "on")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    with open(sys.argv[1], encoding="utf-8", errors="ignore") as f:
        src = f.read()
    with open(sys.argv[2], "w", encoding="utf-8") as f:
        f.write(convert(src))
    print("true" if preset_enabled(src) else "false")
