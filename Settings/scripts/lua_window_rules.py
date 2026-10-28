#!/usr/bin/env python3
"""
lua_window_rules.py — Read, toggle, add, edit, and delete Hyprland Window & Layer rules in Lua.

Operates on ~/.config/hypr/Configs/WindowWorkspaces.lua (and custom_window_rules.lua if present).

Usage:
    lua_window_rules.py list
    lua_window_rules.py toggle <name> <true|false>
    lua_window_rules.py set_opacity <name> <active_val> <inactive_val>
    lua_window_rules.py save <json_payload>
    lua_window_rules.py delete <name>
"""
import json
import os
import re
import subprocess
import sys

HYPR_DIR = os.path.expanduser(os.environ.get("HYPR_DIR", "~/.config/hypr"))
DISABLED_PREFIX = "-- [qs-disabled] "


def get_target_file():
    cfg_file = os.path.join(HYPR_DIR, "Configs", "WindowWorkspaces.lua")
    if os.path.isfile(cfg_file):
        return cfg_file
    custom_file = os.path.join(HYPR_DIR, "custom_window_rules.lua")
    if not os.path.isfile(custom_file):
        os.makedirs(HYPR_DIR, exist_ok=True)
        with open(custom_file, "w", encoding="utf-8") as f:
            f.write("-- Window & Layer rules managed by Quickshell Settings\n")
        hypr_lua = os.path.join(HYPR_DIR, "hyprland.lua")
        if os.path.isfile(hypr_lua):
            with open(hypr_lua, "r", encoding="utf-8") as hf:
                txt = hf.read()
            if "custom_window_rules" not in txt:
                with open(hypr_lua, "a", encoding="utf-8") as hf:
                    hf.write('\npcall(require, "custom_window_rules")\n')
    return custom_file


def reload_hyprland():
    try:
        uid = os.getuid()
        hypr_run = f"/run/user/{uid}/hypr"
        env = os.environ.copy()
        if "HYPRLAND_INSTANCE_SIGNATURE" not in env and os.path.isdir(hypr_run):
            entries = sorted(
                [d for d in os.listdir(hypr_run) if "_" in d],
                key=lambda d: os.path.getmtime(os.path.join(hypr_run, d)),
                reverse=True,
            )
            if entries:
                env["HYPRLAND_INSTANCE_SIGNATURE"] = entries[0]
        subprocess.run(["hyprctl", "reload"], capture_output=True, timeout=1.5, env=env)
    except Exception:
        pass


def find_rule_blocks(lines):
    """
    Scan lines and return list of dicts:
    {
        "start": int,
        "end": int,
        "disabled": bool,
        "rule_type": "window_rule" | "layer_rule",
        "text": str,
        "raw_lines": list[str]
    }
    """
    blocks = []
    i = 0
    while i < len(lines):
        raw = lines[i]
        stripped = raw.strip()
        disabled = stripped.startswith(DISABLED_PREFIX.strip())
        body = stripped[len(DISABLED_PREFIX.strip()):].strip() if disabled else stripped

        m_start = re.match(r"^(?:local\s+\w+\s*=\s*)?hl\.(window_rule|layer_rule)\s*\(", body)
        if not m_start:
            i += 1
            continue

        rule_type = m_start.group(1)
        depth = 0
        j = i
        collected = []
        while j < len(lines):
            seg = lines[j].strip()
            if seg.startswith(DISABLED_PREFIX.strip()):
                seg = seg[len(DISABLED_PREFIX.strip()):].strip()
            # strip comments outside strings safely
            seg_no_comment = re.sub(r"--.*$", "", seg)
            collected.append(seg_no_comment)
            depth += seg_no_comment.count("(") - seg_no_comment.count(")")
            if depth <= 0:
                break
            j += 1

        full_text = "\n".join(collected)
        blocks.append({
            "start": i,
            "end": j,
            "disabled": disabled,
            "rule_type": rule_type,
            "text": full_text,
            "raw_lines": lines[i : j + 1],
        })
        i = j + 1
    return blocks


def extract_kv_pairs(table_body):
    """Extract top-level key = val pairs inside a Lua table body."""
    pairs = {}
    # First extract nested match = { ... }
    m_match = re.search(r"\bmatch\s*=\s*\{([^}]*)\}", table_body, re.DOTALL)
    match_dict = {}
    if m_match:
        m_body = m_match.group(1)
        for km in re.finditer(r'([a-zA-Z0-9_]+)\s*=\s*("(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'|true|false|-?\d+(?:\.\d+)?)', m_body):
            mk = km.group(1).strip()
            mv = km.group(2).strip()
            if (mv.startswith('"') and mv.endswith('"')) or (mv.startswith("'") and mv.endswith("'")):
                mv = mv[1:-1]
            elif mv == "true":
                mv = True
            elif mv == "false":
                mv = False
            match_dict[mk] = mv
        # Remove match = { ... } from table_body before extracting top-level keys
        table_body = table_body[: m_match.start()] + table_body[m_match.end() :]

    for km in re.finditer(r'([a-zA-Z0-9_]+)\s*=\s*("(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'|true|false|-?\d+(?:\.\d+)?)', table_body):
        k = km.group(1).strip()
        v = km.group(2).strip()
        if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
            v = v[1:-1]
        elif v == "true":
            v = True
        elif v == "false":
            v = False
        else:
            try:
                v = float(v) if "." in v else int(v)
            except ValueError:
                pass
        pairs[k] = v

    return match_dict, pairs


