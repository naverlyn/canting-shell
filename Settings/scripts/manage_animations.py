#!/usr/bin/env python3
"""
manage_animations.py

Manages Hyprland animations, presets, bezier curves, and toggle state for Quickshell Settings.
Portable across Vanilla Hyprland, modular dotfiles, and Hyprland Lua setups.
"""

import glob
import json
import os
import re
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BUNDLED_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "presets", "animations"))
BACKUP_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "backups"))
HYPR_DIR = os.path.expanduser(os.environ.get("HYPR_DIR", "~/.config/hypr"))
ANIM_DIR = os.path.join(HYPR_DIR, "animations")
HYPR_CONF = os.path.join(HYPR_DIR, "hyprland.conf")


def run_cmd(cmd, timeout=2.0):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except Exception:
        return None


def find_user_conf():
    if os.path.isfile(os.path.join(HYPR_DIR, "hyprland.lua")):
        for rel in ("Configs/WindowDecoration.lua", "custom_animations.lua"):
            p = os.path.join(HYPR_DIR, rel)
            if os.path.isfile(p):
                return p
    for rel in ("animations.conf", "custom_animations.conf"):
        p = os.path.join(HYPR_DIR, rel)
        if os.path.isfile(p):
            return p
    if os.path.isfile(os.path.join(HYPR_DIR, "hyprland.lua")):
        return os.path.join(HYPR_DIR, "Configs/WindowDecoration.lua")
    return os.path.join(HYPR_DIR, "animations.conf")


def ensure_dirs():
    os.makedirs(BACKUP_DIR, exist_ok=True)
    uconf = find_user_conf()
    os.makedirs(os.path.dirname(uconf), exist_ok=True)
    if not os.path.isdir(ANIM_DIR) or not os.listdir(ANIM_DIR):
        os.makedirs(ANIM_DIR, exist_ok=True)
        if os.path.isdir(BUNDLED_DIR):
            for src in glob.glob(os.path.join(BUNDLED_DIR, "*.conf")):
                dst = os.path.join(ANIM_DIR, os.path.basename(src))
                if not os.path.exists(dst):
                    try:
                        shutil.copy2(src, dst)
                    except OSError:
                        pass
    if not os.path.isfile(uconf) and not uconf.endswith(".lua"):
        for cand in (os.path.join(ANIM_DIR, "00-default.conf"), os.path.join(BUNDLED_DIR, "00-default.conf")):
            if os.path.isfile(cand):
                try:
                    shutil.copy2(cand, uconf)
                except OSError:
                    pass
                break


