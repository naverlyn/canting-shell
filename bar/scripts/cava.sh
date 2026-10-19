#!/usr/bin/env bash
# CAVA spectrum data streamer for Quickshell Bar

BARS="${1:-8}"
FRAMERATE="${2:-30}"
MAX_VAL="${3:-100}"
CHANNELS="${4:-mono}"

METHOD="pipewire"
if [ ! -e "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pipewire-0" ]; then
    METHOD="pulse"
fi

PID=$$
CFG_FILE="/tmp/quickshell_cava_${UID}_${PID}.conf"

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

