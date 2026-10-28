#!/usr/bin/env bash
#
# manage_keybind.sh
#
# Manages Hyprland keybindings live via IPC and persists overrides
# to custom_keybinds.lua (when hyprland.lua is active)
# or UserKeybinds.conf / custom_keybinds.conf (when hyprland.conf is active).
#

set -e

ACTION="$1"
# Passed to embedded Python via environment (safe for quotes in commands)
export ARG OLD_ARG DESC
HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"

find_config_target() {
    # 1. Hyprland Lua configuration
    if [ -f "$HYPR_DIR/hyprland.lua" ]; then
        echo "$HYPR_DIR/custom_keybinds.lua"
        return
    fi

    # 2. Conf configurations
    if [ -f "$HYPR_DIR/UserConfigs/UserKeybinds.conf" ]; then
        echo "$HYPR_DIR/UserConfigs/UserKeybinds.conf"
        return
    fi

    if [ -f "$HYPR_DIR/custom_keybinds.conf" ]; then
        echo "$HYPR_DIR/custom_keybinds.conf"
        return
    fi

    if [ -f "$HYPR_DIR/hyprland.conf" ]; then
        echo "$HYPR_DIR/custom_keybinds.conf"
        return
    fi

    echo "$HYPR_DIR/custom_keybinds.conf"
}

ensure_config_target() {
    local target="$1"
    if [ ! -f "$target" ]; then
        if [ "$target" = "$HYPR_DIR/custom_keybinds.lua" ]; then
            cat << 'EOF' > "$target" 2>/dev/null || true
-- Custom Keybindings managed by Quickshell Settings
EOF
            if [ -f "$HYPR_DIR/hyprland.lua" ] && ! grep -q "custom_keybinds" "$HYPR_DIR/hyprland.lua" 2>/dev/null; then
                (echo "" >> "$HYPR_DIR/hyprland.lua" && echo 'pcall(require, "custom_keybinds")' >> "$HYPR_DIR/hyprland.lua") 2>/dev/null || true
            fi
        elif [ "$target" = "$HYPR_DIR/custom_keybinds.conf" ]; then
            cat << 'EOF' > "$target" 2>/dev/null || true
# Custom Keybindings managed by Quickshell Settings
EOF
            if [ -f "$HYPR_DIR/hyprland.conf" ] && ! grep -q "custom_keybinds.conf" "$HYPR_DIR/hyprland.conf" 2>/dev/null; then
                (echo "" >> "$HYPR_DIR/hyprland.conf" && echo "source = ~/.config/hypr/custom_keybinds.conf" >> "$HYPR_DIR/hyprland.conf") 2>/dev/null || true
            fi
        fi
    fi
}

format_bind() {
    local mods="$1"
    local key="$2"
    if [ -z "$mods" ]; then
        echo ", $key"
    else
        echo "$mods, $key"
    fi
}

format_lua_key() {
    local mods="$1"
    local key="$2"
    if [ -z "$mods" ]; then
        echo "$key"
    else
        local m
        m="$(echo "$mods" | sed -E 's/[[:space:]]+/ + /g')"
        echo "$m + $key"
    fi
}

sanitize_tag() {
    local disp="$1"
    local arg="$2"
    local bind="${3:-}"
    if [ -n "$bind" ]; then
        echo "qs_${bind}_${disp}_${arg}" | tr -cd 'a-zA-Z0-9_'
    else
        echo "qs_${disp}_${arg}" | tr -cd 'a-zA-Z0-9_'
    fi
}

if [ "$ACTION" = "detect_target" ]; then
    find_config_target
    exit 0

elif [ "$ACTION" = "list" ]; then
    python3 - << 'PYEOF'
import os, sys, re, json, subprocess

hypr_dir = os.path.expanduser(os.environ.get("HYPR_DIR", "~/.config/hypr"))

bind_map = {}

def get_modmask(parts):
    mask = 0
    for p in parts:
        pu = p.upper()
        if pu == "SUPER": mask |= 64
        elif pu == "CTRL": mask |= 4
        elif pu == "ALT": mask |= 8
        elif pu == "SHIFT": mask |= 1
    return mask

