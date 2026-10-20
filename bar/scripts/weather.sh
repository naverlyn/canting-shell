#!/usr/bin/env bash

LOC="${1:-Bekasi}"
UNIT="${2:-m}"
MODE="${3:-compact}"
FORCE="${4:-false}"

REQ_LOC="${LOC// /+}"
SAFE_LOC=$(echo "$LOC" | tr ' /' '__')
CACHE="/tmp/quickshell_wttr_${SAFE_LOC}_j1.json"
NOW=$(date +%s)

# Check if cache is recent (< 600s / 10 min) and non-empty, and force refresh is not requested
if [ "$FORCE" != "true" ] && [ -s "$CACHE" ]; then
  FILE_TIME=$(stat -c %Y "$CACHE" 2>/dev/null || stat -f %m "$CACHE" 2>/dev/null || echo 0)
  AGE=$(( NOW - FILE_TIME ))
  if [ "$AGE" -lt 600 ]; then
    cat "$CACHE"
    exit 0
  fi
fi

# Fetch fresh JSON from wttr.in
if RES=$(curl -s --connect-timeout 4 --max-time 7 "https://wttr.in/${REQ_LOC}?format=j1" 2>/dev/null); then
  if [ -n "$RES" ] && echo "$RES" | grep -q '"current_condition"'; then
    echo "$RES" > "$CACHE"
    cat "$CACHE"
    exit 0
  fi
fi

# If curl failed or timed out, but we have an existing cache, serve it
if [ -s "$CACHE" ]; then
  cat "$CACHE"
  exit 0
fi

# Otherwise return empty json object
echo '{"error":"Unable to load weather"}'
