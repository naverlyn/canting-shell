#!/usr/bin/env bash
# /* ---- 💫 manage_animations.sh 💫 ---- */
# Manages Hyprland animations, presets, bezier curves, and toggle state for Quickshell Settings.
# Fully portable across Vanilla Hyprland and modular dotfiles.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR
BUNDLED_DIR="$(cd "$SCRIPT_DIR/../presets/animations" 2>/dev/null && pwd || echo "$SCRIPT_DIR/../presets/animations")"
export BUNDLED_DIR
BACKUP_DIR="$(cd "$SCRIPT_DIR/../backups" 2>/dev/null && pwd || echo "$SCRIPT_DIR/../backups")"
export BACKUP_DIR
ANIM_DIR="$HOME/.config/hypr/animations"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

find_user_conf() {
    if [[ -f "$HOME/.config/hypr/UserConfigs/UserAnimations.conf" ]]; then
        echo "$HOME/.config/hypr/UserConfigs/UserAnimations.conf"
        return
    fi
    if [[ -f "$HOME/.config/hypr/animations.conf" ]]; then
        echo "$HOME/.config/hypr/animations.conf"
        return
    fi
    if [[ -f "$HOME/.config/hypr/custom_animations.conf" ]]; then
        echo "$HOME/.config/hypr/custom_animations.conf"
        return
    fi
    if [[ -d "$HOME/.config/hypr/UserConfigs" ]]; then
        echo "$HOME/.config/hypr/UserConfigs/UserAnimations.conf"
        return
    fi
    echo "$HOME/.config/hypr/animations.conf"
}

