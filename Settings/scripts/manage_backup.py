#!/usr/bin/env python3
"""
manage_backup.py - Configuration Backup and Restore Manager for Quickshell
Handles snapshot creation, selective and full restoration, export, import,
and safe defaults reset for bar, notifications, osd, control center, etc.
"""

import os
import sys
import json
import time
import shutil
import tarfile
from datetime import datetime

BASE_DIR = os.path.expanduser("~/.config/quickshell")
SNAPSHOTS_DIR = os.path.join(BASE_DIR, "backups", "snapshots")

MODULE_FILES = {
    "bar": ["bar_config.json"],
    "notifications": ["notifications_config.json"],
    "osd": ["osd_config.json"],
    "controlcenter": ["control_center_config.json"],
    "appearance": ["theme.conf", "qml_color.json", "ThemeSwitcher/wallpaper-theme.json"],
    "wallpaper": ["wallpaper.conf", "wallpaper_sync.conf", "wallpaper_dirs.conf"],
}

DEFAULT_CONFIGS = {
    "notifications_config.json": {
        "doNotDisturb": False,
        "toastPosition": "top-right",
        "toastMarginX": 10,
        "toastMarginY": 10
    },
    "osd_config.json": {
        "position": "right",
        "orientation": "auto",
        "marginX": 16,
        "marginY": 0,
        "timeoutMs": 1500
    },
    "theme.conf": "10\n",
    "wallpaper_sync.conf": "true\n",
}

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def atomic_write(filepath, content):
    ensure_dir(os.path.dirname(filepath))
    tmp = filepath + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp, filepath)

def format_size(bytes_num):
    for unit in ['B', 'KB', 'MB', 'GB']:
        if bytes_num < 1024.0:
            return f"{bytes_num:.1f} {unit}" if unit != 'B' else f"{bytes_num} B"
        bytes_num /= 1024.0
    return f"{bytes_num:.1f} TB"

def list_snapshots():
    ensure_dir(SNAPSHOTS_DIR)
    snapshots = []
    if not os.path.exists(SNAPSHOTS_DIR):
        return json.dumps(snapshots)

    for item in os.listdir(SNAPSHOTS_DIR):
        item_path = os.path.join(SNAPSHOTS_DIR, item)
        if not os.path.isdir(item_path):
            continue
        meta_file = os.path.join(item_path, "metadata.json")
        meta = None
        if os.path.exists(meta_file):
            try:
                with open(meta_file, "r", encoding="utf-8") as f:
                    meta = json.load(f)
            except Exception:
                pass

        total_size = 0
        file_list = []
        for root_dir, _, files in os.walk(item_path):
            for fname in files:
                if fname == "metadata.json":
                    continue
                fp = os.path.join(root_dir, fname)
                rel_p = os.path.relpath(fp, item_path)
                file_list.append(rel_p)
                try:
                    total_size += os.path.getsize(fp)
                except OSError:
                    pass

        if not meta:
            meta = {
                "id": item,
                "name": item.replace("_", " ").title(),
                "timestamp": int(os.path.getmtime(item_path)),
                "dateFormatted": datetime.fromtimestamp(os.path.getmtime(item_path)).strftime("%Y-%m-%d %H:%M"),
                "type": "imported" if "import" in item else "manual",
                "modules": ["all"],
                "description": ""
            }

        meta["id"] = item
        meta["sizeBytes"] = total_size
        meta["sizeFormatted"] = format_size(total_size)
        meta["files"] = file_list
        if "dateFormatted" not in meta and "timestamp" in meta:
            meta["dateFormatted"] = datetime.fromtimestamp(meta["timestamp"]).strftime("%Y-%m-%d %H:%M")
        snapshots.append(meta)

    # Sort descending by timestamp
    snapshots.sort(key=lambda s: s.get("timestamp", 0), reverse=True)
    return json.dumps(snapshots, indent=2)