def parse_lua_file(filepath):
    if not filepath or not os.path.exists(filepath):
        return
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            text = f.read()
    except Exception:
        return

    lines = text.split("\n")
    vars = {"home": os.path.expanduser("~")}
    for line in lines:
        m_env = re.match(r'^\s*local\s+([a-zA-Z0-9_]+)\s*=\s*os\.getenv\s*\(\s*["\']([^"\']+)["\']\s*\)', line)
        if m_env:
            vars[m_env.group(1)] = os.environ.get(m_env.group(2), "")
            continue
        m_cat = re.match(r'^\s*local\s+([a-zA-Z0-9_]+)\s*=\s*([a-zA-Z0-9_]+)\s*\.\.\s*["\']([^"\']+)["\']', line)
        if m_cat and m_cat.group(2) in vars:
            vars[m_cat.group(1)] = vars[m_cat.group(2)] + m_cat.group(3)
            continue
        m = re.match(r'^\s*local\s+([a-zA-Z0-9_]+)\s*=\s*["\']([^"\']+)["\']', line)
        if m:
            vars[m.group(1)] = m.group(2)

    for line in lines:
        cleaned = re.sub(r'--.*$', '', line).strip()
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

        m_bind = re.search(r'hl\.bind\s*\(\s*(.+?)\s*,\s*(.+?)\s*(?:,\s*(\{.*\})\s*)?\)$', cleaned)
        if not m_bind:
            continue

        key_expr = m_bind.group(1).strip()
        action_expr = m_bind.group(2).strip()
        opts_expr = (m_bind.group(3) or "").strip()

        for k, v in vars.items():
            key_expr = re.sub(r"\b" + k + r"\b", f'"{v}"', key_expr)

        full_key = re.sub(r'["\'\s\.]+', " ", key_expr).strip()
        key_parts = [p.strip() for p in full_key.split("+") if p.strip()]
        if not key_parts:
            continue

        key = key_parts[-1]
        if key == "key":
            continue

        mods = key_parts[:-1]
        modmask = get_modmask(mods)

        resolved_action = action_expr
        for k, v in vars.items():
            resolved_action = re.sub(r"\b" + k + r"\b", v, resolved_action)

        disp = "exec"
        arg = ""
        desc = ""

        if "window.close" in resolved_action or "close()" in resolved_action:
            disp = "killactive"
            desc = "Close Active Window"
        elif "window.float" in resolved_action:
            disp = "togglefloating"
            desc = "Toggle Floating Window"
        elif "layout(\"togglesplit\")" in resolved_action or "togglesplit" in resolved_action:
            disp = "togglesplit"
            desc = "Toggle Split Layout"
        elif re.search(r'dsp\.layout\s*\(', resolved_action):
            lm = re.search(r'layout\s*\(\s*["\']([^"\']*)["\']', resolved_action)
            disp = "layoutmsg"
            arg = lm.group(1) if lm else ""
            desc = f"Layout: {arg}"
        elif "window.pseudo" in resolved_action:
            disp = "pseudo"
            desc = "Pseudo Tiling"
        elif "window.fullscreen" in resolved_action:
            disp = "fullscreen"
            desc = "Toggle Fullscreen"
        elif "focus(" in resolved_action and "direction" in resolved_action:
            dir_m = re.search(r'direction\s*=\s*["\']([^"\']+)["\']', resolved_action)
            direction = dir_m.group(1) if dir_m else ""
            disp = "movefocus"
            arg = direction[0] if direction else ""
            desc = f"Focus Window ({direction})"
        elif "focus(" in resolved_action and "workspace" in resolved_action:
            ws_m = re.search(r'workspace\s*=\s*["\']?([^"\'}\s,]+)["\']?', resolved_action)
            arg = ws_m.group(1) if ws_m else ""
            disp = "workspace"
            desc = f"Switch to Workspace {arg}"
        elif "window.move" in resolved_action and "workspace" in resolved_action:
            ws_m = re.search(r'workspace\s*=\s*["\']?([^"\'}\s,]+)["\']?', resolved_action)
            arg = ws_m.group(1) if ws_m else ""
            disp = "movetoworkspace"
            desc = f"Move Window to Workspace {arg}"
        elif "toggle_special" in resolved_action:
            sp_m = re.search(r'toggle_special\s*\(\s*["\']([^"\']+)["\']\s*\)', resolved_action)
            arg = sp_m.group(1) if sp_m else "special"
            disp = "togglespecialworkspace"
            desc = f"Toggle Special Workspace ({arg})"
        elif "dsp.exit(" in resolved_action:
            disp = "exit"
            arg = ""
            desc = "Exit Hyprland"
        elif "exec_cmd" in resolved_action or "exec" in resolved_action:
            disp = "exec"
            cmd_m = re.search(r'exec_cmd\s*\(\s*(["\'])(.*?)\1\s*\)', resolved_action)
            if cmd_m:
                arg = cmd_m.group(2).strip()
            else:
                arg = re.sub(r'^.*?exec_cmd\s*\(\s*["\']?|["\']?\s*\).*?$', '', resolved_action).strip()

            if "qs ipc call launcher" in arg: desc = "App Launcher"
            elif "qs ipc call settings" in arg: desc = "Settings App"
            elif "qs ipc call wallpaper" in arg: desc = "Wallpaper Switcher"
            elif "qs ipc call theme" in arg: desc = "Theme Switcher"
            elif "qs ipc call clipboard" in arg: desc = "Clipboard Manager"
            elif "ScreenShot.sh --now" in arg: desc = "Take Screenshot (Full)"
            elif "ScreenShot.sh --swappy" in arg: desc = "Take Screenshot (Area)"
            elif "ScreenShot.sh --win" in arg: desc = "Take Screenshot (Window)"
            elif "kitty" in arg: desc = "Terminal (kitty)"
            elif "nautilus" in arg: desc = "File Manager (nautilus)"
            elif "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" in arg: desc = "Volume Up"
            elif "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" in arg: desc = "Volume Down"
            elif "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" in arg: desc = "Mute Volume"
            elif "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" in arg: desc = "Mute Microphone"
            elif "brightnessctl" in arg and "5%+" in arg: desc = "Brightness Up"
            elif "brightnessctl" in arg and "5%-" in arg: desc = "Brightness Down"
            elif "playerctl next" in arg: desc = "Media Next"
            elif "playerctl play-pause" in arg: desc = "Media Play/Pause"
            elif "playerctl previous" in arg: desc = "Media Previous"
            elif "hyprshutdown" in arg: desc = "Power Menu / Shutdown"
            else: desc = arg
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
            "description": desc
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
        cleaned = re.sub(r'#.*$', '', line).strip()
        if not cleaned: continue
        m = re.match(r'^bind[a-z]*\s*=\s*(.+)$', cleaned)
        if not m: continue
        parts = [p.strip() for p in m.group(1).split(",")]
        if len(parts) >= 3:
            mods = parts[0].upper().replace("$MAINMOD", "SUPER").split()
            key = parts[1]
            disp = parts[2]
            arg = ",".join(parts[3:]).strip() if len(parts) > 3 else ""
            mask = get_modmask(mods)
            bind_map[(mask, key.lower())] = {
                "modmask": mask,
                "key": key,
                "dispatcher": disp,
                "arg": arg,
                "description": arg or disp
            }

