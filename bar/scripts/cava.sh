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

# Clean up any legacy leaked temp config files from older shell runs
rm -f "${RUN_DIR}"/quickshell_cava_*.conf 2>/dev/null || true

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

# Stream config via stdin so exec never leaves orphaned temp files behind
exec cava -p /dev/stdin <<EOF
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
