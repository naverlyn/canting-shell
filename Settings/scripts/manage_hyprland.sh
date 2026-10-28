#!/usr/bin/env bash
# /* ---- 💫 manage_hyprland.sh 💫 ---- */
# Comprehensive Hyprland Variables manager for Quickshell Settings.
# Fully compatible with both Vanilla Hyprland, modular dotfiles (JaKooLit, ML4W, HyDE, etc.),
# and modern Hyprland Lua configurations (.lua and .conf).
# Supports reading & live updating variables across General, Decoration, Gestures, and Misc.

set -euo pipefail

HYPR_DIR="${HYPR_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/hypr}"
export HYPR_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR

# Auto-detect HYPRLAND_INSTANCE_SIGNATURE if not explicitly in environment
detect_hypr_instance() {
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        local uid
        uid="$(id -u)"
        local inst
        inst="$(ls -td /run/user/"$uid"/hypr/*_*/ 2>/dev/null | head -n1 || true)"
        if [[ -n "$inst" ]]; then
            export HYPRLAND_INSTANCE_SIGNATURE="$(basename "$inst")"
        fi
    fi
}

find_config_target() {
    local is_decor="${1:-0}"
    local target_section="${2:-}"

    # 1. Hyprland Lua Configuration
    if [[ -f "$HYPR_DIR/hyprland.lua" ]]; then
        # Modular Lua configs under Configs/
        if [[ -d "$HYPR_DIR/Configs" ]]; then
            if [[ "$is_decor" -eq 1 || "$target_section" == "general"* || "$target_section" == "decoration"* ]]; then
                if [[ -f "$HYPR_DIR/Configs/WindowDecoration.lua" ]]; then
                    echo "$HYPR_DIR/Configs/WindowDecoration.lua"
                    return
                fi
            elif [[ "$target_section" == "misc"* || "$target_section" == "cursor"* ]]; then
                if [[ -f "$HYPR_DIR/Configs/Misc.lua" ]]; then
                    echo "$HYPR_DIR/Configs/Misc.lua"
                    return
                fi
            elif [[ "$target_section" == "gestures"* || "$target_section" == "input"* ]]; then
                if [[ -f "$HYPR_DIR/Configs/Input.lua" ]]; then
                    echo "$HYPR_DIR/Configs/Input.lua"
                    return
                fi
            fi
        fi

        # If custom_hypr.lua already exists, use it
        if [[ -f "$HYPR_DIR/custom_hypr.lua" ]]; then
            echo "$HYPR_DIR/custom_hypr.lua"
            return
        fi

        # Create custom_hypr.lua and ensure pcall(require, "custom_hypr") in hyprland.lua
        local custom_file="$HYPR_DIR/custom_hypr.lua"
        if [[ ! -f "$custom_file" ]]; then
            cat << 'EOF' > "$custom_file"
-- Hyprland variables managed by Quickshell Settings
hl.config({
})
EOF
        fi
        if ! grep -q "custom_hypr" "$HYPR_DIR/hyprland.lua" 2>/dev/null; then
            echo "" >> "$HYPR_DIR/hyprland.lua"
            echo 'pcall(require, "custom_hypr")' >> "$HYPR_DIR/hyprland.lua"
        fi
        echo "$custom_file"
        return
    fi

    # 2. Modular UserConfigs exists (e.g. JaKooLit dotfiles)
    if [[ -d "$HYPR_DIR/UserConfigs" ]]; then
        if [[ "$is_decor" -eq 1 && -f "$HYPR_DIR/UserConfigs/UserDecorations.conf" ]]; then
            echo "$HYPR_DIR/UserConfigs/UserDecorations.conf"
            return
        elif [[ "$is_decor" -eq 0 && -f "$HYPR_DIR/UserConfigs/UserSettings.conf" ]]; then
            echo "$HYPR_DIR/UserConfigs/UserSettings.conf"
            return
        fi
    fi

    # 3. If custom_hypr.conf already exists, use it
    if [[ -f "$HYPR_DIR/custom_hypr.conf" ]]; then
        echo "$HYPR_DIR/custom_hypr.conf"
        return
    fi

    # 4. Vanilla Hyprland: hyprland.conf exists
    if [[ -f "$HYPR_DIR/hyprland.conf" ]]; then
        local custom_file="$HYPR_DIR/custom_hypr.conf"
        if [[ ! -f "$custom_file" ]]; then
            cat << 'EOF' > "$custom_file"
# Hyprland variables managed by Quickshell Settings
EOF
        fi
        if ! grep -q "custom_hypr.conf" "$HYPR_DIR/hyprland.conf" 2>/dev/null; then
            echo "" >> "$HYPR_DIR/hyprland.conf"
            echo "source = ~/.config/hypr/custom_hypr.conf" >> "$HYPR_DIR/hyprland.conf"
        fi
        echo "$custom_file"
        return
    fi

    # 5. Fallback
    echo "$HYPR_DIR/hyprland.conf"
}

