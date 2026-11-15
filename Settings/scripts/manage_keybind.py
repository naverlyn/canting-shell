#!/usr/bin/env python3
"""
manage_keybind.py

Manages Hyprland keybindings live via IPC and persists overrides
to custom_keybinds.lua (when hyprland.lua is active)
or UserKeybinds.conf / custom_keybinds.conf (when hyprland.conf is active).
"""

import json
import os
import re
import subprocess
import sys

HYPR_DIR = os.path.expanduser(os.environ.get("HYPR_DIR", "~/.config/hypr"))


def find_config_target():
    if os.path.isfile(os.path.join(HYPR_DIR, "hyprland.lua")):
        return os.path.join(HYPR_DIR, "custom_keybinds.lua")
    for rel in ("UserConfigs/UserKeybinds.conf", "custom_keybinds.conf", "hyprland.conf"):
        p = os.path.join(HYPR_DIR, rel)
        if os.path.isfile(p):
            return os.path.join(HYPR_DIR, "custom_keybinds.conf") if rel == "hyprland.conf" else p
    return os.path.join(HYPR_DIR, "custom_keybinds.conf")


def ensure_config_target(target):
    if os.path.isfile(target):
        return
    os.makedirs(os.path.dirname(target), exist_ok=True)
    if target == os.path.join(HYPR_DIR, "custom_keybinds.lua"):
        try:
            with open(target, "w", encoding="utf-8") as f:
                f.write("-- Custom Keybindings managed by Quickshell Settings\n")
        except OSError:
            pass
        hl_lua = os.path.join(HYPR_DIR, "hyprland.lua")
        if os.path.isfile(hl_lua):
            try:
                with open(hl_lua, "r", encoding="utf-8", errors="ignore") as f:
                    txt = f.read()
                if "custom_keybinds" not in txt:
                    with open(hl_lua, "a", encoding="utf-8") as f:
                        f.write('\npcall(require, "custom_keybinds")\n')
            except OSError:
                pass
    elif target == os.path.join(HYPR_DIR, "custom_keybinds.conf"):
        try:
            with open(target, "w", encoding="utf-8") as f:
                f.write("# Custom Keybindings managed by Quickshell Settings\n")
        except OSError:
            pass
        hl_conf = os.path.join(HYPR_DIR, "hyprland.conf")
        if os.path.isfile(hl_conf):
            try:
                with open(hl_conf, "r", encoding="utf-8", errors="ignore") as f:
                    txt = f.read()
                if "custom_keybinds.conf" not in txt:
                    with open(hl_conf, "a", encoding="utf-8") as f:
                        f.write("\nsource = ~/.config/hypr/custom_keybinds.conf\n")
            except OSError:
                pass


def format_bind(mods, key):
    return f"{mods}, {key}" if mods else f", {key}"


def format_lua_key(mods, key):
    if not mods:
        return key
    m = re.sub(r"\s+", " + ", mods.strip())
    return f"{m} + {key}"


def sanitize_tag(disp, arg, bind=""):
    raw = f"qs_{bind}_{disp}_{arg}" if bind else f"qs_{disp}_{arg}"
    return re.sub(r"[^a-zA-Z0-9_]", "", raw)


def get_modmask(parts):
    mask = 0
    for p in parts:
        pu = p.upper()
        if pu == "SUPER":
            mask |= 64
        elif pu == "CTRL":
            mask |= 4
        elif pu == "ALT":
            mask |= 8
        elif pu == "SHIFT":
            mask |= 1
    return mask


def run_hyprctl(args, timeout=1.0):
    try:
        return subprocess.run(["hyprctl"] + args, capture_output=True, text=True, timeout=timeout)
    except Exception:
        return None


