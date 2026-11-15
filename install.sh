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

        fedora:quickshell)     echo "quickshell" ;;
        fedora:hyprctl)        echo "hyprland" ;;
        fedora:python3)        echo "python3" ;;
        fedora:nmcli)          echo "NetworkManager" ;;
        fedora:bluetoothctl)   echo "bluez" ;;
        fedora:wpctl)          echo "wireplumber" ;;
        fedora:wl-copy)        echo "wl-clipboard" ;;

        debian:quickshell)     echo "quickshell" ;;
        debian:hyprctl)        echo "hyprland" ;;
        debian:python3)        echo "python3" ;;
        debian:nmcli)          echo "network-manager" ;;
        debian:bluetoothctl)   echo "bluez" ;;
        debian:wpctl)          echo "wireplumber" ;;
        debian:wl-copy)        echo "wl-clipboard" ;;

        opensuse:quickshell)   echo "quickshell" ;;
        opensuse:hyprctl)      echo "hyprland" ;;
        opensuse:python3)      echo "python3" ;;
        opensuse:nmcli)        echo "NetworkManager" ;;
        opensuse:bluetoothctl) echo "bluez" ;;
        opensuse:wpctl)        echo "wireplumber" ;;
        opensuse:wl-copy)      echo "wl-clipboard" ;;

        void:quickshell)       echo "quickshell" ;;
        void:hyprctl)          echo "hyprland" ;;
        void:python3)          echo "python3" ;;
        void:nmcli)            echo "NetworkManager" ;;
        void:bluetoothctl)     echo "bluez" ;;
        void:wpctl)            echo "wireplumber" ;;
        void:wl-copy)          echo "wl-clipboard" ;;

        *)                     echo "$cmd" ;;
    esac
}

# Install a list of packages using the detected distro's package manager
install_packages() {
    local distro="$1"
    shift
    local pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && return 0

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
                    if [[ "$p" == "quickshell" ]]; then
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
            cmd_str="sudo dnf install -y ${pkgs[*]}"
            for p in "${pkgs[@]}"; do
                if [[ "$p" == "quickshell" ]]; then
                    echo -e "${YELLOW}Note:${NC} On Fedora, 'quickshell' may require enabling a COPR (e.g. solopasha/hyprland or errornointernet/quickshell)."
                    break
                fi
            done
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
        bash -c "$cmd_str"
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

    for cmd in wpctl brightnessctl nmcli bluetoothctl grim slurp wl-copy cava; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_opt+=("$cmd")
        fi
    done

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
        read -rp "Select a bar preset [1-4 or name, default: laptop]: " choice
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
            echo "[dry-run] mkdir -p \"$TARGET_QS_DIR\" && cp -a \"$real_script/.\" \"$TARGET_QS_DIR/\""
        else
            mkdir -p "$TARGET_QS_DIR"
            cp -a "$real_script/." "$TARGET_QS_DIR/"
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
}

check_dependencies
ensure_install_location

if [[ -z "$PRESET" ]]; then
    choose_preset_interactive
fi

apply_preset

echo ""
echo -e "${BOLD}Next steps:${NC}"
echo -e "  Run ${CYAN}quickshell${NC} to start the shell (or reload if already running)."
echo -e "  You can re-run ${CYAN}./install.sh --preset <name>${NC} anytime to switch bar presets."