def create_snapshot(name, modules_csv="all", backup_type="manual", description=""):
    ensure_dir(SNAPSHOTS_DIR)
    now = time.time()
    ts_str = datetime.fromtimestamp(now).strftime("%Y%m%d_%H%M%S")
    
    if backup_type == "auto_pre_restore":
        snap_id = f"auto_pre_restore_{ts_str}"
        default_name = f"Safety Backup ({datetime.fromtimestamp(now).strftime('%H:%M:%S')})"
    elif backup_type == "auto_pre_reset":
        snap_id = f"auto_pre_reset_{ts_str}"
        default_name = f"Pre-Reset Safety ({datetime.fromtimestamp(now).strftime('%H:%M:%S')})"
    else:
        snap_id = f"backup_{ts_str}"
        default_name = f"Backup {datetime.fromtimestamp(now).strftime('%Y-%m-%d %H:%M')}"

    final_name = name.strip() if name and name.strip() else default_name
    snap_dir = os.path.join(SNAPSHOTS_DIR, snap_id)
    ensure_dir(snap_dir)

    selected_modules = []
    if modules_csv == "all" or not modules_csv.strip():
        selected_modules = list(MODULE_FILES.keys())
    else:
        parts = [p.strip().lower() for p in modules_csv.split(",") if p.strip()]
        for p in parts:
            if p in MODULE_FILES:
                selected_modules.append(p)
            elif p == "all":
                selected_modules = list(MODULE_FILES.keys())
                break

    copied_files = []
    total_size = 0

    for mod in selected_modules:
        rel_files = MODULE_FILES.get(mod, [])
        for rel_f in rel_files:
            src_path = os.path.join(BASE_DIR, rel_f)
            if os.path.exists(src_path):
                dest_path = os.path.join(snap_dir, rel_f)
                ensure_dir(os.path.dirname(dest_path))
                shutil.copy2(src_path, dest_path)
                copied_files.append(rel_f)
                try:
                    total_size += os.path.getsize(dest_path)
                except OSError:
                    pass

    metadata = {
        "id": snap_id,
        "name": final_name,
        "timestamp": int(now),
        "dateFormatted": datetime.fromtimestamp(now).strftime("%Y-%m-%d %H:%M"),
        "type": backup_type,
        "modules": selected_modules,
        "files": copied_files,
        "sizeBytes": total_size,
        "sizeFormatted": format_size(total_size),
        "description": description
    }

    meta_file = os.path.join(snap_dir, "metadata.json")
    with open(meta_file, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    return json.dumps({
        "success": True,
        "id": snap_id,
        "name": final_name,
        "filesCount": len(copied_files),
        "sizeFormatted": format_size(total_size),
        "message": f"Backup '{final_name}' created successfully with {len(copied_files)} files."
    })

def restore_snapshot(snap_id, modules_csv="all"):
    snap_dir = os.path.join(SNAPSHOTS_DIR, snap_id)
    if not os.path.isdir(snap_dir):
        return json.dumps({
            "success": False,
            "message": f"Snapshot '{snap_id}' does not exist."
        })

    # Read snapshot metadata if available
    meta_file = os.path.join(snap_dir, "metadata.json")
    meta = {}
    if os.path.exists(meta_file):
        try:
            with open(meta_file, "r", encoding="utf-8") as f:
                meta = json.load(f)
        except Exception:
            pass

    # 1. Take safety backup before overwriting!
    create_snapshot(
        name=f"Safety Backup (Before restoring {meta.get('name', snap_id)})",
        modules_csv="all",
        backup_type="auto_pre_restore",
        description=f"Automatic safety backup created before restoring snapshot {snap_id}"
    )

    # 2. Determine which files to restore
    selected_modules = []
    if modules_csv == "all" or not modules_csv.strip():
        selected_modules = list(MODULE_FILES.keys())
    else:
        parts = [p.strip().lower() for p in modules_csv.split(",") if p.strip()]
        for p in parts:
            if p in MODULE_FILES:
                selected_modules.append(p)
            elif p == "all":
                selected_modules = list(MODULE_FILES.keys())
                break

    target_rel_files = set()
    for mod in selected_modules:
        for f in MODULE_FILES.get(mod, []):
            target_rel_files.add(f)

    restored_files = []
    for root_dir, _, files in os.walk(snap_dir):
        for fname in files:
            if fname == "metadata.json":
                continue
            src_fp = os.path.join(root_dir, fname)
            rel_p = os.path.relpath(src_fp, snap_dir)

            if rel_p in target_rel_files:
                dest_fp = os.path.join(BASE_DIR, rel_p)
                ensure_dir(os.path.dirname(dest_fp))
                # Atomic write
                try:
                    with open(src_fp, "rb") as sf:
                        content = sf.read()
                    tmp_dest = dest_fp + ".tmp"
                    with open(tmp_dest, "wb") as df:
                        df.write(content)
                    os.replace(tmp_dest, dest_fp)
                    restored_files.append(rel_p)
                except Exception as e:
                    return json.dumps({
                        "success": False,
                        "message": f"Failed restoring {rel_p}: {str(e)}"
                    })

    return json.dumps({
        "success": True,
        "restored": restored_files,
        "message": f"Restored {len(restored_files)} configuration files from '{meta.get('name', snap_id)}'. Settings applied immediately!"
    })

def delete_snapshot(snap_id):
    snap_dir = os.path.join(SNAPSHOTS_DIR, snap_id)
    if not os.path.isdir(snap_dir):
        return json.dumps({"success": False, "message": f"Snapshot '{snap_id}' does not exist."})
    try:
        shutil.rmtree(snap_dir)
        return json.dumps({"success": True, "message": f"Deleted backup '{snap_id}'."})
    except Exception as e:
        return json.dumps({"success": False, "message": f"Error deleting backup: {str(e)}"})

def export_snapshot(snap_id, export_path=None):
    snap_dir = os.path.join(SNAPSHOTS_DIR, snap_id)
    if not os.path.isdir(snap_dir):
        return json.dumps({"success": False, "message": f"Snapshot '{snap_id}' does not exist."})

    downloads_dir = os.path.expanduser("~/Downloads")
    if not export_path or not export_path.strip():
        if os.path.isdir(downloads_dir):
            export_path = os.path.join(downloads_dir, f"quickshell_{snap_id}.tar.gz")
        else:
            export_path = os.path.join(BASE_DIR, "backups", f"quickshell_{snap_id}.tar.gz")

    ensure_dir(os.path.dirname(export_path))
    try:
        with tarfile.open(export_path, "w:gz") as tar:
            tar.add(snap_dir, arcname=os.path.basename(snap_dir))
        return json.dumps({
            "success": True,
            "archivePath": export_path,
            "message": f"Exported archive successfully to: {export_path}"
        })
    except Exception as e:
        return json.dumps({"success": False, "message": f"Failed to export archive: {str(e)}"})

def import_archive(archive_path, custom_name=None):
    archive_path = os.path.expanduser(archive_path.strip())
    if not os.path.isfile(archive_path):
        return json.dumps({"success": False, "message": f"Archive file '{archive_path}' not found."})

    ensure_dir(SNAPSHOTS_DIR)
    now = time.time()
    ts_str = datetime.fromtimestamp(now).strftime("%Y%m%d_%H%M%S")
    target_id = f"backup_imported_{ts_str}"
    target_dir = os.path.join(SNAPSHOTS_DIR, target_id)
    ensure_dir(target_dir)

    try:
        with tarfile.open(archive_path, "r:*") as tar:
            # Check top level
            members = tar.getmembers()
            # If all files share a common root folder, strip it
            common_root = None
            first_parts = [m.name.split("/")[0] for m in members if "/" in m.name]
            if first_parts and all(p == first_parts[0] for p in first_parts):
                common_root = first_parts[0]

            for member in members:
                # Security: prevent directory traversal
                if os.path.isabs(member.name) or ".." in member.name:
                    continue
                name = member.name
                if common_root and name.startswith(common_root + "/"):
                    name = name[len(common_root) + 1:]
                if not name:
                    continue
                
                dest_f = os.path.join(target_dir, name)
                if member.isdir():
                    ensure_dir(dest_f)
                else:
                    ensure_dir(os.path.dirname(dest_f))
                    f_obj = tar.extractfile(member)
                    if f_obj:
                        with open(dest_f, "wb") as out_f:
                            out_f.write(f_obj.read())

        # Ensure metadata exists
        meta_file = os.path.join(target_dir, "metadata.json")
        meta = {}
        if os.path.exists(meta_file):
            try:
                with open(meta_file, "r", encoding="utf-8") as mf:
                    meta = json.load(mf)
            except Exception:
                pass
        
        meta["id"] = target_id
        if custom_name and custom_name.strip():
            meta["name"] = custom_name.strip()
        elif "name" not in meta or not meta["name"]:
            meta["name"] = f"Imported Backup ({datetime.fromtimestamp(now).strftime('%Y-%m-%d %H:%M')})"
        meta["timestamp"] = int(now)
        meta["dateFormatted"] = datetime.fromtimestamp(now).strftime("%Y-%m-%d %H:%M")
        meta["type"] = "imported"
        
        with open(meta_file, "w", encoding="utf-8") as mf:
            json.dump(meta, mf, indent=2)

        return json.dumps({
            "success": True,
            "id": target_id,
            "name": meta["name"],
            "message": f"Successfully imported '{meta['name']}'!"
        })
    except Exception as e:
        if os.path.exists(target_dir):
            shutil.rmtree(target_dir)
        return json.dumps({"success": False, "message": f"Import failed: {str(e)}"})

def reset_defaults(modules_csv="all"):
    # Take auto safety backup first
    create_snapshot(
        name="Safety Backup (Before Factory Reset)",
        modules_csv="all",
        backup_type="auto_pre_reset",
        description="Automatic safety snapshot before restoring default configuration"
    )

    selected_modules = []
    if modules_csv == "all" or not modules_csv.strip():
        selected_modules = list(MODULE_FILES.keys())
    else:
        parts = [p.strip().lower() for p in modules_csv.split(",") if p.strip()]
        for p in parts:
            if p in MODULE_FILES:
                selected_modules.append(p)
            elif p == "all":
                selected_modules = list(MODULE_FILES.keys())
                break

    reset_items = []
    if "notifications" in selected_modules:
        atomic_write(
            os.path.join(BASE_DIR, "notifications_config.json"),
            json.dumps(DEFAULT_CONFIGS["notifications_config.json"], indent=2) + "\n"
        )
        reset_items.append("Notifications")

    if "osd" in selected_modules:
        atomic_write(
            os.path.join(BASE_DIR, "osd_config.json"),
            json.dumps(DEFAULT_CONFIGS["osd_config.json"], indent=2) + "\n"
        )
        reset_items.append("OSD")

    if "bar" in selected_modules:
        default_bar = {
            "barVisible": True,
            "position": "top",
            "barHeight": 32,
            "floating": False,
            "barOpacity": 0.85,
            "pillRadius": 10,
            "pillOpacity": 1.0,
            "hidePill": False,
            "activeStyle": "underline",
            "allMonitors": True,
            "displayTarget": "all",
            "secondaryPosition": "top",
            "secondaryMode": "custom",
            "blankOnSecondary": False,
            "secondaryPanels": [
                ["workspaces"],
                ["windowTitle"],
                ["weather", "clock"]
            ],
            "innerCorners": True,
            "fluidCards": True,
            "barBorder": True,
            "barBorderWidth": 1,
            "barBorderColor": "",
            "screenBorder": False,
            "screenBorderThickness": 4,
            "screenBorderColor": "",
            "bars": [
                {
                    "id": "bar_1",
                    "name": "Primary Bar",
                    "enabled": True,
                    "position": "top",
                    "barHeight": 32,
                    "floating": False,
                    "barOpacity": 0.85,
                    "pillRadius": 10,
                    "pillOpacity": 1.0,
                    "hidePill": False,
                    "allMonitors": True,
                    "displayTarget": "all",
                    "secondaryPosition": "top",
                    "secondaryMode": "custom",
                    "blankOnSecondary": False,
                    "secondaryPanels": [
                        ["workspaces"],
                        ["windowTitle"],
                        ["weather", "clock"]
                    ],
                    "innerCorners": True,
                    "fluidCards": True,
                    "barBorder": True,
                    "barBorderWidth": 1,
                    "barBorderColor": "",
                    "panels": [
                        ["appGrid", "globalMenu", "cpu", "temp", "memory", "disk", "network"],
                        ["windowTitle"],
                        ["tray", "clock", "workspaces", "weather", "idleInhibitor", "controlCenter"]
                    ]
                }
            ],
            "panels": [
                ["appGrid", "globalMenu", "cpu", "temp", "memory", "disk", "network"],
                ["windowTitle"],
                ["tray", "clock", "workspaces", "weather", "idleInhibitor", "controlCenter"]
            ]
        }
        atomic_write(
            os.path.join(BASE_DIR, "bar_config.json"),
            json.dumps(default_bar, indent=2) + "\n"
        )
        reset_items.append("Bar")

    return json.dumps({
        "success": True,
        "reset": reset_items,
        "message": f"Successfully reset {', '.join(reset_items)} to default configuration!"
    })

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: manage_backup.py <list|create|restore|delete|export|import|reset_defaults> [args]"}))
        sys.exit(1)

    cmd = sys.argv[1].lower()

    if cmd == "list":
        print(list_snapshots())

    elif cmd == "create":
        name = sys.argv[2] if len(sys.argv) > 2 else ""
        modules = sys.argv[3] if len(sys.argv) > 3 else "all"
        desc = sys.argv[4] if len(sys.argv) > 4 else ""
        print(create_snapshot(name, modules, "manual", desc))

    elif cmd == "restore":
        if len(sys.argv) < 3:
            print(json.dumps({"success": False, "message": "Missing snapshot ID."}))
            sys.exit(1)
        snap_id = sys.argv[2]
        modules = sys.argv[3] if len(sys.argv) > 3 else "all"
        print(restore_snapshot(snap_id, modules))

    elif cmd == "delete":
        if len(sys.argv) < 3:
            print(json.dumps({"success": False, "message": "Missing snapshot ID."}))
            sys.exit(1)
        snap_id = sys.argv[2]
        print(delete_snapshot(snap_id))

    elif cmd == "export":
        if len(sys.argv) < 3:
            print(json.dumps({"success": False, "message": "Missing snapshot ID."}))
            sys.exit(1)
        snap_id = sys.argv[2]
        out_path = sys.argv[3] if len(sys.argv) > 3 else None
        print(export_snapshot(snap_id, out_path))

    elif cmd == "import":
        if len(sys.argv) < 3:
            print(json.dumps({"success": False, "message": "Missing archive path."}))
            sys.exit(1)
        archive_path = sys.argv[2]
        name = sys.argv[3] if len(sys.argv) > 3 else None
        print(import_archive(archive_path, name))

    elif cmd == "reset_defaults":
        modules = sys.argv[2] if len(sys.argv) > 2 else "all"
        print(reset_defaults(modules))

    else:
        print(json.dumps({"error": f"Unknown command '{cmd}'"}))
        sys.exit(1)

if __name__ == "__main__":
    main()

