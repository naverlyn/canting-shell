#!/usr/bin/env bash
#
# manage_keybind.sh
#
# Manages Hyprland keybindings live via IPC and persists overrides
# to UserKeybinds.conf (Jakoolit) or custom_keybinds.conf (Vanilla).
#

set -e

ACTION="$1"

find_config_target() {
    if [ -f "$HOME/.config/hypr/UserConfigs/UserKeybinds.conf" ]; then
        echo "$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
        return
    fi

    if [ -f "$HOME/.config/hypr/custom_keybinds.conf" ]; then
        echo "$HOME/.config/hypr/custom_keybinds.conf"
        return
    fi

    if [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
        local custom_file="$HOME/.config/hypr/custom_keybinds.conf"
        if [ ! -f "$custom_file" ]; then
            cat << 'EOF' > "$custom_file"
# Custom Keybindings managed by Quickshell Settings
EOF
        fi

        if ! grep -q "custom_keybinds.conf" "$HOME/.config/hypr/hyprland.conf" 2>/dev/null; then
            echo "" >> "$HOME/.config/hypr/hyprland.conf"
            echo "source = ~/.config/hypr/custom_keybinds.conf" >> "$HOME/.config/hypr/hyprland.conf"
        fi

        echo "$custom_file"
        return
    fi

    echo "$HOME/.config/hypr/custom_keybinds.conf"
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

elif [ "$ACTION" = "delete" ] || [ "$ACTION" = "unbind" ]; then
    MODS="$2"
    KEY="$3"
    DISPATCHER="$4"
    ARG="$5"

    BIND=$(format_bind "$MODS" "$KEY")

    # 1. Unbind in running Hyprland socket (multiple passes to clear duplicates)
    for _ in 1 2 3; do
        hyprctl keyword unbind "$BIND" 2>/dev/null || true
    done

    # 2. Persist to config target
    CONFIG_TARGET=$(find_config_target)
    if [ -n "$CONFIG_TARGET" ] && [ -f "$CONFIG_TARGET" ]; then
        TAG=$(sanitize_tag "$DISPATCHER" "$ARG" "$BIND")
        LEGACY_TAG=$(sanitize_tag "$DISPATCHER" "$ARG")

        python3 - << EOF
import re

target = "$CONFIG_TARGET"
tag = "$TAG"
legacy_tag = "$LEGACY_TAG"
arg = """$ARG"""
bind_str = "$BIND"

try:
    with open(target, "r") as f:
        content = f.read()

    # Remove any existing block for this tag, legacy tag, or arg
    for t in [tag, legacy_tag]:
        if t:
            content = re.sub(rf"\n*# <{t}>.*?# </{t}>\n*", "\n", content, flags=re.DOTALL)
    if arg:
        content = re.sub(rf"\n*# <qs_.*?>.*?{re.escape(arg)}.*?# </qs_.*?>\n*", "\n", content, flags=re.DOTALL)

    # Append unbind directive so it stays unbound on compositor reload
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

    # 1. Unbind old in running Hyprland socket
    for _ in 1 2 3; do
        hyprctl keyword unbind "$OLD_BIND" 2>/dev/null || true
    done

    # 2. Bind new in running Hyprland socket
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

    # 3. Persist to config target
    CONFIG_TARGET=$(find_config_target)
    if [ -n "$CONFIG_TARGET" ] && [ -f "$CONFIG_TARGET" ]; then
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
arg = """$ARG"""
old_arg = """$OLD_ARG"""
old_bind = "$OLD_BIND"
new_bind = "$NEW_BIND"
disp = "$DISPATCHER"

try:
    with open(target, "r") as f:
        content = f.read()

    # Remove any existing block for this tag, old_tag, legacy tags, old_arg, or arg
    for t in [tag, old_tag, legacy_tag, legacy_old_tag]:
        if t:
            content = re.sub(rf"\n*# <{t}>.*?# </{t}>\n*", "\n", content, flags=re.DOTALL)
    if old_arg:
        content = re.sub(rf"\n*# <qs_.*?>.*?{re.escape(old_arg)}.*?# </qs_.*?>\n*", "\n", content, flags=re.DOTALL)
    if arg:
        content = re.sub(rf"\n*# <qs_.*?>.*?{re.escape(arg)}.*?# </qs_.*?>\n*", "\n", content, flags=re.DOTALL)

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

    # 1. Bind live in running Hyprland socket
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

    # 2. Persist to config target
    CONFIG_TARGET=$(find_config_target)
    if [ -n "$CONFIG_TARGET" ] && [ -f "$CONFIG_TARGET" ]; then
        TAG=$(sanitize_tag "$DISPATCHER" "$ARG" "$BIND")
        LEGACY_TAG=$(sanitize_tag "$DISPATCHER" "$ARG")

        python3 - << EOF
import re

target = "$CONFIG_TARGET"
tag = "$TAG"
legacy_tag = "$LEGACY_TAG"
arg = """$ARG"""
bind_str = "$BIND"
disp = "$DISPATCHER"

try:
    with open(target, "r") as f:
        content = f.read()

    for t in [tag, legacy_tag]:
        if t:
            content = re.sub(rf"\n*# <{t}>.*?# </{t}>\n*", "\n", content, flags=re.DOTALL)

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
