#!/usr/bin/env bash

# OS Name
os=$(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
[ -z "$os" ] && os="Linux"

# Host model
host=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Custom PC")

# CPU
cpu=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null || echo "Unknown CPU")

# RAM
ram=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "Unknown RAM")

# GPU
gpu=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | cut -d':' -f3 | head -n1 | sed 's/^[ \t]*//' || echo "Integrated Graphics")
[ -z "$gpu" ] && gpu="Integrated Graphics"

# Disk
disk=$(lsblk -d -o SIZE 2>/dev/null | grep -v SIZE | head -n1 | xargs)
[ -z "$disk" ] && disk=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}')
[ -z "$disk" ] && disk="Unknown"

# Kernel
kernel=$(uname -r 2>/dev/null || echo "Unknown")

# Uptime
uptime=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Unknown")

# Session
session="${XDG_SESSION_TYPE:-Wayland}"

echo "$os"
echo "$host"
echo "$cpu"
echo "$ram"
echo "$gpu"
echo "$disk"
echo "$kernel"
echo "$uptime"
echo "$session"