get_status() {
    detect_hypr_instance

    python3 - << 'EOF'
import os, json, re, subprocess

hypr_dir = os.path.expanduser(os.environ.get("HYPR_DIR", "~/.config/hypr"))

# Default baseline fallback values matching Hyprland standard defaults
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
        "inactive_border_col": "#32364a"
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
        "shadow_render_power": 1
    },
    "gestures": {
        "workspace_swipe": True,
        "workspace_swipe_fingers": 3,
        "workspace_swipe_distance": 300,
        "workspace_swipe_invert": True,
        "workspace_swipe_forever": True
    },
    "misc": {
        "vrr": 2,
        "vfr": True,
        "disable_hyprland_logo": True,
        "disable_splash_rendering": True,
        "mouse_move_enables_dpms": True,
        "middle_click_paste": False,
        "no_hardware_cursors": 2
    }
}

parsed_files = set()

def to_val(v_str):
    if v_str in ("true", "yes", "on", "1"):
        return True
    if v_str in ("false", "no", "off", "0"):
        return False
    try:
        if "." in v_str:
            return float(v_str)
        return int(v_str)
    except ValueError:
        return v_str

def apply_kv(block_scope, k, raw_v):
    v_lower = raw_v.lower() if isinstance(raw_v, str) else str(raw_v).lower()
    val = to_val(v_lower)

    if block_scope == "general":
        if k == "gaps_in": data["general"]["gaps_in"] = int(val)
        elif k == "gaps_out": data["general"]["gaps_out"] = int(val)
        elif k == "border_size": data["general"]["border_size"] = int(val)
        elif k == "layout": data["general"]["layout"] = str(val)
        elif k == "resize_on_border": data["general"]["resize_on_border"] = bool(val)
        elif k == "allow_tearing": data["general"]["allow_tearing"] = bool(val)
    elif block_scope == "general.snap" or (block_scope == "general" and k.startswith("snap:")):
        sub_k = k.replace("snap:", "")
        if sub_k == "enabled": data["general"]["snap_enabled"] = bool(val)
        elif sub_k == "window_gap": data["general"]["snap_window_gap"] = int(val)
    elif block_scope == "decoration":
        if k == "rounding": data["decoration"]["rounding"] = int(val)
        elif k == "active_opacity": data["decoration"]["active_opacity"] = float(val)
        elif k == "inactive_opacity": data["decoration"]["inactive_opacity"] = float(val)
        elif k == "dim_inactive": data["decoration"]["dim_inactive"] = bool(val)
        elif k == "dim_strength": data["decoration"]["dim_strength"] = float(val)
    elif block_scope == "decoration.blur":
        if k == "enabled": data["decoration"]["blur_enabled"] = bool(val)
        elif k == "size": data["decoration"]["blur_size"] = int(val)
        elif k == "passes": data["decoration"]["blur_passes"] = int(val)
        elif k == "popups": data["decoration"]["blur_popups"] = bool(val)
        elif k == "xray": data["decoration"]["blur_xray"] = bool(val)
    elif block_scope == "decoration.shadow":
        if k == "enabled": data["decoration"]["shadow_enabled"] = bool(val)
        elif k == "range": data["decoration"]["shadow_range"] = int(val)
        elif k == "render_power": data["decoration"]["shadow_render_power"] = int(val)
    elif block_scope == "gestures":
        if k == "workspace_swipe": data["gestures"]["workspace_swipe"] = bool(val)
        elif k == "workspace_swipe_fingers": data["gestures"]["workspace_swipe_fingers"] = int(val)
        elif k == "workspace_swipe_distance": data["gestures"]["workspace_swipe_distance"] = int(val)
        elif k == "workspace_swipe_invert": data["gestures"]["workspace_swipe_invert"] = bool(val)
        elif k == "workspace_swipe_forever": data["gestures"]["workspace_swipe_forever"] = bool(val)
    elif block_scope == "misc":
        if k == "vrr": data["misc"]["vrr"] = int(val) if isinstance(val, int) else (1 if val else 0)
        elif k == "vfr": data["misc"]["vfr"] = bool(val)
        elif k == "disable_hyprland_logo": data["misc"]["disable_hyprland_logo"] = bool(val)
        elif k == "disable_splash_rendering": data["misc"]["disable_splash_rendering"] = bool(val)
        elif k == "mouse_move_enables_dpms": data["misc"]["mouse_move_enables_dpms"] = bool(val)
        elif k == "middle_click_paste": data["misc"]["middle_click_paste"] = bool(val)
    elif block_scope == "cursor":
        if k == "no_hardware_cursors": data["misc"]["no_hardware_cursors"] = int(val) if isinstance(val, int) else (1 if val else 0)

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
            sub_path = src_match.group(1).strip()
            sub_path = sub_path.replace("$HOME", os.path.expanduser("~"))
            sub_path = sub_path.replace("~", os.path.expanduser("~"))
            sub_path = sub_path.replace("$configs", os.path.join(hypr_dir, "configs"))
            sub_path = sub_path.replace("$UserConfigs", os.path.join(hypr_dir, "UserConfigs"))
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
            k = kv_match.group(1).strip().lower()
            raw_v = kv_match.group(2).strip()
            block_scope = ".".join(current_block) if current_block else ""
            apply_kv(block_scope, k, raw_v)

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

        # Check for require(...)
        req_m = re.search(r'require\s*\(\s*["\']([^"\']+)["\']\s*\)', cleaned)
        if req_m:
            req_mod = req_m.group(1).replace(".", "/") + ".lua"
            for candidate in [
                os.path.join(hypr_dir, req_mod),
                os.path.join(base_dir, req_mod),
                os.path.join(hypr_dir, req_m.group(1) + ".lua")
            ]:
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
            k = m_kv.group(1).lower()
            raw_v = m_kv.group(2).strip().strip("\"'")
            block_scope = ".".join([s for s in stack if s != "hl.config"])
            apply_kv(block_scope, k, raw_v)

        if net_braces < 0:
            for _ in range(abs(net_braces)):
                if stack:
                    stack.pop()

