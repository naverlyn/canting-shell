#!/usr/bin/env python3
"""
manage_hyprland.py

Comprehensive Hyprland Variables manager for Quickshell Settings.
Compatible with Vanilla Hyprland, modular dotfiles, and Hyprland Lua configs.
Supports reading & live updating variables across General, Decoration, Gestures, and Misc.
"""

import glob
import json
import os
import re
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
HYPR_DIR = os.path.expanduser(os.environ.get("HYPR_DIR", "~/.config/hypr"))


def detect_hypr_instance():
    if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        uid = os.getuid()
        candidates = sorted(
            glob.glob(f"/run/user/{uid}/hypr/*_*/"),
            key=lambda p: os.path.getmtime(p),
            reverse=True,
        )
        if candidates:
            os.environ["HYPRLAND_INSTANCE_SIGNATURE"] = os.path.basename(candidates[0].rstrip("/"))


def run_hyprctl(args, timeout=1.0):
    try:
        return subprocess.run(["hyprctl"] + args, capture_output=True, text=True, timeout=timeout)
    except Exception:
        return None


def find_config_target(is_decor=0, target_section=""):
    if os.path.isfile(os.path.join(HYPR_DIR, "hyprland.lua")):
        configs_dir = os.path.join(HYPR_DIR, "Configs")
        if os.path.isdir(configs_dir):
            if is_decor == 1 or target_section.startswith(("general", "decoration")):
                p = os.path.join(configs_dir, "WindowDecoration.lua")
                if os.path.isfile(p):
                    return p
            elif target_section.startswith(("misc", "cursor")):
                p = os.path.join(configs_dir, "Misc.lua")
                if os.path.isfile(p):
                    return p
            elif target_section.startswith(("gestures", "input")):
                p = os.path.join(configs_dir, "Input.lua")
                if os.path.isfile(p):
                    return p

        custom_lua = os.path.join(HYPR_DIR, "custom_hypr.lua")
        if os.path.isfile(custom_lua):
            return custom_lua

        with open(custom_lua, "w", encoding="utf-8") as f:
            f.write("-- Hyprland variables managed by Quickshell Settings\nhl.config({\n})\n")
        hl_lua = os.path.join(HYPR_DIR, "hyprland.lua")
        try:
            with open(hl_lua, "r", encoding="utf-8", errors="ignore") as f:
                if "custom_hypr" not in f.read():
                    with open(hl_lua, "a", encoding="utf-8") as af:
                        af.write('\npcall(require, "custom_hypr")\n')
        except OSError:
            pass
        return custom_lua

    custom_conf = os.path.join(HYPR_DIR, "custom_hypr.conf")
    if os.path.isfile(custom_conf):
        return custom_conf

    hl_conf = os.path.join(HYPR_DIR, "hyprland.conf")
    if os.path.isfile(hl_conf):
        with open(custom_conf, "w", encoding="utf-8") as f:
            f.write("# Hyprland variables managed by Quickshell Settings\n")
        try:
            with open(hl_conf, "r", encoding="utf-8", errors="ignore") as f:
                if "custom_hypr.conf" not in f.read():
                    with open(hl_conf, "a", encoding="utf-8") as af:
                        af.write("\nsource = ~/.config/hypr/custom_hypr.conf\n")
        except OSError:
            pass
        return custom_conf

    return hl_conf