def parse_preset_info(content, filename):
    base = os.path.splitext(filename)[0]

    if " - " in base:
        family = base.split(" - ")[0].strip()
    elif base.startswith(("00", "01", "03")):
        family = "Standard"
    elif "END" in base:
        family = "END"
    elif "Mahaveer" in base:
        family = "Mahaveer"
    else:
        family = "Custom"

    display_name = base
    if " - " in base:
        parts = base.split(" - ")
        if parts[0].strip() in ("HYDE", "ML4W", "Mahaveer", "Custom"):
            display_name = parts[1].strip()
    elif base == "00-default":
        display_name = "Default Classic"
    elif base == "01-default - v2":
        display_name = "Default v2"

    beziers = [
        {"name": m.group(1).strip(), "curve": m.group(2).strip()}
        for m in re.finditer(r"^\s*bezier\s*=\s*([^,]+),\s*(.+)$", content, re.MULTILINE)
    ]

    anims = []
    for m in re.finditer(
        r"^\s*animation\s*=\s*([^,]+),\s*(\d+),\s*([0-9.]+),\s*([^,\n\r]+)(?:,\s*([^\n\r#]+))?",
        content, re.MULTILINE,
    ):
        anims.append({
            "target": m.group(1).strip(),
            "enabled": bool(int(m.group(2))),
            "speed": float(m.group(3)),
            "curve": m.group(4).strip(),
            "style": (m.group(5) or "").strip(),
        })

    if not beziers:
        for m in re.finditer(
            r"""hl\.curve\s*\(\s*["']([^"']+)["']\s*,\s*\{[^\n]*?points\s*=\s*\{\s*\{\s*([^,}]+),\s*([^}]+)\}\s*,\s*\{\s*([^,}]+),\s*([^}]+)\}""",
            content,
        ):
            pts = f"{m.group(2).strip()}, {m.group(3).strip()}, {m.group(4).strip()}, {m.group(5).strip()}"
            beziers.append({"name": m.group(1).strip(), "curve": pts})

    if not anims:
        for m in re.finditer(r"hl\.animation\s*\(\s*\{([^}]+)\}\s*\)", content):
            body = m.group(1)
            leaf_m = re.search(r"""leaf\s*=\s*["']([^"']+)["']""", body)
            if not leaf_m:
                continue
            en_m = re.search(r"enabled\s*=\s*(true|false)", body)
            spd_m = re.search(r"speed\s*=\s*([0-9.]+)", body)
            crv_m = re.search(r"""(?:bezier|spring)\s*=\s*["']([^"']+)["']""", body)
            sty_m = re.search(r"""style\s*=\s*["']([^"']+)["']""", body)
            anims.append({
                "target": leaf_m.group(1).strip(),
                "enabled": (en_m.group(1) == "true") if en_m else True,
                "speed": float(spd_m.group(1)) if spd_m else 4.0,
                "curve": crv_m.group(1).strip() if crv_m else "default",
                "style": sty_m.group(1).strip() if sty_m else "",
            })

    desc = f"{len(beziers)} bezier curves, {len(anims)} rules"
    low = base.lower()
    if family == "Custom":
        desc = "User-created custom animation profile"
    elif "disable" in low:
        desc = "Disables all compositor animations for instant response"
    elif "fast" in low:
        desc = "Snappy, high-acceleration curves with reduced latency"
    elif "minimal" in low:
        desc = "Lightweight, subtle transitions for minimal distraction"
    elif "vertical" in low:
        desc = "Vertical workspace transitions with fluid momentum"
    elif "moving" in low:
        desc = "Dynamic window and workspace motion with overshooting"
    elif "classic" in low:
        desc = "Smooth cubic ease-out curves with balanced timing"
    elif "optimized" in low:
        desc = "Carefully tuned for low GPU overhead and clean visuals"

    return {
        "id": base,
        "name": base,
        "displayName": display_name,
        "family": family,
        "isCustom": (family == "Custom" or base.startswith("Custom - ")),
        "description": desc,
        "bezierCount": len(beziers),
        "animCount": len(anims),
        "beziers": beziers,
        "animations": anims,
    }


