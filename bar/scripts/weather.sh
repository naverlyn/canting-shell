#!/usr/bin/env bash

LOC="${1:-Bekasi}"
UNIT="${2:-m}"
MODE="${3:-compact}"

[ "$UNIT" != "u" ] && UNIT="m"
QUERY_FLAG="${UNIT}"
if [ "$MODE" = "compact" ]; then
  QUERY_FLAG="${QUERY_FLAG}1"
fi

CACHE="/tmp/quickshell_wttr_${LOC}_${UNIT}_${MODE}.cache"

# Fetch weather (using ?q to omit the follow line)
if RES=$(curl -s --connect-timeout 5 --max-time 8 "wttr.in/${LOC}?${QUERY_FLAG}q" 2>/dev/null); then
  [ -n "$RES" ] && ! echo "$RES" | grep -qiE "<html|50[023]" && echo "$RES" > "$CACHE"
fi

[ ! -f "$CACHE" ] && { echo "Unable to load weather forecast."; exit 0; }

# Convert ANSI escape codes to HTML colors
cat "$CACHE" | awk '
function c256(n) {
  if (n < 16) return "#ebcb8b";
  if (n >= 232) { v = (n - 232) * 10 + 8; return sprintf("#%02x%02x%02x", v, v, v); }
  n -= 16;
  return sprintf("#%02x%02x%02x", int(n / 36) * 51, int((n % 36) / 6) * 51, (n % 6) * 51);
}
{
  if ($0 ~ /igor_chubin/) next;
  gsub(/&/, "\\&amp;"); gsub(/</, "\\&lt;"); gsub(/>/, "\\&gt;");
  gsub(/\033\[0m/, "</font></b>");
  gsub(/\033\[1m/, "<b>");
  while (match($0, /\033\[38;5;([0-9]+)[;0-9]*m/)) {
    code = substr($0, RSTART, RLENGTH);
    split(code, p, "[;m]");
    sub(/\033\[38;5;[0-9]+[;0-9]*m/, "<font color=\"" c256(p[3] + 0) "\">");
  }
  gsub(/\033\[[0-9;]*m/, "");
  print;
}'