for i in range(1, 11):
    k = str(i % 10)
    bind_map[(64, k)] = {
        "modmask": 64,
        "key": k,
        "dispatcher": "workspace",
        "arg": str(i),
        "description": f"Switch to Workspace {i}"
    }
    bind_map[(65, k)] = {
        "modmask": 65,
        "key": k,
        "dispatcher": "movetoworkspace",
        "arg": str(i),
        "description": f"Move Window to Workspace {i}"
    }

parse_lua_file(os.path.join(hypr_dir, "Configs", "Keybinds.lua"))
parse_lua_file(os.path.join(hypr_dir, "custom_keybinds.lua"))
parse_lua_file(os.path.join(hypr_dir, "hyprland.lua"))
parse_conf_file(os.path.join(hypr_dir, "UserConfigs", "UserKeybinds.conf"))
parse_conf_file(os.path.join(hypr_dir, "configs", "Keybinds.conf"))
parse_conf_file(os.path.join(hypr_dir, "custom_keybinds.conf"))

live_binds = []
try:
    res = subprocess.run(["hyprctl", "binds", "-j"], capture_output=True, text=True, timeout=0.8)
    if res.returncode == 0 and res.stdout.strip():
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

        # If dispatcher is __lua or empty, resolve it from bind_map
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
            "description": desc
        })