ensure_dirs() {
    mkdir -p "$BACKUP_DIR"
    local uconf
    uconf="$(find_user_conf)"
    mkdir -p "$(dirname "$uconf")"
    if [[ ! -d "$ANIM_DIR" || -z "$(ls -A "$ANIM_DIR" 2>/dev/null)" ]]; then
        mkdir -p "$ANIM_DIR"
        if [[ -d "$BUNDLED_DIR" ]]; then
            cp -n "$BUNDLED_DIR"/*.conf "$ANIM_DIR/" 2>/dev/null || true
        fi
    fi
    if [[ ! -f "$uconf" ]]; then
        if [[ -f "$ANIM_DIR/00-default.conf" ]]; then
            cp -p "$ANIM_DIR/00-default.conf" "$uconf"
        elif [[ -f "$BUNDLED_DIR/00-default.conf" ]]; then
            cp -p "$BUNDLED_DIR/00-default.conf" "$uconf"
        fi
    fi
}

get_status() {
    ensure_dirs
    python3 - << 'EOF'
import os, glob, json, re

anim_dir = os.path.expanduser('~/.config/hypr/animations')
bundled_dir = os.environ.get('BUNDLED_DIR') or os.path.expanduser('~/.config/quickshell/Settings/presets/animations')
backup_dir = os.environ.get('BACKUP_DIR') or os.path.expanduser('~/.config/quickshell/Settings/backups')

user_conf_candidates = [
    os.path.expanduser('~/.config/hypr/UserConfigs/UserAnimations.conf'),
    os.path.expanduser('~/.config/hypr/animations.conf'),
    os.path.expanduser('~/.config/hypr/custom_animations.conf')
]
user_conf = None
for uc in user_conf_candidates:
    if os.path.exists(uc):
        user_conf = uc
        break
if not user_conf:
    user_conf = user_conf_candidates[0] if os.path.isdir(os.path.expanduser('~/.config/hypr/UserConfigs')) else user_conf_candidates[1]

user_content = ""
if user_conf and os.path.exists(user_conf):
    with open(user_conf, 'r', encoding='utf-8', errors='ignore') as f:
        user_content = f.read()

# Check enabled state from state files first (since user explicitly toggled it), then user_conf
enabled_state_file = os.path.expanduser('~/.config/hypr/UserConfigs/.animations_enabled')
local_state_file = os.path.join(backup_dir, '.animations_enabled')

is_enabled = None
for sf in [local_state_file, enabled_state_file]:
    if os.path.exists(sf):
        try:
            with open(sf, 'r', encoding='utf-8') as ef:
                st = ef.read().strip().lower()
                if st in ('true', '1', 'yes'):
                    is_enabled = True
                    break
                elif st in ('false', '0', 'no'):
                    is_enabled = False
                    break
        except Exception:
            pass

if is_enabled is None:
    enabled_match = re.search(r'^\s*enabled\s*=\s*(yes|true|1|no|false|0)', user_content, re.MULTILINE | re.IGNORECASE)
    if enabled_match:
        val = enabled_match.group(1).lower()
        is_enabled = val in ('yes', 'true', '1')
    else:
        is_enabled = True

def parse_preset_info(content, filename):
    base = os.path.splitext(filename)[0]
    
    # Family detection
    family = "Standard"
    if " - " in base:
        fam_prefix = base.split(" - ")[0].strip()
        family = fam_prefix
    elif base.startswith("00") or base.startswith("01") or base.startswith("03"):
        family = "Standard"
    elif "END" in base:
        family = "END"
    elif "Mahaveer" in base:
        family = "Mahaveer"
    else:
        family = "Custom"

    # Display name
    display_name = base
    if " - " in base:
        parts = base.split(" - ")
        display_name = parts[1].strip()
        if parts[0].strip() not in ("HYDE", "ML4W", "Mahaveer", "Custom"):
            display_name = base
    elif base == "00-default":
        display_name = "Default Classic"
    elif base == "01-default - v2":
        display_name = "Default v2"

    # Extract beziers
    beziers = []
    for m in re.finditer(r'^\s*bezier\s*=\s*([^,]+),\s*(.+)$', content, re.MULTILINE):
        beziers.append({"name": m.group(1).strip(), "curve": m.group(2).strip()})

    # Extract animations
    anims = []
    for m in re.finditer(r'^\s*animation\s*=\s*([^,]+),\s*(\d+),\s*([0-9.]+),\s*([^,\n\r]+)(?:,\s*([^\n\r#]+))?', content, re.MULTILINE):
        anims.append({
            "target": m.group(1).strip(),
            "enabled": bool(int(m.group(2))),
            "speed": float(m.group(3)),
            "curve": m.group(4).strip(),
            "style": (m.group(5) or "").strip()
        })

    # Description synthesis
    desc = f"{len(beziers)} bezier curves, {len(anims)} rules"
    if family == "Custom":
        desc = "User-created custom animation profile"
    elif "disable" in base.lower():
        desc = "Disables all compositor animations for instant response"
    elif "fast" in base.lower():
        desc = "Snappy, high-acceleration curves with reduced latency"
    elif "minimal" in base.lower():
        desc = "Lightweight, subtle transitions for minimal distraction"
    elif "vertical" in base.lower():
        desc = "Vertical workspace transitions with fluid momentum"
    elif "moving" in base.lower():
        desc = "Dynamic window and workspace motion with overshooting"
    elif "classic" in base.lower():
        desc = "Smooth cubic ease-out curves with balanced timing"
    elif "optimized" in base.lower():
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
        "animations": anims
    }

state_file = os.path.join(backup_dir, '.current_animation')
if not os.path.exists(state_file):
    state_file = os.path.expanduser('~/.config/hypr/UserConfigs/.current_animation')
saved_preset = ""
if os.path.exists(state_file):
    try:
        with open(state_file, 'r', encoding='utf-8') as sf:
            saved_preset = sf.read().strip()
    except Exception:
        pass

presets = []
candidates_exact = []
candidates_normalized = []

user_clean = re.sub(r'#.*', '', user_content).strip()

seen = set()
all_conf_paths = []
for d in [anim_dir, bundled_dir]:
    if os.path.isdir(d):
        for p in sorted(glob.glob(f'{d}/*.conf')):
            fn = os.path.basename(p)
            if fn not in seen:
                seen.add(fn)
                all_conf_paths.append(p)

for p in all_conf_paths:
    fn = os.path.basename(p)
    try:
        with open(p, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception:
        continue

    info = parse_preset_info(content, fn)
    preset_clean = re.sub(r'#.*', '', content).strip()
    
    if user_content.strip() == content.strip():
        candidates_exact.append(info["id"])
    elif len(user_clean) > 0 and user_clean == preset_clean:
        candidates_normalized.append(info["id"])

    info["active"] = False
    presets.append(info)

# Select the single unique active preset
active_preset_id = ""
if saved_preset and (saved_preset in candidates_exact or saved_preset in candidates_normalized):
    active_preset_id = saved_preset
elif candidates_exact:
    active_preset_id = candidates_exact[0]
elif candidates_normalized:
    active_preset_id = candidates_normalized[0]

if active_preset_id:
    for item in presets:
        if item["id"] == active_preset_id:
            item["active"] = True
            break

# Parse current user beziers & rules
current_info = parse_preset_info(user_content, "current")

output = {
    "enabled": is_enabled,
    "currentPreset": active_preset_id or "Custom",
    "presets": presets,
    "activeBeziers": current_info["beziers"],
    "activeRules": current_info["animations"]
}

print(json.dumps(output))
EOF
}

set_enabled() {
    local target="${1:-true}" # true or false
    ensure_dirs

    if [[ "$target" == "true" ]]; then
        local kw="yes"
        local hypr_val="1"
    else
        local kw="no"
        local hypr_val="0"
    fi

    # Save to state files safely
    local local_state_file="$BACKUP_DIR/.animations_enabled"
    python3 -c "import sys; p, v = sys.argv[1], sys.argv[2]; open(p, 'w').write(v)" "$local_state_file" "$target" 2>/dev/null || true
    if [[ -d "$HOME/.config/hypr/UserConfigs" ]]; then
        python3 -c "import sys; p, v = sys.argv[1], sys.argv[2]; open(p, 'w').write(v)" "$HOME/.config/hypr/UserConfigs/.animations_enabled" "$target" 2>/dev/null || true
    fi

    local user_conf
    user_conf="$(find_user_conf)"
    local conf_name
    conf_name="$(basename "$user_conf")"

    # Backup current user config
    if [[ -f "$user_conf" ]]; then
        cp -p "$user_conf" "$BACKUP_DIR/${conf_name}.pre_toggle" 2>/dev/null || true
    fi

    # Update animation config using Python for 100% reliable AST/regex handling
    if [[ -f "$user_conf" ]]; then
        python3 - "$user_conf" "$kw" << 'PYEOF'
import sys, re

path = sys.argv[1]
kw = sys.argv[2]

try:
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    if re.search(r'^\s*enabled\s*=', content, re.MULTILINE):
        new_content = re.sub(r'^\s*enabled\s*=.*', f'  enabled = {kw}', content, flags=re.MULTILINE)
    elif re.search(r'animations\s*\{', content):
        new_content = re.sub(r'animations\s*\{', f'animations {{\n  enabled = {kw}', content, count=1)
    else:
        new_content = f"animations {{\n  enabled = {kw}\n\n" + content + "\n}\n"

    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
except Exception:
    pass
PYEOF
    fi

    # Apply live to Hyprland
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl keyword animations:enabled "$hypr_val" >/dev/null 2>&1 || true
        hyprctl reload >/dev/null 2>&1 || true
    fi

    echo "{\"success\":true,\"enabled\":$target}"
}

apply_preset() {
    local preset_name="${1:-}"
    if [[ -z "$preset_name" ]]; then
        echo "{\"success\":false,\"error\":\"No preset specified\"}"
        exit 1
    fi

    local target_file="$ANIM_DIR/$preset_name.conf"
    if [[ ! -f "$target_file" ]]; then
        target_file="$ANIM_DIR/$preset_name"
    fi
    if [[ ! -f "$target_file" && -f "$BUNDLED_DIR/$preset_name.conf" ]]; then
        target_file="$BUNDLED_DIR/$preset_name.conf"
    fi
    if [[ ! -f "$target_file" && -f "$BUNDLED_DIR/$preset_name" ]]; then
        target_file="$BUNDLED_DIR/$preset_name"
    fi

    if [[ ! -f "$target_file" ]]; then
        echo "{\"success\":false,\"error\":\"Preset file not found: $preset_name\"}"
        exit 1
    fi

    ensure_dirs

    local user_conf
    user_conf="$(find_user_conf)"
    local conf_name
    conf_name="$(basename "$user_conf")"

    # Backup current user config
    if [[ -f "$user_conf" ]]; then
        cp -p "$user_conf" "$BACKUP_DIR/${conf_name}.pre_preset" 2>/dev/null || true
    fi

    # Copy preset into user_conf
    cp -f "$target_file" "$user_conf" 2>/dev/null || true
    echo -n "$preset_name" > "$BACKUP_DIR/.current_animation" 2>/dev/null || true
    if [[ -d "$HOME/.config/hypr/UserConfigs" ]]; then
        echo -n "$preset_name" > "$HOME/.config/hypr/UserConfigs/.current_animation" 2>/dev/null || true
        python3 -c "import sys; p=sys.argv[1]; open(p, 'w').write('true')" "$HOME/.config/hypr/UserConfigs/.animations_enabled" 2>/dev/null || true
    fi
    python3 -c "import sys; p=sys.argv[1]; open(p, 'w').write('true')" "$BACKUP_DIR/.animations_enabled" 2>/dev/null || true

    # Ensure source line is present in hyprland.conf on vanilla installations
    if [[ -f "$HYPR_CONF" ]] && ! grep -q "$conf_name" "$HYPR_CONF" 2>/dev/null; then
        echo "" >> "$HYPR_CONF"
        if [[ "$user_conf" == *"/UserConfigs/"* ]]; then
            echo "source = ~/.config/hypr/UserConfigs/$conf_name" >> "$HYPR_CONF"
        else
            echo "source = ~/.config/hypr/$conf_name" >> "$HYPR_CONF"
        fi
    fi

    # Also apply beziers and animation rules directly via hyprctl keyword
    # so vanilla setups immediately experience the animation profile without needing a full restart
    if command -v hyprctl >/dev/null 2>&1; then
        while IFS= read -r line; do
            local trimmed
            trimmed="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            if [[ "$trimmed" =~ ^bezier[[:space:]]*=[[:space:]]*(.*) ]]; then
                hyprctl keyword bezier "${BASH_REMATCH[1]}" >/dev/null 2>&1 || true
            elif [[ "$trimmed" =~ ^animation[[:space:]]*=[[:space:]]*(.*) ]]; then
                hyprctl keyword animation "${BASH_REMATCH[1]}" >/dev/null 2>&1 || true
            fi
        done < "$target_file"
        hyprctl reload >/dev/null 2>&1 || true
    fi

    # Optional refresh script from JaKooLit
    if [[ -x "$HOME/.config/hypr/scripts/RefreshNoWaybar.sh" ]]; then
        "$HOME/.config/hypr/scripts/RefreshNoWaybar.sh" >/dev/null 2>&1 || true
    fi

    echo "{\"success\":true,\"preset\":\"$preset_name\"}"
}

save_custom() {
    local payload="${1:-}"
    if [[ -z "$payload" ]]; then
        echo "{\"success\":false,\"error\":\"No configuration payload provided\"}"
        exit 1
    fi

    ensure_dirs

    local preset_id
    preset_id="$(python3 - "$payload" << 'EOF'
import sys, json, os, re

try:
    data = json.loads(sys.argv[1])
except Exception:
    sys.exit(1)

raw_name = data.get("name", "").strip() or "My Animation"
safe_name = re.sub(r'[^a-zA-Z0-9_\- ]', '', raw_name).strip() or "My Animation"
preset_id = f"Custom - {safe_name}"
filename = f"{preset_id}.conf"

# Process beziers
beziers = data.get("beziers", [])
if not beziers or not isinstance(beziers, list):
    cn = data.get("curveName", "customEase").strip() or "customEase"
    cp = data.get("curvePoints", "0.05, 0.9, 0.1, 1.05").strip() or "0.05, 0.9, 0.1, 1.05"
    beziers = [{"name": cn, "curve": cp}]

# Process rules
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
        {"target": "workspaces", "enabled": True, "speed": ws_speed, "curve": primary_curve, "style": ws_style}
    ]

# Construct config
lines = [
    "# Custom Hyprland Animation Preset",
    f"# Profile Name: {safe_name}",
    "# Generated via Quickshell Settings",
    "",
    "animations {",
    "  enabled = yes",
    ""
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
    spd = float(r.get("speed", 4.0))
    crv = r.get("curve", beziers[0].get("name", "default")).strip()
    style = r.get("style", "").strip()
    if style:
        lines.append(f"  animation = {target}, {en}, {spd}, {crv}, {style}")
    else:
        lines.append(f"  animation = {target}, {en}, {spd}, {crv}")

lines.append("}")
lines.append("")

content = "\n".join(lines)

anim_dir = os.path.expanduser('~/.config/hypr/animations')
bundled_dir = os.environ.get('BUNDLED_DIR') or os.path.expanduser('~/.config/quickshell/Settings/presets/animations')
os.makedirs(anim_dir, exist_ok=True)
os.makedirs(bundled_dir, exist_ok=True)

try:
    with open(os.path.join(anim_dir, filename), 'w', encoding='utf-8') as f:
        f.write(content)
except Exception:
    pass

try:
    with open(os.path.join(bundled_dir, filename), 'w', encoding='utf-8') as f:
        f.write(content)
except Exception:
    pass

print(preset_id)
EOF
)"

    if [[ -z "$preset_id" ]]; then
        echo "{\"success\":false,\"error\":\"Failed to create animation configuration\"}"
        exit 1
    fi

    # Automatically activate this newly created preset
    apply_preset "$preset_id" >/dev/null 2>&1 || true

    echo "{\"success\":true,\"preset\":\"$preset_id\"}"
}

delete_custom() {
    local preset_name="${1:-}"
    if [[ -z "$preset_name" ]]; then
        echo "{\"success\":false,\"error\":\"No preset specified\"}"
        exit 1
    fi

    if [[ "$preset_name" != Custom\ -* ]]; then
        echo "{\"success\":false,\"error\":\"Only custom animations can be deleted\"}"
        exit 1
    fi

    local target_file="$ANIM_DIR/$preset_name.conf"
    local bundled_file="$BUNDLED_DIR/$preset_name.conf"

    rm -f "$target_file" 2>/dev/null || true
    rm -f "$bundled_file" 2>/dev/null || true

    # If this was active, switch back to 00-default
    local state_file="$BACKUP_DIR/.current_animation"
    if [[ -f "$state_file" ]] && [[ "$(cat "$state_file" 2>/dev/null)" == "$preset_name" ]]; then
        apply_preset "00-default" >/dev/null 2>&1 || true
    fi

    echo "{\"success\":true,\"deleted\":\"$preset_name\"}"
}

test_animation() {
    local payload="${1:-}"
    if [[ -n "$payload" ]]; then
        python3 - "$payload" << 'EOF' 2>/dev/null || true
import sys, json, os

try:
    data = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)

for b in data.get("beziers", []):
    n = b.get("name", "").strip()
    c = b.get("curve", "").strip()
    if n and c:
        os.system(f"hyprctl keyword bezier '{n}, {c}' >/dev/null 2>&1")

for r in data.get("rules", []):
    target = r.get("target", "").strip()
    if not target:
        continue
    en = 1 if r.get("enabled", True) else 0
    spd = float(r.get("speed", 4.0))
    crv = r.get("curve", "default").strip()
    style = r.get("style", "").strip()
    if style:
        os.system(f"hyprctl keyword animation '{target}, {en}, {spd}, {crv}, {style}' >/dev/null 2>&1")
    else:
        os.system(f"hyprctl keyword animation '{target}, {en}, {spd}, {crv}' >/dev/null 2>&1")
EOF
    fi

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u low -t 2500 -a "Quickshell Settings" "Animation Test" "Hyprland animations updated! Observe popup and window motion."
    fi
    echo "{\"success\":true}"
}

case "${1:-status}" in
    get|status)
        get_status
        ;;
    set_enabled)
        set_enabled "${2:-true}"
        ;;
    apply_preset)
        apply_preset "${2:-}"
        ;;
    save_custom)
        save_custom "${2:-}"
        ;;
    delete_custom)
        delete_custom "${2:-}"
        ;;
    test)
        test_animation "${2:-}"
        ;;
    *)
        echo "Usage: $0 {get|status|set_enabled [true|false]|apply_preset <name>|save_custom <json>|delete_custom <name>|test [json]}"
        exit 1
        ;;
esac