def format_lua_bind(mods_key, d, a):
    lua_keys = f'"{mods_key.strip()}"'
    if d == "exec":
        escaped_a = a.replace("\\", "\\\\").replace('"', '\\"')
        return f'hl.bind({lua_keys}, hl.dsp.exec_cmd("{escaped_a}"))'
    if d in ("killactive", "closewindow"):
        return f"hl.bind({lua_keys}, hl.dsp.window.close())"
    if d == "togglefloating":
        return f'hl.bind({lua_keys}, hl.dsp.window.float({{ action = "toggle" }}))'
    if d == "togglesplit":
        return f'hl.bind({lua_keys}, hl.dsp.layout("togglesplit"))'
    if d == "fullscreen":
        return f'hl.bind({lua_keys}, hl.dsp.window.fullscreen({{ action = "toggle" }}))'
    if d == "pseudo":
        return f"hl.bind({lua_keys}, hl.dsp.window.pseudo())"

    a_s = a.strip()

    def ws(v):
        return v if re.fullmatch(r"-?\d+", v) else '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'

    dirs = {"l": "left", "r": "right", "u": "up", "d": "down",
            "left": "left", "right": "right", "up": "up", "down": "down"}
    if d == "workspace" and a_s:
        return f"hl.bind({lua_keys}, hl.dsp.focus({{ workspace = {ws(a_s)} }}))"
    if d in ("movetoworkspace", "movetoworkspacesilent") and a_s:
        return f"hl.bind({lua_keys}, hl.dsp.window.move({{ workspace = {ws(a_s)} }}))"
    if d == "movefocus" and a_s.lower() in dirs:
        return f'hl.bind({lua_keys}, hl.dsp.focus({{ direction = "{dirs[a_s.lower()]}" }}))'
    if d == "togglespecialworkspace":
        return f'hl.bind({lua_keys}, hl.dsp.workspace.toggle_special("{a_s or "special"}"))'
    if d == "layoutmsg" and a_s:
        return f"hl.bind({lua_keys}, hl.dsp.layout({ws(a_s)}))"
    if d == "exit":
        return f"hl.bind({lua_keys}, hl.dsp.exit())"

    cmd = f"hyprctl dispatch {d} {a}".strip().replace("\\", "\\\\").replace('"', '\\"')
    return f'hl.bind({lua_keys}, hl.dsp.exec_cmd("{cmd}"))'


def with_lua_desc(bind_call, desc):
    dsc = (desc or "").strip()
    if not dsc or not bind_call.endswith(")"):
        return bind_call
    esc = dsc.replace("\\", "\\\\").replace('"', '\\"')
    return bind_call[:-1] + f', {{ desc = "{esc}" }})'


def strip_tag_blocks(content, tags, args=()):
    for t in tags:
        if t:
            content = re.sub(rf"\n*# <{t}>.*?# </{t}>\n*", "\n", content, flags=re.DOTALL)
            content = re.sub(rf"\n*-- <{t}>.*?-- </{t}>\n*", "\n", content, flags=re.DOTALL)
    for a in args:
        if a:
            content = re.sub(
                rf"\n*# <qs_[^>\n]*>(?:(?!# </qs_).)*?{re.escape(a)}(?:(?!# </qs_).)*?# </qs_[^>\n]*>\n*",
                "\n", content, flags=re.DOTALL,
            )
            content = re.sub(
                rf"\n*-- <qs_[^>\n]*>(?:(?!-- </qs_).)*?{re.escape(a)}(?:(?!-- </qs_).)*?-- </qs_[^>\n]*>\n*",
                "\n", content, flags=re.DOTALL,
            )
    return content


