out=$(sensors 2>/dev/null | awk -F: '/°C/ { split($2, a, " "); v = a[1]; sub(/^\+/, "", v); if (v != "0.0°C") { sub(/[ ]+$/, "", $1); print $1 "\t" v } }' | head -8)
if [ -n "$out" ]; then echo "$out"; else printf 'Sensors\tunavailable\n'; fi