# Parse Lua configs if present
parse_lua_config(os.path.join(hypr_dir, "hyprland.lua"))
parse_lua_config(os.path.join(hypr_dir, "Configs", "WindowDecoration.lua"))
parse_lua_config(os.path.join(hypr_dir, "Configs", "Misc.lua"))
parse_lua_config(os.path.join(hypr_dir, "Configs", "Input.lua"))
parse_lua_config(os.path.join(hypr_dir, "custom_hypr.lua"))

# Parse Conf configs if present
parse_conf(os.path.join(hypr_dir, "hyprland.conf"))
parse_conf(os.path.join(hypr_dir, "configs", "SystemSettings.conf"))
parse_conf(os.path.join(hypr_dir, "UserConfigs", "UserDecorations.conf"))
parse_conf(os.path.join(hypr_dir, "UserConfigs", "UserSettings.conf"))
parse_conf(os.path.join(hypr_dir, "custom_hypr.conf"))

# If hyprctl is responsive, query live options from compositor
def query_hyprctl(opt):
    try:
        res = subprocess.run(["hyprctl", "getoption", opt, "-j"], capture_output=True, text=True, timeout=0.3)
        if res.returncode == 0 and res.stdout:
            obj = json.loads(res.stdout)
            if "int" in obj: return obj["int"]
            if "float" in obj: return obj["float"]
            if "str" in obj: return obj["str"]
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
            if type_fn == bool:
                data[sec][k] = bool(val)
            elif type_fn == int:
                data[sec][k] = int(val)
            elif type_fn == float:
                data[sec][k] = float(val)
            else:
                data[sec][k] = str(val)
        except Exception:
            pass

