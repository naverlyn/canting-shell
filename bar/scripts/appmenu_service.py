#!/usr/bin/env python3
"""
Quickshell AppMenu Daemon / Global Menu Bridge
- Registers com.canonical.AppMenu.Registrar on DBus
- Tracks focused window in Hyprland
- Reads active application's DBusMenu (com.canonical.dbusmenu)
- Falls back to smart window/application actions when DBusMenu is absent
- Streams JSON lines to stdout and writes to quickshell_appmenu.json
- Listens on FIFO for instant action triggers
"""

import os
import sys
import json
import time
import signal
import socket
import threading
import subprocess

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
STATE_FILE = os.path.join(RUNTIME_DIR, "quickshell_appmenu.json")
FIFO_FILE = os.path.join(RUNTIME_DIR, "quickshell_appmenu.fifo")

session_bus = None
main_loop = None

# window_id -> {"service": service_name, "path": object_path, "pid": int}
registered_windows = {}
# pid -> {"service": service_name, "path": object_path}
registered_pids = {}

current_active_window = None
last_written_json = ""

def log(msg):
    print(f"[AppMenu] {msg}", file=sys.stderr, flush=True)

class AppMenuRegistrar(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(bus, "/com/canonical/AppMenu/Registrar")

    @dbus.service.method("com.canonical.AppMenu.Registrar", in_signature="uo", sender_keyword="sender")
    def RegisterWindow(self, window_id, menu_path, sender=None):
        wid = int(window_id)
        srv = str(sender)
        pth = str(menu_path)
        pid = None
        if sender and session_bus:
            try:
                pid = int(session_bus.get_unix_process_id(sender))
            except Exception:
                pass

        registered_windows[wid] = {"service": srv, "path": pth, "pid": pid}
        if pid:
            registered_pids[pid] = {"service": srv, "path": pth}
        log(f"Window registered: wid={wid}, srv={srv}, pth={pth}, pid={pid}")
        self.WindowRegistered(wid, srv, dbus.ObjectPath(pth))
        GLib.idle_add(update_active_menu)

    @dbus.service.method("com.canonical.AppMenu.Registrar", in_signature="u")
    def UnregisterWindow(self, window_id):
        wid = int(window_id)
        if wid in registered_windows:
            info = registered_windows.pop(wid)
            pid = info.get("pid")
            if pid and pid in registered_pids:
                registered_pids.pop(pid, None)
            log(f"Window unregistered: wid={wid}")
        self.WindowUnregistered(wid)
        GLib.idle_add(update_active_menu)

    @dbus.service.method("com.canonical.AppMenu.Registrar", in_signature="u", out_signature="so")
    def GetMenuForWindow(self, window_id):
        wid = int(window_id)
        if wid in registered_windows:
            info = registered_windows[wid]
            return (info["service"], dbus.ObjectPath(info["path"]))
        return ("", dbus.ObjectPath("/"))

    @dbus.service.method("com.canonical.AppMenu.Registrar", out_signature="a(uso)")
    def GetMenus(self):
        res = []
        for wid, info in registered_windows.items():
            res.append((dbus.UInt32(wid), info["service"], dbus.ObjectPath(info["path"])))
        return res

    @dbus.service.signal("com.canonical.AppMenu.Registrar", signature="uso")
    def WindowRegistered(self, window_id, service, menu_path):
        pass

    @dbus.service.signal("com.canonical.AppMenu.Registrar", signature="u")
    def WindowUnregistered(self, window_id):
        pass

def parse_shortcut(raw):
    if not raw:
        return ""
    try:
        if isinstance(raw, (list, tuple)) and len(raw) >= 1:
            first = raw[0]
            if isinstance(first, (list, tuple)) and len( first ) >= 2:
                mods = first[:-1]
                key = str(first[-1]).upper()
            elif len(raw) >= 2 and isinstance(raw[0], (list, tuple)):
                mods = raw[0]
                key = str(raw[1]).upper()
            else:
                return ""
            mod_map = {
                "Control": "Ctrl", "Ctrl": "Ctrl",
                "Alt": "Alt",
                "Shift": "Shift",
                "Super": "Super"
            }
            res = [mod_map.get(str(m), str(m)) for m in mods]
            res.append(key)
            return "+".join(res)
        elif isinstance(raw, str):
            return raw
    except Exception:
        pass
    return ""

def parse_node(node, service, path):
    try:
        node_id = int(node[0])
        props = node[1]
        children = node[2]

        raw_label = str(props.get("label", ""))
        label = raw_label.replace("_", "")
        enabled = bool(props.get("enabled", True))
        visible = bool(props.get("visible", True))
        item_type = str(props.get("type", ""))
        is_separator = (item_type == "separator" or label.strip() == "---")
        shortcut = parse_shortcut(props.get("shortcut", []))
        toggle_type = str(props.get("toggle-type", ""))
        toggle_state = int(props.get("toggle-state", 0))

        parsed_children = []
        for c in children:
            parsed_c = parse_node(c, service, path)
            if parsed_c and (parsed_c.get("visible", True) or parsed_c.get("is_separator")):
                parsed_children.append(parsed_c)

        return {
            "id": node_id,
            "label": label,
            "enabled": enabled,
            "visible": visible,
            "is_separator": is_separator,
            "shortcut": shortcut,
            "toggle_type": toggle_type,
            "toggle_state": toggle_state,
            "service": service,
            "path": path,
            "children": parsed_children
        }
    except Exception as e:
        log(f"Error parsing node: {e}")
        return None

def fetch_dbus_menu(bus, service, path):
    try:
        obj = bus.get_object(service, path)
        iface = dbus.Interface(obj, "com.canonical.dbusmenu")
        try:
            iface.AboutToShow(0)
        except Exception:
            pass
        rev, layout = iface.GetLayout(
            0, 3,
            ["label", "enabled", "visible", "type", "shortcut", "toggle-type", "toggle-state", "children-display"]
        )
        if not layout or len(layout) < 3:
            return None
        children = layout[2]
        menus = []
        for c in children:
            parsed = parse_node(c, service, path)
            if parsed and parsed.get("visible", True) and not parsed.get("is_separator") and parsed.get("label"):
                menus.append(parsed)
        return menus if menus else None
    except Exception as e:
        log(f"Failed to fetch dbusmenu from {service} {path}: {e}")
        return None

def get_hypr_active_window():
    try:
        res = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True, timeout=1.0)
        if res.returncode == 0 and res.stdout.strip():
            data = json.loads(res.stdout)
            if data and data.get("address"):
                return data
    except Exception:
        pass
    return None

