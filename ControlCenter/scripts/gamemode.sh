#!/usr/bin/env bash
set -euo pipefail

state=$(hyprctl getoption animations:enabled 2>/dev/null | awk 'NR==1{print $2}' || echo "1")

if [ "$state" = "1" ]; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0" >/dev/null 2>&1
    notify-send -u low -a "Control Center" "Game Mode" "Enabled (animations & blur off)" 2>/dev/null || true
else
    hyprctl reload >/dev/null 2>&1
    notify-send -u low -a "Control Center" "Game Mode" "Disabled (animations restored)" 2>/dev/null || true
fi
