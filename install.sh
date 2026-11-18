#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"
PRESETS_DIR="$CONFIGS_DIR/presets"
THEME_CONF="$CONFIGS_DIR/theme.conf"
BACKUP_SCRIPT="$SCRIPT_DIR/Settings/scripts/manage_backup.py"
TARGET_QS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"

PRESET=""
NO_BACKUP=false
DRY_RUN=false
LIST_ONLY=false
SKIP_DEPS=false
WITH_KEYBINDS=false
SKIP_KEYBINDS=false
WITH_HYPR_LUA=false
SKIP_HYPR_LUA=false

if [[ -t 1 ]]; then
    BOLD='\033[1m'
    DIM='\033[2m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    BOLD='' DIM='' GREEN='' YELLOW='' CYAN='' RED='' NC=''
fi

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install canting-shell and configure a preset (bar, notifications, control center, lockscreen).

Options:
  -p, --preset <name>   Preset to apply (laptop, pc, gaming, minimal)
  -l, --list            List available presets and exit
      --with-hypr-lua   Generate minimal ~/.config/hypr/hyprland.lua if missing
      --skip-hypr-lua   Skip minimal hyprland.lua generation prompt
      --with-keybinds   Add minimal Hyprland keybinds without prompting
      --skip-keybinds   Skip minimal Hyprland keybinds prompt
      --skip-deps       Skip missing dependency installation prompt
      --no-backup       Do not back up existing config files
      --dry-run         Show what would be done without modifying files
  -h, --help            Show this help message
EOF
}

list_presets() {
    echo -e "${BOLD}Available presets (bar, notifications, control center, lockscreen):${NC}"
    echo -e "  ${CYAN}laptop${NC}   - Compact bar with battery/brightness, balanced toasts, 2-panel CC & full lockscreen"
    echo -e "  ${CYAN}pc${NC}       - Desktop bar with CPU/RAM/net/weather, 3-panel CC & full lockscreen"
    echo -e "  ${CYAN}gaming${NC}   - 1s CPU/GPU/temp bar, compact bottom-right toasts & fast minimal lockscreen"
    echo -e "  ${CYAN}minimal${NC}  - Floating minimal bar, compact toasts, 1-panel vertical CC & clean lockscreen"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--preset)
            [[ $# -ge 2 ]] || { echo -e "${RED}Error:${NC} --preset requires an argument" >&2; exit 1; }
            PRESET="$2"
            shift 2
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --with-hypr-lua)
            WITH_HYPR_LUA=true
            shift
            ;;
        --skip-hypr-lua)
            SKIP_HYPR_LUA=true
            shift
            ;;
        --with-keybinds)
            WITH_KEYBINDS=true
            shift
            ;;
        --skip-keybinds)
            SKIP_KEYBINDS=true
            shift
            ;;
        --no-backup)
            NO_BACKUP=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error:${NC} Unknown option '$1'" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ "$LIST_ONLY" == true ]]; then
    list_presets
    exit 0
fi

echo -e "${BOLD}${CYAN}canting-shell installer${NC}"
echo ""

# Detect Linux distribution family from /etc/os-release
detect_distro() {
    local id="" id_like=""
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        id="${ID:-}"
        id_like="${ID_LIKE:-}"
    fi

    case "$id" in
        arch|cachyos|endeavouros|manjaro|garuda|artix) echo "arch" ;;
        fedora|nobara) echo "fedora" ;;
        ubuntu|debian|pop|linuxmint|zorin|elementary) echo "debian" ;;
        opensuse*|suse*) echo "opensuse" ;;
        void) echo "void" ;;
        nixos) echo "nixos" ;;
        *)
            if [[ "$id_like" == *arch* ]]; then echo "arch"
            elif [[ "$id_like" == *fedora* || "$id_like" == *rhel* ]]; then echo "fedora"
            elif [[ "$id_like" == *debian* || "$id_like" == *ubuntu* ]]; then echo "debian"
            elif [[ "$id_like" == *suse* ]]; then echo "opensuse"
            else echo "unknown"
            fi
            ;;
    esac
}

