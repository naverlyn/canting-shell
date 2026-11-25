#!/usr/bin/env bash
set -uo pipefail

subcmd="${1:-}"
shift || true

apply_eff() {
    local inP="$1" eff="$2" outP="$3"
    if [ -z "$eff" ] || [ "$eff" = "none" ] || ! command -v magick >/dev/null 2>&1; then
        printf "%s" "$inP"
        return 0
    fi
    mkdir -p "$HOME/.cache/quickshell/wallpaper_effects"
    run_magick() { nice -n 19 ionice -c 3 magick "$@"; }
    case "$eff" in
        negate)         run_magick "$inP" -negate "$outP" ;;
        bw)             run_magick "$inP" -colorspace gray -sigmoidal-contrast 10,40% "$outP" ;;
        blurred)        run_magick "$inP" -resize "2560x1440>" -blur 0x8 "$outP" ;;
        charcoal)       run_magick "$inP" -resize "2560x1440>" -charcoal 0x4 "$outP" ;;
        edge)           run_magick "$inP" -resize "2560x1440>" -edge 1 "$outP" ;;
        emboss)         run_magick "$inP" -resize "2560x1440>" -emboss 0x4 "$outP" ;;
        oil)            run_magick "$inP" -resize "2560x1440>" -paint 3 "$outP" ;;
        posterize)      run_magick "$inP" -posterize 4 "$outP" ;;
        sepia)          run_magick "$inP" -sepia-tone 65% "$outP" ;;
        solarize)       run_magick "$inP" -solarize 80% "$outP" ;;
        sharpen)        run_magick "$inP" -sharpen 0x4 "$outP" ;;
        vignette)       run_magick "$inP" -vignette 0x3 "$outP" ;;
        vignette_black) run_magick "$inP" -background black -vignette 0x3 "$outP" ;;
        zoomed)         run_magick "$inP" -gravity Center -extent 1:1 "$outP" ;;
        *)              printf "%s" "$inP"; return 0 ;;
    esac
    if [ -f "$outP" ]; then printf "%s" "$outP"; else printf "%s" "$inP"; fi
}

send_to_daemon() {
    local path="$1" target="$2" mode="$3" filter="$4"
    if command -v awww >/dev/null 2>&1; then
        if ! awww query >/dev/null 2>&1 && command -v awww-daemon >/dev/null 2>&1; then
            nohup awww-daemon --format xrgb >/dev/null 2>&1 &
            for _ in 1 2 3 4 5 6 7 8 9 10; do
                awww query >/dev/null 2>&1 && break
                sleep 0.1
            done
        fi
        local filterArg=()
        [ -n "$filter" ] && filterArg=(--filter "$filter")
        if [ -n "$target" ] && [ "$target" != "all" ]; then
            awww img "$path" -o "$target" --resize "$mode" "${filterArg[@]}" --transition-type grow --transition-pos center --transition-duration 1 || true
        else
            awww img "$path" --resize "$mode" "${filterArg[@]}" --transition-type grow --transition-pos center --transition-duration 1 || true
        fi
    elif command -v swww >/dev/null 2>&1; then
        if ! swww query >/dev/null 2>&1 && command -v swww-daemon >/dev/null 2>&1; then
            nohup swww-daemon >/dev/null 2>&1 &
            for _ in 1 2 3 4 5 6 7 8 9 10; do
                swww query >/dev/null 2>&1 && break
                sleep 0.1
            done
        fi
        local filterArg=()
        [ -n "$filter" ] && filterArg=(--filter "$filter")
        if [ -n "$target" ] && [ "$target" != "all" ]; then
            swww img "$path" -o "$target" --resize "$mode" "${filterArg[@]}" --transition-type grow --transition-pos center --transition-duration 1 || true
        else
            swww img "$path" --resize "$mode" "${filterArg[@]}" --transition-type grow --transition-pos center --transition-duration 1 || true
        fi
    elif command -v hyprpaper >/dev/null 2>&1 && command -v hyprctl >/dev/null 2>&1; then
        hyprctl hyprpaper preload "$path" 2>/dev/null || true
        if [ -n "$target" ] && [ "$target" != "all" ]; then
            hyprctl hyprpaper wallpaper "$target,$path" 2>/dev/null || true
        else
            hyprctl hyprpaper wallpaper ",$path" 2>/dev/null || true
        fi
        hyprctl hyprpaper unload unused 2>/dev/null || true
    fi
}

case "$subcmd" in
    browse)
        dir="${1:-}"
        cd "$dir" 2>/dev/null || exit 1
        img_count=$(find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | wc -l)
        echo "IMAGES:$img_count"
        for d in */; do
            [ -d "$d" ] || continue
            name="${d%/}"
            [ "$name" = "*" ] && continue
            case "$name" in .*) continue ;; esac
            printf "DIR:%s\n" "$name"
        done | sort -f
        ;;

    set)
        origPath="${1:-}" target="${2:-}" mode="${3:-crop}" filter="${4:-}" effect="${5:-none}" syncFlag="${6:-noSync}" setSh="${7:-}"
        export MAGICK_THREAD_LIMIT=2
        export OMP_NUM_THREADS=2
        pkill -f "^magick .*wallpaper_effects/wallpaper_modified" 2>/dev/null || true
        cacheDir="$HOME/.cache/quickshell/wallpaper_effects"
        mkdir -p "$cacheDir"
        safeTarget="$(printf '%s' "${target:-all}" | tr -cd 'a-zA-Z0-9_-')"
        path="$(apply_eff "$origPath" "$effect" "$cacheDir/wallpaper_modified_${safeTarget:-all}.png")"
        send_to_daemon "$path" "$target" "$mode" "$filter"
        if [ "$syncFlag" = "syncTheme" ] && [ -f "$setSh" ]; then
            env WALLPAPER_THEME_TOOL=wallust sh "$setSh" "$path" 2>/dev/null || true
        fi
        ;;

    reapply)
        mode="${1:-crop}" wallA="${2:-}" wallB="${3:-}" outA="${4:-}" outB="${5:-}" filter="${6:-}" effect="${7:-none}"
        export MAGICK_THREAD_LIMIT=2
        export OMP_NUM_THREADS=2
        pkill -f "^magick .*wallpaper_effects/wallpaper_modified" 2>/dev/null || true
        cacheDir="$HOME/.cache/quickshell/wallpaper_effects"
        mkdir -p "$cacheDir"
        effA="$(apply_eff "$wallA" "$effect" "$cacheDir/wallpaper_modified_A.png")"
        effB="$(apply_eff "$wallB" "$effect" "$cacheDir/wallpaper_modified_B.png")"
        if [ -n "$effB" ] && [ "$effB" != "$effA" ] && [ -n "$outA" ] && [ -n "$outB" ]; then
            send_to_daemon "$effA" "$outA" "$mode" "$filter"
            send_to_daemon "$effB" "$outB" "$mode" "$filter"
        elif [ -n "$effA" ]; then
            send_to_daemon "$effA" "${outA:-all}" "$mode" "$filter"
        fi
        ;;

    check-startup)
        wA="${1:-}"
        if command -v awww >/dev/null 2>&1; then
            q=$(awww query 2>/dev/null || true)
            if [ -n "$q" ] && printf '%s' "$q" | grep -Fq "$wA"; then echo 'ALREADY_SET'; exit 0; fi
        elif command -v swww >/dev/null 2>&1; then
            q=$(swww query 2>/dev/null || true)
            if [ -n "$q" ] && printf '%s' "$q" | grep -Fq "$wA"; then echo 'ALREADY_SET'; exit 0; fi
        fi
        echo 'NEED_APPLY'
        ;;
esac