# Lua configs: workspace swipe lives in hl.gesture({...}), not gestures:workspace_swipe*
if os.path.isfile(os.path.join(hypr_dir, "hyprland.lua")):
    try:
        res = subprocess.run(["python3", os.path.join(os.environ.get("SCRIPT_DIR", "."), "lua_gesture.py"), "get"],
                             capture_output=True, text=True, timeout=2)
        g = json.loads(res.stdout)
        data["gestures"]["workspace_swipe"] = bool(g["enabled"])
        data["gestures"]["workspace_swipe_fingers"] = int(g["fingers"])
    except Exception:
        pass

# Parse border colors from theme-borders.lua / theme-borders.conf / WindowDecoration.lua
def rgba_to_hex(c_str):
    m = re.search(r"rgba\(\s*([0-9a-fA-F]{6})", c_str)
    if m:
        return "#" + m.group(1).lower()
    m_hex = re.search(r"([0-9a-fA-F]{6})", c_str)
    if m_hex:
        return "#" + m_hex.group(1).lower()
    return None

for b_file in [
    os.path.join(hypr_dir, "Configs", "WindowDecoration.lua"),
    os.path.join(hypr_dir, "theme-borders.conf"),
    os.path.join(hypr_dir, "theme-borders.lua")
]:
    if os.path.isfile(b_file):
        try:
            with open(b_file, "r", encoding="utf-8", errors="ignore") as bf:
                b_txt = bf.read()
            if "custom_border = true" in b_txt:
                data["general"]["border_theme_sync"] = False
            elif "theme_sync = true" in b_txt:
                data["general"]["border_theme_sync"] = True

            # Match active_border and inactive_border in Lua or Conf
            for bline in b_txt.splitlines():
                bs = bline.split("--")[0].strip()
                if "inactive_border" in bs and "=" in bs:
                    rhs = bs.split("=", 1)[1]
                    cols = re.findall(r'rgba\(\s*[0-9a-fA-F]{6,8}\s*\)', rhs)
                    if cols:
                        hi = rgba_to_hex(cols[0])
                        if hi: data["general"]["inactive_border_col"] = hi
                elif "active_border" in bs and "=" in bs:
                    rhs = bs.split("=", 1)[1]
                    cols = re.findall(r'rgba\(\s*[0-9a-fA-F]{6,8}\s*\)', rhs)
                    if len(cols) >= 1:
                        h1 = rgba_to_hex(cols[0])
                        if h1: data["general"]["active_border_col1"] = h1
                    if len(cols) >= 2:
                        h2 = rgba_to_hex(cols[1])
                        if h2: data["general"]["active_border_col2"] = h2
                    elif len(cols) == 1:
                        h1 = rgba_to_hex(cols[0])
                        if h1: data["general"]["active_border_col2"] = h1
                    ang_m = re.search(r'angle\s*=\s*(\d+)|(\d+)deg', rhs)
                    if ang_m:
                        data["general"]["active_border_angle"] = int(ang_m.group(1) or ang_m.group(2))
        except Exception:
            pass

