#!/usr/bin/env bash
# /* ---- 💫 manage_touchpad.sh 💫 ---- */
# Manages touchpad state across Hyprland, JaKooLit dotfiles, and vanilla setups.

set -euo pipefail

get_status_file() {
    if [[ -n "${XDG_RUNTIME_DIR:-}" && -d "$XDG_RUNTIME_DIR" ]]; then
        echo "$XDG_RUNTIME_DIR/touchpad.status"
    else
        echo "/tmp/touchpad.status"
    fi
}

get_touchpad_device() {
    local dev=""
    for conf in "$HOME/.config/hypr/UserConfigs/Laptops.conf" "$HOME/.config/hypr/configs/Laptops.conf"; do
        if [[ -f "$conf" ]]; then
            dev="$(awk -F= '/^\$Touchpad_Device/ { gsub(/[[:space:]]*/, "", $1); gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit }' "$conf" 2>/dev/null || true)"
            if [[ -n "$dev" ]]; then
                echo "$dev"
                return 0
            fi
        fi
    done

    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        dev="$(hyprctl devices -j 2>/dev/null | jq -r '.mice[]? | select(.name | test("touchpad|trackpad|synaptics|elan"; "i")) | .name' 2>/dev/null | head -n1 || true)"
        if [[ -n "$dev" && "$dev" != "null" ]]; then
            echo "$dev"
            return 0
        fi
    fi
    echo ""
}

get_status() {
    local sf
    sf="$(get_status_file)"
    if [[ -f "$sf" ]]; then
        local content
        content="$(tr -d '\r\n' < "$sf")"
        echo "$content"
        return 0
    fi
    echo "true"
}

set_status() {
    local target="$1" # "true" or "false"
    local sf
    sf="$(get_status_file)"
    printf "%s\n" "$target" > "$sf"

    local dev
    dev="$(get_touchpad_device)"
    if [[ -n "$dev" ]]; then
        hyprctl keyword "device:${dev}:enabled" "$target" -r >/dev/null 2>&1 || true
    fi
    hyprctl keyword '$TOUCHPAD_ENABLED' "$target" >/dev/null 2>&1 || true
    echo "$target"
}

toggle_status() {
    local current
    current="$(get_status)"
    if [[ "$current" == "true" ]]; then
        set_status "false"
    else
        set_status "true"
    fi
}

case "${1:-status}" in
    status)
        get_status
        ;;
    set)
        set_status "${2:-true}"
        ;;
    toggle)
        toggle_status
        ;;
    device)
        get_touchpad_device
        ;;
    *)
        echo "Usage: $0 {status|set [true|false]|toggle|device}"
        exit 1
        ;;
esac