def get_status():
    detect_hypr_instance()
    data = {
        "general": {
            "gaps_in": 2,
            "gaps_out": 4,
            "border_size": 0,
            "layout": "dwindle",
            "resize_on_border": True,
            "allow_tearing": False,
            "snap_enabled": False,
            "snap_window_gap": 10,
            "border_theme_sync": True,
            "active_border_col1": "#7aa2f7",
            "active_border_col2": "#7dcfff",
            "active_border_angle": 45,
            "inactive_border_col": "#32364a",
        },
        "decoration": {
            "rounding": 10,
            "active_opacity": 1.0,
            "inactive_opacity": 0.9,
            "dim_inactive": True,
            "dim_strength": 0.1,
            "blur_enabled": True,
            "blur_size": 6,
            "blur_passes": 3,
            "blur_popups": True,
            "blur_xray": True,
            "shadow_enabled": False,
            "shadow_range": 3,
            "shadow_render_power": 1,
        },
        "gestures": {
            "workspace_swipe": True,
            "workspace_swipe_fingers": 3,
            "workspace_swipe_distance": 300,
            "workspace_swipe_invert": True,
            "workspace_swipe_forever": True,
        },
        "misc": {
            "vrr": 2,
            "vfr": True,
            "disable_hyprland_logo": True,
            "disable_splash_rendering": True,
            "mouse_move_enables_dpms": True,
            "middle_click_paste": False,
            "no_hardware_cursors": 2,
        },
    }

    parsed_files = set()

    def to_val(v_str):
        if v_str in ("true", "yes", "on", "1"):
            return True
        if v_str in ("false", "no", "off", "0"):
            return False
        try:
            return float(v_str) if "." in v_str else int(v_str)
        except ValueError:
            return v_str

    def apply_kv(block_scope, k, raw_v):
        v_lower = raw_v.lower() if isinstance(raw_v, str) else str(raw_v).lower()
        val = to_val(v_lower)
        if block_scope == "general":
            if k in ("gaps_in", "gaps_out", "border_size"):
                data["general"][k] = int(val)
            elif k == "layout":
                data["general"]["layout"] = str(val)
            elif k in ("resize_on_border", "allow_tearing"):
                data["general"][k] = bool(val)
        elif block_scope == "general.snap" or (block_scope == "general" and k.startswith("snap:")):
            sub_k = k.replace("snap:", "")
            if sub_k == "enabled":
                data["general"]["snap_enabled"] = bool(val)
            elif sub_k == "window_gap":
                data["general"]["snap_window_gap"] = int(val)
        elif block_scope == "decoration":
            if k == "rounding":
                data["decoration"]["rounding"] = int(val)
            elif k in ("active_opacity", "inactive_opacity", "dim_strength"):
                data["decoration"][k] = float(val)
            elif k == "dim_inactive":
                data["decoration"]["dim_inactive"] = bool(val)
        elif block_scope == "decoration.blur":
            if k in ("enabled", "popups", "xray"):
                data["decoration"][f"blur_{k}"] = bool(val)
            elif k in ("size", "passes"):
                data["decoration"][f"blur_{k}"] = int(val)
        elif block_scope == "decoration.shadow":
            if k == "enabled":
                data["decoration"]["shadow_enabled"] = bool(val)
            elif k in ("range", "render_power"):
                data["decoration"][f"shadow_{k}"] = int(val)
        elif block_scope == "gestures":
            if k in ("workspace_swipe", "workspace_swipe_invert", "workspace_swipe_forever"):
                data["gestures"][k] = bool(val)
            elif k in ("workspace_swipe_fingers", "workspace_swipe_distance"):
                data["gestures"][k] = int(val)
        elif block_scope == "misc":
            if k == "vrr":
                data["misc"]["vrr"] = int(val) if isinstance(val, int) else (1 if val else 0)
            elif k in ("vfr", "disable_hyprland_logo", "disable_splash_rendering", "mouse_move_enables_dpms", "middle_click_paste"):
                data["misc"][k] = bool(val)
        elif block_scope == "cursor" and k == "no_hardware_cursors":
            data["misc"]["no_hardware_cursors"] = int(val) if isinstance(val, int) else (1 if val else 0)

    def parse_conf(path):
        real_path = os.path.realpath(os.path.expanduser(path))
        if not os.path.exists(real_path) or real_path in parsed_files:
            return
        parsed_files.add(real_path)
        try:
            with open(real_path, "r", encoding="utf-8", errors="ignore") as f:
                lines = f.readlines()
        except Exception:
            return
        current_block = []
        base_dir = os.path.dirname(real_path)
        for line in lines:
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            src_match = re.match(r"^source\s*=\s*(.*)", stripped)
            if src_match:
                sub_path = (
                    src_match.group(1).strip()
                    .replace("$HOME", os.path.expanduser("~"))
                    .replace("~", os.path.expanduser("~"))
                    .replace("$configs", os.path.join(HYPR_DIR, "configs"))
                    .replace("$UserConfigs", os.path.join(HYPR_DIR, "UserConfigs"))
                )
                if not os.path.isabs(sub_path):
                    sub_path = os.path.join(base_dir, sub_path)
                parse_conf(sub_path)
                continue
            open_match = re.match(r"^([a-zA-Z0-9_\.\-]+)\s*\{", stripped)
            if open_match:
                current_block.append(open_match.group(1).lower())
                continue
            if "}" in stripped:
                if current_block:
                    current_block.pop()
                continue
            kv_match = re.match(r"^([a-zA-Z0-9_\.\-]+)\s*=\s*([^#]+)", stripped)
            if kv_match:
                apply_kv(".".join(current_block), kv_match.group(1).strip().lower(), kv_match.group(2).strip())

    def parse_lua_config(path):
        real_path = os.path.realpath(os.path.expanduser(path))
        if not os.path.exists(real_path) or real_path in parsed_files:
            return
        parsed_files.add(real_path)
        try:
            with open(real_path, "r", encoding="utf-8", errors="ignore") as f:
                lines = f.readlines()
        except Exception:
            return
        stack = []
        base_dir = os.path.dirname(real_path)
        for line in lines:
            cleaned = re.sub(r"--.*$", "", line).strip()
            if not cleaned:
                continue
            req_m = re.search(r'require\s*\(\s*["\']([^"\']+)["\']\s*\)', cleaned)
            if req_m:
                req_mod = req_m.group(1).replace(".", "/") + ".lua"
                for candidate in (
                    os.path.join(HYPR_DIR, req_mod),
                    os.path.join(base_dir, req_mod),
                    os.path.join(HYPR_DIR, req_m.group(1) + ".lua"),
                ):
                    if os.path.exists(candidate):
                        parse_lua_config(candidate)
                        break
                continue
            net_braces = cleaned.count("{") - cleaned.count("}")
            m_tbl = re.match(r"^([a-zA-Z0-9_\.]+)\s*=\s*\{", cleaned)
            if m_tbl and net_braces > 0:
                stack.append(m_tbl.group(1).lower())
                continue
            m_kv = re.match(r"^([a-zA-Z0-9_\.]+)\s*=\s*([^,]+)", cleaned)
            if m_kv and not cleaned.endswith("{"):
                block_scope = ".".join([s for s in stack if s != "hl.config"])
                apply_kv(block_scope, m_kv.group(1).lower(), m_kv.group(2).strip().strip("\"'"))
            if net_braces < 0:
                for _ in range(abs(net_braces)):
                    if stack:
                        stack.pop()

    for rel in ("hyprland.lua", "Configs/WindowDecoration.lua", "Configs/Misc.lua", "Configs/Input.lua", "custom_hypr.lua"):
        parse_lua_config(os.path.join(HYPR_DIR, rel))
    for rel in ("hyprland.conf", "custom_hypr.conf"):
        parse_conf(os.path.join(HYPR_DIR, rel))

    def query_hyprctl(opt):
        res = run_hyprctl(["getoption", opt, "-j"], timeout=0.3)
        if res and res.returncode == 0 and res.stdout:
            try:
                obj = json.loads(res.stdout)
                for key in ("int", "float", "str"):
                    if key in obj:
                        return obj[key]
            except Exception:
                pass
        return None

    opts_to_query = [
        ("general", "gaps_in", "general:gaps_in", int),
        ("general", "gaps_out", "general:gaps_out", int),
        ("general", "border_size", "general:border_size", int),
        ("general", "layout", "general:layout", str),
        ("general", "resize_on_border", "general:resize_on_border", bool),
        ("general", "allow_tearing", "general:allow_tearing", bool),
        ("general", "snap_enabled", "general:snap:enabled", bool),
        ("general", "snap_window_gap", "general:snap:window_gap", int),
        ("decoration", "rounding", "decoration:rounding", int),
        ("decoration", "active_opacity", "decoration:active_opacity", float),
        ("decoration", "inactive_opacity", "decoration:inactive_opacity", float),
        ("decoration", "dim_inactive", "decoration:dim_inactive", bool),
        ("decoration", "dim_strength", "decoration:dim_strength", float),
        ("decoration", "blur_enabled", "decoration:blur:enabled", bool),
        ("decoration", "blur_size", "decoration:blur:size", int),
        ("decoration", "blur_passes", "decoration:blur:passes", int),
        ("decoration", "blur_popups", "decoration:blur:popups", bool),
        ("decoration", "blur_xray", "decoration:blur:xray", bool),
        ("decoration", "shadow_enabled", "decoration:shadow:enabled", bool),
        ("decoration", "shadow_range", "decoration:shadow:range", int),
        ("decoration", "shadow_render_power", "decoration:shadow:render_power", int),
        ("gestures", "workspace_swipe", "gestures:workspace_swipe", bool),
        ("gestures", "workspace_swipe_fingers", "gestures:workspace_swipe_fingers", int),
        ("gestures", "workspace_swipe_distance", "gestures:workspace_swipe_distance", int),
        ("gestures", "workspace_swipe_invert", "gestures:workspace_swipe_invert", bool),
        ("gestures", "workspace_swipe_forever", "gestures:workspace_swipe_forever", bool),
        ("misc", "vrr", "misc:vrr", int),
        ("misc", "vfr", "misc:vfr", bool),
        ("misc", "disable_hyprland_logo", "misc:disable_hyprland_logo", bool),
        ("misc", "disable_splash_rendering", "misc:disable_splash_rendering", bool),
        ("misc", "mouse_move_enables_dpms", "misc:mouse_move_enables_dpms", bool),
        ("misc", "middle_click_paste", "misc:middle_click_paste", bool),
        ("misc", "no_hardware_cursors", "cursor:no_hardware_cursors", int),
    ]
    for sec, k, opt_name, type_fn in opts_to_query:
        val = query_hyprctl(opt_name)
        if val is not None:
            try:
                data[sec][k] = type_fn(val)
            except Exception:
                pass

    if os.path.isfile(os.path.join(HYPR_DIR, "hyprland.lua")):
        try:
            res = subprocess.run(
                ["python3", os.path.join(SCRIPT_DIR, "lua_gesture.py"), "get"],
                capture_output=True, text=True, timeout=2,
            )
            g = json.loads(res.stdout)
            data["gestures"]["workspace_swipe"] = bool(g["enabled"])
            data["gestures"]["workspace_swipe_fingers"] = int(g["fingers"])
        except Exception:
            pass

    def rgba_to_hex(c_str):
        m = re.search(r"rgba\(\s*([0-9a-fA-F]{6})", c_str) or re.search(r"([0-9a-fA-F]{6})", c_str)
        return ("#" + m.group(1).lower()) if m else None

    for b_file in (
        os.path.join(HYPR_DIR, "Configs", "WindowDecoration.lua"),
        os.path.join(HYPR_DIR, "theme-borders.conf"),
        os.path.join(HYPR_DIR, "theme-borders.lua"),
    ):
        if os.path.isfile(b_file):
            try:
                with open(b_file, "r", encoding="utf-8", errors="ignore") as bf:
                    b_txt = bf.read()
                if "custom_border = true" in b_txt:
                    data["general"]["border_theme_sync"] = False
                elif "theme_sync = true" in b_txt:
                    data["general"]["border_theme_sync"] = True

                for bline in b_txt.splitlines():
                    bs = bline.split("--")[0].strip()
                    if "inactive_border" in bs and "=" in bs:
                        cols = re.findall(r"rgba\(\s*[0-9a-fA-F]{6,8}\s*\)", bs.split("=", 1)[1])
                        if cols and rgba_to_hex(cols[0]):
                            data["general"]["inactive_border_col"] = rgba_to_hex(cols[0])
                    elif "active_border" in bs and "=" in bs:
                        rhs = bs.split("=", 1)[1]
                        cols = re.findall(r"rgba\(\s*[0-9a-fA-F]{6,8}\s*\)", rhs)
                        if len(cols) >= 1 and rgba_to_hex(cols[0]):
                            data["general"]["active_border_col1"] = rgba_to_hex(cols[0])
                        if len(cols) >= 2 and rgba_to_hex(cols[1]):
                            data["general"]["active_border_col2"] = rgba_to_hex(cols[1])
                        elif len(cols) == 1 and rgba_to_hex(cols[0]):
                            data["general"]["active_border_col2"] = rgba_to_hex(cols[0])
                        ang_m = re.search(r"angle\s*=\s*(\d+)|(\d+)deg", rhs)
                        if ang_m:
                            data["general"]["active_border_angle"] = int(ang_m.group(1) or ang_m.group(2))
            except Exception:
                pass

    print(json.dumps(data))