print(json.dumps(data))
EOF
}

set_borders() {
    local col1="${1:-#7aa2f7}"
    local col2="${2:-#7dcfff}"
    local angle="${3:-45}"
    local inactive="${4:-#32364a}"
    local sync="${5:-false}"

    detect_hypr_instance

    python3 - "$col1" "$col2" "$angle" "$inactive" "$sync" << 'EOF'
import sys, os, re, json, subprocess

col1 = sys.argv[1].strip()
col2 = sys.argv[2].strip()
try:
    angle = int(float(sys.argv[3].strip()))
except Exception:
    angle = 45
inactive = sys.argv[4].strip()
sync = sys.argv[5].strip().lower() in ("true", "1", "yes", "on")

hypr_dir = os.path.expanduser(os.environ.get("HYPR_DIR", "~/.config/hypr"))
is_lua = os.path.isfile(os.path.join(hypr_dir, "hyprland.lua"))

def to_rgba(hex_str):
    h = hex_str.strip().lstrip("#")
    if re.fullmatch(r"[0-9a-fA-F]{6}", h):
        return f"rgba({h.lower()}ff)"
    if re.fullmatch(r"[0-9a-fA-F]{8}", h):
        return f"rgba({h.lower()})"
    if hex_str.startswith("rgba("):
        return hex_str
    return "rgba(7aa2f7ff)"

rgba1 = to_rgba(col1)
rgba2 = to_rgba(col2)
rgba_inact = to_rgba(inactive)
header_flag = "theme_sync = true" if sync else "custom_border = true"

if is_lua:
    target = os.path.join(hypr_dir, "theme-borders.lua")
    lua_content = (
        f"-- {header_flag}\n"
        f"hl.config({{\n"
        f"    general = {{\n"
        f'        ["col.active_border"] = {{ colors = {{ "{rgba1}", "{rgba2}" }}, angle = {angle} }},\n'
        f'        ["col.inactive_border"] = "{rgba_inact}",\n'
        f"    }},\n"
        f"}})\n"
    )
    with open(target, "w", encoding="utf-8") as f:
        f.write(lua_content)

    # Also keep Configs/WindowDecoration.lua in sync if present
    win_dec = os.path.join(hypr_dir, "Configs", "WindowDecoration.lua")
    if os.path.isfile(win_dec):
        try:
            with open(win_dec, "r", encoding="utf-8") as wf:
                w_txt = wf.read()
            w_txt = re.sub(
                r'(active_border\s*=\s*)\{[^}]+\}\s*,\s*angle\s*=\s*\d+\s*\}',
                f'\\1{{ colors = {{"{rgba1}", "{rgba2}"}}, angle = {angle} }}',
                w_txt
            )
            w_txt = re.sub(
                r'(inactive_border\s*=\s*)"[^"]+"',
                f'\\1"{rgba_inact}"',
                w_txt
            )
            with open(win_dec, "w", encoding="utf-8") as wf:
                wf.write(w_txt)
        except Exception:
            pass

    hypr_lua = os.path.join(hypr_dir, "hyprland.lua")
    if os.path.isfile(hypr_lua):
        with open(hypr_lua, "r", encoding="utf-8") as hf:
            h_txt = hf.read()
        if "theme-borders" not in h_txt:
            with open(hypr_lua, "a", encoding="utf-8") as hf:
                hf.write('\npcall(require, "theme-borders")\n')

    try:
        subprocess.run(
            ["hyprctl", "eval", f'dofile("{target}")'],
            capture_output=True, timeout=1
        )
    except Exception:
        pass
else:
    target = os.path.join(hypr_dir, "theme-borders.conf")
    conf_content = (
        f"# {header_flag}\n"
        f"general {{\n"
        f"    col.active_border = {rgba1} {rgba2} {angle}deg\n"
        f"    col.inactive_border = {rgba_inact}\n"
        f"}}\n"
    )
    with open(target, "w", encoding="utf-8") as f:
        f.write(conf_content)
    try:
        subprocess.run(["hyprctl", "keyword", "general:col.active_border", f"{rgba1} {rgba2} {angle}deg"], capture_output=True, timeout=1)
        subprocess.run(["hyprctl", "keyword", "general:col.inactive_border", rgba_inact], capture_output=True, timeout=1)
    except Exception:
        pass

print(json.dumps({
    "status": "ok",
    "key": "Border colors",
    "col1": col1,
    "col2": col2,
    "angle": angle,
    "inactive": inactive,
    "sync": sync
}))
EOF
}

