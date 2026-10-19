#!/usr/bin/env python3
"""
Quickshell AppMenu Controller
Triggers DBus actions or Hyprland commands via FIFO or direct DBus fallback.
"""

import os
import sys
import time
import subprocess

RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
FIFO_FILE = os.path.join(RUNTIME_DIR, "quickshell_appmenu.fifo")

def try_fifo_send(line):
    if not os.path.exists(FIFO_FILE):
        return False
    try:
        fd = os.open(FIFO_FILE, os.O_WRONLY | os.O_NONBLOCK)
        with os.fdopen(fd, "w") as f:
            f.write(line + "\n")
        return True
    except Exception:
        return False

def direct_dbus_trigger(service, path, item_id):
    try:
        import dbus
        bus = dbus.SessionBus()
        obj = bus.get_object(service, path)
        iface = dbus.Interface(obj, "com.canonical.dbusmenu")
        iface.Event(int(item_id), "clicked", dbus.Int32(0), dbus.UInt32(int(time.time())))
        return True
    except Exception as e:
        print(f"Direct DBus trigger failed: {e}", file=sys.stderr)
        return False

def direct_hypr_dispatch(cmd):
    try:
        args = ["hyprctl", "dispatch"] + cmd.strip().split()
        subprocess.run(args, check=False)
        return True
    except Exception as e:
        print(f"Direct hypr dispatch failed: {e}", file=sys.stderr)
        return False

def main():
    if len(sys.argv) < 2:
        sys.exit(1)

    action = sys.argv[1]

    if action == "trigger":
        if len(sys.argv) < 5:
            sys.exit(1)
        service = sys.argv[2]
        path = sys.argv[3]
        item_id = sys.argv[4]

        if try_fifo_send(f"trigger {service} {path} {item_id}"):
            sys.exit(0)
        direct_dbus_trigger(service, path, item_id)

    elif action == "hypr":
        if len(sys.argv) < 3:
            sys.exit(1)
        cmd = " ".join(sys.argv[2:])
        if try_fifo_send(f"hypr {cmd}"):
            sys.exit(0)
        direct_hypr_dispatch(cmd)

    elif action == "refresh":
        try_fifo_send("refresh")

if __name__ == "__main__":
    main()