def cmd_list():
    bind_map = {}

    def parse_lua_file(filepath):
        if not filepath or not os.path.exists(filepath):
            return
        try:
            with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                text = f.read()
        except Exception:
            return

        lines = text.split("\n")
        lvars = {"home": os.path.expanduser("~")}
        for line in lines:
            m_env = re.match(r'^\s*local\s+([a-zA-Z0-9_]+)\s*=\s*os\.getenv\s*\(\s*["\']([^"\']+)["\']\s*\)', line)
            if m_env:
                lvars[m_env.group(1)] = os.environ.get(m_env.group(2), "")
                continue
            m_cat = re.match(r'^\s*local\s+([a-zA-Z0-9_]+)\s*=\s*([a-zA-Z0-9_]+)\s*\.\.\s*["\']([^"\']+)["\']', line)
            if m_cat and m_cat.group(2) in lvars:
                lvars[m_cat.group(1)] = lvars[m_cat.group(2)] + m_cat.group(3)
                continue
            m = re.match(r'^\s*local\s+([a-zA-Z0-9_]+)\s*=\s*["\']([^"\']+)["\']', line)
            if m:
                lvars[m.group(1)] = m.group(2)

        for line in lines:
            cleaned = re.sub(r"--.*$", "", line).strip()
            if not cleaned:
                continue

            m_unbind = re.search(r'hl\.unbind\s*\(\s*["\']([^"\']+)["\']\s*\)', cleaned)
            if m_unbind:
                uk_parts = [p.strip() for p in m_unbind.group(1).split("+") if p.strip()]
                if uk_parts:
                    um = get_modmask(uk_parts[:-1])
                    uk = uk_parts[-1].lower()
                    bind_map.pop((um, uk), None)
                    if uk == "return":
                        bind_map.pop((um, "enter"), None)
                continue

            m_bind = re.search(r"hl\.bind\s*\(\s*(.+?)\s*,\s*(.+?)\s*(?:,\s*(\{.*\})\s*)?\)$", cleaned)
            if not m_bind:
                continue

            key_expr = m_bind.group(1).strip()
            action_expr = m_bind.group(2).strip()
            opts_expr = (m_bind.group(3) or "").strip()

            for k, v in lvars.items():
                key_expr = re.sub(r"\b" + k + r"\b", f'"{v}"', key_expr)

            full_key = re.sub(r'["\'\s\.]+', " ", key_expr).strip()
            key_parts = [p.strip() for p in full_key.split("+") if p.strip()]
            if not key_parts:
                continue

            key = key_parts[-1]
            if key == "key":
                continue

            modmask = get_modmask(key_parts[:-1])
            resolved_action = action_expr
            for k, v in lvars.items():
                resolved_action = re.sub(r"\b" + k + r"\b", v, resolved_action)

            disp = "exec"
            arg = ""
            desc = ""

            if "window.close" in resolved_action or "close()" in resolved_action:
                disp, desc = "killactive", "Close Active Window"
            elif "window.float" in resolved_action:
                disp, desc = "togglefloating", "Toggle Floating Window"
            elif 'layout("togglesplit")' in resolved_action or "togglesplit" in resolved_action:
                disp, desc = "togglesplit", "Toggle Split Layout"
            elif re.search(r"dsp\.layout\s*\(", resolved_action):
                lm = re.search(r'layout\s*\(\s*["\']([^"\']*)["\']', resolved_action)
                disp = "layoutmsg"
                arg = lm.group(1) if lm else ""
                desc = f"Layout: {arg}"
            elif "window.pseudo" in resolved_action:
                disp, desc = "pseudo", "Pseudo Tiling"
            elif "window.fullscreen" in resolved_action:
                disp, desc = "fullscreen", "Toggle Fullscreen"
            elif "focus(" in resolved_action and "direction" in resolved_action:
                dir_m = re.search(r'direction\s*=\s*["\']([^"\']+)["\']', resolved_action)
                direction = dir_m.group(1) if dir_m else ""
                disp = "movefocus"
                arg = direction[0] if direction else ""
                desc = f"Focus Window ({direction})"
            elif "focus(" in resolved_action and "workspace" in resolved_action:
                ws_m = re.search(r'workspace\s*=\s*["\']?([^"\'}\s,]+)["\']?', resolved_action)
                arg = ws_m.group(1) if ws_m else ""
                disp, desc = "workspace", f"Switch to Workspace {arg}"
            elif "window.move" in resolved_action and "workspace" in resolved_action:
                ws_m = re.search(r'workspace\s*=\s*["\']?([^"\'}\s,]+)["\']?', resolved_action)
                arg = ws_m.group(1) if ws_m else ""
                disp, desc = "movetoworkspace", f"Move Window to Workspace {arg}"
            elif "toggle_special" in resolved_action:
                sp_m = re.search(r'toggle_special\s*\(\s*["\']([^"\']+)["\']\s*\)', resolved_action)
                arg = sp_m.group(1) if sp_m else "special"
                disp, desc = "togglespecialworkspace", f"Toggle Special Workspace ({arg})"
            elif "dsp.exit(" in resolved_action:
                disp, arg, desc = "exit", "", "Exit Hyprland"
            elif "exec_cmd" in resolved_action or "exec" in resolved_action:
                disp = "exec"
                cmd_m = re.search(r'exec_cmd\s*\(\s*(["\'])(.*?)\1\s*\)', resolved_action)
                if cmd_m:
                    arg = cmd_m.group(2).strip()
                else:
                    arg = re.sub(r'^.*?exec_cmd\s*\(\s*["\']?|["\']?\s*\).*?$', "", resolved_action).strip()

                known = [
                    ("qs ipc call launcher", "App Launcher"),
                    ("qs ipc call settings", "Settings App"),
                    ("qs ipc call wallpaper", "Wallpaper Switcher"),
                    ("qs ipc call theme", "Theme Switcher"),
                    ("qs ipc call clipboard", "Clipboard Manager"),
                    ("ScreenShot.sh --now", "Take Screenshot (Full)"),
                    ("ScreenShot.sh --swappy", "Take Screenshot (Area)"),
                    ("ScreenShot.sh --win", "Take Screenshot (Window)"),
                    ("kitty", "Terminal (kitty)"),
                    ("nautilus", "File Manager (nautilus)"),
                    ("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "Volume Up"),
                    ("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", "Volume Down"),
                    ("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", "Mute Volume"),
                    ("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", "Mute Microphone"),
                    ("playerctl next", "Media Next"),
                    ("playerctl play-pause", "Media Play/Pause"),
                    ("playerctl previous", "Media Previous"),
                    ("hyprshutdown", "Power Menu / Shutdown"),
                ]
                desc = arg
                if "brightnessctl" in arg and "5%+" in arg:
                    desc = "Brightness Up"
                elif "brightnessctl" in arg and "5%-" in arg:
                    desc = "Brightness Down"
                else:
                    for pat, label in known:
                        if pat in arg:
                            desc = label
                            break
            else:
                desc = resolved_action

            if opts_expr:
                desc_m = re.search(r'desc\s*=\s*["\']([^"\']+)["\']', opts_expr)
                if desc_m:
                    desc = desc_m.group(1).strip()

            entry = {
                "modmask": modmask,
                "key": key,
                "dispatcher": disp,
                "arg": arg,
                "description": desc,
            }
            bind_map[(modmask, key.lower())] = entry
            if key.lower() == "return":
                bind_map[(modmask, "enter")] = entry

    def parse_conf_file(filepath):
        if not filepath or not os.path.exists(filepath):
            return
        try:
            with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                text = f.read()
        except Exception:
            return
        for line in text.splitlines():
            cleaned = re.sub(r"#.*$", "", line).strip()
            if not cleaned:
                continue
            m = re.match(r"^bind[a-z]*\s*=\s*(.+)$", cleaned)
            if not m:
                continue
            parts = [p.strip() for p in m.group(1).split(",")]
            if len(parts) >= 3:
                mods = parts[0].upper().replace("$MAINMOD", "SUPER").split()
                key, disp = parts[1], parts[2]
                arg = ",".join(parts[3:]).strip() if len(parts) > 3 else ""
                mask = get_modmask(mods)
                bind_map[(mask, key.lower())] = {
                    "modmask": mask,
                    "key": key,
                    "dispatcher": disp,
                    "arg": arg,
                    "description": arg or disp,
                }

    for i in range(1, 11):
        k = str(i % 10)
        bind_map[(64, k)] = {"modmask": 64, "key": k, "dispatcher": "workspace", "arg": str(i), "description": f"Switch to Workspace {i}"}
        bind_map[(65, k)] = {"modmask": 65, "key": k, "dispatcher": "movetoworkspace", "arg": str(i), "description": f"Move Window to Workspace {i}"}

    for rel in ("Configs/Keybinds.lua", "custom_keybinds.lua", "hyprland.lua"):
        parse_lua_file(os.path.join(HYPR_DIR, rel))
    for rel in ("UserConfigs/UserKeybinds.conf", "configs/Keybinds.conf", "custom_keybinds.conf"):
        parse_conf_file(os.path.join(HYPR_DIR, rel))

    live_binds = []
    res = run_hyprctl(["binds", "-j"], timeout=0.8)
    if res and res.returncode == 0 and res.stdout.strip():
        try:
            data = json.loads(res.stdout)
            if isinstance(data, list):
                live_binds = data
        except Exception:
            pass

    final_binds = []
    if live_binds:
        for i, b in enumerate(live_binds):
            if b.get("mouse") or (b.get("key") and b["key"].startswith("mouse")):
                continue
            modmask = b.get("modmask", 0)
            raw_key = b.get("key", "")
            key_norm = raw_key.lower()
            disp = b.get("dispatcher", "")
            arg = b.get("arg", "")
            desc = b.get("description", "")

            if disp in ("__lua", "lua", "") or not disp or not arg:
                lookup = bind_map.get((modmask, key_norm))
                if not lookup and key_norm == "return":
                    lookup = bind_map.get((modmask, "enter"))
                elif not lookup and key_norm == "enter":
                    lookup = bind_map.get((modmask, "return"))
                if lookup:
                    disp = lookup["dispatcher"]
                    arg = lookup["arg"]
                    if not desc:
                        desc = lookup["description"]
            elif not desc:
                lookup = bind_map.get((modmask, key_norm))
                if lookup and lookup.get("description"):
                    desc = lookup["description"]

            final_binds.append({
                "uid": i,
                "modmask": modmask,
                "key": raw_key,
                "dispatcher": disp,
                "arg": arg,
                "description": desc,
            })
    else:
        seen = set()
        uid = 0
        for (m, _), b in bind_map.items():
            if (m, b["key"]) in seen or b["key"].startswith("mouse"):
                continue
            seen.add((m, b["key"]))
            final_binds.append({
                "uid": uid,
                "modmask": b["modmask"],
                "key": b["key"],
                "dispatcher": b["dispatcher"],
                "arg": b["arg"],
                "description": b["description"],
            })
            uid += 1

    print(json.dumps(final_binds))


def cmd_delete(mods, key, disp, arg):
    bind_str = format_bind(mods, key)
    lua_key = format_lua_key(mods, key)

    if os.path.isfile(os.path.join(HYPR_DIR, "hyprland.lua")):
        run_hyprctl(["eval", f'pcall(function() hl.unbind("{lua_key}") end)'])
    else:
        for _ in range(3):
            run_hyprctl(["keyword", "unbind", bind_str])

    target = find_config_target()
    if target:
        ensure_config_target(target)
        tag = sanitize_tag(disp, arg, bind_str)
        legacy_tag = sanitize_tag(disp, arg)
        is_lua = target.endswith(".lua")
        try:
            with open(target, "r", encoding="utf-8") as f:
                content = f.read()
            content = strip_tag_blocks(content, [tag, legacy_tag], [arg])
            if is_lua:
                content = re.sub(
                    rf'\n*-- <qs_[^>\n]*>\s*pcall\(function\(\) hl\.unbind\("{re.escape(lua_key)}"\) end\)\s*-- </qs_[^>\n]*>\n*',
                    "\n", content,
                )

            def norm_key(k):
                return re.sub(r'[\s+"\'.]', "", k).lower()

            defined_elsewhere = True
            if is_lua:
                defined_elsewhere = False
                want = norm_key(lua_key)
                hdir = os.path.dirname(target)
                for fp in (os.path.join(hdir, "Configs/Keybinds.lua"), os.path.join(hdir, "hyprland.lua")):
                    try:
                        with open(fp, "r", encoding="utf-8") as ff:
                            txt = re.sub(r"(?m)^\s*--.*$", "", ff.read())
                    except Exception:
                        continue
                    mm = re.search(r'local\s+mainMod\s*=\s*["\']([^"\']+)["\']', txt)
                    for m in re.finditer(r"hl\.bind\(\s*([^,]+?)\s*,", txt):
                        expr = m.group(1)
                        if mm:
                            expr = re.sub(r"\bmainMod\b", mm.group(1), expr)
                        if norm_key(expr) == want:
                            defined_elsewhere = True

            if not defined_elsewhere:
                with open(target, "w", encoding="utf-8") as f:
                    f.write(content.rstrip() + "\n")
                print("delete_ok")
                return

            if is_lua:
                block = f'\n-- <{tag}>\npcall(function() hl.unbind("{lua_key}") end)\n-- </{tag}>\n'
            else:
                block = f"\n# <{tag}>\nunbind = {bind_str}\n# </{tag}>\n"

            with open(target, "w", encoding="utf-8") as f:
                f.write(content.rstrip() + "\n" + block)
        except Exception:
            pass
    print("delete_ok")


def live_bind_conf(bind_str, disp, arg, desc):
    if arg:
        if desc:
            res = run_hyprctl(["keyword", "bindd", f"{bind_str}, {desc}, {disp}, {arg}"])
            if not res or res.returncode != 0:
                run_hyprctl(["keyword", "bind", f"{bind_str}, {disp}, {arg}"])
        else:
            run_hyprctl(["keyword", "bind", f"{bind_str}, {disp}, {arg}"])
    else:
        if desc:
            res = run_hyprctl(["keyword", "bindd", f"{bind_str}, {desc}, {disp}"])
            if not res or res.returncode != 0:
                run_hyprctl(["keyword", "bind", f"{bind_str}, {disp}"])
        else:
            run_hyprctl(["keyword", "bind", f"{bind_str}, {disp}"])


def cmd_rebind(old_mod, old_key, new_mod, new_key, disp, arg, desc, old_arg="", old_disp=""):
    old_bind = format_bind(old_mod, old_key)
    new_bind = format_bind(new_mod, new_key)
    old_lua = format_lua_key(old_mod, old_key)
    new_lua = format_lua_key(new_mod, new_key)

    if not os.path.isfile(os.path.join(HYPR_DIR, "hyprland.lua")):
        for _ in range(3):
            run_hyprctl(["keyword", "unbind", old_bind])
        live_bind_conf(new_bind, disp, arg, desc)

    target = find_config_target()
    if target:
        ensure_config_target(target)
        tag = sanitize_tag(disp, arg, new_bind)
        old_tag = sanitize_tag(old_disp, old_arg, old_bind)
        legacy_tag = sanitize_tag(disp, arg)
        legacy_old_tag = sanitize_tag(old_disp, old_arg)
        is_lua = target.endswith(".lua")
        try:
            with open(target, "r", encoding="utf-8") as f:
                content = f.read()
            content = strip_tag_blocks(content, [tag, old_tag, legacy_tag, legacy_old_tag], [old_arg, arg])

            if is_lua:
                bind_line = with_lua_desc(format_lua_bind(new_lua, disp, arg), desc)
                run_hyprctl(["eval", f'pcall(function() hl.unbind("{old_lua}") end); {bind_line}'])
                block = f'\n-- <{tag}>\npcall(function() hl.unbind("{old_lua}") end)\n{bind_line}\n-- </{tag}>\n'
            else:
                bind_line = f"bind = {new_bind}, {disp}, {arg}" if arg else f"bind = {new_bind}, {disp}"
                block = f"\n# <{tag}>\nunbind = {old_bind}\n{bind_line}\n# </{tag}>\n"

            with open(target, "w", encoding="utf-8") as f:
                f.write(content.rstrip() + "\n" + block)
        except Exception:
            pass
    print("rebind_ok")


def cmd_add(mods, key, disp, arg, desc):
    bind_str = format_bind(mods, key)
    lua_key = format_lua_key(mods, key)

    if not os.path.isfile(os.path.join(HYPR_DIR, "hyprland.lua")):
        live_bind_conf(bind_str, disp, arg, desc)

    target = find_config_target()
    if target:
        ensure_config_target(target)
        tag = sanitize_tag(disp, arg, bind_str)
        legacy_tag = sanitize_tag(disp, arg)
        is_lua = target.endswith(".lua")
        try:
            with open(target, "r", encoding="utf-8") as f:
                content = f.read()
            content = strip_tag_blocks(content, [tag, legacy_tag])

            if is_lua:
                bind_line = with_lua_desc(format_lua_bind(lua_key, disp, arg), desc)
                run_hyprctl(["eval", bind_line])
                block = f"\n-- <{tag}>\n{bind_line}\n-- </{tag}>\n"
            else:
                bind_line = f"bind = {bind_str}, {disp}, {arg}" if arg else f"bind = {bind_str}, {disp}"
                block = f"\n# <{tag}>\n{bind_line}\n# </{tag}>\n"

            with open(target, "w", encoding="utf-8") as f:
                f.write(content.rstrip() + "\n" + block)
        except Exception:
            pass
    print("add_ok")


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else ""
    args = sys.argv[2:]

    if action == "detect_target":
        print(find_config_target())
    elif action == "list":
        cmd_list()
    elif action in ("delete", "unbind"):
        cmd_delete(*(args + [""] * 4)[:4])
    elif action == "rebind":
        cmd_rebind(*(args + [""] * 9)[:9])
    elif action == "add":
        cmd_add(*(args + [""] * 5)[:5])
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
