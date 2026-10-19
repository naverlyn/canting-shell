#!/usr/bin/env bash
# /* ---- 💫 manage_hypridle.sh 💫 ---- */
# Manages hypridle.conf inactivity lock timeout for Quickshell Settings.
# 100% pure Bash + awk implementation matching JaKooLit dotfiles conventions.

set -euo pipefail

CONF="${HYPRIDLE_CONF:-$HOME/.config/hypr/hypridle.conf}"
ACTION="${1:-get}"
ARG="${2:-}"

get_timeout() {
    if [[ ! -f "$CONF" ]]; then
        printf '{"timeout_seconds": 600, "timeout_minutes": 10, "error": "file_not_found"}\n'
        return 0
    fi

    local sec
    sec=$(awk '
        /^[[:space:]]*listener[[:space:]]*\{/ { in_listener=1; cur_timeout=""; has_lock=0; next }
        in_listener && /^[[:space:]]*timeout[[:space:]]*=/ {
            match($0, /[0-9]+/)
            cur_timeout=substr($0, RSTART, RLENGTH)
        }
        in_listener && /loginctl[[:space:]]+lock-session/ { has_lock=1 }
        in_listener && /^[[:space:]]*\}/ {
            if (has_lock && cur_timeout != "") {
                print cur_timeout
                exit
            }
            in_listener=0
        }
    ' "$CONF")

    if [[ -z "$sec" ]]; then
        sec=600
    fi

    local mins=$(( sec / 60 ))
    printf '{"timeout_seconds": %d, "timeout_minutes": %d}\n' "$sec" "$mins"
}

set_timeout() {
    local mins="$ARG"
    if [[ -z "$mins" || ! "$mins" =~ ^[0-9]+$ || "$mins" -le 0 ]]; then
        printf '{"success": false, "error": "invalid_minutes"}\n'
        exit 1
    fi

    if [[ ! -f "$CONF" ]]; then
        printf '{"success": false, "error": "file_not_found"}\n'
        exit 1
    fi

    local new_sec=$(( mins * 60 ))
    local warn_sec
    if (( new_sec > 60 )); then
        warn_sec=$(( new_sec - 60 ))
    else
        warn_sec=$(( new_sec - 10 ))
        (( warn_sec < 5 )) && warn_sec=5
    fi

    local tmp
    tmp=$(mktemp)

    awk -v new_sec="$new_sec" -v warn_sec="$warn_sec" '
        /^[[:space:]]*listener[[:space:]]*\{/ {
            in_listener=1
            block=$0 "\n"
            is_warn=0
            is_lock=0
            next
        }
        in_listener {
            block = block $0 "\n"
            if (/You are idle!/) is_warn=1
            if (/loginctl[[:space:]]+lock-session/) is_lock=1
            if (/^[[:space:]]*\}/) {
                in_listener=0
                if (is_warn) {
                    gsub(/timeout[[:space:]]*=[[:space:]]*[0-9]+/, "timeout = " warn_sec, block)
                } else if (is_lock) {
                    gsub(/timeout[[:space:]]*=[[:space:]]*[0-9]+/, "timeout = " new_sec, block)
                }
                printf "%s", block
                next
            }
            next
        }
        { print }
    ' "$CONF" > "$tmp"

    cat "$tmp" > "$CONF"
    rm -f "$tmp"

    # Restart hypridle if currently running
    if pgrep -x hypridle >/dev/null 2>&1; then
        pkill -x hypridle || true
        sleep 0.1
        hypridle >/dev/null 2>&1 &
        disown || true
    fi

    printf '{"success": true, "timeout_seconds": %d, "timeout_minutes": %d}\n' "$new_sec" "$mins"
}

case "$ACTION" in
    get)
        get_timeout
        ;;
    set)
        set_timeout
        ;;
    *)
        printf '{"error": "unknown_action", "action": "%s"}\n' "$ACTION"
        exit 1
        ;;
esac