def set_borders(col1="#7aa2f7", col2="#7dcfff", angle="45", inactive="#32364a", sync="false"):
    detect_hypr_instance()
    try:
        angle_int = int(float(str(angle).strip()))
    except Exception:
        angle_int = 45
    sync_bool = str(sync).strip().lower() in ("true", "1", "yes", "on")

    def to_rgba(hex_str):
        h = hex_str.strip().lstrip("#")
        if re.fullmatch(r"[0-9a-fA-F]{6}", h):
            return f"rgba({h.lower()}ff)"
        if re.fullmatch(r"[0-9a-fA-F]{8}", h):
            return f"rgba({h.lower()})"
        return hex_str if hex_str.startswith("rgba(") else "rgba(7aa2f7ff)"

    rgba1 = to_rgba(col1)
    rgba2 = to_rgba(col2)
    rgba_inact = to_rgba(inactive)
    header_flag = "theme_sync = true" if sync_bool else "custom_border = true"
    is_lua = os.path.isfile(os.path.join(HYPR_DIR, "hyprland.lua"))

    if is_lua:
        target = os.path.join(HYPR_DIR, "theme-borders.lua")
        lua_content = (
            f"-- {header_flag}\n"
            f"hl.config({{\n"
            f"    general = {{\n"
            f'        ["col.active_border"] = {{ colors = {{ "{rgba1}", "{rgba2}" }}, angle = {angle_int} }},\n'
            f'        ["col.inactive_border"] = "{rgba_inact}",\n'
            f"    }},\n"
            f"}})\n"
        )
        with open(target, "w", encoding="utf-8") as f:
            f.write(lua_content)

        win_dec = os.path.join(HYPR_DIR, "Configs", "WindowDecoration.lua")
        if os.path.isfile(win_dec):
            try:
                with open(win_dec, "r", encoding="utf-8") as wf:
                    w_txt = wf.read()
                w_txt = re.sub(
                    r"(active_border\s*=\s*)\{[^}]+\}\s*,\s*angle\s*=\s*\d+\s*\}",
                    f'\\1{{ colors = {{"{rgba1}", "{rgba2}"}}, angle = {angle_int} }}',
                    w_txt,
                )
                w_txt = re.sub(r'(inactive_border\s*=\s*)"[^"]+"', f'\\1"{rgba_inact}"', w_txt)
                with open(win_dec, "w", encoding="utf-8") as wf:
                    wf.write(w_txt)
            except Exception:
                pass

        hypr_lua = os.path.join(HYPR_DIR, "hyprland.lua")
        if os.path.isfile(hypr_lua):
            with open(hypr_lua, "r", encoding="utf-8") as hf:
                if "theme-borders" not in hf.read():
                    with open(hypr_lua, "a", encoding="utf-8") as af:
                        af.write('\npcall(require, "theme-borders")\n')
        run_hyprctl(["eval", f'dofile("{target}")'])
    else:
        target = os.path.join(HYPR_DIR, "theme-borders.conf")
        conf_content = (
            f"# {header_flag}\n"
            f"general {{\n"
            f"    col.active_border = {rgba1} {rgba2} {angle_int}deg\n"
            f"    col.inactive_border = {rgba_inact}\n"
            f"}}\n"
        )
        with open(target, "w", encoding="utf-8") as f:
            f.write(conf_content)
        run_hyprctl(["keyword", "general:col.active_border", f"{rgba1} {rgba2} {angle_int}deg"])
        run_hyprctl(["keyword", "general:col.inactive_border", rgba_inact])

    print(json.dumps({
        "status": "ok",
        "key": "Border colors",
        "col1": col1,
        "col2": col2,
        "angle": angle_int,
        "inactive": inactive,
        "sync": sync_bool,
    }))


