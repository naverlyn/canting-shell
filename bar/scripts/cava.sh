#!/usr/bin/env bash
# CAVA spectrum data streamer for Quickshell Bar

BARS="${1:-8}"
FRAMERATE="${2:-30}"
MAX_VAL="${3:-100}"
CHANNELS="${4:-mono}"

if ! command -v cava >/dev/null 2>&1; then
    echo "cava: command not found. Please install cava." >&2
    exit 1
fi

# Detect supported input methods compiled into the cava binary (portable across Arch, Fedora, etc.)
SUPPORTED_METHODS=$(printf "[input]\nmethod = probe\n" | cava -p /dev/stdin 2>&1)
RUN_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
METHOD=""

# 1. Native PipeWire (e.g. Arch Linux with cava pipewire build)
if [ -e "${RUN_DIR}/pipewire-0" ] && echo "$SUPPORTED_METHODS" | grep -qw "pipewire"; then
    METHOD="pipewire"
# 2. PulseAudio / PipeWire-Pulse (e.g. Fedora with pipewire-pulse, or standalone PulseAudio)
elif [ -e "${RUN_DIR}/pulse/native" ] || [ -e "${RUN_DIR}/pipewire-0" ] || command -v pactl >/dev/null 2>&1; then
    if echo "$SUPPORTED_METHODS" | grep -qw "pulse"; then
        METHOD="pulse"
    fi
fi

# 3. Fallbacks
if [ -z "$METHOD" ]; then
    if echo "$SUPPORTED_METHODS" | grep -qw "pulse"; then
        METHOD="pulse"
    elif echo "$SUPPORTED_METHODS" | grep -qw "alsa"; then
        METHOD="alsa"
    elif echo "$SUPPORTED_METHODS" | grep -qw "pipewire"; then
        METHOD="pipewire"
    else
        METHOD="pulse"
    fi
fi

PID=$$
CFG_FILE="${RUN_DIR:-/tmp}/quickshell_cava_${UID:-1000}_${PID}.conf"

cleanup() {
    rm -f "$CFG_FILE"
}
trap cleanup EXIT INT TERM HUP

cat <<EOF > "$CFG_FILE"
[general]
bars = $BARS
framerate = $FRAMERATE
autosens = 1

[input]
method = $METHOD
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = $MAX_VAL
bar_delimiter = 59
frame_delimiter = 10
channels = $CHANNELS
EOF

exec cava -p "$CFG_FILE"

