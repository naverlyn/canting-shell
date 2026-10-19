#!/usr/bin/env python3
import sys
import os
import subprocess
import json
import re

THUMB_DIR = "/tmp/cliphist_thumbs"

def get_list(limit=150, out_file=None):
    os.makedirs(THUMB_DIR, exist_ok=True)
    try:
        raw_out = subprocess.check_output(["cliphist", "list"], text=True, errors="replace")
    except Exception as e:
        data = []
        if out_file:
            with open(out_file, "w", encoding="utf-8") as f:
                json.dump(data, f)
        else:
            print(json.dumps(data))
        return

    lines = raw_out.strip().split("\n")
    items = []
    thumb_gen_count = 0

    for line in lines:
        if not line:
            continue
        parts = line.split("\t", 1)
        cid = parts[0].strip()
        preview = parts[1] if len(parts) > 1 else ""

        cat = "text"
        img_meta = ""
        is_binary = False
        thumb_path = ""

        # Binary image detection
        if preview.startswith("[[ binary data"):
            cat = "image"
            is_binary = True
            m = re.search(r'\[\[ binary data ([\d\.]+\s*\w+) (\w+) (\d+x\d+) \]\]', preview)
            if m:
                img_meta = f"{m.group(2).upper()} · {m.group(3)} · {m.group(1)}"
            else:
                img_meta = "Image"

            thumb_path = f"{THUMB_DIR}/{cid}.png"
            if not os.path.exists(thumb_path) and thumb_gen_count < 30:
                try:
                    p = subprocess.Popen(["cliphist", "decode"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
                    stdout, _ = p.communicate(input=line.encode('utf-8'))
                    if p.returncode == 0 and len(stdout) > 0:
                        with open(thumb_path, "wb") as f:
                            f.write(stdout)
                    thumb_gen_count += 1
                except Exception:
                    pass
        elif re.match(r'^https?://', preview.strip()):
            cat = "link"
        elif re.match(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{3}|[0-9a-fA-F]{8})$', preview.strip()):
            cat = "color"
        elif any(k in preview for k in ['def ', 'function', 'const ', 'class ', 'import ', '=>', '{', '</', '/>', 'return ']):
            cat = "code"

        items.append({
            "id": cid,
            "preview": preview[:500],
            "category": cat,
            "imgMeta": img_meta,
            "isBinary": is_binary,
            "thumbPath": thumb_path if os.path.exists(thumb_path) else "",
            "raw": line
        })

        if limit > 0 and len(items) >= limit:
            break

    if out_file:
        tmp = out_file + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(items, f)
        os.replace(tmp, out_file)
    else:
        print(json.dumps(items))

def copy_item(cid):
    try:
        out = subprocess.check_output(["cliphist", "list"], text=True, errors="replace")
    except Exception:
        sys.exit(1)

    target_line = None
    for line in out.strip().split("\n"):
        if line.startswith(f"{cid}\t") or line.strip() == cid:
            target_line = line
            break

    if not target_line:
        sys.exit(1)

    try:
        p1 = subprocess.Popen(["cliphist", "decode"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        decoded, _ = p1.communicate(input=target_line.encode('utf-8'))
        if p1.returncode != 0 or len(decoded) == 0:
            sys.exit(1)

        p2 = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE)
        p2.communicate(input=decoded)
        if p2.returncode != 0:
            sys.exit(1)
        sys.exit(0)
    except Exception as e:
        sys.exit(1)

def delete_item(cid):
    try:
        out = subprocess.check_output(["cliphist", "list"], text=True, errors="replace")
    except Exception:
        sys.exit(1)

    for line in out.strip().split("\n"):
        if line.startswith(f"{cid}\t") or line.strip() == cid:
            p = subprocess.Popen(["cliphist", "delete"], stdin=subprocess.PIPE)
            p.communicate(input=line.encode('utf-8'))
            thumb_path = f"{THUMB_DIR}/{cid}.png"
            if os.path.exists(thumb_path):
                try:
                    os.remove(thumb_path)
                except Exception:
                    pass
            sys.exit(0)
    sys.exit(1)

def wipe_all():
    subprocess.run(["cliphist", "wipe"], check=False)
    if os.path.exists(THUMB_DIR):
        for f in os.listdir(THUMB_DIR):
            try:
                os.remove(os.path.join(THUMB_DIR, f))
            except Exception:
                pass
    sys.exit(0)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: clip_service.py [list|copy|delete|wipe] [args...]")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "list":
        limit = int(sys.argv[2]) if len(sys.argv) > 2 else 150
        out_f = sys.argv[3] if len(sys.argv) > 3 else None
        get_list(limit, out_f)
    elif cmd == "copy" and len(sys.argv) > 2:
        copy_item(sys.argv[2])
    elif cmd == "delete" and len(sys.argv) > 2:
        delete_item(sys.argv[2])
    elif cmd == "wipe":
        wipe_all()
    else:
        sys.exit(1)
