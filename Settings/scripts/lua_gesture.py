#!/usr/bin/env python3
"""
lua_gesture.py — read/write the workspace swipe gesture in a Hyprland Lua config.

Modern Hyprland removed `gestures:workspace_swipe` and `gestures:workspace_swipe_fingers`
in favour of gesture declarations. In Lua configs that is:

    hl.gesture({
        fingers = 3,
        direction = "horizontal",
        action = "workspace"
    })

Usage:
    lua_gesture.py get                      -> {"found": bool, "enabled": bool, "fingers": int, "file": str}
    lua_gesture.py set enabled true|false
    lua_gesture.py set fingers <n>

Disabling comments the block out (prefix "-- [qs-disabled] "), enabling uncomments it,
or appends a fresh block to Configs/Input.lua (or hyprland.lua) if none exists.
"""
import json
import os
import re
import sys

HYPR_DIR = os.path.expanduser(os.environ.get("HYPR_DIR", "~/.config/hypr"))
DISABLED_PREFIX = "-- [qs-disabled] "


def candidate_files():
    files = []
    cfg = os.path.join(HYPR_DIR, "Configs")
    if os.path.isdir(cfg):
        # Input.lua first: the natural home of gestures
        names = sorted(os.listdir(cfg), key=lambda n: (n != "Input.lua", n))
        files += [os.path.join(cfg, n) for n in names if n.endswith(".lua")]
    for n in ("hyprland.lua", "custom_hypr.lua"):
        p = os.path.join(HYPR_DIR, n)
        if os.path.isfile(p):
            files.append(p)
    return files


def find_block(lines):
    """Return (start, end, disabled) of the hl.gesture block with action "workspace", or None."""
    i = 0
    while i < len(lines):
        raw = lines[i]
        stripped = raw.strip()
        disabled = stripped.startswith(DISABLED_PREFIX.strip())
        body = stripped[len(DISABLED_PREFIX.strip()):].strip() if disabled else stripped
        if body.startswith("--") or not re.match(r"hl\.gesture\s*\(", body):
            i += 1
            continue
        # collect until parens balance
        depth = 0
        j = i
        text = ""
        while j < len(lines):
            seg = lines[j].strip()
            if disabled and seg.startswith(DISABLED_PREFIX.strip()):
                seg = seg[len(DISABLED_PREFIX.strip()):]
            seg = re.sub(r"--.*$", "", seg)
            text += seg + "\n"
            depth += seg.count("(") - seg.count(")")
            if depth <= 0:
                break
            j += 1
        if re.search(r'action\s*=\s*["\']workspace["\']', text) and \
           not re.search(r'direction\s*=\s*["\'](vertical|up|down)', text):
            return i, j, disabled, text
        i = j + 1
    return None


def get():
    for path in candidate_files():
        with open(path, encoding="utf-8", errors="ignore") as f:
            lines = f.read().splitlines()
        blk = find_block(lines)
        if blk:
            _, _, disabled, text = blk
            m = re.search(r"fingers\s*=\s*(\d+)", text)
            return {"found": True, "enabled": not disabled,
                    "fingers": int(m.group(1)) if m else 3, "file": path}
    return {"found": False, "enabled": False, "fingers": 3, "file": ""}


def default_target():
    p = os.path.join(HYPR_DIR, "Configs", "Input.lua")
    return p if os.path.isfile(p) else os.path.join(HYPR_DIR, "hyprland.lua")


def write(path, lines):
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def set_value(key, val):
    info = get()
    if not info["found"]:
        if key == "enabled" and val.lower() not in ("true", "1"):
            return {"status": "ok", "note": "no gesture block; nothing to disable"}
        fingers = int(val) if key == "fingers" else 3
        path = default_target()
        with open(path, encoding="utf-8") as f:
            lines = f.read().rstrip("\n").splitlines()
        lines += ["", "hl.gesture({", f"    fingers = {fingers},",
                  '    direction = "horizontal",', '    action = "workspace"', "})"]
        write(path, lines)
        return {"status": "ok", "target": path, "created": True}

    path = info["file"]
    with open(path, encoding="utf-8") as f:
        lines = f.read().splitlines()
    start, end, disabled, _ = find_block(lines)

    if key == "enabled":
        want = val.lower() in ("true", "1")
        for k in range(start, end + 1):
            if want and disabled:
                lines[k] = lines[k].replace(DISABLED_PREFIX, "", 1)
            elif not want and not disabled:
                lead = lines[k][:len(lines[k]) - len(lines[k].lstrip())]
                lines[k] = lead + DISABLED_PREFIX + lines[k].lstrip()
    elif key == "fingers":
        n = int(val)
        done = False
        for k in range(start, end + 1):
            if re.search(r"fingers\s*=\s*\d+", lines[k]):
                lines[k] = re.sub(r"(fingers\s*=\s*)\d+", rf"\g<1>{n}", lines[k], count=1)
                done = True
                break
        if not done:
            lines[start] = re.sub(r"hl\.gesture\s*\(\s*\{", f"hl.gesture({{ fingers = {n},", lines[start], count=1)
    else:
        return {"status": "error", "message": f"unknown key {key}"}

    write(path, lines)
    try:
        import subprocess
        cur = get()
        if cur["enabled"]:
            subprocess.run(
                ["hyprctl", "eval", f'hl.gesture({{ fingers = {cur["fingers"]}, direction = "horizontal", action = "workspace" }})'],
                capture_output=True, timeout=1
            )
        else:
            subprocess.run(["hyprctl", "reload"], capture_output=True, timeout=1)
    except Exception:
        pass
    return {"status": "ok", "target": path, "key": key, "value": val}


if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "get":
        print(json.dumps(get()))
    elif len(sys.argv) == 4 and sys.argv[1] == "set":
        print(json.dumps(set_value(sys.argv[2], sys.argv[3])))
    else:
        print(__doc__)
        sys.exit(1)
