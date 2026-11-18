#!/usr/bin/env python3
"""Helper script for the canting-shell first-run SetupWizard."""

import json
import os
import shutil
import subprocess
import sys
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
    ("grim", ("grim",)),
    ("magick", ("magick",)),
    ("kitty", ("kitty", "alacritty", "foot", "wezterm", "ghostty", "konsole", "gnome-terminal")),
]

DISTRO_PKG_MAP = {
    "arch": {
        "awww": "awww",
        "wallust": "wallust",
        "cliphist": "cliphist",
        "cava": "cava",
        "grim": "grim",
        "magick": "imagemagick",
        "kitty": "kitty",
    },
    "fedora": {
        "awww": "swww",
        "wallust": "wallust",
        "cliphist": "cliphist",
        "cava": "cava",
        "grim": "grim",
        "magick": "ImageMagick",
        "kitty": "kitty",
    },
    "debian": {
        "awww": "swww",
        "wallust": "wallust",
        "cliphist": "cliphist",
        "cava": "cava",
        "grim": "grim",
        "magick": "imagemagick",
        "kitty": "kitty",
    },
    "opensuse": {
        "awww": "swww",
        "wallust": "wallust",
        "cliphist": "cliphist",
        "cava": "cava",
        "grim": "grim",
        "magick": "ImageMagick",
        "kitty": "kitty",
    },
    "void": {
        "awww": "swww",
        "wallust": "wallust",
        "cliphist": "cliphist",
        "cava": "cava",
        "grim": "grim",
        "magick": "ImageMagick",
        "kitty": "kitty",
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


def cmd_status():
    tools = {}
    for key, bins in TOOL_CHECKS:
        tools[key] = any(shutil.which(b) is not None for b in bins)
    print(json.dumps({
        "done": os.path.isfile(MARKER_FILE),
        "tools": tools,
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


def cmd_install_tools(keys):
    distro = detect_distro()
    pkg_map = DISTRO_PKG_MAP.get(distro, {})
    pkgs = []
    for k in keys:
        pkg = pkg_map.get(k, k)
        if pkg not in pkgs:
            pkgs.append(pkg)

    if not pkgs:
        print("No packages specified.", flush=True)
        sys.exit(1)

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
    if rc == 0:
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
