#!/usr/bin/env bash
# ControlCenter Night Light helper (supports hyprsunset, wlsunset, gammastep)

is_running() {
    pgrep -x hyprsunset >/dev/null 2>&1 || pgrep -x wlsunset >/dev/null 2>&1 || pgrep -x gammastep >/dev/null 2>&1
}

has_tool() {
    command -v hyprsunset >/dev/null 2>&1 || command -v wlsunset >/dev/null 2>&1 || command -v gammastep >/dev/null 2>&1
}

kill_all() {
    pkill -x hyprsunset 2>/dev/null
    pkill -x wlsunset 2>/dev/null
    pkill -x gammastep 2>/dev/null
}

start_tool() {
    local temp="${1:-4500}"
    if command -v hyprsunset >/dev/null 2>&1; then
        hyprsunset -t "$temp" >/dev/null 2>&1 &
        return 0
    elif command -v wlsunset >/dev/null 2>&1; then
        wlsunset -t "$temp" >/dev/null 2>&1 &
        return 0
    elif command -v gammastep >/dev/null 2>&1; then
        gammastep -O "$temp" >/dev/null 2>&1 &
        return 0
    fi
    return 1
}

ACTION="${1:-status}"
TEMP="${2:-4500}"

case "$ACTION" in
    status)
        if is_running; then
            echo "on"
        elif has_tool; then
            echo "off"
        else
            echo "missing"
        fi
        ;;
    toggle)
        if is_running; then
            kill_all
            echo "off"
        else
            if start_tool "$TEMP"; then
                echo "on"
            else
                if command -v notify-send >/dev/null 2>&1; then
                    notify-send "Night Light" "hyprsunset is not installed. Run: sudo pacman -S hyprsunset" -i display-brightness-symbolic 2>/dev/null &
                fi
                echo "missing"
            fi
        fi
        ;;
    on|set)
        kill_all
        if start_tool "$TEMP"; then
            echo "on"
        else
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "Night Light" "hyprsunset is not installed. Run: sudo pacman -S hyprsunset" -i display-brightness-symbolic 2>/dev/null &
            fi
            echo "missing"
        fi
        ;;
    off)
        kill_all
        echo "off"
        ;;
    *)
        echo "Usage: $0 [status|toggle|on|off|set] [temperature]"
        ;;
esac