# Map a CLI binary name to its distro package name
map_pkg_for_distro() {
    local cmd="$1" distro="$2"
    case "$distro:$cmd" in
        arch:quickshell)       echo "quickshell" ;;
        arch:hyprctl)          echo "hyprland" ;;
        arch:python3)          echo "python" ;;
        arch:nmcli)            echo "networkmanager" ;;
        arch:bluetoothctl)     echo "bluez-utils" ;;
        arch:wpctl)            echo "wireplumber" ;;
        arch:wl-copy)          echo "wl-clipboard" ;;
        arch:pkexec)           echo "polkit" ;;
        arch:magick)           echo "imagemagick" ;;
        arch:nerd-font)        echo "ttf-jetbrains-mono-nerd" ;;

        fedora:quickshell)     echo "quickshell" ;;
        fedora:hyprctl)        echo "hyprland" ;;
        fedora:python3)        echo "python3" ;;
        fedora:nmcli)          echo "NetworkManager" ;;
        fedora:bluetoothctl)   echo "bluez" ;;
        fedora:wpctl)          echo "wireplumber" ;;
        fedora:wl-copy)        echo "wl-clipboard" ;;
        fedora:pkexec)         echo "polkit" ;;
        fedora:magick)         echo "ImageMagick" ;;

        debian:quickshell)     echo "quickshell" ;;
        debian:hyprctl)        echo "hyprland" ;;
        debian:python3)        echo "python3" ;;
        debian:nmcli)          echo "network-manager" ;;
        debian:bluetoothctl)   echo "bluez" ;;
        debian:wpctl)          echo "wireplumber" ;;
        debian:wl-copy)        echo "wl-clipboard" ;;
        debian:pkexec)         echo "pkexec" ;;
        debian:magick)         echo "imagemagick" ;;

        opensuse:quickshell)   echo "quickshell" ;;
        opensuse:hyprctl)      echo "hyprland" ;;
        opensuse:python3)      echo "python3" ;;
        opensuse:nmcli)        echo "NetworkManager" ;;
        opensuse:bluetoothctl) echo "bluez" ;;
        opensuse:wpctl)        echo "wireplumber" ;;
        opensuse:wl-copy)      echo "wl-clipboard" ;;
        opensuse:pkexec)       echo "polkit" ;;
        opensuse:magick)       echo "ImageMagick" ;;

        void:quickshell)       echo "quickshell" ;;
        void:hyprctl)          echo "hyprland" ;;
        void:python3)          echo "python3" ;;
        void:nmcli)            echo "NetworkManager" ;;
        void:bluetoothctl)     echo "bluez" ;;
        void:wpctl)            echo "wireplumber" ;;
        void:wl-copy)          echo "wl-clipboard" ;;
        void:pkexec)           echo "polkit" ;;
        void:magick)           echo "ImageMagick" ;;

        *)                     echo "$cmd" ;;
    esac
}

# Install JetBrainsMono Nerd Font from GitHub releases into ~/.local/share/fonts
install_nerd_font_fallback() {
    local font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerdFont"
    local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] Would download and install JetBrainsMono Nerd Font to $font_dir"
        return 0
    fi
    if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning:${NC} curl and tar are required to install Nerd Font automatically."
        return 0
    fi
    echo -e "Installing ${CYAN}JetBrainsMono Nerd Font${NC} to $font_dir..."
    mkdir -p "$font_dir"
    if curl -fsSL "$url" | tar -xJ -C "$font_dir"; then
        command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$font_dir" >/dev/null 2>&1 || true
        echo -e "${GREEN}✓${NC} Installed JetBrainsMono Nerd Font"
    else
        echo -e "${YELLOW}Warning:${NC} Failed to download JetBrainsMono Nerd Font."
    fi
}