else:
    seen = set()
    uid = 0
    for (m, k), b in bind_map.items():
        if (m, b["key"]) in seen or b["key"].startswith("mouse"):
            continue
        seen.add((m, b["key"]))
        final_binds.append({
            "uid": uid,
            "modmask": b["modmask"],
            "key": b["key"],
            "dispatcher": b["dispatcher"],
            "arg": b["arg"],
            "description": b["description"]
        })
        uid += 1

print(json.dumps(final_binds))
PYEOF
    exit 0

elif [ "$ACTION" = "delete" ] || [ "$ACTION" = "unbind" ]; then
    MODS="$2"
    KEY="$3"
    DISPATCHER="$4"
    ARG="$5"

    BIND=$(format_bind "$MODS" "$KEY")
    LUA_KEY=$(format_lua_key "$MODS" "$KEY")

    # 1. Unbind in running Hyprland socket (multiple passes to clear duplicates)
    if [ -f "$HYPR_DIR/hyprland.lua" ]; then
        hyprctl eval "pcall(function() hl.unbind(\"$LUA_KEY\") end)" >/dev/null 2>&1 || true
    else
        for _ in 1 2 3; do
            hyprctl keyword unbind "$BIND" 2>/dev/null || true
        done
    fi

    # 2. Persist to config target
    CONFIG_TARGET=$(find_config_target)
    if [ -n "$CONFIG_TARGET" ]; then
        ensure_config_target "$CONFIG_TARGET"
        TAG=$(sanitize_tag "$DISPATCHER" "$ARG" "$BIND")
        LEGACY_TAG=$(sanitize_tag "$DISPATCHER" "$ARG")

        python3 - << EOF
import re

target = "$CONFIG_TARGET"
tag = "$TAG"
legacy_tag = "$LEGACY_TAG"
arg = __import__("os").environ.get("ARG", "")
bind_str = "$BIND"
lua_key = "$LUA_KEY"
is_lua = target.endswith(".lua")

try:
    with open(target, "r") as f:
        content = f.read()

    original = content
    # Remove any existing block for this tag, legacy tag, or arg
    for t in [tag, legacy_tag]:
        if t:
            content = re.sub(rf"\n*# <{t}>.*?# </{t}>\n*", "\n", content, flags=re.DOTALL)
            content = re.sub(rf"\n*-- <{t}>.*?-- </{t}>\n*", "\n", content, flags=re.DOTALL)
    if arg:
        content = re.sub(rf"\n*# <qs_[^>\n]*>(?:(?!# </qs_).)*?{re.escape(arg)}(?:(?!# </qs_).)*?# </qs_[^>\n]*>\n*", "\n", content, flags=re.DOTALL)
        content = re.sub(rf"\n*-- <qs_[^>\n]*>(?:(?!-- </qs_).)*?{re.escape(arg)}(?:(?!-- </qs_).)*?-- </qs_[^>\n]*>\n*", "\n", content, flags=re.DOTALL)

    # Tombstone cleanup: drop stale unbind-only blocks for this key (avoid pile-up)
    if is_lua:
        content = re.sub(rf'\\n*-- <qs_[^>\\n]*>\\s*pcall\\(function\\(\\) hl\\.unbind\\("{re.escape(lua_key)}"\\) end\\)\\s*-- </qs_[^>\\n]*>\\n*', "\\n", content)

    # An unbind tombstone is only needed to disable a bind defined elsewhere
    # (e.g. the default Configs/Keybinds.lua). If the key only lived in our own
    # block, removing that block is enough and no tombstone is left behind.
    def norm_key(k):
        return re.sub(r"[\\s+\"'.]", "", k).lower()

    defined_elsewhere = True
    if is_lua:
        defined_elsewhere = False
        want = norm_key(lua_key)
        hdir = __import__("os").path.dirname(target)
        for fp in [hdir + "/Configs/Keybinds.lua", hdir + "/hyprland.lua"]:
            try:
                with open(fp, "r") as ff:
                    txt = re.sub(r"(?m)^\\s*--.*$", "", ff.read())
            except Exception:
                continue
            mm = re.search(r"local\\s+mainMod\\s*=\\s*[\"']([^\"']+)[\"']", txt)
            for m in re.finditer(r"hl\\.bind\\(\\s*([^,]+?)\\s*,", txt):
                expr = m.group(1)
                if mm:
                    expr = re.sub(r"\\bmainMod\\b", mm.group(1), expr)
                if norm_key(expr) == want:
                    defined_elsewhere = True

    if not defined_elsewhere:
        content = content.rstrip() + "\\n"
        with open(target, "w") as f:
            f.write(content)
        raise SystemExit(0)

    if is_lua:
        unbind_block = f"""
-- <{tag}>
pcall(function() hl.unbind("{lua_key}") end)
-- </{tag}>
"""
    else:
        unbind_block = f"""
# <{tag}>
unbind = {bind_str}
# </{tag}>
"""
    content = content.rstrip() + "\n" + unbind_block

    with open(target, "w") as f:
        f.write(content)
