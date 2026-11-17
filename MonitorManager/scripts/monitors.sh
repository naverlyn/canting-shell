#!/usr/bin/env bash
set -uo pipefail

subcmd="${1:-}"
shift || true

case "$subcmd" in
    check)
        if [ -f "$HOME/.config/hypr/hyprland.lua" ]; then
            echo lua
            grep -Eq 'require.*[Mm]onitors' "$HOME/.config/hypr/hyprland.lua" && echo yes || echo no
            if [ -f "$HOME/.config/hypr/Configs/Monitors.lua" ]; then
                echo "~/.config/hypr/Configs/Monitors.lua"
            else
                echo "~/.config/hypr/monitors.lua"
            fi
        else
            echo conf
            grep -Eq 'source.*[Mm]onitors\.conf' "$HOME/.config/hypr/hyprland.conf" 2>/dev/null && echo yes || echo no
            echo "~/.config/hypr/monitors.conf"
        fi
        ;;

    write)
        fmt="${1:-conf}"
        content="${2:-}"
        if [ "$fmt" = "lua" ]; then
            hypr_conf="$HOME/.config/hypr/hyprland.lua"
            target="$HOME/.config/hypr/monitors.lua"
            mod="monitors"
            if [ -f "$HOME/.config/hypr/Configs/Monitors.lua" ]; then
                target="$HOME/.config/hypr/Configs/Monitors.lua"
                mod="Configs.Monitors"
            fi
            printf '%s' "$content" > "$target" && \
            if [ -f "$hypr_conf" ] && ! grep -Eq 'require.*[Mm]onitors' "$hypr_conf"; then
                printf '\nrequire("%s")\n' "$mod" >> "$hypr_conf"
            fi
        else
            hypr_conf="$HOME/.config/hypr/hyprland.conf"
            target="$HOME/.config/hypr/monitors.conf"
            printf '%s' "$content" > "$target" && \
            if [ -f "$hypr_conf" ] && ! grep -Eq 'source.*[Mm]onitors\.conf' "$hypr_conf"; then
                printf '\nsource = ~/.config/hypr/monitors.conf\n' >> "$hypr_conf"
            fi
        fi
        ;;
esac
