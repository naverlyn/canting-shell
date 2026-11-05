#!/usr/bin/env python3
"""
manage_autostart.py — Backend script for managing Autostart Applications & Daemons.
Supports:
  - Freedesktop XDG autostart entries (~/.config/autostart and /etc/xdg/autostart)
  - Hyprland startup commands (~/.config/hypr/Configs/AutoStart.lua & custom_autostart.lua)
  - Environment variables defined in AutoStart.lua
  - Process running status checks & live test runs
"""

import sys
import os
import re
import json
import glob
import shutil
import subprocess

HYPR_DIR = os.path.expanduser(os.environ.get("HYPR_DIR", "~/.config/hypr"))
AUTOSTART_DIR = os.path.expanduser("~/.config/autostart")
SYS_AUTOSTART_DIR = "/etc/xdg/autostart"
DISABLED_PREFIX = "-- [qs-disabled] "


def ensure_autostart_dirs():
    try:
        os.makedirs(AUTOSTART_DIR, exist_ok=True)
    except Exception:
        pass
    try:
        os.makedirs(HYPR_DIR, exist_ok=True)
    except Exception:
        pass


def parse_desktop_file(path, scope):
    entry = {
        "id": os.path.basename(path),
        "file": path,
        "scope": scope,
        "enabled": True,
        "name": "",
        "exec": "",
        "icon": "",
        "comment": "",
        "terminal": False
    }
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                line = line.strip()
                if line.startswith("Name=") and not entry["name"]:
                    entry["name"] = line[5:].strip()
                elif line.startswith("Exec=") and not entry["exec"]:
                    entry["exec"] = line[5:].strip()
                elif line.startswith("Icon=") and not entry["icon"]:
                    entry["icon"] = line[5:].strip()
                elif line.startswith("Comment=") and not entry["comment"]:
                    entry["comment"] = line[8:].strip()
                elif line.startswith("Terminal="):
                    entry["terminal"] = line[9:].strip().lower() == "true"
                elif line.startswith("Hidden="):
                    if line[7:].strip().lower() == "true":
                        entry["enabled"] = False
                elif line.startswith("X-GNOME-Autostart-enabled="):
                    if line[26:].strip().lower() == "false":
                        entry["enabled"] = False
    except Exception:
        pass

    if not entry["name"]:
        entry["name"] = os.path.splitext(entry["id"])[0]

    return entry


def get_xdg_apps():
    ensure_autostart_dirs()
    apps = {}

    # 1. System autostart apps
    if os.path.isdir(SYS_AUTOSTART_DIR):
        for p in sorted(glob.glob(os.path.join(SYS_AUTOSTART_DIR, "*.desktop"))):
            e = parse_desktop_file(p, "system")
            apps[e["id"]] = e

    # 2. User autostart apps (overrides system)
    if os.path.isdir(AUTOSTART_DIR):
        for p in sorted(glob.glob(os.path.join(AUTOSTART_DIR, "*.desktop"))):
            e = parse_desktop_file(p, "user")
            apps[e["id"]] = e

    return sorted(list(apps.values()), key=lambda x: x["name"].lower())