def categorize_rule(rule_type, name, match_dict, effects):
    if rule_type == "layer_rule":
        return "layer"
    if "tag" in effects and str(effects["tag"]).startswith("+"):
        return "tag"
    if name.startswith("opacity-") or (len(effects) == 1 and "opacity" in effects):
        return "opacity"
    if name.startswith("float-") or name.startswith("center-") or name.startswith("dialog-"):
        return "float"
    return "special"


def format_match_summary(rule_type, match_dict):
    if not match_dict:
        return "Any window"
    parts = []
    for k, v in match_dict.items():
        parts.append(f"{k}: {v}")
    return " · ".join(parts)


def format_effect_pills(rule_type, effects):
    pills = []
    for k, v in effects.items():
        if k == "name":
            continue
        if isinstance(v, bool):
            if v:
                pills.append(k.replace("_", " "))
            else:
                pills.append(f"no {k.replace('_', ' ')}")
        else:
            pills.append(f"{k}: {v}")
    return pills


def parse_all_rules():
    path = get_target_file()
    if not os.path.isfile(path):
        return []
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.read().splitlines()

    blocks = find_rule_blocks(lines)
    rules = []
    for idx, blk in enumerate(blocks):
        m_inner = re.search(r"hl\.(?:window_rule|layer_rule)\s*\(\s*\{(.*)\}\s*\)", blk["text"], re.DOTALL)
        if not m_inner:
            continue
        inner = m_inner.group(1)
        match_dict, effects = extract_kv_pairs(inner)
        name = str(effects.get("name", f"rule-{idx + 1}"))
        category = categorize_rule(blk["rule_type"], name, match_dict, effects)

        # Parse active/inactive opacity if present
        op_str = str(effects.get("opacity", ""))
        op_parts = op_str.split()
        active_op = 1.0
        inactive_op = 1.0
        if len(op_parts) >= 1:
            try:
                active_op = float(op_parts[0])
                inactive_op = float(op_parts[1]) if len(op_parts) >= 2 else active_op
            except ValueError:
                pass

        rules.append({
            "uid": idx,
            "name": name,
            "ruleType": blk["rule_type"],
            "enabled": not blk["disabled"],
            "category": category,
            "match": match_dict,
            "effects": {k: v for k, v in effects.items() if k != "name"},
            "matchSummary": format_match_summary(blk["rule_type"], match_dict),
            "effectPills": format_effect_pills(blk["rule_type"], effects),
            "activeOpacity": active_op,
            "inactiveOpacity": inactive_op,
        })
    return rules


def toggle_rule(target_name, enabled_str):
    want = str(enabled_str).lower() in ("true", "1", "yes", "on")
    path = get_target_file()
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.read().splitlines()

    blocks = find_rule_blocks(lines)
    found = False
    for blk in blocks:
        m_inner = re.search(r"hl\.(?:window_rule|layer_rule)\s*\(\s*\{(.*)\}\s*\)", blk["text"], re.DOTALL)
        if not m_inner:
            continue
        _, effects = extract_kv_pairs(m_inner.group(1))
        if str(effects.get("name", "")) == target_name:
            found = True
            for k in range(blk["start"], blk["end"] + 1):
                if want and blk["disabled"]:
                    lines[k] = lines[k].replace(DISABLED_PREFIX, "", 1)
                elif not want and not blk["disabled"]:
                    lead = lines[k][: len(lines[k]) - len(lines[k].lstrip())]
                    lines[k] = lead + DISABLED_PREFIX + lines[k].lstrip()
            break

    if not found:
        return {"status": "error", "message": f"Rule '{target_name}' not found"}

    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    reload_hyprland()
    return {"status": "ok", "name": target_name, "enabled": want}


def set_opacity(target_name, active_val, inactive_val):
    path = get_target_file()
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.read().splitlines()

    blocks = find_rule_blocks(lines)
    found = False
    try:
        a_f = round(float(active_val), 2)
        i_f = round(float(inactive_val), 2)
    except ValueError:
        return {"status": "error", "message": "Invalid opacity values"}

    new_op_str = f"{a_f} {i_f}"

    for blk in blocks:
        m_inner = re.search(r"hl\.(?:window_rule|layer_rule)\s*\(\s*\{(.*)\}\s*\)", blk["text"], re.DOTALL)
        if not m_inner:
            continue
        _, effects = extract_kv_pairs(m_inner.group(1))
        if str(effects.get("name", "")) == target_name:
            found = True
            for k in range(blk["start"], blk["end"] + 1):
                if "opacity" in lines[k]:
                    lines[k] = re.sub(
                        r'(opacity\s*=\s*)"[^"]*"',
                        f'\\1"{new_op_str}"',
                        lines[k],
                    )
            break

    if not found:
        return {"status": "error", "message": f"Rule '{target_name}' not found"}

    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    reload_hyprland()
    return {"status": "ok", "name": target_name, "opacity": new_op_str}


