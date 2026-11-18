.pragma library

function formatModmask(modmask) {
    const m = Number(modmask) || 0;
    const mods = [];
    if (m & 64) mods.push("SUPER");
    if (m & 4) mods.push("CTRL");
    if (m & 8) mods.push("ALT");
    if (m & 1) mods.push("SHIFT");
    if (m & 2) mods.push("CAPS");
    if (m & 128) mods.push("MOD5");
    return mods;
}

function formatKeyName(rawKey) {
    const k = String(rawKey || "").trim();
    if (k === "") return "";
    const map = {
        "Return": "Enter",
        "Escape": "Esc",
        "BackSpace": "Backspace",
        "space": "Space",
        "Space": "Space",
        "left": "←",
        "Left": "←",
        "right": "→",
        "Right": "→",
        "up": "↑",
        "Up": "↑",
        "down": "↓",
        "Down": "↓",
        "Print": "Print",
        "XF86AudioRaiseVolume": "Vol +",
        "XF86AudioLowerVolume": "Vol -",
        "XF86AudioMute": "Mute",
        "XF86AudioMicMute": "Mic Mute",
        "XF86MonBrightnessUp": "Bright +",
        "XF86MonBrightnessDown": "Bright -",
        "XF86AudioNext": "Next",
        "XF86AudioPrev": "Prev",
        "XF86AudioPlay": "Play",
        "XF86AudioPause": "Pause"
    };
    if (map[k]) return map[k];
    if (k.length === 1) return k.toUpperCase();
    return k;
}

function cleanDispatcher(disp) {
    const s = String(disp || "").trim();
    const m = s.match(/^HL\.Dispatcher\((.+)\)$/);
    return m ? m[1] : s;
}

function categorizeBind(rawKey, dispClean, desc) {
    const k = String(rawKey || "");
    const d = String(dispClean || "").toLowerCase();
    const t = String(desc || "").toLowerCase();

    if (k.indexOf("XF86") === 0 || t.indexOf("volume") !== -1 || t.indexOf("bright") !== -1 || t.indexOf("media") !== -1 || t.indexOf("mute") !== -1) {
        return "Media";
    }
    if (d.indexOf("workspace") !== -1 || t.indexOf("workspace") !== -1) {
        return "Workspaces";
    }
    if (d === "close" || d === "float" || d === "pseudo" || d === "layout" || d === "focus" || d === "move" || d === "fullscreen" || d.indexOf("resize") !== -1 || t.indexOf("window") !== -1 || t.indexOf("tiling") !== -1 || t.indexOf("fullscreen") !== -1) {
        return "Windows";
    }
    if (t.indexOf("screenshot") !== -1 || t.indexOf("lock") !== -1 || t.indexOf("power") !== -1 || t.indexOf("settings") !== -1 || t.indexOf("wallpaper") !== -1 || t.indexOf("theme") !== -1 || t.indexOf("clipboard") !== -1 || t.indexOf("launcher") !== -1) {
        return "System";
    }
    if (d === "exec_cmd" || d === "exec") {
        return "Apps";
    }
    return "System";
}

function normalizeBinds(rawList) {
    if (!Array.isArray(rawList)) return [];
    const out = [];
    for (let i = 0; i < rawList.length; i++) {
        const b = rawList[i];
        if (!b || b.mouse) continue;
        const rawKey = String(b.key || "").trim();
        if (rawKey === "" || rawKey.indexOf("mouse") === 0) continue;

        const mods = formatModmask(b.modmask);
        const keyLabel = formatKeyName(rawKey);
        const dispClean = cleanDispatcher(b.dispatcher);
        const argClean = String(b.arg || "").trim();
        const dispatcherLabel = argClean !== ""
            ? (dispClean !== "" ? (dispClean + " · " + argClean) : argClean)
            : dispClean;
        const desc = String(b.description || "").trim();
        const title = desc !== "" ? desc : (dispClean !== "" ? dispClean : rawKey);
        const category = categorizeBind(rawKey, dispClean, title);
        const comboParts = mods.concat([keyLabel]);
        const comboText = comboParts.join(" + ");

        out.push({
            uid: b.uid !== undefined ? b.uid : i,
            mods: mods,
            keyLabel: keyLabel,
            comboText: comboText,
            title: title,
            dispatcherLabel: dispatcherLabel,
            category: category,
            searchBlob: (title + " " + comboText + " " + rawKey + " " + dispClean + " " + argClean + " " + category).toLowerCase()
        });
    }
    return out;
}
