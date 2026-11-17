#!/usr/bin/env bash
set -uo pipefail

mode="${1:-full}"
swappy_flag="${2:-0}"
delay_arg="${3:-0}"

sleep 0.2

dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"
mkdir -p "$dir"
time_stamp="$(date "+%d-%b_%H-%M-%S")"
file="$dir/Screenshot_${time_stamp}_${RANDOM}.png"

if [ "$mode" = "region" ]; then
    geom="$(slurp 2>&1)" || exit 0
    if [ "$delay_arg" -gt 0 ] 2>/dev/null; then
        sleep "$delay_arg"
    fi
    err="$(grim -g "$geom" "$file" 2>&1)" || {
        notify-send -u critical -a "Screenshot" "Screenshot Failed" "$err"
        exit 1
    }
elif [ "$mode" = "window" ]; then
    geom="$(hyprctl activewindow -j 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); a=d.get('at',[0,0]); s=d.get('size',[0,0]); print(f'{a[0]},{a[1]} {s[0]}x{s[1]}') if s[0]>0 and s[1]>0 else sys.exit(1)" 2>/dev/null)" || geom=""
    if [ -n "$geom" ]; then
        err="$(grim -g "$geom" "$file" 2>&1)" || {
            notify-send -u critical -a "Screenshot" "Screenshot Failed" "$err"
            exit 1
        }
    else
        err="$(grim "$file" 2>&1)" || {
            notify-send -u critical -a "Screenshot" "Screenshot Failed" "$err"
            exit 1
        }
    fi
else
    err="$(grim "$file" 2>&1)" || {
        notify-send -u critical -a "Screenshot" "Screenshot Failed" "$err"
        exit 1
    }
fi

wl-copy --type image/png < "$file" >/dev/null 2>&1 &

if command -v canberra-gtk-play >/dev/null 2>&1; then
    canberra-gtk-play -i camera-shutter >/dev/null 2>&1 &
fi

notify_args=(-t 10000 -a "Screenshot" -A "action1=Open" -A "action2=Delete" -h "string:x-canonical-private-synchronous:shot-notify" -i "camera-photo")

if [ "$swappy_flag" = "1" ]; then
    resp="$(timeout 10 notify-send "${notify_args[@]}" "Screenshot" "Captured (Swappy)")" || resp=""
    case "$resp" in
        action1) swappy -f "$file" >/dev/null 2>&1 & ;;
        action2) rm -f "$file" ;;
    esac
else
    resp="$(timeout 10 notify-send "${notify_args[@]}" "Screenshot" "Saved to Screenshots")" || resp=""
    case "$resp" in
        action1) xdg-open "$file" >/dev/null 2>&1 & ;;
        action2) rm -f "$file" ;;
    esac
fi
