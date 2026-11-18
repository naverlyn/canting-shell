#!/usr/bin/env python3
"""Helper script for the canting-shell first-run SetupWizard."""

import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import urllib.request
from datetime import datetime, timezone

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CONFIGS_DIR = os.path.join(BASE_DIR, "configs")
PRESETS_DIR = os.path.join(CONFIGS_DIR, "presets")
MARKER_FILE = os.path.join(CONFIGS_DIR, ".setup_done")

MODULE_TARGETS = {
    "bar": "bar_config.json",
    "notifications": "notifications_config.json",
    "control_center": "control_center_config.json",
    "lockscreen": "lockscreen_config.json",
}

TOOL_CHECKS = [
    ("awww", ("awww", "swww", "hyprpaper")),
    ("wallust", ("wallust", "matugen")),
    ("cliphist", ("cliphist",)),
    ("cava", ("cava",)),
    ("grim", ("grim", "slurp")),
    ("swappy", ("swappy",)),
    ("magick", ("magick",)),
    ("kitty", ("kitty", "alacritty", "foot", "wezterm", "ghostty", "konsole", "gnome-terminal")),
    ("wl-copy", ("wl-copy",)),
    ("brightnessctl", ("brightnessctl",)),
    ("wpctl", ("wpctl",)),
    ("nmcli", ("nmcli",)),
    ("bluetoothctl", ("bluetoothctl",)),
    ("hypridle", ("hypridle",)),
    ("hyprsunset", ("hyprsunset", "wlsunset", "gammastep")),
    ("curl", ("curl",)),
    ("jq", ("jq",)),
]

TOOL_REQUIRE_ALL = {"grim"}

DISTRO_PKG_MAP = {
    "arch": {
        "awww": ["awww"],
        "wallust": ["wallust"],
        "cliphist": ["cliphist"],
        "cava": ["cava"],
        "grim": ["grim", "slurp"],
        "swappy": ["swappy"],
        "magick": ["imagemagick"],
        "kitty": ["kitty"],
        "wl-copy": ["wl-clipboard"],
        "brightnessctl": ["brightnessctl"],
        "wpctl": ["wireplumber"],
        "nmcli": ["networkmanager"],
        "bluetoothctl": ["bluez-utils"],
        "hypridle": ["hypridle"],
        "hyprsunset": ["hyprsunset"],
        "curl": ["curl"],
        "jq": ["jq"],
        "nerd-font": ["ttf-jetbrains-mono-nerd"],
    },
    "fedora": {
        "awww": ["swww"],
        "wallust": ["wallust"],
        "cliphist": ["cliphist"],
        "cava": ["cava"],
        "grim": ["grim", "slurp"],
        "swappy": ["swappy"],
        "magick": ["ImageMagick"],
        "kitty": ["kitty"],
        "wl-copy": ["wl-clipboard"],
        "brightnessctl": ["brightnessctl"],
        "wpctl": ["wireplumber"],
        "nmcli": ["NetworkManager"],
        "bluetoothctl": ["bluez"],
        "hypridle": ["hypridle"],
        "hyprsunset": ["hyprsunset"],
        "curl": ["curl"],
        "jq": ["jq"],
    },
    "debian": {
        "awww": ["swww"],
        "wallust": ["wallust"],
        "cliphist": ["cliphist"],
        "cava": ["cava"],
        "grim": ["grim", "slurp"],
        "swappy": ["swappy"],
        "magick": ["imagemagick"],
        "kitty": ["kitty"],
        "wl-copy": ["wl-clipboard"],
        "brightnessctl": ["brightnessctl"],
        "wpctl": ["wireplumber"],
        "nmcli": ["network-manager"],
        "bluetoothctl": ["bluez"],
        "hypridle": ["hypridle"],
        "hyprsunset": ["hyprsunset"],
        "curl": ["curl"],
        "jq": ["jq"],
    },
    "opensuse": {
        "awww": ["swww"],
        "wallust": ["wallust"],
        "cliphist": ["cliphist"],
        "cava": ["cava"],
        "grim": ["grim", "slurp"],
        "swappy": ["swappy"],
        "magick": ["ImageMagick"],
        "kitty": ["kitty"],
        "wl-copy": ["wl-clipboard"],
        "brightnessctl": ["brightnessctl"],
        "wpctl": ["wireplumber"],
        "nmcli": ["NetworkManager"],
        "bluetoothctl": ["bluez"],
        "hypridle": ["hypridle"],
        "hyprsunset": ["hyprsunset"],
        "curl": ["curl"],
        "jq": ["jq"],
    },
    "void": {
        "awww": ["swww"],
        "wallust": ["wallust"],
        "cliphist": ["cliphist"],
        "cava": ["cava"],
        "grim": ["grim", "slurp"],
        "swappy": ["swappy"],
        "magick": ["ImageMagick"],
        "kitty": ["kitty"],
        "wl-copy": ["wl-clipboard"],
        "brightnessctl": ["brightnessctl"],
        "wpctl": ["wireplumber"],
        "nmcli": ["NetworkManager"],
        "bluetoothctl": ["bluez"],
        "hypridle": ["hypridle"],
        "hyprsunset": ["hyprsunset"],
        "curl": ["curl"],
        "jq": ["jq"],
    },
}


