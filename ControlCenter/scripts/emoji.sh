#!/usr/bin/env bash
set -euo pipefail

if pgrep -x rofi >/dev/null 2>&1; then
    pkill -x rofi
    exit 0
fi

# Prefer rofi-emoji if installed
if rofi -dump-config 2>/dev/null | grep -q "emoji"; then
    exec rofi -modi emoji -show emoji -kb-custom-1 Ctrl+c
fi

# Fallback to rofi -show emoji directly (works when rofi-emoji plugin is available)
if rofi -modi emoji -show emoji -emoji-mode copy 2>/dev/null; then
    exit 0
fi

notify-send -u normal -a "Control Center" "Emoji Picker" "Install rofi-emoji to use the emoji picker." 2>/dev/null || true
exit 1