set_var() {
    local target_section="${1:-}"
    local target_key="${2:-}"
    local target_val="${3:-}"

    if [[ -z "$target_section" || -z "$target_key" || -z "$target_val" ]]; then
        echo "{\"status\":\"error\",\"message\":\"Missing parameters\"}"
        exit 1
    fi

    if [[ "$target_section" == "misc" && "$target_key" == "no_hardware_cursors" ]]; then
        target_section="cursor"
    fi

    detect_hypr_instance

    # Lua configs: workspace_swipe / workspace_swipe_fingers were replaced by hl.gesture().
    # Edit the gesture block instead; Hyprland auto-reloads the config on save.
    if [[ -f "$HYPR_DIR/hyprland.lua" && "$target_section" == "gestures" ]]; then
        case "$target_key" in
            workspace_swipe)
                python3 "$SCRIPT_DIR/lua_gesture.py" set enabled "$target_val"; return ;;
            workspace_swipe_fingers)
                python3 "$SCRIPT_DIR/lua_gesture.py" set fingers "$target_val"; return ;;
        esac
    fi

    # 1. Apply live via hyprctl if available (legacy .conf mode; Lua mode uses hyprctl eval below)
    if [[ ! -f "$HYPR_DIR/hyprland.lua" ]] && command -v hyprctl >/dev/null 2>&1; then
        local hypr_arg="$target_val"
        if [[ "$target_val" == "true" ]]; then
            hypr_arg="1"
        elif [[ "$target_val" == "false" ]]; then
            hypr_arg="0"
        fi

        # Convert nested dot notation (decoration.blur -> decoration:blur)
        local opt_name="${target_section//./:}:${target_key}"
        hyprctl keyword "$opt_name" "$hypr_arg" >/dev/null 2>&1 || true
    fi

    # 2. Determine target persistence file
    local is_decor=0
    if [[ "$target_section" == "decoration"* || "$target_section" == "general"* ]]; then
        is_decor=1
    fi
    local target_path
    target_path="$(find_config_target "$is_decor" "$target_section")"

    # 3. Persist in config file (.lua or .conf)
    python3 - "$target_path" "$target_section" "$target_key" "$target_val" << 'EOF'
import sys, os, re, json

target_path = sys.argv[1].strip()
section = sys.argv[2].strip()
key = sys.argv[3].strip()
val = sys.argv[4].strip()

is_lua = target_path.endswith(".lua")

if not os.path.exists(target_path):
    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    with open(target_path, "w", encoding="utf-8") as f:
        if is_lua:
            f.write("-- Hyprland Configuration managed by Quickshell\nhl.config({\n})\n")
        else:
            f.write("# Hyprland Configuration managed by Quickshell\n\n")

