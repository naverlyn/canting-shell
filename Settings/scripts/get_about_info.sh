#!/usr/bin/env bash

# OS Name
os=$(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
[ -z "$os" ] && os="Linux"

# Host model
host=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Custom PC")

# CPU
cpu=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null || echo "Unknown CPU")

# RAM (usable memory formatted cleanly, e.g. 15.5 GB)
ram=$(awk '/MemTotal/ {
    gb = $2 / 1048576;
    if (gb >= 1) printf "%.1f GB\n", gb;
    else printf "%.0f MB\n", $2 / 1024;
    exit
}' /proc/meminfo 2>/dev/null)
[ -z "$ram" ] && ram="Unknown RAM"

# GPU
gpu=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | cut -d':' -f3 | head -n1 | sed 's/^[ \t]*//' || echo "Integrated Graphics")
[ -z "$gpu" ] && gpu="Integrated Graphics"

# Disk (total physical disk capacity in human-readable SI units, e.g. 1.8 TB / 512 GB)
disk=$(lsblk -b -d -n -o SIZE,TYPE 2>/dev/null | awk '$2=="disk" {sum+=$1} END {
    if (sum >= 1000000000000) printf "%.1f TB\n", sum / 1000000000000;
    else if (sum >= 1000000000) printf "%.0f GB\n", sum / 1000000000;
    else if (sum > 0) printf "%.0f MB\n", sum / 1000000;
}')
[ -z "$disk" ] && disk=$(df -h --si / 2>/dev/null | awk 'NR==2 {print $2}' | sed 's/\([0-9]\)\([A-Za-z]\)/\1 \2B/')
[ -z "$disk" ] && disk="Unknown"

# Kernel
kernel=$(uname -r 2>/dev/null || echo "Unknown")

# Uptime
uptime=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Unknown")

# Session
session="${XDG_SESSION_TYPE:-Wayland}"

# Architecture
arch=$(uname -m 2>/dev/null || echo "x86_64")

# Hostname
hostname=$(uname -n 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "localhost")

# Desktop / Compositor
desktop="${XDG_CURRENT_DESKTOP:-${HYPRLAND_INSTANCE_SIGNATURE:+Hyprland}}"
[ -z "$desktop" ] && desktop="Wayland"

echo "$os"
echo "$host"
echo "$cpu"
echo "$ram"
echo "$gpu"
echo "$disk"
echo "$kernel"
echo "$uptime"
echo "$session"
echo "$arch"
echo "$hostname"
echo "$desktop"