except Exception as e:
    pass
EOF
    fi

    echo "delete_ok"

elif [ "$ACTION" = "rebind" ]; then
    OLD_MOD="$2"
    OLD_KEY="$3"
    NEW_MOD="$4"
    NEW_KEY="$5"
    DISPATCHER="$6"
    ARG="$7"
    DESC="$8"
    OLD_ARG="$9"
    OLD_DISP="${10:-}"

    OLD_BIND=$(format_bind "$OLD_MOD" "$OLD_KEY")
    NEW_BIND=$(format_bind "$NEW_MOD" "$NEW_KEY")
    OLD_LUA_KEY=$(format_lua_key "$OLD_MOD" "$OLD_KEY")
    NEW_LUA_KEY=$(format_lua_key "$NEW_MOD" "$NEW_KEY")

    # 1 & 2. Unbind old and bind new in running Hyprland socket (legacy .conf mode; Lua mode uses hyprctl eval below)
    if [ ! -f "$HYPR_DIR/hyprland.lua" ]; then
        for _ in 1 2 3; do
            hyprctl keyword unbind "$OLD_BIND" 2>/dev/null || true
        done

        if [ -n "$ARG" ]; then
            if [ -n "$DESC" ]; then
                hyprctl keyword bindd "$NEW_BIND, $DESC, $DISPATCHER, $ARG" 2>/dev/null || hyprctl keyword bind "$NEW_BIND, $DISPATCHER, $ARG" 2>/dev/null || true
            else
                hyprctl keyword bind "$NEW_BIND, $DISPATCHER, $ARG" 2>/dev/null || true
            fi
        else
            if [ -n "$DESC" ]; then
                hyprctl keyword bindd "$NEW_BIND, $DESC, $DISPATCHER" 2>/dev/null || hyprctl keyword bind "$NEW_BIND, $DISPATCHER" 2>/dev/null || true
            else
                hyprctl keyword bind "$NEW_BIND, $DISPATCHER" 2>/dev/null || true
            fi
        fi
    fi

    # 3. Persist to config target
    CONFIG_TARGET=$(find_config_target)
    if [ -n "$CONFIG_TARGET" ]; then
        ensure_config_target "$CONFIG_TARGET"
        TAG=$(sanitize_tag "$DISPATCHER" "$ARG" "$NEW_BIND")
        OLD_TAG=$(sanitize_tag "$OLD_DISP" "$OLD_ARG" "$OLD_BIND")
        LEGACY_TAG=$(sanitize_tag "$DISPATCHER" "$ARG")
        LEGACY_OLD_TAG=$(sanitize_tag "$OLD_DISP" "$OLD_ARG")

        python3 - << EOF
import re