def update_hypr_config(cfg_text, sec, k, v):
    lines = cfg_text.splitlines()
    target_parts = sec.split(".")
    block_stack = []
    found_key_line = -1
    target_block_open_line = -1

    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        open_m = re.match(r"^(\s*)([a-zA-Z0-9_\.\-]+)\s*\{", line)
        if open_m:
            block_stack.append(open_m.group(2).lower())
            if [b.lower() for b in target_parts] == block_stack:
                target_block_open_line = i
            continue
        if "}" in stripped:
            if block_stack:
                block_stack.pop()
            continue
        kv_m = re.match(r"^(\s*)([a-zA-Z0-9_\.\-]+)\s*=\s*(.*)", line)
        if kv_m and [b.lower() for b in target_parts] == block_stack and kv_m.group(2).strip().lower() == k.lower():
            found_key_line = i

    indent = "  " * len(target_parts)
    new_kv_line = f"{indent}{k} = {v}"
    if found_key_line != -1:
        lines[found_key_line] = new_kv_line
        return "\n".join(lines) + "\n"
    if target_block_open_line != -1:
        lines.insert(target_block_open_line + 1, new_kv_line)
        return "\n".join(lines) + "\n"
    if len(target_parts) == 1:
        return cfg_text.rstrip() + f"\n{target_parts[0]} {{\n  {k} = {v}\n}}\n"
    if len(target_parts) == 2:
        parent_sec, sub_sec = target_parts[0], target_parts[1]
        parent_open = -1
        p_stack = []
        for i, line in enumerate(lines):
            open_m = re.match(r"^(\s*)([a-zA-Z0-9_\.\-]+)\s*\{", line)
            if open_m:
                p_stack.append(open_m.group(2).lower())
                if p_stack == [parent_sec.lower()]:
                    parent_open = i
            if "}" in line.strip() and p_stack:
                p_stack.pop()
        if parent_open != -1:
            lines.insert(parent_open + 1, f"  {sub_sec} {{\n    {k} = {v}\n  }}")
            return "\n".join(lines) + "\n"
        return cfg_text.rstrip() + f"\n{parent_sec} {{\n  {sub_sec} {{\n    {k} = {v}\n  }}\n}}\n"
    return cfg_text