# Install a list of packages using the detected distro's package manager
install_packages() {
    local distro="$1"
    shift
    local raw_pkgs=("$@")
    local pkgs=()
    local need_nerd_font=false
    for p in "${raw_pkgs[@]}"; do
        if [[ "$p" == "nerd-font" ]]; then
            need_nerd_font=true
        else
            pkgs+=("$p")
        fi
    done

    if [[ ${#pkgs[@]} -eq 0 ]]; then
        [[ "$need_nerd_font" == true ]] && install_nerd_font_fallback
        return 0
    fi

    local cmd_str=""
    case "$distro" in
        arch)
            local aur_helper=""
            if command -v paru >/dev/null 2>&1; then
                aur_helper="paru"
            elif command -v yay >/dev/null 2>&1; then
                aur_helper="yay"
            fi

            if [[ -n "$aur_helper" ]]; then
                cmd_str="$aur_helper -S --needed ${pkgs[*]}"
            else
                local repo_pkgs=() aur_pkgs=()
                for p in "${pkgs[@]}"; do
                    if [[ "$p" == "quickshell" || "$p" == "awww" ]]; then
                        aur_pkgs+=("$p")
                    else
                        repo_pkgs+=("$p")
                    fi
                done
                if [[ ${#repo_pkgs[@]} -gt 0 ]]; then
                    cmd_str="sudo pacman -S --needed ${repo_pkgs[*]}"
                fi
                if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
                    echo -e "${YELLOW}Note:${NC} No AUR helper (yay/paru) found for: ${aur_pkgs[*]}"
                    echo -e "      Install an AUR helper or build ${CYAN}${aur_pkgs[*]}${NC} from AUR."
                fi
            fi
            ;;
        fedora)
            local coprs=()
            local need_hypr_copr=false need_qs_copr=false need_pkg_copr=false
            for p in "${pkgs[@]}"; do
                case "$p" in
                    hyprland|hyprland-guiutils|xdg-desktop-portal-hyprland|hypridle|hyprsunset) need_hypr_copr=true ;;
                    quickshell) need_qs_copr=true ;;
                    wallust) need_pkg_copr=true ;;
                esac
            done
            local enabled_repos=""
            enabled_repos="$(dnf repolist --enabled 2>/dev/null || true)"
            enabled_repos+=$'\n'"$(dnf copr list --enabled 2>/dev/null || true)"
            enabled_repos+=$'\n'"$(ls /etc/yum.repos.d/_copr* 2>/dev/null || true)"
            if [[ "$need_qs_copr" == true ]] && ! grep -qiE "errornointernet[:/]quickshell" <<< "$enabled_repos"; then
                coprs+=("errornointernet/quickshell")
            fi
            if [[ "$need_pkg_copr" == true ]] && ! grep -qiE "errornointernet[:/]packages" <<< "$enabled_repos"; then
                coprs+=("errornointernet/packages")
            fi
            if [[ "$need_hypr_copr" == true ]] && ! grep -qiE "lionheartp[:/]Hyprland" <<< "$enabled_repos"; then
                coprs+=("lionheartp/Hyprland")
            fi
            if [[ ${#coprs[@]} -gt 0 ]]; then
                echo -e "${YELLOW}Note:${NC} On Fedora, Hyprland/Quickshell require COPR repos: ${CYAN}${coprs[*]}${NC}"
                if [[ "$DRY_RUN" == true ]]; then
                    for copr in "${coprs[@]}"; do
                        echo "[dry-run] Would run: sudo dnf copr enable -y $copr"
                    done
                elif [[ -t 0 ]]; then
                    read -rp "Enable required COPR repo(s) (${coprs[*]})? [Y/n]: " copr_ans
                    if [[ "${copr_ans,,}" != "n" ]]; then
                        for copr in "${coprs[@]}"; do
                            if ! sudo dnf copr enable -y "$copr"; then
                                echo -e "${YELLOW}Warning:${NC} Failed to enable COPR $copr"
                                if [[ "$copr" == "lionheartp/Hyprland" ]]; then
                                    echo -e "${YELLOW}Note:${NC} lionheartp/Hyprland requires Fedora 44+. Install Hyprland manually or upgrade to Fedora 44+."
                                fi
                            fi
                        done
                    fi
                fi
            fi
            cmd_str="sudo dnf install -y --skip-unavailable ${pkgs[*]}"
            ;;
        debian)
            cmd_str="sudo apt update && sudo apt install -y ${pkgs[*]}"
            ;;
        opensuse)
            cmd_str="sudo zypper install -y ${pkgs[*]}"
            ;;
        void)
            cmd_str="sudo xbps-install -S ${pkgs[*]}"
            ;;
        nixos)
            echo -e "${YELLOW}NixOS detected:${NC} Add these packages to your configuration.nix / home.nix:"
            echo -e "  ${CYAN}${pkgs[*]}${NC}"
            return 0
            ;;
        *)
            echo -e "${YELLOW}Unknown distribution.${NC} Please install manually: ${CYAN}${pkgs[*]}${NC}"
            return 0
            ;;
    esac

    [[ -z "$cmd_str" ]] && return 0

    if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] Would run: $cmd_str"
    else
        echo -e "Running: ${CYAN}$cmd_str${NC}"
        if ! bash -c "$cmd_str"; then
            echo -e "${YELLOW}Warning:${NC} Package installation exited with errors; continuing with configuration."
        fi
    fi

    if [[ "$need_nerd_font" == true ]]; then
        install_nerd_font_fallback
    fi
}