def lua_escape(s):
    return str(s).replace("\\", "\\\\").replace('"', '\\"')


def format_lua_val(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    s = str(v).strip()
    if s.lower() == "true":
        return "true"
    if s.lower() == "false":
        return "false"
    try:
        if "." in s:
            return str(float(s))
        return str(int(s))
    except ValueError:
        return f'"{lua_escape(s)}"'


def build_lua_rule_block(payload, disabled=False):
    rule_type = payload.get("ruleType", "window_rule")
    if rule_type not in ("window_rule", "layer_rule"):
        rule_type = "window_rule"

    name = re.sub(r"[^a-zA-Z0-9_\-]", "-", str(payload.get("name", "custom-rule")).strip()) or "custom-rule"
    match_dict = payload.get("match", {})
    effects = payload.get("effects", {})

    match_parts = []
    for mk, mv in match_dict.items():
        if mv is None or str(mv).strip() == "":
            continue
        match_parts.append(f"{mk} = {format_lua_val(mv)}")

    effect_lines = []
    for ek, ev in effects.items():
        if ek == "name" or ev is None or str(ev).strip() == "":
            continue
        if isinstance(ev, bool) and not ev:
            continue
        effect_lines.append(f"    {ek} = {format_lua_val(ev)},")

    prefix = DISABLED_PREFIX if disabled else ""
    match_str = "{ " + ", ".join(match_parts) + " }" if match_parts else "{ class = \".*\" }"

    block_lines = [
        f"{prefix}hl.{rule_type}({{",
        f'{prefix}    name  = "{lua_escape(name)}",',
        f"{prefix}    match = {match_str},",
    ]
    for el in effect_lines:
        block_lines.append(f"{prefix}{el}")
    block_lines.append(f"{prefix}}})")
    return block_lines


def save_rule(json_str):
    try:
        payload = json.loads(json_str)
    except Exception as e:
        return {"status": "error", "message": str(e)}

    orig_name = str(payload.get("originalName", "")).strip()
    new_name = str(payload.get("name", "")).strip()
    if not new_name:
        return {"status": "error", "message": "Rule name is required"}

    path = get_target_file()
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.read().splitlines()

    blocks = find_rule_blocks(lines)
    target_blk = None
    for blk in blocks:
        m_inner = re.search(r"hl\.(?:window_rule|layer_rule)\s*\(\s*\{(.*)\}\s*\)", blk["text"], re.DOTALL)
        if not m_inner:
            continue
        _, effects = extract_kv_pairs(m_inner.group(1))
        rname = str(effects.get("name", ""))
        if (orig_name and rname == orig_name) or (not orig_name and rname == new_name):
            target_blk = blk
            break

    disabled = target_blk["disabled"] if target_blk else not bool(payload.get("enabled", True))
    new_block_lines = build_lua_rule_block(payload, disabled=disabled)

    if target_blk:
        lines[target_blk["start"] : target_blk["end"] + 1] = new_block_lines
    else:
        if lines and lines[-1].strip() != "":
            lines.append("")
        lines.extend(new_block_lines)

    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    reload_hyprland()
    return {"status": "ok", "name": new_name}


def delete_rule(target_name):
    path = get_target_file()
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.read().splitlines()

    blocks = find_rule_blocks(lines)
    target_blk = None
    for blk in blocks:
        m_inner = re.search(r"hl\.(?:window_rule|layer_rule)\s*\(\s*\{(.*)\}\s*\)", blk["text"], re.DOTALL)
        if not m_inner:
            continue
        _, effects = extract_kv_pairs(m_inner.group(1))
        if str(effects.get("name", "")) == target_name:
            target_blk = blk
            break

    if not target_blk:
        return {"status": "error", "message": f"Rule '{target_name}' not found"}

    del lines[target_blk["start"] : target_blk["end"] + 1]
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    reload_hyprland()
    return {"status": "ok", "deleted": target_name}


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    if cmd == "list":
        print(json.dumps(parse_all_rules()))
    elif cmd == "toggle" and len(sys.argv) >= 4:
        print(json.dumps(toggle_rule(sys.argv[2], sys.argv[3])))
    elif cmd == "set_opacity" and len(sys.argv) >= 5:
        print(json.dumps(set_opacity(sys.argv[2], sys.argv[3], sys.argv[4])))
    elif cmd == "save" and len(sys.argv) >= 3:
        print(json.dumps(save_rule(sys.argv[2])))
    elif cmd == "delete" and len(sys.argv) >= 3:
        print(json.dumps(delete_rule(sys.argv[2])))
    else:
        print(__doc__)
        sys.exit(1)