def get_fallback_menus(active_win):
    title = (active_win.get("title") or "Desktop") if active_win else "Desktop"
    app_class = (active_win.get("class") or "System") if active_win else "System"
    pid = active_win.get("pid") if active_win else 0
    is_window = bool(active_win and active_win.get("mapped", True) and active_win.get("address"))

    return [
        {
            "id": 100,
            "label": "File",
            "enabled": True,
            "children": [
                { "id": 101, "label": "New Window", "shortcut": "Ctrl+Shift+N", "enabled": is_window, "hypr": f"exec {app_class}" if is_window else "" },
                { "id": 102, "type": "separator", "is_separator": True },
                { "id": 103, "label": "Close Window", "shortcut": "Alt+F4", "enabled": is_window, "hypr": "closewindow activewindow" },
                { "id": 104, "label": "Force Kill", "shortcut": "Super+Shift+Q", "enabled": is_window, "hypr": "killactive" }
            ]
        },
        {
            "id": 200,
            "label": "Edit",
            "enabled": True,
            "children": [
                { "id": 201, "label": "Copy", "shortcut": "Ctrl+C", "enabled": is_window, "hypr": "sendshortcut Ctrl,c,activewindow" },
                { "id": 202, "label": "Paste", "shortcut": "Ctrl+V", "enabled": is_window, "hypr": "sendshortcut Ctrl,v,activewindow" },
                { "id": 203, "type": "separator", "is_separator": True },
                { "id": 204, "label": "Select All", "shortcut": "Ctrl+A", "enabled": is_window, "hypr": "sendshortcut Ctrl,a,activewindow" }
            ]
        },
        {
            "id": 300,
            "label": "View",
            "enabled": True,
            "children": [
                { "id": 301, "label": "Toggle Fullscreen", "shortcut": "Super+F", "enabled": is_window, "hypr": "fullscreen 0" },
                { "id": 302, "label": "Toggle Floating", "shortcut": "Super+V", "enabled": is_window, "hypr": "togglefloating activewindow" },
                { "id": 303, "label": "Pin Window (Sticky)", "shortcut": "Super+P", "enabled": is_window, "hypr": "pin activewindow" },
                { "id": 304, "type": "separator", "is_separator": True },
                { "id": 305, "label": "Center Window", "enabled": is_window, "hypr": "centerwindow" }
            ]
        },
        {
            "id": 400,
            "label": "Window",
            "enabled": True,
            "children": [
                { "id": 401, "label": "Move to Workspace 1", "shortcut": "Super+Shift+1", "enabled": is_window, "hypr": "movetoworkspace 1" },
                { "id": 402, "label": "Move to Workspace 2", "shortcut": "Super+Shift+2", "enabled": is_window, "hypr": "movetoworkspace 2" },
                { "id": 403, "label": "Move to Workspace 3", "shortcut": "Super+Shift+3", "enabled": is_window, "hypr": "movetoworkspace 3" },
                { "id": 404, "label": "Move to Workspace 4", "shortcut": "Super+Shift+4", "enabled": is_window, "hypr": "movetoworkspace 4" },
                { "id": 405, "label": "Move to Workspace 5", "shortcut": "Super+Shift+5", "enabled": is_window, "hypr": "movetoworkspace 5" },
                { "id": 406, "type": "separator", "is_separator": True },
                { "id": 407, "label": "Toggle Split Layout", "shortcut": "Super+J", "enabled": is_window, "hypr": "togglesplit" }
            ]
        },
        {
            "id": 500,
            "label": "Help",
            "enabled": True,
            "children": [
                { "id": 501, "label": f"App: {app_class}", "enabled": False },
                { "id": 502, "label": f"Title: {title[:40]}", "enabled": False },
                { "id": 503, "label": f"PID: {pid}", "enabled": False }
            ]
        }
    ]

