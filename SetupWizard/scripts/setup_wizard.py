#!/usr/bin/env python3
"""Helper script for the canting-shell first-run SetupWizard."""

import json
import os
import shutil
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
]


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


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else ""
    if action == "status":
        cmd_status()
    elif action == "apply_preset" and len(sys.argv) > 2:
        cmd_apply_preset(sys.argv[2])
    elif action == "mark_done":
        cmd_mark_done()
    else:
        print(json.dumps({"ok": False, "error": "Usage: setup_wizard.py [status|apply_preset <name>|mark_done]"}))
        sys.exit(1)


if __name__ == "__main__":
    main()