def detect_distro():
    os_release = {}
    if os.path.isfile("/etc/os-release"):
        with open("/etc/os-release", "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    k, v = line.split("=", 1)
                    os_release[k] = v.strip().strip('"').strip("'")
    distro_id = os_release.get("ID", "").lower()
    id_like = os_release.get("ID_LIKE", "").lower()
    if distro_id in ("arch", "cachyos", "endeavouros", "manjaro", "garuda", "artix") or "arch" in id_like:
        return "arch"
    if distro_id in ("fedora", "nobara") or "fedora" in id_like or "rhel" in id_like:
        return "fedora"
    if distro_id in ("ubuntu", "debian", "pop", "linuxmint", "zorin", "elementary") or "debian" in id_like or "ubuntu" in id_like:
        return "debian"
    if distro_id.startswith("opensuse") or "suse" in id_like:
        return "opensuse"
    if distro_id == "void":
        return "void"
    return "unknown"


def has_nerd_font():
    if shutil.which("fc-list"):
        try:
            out = subprocess.check_output(["fc-list", ":", "family"], text=True, stderr=subprocess.DEVNULL)
            if re.search(r"Nerd ?Font| NF(,|$)| NFM(,|$)| NFP(,|$)", out, re.IGNORECASE | re.MULTILINE):
                return True
        except Exception:
            pass
    data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
    for d in (os.path.join(data_home, "fonts"), "/usr/share/fonts", "/usr/local/share/fonts"):
        if not os.path.isdir(d):
            continue
        for root, _, files in os.walk(d):
            for fname in files:
                if "nerd" in fname.lower():
                    return True
    return False


def install_nerd_font_fallback():
    data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
    font_dir = os.path.join(data_home, "fonts", "JetBrainsMonoNerdFont")
    url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    print(f"Downloading JetBrainsMono Nerd Font to {font_dir}...", flush=True)
    os.makedirs(font_dir, exist_ok=True)
    tmp_tar = os.path.join(font_dir, "JetBrainsMono.tar.xz")
    urllib.request.urlretrieve(url, tmp_tar)
    with tarfile.open(tmp_tar, "r:xz") as tf:
        tf.extractall(font_dir)
    os.remove(tmp_tar)
    if shutil.which("fc-cache"):
        subprocess.run(["fc-cache", "-fv", font_dir], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("Installed JetBrainsMono Nerd Font.", flush=True)


def _has_sys_entries(path):
    try:
        return os.path.isdir(path) and len(os.listdir(path)) > 0
    except OSError:
        return False


def cmd_status():
    tools = {}
    for key, bins in TOOL_CHECKS:
        if key in TOOL_REQUIRE_ALL:
            tools[key] = all(shutil.which(b) is not None for b in bins)
        else:
            tools[key] = any(shutil.which(b) is not None for b in bins)
    tools["nerd-font"] = has_nerd_font()
    print(json.dumps({
        "done": os.path.isfile(MARKER_FILE),
        "tools": tools,
        "hardware": {
            "bluetooth": _has_sys_entries("/sys/class/bluetooth"),
            "backlight": _has_sys_entries("/sys/class/backlight"),
        },
    }))


def cmd_apply_preset(preset_name):
    if preset_name not in ("laptop", "pc", "gaming", "minimal"):
        print(json.dumps({"ok": False, "error": f"Unknown preset: {preset_name}"}))
        sys.exit(1)

    os.makedirs(CONFIGS_DIR, exist_ok=True)
    for module, target_name in MODULE_TARGETS.items():
        preset_path = os.path.join(PRESETS_DIR, module, f"{preset_name}.json")
        target_path = os.path.join(CONFIGS_DIR, target_name)
        if not os.path.isfile(preset_path):
            continue
        current = {}
        if os.path.isfile(target_path):
            try:
                with open(target_path, "r", encoding="utf-8") as f:
                    current = json.load(f)
            except Exception:
                current = {}
        with open(preset_path, "r", encoding="utf-8") as f:
            preset = json.load(f)
        current.update(preset)
        tmp_path = target_path + ".tmp"
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(current, f, indent=2)
            f.write("\n")
        os.replace(tmp_path, target_path)

    print(json.dumps({"ok": True, "preset": preset_name}))


def cmd_mark_done():
    os.makedirs(CONFIGS_DIR, exist_ok=True)
    with open(MARKER_FILE, "w", encoding="utf-8") as f:
        f.write(datetime.now(timezone.utc).isoformat() + "\n")
    print(json.dumps({"ok": True}))


def _is_proc_running(pattern):
    return subprocess.run(
        ["pgrep", "-f", pattern],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    ).returncode == 0


def _start_detached(cmd_list):
    subprocess.Popen(
        cmd_list,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def _add_to_hypr_autostart(entries):
    """Add missing daemon commands to Hyprland AutoStart.lua or hyprland.conf."""
    if not entries:
        return
    hypr_dir = os.path.join(os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")), "hypr")
    hypr_lua = os.path.join(hypr_dir, "hyprland.lua")
    autostart_lua = os.path.join(hypr_dir, "Configs", "AutoStart.lua")
    hypr_conf = os.path.join(hypr_dir, "hyprland.conf")

    if os.path.isfile(hypr_lua):
        os.makedirs(os.path.dirname(autostart_lua), exist_ok=True)
        txt = ""
        if os.path.isfile(autostart_lua):
            with open(autostart_lua, "r", encoding="utf-8") as f:
                txt = f.read()
        missing_lines = [cmd for needle, cmd in entries if needle not in txt]
        if not missing_lines:
            return
        m = re.search(r'hl\.on\(\s*["\']hyprland\.start["\']\s*,\s*function\s*\(\)\s*\n?', txt)
        add_block = "".join(f'    hl.exec_cmd("{cmd}")\n' for cmd in missing_lines)
        if m:
            idx = m.end()
            txt = txt[:idx] + add_block + txt[idx:]
        else:
            txt = txt.rstrip() + ('\n\n' if txt.strip() else '') + 'hl.on("hyprland.start", function()\n' + add_block + 'end)\n'
        with open(autostart_lua, "w", encoding="utf-8") as f:
            f.write(txt)
        print(f"Added daemon(s) to {autostart_lua}", flush=True)
    elif os.path.isfile(hypr_conf):
        with open(hypr_conf, "r", encoding="utf-8") as f:
            txt = f.read()
        missing_lines = [cmd for needle, cmd in entries if needle not in txt]
        if not missing_lines:
            return
        with open(hypr_conf, "a", encoding="utf-8") as f:
            f.write("\n" + "".join(f"exec-once = {cmd}\n" for cmd in missing_lines))
        print(f"Added daemon(s) to {hypr_conf}", flush=True)


def ensure_daemons_started_and_autostart(keys):
    autostart_entries = []

    if "awww" in keys:
        if shutil.which("awww-daemon"):
            autostart_entries.append(("awww-daemon", "awww-daemon --format xrgb"))
            if not _is_proc_running(r"^awww-daemon"):
                _start_detached(["awww-daemon", "--format", "xrgb"])
                print("Started awww-daemon.", flush=True)
        elif shutil.which("swww-daemon"):
            autostart_entries.append(("swww-daemon", "swww-daemon"))
            if not _is_proc_running(r"^swww-daemon"):
                _start_detached(["swww-daemon"])
                print("Started swww-daemon.", flush=True)

    if "cliphist" in keys and shutil.which("cliphist") and shutil.which("wl-paste"):
        autostart_entries.append(("cliphist store", "wl-paste --type text --watch cliphist store"))
        autostart_entries.append(("type image --watch cliphist", "wl-paste --type image --watch cliphist store"))
        if not _is_proc_running(r"wl-paste.*cliphist"):
            _start_detached(["wl-paste", "--type", "text", "--watch", "cliphist", "store"])
            _start_detached(["wl-paste", "--type", "image", "--watch", "cliphist", "store"])
            print("Started cliphist wl-paste watchers.", flush=True)

    if "hypridle" in keys and shutil.which("hypridle"):
        autostart_entries.append(("hypridle", "hypridle"))
        if not _is_proc_running(r"^hypridle"):
            _start_detached(["hypridle"])
            print("Started hypridle.", flush=True)

    _add_to_hypr_autostart(autostart_entries)


def cmd_install_tools(keys):
    distro = detect_distro()
    pkg_map = DISTRO_PKG_MAP.get(distro, {})
    pkgs = []
    need_nerd_font_fallback = False

    for k in keys:
        if k == "nerd-font" and "nerd-font" not in pkg_map:
            need_nerd_font_fallback = True
            continue
        mapped = pkg_map.get(k, [k])
        for pkg in (mapped if isinstance(mapped, list) else [mapped]):
            if pkg not in pkgs:
                pkgs.append(pkg)

    rc = 0
    if pkgs:
        if distro == "arch":
            aur_helper = shutil.which("paru") or shutil.which("yay")
            if aur_helper:
                cmd = [aur_helper, "--sudo", "pkexec", "-S", "--noconfirm", "--needed", *pkgs]
            else:
                cmd = ["pkexec", "pacman", "-S", "--noconfirm", "--needed", *pkgs]
        elif distro == "fedora":
            cmd = ["pkexec", "dnf", "install", "-y", *pkgs]
        elif distro == "debian":
            cmd = ["pkexec", "apt-get", "install", "-y", *pkgs]
        elif distro == "opensuse":
            cmd = ["pkexec", "zypper", "install", "-y", *pkgs]
        elif distro == "void":
            cmd = ["pkexec", "xbps-install", "-Sy", *pkgs]
        else:
            print(f"Unsupported distro '{distro}'. Please install manually: {' '.join(pkgs)}", flush=True)
            sys.exit(1)

        print(f"$ {' '.join(cmd)}", flush=True)
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
        if proc.stdout:
            for line in proc.stdout:
                print(line.rstrip("\n"), flush=True)
        rc = proc.wait()

    if rc == 0 and need_nerd_font_fallback:
        try:
            install_nerd_font_fallback()
        except Exception as e:
            print(f"Failed to install Nerd Font fallback: {e}", flush=True)
            rc = 1

    if rc == 0:
        ensure_daemons_started_and_autostart(keys)
        print("Done.", flush=True)
    else:
        print(f"Exited with code {rc}.", flush=True)
    sys.exit(rc)


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else ""
    if action == "status":
        cmd_status()
    elif action == "apply_preset" and len(sys.argv) > 2:
        cmd_apply_preset(sys.argv[2])
    elif action == "mark_done":
        cmd_mark_done()
    elif action == "install_tools" and len(sys.argv) > 2:
        cmd_install_tools(sys.argv[2:])
    else:
        print(json.dumps({"ok": False, "error": "Usage: setup_wizard.py [status|apply_preset <name>|mark_done|install_tools <key>...]"}))
        sys.exit(1)


if __name__ == "__main__":
    main()