# Check core and optional dependencies and offer to install missing ones
check_dependencies() {
    local missing_core=()
    local missing_opt=()

    for cmd in quickshell hyprctl python3 jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_core+=("$cmd")
        fi
    done

    for cmd in wpctl brightnessctl nmcli bluetoothctl grim slurp wl-copy cliphist cava pkexec magick curl hypridle; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_opt+=("$cmd")
        fi
    done

    if ! command -v awww >/dev/null 2>&1 && ! command -v swww >/dev/null 2>&1 && ! command -v hyprpaper >/dev/null 2>&1; then
        missing_opt+=("awww")
    fi

    if ! command -v wallust >/dev/null 2>&1 && ! command -v matugen >/dev/null 2>&1; then
        missing_opt+=("wallust")
    fi

    if ! command -v hyprsunset >/dev/null 2>&1 && ! command -v wlsunset >/dev/null 2>&1 && ! command -v gammastep >/dev/null 2>&1; then
        missing_opt+=("hyprsunset")
    fi

    if ! command -v hyprland-dialog >/dev/null 2>&1; then
        missing_opt+=("hyprland-guiutils")
    fi

    if ! command -v xdg-desktop-portal-hyprland >/dev/null 2>&1 \
        && [[ ! -x /usr/libexec/xdg-desktop-portal-hyprland ]] \
        && [[ ! -x /usr/lib/xdg-desktop-portal-hyprland ]] \
        && [[ ! -x /usr/lib/xdg-desktop-portal/xdg-desktop-portal-hyprland ]]; then
        missing_opt+=("xdg-desktop-portal-hyprland")
    fi

    local has_nerd_font=false
    if command -v fc-list >/dev/null 2>&1; then
        if fc-list : family 2>/dev/null | grep -qiE "Nerd ?Font| NF(,|$)| NFM(,|$)| NFP(,|$)"; then
            has_nerd_font=true
        fi
    fi
    if [[ "$has_nerd_font" == false ]]; then
        if find "${XDG_DATA_HOME:-$HOME/.local/share}/fonts" /usr/share/fonts /usr/local/share/fonts -iname "*Nerd*" -print -quit 2>/dev/null | grep -q .; then
            has_nerd_font=true
        fi
    fi
    if [[ "$has_nerd_font" == false ]]; then
        missing_opt+=("nerd-font")
    fi

    if [[ ${#missing_core[@]} -eq 0 && ${#missing_opt[@]} -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} All core and optional dependencies are installed"
        echo ""
        return 0
    fi

    local distro
    distro="$(detect_distro)"

    local core_pkgs=() opt_pkgs=()
    for cmd in "${missing_core[@]}"; do
        core_pkgs+=("$(map_pkg_for_distro "$cmd" "$distro")")
    done
    for cmd in "${missing_opt[@]}"; do
        opt_pkgs+=("$(map_pkg_for_distro "$cmd" "$distro")")
    done

    if [[ ${#missing_core[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Missing core tools:${NC} ${missing_core[*]}"
        echo -e "  ${DIM}Packages ($distro): ${core_pkgs[*]}${NC}"
    else
        echo -e "${GREEN}✓${NC} Core dependencies found (quickshell, hyprctl, python3, jq)"
    fi

    if [[ ${#missing_opt[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Missing optional tools:${NC} ${missing_opt[*]}"
        echo -e "  ${DIM}Packages ($distro): ${opt_pkgs[*]}${NC}"
    fi

    if [[ "$SKIP_DEPS" == true || ! -t 0 ]]; then
        echo ""
        return 0
    fi

    echo ""
    echo -e "${BOLD}Install missing dependencies?${NC} (detected: ${CYAN}$distro${NC})"
    if [[ ${#core_pkgs[@]} -gt 0 && ${#opt_pkgs[@]} -gt 0 ]]; then
        echo "  [1] Install all missing (core + optional)"
        echo "  [2] Install missing core packages only"
        echo "  [3] Skip"
        read -rp "Choose [1-3, default: 3]: " dep_choice
        case "$dep_choice" in
            1) install_packages "$distro" "${core_pkgs[@]}" "${opt_pkgs[@]}" ;;
            2) install_packages "$distro" "${core_pkgs[@]}" ;;
            *) echo -e "${DIM}Skipping dependency installation.${NC}" ;;
        esac
    elif [[ ${#core_pkgs[@]} -gt 0 ]]; then
        read -rp "Install missing core packages (${core_pkgs[*]})? [y/N]: " dep_choice
        if [[ "${dep_choice,,}" == "y" ]]; then
            install_packages "$distro" "${core_pkgs[@]}"
        fi
    elif [[ ${#opt_pkgs[@]} -gt 0 ]]; then
        read -rp "Install missing optional packages (${opt_pkgs[*]})? [y/N]: " dep_choice
        if [[ "${dep_choice,,}" == "y" ]]; then
            install_packages "$distro" "${opt_pkgs[@]}"
        fi
    fi
    echo ""
}

# Prompt user for a preset if not provided via CLI
choose_preset_interactive() {
    list_presets
    echo ""
    while true; do
        read -rp "Select a preset [1-4 or name, default: laptop]: " choice
        case "${choice,,}" in
            ""|1|laptop)  PRESET="laptop"; break ;;
            2|pc|desktop) PRESET="pc"; break ;;
            3|gaming)     PRESET="gaming"; break ;;
            4|minimal)    PRESET="minimal"; break ;;
            *) echo -e "${RED}Invalid selection.${NC} Please enter 1-4 or laptop/pc/gaming/minimal." ;;
        esac
    done
}

# Copy this repo into ~/.config/quickshell if run from another directory
ensure_install_location() {
    local real_script real_target backup_dir
    real_script="$(readlink -f "$SCRIPT_DIR")"
    real_target="$(readlink -f "$TARGET_QS_DIR" 2>/dev/null || echo "$TARGET_QS_DIR")"

    if [[ "$real_script" != "$real_target" ]]; then
        echo -e "${YELLOW}Note:${NC} Repo is at ${CYAN}$real_script${NC}. Quickshell reads from ${CYAN}$TARGET_QS_DIR${NC}."
        if [[ -e "$TARGET_QS_DIR" || -L "$TARGET_QS_DIR" ]]; then
            read -rp "Existing $TARGET_QS_DIR found. Back it up and install there? [Y/n]: " copy_ans
            if [[ "${copy_ans,,}" == "n" ]]; then
                echo -e "${YELLOW}Skipping copy.${NC} Configuring $SCRIPT_DIR in place."
                echo ""
                return 0
            fi
            backup_dir="${TARGET_QS_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
            if [[ "$DRY_RUN" == true ]]; then
                if [[ "$NO_BACKUP" == false ]]; then
                    echo "[dry-run] mv \"$TARGET_QS_DIR\" \"$backup_dir\""
                else
                    echo "[dry-run] rm -rf \"$TARGET_QS_DIR\""
                fi
            else
                if [[ "$NO_BACKUP" == false ]]; then
                    mv "$TARGET_QS_DIR" "$backup_dir"
                    echo -e "${GREEN}✓${NC} Backed up existing config to $backup_dir"
                else
                    rm -rf "$TARGET_QS_DIR"
                fi
            fi
        fi

        if [[ "$DRY_RUN" == true ]]; then
            echo "[dry-run] mkdir -p \"$TARGET_QS_DIR\" && copy repo (excluding .git, backups) to \"$TARGET_QS_DIR/\""
        else
            mkdir -p "$TARGET_QS_DIR"
            tar -C "$real_script" --exclude='.git' --exclude='backups' -cf - . | tar -C "$TARGET_QS_DIR" -xf -
            echo -e "${GREEN}✓${NC} Installed canting-shell to $TARGET_QS_DIR"
        fi

        # Point config/preset paths to the installed location
        CONFIGS_DIR="$TARGET_QS_DIR/configs"
        PRESETS_DIR="$CONFIGS_DIR/presets"
        THEME_CONF="$CONFIGS_DIR/theme.conf"
        BACKUP_SCRIPT="$TARGET_QS_DIR/Settings/scripts/manage_backup.py"
        echo ""
    fi
}

apply_module_preset() {
    local module="$1"
    local target_file="$2"
    local preset_file="$PRESETS_DIR/$module/${PRESET}.json"

    if [[ ! -f "$preset_file" ]]; then
        echo -e "${RED}Error:${NC} Preset '$PRESET' for '$module' not found at $preset_file" >&2
        exit 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] Would apply '$PRESET' ($preset_file -> $target_file)"
        return 0
    fi

    # Merge preset onto existing config (or create from preset) so unrelated user preferences remain intact
    if [[ -f "$target_file" ]] && command -v python3 >/dev/null 2>&1; then
        python3 - "$target_file" "$preset_file" <<'PY'
import json, sys

target_path, preset_path = sys.argv[1], sys.argv[2]
try:
    with open(target_path, "r", encoding="utf-8") as f:
        current = json.load(f)
except Exception:
    current = {}

with open(preset_path, "r", encoding="utf-8") as f:
    preset = json.load(f)

current.update(preset)
with open(target_path, "w", encoding="utf-8") as f:
    json.dump(current, f, indent=2)
    f.write("\n")
PY
    else
        cp "$preset_file" "$target_file"
    fi

    echo -e "${GREEN}✓${NC} Applied '${CYAN}$PRESET${NC}' preset to configs/$(basename "$target_file")"
}

apply_preset() {
    if [[ ! -f "$PRESETS_DIR/bar/${PRESET}.json" ]]; then
        echo -e "${RED}Error:${NC} Unknown preset '$PRESET'" >&2
        list_presets >&2
        exit 1
    fi

    mkdir -p "$CONFIGS_DIR"

    if [[ "$NO_BACKUP" == false ]] && [[ -f "$CONFIGS_DIR/bar_config.json" || -f "$CONFIGS_DIR/notifications_config.json" || -f "$CONFIGS_DIR/control_center_config.json" || -f "$CONFIGS_DIR/lockscreen_config.json" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "[dry-run] Would create snapshot via Settings/scripts/manage_backup.py before applying '$PRESET'"
        elif [[ -f "$BACKUP_SCRIPT" ]] && command -v python3 >/dev/null 2>&1; then
            python3 "$BACKUP_SCRIPT" create \
                "Pre-Preset ($PRESET)" \
                "bar,notifications,controlcenter,lockscreen" \
                "Automatic backup before applying '$PRESET' preset via install.sh" >/dev/null
            echo -e "${GREEN}✓${NC} Saved snapshot in Backup & Restore (Pre-Preset: $PRESET)"
        fi
    fi

    apply_module_preset "bar" "$CONFIGS_DIR/bar_config.json"
    apply_module_preset "notifications" "$CONFIGS_DIR/notifications_config.json"
    apply_module_preset "control_center" "$CONFIGS_DIR/control_center_config.json"
    apply_module_preset "lockscreen" "$CONFIGS_DIR/lockscreen_config.json"

    if [[ "$DRY_RUN" != true && ! -f "$THEME_CONF" ]]; then
        printf '0\n' > "$THEME_CONF"
        echo -e "${GREEN}✓${NC} Initialized default theme in configs/theme.conf"
    fi

    if [[ "$DRY_RUN" != true ]]; then
        date -u +"%Y-%m-%dT%H:%M:%SZ" > "$CONFIGS_DIR/.setup_done"
    fi
}

# Optionally generate a minimal ~/.config/hypr/hyprland.lua + Configs/ layout
setup_minimal_hypr_lua() {
    if [[ "$SKIP_HYPR_LUA" == true ]]; then
        return 0
    fi

    local hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
    local hypr_lua="$hypr_dir/hyprland.lua"
    local configs_dir="$hypr_dir/Configs"

    if [[ -f "$hypr_lua" ]]; then
        return 0
    fi

    if [[ "$WITH_HYPR_LUA" == false ]]; then
        if [[ ! -t 0 ]]; then
            return 0
        fi
        echo ""
        read -rp "No ~/.config/hypr/hyprland.lua found. Generate minimal Hyprland Lua config (with Configs/ modules)? [y/N]: " lua_ans
        if [[ "${lua_ans,,}" != "y" ]]; then
            echo -e "${DIM}Skipping hyprland.lua generation.${NC}"
            return 0
        fi
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] Would generate $hypr_lua and minimal modules in $configs_dir"
        return 0
    fi

    mkdir -p "$configs_dir"

    if [[ -f "$hypr_dir/hyprland.conf" && "$NO_BACKUP" == false ]]; then
        local bak="$hypr_dir/hyprland.conf.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$hypr_dir/hyprland.conf" "$bak"
        echo -e "${GREEN}✓${NC} Backed up existing hyprland.conf to $bak"
    fi

    cat > "$hypr_lua" <<'LUA'
-- Minimal Hyprland Lua config generated by canting-shell installer

pcall(require, "Configs.Keybinds")
pcall(require, "Configs.Monitors")
pcall(require, "Configs.AutoStart")
pcall(require, "Configs.ENVAR")
pcall(require, "Configs.Input")
pcall(require, "Configs.Misc")
pcall(require, "Configs.WindowDecoration")
pcall(require, "theme-borders")
pcall(require, "custom_hypr")
pcall(require, "custom_keybinds")
pcall(require, "custom_animations")
LUA

    if [[ ! -f "$configs_dir/Monitors.lua" ]]; then
        cat > "$configs_dir/Monitors.lua" <<'LUA'
-- Default monitor rule (manage displays visually via MonitorManager)
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
LUA
    fi

    if [[ ! -f "$configs_dir/ENVAR.lua" ]]; then
        cat > "$configs_dir/ENVAR.lua" <<'LUA'
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
LUA
    fi

    if [[ ! -f "$configs_dir/AutoStart.lua" ]]; then
        cat > "$configs_dir/AutoStart.lua" <<'LUA'
local envs = {
    XDG_CURRENT_DESKTOP = "Hyprland",
    XDG_SESSION_DESKTOP = "Hyprland",
    XDG_SESSION_TYPE = "wayland",
    GDK_BACKEND = "wayland,x11,*",
    QT_QPA_PLATFORM = "wayland;xcb",
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
    ELECTRON_OZONE_PLATFORM_HINT = "auto",
    MOZ_ENABLE_WAYLAND = "1",
}

for k, v in pairs(envs) do
    if hl.env then hl.env(k, v) end
    if os.setenv then os.setenv(k, v) end
end

hl.on("hyprland.start", function()
    hl.exec_cmd("command -v awww-daemon >/dev/null 2>&1 && awww-daemon --format xrgb || (command -v swww-daemon >/dev/null 2>&1 && swww-daemon)")
    hl.exec_cmd("quickshell")
end)
LUA
    fi

    if [[ ! -f "$configs_dir/Input.lua" ]]; then
        cat > "$configs_dir/Input.lua" <<'LUA'
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})
LUA
    fi

    if [[ ! -f "$configs_dir/Misc.lua" ]]; then
        cat > "$configs_dir/Misc.lua" <<'LUA'
hl.config({
    misc = {
        vrr = 2,
        focus_on_activate = true,
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },
    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
    },
})
LUA
    fi

    if [[ ! -f "$configs_dir/WindowDecoration.lua" ]]; then
        cat > "$configs_dir/WindowDecoration.lua" <<'LUA'
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
    },
})
LUA
    fi

    if [[ ! -f "$configs_dir/Keybinds.lua" ]]; then
        cat > "$configs_dir/Keybinds.lua" <<'LUA'
-- Essential WM keybinds (canting-shell binds live in custom_keybinds.lua)
local term = "kitty || alacritty || foot || wezterm || xdg-terminal-exec"
hl.bind("SUPER + Return", hl.dsp.exec_cmd(term), { desc = "Terminal" })
hl.bind("SUPER + Q", hl.dsp.window.close(), { desc = "Close Window" })
hl.bind("SUPER + Space", hl.dsp.window.float({ action = "toggle" }), { desc = "Toggle Floating" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle" }), { desc = "Toggle Fullscreen" })
hl.bind("SUPER + M", hl.dsp.exit(), { desc = "Exit Hyprland" })

for i = 1, 9 do
    hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
LUA
    fi

    echo -e "${GREEN}✓${NC} Generated minimal Hyprland Lua config at $hypr_lua"
}

# Optionally add minimal Hyprland keybinds for first-time setup
setup_minimal_keybinds() {
    if [[ "$SKIP_KEYBINDS" == true ]]; then
        return 0
    fi

    if [[ "$WITH_KEYBINDS" == false ]]; then
        if [[ ! -t 0 ]]; then
            return 0
        fi
        echo ""
        read -rp "Add minimal canting-shell Hyprland keybinds (launcher, settings, clipboard, lockscreen, etc.)? [y/N]: " kb_ans
        if [[ "${kb_ans,,}" != "y" ]]; then
            echo -e "${DIM}Skipping keybind setup.${NC}"
            return 0
        fi
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning:${NC} python3 not found; skipping Hyprland keybind setup."
        return 0
    fi

    local hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
    python3 - "$hypr_dir" "$DRY_RUN" <<'PY'
import json
import os
import subprocess
import sys

hypr_dir = sys.argv[1]
dry_run = sys.argv[2] == "true"

BINDINGS = [
    ("SUPER", "D", "qs ipc call launcher toggle", "App Launcher"),
    ("SUPER", "I", "qs ipc call settings toggle", "Settings"),
    ("SUPER", "V", "qs ipc call clipboard toggle", "Clipboard History"),
    ("SUPER", "L", "qs ipc call lockscreen lock", "Lock Screen"),
    ("SUPER", "Tab", "qs ipc call overview toggle", "Workspace Overview"),
    ("ALT", "Tab", "qs ipc call overview switcher", "Window Switcher"),
    ("SUPER", "H", "qs ipc call keybinds toggle", "Keybinds Cheat Sheet"),
    ("SUPER", "W", "qs ipc call wallpaper toggle", "Wallpaper Picker"),
    ("SUPER", "B", "qs ipc call theme toggle", "Theme Switcher"),
    ("SUPER SHIFT", "S", "qs ipc call screenshot toggle", "Screenshot HUD"),
    ("SUPER SHIFT", "E", "qs ipc call powermenu toggle", "Power Menu"),
]

MOD_BITS = {"SHIFT": 1, "CTRL": 4, "ALT": 8, "SUPER": 64}

def modmask(mods):
    mask = 0
    for part in mods.split():
        mask |= MOD_BITS.get(part.upper(), 0)
    return mask

active_binds = set()
if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
    try:
        res = subprocess.run(["hyprctl", "binds", "-j"], capture_output=True, text=True, timeout=2)
        if res.returncode == 0 and res.stdout.strip():
            for b in json.loads(res.stdout):
                active_binds.add((int(b.get("modmask", 0)), str(b.get("key", "")).lower()))
    except Exception:
        pass

is_lua = os.path.isfile(os.path.join(hypr_dir, "hyprland.lua"))
target = os.path.join(hypr_dir, "custom_keybinds.lua" if is_lua else "custom_keybinds.conf")

existing_text = ""
if os.path.isfile(target):
    with open(target, "r", encoding="utf-8", errors="ignore") as f:
        existing_text = f.read()

lines_to_add = []
skipped_present = []
skipped_conflict = []

for mods, key, cmd, desc in BINDINGS:
    if cmd in existing_text:
        skipped_present.append(f"{mods} + {key}")
        continue
    if (modmask(mods), key.lower()) in active_binds:
        skipped_conflict.append(f"{mods} + {key} ({desc})")
        continue
    if is_lua:
        lua_keys = " + ".join(mods.split() + [key])
        lines_to_add.append(f'hl.bind("{lua_keys}", hl.dsp.exec_cmd("{cmd}"), {{ desc = "{desc}" }})')
    else:
        lines_to_add.append(f"bindd = {mods}, {key}, {desc}, exec, {cmd}")

if dry_run:
    print(f"[dry-run] Keybind target: {target}")
    for line in lines_to_add:
        print(f"[dry-run] Would add: {line}")
    if skipped_present:
        print(f"[dry-run] Already configured: {', '.join(skipped_present)}")
    if skipped_conflict:
        print(f"[dry-run] Skipped existing binds: {', '.join(skipped_conflict)}")
    sys.exit(0)

if lines_to_add:
    os.makedirs(hypr_dir, exist_ok=True)
    header = ""
    if not os.path.isfile(target):
        header = (
            "-- Custom Keybindings managed by canting-shell\n"
            if is_lua else
            "# Custom Keybindings managed by canting-shell\n"
        )
    prefix = ""
    if existing_text and not existing_text.endswith("\n"):
        prefix = "\n"
    with open(target, "a", encoding="utf-8") as f:
        if header:
            f.write(header)
        f.write(prefix + "\n".join(lines_to_add) + "\n")

    main_cfg = os.path.join(hypr_dir, "hyprland.lua" if is_lua else "hyprland.conf")
    if os.path.isfile(main_cfg):
        with open(main_cfg, "r", encoding="utf-8", errors="ignore") as f:
            main_txt = f.read()
        needle = "custom_keybinds" if is_lua else "custom_keybinds.conf"
        if needle not in main_txt:
            hook = (
                '\npcall(require, "custom_keybinds")\n'
                if is_lua else
                "\nsource = ~/.config/hypr/custom_keybinds.conf\n"
            )
            with open(main_cfg, "a", encoding="utf-8") as f:
                f.write(hook)

    print(f"\033[0;32m✓\033[0m Added {len(lines_to_add)} minimal keybind(s) to {target}")
else:
    print(f"\033[0;32m✓\033[0m Minimal keybinds already present in {target}")

if skipped_conflict:
    print(f"\033[0;33mNote:\033[0m Skipped keybind(s) already bound in Hyprland: {', '.join(skipped_conflict)}")
PY

    if [[ "$DRY_RUN" != true && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null 2>&1 || true
    fi
}

check_dependencies
ensure_install_location

if [[ -z "$PRESET" ]]; then
    choose_preset_interactive
fi

apply_preset
setup_minimal_hypr_lua
setup_minimal_keybinds

echo ""
echo -e "${BOLD}Next steps:${NC}"
echo -e "  Run ${CYAN}quickshell${NC} to start the shell (or reload if already running)."
echo -e "  You can re-run ${CYAN}./install.sh --preset <name>${NC} anytime to switch presets."