def write_state(data):
    global last_written_json
    compact = json.dumps(data, ensure_ascii=False)
    if compact == last_written_json:
        return
    last_written_json = compact

    # Stream single-line JSON to stdout for Quickshell SplitParser
    try:
        print(compact, flush=True)
    except Exception:
        pass

    # Also write to state file for FileView fallback
    tmp = STATE_FILE + f".tmp.{os.getpid()}"
    try:
        with open(tmp, "w", encoding="utf-8") as f:
            f.write(compact + "\n")
        os.replace(tmp, STATE_FILE)
    except Exception as e:
        log(f"Failed to write state file: {e}")

def update_active_menu():
    global current_active_window
    active = get_hypr_active_window()
    current_active_window = active

    title = (active.get("title") or "") if active else ""
    app_class = (active.get("class") or "") if active else ""
    pid = active.get("pid") if active else None

    menu_found = False
    menus = []

    # 1. Check if PID is registered with DBusMenu
    if pid and pid in registered_pids and session_bus:
        info = registered_pids[pid]
        dbus_menus = fetch_dbus_menu(session_bus, info["service"], info["path"])
        if dbus_menus:
            menus = dbus_menus
            menu_found = True

    # 2. Check if window ID or address is registered
    if not menu_found and active and session_bus:
        for wid, info in list(registered_windows.items()):
            if info.get("pid") == pid:
                dbus_menus = fetch_dbus_menu(session_bus, info["service"], info["path"])
                if dbus_menus:
                    menus = dbus_menus
                    menu_found = True
                    break

    # 3. Check well-known Qt/KDE DBus menu exports if not registered via registrar
    if not menu_found and pid and session_bus:
        try:
            dbus_obj = session_bus.get_object("org.freedesktop.DBus", "/org/freedesktop/DBus")
            dbus_iface = dbus.Interface(dbus_obj, "org.freedesktop.DBus")
            names = dbus_iface.ListNames()
            for name in names:
                name_str = str(name)
                if name_str.startswith(":"):
                    try:
                        conn_pid = int(session_bus.get_unix_process_id(name_str))
                        if conn_pid == pid:
                            for candidate_path in ["/MenuBar", "/MenuBar/1", "/com/canonical/menu/1"]:
                                dbus_menus = fetch_dbus_menu(session_bus, name_str, candidate_path)
                                if dbus_menus:
                                    menus = dbus_menus
                                    menu_found = True
                                    registered_pids[pid] = {"service": name_str, "path": candidate_path}
                                    break
                            if menu_found:
                                break
                    except Exception:
                        continue
        except Exception:
            pass

    # 4. Fallback if no native DBusMenu
    if not menu_found:
        menus = get_fallback_menus(active)

    state = {
        "has_menu": menu_found,
        "app_title": title,
        "app_class": app_class,
        "pid": pid,
        "menus": menus
    }
    write_state(state)
    return True