target = "$CONFIG_TARGET"
tag = "$TAG"
old_tag = "$OLD_TAG"
legacy_tag = "$LEGACY_TAG"
legacy_old_tag = "$LEGACY_OLD_TAG"
arg = __import__("os").environ.get("ARG", "")
old_arg = __import__("os").environ.get("OLD_ARG", "")
old_bind = "$OLD_BIND"
new_bind = "$NEW_BIND"
old_lua = "$OLD_LUA_KEY"
new_lua = "$NEW_LUA_KEY"
disp = "$DISPATCHER"
is_lua = target.endswith(".lua")

def format_lua_bind(mods_key, d, a):
    lua_keys = f'"{mods_key.strip()}"'
    if d == "exec":
        escaped_a = a.replace(chr(92), chr(92) * 2).replace('"', chr(92) + '"')
        return f'hl.bind({lua_keys}, hl.dsp.exec_cmd("{escaped_a}"))'
    elif d in ("killactive", "closewindow"):
        return f'hl.bind({lua_keys}, hl.dsp.window.close())'
    elif d == "togglefloating":
        return f'hl.bind({lua_keys}, hl.dsp.window.float({{ action = "toggle" }}))'
    elif d == "togglesplit":
        return f'hl.bind({lua_keys}, hl.dsp.layout("togglesplit"))'
    elif d == "fullscreen":
        return f'hl.bind({lua_keys}, hl.dsp.window.fullscreen({{ action = "toggle" }}))'
    elif d == "pseudo":
        return f'hl.bind({lua_keys}, hl.dsp.window.pseudo())'
    # Native Lua dispatchers (same API as ~/.config/hypr/Configs/Keybinds.lua)
    a_s = a.strip()
    def ws(v):
        return v if re.fullmatch(r"-?\d+", v) else '"' + v.replace(chr(92), chr(92) * 2).replace('"', chr(92) + '"') + '"'
    dirs = {"l": "left", "r": "right", "u": "up", "d": "down",
            "left": "left", "right": "right", "up": "up", "down": "down"}
    if d == "workspace" and a_s:
        return f'hl.bind({lua_keys}, hl.dsp.focus({{ workspace = {ws(a_s)} }}))'
    if d in ("movetoworkspace", "movetoworkspacesilent") and a_s:
        return f'hl.bind({lua_keys}, hl.dsp.window.move({{ workspace = {ws(a_s)} }}))'
    if d == "movefocus" and a_s.lower() in dirs:
        return f'hl.bind({lua_keys}, hl.dsp.focus({{ direction = "{dirs[a_s.lower()]}" }}))'
    if d == "togglespecialworkspace":
        return f'hl.bind({lua_keys}, hl.dsp.workspace.toggle_special("{a_s or "special"}"))'
    if d == "layoutmsg" and a_s:
        return f'hl.bind({lua_keys}, hl.dsp.layout({ws(a_s)}))'
    if d == "exit":
        return f'hl.bind({lua_keys}, hl.dsp.exit())'
    # Unknown dispatcher: legacy dispatch string via hyprctl (may not work on Lua-only Hyprland)
    cmd = f"hyprctl dispatch {d} {a}".strip().replace(chr(92), chr(92) * 2).replace('"', chr(92) + '"')
    return f'hl.bind({lua_keys}, hl.dsp.exec_cmd("{cmd}"))'

def with_lua_desc(bind_call):
    dsc = __import__("os").environ.get("DESC", "").strip()
    if not dsc or not bind_call.endswith(")"):
        return bind_call
    esc = dsc.replace(chr(92), chr(92) * 2).replace('"', chr(92) + '"')
    return bind_call[:-1] + f', {{ desc = "{esc}" }})'

