#!/usr/bin/env bash
# /* ---- 💫 manage_hyprlock.sh 💫 ---- */
# Manages hyprlock.conf settings for Quickshell Settings App.
# 100% pure Bash + awk + jq implementation matching JaKooLit dotfiles conventions.
# Supports live configuration query, update, modular text/command building blocks, custom wallpaper generation, restore, and test.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_PATH="${CONF_PATH:-${HYPRLOCK_CONF:-$HOME/.config/hypr/hyprlock.conf}}"
BACKUP_DIR="$(cd "$SCRIPT_DIR/../backups" 2>/dev/null && pwd || echo "$SCRIPT_DIR/../backups")"
BACKUP_FILE="$BACKUP_DIR/hyprlock.conf.bak"
WALLPAPER_CURRENT="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
QUICKSHELL_WALLPAPER_CONF="$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd)/wallpaper.conf"

ensure_hyprlock_conf() {
    if [[ ! -f "$CONF_PATH" ]]; then
        mkdir -p "$(dirname "$CONF_PATH")"
        cat << 'EOF' > "$CONF_PATH"
# Hyprlock configuration managed by Quickshell

general {
    grace = 0
    disable_loading_bar = true
    immediate_render = true
}

background {
    monitor =
    path = screenshot
    blur_passes = 2
    blur_size = 6
    contrast = 1.0
    brightness = 0.8
    vibrancy = 0.2
}

input-field {
    monitor =
    size = 250, 50
    outline_thickness = 2
    dots_size = 0.2
    dots_spacing = 0.2
    dots_center = true
    fade_on_empty = false
    placeholder_text = <i>Input Password...</i>
    hide_input = false
    position = 0, -50
    halign = center
    valign = center
}

# [Block: Clock]
label {
    monitor =
    text = cmd[update:1000] echo "$TIME"
    color = rgba(240, 240, 240, 0.95)
    font_size = 80
    font_family = Hack Nerd Font
    position = 0, 100
    halign = center
    valign = center
}
EOF
    fi
}

ensure_hyprlock_wallust_config() {
    local toml="$SCRIPT_DIR/wallust-hyprlock.toml"
    if [[ ! -f "$toml" ]]; then
        cat << 'EOF' > "$toml"
# Wallust isolated configuration for Hyprlock
# Generates color palette ONLY for hyprlock without touching desktop theme, quickshell, waybar, rofi, etc.

backend = "kmeans"
color_space = "labmixed"
palette = "dark16"
threshold = 11

[templates]
hyprlock.template = 'colors-hyprland.conf'
hyprlock.target = '~/.config/quickshell/Settings/scripts/wallust-hyprlock.conf'
EOF
    fi

    ensure_hyprlock_source
}

ensure_hyprlock_source() {
    local target_source="source = $SCRIPT_DIR/wallust-hyprlock.conf"
    if [[ -f "$CONF_PATH" ]] && ! grep -q "wallust-hyprlock.conf" "$CONF_PATH" 2>/dev/null; then
        sed -i 's|^source = .*/wallust/wallust-hyprland.conf|'"$target_source"'|' "$CONF_PATH" || true
    fi

    if [[ ! -f "$SCRIPT_DIR/wallust-hyprlock.conf" ]]; then
        if [[ -f "$HOME/.config/hypr/wallust/wallust-hyprland.conf" ]]; then
            cp -f "$HOME/.config/hypr/wallust/wallust-hyprland.conf" "$SCRIPT_DIR/wallust-hyprlock.conf"
        fi
    fi
}

generate_hyprlock_palette() {
    local img="${1:-}"
    img="${img/#\~/$HOME}"
    if [[ -z "$img" || ! -f "$img" ]]; then
        return 1
    fi

    ensure_hyprlock_wallust_config

    if command -v wallust >/dev/null 2>&1; then
        local templates_dir="$HOME/.config/wallust/templates"
        wallust run -C "$SCRIPT_DIR/wallust-hyprlock.toml" --templates-dir "$templates_dir" -s --no-hooks "$img" >/dev/null 2>&1 || true
    fi
}

ensure_backups() {
    mkdir -p "$BACKUP_DIR"
    if [[ -f "$CONF_PATH" && ! -f "$BACKUP_FILE" ]]; then
        cp -p "$CONF_PATH" "$BACKUP_FILE"
    fi
    if [[ -f "$CONF_PATH" ]]; then
        cp -p "$CONF_PATH" "$BACKUP_DIR/hyprlock.conf.pre_edit"
    fi
}

sync_wallpaper_current() {
    local src="${1:-}"
    if [[ -z "$src" && -f "$QUICKSHELL_WALLPAPER_CONF" ]]; then
        src="$(head -n 1 "$QUICKSHELL_WALLPAPER_CONF" | tr -d '\r\n')"
    fi
    # Expand tilde if present
    src="${src/#\~/$HOME}"
    if [[ -n "$src" && -f "$src" ]]; then
        mkdir -p "$(dirname "$WALLPAPER_CURRENT")"
        cp -f "$src" "$WALLPAPER_CURRENT" 2>/dev/null || true
        return 0
    fi
    return 1
}