def is_process_running(cmd_str):
    if not cmd_str:
        return False
    # Extract first binary name
    bin_name = cmd_str.split()[0]
    bin_name = os.path.basename(bin_name).replace(".sh", "")
    try:
        # Check using pgrep
        res = subprocess.run(["pgrep", "-f", bin_name], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return res.returncode == 0
    except Exception:
        return False


def get_hyprland_commands():
    cmds = []
    hypr_autostart_file = os.path.join(HYPR_DIR, "Configs", "AutoStart.lua")
    custom_autostart_file = os.path.join(HYPR_DIR, "custom_autostart.lua")

    # Map of local variables in AutoStart.lua
    var_map = {
        "home": os.path.expanduser("~"),
        "awwwDaemon": "awww-daemon --format xrgb",
        "quickshell": "quickshell",
        "polkit": os.path.expanduser("~/.config/hypr/Configs/Polkit.sh"),
        "portalHyprland": os.path.expanduser("~/.config/hypr/Configs/PortalHyprland.sh"),
        "importEnv": "systemctl --user import-environment WAYLAND_DISPLAY ...",
        "dbusEnv": "dbus-update-activation-environment --systemd WAYLAND_DISPLAY ..."
    }

    # 1. Read AutoStart.lua
    if os.path.isfile(hypr_autostart_file):
        try:
            with open(hypr_autostart_file, "r", encoding="utf-8") as f:
                content = f.read()

            # Parse any local var definitions
            for line in content.splitlines():
                m_var = re.match(r"^local\s+([A-Za-z0-9_]+)\s*=\s*(.+)$", line.strip())
                if m_var:
                    k, v = m_var.group(1), m_var.group(2).strip().strip('"').strip("'")
                    if " .. " in v:
                        v = v.replace('home .. "', os.path.expanduser("~")).replace('home .. \'', os.path.expanduser("~"))
                        v = v.replace(' .. envList', ' WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE QT_QPA_PLATFORMTHEME')
                        v = v.replace('"', '').replace("'", "").strip()
                    var_map[k] = v

            # Find hl.exec_cmd calls
            idx = 0
            for line in content.splitlines():
                raw = line.strip()
                is_disabled = raw.startswith(DISABLED_PREFIX.strip())
                test_line = raw
                if is_disabled:
                    test_line = raw.replace(DISABLED_PREFIX.strip(), "").strip()

                m_cmd = re.search(r"hl\.exec_cmd\(([^)]+)\)", test_line)
                if m_cmd:
                    raw_arg = m_cmd.group(1).strip().strip('"').strip("'")
                    resolved_cmd = var_map.get(raw_arg, raw_arg)
                    name = raw_arg
                    if name in ["awwwDaemon"]:
                        name = "Awww Wallpaper Daemon"
                    elif name in ["quickshell"]:
                        name = "Quickshell Desktop Shell"
                    elif name in ["polkit"]:
                        name = "Polkit Authentication Agent"
                    elif name in ["portalHyprland"]:
                        name = "XDG Desktop Portal Hyprland"
                    elif name in ["importEnv"]:
                        name = "Systemd Environment Import"
                    elif name in ["dbusEnv"]:
                        name = "DBus Activation Environment"
                    else:
                        name = os.path.basename(resolved_cmd)

                    cmds.append({
                        "id": f"sys_{idx}_{raw_arg}",
                        "name": name,
                        "raw_target": raw_arg,
                        "cmd": resolved_cmd,
                        "enabled": not is_disabled,
                        "is_system": True,
                        "running": is_process_running(resolved_cmd),
                        "file": "AutoStart.lua"
                    })
                    idx += 1
        except Exception as e:
            sys.stderr.write(f"Error reading AutoStart.lua: {e}\n")

    # 2. Read custom_autostart.lua if it exists
    if os.path.isfile(custom_autostart_file):
        try:
            with open(custom_autostart_file, "r", encoding="utf-8") as f:
                c_content = f.read()

            custom_blocks = re.findall(r"--\s*<qs_cmd_([^>]+)>\n(.*?)\n--\s*</qs_cmd_\1>", c_content, re.DOTALL)
            for block_id, block_code in custom_blocks:
                is_disabled = DISABLED_PREFIX.strip() in block_code
                m_c = re.search(r"hl\.exec_cmd\(\"([^\"]+)\"\)", block_code)
                if not m_c:
                    m_c = re.search(r"hl\.exec_cmd\('([^']+)'\)", block_code)
                cmd_val = m_c.group(1) if m_c else ""

                m_n = re.search(r"--\s*name:\s*(.+)", block_code)
                name_val = m_n.group(1).strip() if m_n else block_id

                cmds.append({
                    "id": f"custom_{block_id}",
                    "name": name_val,
                    "raw_target": block_id,
                    "cmd": cmd_val,
                    "enabled": not is_disabled,
                    "is_system": False,
                    "running": is_process_running(cmd_val),
                    "file": "custom_autostart.lua"
                })
        except Exception as e:
            sys.stderr.write(f"Error reading custom_autostart.lua: {e}\n")

    return cmds


def get_env_vars():
    hypr_autostart_file = os.path.join(HYPR_DIR, "Configs", "AutoStart.lua")
    envs = []
    if os.path.isfile(hypr_autostart_file):
        try:
            with open(hypr_autostart_file, "r", encoding="utf-8") as f:
                content = f.read()

            env_match = re.search(r"local\s+envs\s*=\s*\{([^}]+)\}", content, re.DOTALL)
            if env_match:
                for line in env_match.group(1).splitlines():
                    line = line.strip().rstrip(",")
                    if line.startswith("--") or not line:
                        continue
                    m = re.match(r"^([A-Za-z0-9_]+)\s*=\s*\"([^\"]+)\"", line)
                    if m:
                        envs.append({"key": m.group(1), "value": m.group(2)})
        except Exception:
            pass
    return envs


def toggle_xdg_app(app_id, enable):
    ensure_autostart_dirs()
    user_file = os.path.join(AUTOSTART_DIR, app_id)
    sys_file = os.path.join(SYS_AUTOSTART_DIR, app_id)

    target_file = user_file
    if not os.path.isfile(user_file) and os.path.isfile(sys_file):
        shutil.copy2(sys_file, user_file)

    if not os.path.isfile(user_file):
        return {"success": False, "error": f"Desktop file {app_id} not found."}

    try:
        with open(user_file, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()

        has_hidden = False
        has_gnome = False
        new_lines = []

        for line in lines:
            if line.startswith("Hidden="):
                new_lines.append(f"Hidden={'false' if enable else 'true'}\n")
                has_hidden = True
            elif line.startswith("X-GNOME-Autostart-enabled="):
                new_lines.append(f"X-GNOME-Autostart-enabled={'true' if enable else 'false'}\n")
                has_gnome = True
            else:
                new_lines.append(line)

        if not has_hidden:
            new_lines.append(f"Hidden={'false' if enable else 'true'}\n")
        if not has_gnome:
            new_lines.append(f"X-GNOME-Autostart-enabled={'true' if enable else 'false'}\n")

        with open(user_file, "w", encoding="utf-8") as f:
            f.writelines(new_lines)

        return {"success": True, "app_id": app_id, "enabled": enable}
    except Exception as e:
        return {"success": False, "error": str(e)}


def add_xdg_app(name, exec_cmd, icon="", comment=""):
    ensure_autostart_dirs()
    safe_id = re.sub(r"[^a-zA-Z0-9_\-]", "", name.lower().replace(" ", "_")) + ".desktop"
    target_file = os.path.join(AUTOSTART_DIR, safe_id)

    content = f"""[Desktop Entry]
Type=Application
Name={name}
Exec={exec_cmd}
Icon={icon or 'application-x-executable'}
Comment={comment or 'Autostarted via Quickshell Settings'}
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
"""
    try:
        with open(target_file, "w", encoding="utf-8") as f:
            f.write(content)
        return {"success": True, "app_id": safe_id, "file": target_file}
    except Exception as e:
        return {"success": False, "error": str(e)}


def delete_xdg_app(app_id):
    user_file = os.path.join(AUTOSTART_DIR, app_id)
    sys_file = os.path.join(SYS_AUTOSTART_DIR, app_id)

    if os.path.isfile(sys_file):
        # System app cannot be deleted from disk; mask it with Hidden=true
        return toggle_xdg_app(app_id, False)

    if os.path.isfile(user_file):
        try:
            os.remove(user_file)
            return {"success": True, "deleted": app_id}
        except Exception as e:
            return {"success": False, "error": str(e)}

    return {"success": False, "error": "File not found"}


def toggle_hypr_cmd(cmd_id, enable):
    if cmd_id.startswith("sys_"):
        # AutoStart.lua
        target_file = os.path.join(HYPR_DIR, "Configs", "AutoStart.lua")
        raw_key = "_".join(cmd_id.split("_")[2:])
        try:
            with open(target_file, "r", encoding="utf-8") as f:
                lines = f.readlines()

            new_lines = []
            matched = False
            for line in lines:
                m = re.search(rf"hl\.exec_cmd\(\s*{re.escape(raw_key)}\s*\)", line)
                if m:
                    matched = True
                    clean_line = line.replace(DISABLED_PREFIX, "").lstrip()
                    if enable:
                        new_lines.append(f"\thl.exec_cmd({raw_key})\n")
                    else:
                        new_lines.append(f"\t{DISABLED_PREFIX}hl.exec_cmd({raw_key})\n")
                else:
                    new_lines.append(line)

            if matched:
                with open(target_file, "w", encoding="utf-8") as f:
                    f.writelines(new_lines)
                return {"success": True, "cmd_id": cmd_id, "enabled": enable}
        except Exception as e:
            return {"success": False, "error": str(e)}

    elif cmd_id.startswith("custom_"):
        # custom_autostart.lua
        target_file = os.path.join(HYPR_DIR, "custom_autostart.lua")
        block_id = cmd_id.replace("custom_", "")
        if not os.path.isfile(target_file):
            return {"success": False, "error": "custom_autostart.lua not found"}

        try:
            with open(target_file, "r", encoding="utf-8") as f:
                content = f.read()

            pattern = rf"(--\s*<qs_cmd_{re.escape(block_id)}>\n)(.*?)(\n--\s*</qs_cmd_{re.escape(block_id)}>)"
            m = re.search(pattern, content, re.DOTALL)
            if not m:
                return {"success": False, "error": "Command block not found"}

            header, body, footer = m.group(1), m.group(2), m.group(3)
            body_lines = []
            for b_line in body.splitlines():
                if "hl.exec_cmd" in b_line:
                    clean = b_line.replace(DISABLED_PREFIX, "").strip()
                    if enable:
                        body_lines.append(f"    {clean}")
                    else:
                        body_lines.append(f"    {DISABLED_PREFIX}{clean}")
                else:
                    body_lines.append(b_line)

            new_block = header + "\n".join(body_lines) + footer
            new_content = content[:m.start()] + new_block + content[m.end():]

            with open(target_file, "w", encoding="utf-8") as f:
                f.write(new_content)

            return {"success": True, "cmd_id": cmd_id, "enabled": enable}
        except Exception as e:
            return {"success": False, "error": str(e)}

    return {"success": False, "error": "Unknown command ID"}


def add_hypr_cmd(name, cmd):
    ensure_autostart_dirs()
    target_file = os.path.join(HYPR_DIR, "custom_autostart.lua")
    hypr_lua = os.path.join(HYPR_DIR, "hyprland.lua")

    # Ensure custom_autostart is loaded in hyprland.lua
    if os.path.isfile(hypr_lua):
        try:
            with open(hypr_lua, "r", encoding="utf-8") as f:
                h_txt = f.read()
            if "custom_autostart" not in h_txt:
                with open(hypr_lua, "a", encoding="utf-8") as f:
                    f.write('\npcall(require, "custom_autostart")\n')
        except Exception:
            pass

    safe_id = re.sub(r"[^a-zA-Z0-9_]", "", name.lower().replace(" ", "_"))

    block = f"""
    -- <qs_cmd_{safe_id}>
    -- name: {name}
    hl.exec_cmd("{cmd}")
    -- </qs_cmd_{safe_id}>
"""

    try:
        if not os.path.isfile(target_file):
            initial = f"""-- Custom Autostart Commands managed by Quickshell Settings
hl.on("hyprland.start", function ()
{block}end)
"""
            with open(target_file, "w", encoding="utf-8") as f:
                f.write(initial)
            return {"success": True, "cmd_id": f"custom_{safe_id}"}
        else:
            with open(target_file, "r", encoding="utf-8") as f:
                c_txt = f.read()

            if f"<qs_cmd_{safe_id}>" in c_txt:
                return {"success": False, "error": f"Command with ID '{safe_id}' already exists."}

            # Insert before closing 'end)'
            pos = c_txt.rfind("end)")
            if pos != -1:
                new_txt = c_txt[:pos] + block + c_txt[pos:]
            else:
                new_txt = c_txt + f"\nhl.on('hyprland.start', function ()\n{block}end)\n"

            with open(target_file, "w", encoding="utf-8") as f:
                f.write(new_txt)

            return {"success": True, "cmd_id": f"custom_{safe_id}"}
    except Exception as e:
        return {"success": False, "error": str(e)}


def delete_hypr_cmd(cmd_id):
    if not cmd_id.startswith("custom_"):
        return {"success": False, "error": "System commands in AutoStart.lua cannot be deleted, only toggled."}

    block_id = cmd_id.replace("custom_", "")
    target_file = os.path.join(HYPR_DIR, "custom_autostart.lua")
    if not os.path.isfile(target_file):
        return {"success": False, "error": "custom_autostart.lua not found"}

    try:
        with open(target_file, "r", encoding="utf-8") as f:
            content = f.read()

        pattern = rf"\n?\s*--\s*<qs_cmd_{re.escape(block_id)}>.*?--\s*</qs_cmd_{re.escape(block_id)}>\n?"
        new_content = re.sub(pattern, "\n", content, flags=re.DOTALL)

        with open(target_file, "w", encoding="utf-8") as f:
            f.write(new_content)

        return {"success": True, "deleted": cmd_id}
    except Exception as e:
        return {"success": False, "error": str(e)}


def test_run_cmd(cmd):
    if not cmd:
        return {"success": False, "error": "Empty command"}
    try:
        subprocess.Popen(cmd, shell=True, start_new_session=True)
        return {"success": True, "message": f"Started '{cmd}'"}
    except Exception as e:
        return {"success": False, "error": str(e)}


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No action specified"}))
        sys.exit(1)

    action = sys.argv[1]

    if action == "list":
        result = {
            "success": True,
            "apps": get_xdg_apps(),
            "hypr_commands": get_hyprland_commands(),
            "envs": get_env_vars()
        }
        print(json.dumps(result, indent=2))

    elif action == "toggle_app":
        if len(sys.argv) < 4:
            print(json.dumps({"error": "Usage: toggle_app <app_id> <true|false>"}))
            sys.exit(1)
        res = toggle_xdg_app(sys.argv[2], sys.argv[3].lower() == "true")
        print(json.dumps(res))

    elif action == "add_app":
        if len(sys.argv) < 4:
            print(json.dumps({"error": "Usage: add_app <name> <exec> [icon] [comment]"}))
            sys.exit(1)
        name = sys.argv[2]
        cmd = sys.argv[3]
        icon = sys.argv[4] if len(sys.argv) > 4 else ""
        comment = sys.argv[5] if len(sys.argv) > 5 else ""
        res = add_xdg_app(name, cmd, icon, comment)
        print(json.dumps(res))

    elif action == "delete_app":
        if len(sys.argv) < 3:
            print(json.dumps({"error": "Usage: delete_app <app_id>"}))
            sys.exit(1)
        res = delete_xdg_app(sys.argv[2])
        print(json.dumps(res))

    elif action == "toggle_hypr_cmd":
        if len(sys.argv) < 4:
            print(json.dumps({"error": "Usage: toggle_hypr_cmd <cmd_id> <true|false>"}))
            sys.exit(1)
        res = toggle_hypr_cmd(sys.argv[2], sys.argv[3].lower() == "true")
        print(json.dumps(res))

    elif action == "add_hypr_cmd":
        if len(sys.argv) < 4:
            print(json.dumps({"error": "Usage: add_hypr_cmd <name> <cmd>"}))
            sys.exit(1)
        res = add_hypr_cmd(sys.argv[2], sys.argv[3])
        print(json.dumps(res))

    elif action == "delete_hypr_cmd":
        if len(sys.argv) < 3:
            print(json.dumps({"error": "Usage: delete_hypr_cmd <cmd_id>"}))
            sys.exit(1)
        res = delete_hypr_cmd(sys.argv[2])
        print(json.dumps(res))

    elif action == "test_run":
        if len(sys.argv) < 3:
            print(json.dumps({"error": "Usage: test_run <cmd>"}))
            sys.exit(1)
        res = test_run_cmd(" ".join(sys.argv[2:]))
        print(json.dumps(res))

    else:
        print(json.dumps({"error": f"Unknown action '{action}'"}))
        sys.exit(1)


if __name__ == "__main__":
    main()
