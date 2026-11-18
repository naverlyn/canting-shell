#!/usr/bin/env bash

FORCE="${1:-false}"
CACHE="/tmp/quickshell_weather_ip_loc"
NOW=$(date +%s)

# Return cached location if recent (< 1800s / 30 min) and non-empty
if [ "$FORCE" != "true" ] && [ -s "$CACHE" ]; then
  FILE_TIME=$(stat -c %Y "$CACHE" 2>/dev/null || stat -f %m "$CACHE" 2>/dev/null || echo 0)
  AGE=$(( NOW - FILE_TIME ))
  if [ "$AGE" -lt 1800 ]; then
    cat "$CACHE"
    exit 0
  fi
fi

parse_city() {
  python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    city = (data.get("city") or "").strip()
    if city:
        print(city)
except Exception:
    pass
' 2>/dev/null
}

# 1. Get public IP first
IP=""
for ip_url in "https://api.ipify.org" "https://ifconfig.me/ip" "https://icanhazip.com"; do
  RES=$(curl -fsS --connect-timeout 3 --max-time 4 "$ip_url" 2>/dev/null | tr -d '[:space:]')
  if [ -n "$RES" ] && printf '%s' "$RES" | grep -Eq '^[0-9a-fA-F:.]+$'; then
    IP="$RES"
    break
  fi
done

# 2. Resolve city from public IP (fallback to caller-IP endpoints if IP lookup failed)
CITY=""
if [ -n "$IP" ]; then
  for geo_url in "https://ipinfo.io/${IP}/json" "http://ip-api.com/json/${IP}?fields=status,city" "https://ipapi.co/${IP}/json/"; do
    JSON=$(curl -fsS --connect-timeout 3 --max-time 5 "$geo_url" 2>/dev/null)
    if [ -n "$JSON" ]; then
      CITY=$(printf '%s' "$JSON" | parse_city)
      [ -n "$CITY" ] && break
    fi
  done
else
  for geo_url in "https://ipinfo.io/json" "http://ip-api.com/json?fields=status,city" "https://ipapi.co/json/"; do
    JSON=$(curl -fsS --connect-timeout 3 --max-time 5 "$geo_url" 2>/dev/null)
    if [ -n "$JSON" ]; then
      CITY=$(printf '%s' "$JSON" | parse_city)
      [ -n "$CITY" ] && break
    fi
  done
fi

if [ -n "$CITY" ]; then
  printf '%s\n' "$CITY" > "$CACHE"
  printf '%s\n' "$CITY"
  exit 0
fi

# Fallback to stale cache if available
if [ -s "$CACHE" ]; then
  cat "$CACHE"
  exit 0
fi

exit 1