def update_lua_config(cfg_text, sec, k, v_str):
    def format_lua_val(val):
        v_s = str(val).strip()
        if v_s.lower() in ("true", "false"):
            return v_s.lower()
        try:
            if "." in v_s:
                float(v_s)
            else:
                int(v_s)
            return v_s
        except ValueError:
            return f'"{v_s}"'

    formatted_val = format_lua_val(v_str)
    lua_key = k if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", k) else f'["{k}"]'
    lines = cfg_text.splitlines()
    target_parts = [p.lower() for p in sec.split(".")]

    stack = []
    found_key_idx = -1
    target_open_idx = -1
    target_indent = "    "
    parent_open_idx = -1

    for i, line in enumerate(lines):
        cleaned = re.sub(r"--.*$", "", line).strip()
        if not cleaned:
            continue
        m_tbl = re.match(r"^([a-zA-Z0-9_\.]+)\s*=\s*\{", cleaned)
        net_braces = cleaned.count("{") - cleaned.count("}")
        if m_tbl and net_braces > 0:
            stack.append(m_tbl.group(1).lower())
            if stack == target_parts:
                target_open_idx = i
                target_indent = line[:len(line) - len(line.lstrip())] + "    "
            elif len(target_parts) > 1 and stack == target_parts[:-1]:
                parent_open_idx = i
            continue
        m_kv = re.match(r"^(?:\[\s*[\"']([^\"']+)[\"']\s*\]|([a-zA-Z0-9_\.]+))\s*=\s*([^,]+)", cleaned)
        if m_kv and not cleaned.endswith("{"):
            key_name = (m_kv.group(1) or m_kv.group(2)).lower()
            if stack == target_parts and key_name == k.lower():
                found_key_idx = i
                break
        if net_braces < 0:
            for _ in range(abs(net_braces)):
                if stack:
                    stack.pop()

    if found_key_idx != -1:
        orig = lines[found_key_idx]
        leading = orig[:len(orig) - len(orig.lstrip())]
        cm = re.search(r"\s*--.*$", orig)
        lines[found_key_idx] = f"{leading}{lua_key} = {formatted_val}," + (cm.group(0) if cm else "")
        return "\n".join(lines) + "\n"
    if target_open_idx != -1:
        lines.insert(target_open_idx + 1, f"{target_indent}{lua_key} = {formatted_val},")
        return "\n".join(lines) + "\n"
    if parent_open_idx != -1 and len(target_parts) > 1:
        orig = lines[parent_open_idx]
        leading = orig[:len(orig) - len(orig.lstrip())]
        sub_sec = target_parts[-1]
        nested_block = [
            f"{leading}    {sub_sec} = {{",
            f"{leading}        {lua_key} = {formatted_val},",
            f"{leading}    }},",
        ]
        lines.insert(parent_open_idx + 1, "\n".join(nested_block))
        return "\n".join(lines) + "\n"

    indent = "    "
    if len(target_parts) == 1:
        block = f"\nhl.config({{\n{indent}{sec} = {{\n{indent}{indent}{lua_key} = {formatted_val},\n{indent}}},\n}})\n"
    else:
        block = f"\nhl.config({{\n{indent}{target_parts[0]} = {{\n{indent}{indent}{target_parts[1]} = {{\n{indent}{indent}{indent}{lua_key} = {formatted_val},\n{indent}{indent}}},\n{indent}}},\n}})\n"
    return cfg_text.rstrip() + block