def hyprland_event_listener():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    xdg = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    if not sig:
        log("No HYPRLAND_INSTANCE_SIGNATURE found; polling will be used.")
        return

    sock_path = os.path.join(xdg, "hypr", sig, ".socket2.sock")
    while True:
        try:
            if not os.path.exists(sock_path):
                time.sleep(1)
                continue
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(sock_path)
            log(f"Connected to Hyprland IPC socket at {sock_path}")
            buf = ""
            while True:
                data = s.recv(4096)
                if not data:
                    break
                buf += data.decode("utf-8", errors="replace")
                while "\n" in buf:
                    line, buf = buf.split("\n", 1)
                    if line.startswith("activewindow>>") or line.startswith("activewindowv2>>") or line.startswith("closewindow>>"):
                        GLib.idle_add(update_active_menu)
        except Exception as e:
            log(f"Hyprland socket reconnecting: {e}")
            time.sleep(1)

def trigger_menu_item(service, path, item_id):
    if not session_bus:
        return False
    try:
        obj = session_bus.get_object(service, path)
        iface = dbus.Interface(obj, "com.canonical.dbusmenu")
        iface.Event(int(item_id), "clicked", dbus.Int32(0), dbus.UInt32(int(time.time())))
        log(f"Triggered DBus action: id={item_id} on {service} {path}")
        return True
    except Exception as e:
        log(f"Failed to trigger item {item_id}: {e}")
        return False

def trigger_hypr_command(cmd):
    try:
        args = ["hyprctl", "dispatch"] + cmd.strip().split()
        subprocess.run(args, check=False)
        log(f"Dispatched Hyprland command: {cmd}")
        return True
    except Exception as e:
        log(f"Failed to dispatch Hyprland command {cmd}: {e}")
        return False

def fifo_listener():
    try:
        if os.path.exists(FIFO_FILE):
            os.remove(FIFO_FILE)
        os.mkfifo(FIFO_FILE)
    except Exception as e:
        log(f"Failed to create FIFO {FIFO_FILE}: {e}")
        return

    while True:
        try:
            with open(FIFO_FILE, "r") as fifo:
                for line in fifo:
                    line = line.strip()
                    if not line:
                        continue
                    parts = line.split(" ", 3)
                    cmd = parts[0]
                    if cmd == "trigger" and len(parts) >= 4:
                        srv = parts[1]
                        pth = parts[2]
                        iid = parts[3]
                        trigger_menu_item(srv, pth, iid)
                    elif cmd == "hypr" and len(parts) >= 2:
                        hcmd = line[5:].strip()
                        trigger_hypr_command(hcmd)
                    elif cmd == "refresh":
                        GLib.idle_add(update_active_menu)
        except Exception:
            time.sleep(0.1)

def cleanup():
    try:
        if os.path.exists(FIFO_FILE):
            os.remove(FIFO_FILE)
    except Exception:
        pass
    try:
        if os.path.exists(STATE_FILE):
            os.remove(STATE_FILE)
    except Exception:
        pass

def main():
    global session_bus, main_loop
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    main_loop = GLib.MainLoop()

    try:
        session_bus = dbus.SessionBus()
    except Exception as e:
        log(f"Failed to connect to SessionBus: {e}")
        session_bus = None

    if session_bus:
        try:
            bus_name = dbus.service.BusName("com.canonical.AppMenu.Registrar", session_bus, do_not_queue=True)
            registrar = AppMenuRegistrar(session_bus)
            log("Claimed com.canonical.AppMenu.Registrar on SessionBus successfully.")
        except Exception as e:
            log(f"Note: Could not claim com.canonical.AppMenu.Registrar: {e}")

    t_hypr = threading.Thread(target=hyprland_event_listener, daemon=True)
    t_hypr.start()

    t_fifo = threading.Thread(target=fifo_listener, daemon=True)
    t_fifo.start()

    update_active_menu()
    GLib.timeout_add_seconds(2, update_active_menu)

    def handle_sig(sig, frame):
        cleanup()
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_sig)
    signal.signal(signal.SIGTERM, handle_sig)

    try:
        main_loop.run()
    except KeyboardInterrupt:
        cleanup()

if __name__ == "__main__":
    main()