try:
    with open(target, "r") as f:
        content = f.read()

    # Remove any existing block for this tag, old_tag, legacy tags, old_arg, or arg
    for t in [tag, old_tag, legacy_tag, legacy_old_tag]:
        if t:
            content = re.sub(rf"\n*# <{t}>.*?# </{t}>\n*", "\n", content, flags=re.DOTALL)
            content = re.sub(rf"\n*-- <{t}>.*?-- </{t}>\n*", "\n", content, flags=re.DOTALL)
    if old_arg:
        content = re.sub(rf"\n*# <qs_[^>\n]*>(?:(?!# </qs_).)*?{re.escape(old_arg)}(?:(?!# </qs_).)*?# </qs_[^>\n]*>\n*", "\n", content, flags=re.DOTALL)
        content = re.sub(rf"\n*-- <qs_[^>\n]*>(?:(?!-- </qs_).)*?{re.escape(old_arg)}(?:(?!-- </qs_).)*?-- </qs_[^>\n]*>\n*", "\n", content, flags=re.DOTALL)
    if arg:
        content = re.sub(rf"\n*# <qs_[^>\n]*>(?:(?!# </qs_).)*?{re.escape(arg)}(?:(?!# </qs_).)*?# </qs_[^>\n]*>\n*", "\n", content, flags=re.DOTALL)
        content = re.sub(rf"\n*-- <qs_[^>\n]*>(?:(?!-- </qs_).)*?{re.escape(arg)}(?:(?!-- </qs_).)*?-- </qs_[^>\n]*>\n*", "\n", content, flags=re.DOTALL)

    if is_lua:
        bind_line = with_lua_desc(format_lua_bind(new_lua, disp, arg))
        try:
            __import__("subprocess").run(
                ["hyprctl", "eval", f'pcall(function() hl.unbind("{old_lua}") end); {bind_line}'],
                capture_output=True, timeout=1
            )
        except Exception:
            pass
        rebind_block = f"""
-- <{tag}>
pcall(function() hl.unbind("{old_lua}") end)
{bind_line}
-- </{tag}>
"""
    else:
        bind_line = f"bind = {new_bind}, {disp}, {arg}" if arg else f"bind = {new_bind}, {disp}"
        rebind_block = f"""
# <{tag}>
unbind = {old_bind}
{bind_line}
# </{tag}>
"""
    content = content.rstrip() + "\n" + rebind_block

    with open(target, "w") as f:
        f.write(content)
except Exception as e:
    pass
EOF
    fi

    echo "rebind_ok"

elif [ "$ACTION" = "add" ]; then
    MODS="$2"
    KEY="$3"
    DISPATCHER="$4"
    ARG="$5"
    DESC="$6"

    BIND=$(format_bind "$MODS" "$KEY")
    LUA_KEY=$(format_lua_key "$MODS" "$KEY")

    # 1. Bind live in running Hyprland socket (legacy .conf mode; Lua mode uses hyprctl eval below)
    if [ ! -f "$HYPR_DIR/hyprland.lua" ]; then
        if [ -n "$ARG" ]; then
            if [ -n "$DESC" ]; then
                hyprctl keyword bindd "$BIND, $DESC, $DISPATCHER, $ARG" 2>/dev/null || hyprctl keyword bind "$BIND, $DISPATCHER, $ARG" 2>/dev/null || true
            else
                hyprctl keyword bind "$BIND, $DISPATCHER, $ARG" 2>/dev/null || true
            fi
        else
            if [ -n "$DESC" ]; then
                hyprctl keyword bindd "$BIND, $DESC, $DISPATCHER" 2>/dev/null || hyprctl keyword bind "$BIND, $DISPATCHER" 2>/dev/null || true
            else
                hyprctl keyword bind "$BIND, $DISPATCHER" 2>/dev/null || true
            fi
        fi
    fi

    # 2. Persist to config target
    CONFIG_TARGET=$(find_config_target)
    if [ -n "$CONFIG_TARGET" ]; then
        ensure_config_target "$CONFIG_TARGET"
        TAG=$(sanitize_tag "$DISPATCHER" "$ARG" "$BIND")
        LEGACY_TAG=$(sanitize_tag "$DISPATCHER" "$ARG")

        python3 - << EOF
import re

target = "$CONFIG_TARGET"
tag = "$TAG"
legacy_tag = "$LEGACY_TAG"
arg = __import__("os").environ.get("ARG", "")
bind_str = "$BIND"
lua_key = "$LUA_KEY"
disp = "$DISPATCHER"
is_lua = target.endswith(".lua")