def set_var(target_section, target_key, target_val):
    if not target_section or not target_key or not target_val:
        print(json.dumps({"status": "error", "message": "Missing parameters"}))
        sys.exit(1)

    if target_section == "misc" and target_key == "no_hardware_cursors":
        target_section = "cursor"

    detect_hypr_instance()

    if os.path.isfile(os.path.join(HYPR_DIR, "hyprland.lua")) and target_section == "gestures":
        if target_key == "workspace_swipe":
            res = subprocess.run(["python3", os.path.join(SCRIPT_DIR, "lua_gesture.py"), "set", "enabled", target_val])
            sys.exit(res.returncode)
        if target_key == "workspace_swipe_fingers":
            res = subprocess.run(["python3", os.path.join(SCRIPT_DIR, "lua_gesture.py"), "set", "fingers", target_val])
            sys.exit(res.returncode)

    if not os.path.isfile(os.path.join(HYPR_DIR, "hyprland.lua")) and shutil.which("hyprctl"):
        hypr_arg = "1" if target_val == "true" else ("0" if target_val == "false" else target_val)
        opt_name = f"{target_section.replace('.', ':')}:{target_key}"
        run_hyprctl(["keyword", opt_name, hypr_arg])

    is_decor = 1 if target_section.startswith(("decoration", "general")) else 0
    target_path = find_config_target(is_decor, target_section)
    is_lua = target_path.endswith(".lua")

    if not os.path.exists(target_path):
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        with open(target_path, "w", encoding="utf-8") as f:
            f.write("-- Hyprland Configuration managed by Quickshell\nhl.config({\n})\n" if is_lua else "# Hyprland Configuration managed by Quickshell\n\n")

    with open(target_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    if is_lua:
        updated = update_lua_config(content, target_section, target_key, target_val)
        v_s = str(target_val).strip()
        if v_s.lower() in ("true", "false"):
            fv = v_s.lower()
        else:
            try:
                float(v_s) if "." in v_s else int(v_s)
                fv = v_s
            except ValueError:
                fv = f'"{v_s}"'
        lk = target_key if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", target_key) else f'["{target_key}"]'
        parts = [p.lower() for p in target_section.split(".")]
        if len(parts) == 1:
            eval_code = f"hl.config({{ {parts[0]} = {{ {lk} = {fv} }} }})"
        else:
            eval_code = f"hl.config({{ {parts[0]} = {{ {parts[1]} = {{ {lk} = {fv} }} }} }})"
        run_hyprctl(["eval", eval_code])
    else:
        updated = update_hypr_config(content, target_section, target_key, target_val)

    with open(target_path, "w", encoding="utf-8") as f:
        f.write(updated)

    print(json.dumps({"status": "ok", "section": target_section, "key": target_key, "value": target_val, "target": target_path}))


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "get"
    args = sys.argv[2:]
    if cmd == "get":
        get_status()
    elif cmd == "set":
        set_var(*(args + [""] * 3)[:3])
    elif cmd == "set_borders":
        set_borders(*(args + ["#7aa2f7", "#7dcfff", "45", "#32364a", "false"])[:5])
    else:
        print(f"Usage: {sys.argv[0]} {{get|set <section> <key> <value>|set_borders <col1> <col2> <angle> <inactive> <sync>}}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
