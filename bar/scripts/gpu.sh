#!/usr/bin/env bash
if command -v nvidia-smi >/dev/null 2>&1; then
  info=$(nvidia-smi --query-gpu=name,driver_version,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,clocks.gr --format=csv,noheader,nounits 2>/dev/null | head -n1)
  if [ -n "$info" ]; then
    IFS=',' read -r name drv util mem_used mem_tot temp pwr clk <<< "$info"
    name=$(echo "$name" | xargs)
    drv=$(echo "$drv" | xargs)
    util=$(echo "$util" | xargs)
    mem_used=$(echo "$mem_used" | xargs)
    mem_tot=$(echo "$mem_tot" | xargs)
    temp=$(echo "$temp" | xargs)
    pwr=$(echo "$pwr" | xargs)
    clk=$(echo "$clk" | xargs)
    echo -e "GPU\t${name}"
    echo -e "Driver\t${drv}"
    echo -e "Utilization\t${util}%"
    echo -e "VRAM\t${mem_used} / ${mem_tot} MiB"
    echo -e "Temperature\t${temp}°C"
    [ -n "$pwr" ] && [ "$pwr" != "[N/A]" ] && echo -e "Power Draw\t${pwr} W"
    [ -n "$clk" ] && [ "$clk" != "[N/A]" ] && echo -e "Core Clock\t${clk} MHz"
    procs=$(nvidia-smi pmon -c 1 2>/dev/null | awk 'NR>2 && $2 != "-" && $9 != "-" { printf "%s\t%s%%\n", $9, ($4 == "-" ? "0" : $4) }' | head -5)
    if [ -n "$procs" ]; then
      echo "#Active GPU Apps"
      echo "$procs"
    fi
    exit 0
  fi
fi

gpu_name=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -n1 | sed -E 's/^.*: //')
[ -n "$gpu_name" ] && echo -e "GPU\t${gpu_name}"

for card in /sys/class/drm/card[0-9]; do
  if [ -f "$card/device/gpu_busy_percent" ]; then
    busy=$(cat "$card/device/gpu_busy_percent" 2>/dev/null)
    echo -e "Utilization\t${busy:-0}%"
    if [ -f "$card/device/mem_info_vram_used" ] && [ -f "$card/device/mem_info_vram_total" ]; then
      u=$(($(cat "$card/device/mem_info_vram_used" 2>/dev/null || echo 0) / 1048576))
      t=$(($(cat "$card/device/mem_info_vram_total" 2>/dev/null || echo 0) / 1048576))
      echo -e "VRAM\t${u} / ${t} MiB"
    fi
    for tfile in "$card"/device/hwmon/hwmon*/temp1_input; do
      if [ -f "$tfile" ]; then
        tv=$(($(cat "$tfile" 2>/dev/null || echo 0) / 1000))
        [ "$tv" -gt 0 ] && echo -e "Temperature\t${tv}°C"
        break
      fi
    done
    break
  fi
done
