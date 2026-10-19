#!/usr/bin/env bash
# /* ---- 💫 manage_hyprland.sh 💫 ---- */
# Comprehensive Hyprland Variables manager for Quickshell Settings.
# Fully compatible with both Vanilla Hyprland and modular dotfiles (JaKooLit, ML4W, HyDE, etc.).
# Supports reading & live updating variables across General, Decoration, Gestures, and Misc.

set -euo pipefail

HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"

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
    # 1. If modular UserConfigs exists (e.g. JaKooLit dotfiles)
    if [[ -d "$HYPR_DIR/UserConfigs" ]]; then
        if [[ "$is_decor" -eq 1 && -f "$HYPR_DIR/UserConfigs/UserDecorations.conf" ]]; then
            echo "$HYPR_DIR/UserConfigs/UserDecorations.conf"
            return
        elif [[ "$is_decor" -eq 0 && -f "$HYPR_DIR/UserConfigs/UserSettings.conf" ]]; then
            echo "$HYPR_DIR/UserConfigs/UserSettings.conf"
            return
        fi
    fi

    # 2. If custom_hypr.conf already exists, use it
    if [[ -f "$HYPR_DIR/custom_hypr.conf" ]]; then
        echo "$HYPR_DIR/custom_hypr.conf"
        return
    fi

    # 3. Vanilla Hyprland: hyprland.conf exists
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

    # 4. Fallback
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
        "snap_window_gap": 10
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

        # Check for source directives: source = <path>
        src_match = re.match(r"^source\s*=\s*(.*)", stripped)
        if src_match:
            sub_path = src_match.group(1).strip()
            # Expand $HOME, ~, $configs, $UserConfigs
            sub_path = sub_path.replace("$HOME", os.path.expanduser("~"))
            sub_path = sub_path.replace("~", os.path.expanduser("~"))
            sub_path = sub_path.replace("$configs", os.path.join(hypr_dir, "configs"))
            sub_path = sub_path.replace("$UserConfigs", os.path.join(hypr_dir, "UserConfigs"))
            if not os.path.isabs(sub_path):
                sub_path = os.path.join(base_dir, sub_path)
            parse_conf(sub_path)
            continue

        # Check block open: e.g. "general {", "shadow {", "blur {"
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
            v_lower = raw_v.lower()

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

            val = to_val(v_lower)
            block_scope = ".".join(current_block) if current_block else ""

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

# Parse from main hyprland.conf (which will recursively parse sourced files)
parse_conf(os.path.join(hypr_dir, "hyprland.conf"))
# Explicitly parse custom or user configs if not already sourced
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

print(json.dumps(data))
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

    detect_hypr_instance

    # 1. Apply live via hyprctl if available
    if command -v hyprctl >/dev/null 2>&1; then
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
    target_path="$(find_config_target "$is_decor")"

    # 3. Persist in config file with brace-counting AST parser
    python3 - "$target_path" "$target_section" "$target_key" "$target_val" << 'EOF'
import sys, os, re, json

target_path = sys.argv[1].strip()
section = sys.argv[2].strip()
key = sys.argv[3].strip()
val = sys.argv[4].strip()

if not os.path.exists(target_path):
    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    with open(target_path, "w", encoding="utf-8") as f:
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
    *)
        echo "Usage: $0 {get|set <section> <key> <value>}"
        exit 1
        ;;
esac