def get_status():
    ensure_dirs()
    user_conf = find_user_conf()
    user_content = ""
    if user_conf and os.path.exists(user_conf):
        with open(user_conf, "r", encoding="utf-8", errors="ignore") as f:
            user_content = f.read()

    local_state = os.path.join(BACKUP_DIR, ".animations_enabled")
    is_enabled = None
    if os.path.exists(local_state):
        try:
            with open(local_state, "r", encoding="utf-8") as ef:
                st = ef.read().strip().lower()
            if st in ("true", "1", "yes"):
                is_enabled = True
            elif st in ("false", "0", "no"):
                is_enabled = False
        except Exception:
            pass

    if is_enabled is None:
        if user_conf.endswith(".lua"):
            lua_m = re.search(r"animations\s*=\s*\{[^}]*?enabled\s*=\s*(true|false)", user_content, re.DOTALL | re.IGNORECASE)
            is_enabled = (lua_m.group(1).lower() == "true") if lua_m else True
        else:
            em = re.search(r"^\s*enabled\s*=\s*(yes|true|1|no|false|0)", user_content, re.MULTILINE | re.IGNORECASE)
            is_enabled = (em.group(1).lower() in ("yes", "true", "1")) if em else True

    state_file = os.path.join(BACKUP_DIR, ".current_animation")
    saved_preset = ""
    if os.path.exists(state_file):
        try:
            with open(state_file, "r", encoding="utf-8") as sf:
                saved_preset = sf.read().strip()
        except Exception:
            pass

    seen = set()
    all_conf_paths = []
    for d in (ANIM_DIR, BUNDLED_DIR):
        if os.path.isdir(d):
            for p in sorted(glob.glob(os.path.join(d, "*.conf"))):
                fn = os.path.basename(p)
                if fn not in seen:
                    seen.add(fn)
                    all_conf_paths.append(p)

    user_clean = re.sub(r"#.*", "", user_content).strip()
    presets = []
    candidates_exact = []
    candidates_normalized = []

    for p in all_conf_paths:
        fn = os.path.basename(p)
        try:
            with open(p, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
        except Exception:
            continue

        info = parse_preset_info(content, fn)
        preset_clean = re.sub(r"#.*", "", content).strip()
        if user_content.strip() == content.strip():
            candidates_exact.append(info["id"])
        elif user_clean and user_clean == preset_clean:
            candidates_normalized.append(info["id"])
        info["active"] = False
        presets.append(info)

    saved_preset_id = re.sub(r"\.conf$", "", saved_preset) if saved_preset else ""
    preset_ids = {item["id"] for item in presets}
    active_preset_id = ""
    if saved_preset_id and (saved_preset_id in candidates_exact or saved_preset_id in candidates_normalized):
        active_preset_id = saved_preset_id
    elif candidates_exact:
        active_preset_id = candidates_exact[0]
    elif candidates_normalized:
        active_preset_id = candidates_normalized[0]
    elif saved_preset_id and saved_preset_id in preset_ids and user_conf.endswith(".lua"):
        active_preset_id = saved_preset_id

    if active_preset_id:
        for item in presets:
            if item["id"] == active_preset_id:
                item["active"] = True
                break

    anim_source = user_content
    custom_lua_anim = os.path.join(HYPR_DIR, "custom_animations.lua")
    if os.path.exists(custom_lua_anim):
        try:
            with open(custom_lua_anim, "r", encoding="utf-8", errors="ignore") as cf:
                anim_source = cf.read()
        except Exception:
            pass
    current_info = parse_preset_info(anim_source, "current")

    print(json.dumps({
        "enabled": is_enabled,
        "currentPreset": active_preset_id or "Custom",
        "presets": presets,
        "activeBeziers": current_info["beziers"],
        "activeRules": current_info["animations"],
    }))


def write_text(path, text):
    try:
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
    except OSError:
        pass


def set_enabled(target="true", emit_json=True):
    ensure_dirs()
    is_on = str(target).lower() in ("true", "1", "yes")
    target_str = "true" if is_on else "false"
    kw = "yes" if is_on else "no"
    hypr_val = "1" if is_on else "0"

    write_text(os.path.join(BACKUP_DIR, ".animations_enabled"), target_str)

    user_conf = find_user_conf()
    conf_name = os.path.basename(user_conf)
    if os.path.isfile(user_conf):
        try:
            shutil.copy2(user_conf, os.path.join(BACKUP_DIR, f"{conf_name}.pre_toggle"))
        except OSError:
            pass
        try:
            with open(user_conf, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            if user_conf.endswith(".lua"):
                if re.search(r"animations\s*=\s*\{", content):
                    pat = r"(animations\s*=\s*\{[^}]*?enabled\s*=\s*)(true|false)"
                    if re.search(pat, content, re.DOTALL):
                        new_content = re.sub(pat, rf"\g<1>{target_str}", content, count=1, flags=re.DOTALL)
                    else:
                        new_content = re.sub(r"(animations\s*=\s*\{)", rf"\1\n        enabled = {target_str},", content, count=1)
                else:
                    new_content = content.rstrip() + f"\nhl.config({{\n    animations = {{\n        enabled = {target_str},\n    }},\n}})\n"
            else:
                if re.search(r"^\s*enabled\s*=", content, re.MULTILINE):
                    new_content = re.sub(r"^\s*enabled\s*=.*", f"  enabled = {kw}", content, flags=re.MULTILINE)
                elif re.search(r"animations\s*\{", content):
                    new_content = re.sub(r"animations\s*\{", f"animations {{\n  enabled = {kw}", content, count=1)
                else:
                    new_content = f"animations {{\n  enabled = {kw}\n\n" + content + "\n}\n"
            write_text(user_conf, new_content)
        except Exception:
            pass

    if shutil.which("hyprctl"):
        if os.path.isfile(os.path.join(HYPR_DIR, "hyprland.lua")):
            run_cmd(["hyprctl", "eval", f"hl.config({{ animations = {{ enabled = {target_str} }} }})"])
        else:
            run_cmd(["hyprctl", "keyword", "animations:enabled", hypr_val])
            run_cmd(["hyprctl", "reload"])

    if emit_json:
        print(json.dumps({"success": True, "enabled": is_on}))


def apply_preset(preset_name, emit_json=True):
    if not preset_name:
        if emit_json:
            print(json.dumps({"success": False, "error": "No preset specified"}))
        sys.exit(1)

    target_file = None
    for d in (ANIM_DIR, BUNDLED_DIR):
        for cand in (os.path.join(d, f"{preset_name}.conf"), os.path.join(d, preset_name)):
            if os.path.isfile(cand):
                target_file = cand
                break
        if target_file:
            break

    if not target_file:
        if emit_json:
            print(json.dumps({"success": False, "error": f"Preset file not found: {preset_name}"}))
        sys.exit(1)

    ensure_dirs()
    user_conf = find_user_conf()
    conf_name = os.path.basename(user_conf)
    if os.path.isfile(user_conf):
        try:
            shutil.copy2(user_conf, os.path.join(BACKUP_DIR, f"{conf_name}.pre_preset"))
        except OSError:
            pass

    hl_lua = os.path.join(HYPR_DIR, "hyprland.lua")
    if os.path.isfile(hl_lua):
        lua_out = os.path.join(HYPR_DIR, "custom_animations.lua")
        if os.path.isfile(lua_out):
            try:
                shutil.copy2(lua_out, os.path.join(BACKUP_DIR, "custom_animations.lua.pre_preset"))
            except OSError:
                pass
        res = run_cmd(["python3", os.path.join(SCRIPT_DIR, "lua_anim.py"), target_file, lua_out], timeout=5.0)
        if not res or res.returncode != 0:
            if emit_json:
                print(json.dumps({"success": False, "error": "Failed to convert preset to Lua"}))
            sys.exit(1)
        preset_on = res.stdout.strip() or "true"
        try:
            with open(hl_lua, "r", encoding="utf-8", errors="ignore") as f:
                hl_txt = f.read()
            if "custom_animations" not in hl_txt:
                with open(hl_lua, "a", encoding="utf-8") as f:
                    f.write('\npcall(require, "custom_animations")\n')
        except OSError:
            pass
        write_text(os.path.join(BACKUP_DIR, ".current_animation"), preset_name)
        if shutil.which("hyprctl"):
            run_cmd(["hyprctl", "eval", f'dofile("{lua_out}")'])
        set_enabled(preset_on, emit_json=False)
        if emit_json:
            print(json.dumps({"success": True, "preset": preset_name, "target": lua_out}))
        return

    try:
        shutil.copyfile(target_file, user_conf)
    except OSError:
        pass
    write_text(os.path.join(BACKUP_DIR, ".current_animation"), preset_name)
    write_text(os.path.join(BACKUP_DIR, ".animations_enabled"), "true")

    if os.path.isfile(HYPR_CONF):
        try:
            with open(HYPR_CONF, "r", encoding="utf-8", errors="ignore") as f:
                hc_txt = f.read()
            if conf_name not in hc_txt:
                src_line = f"source = ~/.config/hypr/{conf_name}"
                with open(HYPR_CONF, "a", encoding="utf-8") as f:
                    f.write(f"\n{src_line}\n")
        except OSError:
            pass

    if shutil.which("hyprctl"):
        try:
            with open(target_file, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    trimmed = line.strip()
                    m_bez = re.match(r"^bezier\s*=\s*(.*)", trimmed)
                    m_ani = re.match(r"^animation\s*=\s*(.*)", trimmed)
                    if m_bez:
                        run_cmd(["hyprctl", "keyword", "bezier", m_bez.group(1)])
                    elif m_ani:
                        run_cmd(["hyprctl", "keyword", "animation", m_ani.group(1)])
        except OSError:
            pass
        run_cmd(["hyprctl", "reload"])

    if emit_json:
        print(json.dumps({"success": True, "preset": preset_name}))


def save_custom(payload):
    if not payload:
        print(json.dumps({"success": False, "error": "No configuration payload provided"}))
        sys.exit(1)

    ensure_dirs()
    try:
        data = json.loads(payload)
    except Exception:
        print(json.dumps({"success": False, "error": "Invalid JSON payload"}))
        sys.exit(1)

    raw_name = data.get("name", "").strip() or "My Animation"
    safe_name = re.sub(r"[^a-zA-Z0-9_\- ]", "", raw_name).strip() or "My Animation"
    preset_id = f"Custom - {safe_name}"
    filename = f"{preset_id}.conf"

    beziers = data.get("beziers", [])
    if not beziers or not isinstance(beziers, list):
        cn = data.get("curveName", "customEase").strip() or "customEase"
        cp = data.get("curvePoints", "0.05, 0.9, 0.1, 1.05").strip() or "0.05, 0.9, 0.1, 1.05"
        beziers = [{"name": cn, "curve": cp}]

    rules = data.get("rules", [])
    if not rules or not isinstance(rules, list):
        primary_curve = beziers[0].get("name", "customEase")
        win_speed = float(data.get("windowSpeed", 4.0))
        win_style = data.get("windowStyle", "popin 80%").strip() or "popin 80%"
        ws_speed = float(data.get("workspaceSpeed", 5.0))
        ws_style = data.get("workspaceStyle", "slide").strip() or "slide"
        fade_speed = float(data.get("fadeSpeed", 3.0))
        rules = [
            {"target": "windows", "enabled": True, "speed": win_speed, "curve": primary_curve, "style": win_style},
            {"target": "windowsIn", "enabled": True, "speed": win_speed, "curve": primary_curve, "style": win_style},
            {"target": "windowsOut", "enabled": True, "speed": win_speed, "curve": primary_curve, "style": win_style},
            {"target": "windowsMove", "enabled": True, "speed": win_speed, "curve": primary_curve, "style": ""},
            {"target": "layers", "enabled": True, "speed": win_speed, "curve": primary_curve, "style": "slide"},
            {"target": "layersIn", "enabled": True, "speed": win_speed, "curve": primary_curve, "style": "slide"},
            {"target": "layersOut", "enabled": True, "speed": win_speed, "curve": primary_curve, "style": "slide"},
            {"target": "border", "enabled": True, "speed": 1.0, "curve": "linear", "style": ""},
            {"target": "fade", "enabled": True, "speed": fade_speed, "curve": primary_curve, "style": ""},
            {"target": "workspaces", "enabled": True, "speed": ws_speed, "curve": primary_curve, "style": ws_style},
        ]

    lines = [
        "# Custom Hyprland Animation Preset",
        f"# Profile Name: {safe_name}",
        "# Generated via Quickshell Settings",
        "",
        "animations {",
        "  enabled = yes",
        "",
    ]

    seen_beziers = set()
    for b in beziers:
        bn = b.get("name", "").strip()
        bc = b.get("curve", "").strip()
        if bn and bc and bn not in seen_beziers:
            seen_beziers.add(bn)
            lines.append(f"  bezier = {bn}, {bc}")
    if "linear" not in seen_beziers:
        lines.append("  bezier = linear, 0.0, 0.0, 1.0, 1.0")
    lines.append("")

    for r in rules:
        target = r.get("target", "").strip()
        if not target:
            continue
        en = 1 if r.get("enabled", True) else 0
        spd = min(100.0, max(0.01, float(r.get("speed", 4.0))))
        crv = r.get("curve", beziers[0].get("name", "default")).strip()
        style = r.get("style", "").strip()
        if style:
            lines.append(f"  animation = {target}, {en}, {spd}, {crv}, {style}")
        else:
            lines.append(f"  animation = {target}, {en}, {spd}, {crv}")

    lines.extend(["}", ""])
    content = "\n".join(lines)

    os.makedirs(ANIM_DIR, exist_ok=True)
    os.makedirs(BUNDLED_DIR, exist_ok=True)
    write_text(os.path.join(ANIM_DIR, filename), content)
    write_text(os.path.join(BUNDLED_DIR, filename), content)

    try:
        apply_preset(preset_id, emit_json=False)
    except SystemExit:
        pass
    print(json.dumps({"success": True, "preset": preset_id}))


def delete_custom(preset_name):
    if not preset_name:
        print(json.dumps({"success": False, "error": "No preset specified"}))
        sys.exit(1)
    if not preset_name.startswith("Custom -"):
        print(json.dumps({"success": False, "error": "Only custom animations can be deleted"}))
        sys.exit(1)

    for p in (os.path.join(ANIM_DIR, f"{preset_name}.conf"), os.path.join(BUNDLED_DIR, f"{preset_name}.conf")):
        try:
            if os.path.exists(p):
                os.remove(p)
        except OSError:
            pass

    state_file = os.path.join(BACKUP_DIR, ".current_animation")
    if os.path.isfile(state_file):
        try:
            with open(state_file, "r", encoding="utf-8") as f:
                if f.read().strip() == preset_name:
                    apply_preset("00-default", emit_json=False)
        except Exception:
            pass

    print(json.dumps({"success": True, "deleted": preset_name}))


def test_animation(payload):
    if payload:
        try:
            data = json.loads(payload)
            is_lua = os.path.exists(os.path.join(HYPR_DIR, "hyprland.lua"))
            lua_lines = []
            for b in data.get("beziers", []):
                n = b.get("name", "").strip()
                c = b.get("curve", "").strip()
                if n and c:
                    if is_lua:
                        pts = [p.strip() for p in c.split(",")]
                        if len(pts) >= 4:
                            lua_lines.append(
                                f'hl.curve("{n}", {{ type = "bezier", points = {{ {{{pts[0]}, {pts[1]}}}, {{{pts[2]}, {pts[3]}}} }} }})'
                            )
                    else:
                        run_cmd(["hyprctl", "keyword", "bezier", f"{n}, {c}"])

            for r in data.get("rules", []):
                target = r.get("target", "").strip()
                if not target:
                    continue
                en = 1 if r.get("enabled", True) else 0
                spd = min(100.0, max(0.01, float(r.get("speed", 4.0))))
                crv = r.get("curve", "default").strip()
                style = r.get("style", "").strip()
                if is_lua:
                    fields = [f'leaf = "{target}"', f'enabled = {"true" if en else "false"}']
                    if en:
                        fields.extend([f"speed = {spd}", f'bezier = "{crv}"'])
                        if style:
                            fields.append(f'style = "{style}"')
                    lua_lines.append("hl.animation({ " + ", ".join(fields) + " })")
                else:
                    rule_val = f"{target}, {en}, {spd}, {crv}, {style}" if style else f"{target}, {en}, {spd}, {crv}"
                    run_cmd(["hyprctl", "keyword", "animation", rule_val])

            if is_lua and lua_lines:
                run_cmd(["hyprctl", "eval", "; ".join(lua_lines)])
        except Exception:
            pass

    if shutil.which("notify-send"):
        run_cmd([
            "notify-send", "-u", "low", "-t", "2500", "-a", "Quickshell Settings",
            "Animation Test", "Hyprland animations updated! Observe popup and window motion.",
        ])
    print(json.dumps({"success": True}))


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    arg = sys.argv[2] if len(sys.argv) > 2 else ""

    if cmd in ("get", "status"):
        get_status()
    elif cmd == "set_enabled":
        set_enabled(arg or "true")
    elif cmd == "apply_preset":
        apply_preset(arg)
    elif cmd == "save_custom":
        save_custom(arg)
    elif cmd == "delete_custom":
        delete_custom(arg)
    elif cmd == "test":
        test_animation(arg)
    else:
        print(f"Usage: {sys.argv[0]} {{get|status|set_enabled [true|false]|apply_preset <name>|save_custom <json>|delete_custom <name>|test [json]}}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