def format_lua_bind(mods_key, d, a):
    lua_keys = f'"{mods_key.strip()}"'
    if d == "exec":
        escaped_a = a.replace(chr(92), chr(92) * 2).replace('"', chr(92) + '"')
        return f'hl.bind({lua_keys}, hl.dsp.exec_cmd("{escaped_a}"))'
    elif d in ("killactive", "closewindow"):
        return f'hl.bind({lua_keys}, hl.dsp.window.close())'
    elif d == "togglefloating":
        return f'hl.bind({lua_keys}, hl.dsp.window.float({{ action = "toggle" }}))'
    elif d == "togglesplit":
        return f'hl.bind({lua_keys}, hl.dsp.layout("togglesplit"))'
    elif d == "fullscreen":
        return f'hl.bind({lua_keys}, hl.dsp.window.fullscreen({{ action = "toggle" }}))'
    elif d == "pseudo":
        return f'hl.bind({lua_keys}, hl.dsp.window.pseudo())'
    # Native Lua dispatchers (same API as ~/.config/hypr/Configs/Keybinds.lua)
    a_s = a.strip()
    def ws(v):
        return v if re.fullmatch(r"-?\d+", v) else '"' + v.replace(chr(92), chr(92) * 2).replace('"', chr(92) + '"') + '"'
    dirs = {"l": "left", "r": "right", "u": "up", "d": "down",
            "left": "left", "right": "right", "up": "up", "down": "down"}
    if d == "workspace" and a_s:
        return f'hl.bind({lua_keys}, hl.dsp.focus({{ workspace = {ws(a_s)} }}))'
    if d in ("movetoworkspace", "movetoworkspacesilent") and a_s:
        return f'hl.bind({lua_keys}, hl.dsp.window.move({{ workspace = {ws(a_s)} }}))'
    if d == "movefocus" and a_s.lower() in dirs:
        return f'hl.bind({lua_keys}, hl.dsp.focus({{ direction = "{dirs[a_s.lower()]}" }}))'
    if d == "togglespecialworkspace":
        return f'hl.bind({lua_keys}, hl.dsp.workspace.toggle_special("{a_s or "special"}"))'
    if d == "layoutmsg" and a_s:
        return f'hl.bind({lua_keys}, hl.dsp.layout({ws(a_s)}))'
    if d == "exit":
        return f'hl.bind({lua_keys}, hl.dsp.exit())'
    # Unknown dispatcher: legacy dispatch string via hyprctl (may not work on Lua-only Hyprland)
    cmd = f"hyprctl dispatch {d} {a}".strip().replace(chr(92), chr(92) * 2).replace('"', chr(92) + '"')
    return f'hl.bind({lua_keys}, hl.dsp.exec_cmd("{cmd}"))'

def with_lua_desc(bind_call):
    dsc = __import__("os").environ.get("DESC", "").strip()
    if not dsc or not bind_call.endswith(")"):
        return bind_call
    esc = dsc.replace(chr(92), chr(92) * 2).replace('"', chr(92) + '"')
    return bind_call[:-1] + f', {{ desc = "{esc}" }})'

try:
    with open(target, "r") as f:
        content = f.read()

    for t in [tag, legacy_tag]:
        if t:
            content = re.sub(rf"\n*# <{t}>.*?# </{t}>\n*", "\n", content, flags=re.DOTALL)
            content = re.sub(rf"\n*-- <{t}>.*?-- </{t}>\n*", "\n", content, flags=re.DOTALL)

    if is_lua:
        bind_line = with_lua_desc(format_lua_bind(lua_key, disp, arg))
        try:
            __import__("subprocess").run(["hyprctl", "eval", bind_line], capture_output=True, timeout=1)
        except Exception:
            pass
        add_block = f"""
-- <{tag}>
{bind_line}
-- </{tag}>
"""
    else:
        bind_line = f"bind = {bind_str}, {disp}, {arg}" if arg else f"bind = {bind_str}, {disp}"
        add_block = f"""
# <{tag}>
{bind_line}
# </{tag}>
"""
    content = content.rstrip() + "\n" + add_block

    with open(target, "w") as f:
        f.write(content)
except Exception as e:
    pass
EOF
    fi

    echo "add_ok"
fi