with open(target_path, "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

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
            bname = open_m.group(2).lower()
            block_stack.append(bname)
            if [b.lower() for b in target_parts] == block_stack:
                target_block_open_line = i
            continue

        if "}" in stripped:
            if block_stack:
                block_stack.pop()
            continue

        kv_m = re.match(r"^(\s*)([a-zA-Z0-9_\.\-]+)\s*=\s*(.*)", line)
        if kv_m:
            key_name = kv_m.group(2).strip().lower()
            if [b.lower() for b in target_parts] == block_stack and key_name == k.lower():
                found_key_line = i

    indent = "  " * len(target_parts)
    new_kv_line = f"{indent}{k} = {v}"

    if found_key_line != -1:
        lines[found_key_line] = new_kv_line
        return "\n".join(lines) + "\n"

    if target_block_open_line != -1:
        lines.insert(target_block_open_line + 1, new_kv_line)
        return "\n".join(lines) + "\n"

    # Block does not exist, append cleanly
    if len(target_parts) == 1:
        p_sec = target_parts[0]
        block_text = f"\n{p_sec} {{\n  {k} = {v}\n}}\n"
        return cfg_text.rstrip() + block_text
    elif len(target_parts) == 2:
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
        else:
            block_text = f"\n{parent_sec} {{\n  {sub_sec} {{\n    {k} = {v}\n  }}\n}}\n"
            return cfg_text.rstrip() + block_text

    return cfg_text

def update_lua_config(cfg_text, sec, k, v_str):
    def format_lua_val(val):
        v_s = str(val).strip()
        if v_s.lower() in ("true", "false"):
            return v_s.lower()
        try:
            if "." in v_s:
                float(v_s)
                return v_s
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
        if not cleaned: continue

        m_tbl = re.match(r"^([a-zA-Z0-9_\.]+)\s*=\s*\{", cleaned)
        net_braces = cleaned.count("{") - cleaned.count("}")

        if m_tbl and net_braces > 0:
            stack.append(m_tbl.group(1).lower())
            if stack == target_parts:
                target_open_idx = i
                leading = line[:len(line) - len(line.lstrip())]
                target_indent = leading + "    "
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
                if stack: stack.pop()

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
            f"{leading}    }},"
        ]
        lines.insert(parent_open_idx + 1, "\n".join(nested_block))
        return "\n".join(lines) + "\n"

    indent = "    "
    if len(target_parts) == 1:
        block = f"\nhl.config({{\n{indent}{sec} = {{\n{indent}{indent}{lua_key} = {formatted_val},\n{indent}}},\n}})\n"
    else:
        p_sec = target_parts[0]
        sub_sec = target_parts[1]
        block = f"\nhl.config({{\n{indent}{p_sec} = {{\n{indent}{indent}{sub_sec} = {{\n{indent}{indent}{indent}{lua_key} = {formatted_val},\n{indent}{indent}}},\n{indent}}},\n}})\n"
    return cfg_text.rstrip() + block

if is_lua:
    updated = update_lua_config(content, section, key, val)
    try:
        import subprocess
        v_s = str(val).strip()
        if v_s.lower() in ("true", "false"):
            fv = v_s.lower()
        else:
            try:
                fv = v_s if ("." in v_s and float(v_s) is not None) or int(v_s) is not None else v_s
            except ValueError:
                fv = f'"{v_s}"'
        lk = key if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key) else f'["{key}"]'
        parts = [p.lower() for p in section.split(".")]
        if len(parts) == 1:
            eval_code = f"hl.config({{ {parts[0]} = {{ {lk} = {fv} }} }})"
        else:
            eval_code = f"hl.config({{ {parts[0]} = {{ {parts[1]} = {{ {lk} = {fv} }} }} }})"
        subprocess.run(["hyprctl", "eval", eval_code], capture_output=True, timeout=1)
    except Exception:
        pass
else:
    updated = update_hypr_config(content, section, key, val)

with open(target_path, "w", encoding="utf-8") as f:
    f.write(updated)

print(json.dumps({"status": "ok", "section": section, "key": key, "value": val, "target": target_path}))
EOF
}

case "${1:-get}" in
    get)
        get_status
        ;;
    set)
        set_var "${2:-}" "${3:-}" "${4:-}"
        ;;
    set_borders)
        set_borders "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}"
        ;;
    *)
        echo "Usage: $0 {get|set <section> <key> <value>|set_borders <col1> <col2> <angle> <inactive> <sync>}"
        exit 1
        ;;
esac