parse_blocks() {
    local target_file="${1:-$CONF_PATH}"
    if [[ ! -f "$target_file" ]]; then
        echo "[]"
        return 0
    fi

    awk '
    BEGIN {
        b_idx = 0;
        in_b = 0;
        last_comment = "";
    }

    # Match comment line
    /^[[:space:]]*#[[:space:]]*[A-Za-z0-9_\[\]: -]+/ && !in_b {
        c = $0;
        sub(/^[[:space:]]*#[[:space:]]*/, "", c);
        sub(/^[[:space:]]*#[[:space:]]*/, "", c);
        sub(/[[:space:]]+$/, "", c);
        if (c !~ /^label/) {
            last_comment = c;
        }
    }

    # Match label start (either active or commented)
    /^[[:space:]]*#?[[:space:]]*label[[:space:]]*\{/ {
        in_b = 1;
        is_commented = ($0 ~ /^[[:space:]]*#/);
        
        b_name = (last_comment != "" ? last_comment : ("Block " (b_idx + 1)));
        b_text = "";
        b_color = "$color8";
        b_fsize = 14;
        b_ffam = "Victor Mono Bold Oblique";
        b_halign = "center";
        b_valign = "center";
        b_pos = "0, 0";
        next;
    }

    in_b && /^[[:space:]]*#?[[:space:]]*\}/ {
        in_b = 0;
        names[b_idx] = b_name;
        enabled[b_idx] = (is_commented ? "false" : "true");
        texts[b_idx] = b_text;
        colors[b_idx] = b_color;
        fsizes[b_idx] = b_fsize;
        ffams[b_idx] = b_ffam;
        haligns[b_idx] = b_halign;
        valigns[b_idx] = b_valign;
        positions[b_idx] = b_pos;
        b_idx++;
        last_comment = "";
        next;
    }

    in_b {
        line = $0;
        sub(/^[[:space:]]*#[[:space:]]*/, "", line);
        sub(/^[[:space:]]+/, "", line);
        sub(/[[:space:]]+$/, "", line);
        
        if (line ~ /^text[[:space:]]*=/) {
            sub(/^text[[:space:]]*=[[:space:]]*/, "", line);
            b_text = line;
        } else if (line ~ /^color[[:space:]]*=/) {
            sub(/^color[[:space:]]*=[[:space:]]*/, "", line);
            b_color = line;
        } else if (line ~ /^font_size[[:space:]]*=/) {
            sub(/^font_size[[:space:]]*=[[:space:]]*/, "", line);
            b_fsize = line;
        } else if (line ~ /^font_family[[:space:]]*=/) {
            sub(/^font_family[[:space:]]*=[[:space:]]*/, "", line);
            b_ffam = line;
        } else if (line ~ /^halign[[:space:]]*=/) {
            sub(/^halign[[:space:]]*=[[:space:]]*/, "", line);
            b_halign = line;
        } else if (line ~ /^valign[[:space:]]*=/) {
            sub(/^valign[[:space:]]*=[[:space:]]*/, "", line);
            b_valign = line;
        } else if (line ~ /^position[[:space:]]*=/) {
            sub(/^position[[:space:]]*=[[:space:]]*/, "", line);
            b_pos = line;
        }
    }

    END {
        printf "[\n";
        for (i = 0; i < b_idx; i++) {
            txt = texts[i];
            is_cmd = "false";
            cmd_interval = 1000;
            cmd_body = "";
            if (txt ~ /^cmd\[update:/) {
                is_cmd = "true";
                match(txt, /^cmd\[update:([0-9]+)\][[:space:]]*/);
                int_str = substr(txt, RSTART + 11, RLENGTH - 11);
                gsub(/[^0-9]/, "", int_str);
                cmd_interval = (int_str + 0);
                body = txt;
                sub(/^cmd\[update:[0-9]+\][[:space:]]*/, "", body);
                cmd_body = body;
            } else if (txt ~ /^cmd\[/) {
                is_cmd = "true";
                body = txt;
                sub(/^cmd\[[^\]]*\][[:space:]]*/, "", body);
                cmd_body = body;
            }
            
            is_custom = (names[i] ~ /^(\[Block:|Custom:)/ || i >= 7) ? "true" : "false";
            
            clean_name = names[i];
            sub(/^\[Block:[[:space:]]*/, "", clean_name);
            sub(/\]$/, "", clean_name);
            sub(/^Custom:[[:space:]]*/, "", clean_name);
            
            gsub(/\\/, "\\\\", clean_name); gsub(/"/, "\\\"", clean_name);
            gsub(/\\/, "\\\\", txt); gsub(/"/, "\\\"", txt);
            gsub(/\\/, "\\\\", cmd_body); gsub(/"/, "\\\"", cmd_body);
            gsub(/"/, "\\\"", colors[i]);
            gsub(/"/, "\\\"", ffams[i]);
            
            split(positions[i], pparts, ",");
            px = (pparts[1] + 0);
            py = (pparts[2] + 0);
            
            printf "  {\n";
            printf "    \"index\": %d,\n", i;
            printf "    \"name\": \"%s\",\n", clean_name;
            printf "    \"enabled\": %s,\n", enabled[i];
            printf "    \"is_custom\": %s,\n", is_custom;
            printf "    \"is_cmd\": %s,\n", is_cmd;
            printf "    \"cmd_interval\": %d,\n", cmd_interval;
            printf "    \"cmd_body\": \"%s\",\n", cmd_body;
            printf "    \"raw_text\": \"%s\",\n", txt;
            printf "    \"font_size\": %d,\n", fsizes[i];
            printf "    \"font_family\": \"%s\",\n", ffams[i];
            printf "    \"position_x\": %d,\n", px;
            printf "    \"position_y\": %d,\n", py;
            printf "    \"halign\": \"%s\",\n", haligns[i];
            printf "    \"valign\": \"%s\",\n", valigns[i];
            printf "    \"color\": \"%s\"\n", colors[i];
            printf "  }%s\n", (i == b_idx - 1 ? "" : ",");
        }
        printf "]\n";
    }
    ' "$target_file"
}

get_base_settings() {
    awk '
    function clean_val(v) {
        sub(/[[:space:]]*#.*$/, "", v);
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", v);
        return v;
    }

    BEGIN {
        gen_scale = 2; gen_imm = "true";
        bg_src = "wallpaper_current"; bg_custom = "";
        blur_passes = 2; blur_size = 3; contrast = 1.3; brightness = 0.8; vibrancy = 0.21;
        clock_fmt = "12h"; clock_size = 110;
        show_date = "true"; show_user = "true"; show_layout = "true";
        show_uptime = "true"; show_batt = "true"; show_weather = "true";
        in_w = 260; in_h = 56; in_thick = 2; in_dsize = 0.2; in_dspace = 0.2;
        in_dcenter = "true"; in_fade = "false"; in_hide = "false"; in_holder = "Type Password";

        cur_section = ""; in_gen = 0; in_bg = 0; in_input = 0;
    }

    /^[[:space:]]*#[[:space:]]*Hour-Time/ { cur_section = "time"; next }
    /^[[:space:]]*#[[:space:]]*Date/ { cur_section = "date"; next }
    /^[[:space:]]*#[[:space:]]*USER/ { cur_section = "user"; next }
    /^[[:space:]]*#[[:space:]]*Keyboard LAYOUT/ { cur_section = "layout"; next }
    /^[[:space:]]*#[[:space:]]*uptime/ { cur_section = "uptime"; next }
    /^[[:space:]]*#[[:space:]]*battery information/ { cur_section = "battery"; next }
    /^[[:space:]]*#[[:space:]]*weather/ { cur_section = "weather"; next }

    /^[[:space:]]*general[[:space:]]*\{/ { in_gen = 1; next }
    in_gen && /^[[:space:]]*\}/ { in_gen = 0; next }
    in_gen && /^[[:space:]]*fractional_scaling[[:space:]]*=/ {
        split($0, a, "="); gen_scale = clean_val(a[2]);
    }
    in_gen && /^[[:space:]]*immediate_render[[:space:]]*=/ {
        split($0, a, "="); gen_imm = tolower(clean_val(a[2]));
    }

    /^[[:space:]]*background[[:space:]]*\{/ { in_bg = 1; next }
    in_bg && /^[[:space:]]*\}/ { in_bg = 0; next }
    in_bg && /^[[:space:]]*path[[:space:]]*=/ {
        split($0, a, "=");
        sub(/^[[:space:]]+/, "", a[2]);
        sub(/[[:space:]]*#.*$/, "", a[2]);
        gsub(/[[:space:]]+$/, "", a[2]);
        p = a[2];
        if (p ~ /screenshot/) {
            bg_src = "screenshot";
        } else if (p ~ /\.wallpaper_modified/) {
            bg_src = "wallpaper_modified";
        } else if (p ~ /\.wallpaper_current/) {
            bg_src = "wallpaper_current";
        } else {
            bg_src = "custom";
            bg_custom = p;
        }
    }
    in_bg && /^[[:space:]]*blur_size[[:space:]]*=/ { split($0, a, "="); blur_size = clean_val(a[2]); }
    in_bg && /^[[:space:]]*blur_passes[[:space:]]*=/ { split($0, a, "="); blur_passes = clean_val(a[2]); }
    in_bg && /^[[:space:]]*contrast[[:space:]]*=/ { split($0, a, "="); contrast = clean_val(a[2]); }
    in_bg && /^[[:space:]]*brightness[[:space:]]*=/ { split($0, a, "="); brightness = clean_val(a[2]); }
    in_bg && /^[[:space:]]*vibrancy[[:space:]]*=/ { split($0, a, "="); vibrancy = clean_val(a[2]); }

    /^[[:space:]]*input-field[[:space:]]*\{/ { in_input = 1; next }
    in_input && /^[[:space:]]*\}/ { in_input = 0; next }
    in_input && /^[[:space:]]*size[[:space:]]*=/ {
        split($0, a, "="); split(a[2], s, ",");
        in_w = clean_val(s[1]); in_h = clean_val(s[2]);
    }
    in_input && /^[[:space:]]*outline_thickness[[:space:]]*=/ { split($0, a, "="); in_thick = clean_val(a[2]); }
    in_input && /^[[:space:]]*dots_size[[:space:]]*=/ { split($0, a, "="); in_dsize = clean_val(a[2]); }
    in_input && /^[[:space:]]*dots_spacing[[:space:]]*=/ { split($0, a, "="); in_dspace = clean_val(a[2]); }
    in_input && /^[[:space:]]*dots_center[[:space:]]*=/ { split($0, a, "="); in_dcenter = tolower(clean_val(a[2])); }
    in_input && /^[[:space:]]*fade_on_empty[[:space:]]*=/ { split($0, a, "="); in_fade = tolower(clean_val(a[2])); }
    in_input && /^[[:space:]]*hide_input[[:space:]]*=/ { split($0, a, "="); in_hide = tolower(clean_val(a[2])); }
    in_input && /^[[:space:]]*placeholder_text[[:space:]]*=/ {
        p = $0;
        sub(/^[[:space:]]*placeholder_text[[:space:]]*=[[:space:]]*/, "", p);
        gsub(/<[^>]*>/, "", p);
        gsub(/^["'\''"]+|["'\''"]+$/, "", p);
        in_holder = clean_val(p);
    }

    cur_section == "time" && /^[[:space:]]*text[[:space:]]*=/ {
        if ($0 ~ /%H/ && $0 !~ /%I/) clock_fmt = "24h"; else clock_fmt = "12h";
    }
    cur_section == "time" && /^[[:space:]]*font_size[[:space:]]*=/ {
        split($0, a, "="); clock_size = clean_val(a[2]);
    }

    cur_section == "date" && /^[[:space:]]*#[[:space:]]*label[[:space:]]*\{/ { show_date = "false"; }
    cur_section == "user" && /^[[:space:]]*#[[:space:]]*label[[:space:]]*\{/ { show_user = "false"; }
    cur_section == "layout" && /^[[:space:]]*#[[:space:]]*label[[:space:]]*\{/ { show_layout = "false"; }
    cur_section == "uptime" && /^[[:space:]]*#[[:space:]]*label[[:space:]]*\{/ { show_uptime = "false"; }
    cur_section == "battery" && /^[[:space:]]*#[[:space:]]*label[[:space:]]*\{/ { show_batt = "false"; }
    cur_section == "weather" && /^[[:space:]]*#[[:space:]]*label[[:space:]]*\{/ { show_weather = "false"; }

    /^[[:space:]]*#?[[:space:]]*\}/ && cur_section != "" { cur_section = ""; }

    END {
        printf "{\n";
        printf "  \"general_fractional_scaling\": %d,\n", gen_scale;
        printf "  \"general_immediate_render\": %s,\n", (gen_imm == "true" ? "true" : "false");
        printf "  \"background_source\": \"%s\",\n", bg_src;
        printf "  \"background_custom_path\": \"%s\",\n", bg_custom;
        printf "  \"blur_passes\": %d,\n", blur_passes;
        printf "  \"blur_size\": %d,\n", blur_size;
        printf "  \"contrast\": %s,\n", contrast;
        printf "  \"brightness\": %s,\n", brightness;
        printf "  \"vibrancy\": %s,\n", vibrancy;
        printf "  \"clock_format\": \"%s\",\n", clock_fmt;
        printf "  \"clock_font_size\": %d,\n", clock_size;
        printf "  \"show_date\": %s,\n", show_date;
        printf "  \"show_user\": %s,\n", show_user;
        printf "  \"show_layout\": %s,\n", show_layout;
        printf "  \"show_uptime\": %s,\n", show_uptime;
        printf "  \"show_battery\": %s,\n", show_batt;
        printf "  \"show_weather\": %s,\n", show_weather;
        printf "  \"input_width\": %d,\n", in_w;
        printf "  \"input_height\": %d,\n", in_h;
        printf "  \"input_outline_thickness\": %d,\n", in_thick;
        printf "  \"input_dots_size\": %s,\n", in_dsize;
        printf "  \"input_dots_spacing\": %s,\n", in_dspace;
        printf "  \"input_dots_center\": %s,\n", (in_dcenter == "true" ? "true" : "false");
        printf "  \"input_fade_on_empty\": %s,\n", (in_fade == "true" ? "true" : "false");
        printf "  \"input_hide_input\": %s,\n", (in_hide == "true" ? "true" : "false");
        printf "  \"input_placeholder\": \"%s\"\n", in_holder;
        printf "}\n";
    }
    ' "$CONF_PATH"
}

cmd_get() {
    ensure_hyprlock_conf

    local base_json blocks_json
    base_json="$(get_base_settings)"
    blocks_json="$(parse_blocks "$CONF_PATH")"
    jq -n --argjson base "$base_json" --argjson blocks "$blocks_json" '$base + {text_blocks: $blocks}'
}

cmd_set() {
    local payload="${1:-}"
    if [[ -z "$payload" ]]; then
        payload="$(cat -)"
    fi

    if [[ -z "$payload" || "$payload" == "{}" ]]; then
        echo '{"status":"ok","message":"No changes"}'
        return 0
    fi

    ensure_backups

    local tmp_file
    tmp_file="$(mktemp /tmp/hyprlock_edit.XXXXXX.conf)"

    # Extract all fields using jq with safe fallbacks
    local has_gen_scale has_gen_imm
    local v_gen_scale v_gen_imm
    local has_bg_src v_bg_src v_bg_custom
    local has_blur_passes v_blur_passes
    local has_blur_size v_blur_size
    local has_contrast v_contrast
    local has_brightness v_brightness
    local has_vibrancy v_vibrancy
    local has_clock_fmt v_clock_fmt
    local has_clock_size v_clock_size
    local has_in_w v_in_w has_in_h v_in_h
    local has_in_thick v_in_thick
    local has_in_dsize v_in_dsize
    local has_in_dspace v_in_dspace
    local has_in_dcenter v_in_dcenter
    local has_in_fade v_in_fade
    local has_in_hide v_in_hide
    local has_in_holder v_in_holder
    local has_show_date v_show_date
    local has_show_user v_show_user
    local has_show_layout v_show_layout
    local has_show_uptime v_show_uptime
    local has_show_battery v_show_battery
    local has_show_weather v_show_weather

    eval "$(echo "$payload" | jq -r '
        def flag(key; val):
            if val != null then
                "has_\(key)=1\nv_\(key)=\(@sh "\(val)")\n"
            else
                "has_\(key)=0\n"
            end;
        flag("gen_scale"; .general_fractional_scaling),
        flag("gen_imm"; .general_immediate_render),
        flag("bg_src"; .background_source),
        flag("bg_custom"; .background_custom_path),
        flag("blur_passes"; .blur_passes),
        flag("blur_size"; .blur_size),
        flag("contrast"; .contrast),
        flag("brightness"; .brightness),
        flag("vibrancy"; .vibrancy),
        flag("clock_fmt"; .clock_format),
        flag("clock_size"; .clock_font_size),
        flag("in_w"; .input_width),
        flag("in_h"; .input_height),
        flag("in_thick"; .input_outline_thickness),
        flag("in_dsize"; .input_dots_size),
        flag("in_dspace"; .input_dots_spacing),
        flag("in_dcenter"; .input_dots_center),
        flag("in_fade"; .input_fade_on_empty),
        flag("in_hide"; .input_hide_input),
        flag("in_holder"; .input_placeholder),
        flag("show_date"; .show_date),
        flag("show_user"; .show_user),
        flag("show_layout"; .show_layout),
        flag("show_uptime"; .show_uptime),
        flag("show_battery"; .show_battery),
        flag("show_weather"; .show_weather)
    ')"

    # If custom wallpaper was set, derive colors for Hyprlock ONLY (isolated, not globally)
    local target_img=""
    if [[ "${has_bg_custom:-0}" -eq 1 && -n "${v_bg_custom:-}" ]]; then
        target_img="${v_bg_custom/#\~/$HOME}"
    fi

    if [[ "${has_bg_src:-0}" -eq 1 && "${v_bg_src:-}" == "custom" && -n "$target_img" ]]; then
        if [[ -f "$target_img" ]]; then
            generate_hyprlock_palette "$target_img"
        fi
    elif [[ -n "$target_img" && -f "$target_img" ]]; then
        generate_hyprlock_palette "$target_img"
    elif [[ "${has_bg_src:-0}" -eq 1 && "${v_bg_src:-}" == "wallpaper_current" ]]; then
        # Sync hyprlock colors with current wallpaper without touching desktop theme
        if [[ -f "$HOME/.config/hypr/wallust/wallust-hyprland.conf" ]]; then
            cp -f "$HOME/.config/hypr/wallust/wallust-hyprland.conf" "$SCRIPT_DIR/wallust-hyprlock.conf"
        fi
    fi

    # Clean input placeholder of emojis / icons if needed
    if [[ "${has_in_holder:-0}" -eq 1 ]]; then
        v_in_holder="$(echo "$v_in_holder" | sed 's/[^a-zA-Z0-9 ._!?-]//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [[ -z "$v_in_holder" ]] && v_in_holder="Type Password"
    fi

    awk \
        -v has_gen_scale="${has_gen_scale:-0}" -v v_gen_scale="${v_gen_scale:-}" \
        -v has_gen_imm="${has_gen_imm:-0}" -v v_gen_imm="${v_gen_imm:-}" \
        -v has_bg_src="${has_bg_src:-0}" -v v_bg_src="${v_bg_src:-}" \
        -v has_bg_custom="${has_bg_custom:-0}" -v v_bg_custom="${v_bg_custom:-}" \
        -v has_blur_passes="${has_blur_passes:-0}" -v v_blur_passes="${v_blur_passes:-}" \
        -v has_blur_size="${has_blur_size:-0}" -v v_blur_size="${v_blur_size:-}" \
        -v has_contrast="${has_contrast:-0}" -v v_contrast="${v_contrast:-}" \
        -v has_brightness="${has_brightness:-0}" -v v_brightness="${v_brightness:-}" \
        -v has_vibrancy="${has_vibrancy:-0}" -v v_vibrancy="${v_vibrancy:-}" \
        -v has_clock_fmt="${has_clock_fmt:-0}" -v v_clock_fmt="${v_clock_fmt:-}" \
        -v has_clock_size="${has_clock_size:-0}" -v v_clock_size="${v_clock_size:-}" \
        -v has_in_w="${has_in_w:-0}" -v v_in_w="${v_in_w:-}" \
        -v has_in_h="${has_in_h:-0}" -v v_in_h="${v_in_h:-}" \
        -v has_in_thick="${has_in_thick:-0}" -v v_in_thick="${v_in_thick:-}" \
        -v has_in_dsize="${has_in_dsize:-0}" -v v_in_dsize="${v_in_dsize:-}" \
        -v has_in_dspace="${has_in_dspace:-0}" -v v_in_dspace="${v_in_dspace:-}" \
        -v has_in_dcenter="${has_in_dcenter:-0}" -v v_in_dcenter="${v_in_dcenter:-}" \
        -v has_in_fade="${has_in_fade:-0}" -v v_in_fade="${v_in_fade:-}" \
        -v has_in_hide="${has_in_hide:-0}" -v v_in_hide="${v_in_hide:-}" \
        -v has_in_holder="${has_in_holder:-0}" -v v_in_holder="${v_in_holder:-}" \
        -v has_show_date="${has_show_date:-0}" -v v_show_date="${v_show_date:-}" \
        -v has_show_user="${has_show_user:-0}" -v v_show_user="${v_show_user:-}" \
        -v has_show_layout="${has_show_layout:-0}" -v v_show_layout="${v_show_layout:-}" \
        -v has_show_uptime="${has_show_uptime:-0}" -v v_show_uptime="${v_show_uptime:-}" \
        -v has_show_batt="${has_show_battery:-0}" -v v_show_batt="${v_show_battery:-}" \
        -v has_show_weather="${has_show_weather:-0}" -v v_show_weather="${v_show_weather:-}" \
    '
    BEGIN {
        in_gen = 0; in_bg = 0; in_input = 0;
        cur_sec = ""; in_sec_block = 0;
        bg_path_written = 0;
    }

    # Track Sections
    /^[[:space:]]*#[[:space:]]*Hour-Time/ { cur_sec = "time"; print $0; next }
    /^[[:space:]]*#[[:space:]]*Date/ { cur_sec = "date"; print $0; next }
    /^[[:space:]]*#[[:space:]]*USER/ { cur_sec = "user"; print $0; next }
    /^[[:space:]]*#[[:space:]]*Keyboard LAYOUT/ { cur_sec = "layout"; print $0; next }
    /^[[:space:]]*#[[:space:]]*uptime/ { cur_sec = "uptime"; print $0; next }
    /^[[:space:]]*#[[:space:]]*battery information/ { cur_sec = "battery"; print $0; next }
    /^[[:space:]]*#[[:space:]]*weather/ { cur_sec = "weather"; print $0; next }

    # Handle general block
    /^[[:space:]]*general[[:space:]]*\{/ { in_gen = 1; print $0; next }
    in_gen && /^[[:space:]]*\}/ { in_gen = 0; print $0; next }
    in_gen {
        indent = match($0, /[^ \t]/) ? substr($0, 1, RSTART - 1) : "    ";
        if (has_gen_scale == 1 && $0 ~ /^[[:space:]]*fractional_scaling[[:space:]]*=/) {
            printf "%sfractional_scaling = %d\n", indent, v_gen_scale;
            next;
        }
        if (has_gen_imm == 1 && $0 ~ /^[[:space:]]*immediate_render[[:space:]]*=/) {
            printf "%simmediate_render = %s\n", indent, (v_gen_imm == "true" ? "true" : "false");
            next;
        }
        if ($0 ~ /^[[:space:]]*grace[[:space:]]*=/) { next; }
        print $0;
        next;
    }

    # Handle background block
    /^[[:space:]]*background[[:space:]]*\{/ { in_bg = 1; bg_path_written = 0; print $0; next }
    in_bg && /^[[:space:]]*\}/ { in_bg = 0; print $0; next }
    in_bg {
        indent = match($0, /[^ \t]/) ? substr($0, 1, RSTART - 1) : "    ";
        if ($0 ~ /^[[:space:]]*#?[[:space:]]*path[[:space:]]*=/) {
            if (has_bg_src == 1 || (has_bg_custom == 1 && v_bg_custom != "")) {
                if (bg_path_written == 0) {
                    if (v_bg_src == "screenshot") {
                        printf "%spath = screenshot   # screenshot of your desktop\n", indent;
                    } else if (v_bg_src == "wallpaper_modified") {
                        printf "%spath = $HOME/.config/hypr/wallpaper_effects/.wallpaper_modified # by wallpaper effects\n", indent;
                    } else if (v_bg_src == "custom" || (has_bg_custom == 1 && v_bg_custom != "")) {
                        target_p = (v_bg_custom != "") ? v_bg_custom : "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current";
                        printf "%spath = %s # custom wallpaper\n", indent, target_p;
                    } else {
                        printf "%spath = $HOME/.config/hypr/wallpaper_effects/.wallpaper_current # current wallpaper\n", indent;
                    }
                    bg_path_written = 1;
                }
                next;
            }
        }
        if (has_blur_size == 1 && $0 ~ /^[[:space:]]*blur_size[[:space:]]*=/) {
            printf "%sblur_size = %d\n", indent, v_blur_size;
            next;
        }
        if (has_blur_passes == 1 && $0 ~ /^[[:space:]]*blur_passes[[:space:]]*=/) {
            printf "%sblur_passes = %d\n", indent, v_blur_passes;
            next;
        }
        if (has_contrast == 1 && $0 ~ /^[[:space:]]*contrast[[:space:]]*=/) {
            printf "%scontrast = %s\n", indent, v_contrast;
            next;
        }
        if (has_brightness == 1 && $0 ~ /^[[:space:]]*brightness[[:space:]]*=/) {
            printf "%sbrightness = %s\n", indent, v_brightness;
            next;
        }
        if (has_vibrancy == 1 && $0 ~ /^[[:space:]]*vibrancy[[:space:]]*=/) {
            printf "%svibrancy = %s\n", indent, v_vibrancy;
            next;
        }
        print $0;
        next;
    }

    # Handle input-field block
    /^[[:space:]]*input-field[[:space:]]*\{/ { in_input = 1; print $0; next }
    in_input && /^[[:space:]]*\}/ { in_input = 0; print $0; next }
    in_input {
        indent = match($0, /[^ \t]/) ? substr($0, 1, RSTART - 1) : "    ";
        if (has_in_w == 1 && has_in_h == 1 && $0 ~ /^[[:space:]]*size[[:space:]]*=/) {
            printf "%ssize = %d, %d\n", indent, v_in_w, v_in_h;
            next;
        }
        if (has_in_thick == 1 && $0 ~ /^[[:space:]]*outline_thickness[[:space:]]*=/) {
            printf "%soutline_thickness = %d\n", indent, v_in_thick;
            next;
        }
        if (has_in_dsize == 1 && $0 ~ /^[[:space:]]*dots_size[[:space:]]*=/) {
            printf "%sdots_size = %s\n", indent, v_in_dsize;
            next;
        }
        if (has_in_dspace == 1 && $0 ~ /^[[:space:]]*dots_spacing[[:space:]]*=/) {
            printf "%sdots_spacing = %s\n", indent, v_in_dspace;
            next;
        }
        if (has_in_dcenter == 1 && $0 ~ /^[[:space:]]*dots_center[[:space:]]*=/) {
            printf "%sdots_center = %s\n", indent, (v_in_dcenter == "true" ? "true" : "false");
            next;
        }
        if (has_in_fade == 1 && $0 ~ /^[[:space:]]*fade_on_empty[[:space:]]*=/) {
            printf "%sfade_on_empty = %s\n", indent, (v_in_fade == "true" ? "true" : "false");
            next;
        }
        if (has_in_hide == 1 && $0 ~ /^[[:space:]]*hide_input[[:space:]]*=/) {
            printf "%shide_input = %s\n", indent, (v_in_hide == "true" ? "true" : "false");
            next;
        }
        if (has_in_holder == 1 && $0 ~ /^[[:space:]]*placeholder_text[[:space:]]*=/) {
            printf "%splaceholder_text = <i><span foreground=\"##ffffff99\">%s</span></i>\n", indent, v_in_holder;
            next;
        }
        print $0;
        next;
    }

    # Handle Time label block
    cur_sec == "time" {
        indent = match($0, /[^ \t]/) ? substr($0, 1, RSTART - 1) : "    ";
        if (has_clock_fmt == 1 && $0 ~ /^[[:space:]]*text[[:space:]]*=/) {
            if (v_clock_fmt == "24h") {
                printf "%stext = cmd[update:1000] echo \"$(date +'\''%%H:%%M'\'')\"\n", indent;
            } else {
                printf "%stext = cmd[update:1000] echo \"$(date +'\''%%I:%%M %%p'\'')\"\n", indent;
            }
            next;
        }
        if (has_clock_size == 1 && $0 ~ /^[[:space:]]*font_size[[:space:]]*=/) {
            printf "%sfont_size = %d\n", indent, v_clock_size;
            next;
        }
        if ($0 ~ /^[[:space:]]*\}/) { cur_sec = ""; }
        print $0;
        next;
    }

    # Widget comment/uncomment handling
    cur_sec != "" && cur_sec != "time" {
        sec_flag = 0;
        sec_val = "";
        if (cur_sec == "date" && has_show_date == 1) { sec_flag = 1; sec_val = v_show_date; }
        if (cur_sec == "user" && has_show_user == 1) { sec_flag = 1; sec_val = v_show_user; }
        if (cur_sec == "layout" && has_show_layout == 1) { sec_flag = 1; sec_val = v_show_layout; }
        if (cur_sec == "uptime" && has_show_uptime == 1) { sec_flag = 1; sec_val = v_show_uptime; }
        if (cur_sec == "battery" && has_show_batt == 1) { sec_flag = 1; sec_val = v_show_batt; }
        if (cur_sec == "weather" && has_show_weather == 1) { sec_flag = 1; sec_val = v_show_weather; }

        if (sec_flag == 1) {
            if (sec_val == "false") {
                if ($0 ~ /^[[:space:]]*#/) {
                    print $0;
                } else {
                    print "# " $0;
                }
            } else {
                line = $0;
                sub(/^[[:space:]]*#[[:space:]]?/, "", line);
                print line;
            }
        } else {
            print $0;
        }

        if ($0 ~ /\}/) { cur_sec = ""; }
        next;
    }

    # Default: print line as-is
    { print $0; }
    ' "$CONF_PATH" > "$tmp_file"

    cp -f "$tmp_file" "$CONF_PATH" 2>/dev/null || cat "$tmp_file" > "$CONF_PATH" 2>/dev/null || true
    rm -f "$tmp_file"

    local new_data
    new_data="$(cmd_get)"
    jq -n --argjson data "$new_data" '{"status":"ok", "data": $data}'
}

cmd_update_block() {
    local target_idx="${1:-}"
    local payload="${2:-}"
    if [[ -z "$target_idx" || -z "$payload" ]]; then
        echo '{"status":"error","message":"Missing index or payload"}'
        return 1
    fi

    ensure_backups

    local tmp_file
    tmp_file="$(mktemp /tmp/hyprlock_ublock.XXXXXX.conf)" || tmp_file="/tmp/hyprlock_ublock.conf"

    python3 -c '
import sys, json, re

target_idx = int(sys.argv[1])
payload = json.loads(sys.argv[2])
conf_path = sys.argv[3]
tmp_file = sys.argv[4]

with open(conf_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

out_lines = []
in_b = False
b_idx = -1
is_target = False

for line in lines:
    # Match label start (either active or commented)
    if not in_b and re.match(r"^\s*#?\s*label\s*\{", line):
        in_b = True
        b_idx += 1
        is_target = (b_idx == target_idx)
        if is_target and "enabled" in payload:
            if payload["enabled"]:
                out_lines.append(re.sub(r"^\s*#\s*label\s*\{", "label {", line))
            else:
                if not line.strip().startswith("#"):
                    out_lines.append("# " + line)
                else:
                    out_lines.append(line)
            continue
        out_lines.append(line)
        continue

    if in_b and re.match(r"^\s*#?\s*\}", line):
        in_b = False
        if is_target and "enabled" in payload:
            if payload["enabled"]:
                out_lines.append(re.sub(r"^\s*#\s*\}", "}", line))
            else:
                if not line.strip().startswith("#"):
                    out_lines.append("# " + line)
                else:
                    out_lines.append(line)
            is_target = False
            continue
        is_target = False
        out_lines.append(line)
        continue

    if in_b and is_target:
        # Check enabled state toggle on body lines
        if "enabled" in payload:
            if payload["enabled"]:
                line = re.sub(r"^\s*#\s?", "", line)
            else:
                if not line.strip().startswith("#"):
                    line = "# " + line

        # If property updates
        if "raw_text" in payload and re.search(r"text\s*=", line):
            indent = re.match(r"^(\s*#?\s*)", line).group(1)
            line = indent + "text = " + str(payload.get("raw_text")) + "\n"
        elif "font_size" in payload and re.search(r"font_size\s*=", line):
            indent = re.match(r"^(\s*#?\s*)", line).group(1)
            line = indent + "font_size = " + str(payload.get("font_size")) + "\n"
        elif "font_family" in payload and re.search(r"font_family\s*=", line):
            indent = re.match(r"^(\s*#?\s*)", line).group(1)
            line = indent + "font_family = " + str(payload.get("font_family")) + "\n"
        elif "color" in payload and re.search(r"color\s*=", line):
            indent = re.match(r"^(\s*#?\s*)", line).group(1)
            line = indent + "color = " + str(payload.get("color")) + "\n"
        elif "halign" in payload and re.search(r"halign\s*=", line):
            indent = re.match(r"^(\s*#?\s*)", line).group(1)
            line = indent + "halign = " + str(payload.get("halign")) + "\n"
        elif "valign" in payload and re.search(r"valign\s*=", line):
            indent = re.match(r"^(\s*#?\s*)", line).group(1)
            line = indent + "valign = " + str(payload.get("valign")) + "\n"
        elif ("position_x" in payload or "position_y" in payload) and re.search(r"position\s*=", line):
            indent = re.match(r"^(\s*#?\s*)", line).group(1)
            px = int(round(float(payload.get("position_x", 0))))
            py = int(round(float(payload.get("position_y", 0))))
            line = indent + "position = " + str(px) + ", " + str(py) + "\n"

        out_lines.append(line)
        continue

    # Update comment header name if specified
    if not in_b and "name" in payload and (b_idx + 1) == target_idx and re.match(r"^\s*#\s*[A-Za-z0-9_\[\]: -]+", line):
        if not re.match(r"^\s*#\s*label", line):
            out_lines.append("# " + str(payload.get("name")) + "\n")
            continue

    out_lines.append(line)

with open(tmp_file, "w", encoding="utf-8") as f:
    f.writelines(out_lines)
' "$target_idx" "$payload" "$CONF_PATH" "$tmp_file"

    if ! cp -f "$tmp_file" "$CONF_PATH" 2>/dev/null && ! cat "$tmp_file" > "$CONF_PATH" 2>/dev/null; then
        rm -f "$tmp_file"
        echo '{"status":"error","message":"Failed to write hyprlock.conf"}'
        return 1
    fi
    rm -f "$tmp_file"

    local updated_blocks
    updated_blocks="$(parse_blocks "$CONF_PATH")"
    jq -n --argjson blocks "$updated_blocks" '{"status":"ok", "blocks": $blocks}'
}

cmd_update_positions() {
    local payload="${1:-}"
    if [[ -z "$payload" ]]; then
        echo '{"status":"error","message":"Missing payload"}'
        return 1
    fi

    ensure_backups

    local tmp_file
    tmp_file="$(mktemp /tmp/hyprlock_upos.XXXXXX.conf)" || tmp_file="/tmp/hyprlock_upos.conf"

    python3 -c '
import sys, json, re

payload_str = sys.argv[1]
conf_path = sys.argv[2]
tmp_file = sys.argv[3]

try:
    updates = json.loads(payload_str)
except Exception as e:
    print(json.dumps({"status": "error", "message": f"Invalid JSON: {e}"}))
    sys.exit(1)

update_map = {}
for item in updates:
    if "index" in item:
        update_map[int(item["index"])] = item

with open(conf_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

out_lines = []
in_label = False
label_idx = -1
target_update = None

for line in lines:
    if not in_label and re.match(r"^\s*#?\s*label\s*\{", line):
        in_label = True
        label_idx += 1
        target_update = update_map.get(label_idx)
        out_lines.append(line)
        continue

    if in_label and re.match(r"^\s*#?\s*\}", line):
        in_label = False
        target_update = None
        out_lines.append(line)
        continue

    if in_label and target_update:
        if ("position_x" in target_update or "position_y" in target_update) and re.match(r"^\s*#?\s*position\s*=", line):
            m = re.match(r"^(\s*#?\s*)position\s*=.*$", line)
            prefix = m.group(1) if m else "    "
            px = int(round(float(target_update.get("position_x", 0))))
            py = int(round(float(target_update.get("position_y", 0))))
            out_lines.append(f"{prefix}position = {px}, {py}\n")
            continue
        elif "halign" in target_update and re.match(r"^\s*#?\s*halign\s*=", line):
            m = re.match(r"^(\s*#?\s*)halign\s*=.*$", line)
            prefix = m.group(1) if m else "    "
            ha = target_update["halign"]
            out_lines.append(f"{prefix}halign = {ha}\n")
            continue
        elif "valign" in target_update and re.match(r"^\s*#?\s*valign\s*=", line):
            m = re.match(r"^(\s*#?\s*)valign\s*=.*$", line)
            prefix = m.group(1) if m else "    "
            va = target_update["valign"]
            out_lines.append(f"{prefix}valign = {va}\n")
            continue

    out_lines.append(line)

with open(tmp_file, "w", encoding="utf-8") as f:
    f.writelines(out_lines)
' "$payload" "$CONF_PATH" "$tmp_file"

    if ! cp -f "$tmp_file" "$CONF_PATH" 2>/dev/null && ! cat "$tmp_file" > "$CONF_PATH" 2>/dev/null; then
        rm -f "$tmp_file"
        echo '{"status":"error","message":"Failed to write hyprlock.conf"}'
        return 1
    fi
    rm -f "$tmp_file"

    local updated_blocks
    updated_blocks="$(parse_blocks "$CONF_PATH")"
    jq -n --argjson blocks "$updated_blocks" '{"status":"ok", "blocks": $blocks}'
}

cmd_add_block() {
    local payload="${1:-}"
    if [[ -z "$payload" ]]; then
        echo '{"status":"error","message":"Missing payload"}'
        return 1
    fi

    ensure_backups

    local name raw_text font_size font_family pos_x pos_y halign valign color
    name="$(echo "$payload" | jq -r '.name // "Custom Block"')"
    raw_text="$(echo "$payload" | jq -r '.raw_text // "Custom Text"')"
    font_size="$(echo "$payload" | jq -r '.font_size // 14')"
    font_family="$(echo "$payload" | jq -r '.font_family // "Victor Mono Bold Oblique"')"
    pos_x="$(echo "$payload" | jq -r '.position_x // 0')"
    pos_y="$(echo "$payload" | jq -r '.position_y // 50')"
    halign="$(echo "$payload" | jq -r '.halign // "center"')"
    valign="$(echo "$payload" | jq -r '.valign // "bottom"')"
    color="$(echo "$payload" | jq -r '.color // "$color8"')"

    cat >> "$CONF_PATH" << EOF

# [Block: $name]
label {
    monitor =
    text = $raw_text
    color = $color
    font_size = $font_size
    font_family = $font_family
    position = $pos_x, $pos_y
    halign = $halign
    valign = $valign
}
EOF

    local updated_blocks
    updated_blocks="$(parse_blocks "$CONF_PATH")"
    jq -n --argjson blocks "$updated_blocks" '{"status":"ok", "blocks": $blocks}'
}

cmd_delete_block() {
    local target_idx="${1:-}"
    if [[ -z "$target_idx" ]]; then
        echo '{"status":"error","message":"Missing index"}'
        return 1
    fi

    ensure_backups

    local tmp_file
    tmp_file="$(mktemp /tmp/hyprlock_del.XXXXXX.conf)"

    awk -v target_idx="$target_idx" '
    BEGIN {
        b_idx = 0;
        in_b = 0;
        comment_buf = "";
    }

    /^[[:space:]]*#[[:space:]]*[A-Za-z0-9_\[\]: -]+/ && !in_b {
        comment_buf = $0;
        next;
    }

    /^[[:space:]]*#?[[:space:]]*label[[:space:]]*\{/ {
        in_b = 1;
        if (b_idx == target_idx) {
            comment_buf = "";
            next;
        }
        if (comment_buf != "") {
            print comment_buf;
            comment_buf = "";
        }
        print $0;
        next;
    }

    in_b && /^[[:space:]]*#?[[:space:]]*\}/ {
        in_b = 0;
        if (b_idx == target_idx) {
            b_idx++;
            next;
        }
        b_idx++;
        print $0;
        next;
    }

    in_b {
        if (b_idx == target_idx) next;
        print $0;
        next;
    }

    {
        if (comment_buf != "") {
            print comment_buf;
            comment_buf = "";
        }
        print $0;
    }
    ' "$CONF_PATH" > "$tmp_file"

    cp -f "$tmp_file" "$CONF_PATH"
    rm -f "$tmp_file"

    local updated_blocks
    updated_blocks="$(parse_blocks "$CONF_PATH")"
    jq -n --argjson blocks "$updated_blocks" '{"status":"ok", "blocks": $blocks}'
}

cmd_eval() {
    local cmd="${1:-}"
    if [[ -z "$cmd" ]]; then
        echo '{"status":"ok","output":""}'
        return 0
    fi
    export Scripts="$HOME/.config/hypr/scripts"
    local output
    output="$(timeout 3s bash -c "$cmd" 2>&1 || true)"
    jq -n --arg o "$output" '{"status":"ok", "output": $o}'
}

cmd_generate_wallpaper() {
    local target="${1:-}"
    if [[ -z "$target" ]]; then
        echo '{"status":"error","message":"No wallpaper specified"}'
        return 1
    fi

    target="${target/#\~/$HOME}"
    if [[ ! -f "$target" ]]; then
        echo '{"status":"error","message":"Wallpaper file not found: '"$target"'"}'
        return 1
    fi

    # 1. Update hyprlock config to use custom source and custom path
    cmd_set '{"background_source":"custom","background_custom_path":"'"$target"'"}' >/dev/null

    # 2. Derive colors for Hyprlock ONLY (isolated, not globally)
    generate_hyprlock_palette "$target"

    echo '{"status":"ok","message":"Hyprlock wallpaper & palette updated"}'
}

cmd_restore() {
    if [[ -f "$BACKUP_FILE" ]]; then
        cp -f "$BACKUP_FILE" "$CONF_PATH"
        echo '{"status":"ok","message":"Restored from backup"}'
    else
        echo '{"status":"error","message":"No backup found to restore"}'
        return 1
    fi
}

cmd_test() {
    if pidof hyprlock >/dev/null 2>&1; then
        echo '{"status":"already_running"}'
    else
        hyprlock >/dev/null 2>&1 &
        echo '{"status":"launched"}'
    fi
}

main() {
    local action="${1:-get}"
    case "$action" in
        get)
            cmd_get
            ;;
        set)
            shift
            cmd_set "${1:-}"
            ;;
        update-block|update_block)
            shift
            cmd_update_block "${1:-}" "${2:-}"
            ;;
        update-positions|update_positions|update-blocks|update_blocks)
            shift
            cmd_update_positions "${1:-}"
            ;;
        add-block|add_block)
            shift
            cmd_add_block "${1:-}"
            ;;
        delete-block|delete_block)
            shift
            cmd_delete_block "${1:-}"
            ;;
        eval)
            shift
            cmd_eval "${1:-}"
            ;;
        generate-wallpaper|generate_wallpaper)
            shift
            cmd_generate_wallpaper "${1:-}"
            ;;
        restore)
            cmd_restore
            ;;
        test)
            cmd_test
            ;;
        *)
            echo "{\"status\":\"error\",\"message\":\"Unknown action: $action\"}" >&2
            exit 1
            ;;
    esac
}

main "$@"
