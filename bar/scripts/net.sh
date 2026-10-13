iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}')
ipaddr=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}')
gateway=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="via") {print $(i+1); exit}}')

if [ -n "$iface" ]; then
  printf "Interface\t%s\n" "$iface"
  printf "Local IP\t%s\n" "${ipaddr:-N/A}"
  printf "Gateway\t%s\n" "${gateway:-Direct}"
else
  printf "Status\tOffline\n"
fi

ssid=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes:' | head -1)
if [ -n "$ssid" ]; then
  wname=$(echo "$ssid" | cut -d: -f2)
  wsig=$(echo "$ssid" | cut -d: -f3)
  printf "Wi-Fi SSID\t%s (%s%%)\n" "$wname" "$wsig"
fi

echo "#Session Traffic (RX / TX)"
awk 'NR>2 {
  sub(/:/, "", $1);
  if ($1 != "lo" && ($2 > 0 || $10 > 0)) {
    rx = $2; tx = $10;
    if (rx >= 1073741824) rxs = sprintf("%.2f GB", rx/1073741824);
    else if (rx >= 1048576) rxs = sprintf("%.1f MB", rx/1048576);
    else rxs = sprintf("%.0f KB", rx/1024);

    if (tx >= 1073741824) txs = sprintf("%.2f GB", tx/1073741824);
    else if (tx >= 1048576) txs = sprintf("%.1f MB", tx/1048576);
    else txs = sprintf("%.0f KB", tx/1024);

    printf "%s\t↓ %s  ↑ %s\n", $1, rxs, txs
  }
}' /proc/net/dev
