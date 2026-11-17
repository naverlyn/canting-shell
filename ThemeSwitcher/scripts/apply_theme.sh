#!/usr/bin/env bash
set -uo pipefail

subcmd="${1:-}"
shift || true

case "$subcmd" in
    hyprlock)
        hyprlock_conf="${1:-}"
        [ -n "$hyprlock_conf" ] || exit 0
        mkdir -p "$HOME/.config/hypr/wallust"
        dest="$HOME/.config/quickshell/Settings/scripts/wallust-hyprlock.conf"
        printf '%s\n' "$hyprlock_conf" > "$dest"
        cp -f "$dest" "$HOME/.config/hypr/wallust/wallust-hyprland.conf" 2>/dev/null || true
        if [ -f "$HOME/.config/hypr/hyprlock.conf" ]; then
            sed -i 's|^source = .*/wallust/wallust-hyprland\.conf|source = $HOME/.config/quickshell/Settings/scripts/wallust-hyprlock.conf|' "$HOME/.config/hypr/hyprlock.conf" 2>/dev/null || true
        fi
        ;;

    borders)
        fmt="${1:-conf}"
        active1="${2:-}"
        active2="${3:-}"
        angle="${4:-45}"
        inactive="${5:-}"
        if grep -q "custom_border = true" "$HOME/.config/hypr/theme-borders.lua" "$HOME/.config/hypr/theme-borders.conf" 2>/dev/null; then
            exit 0
        fi
        active="${active1} ${active2} ${angle}deg"
        if [ "$fmt" = "lua" ]; then
            printf '%s\n' \
                '-- theme_sync = true' \
                'hl.config({' \
                '    general = {' \
                "        [\"col.active_border\"] = { colors = { \"${active1}\", \"${active2}\" }, angle = ${angle} }," \
                "        [\"col.inactive_border\"] = \"${inactive}\"," \
                '    },' \
                '})' > "$HOME/.config/hypr/theme-borders.lua"
            hyprctl eval 'dofile(os.getenv("HOME") .. "/.config/hypr/theme-borders.lua")' >/dev/null 2>&1 || true
            if [ -f "$HOME/.config/hypr/hyprland.lua" ] && ! grep -q "theme-borders" "$HOME/.config/hypr/hyprland.lua" 2>/dev/null; then
                printf '\npcall(require, "theme-borders")\n' >> "$HOME/.config/hypr/hyprland.lua"
            fi
        else
            printf '%s\n' \
                '# theme_sync = true' \
                'general {' \
                "    col.active_border = ${active}" \
                "    col.inactive_border = ${inactive}" \
                '}' > "$HOME/.config/hypr/theme-borders.conf"
            hyprctl keyword general:col.active_border "$active" >/dev/null 2>&1 || true
            hyprctl keyword general:col.inactive_border "$inactive" >/dev/null 2>&1 || true
            if [ -f "$HOME/.config/hypr/hyprland.conf" ] && ! grep -q "theme-borders" "$HOME/.config/hypr/hyprland.conf" 2>/dev/null; then
                printf '\nsource = ~/.config/hypr/theme-borders.conf\n' >> "$HOME/.config/hypr/hyprland.conf"
            fi
        fi
        ;;

    kitty)
        kitty_conf="${1:-}"
        kitty_args="${2:-}"
        [ -n "$kitty_conf" ] || exit 0
        mkdir -p "$HOME/.config/kitty"
        printf '%s\n' "$kitty_conf" > "$HOME/.config/kitty/theme-colors.conf"
        if [ -n "$kitty_args" ]; then
            for sock in /tmp/kitty-*; do
                # shellcheck disable=SC2086
                [ -S "$sock" ] && kitty @ --to "unix:$sock" set-colors --all --configured $kitty_args 2>/dev/null || true
            done
        fi
        ;;
esac
