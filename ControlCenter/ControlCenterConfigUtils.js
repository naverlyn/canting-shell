.pragma library

function _cloneQuickAppList(root, fallbackList) {
    if (fallbackList && fallbackList.length > root.quickApps.length) {
        return fallbackList.map(function(a) {
            return {
                id: a.id || a.desktopId || ("app_" + Math.random()),
                desktopId: a.desktopId || "",
                label: a.label || "App",
                icon: a.icon || "󰀻",
                cmd: a.cmd || ""
            };
        });
    }
    return root.quickApps.slice();
}

function addQuickApp(root, label, icon, cmd, desktopId) {
    var cleanLabel = String(label || "App").trim() || "App";
    var cleanIcon = String(icon || "󰀻").trim() || "󰀻";
    var cleanCmd = String(cmd || "").trim();
    var cleanDesktop = String(desktopId || "").trim();
    if (!cleanCmd && !cleanDesktop) return false;
    var copy = root.quickApps.slice();
    if (copy.length >= 15) return false;
    copy.push({
        id: cleanDesktop || ("app_" + Date.now() + "_" + copy.length),
        desktopId: cleanDesktop,
        label: cleanLabel,
        icon: cleanIcon,
        cmd: cleanCmd
    });
    root.quickApps = copy;
    if (copy.length > root.quickAppsMaxCount) {
        root.quickAppsMaxCount = Math.min(15, Math.max(3, copy.length));
    }
    root.saveConfig();
    return true;
}

function replaceQuickAppAt(root, index, label, icon, cmd, desktopId, fallbackList) {
    var copy = _cloneQuickAppList(root, fallbackList);
    if (index < 0 || index >= 15) return false;
    var item = {
        id: String(desktopId || ("app_" + Date.now() + "_" + index)),
        desktopId: String(desktopId || ""),
        label: String(label || "App").trim() || "App",
        icon: String(icon || "󰀻").trim() || "󰀻",
        cmd: String(cmd || "").trim()
    };
    if (index < copy.length) {
        copy[index] = item;
    } else {
        copy.push(item);
    }
    root.quickApps = copy.slice(0, 15);
    root.saveConfig();
    return true;
}

function moveQuickAppInFullList(root, fromIdx, toIdx, fallbackList) {
    var copy = _cloneQuickAppList(root, fallbackList);
    if (fromIdx < 0 || fromIdx >= copy.length) return;
    if (toIdx < 0 || toIdx >= copy.length) return;
    if (fromIdx === toIdx) return;
    var item = copy.splice(fromIdx, 1)[0];
    copy.splice(toIdx, 0, item);
    root.quickApps = copy.slice(0, 15);
    root.saveConfig();
}

function updateQuickApp(root, index, label, icon, cmd, desktopId) {
    if (index < 0 || index >= root.quickApps.length) return false;
    var copy = root.quickApps.slice();
    var prev = copy[index];
    copy[index] = {
        id: prev.id || ("app_" + index),
        desktopId: desktopId !== undefined ? String(desktopId) : (prev.desktopId || ""),
        label: String(label !== undefined ? label : prev.label).trim() || "App",
        icon: String(icon !== undefined ? icon : prev.icon).trim() || "󰀻",
        cmd: String(cmd !== undefined ? cmd : prev.cmd).trim()
    };
    root.quickApps = copy;
    root.saveConfig();
    return true;
}

function removeQuickApp(root, index) {
    if (index < 0 || index >= root.quickApps.length) return;
    var copy = root.quickApps.slice();
    copy.splice(index, 1);
    root.quickApps = copy;
    if (root.quickAppsMaxCount > Math.max(3, copy.length) && copy.length >= 3) {
        root.quickAppsMaxCount = copy.length;
    }
    root.saveConfig();
}

function moveQuickApp(root, fromIdx, toIdx) {
    if (fromIdx < 0 || fromIdx >= root.quickApps.length) return;
    if (toIdx < 0 || toIdx >= root.quickApps.length) return;
    if (fromIdx === toIdx) return;
    var copy = root.quickApps.slice();
    var item = copy.splice(fromIdx, 1)[0];
    copy.splice(toIdx, 0, item);
    root.quickApps = copy;
    root.saveConfig();
}

function resetQuickApps(root) {
    root.quickAppsMaxCount = 8;
    root.quickApps = JSON.parse(JSON.stringify(root.defaultQuickApps));
    root.saveConfig();
}

function resetDefaults(root) {
    root.panelWidth = 320;
    root.panelLayout = "horizontal";
    root.panelCount = 3;
    root.cardTitles = {};
    root.groupSize = 2;
    root.panel1 = ["connectivity", "quickSettings", "systemInfo"];
    root.panel2 = ["brightness", "media"];
    root.panel3 = ["audio", "notifications"];
    root.groupTilesEnabled = true;
    root.groupedTileIds = ["wifi", "bluetooth", "dnd", "airplane"];
    root.secondaryTileIds = ["mute", "gamemode", "clipboard", "darkmode"];
    root.quickAppsMaxCount = 8;
    root.quickApps = JSON.parse(JSON.stringify(root.defaultQuickApps));
    root.mediaWidgetStyle = "auto";
    root.showHeader = true;
    root.mediaAutoHide = true;
    root.mediaShowCava = false;
    root.tiles = [
        { id: "wifi", enabled: true },
        { id: "nightlight", enabled: true },
        { id: "caffeine", enabled: true },
        { id: "dnd", enabled: true },
        { id: "mic", enabled: true },
        { id: "screenshot", enabled: true },
        { id: "lock", enabled: true },
        { id: "mute", enabled: false },
        { id: "gamemode", enabled: false },
        { id: "clipboard", enabled: false },
        { id: "darkmode", enabled: false },
        { id: "emoji", enabled: false },
        { id: "bluetooth", enabled: true },
        { id: "airplane", enabled: true }
    ];
    root.cardOrderRevision++;
    root.cardsUpdated();
    root.saveConfig();
}

function buildConfigData(root) {
    return {
        width: root.panelWidth,
        panelLayout: root.panelLayout,
        panelCount: root.panelCount,
        panel1: root.panel1,
        panel2: root.panel2,
        panel3: root.panel3,
        cardTitles: root.cardTitles,
        groupSize: root.groupSize,
        groupTilesEnabled: root.groupTilesEnabled,
        groupedTileIds: root.groupedTileIds,
        secondaryTileIds: root.secondaryTileIds,
        quickAppsMaxCount: root.quickAppsMaxCount,
        quickApps: root.quickApps,
        mediaWidgetStyle: root.mediaWidgetStyle,
        cards: {
            header: root.showHeader
        },
        mediaAutoHide: root.mediaAutoHide,
        mediaShowCava: root.mediaShowCava,
        tiles: root.tiles
    };
}

function sanitizePanelList(root, arr, seenMap) {
    var res = [];
    if (!Array.isArray(arr)) return res;
    for (var i = 0; i < arr.length; i++) {
        var cid = arr[i];
        if (cid && root.getCardDef(cid) && !seenMap[cid]) {
            res.push(cid);
            seenMap[cid] = true;
        }
    }
    return res;
}

function applyConfig(root, cfg) {
    if (!cfg) return;
    if (cfg.width !== undefined) {
        root.panelWidth = Math.max(280, Math.min(460, Math.round(Number(cfg.width) || 320)));
    }
    if (cfg.panelLayout !== undefined) {
        root.panelLayout = (cfg.panelLayout === "horizontal") ? "horizontal" : "vertical";
    }
    if (cfg.panelCount !== undefined) {
        root.panelCount = Math.max(1, Math.min(3, Math.round(Number(cfg.panelCount) || 3)));
    }
    if (cfg.groupSize !== undefined) {
        root.groupSize = Math.max(2, Math.min(6, Math.round(Number(cfg.groupSize) || 2)));
    }
    if (cfg.cardTitles && typeof cfg.cardTitles === "object") {
        var titles = {};
        for (var k in cfg.cardTitles) {
            if (typeof cfg.cardTitles[k] === "string") titles[k] = cfg.cardTitles[k];
        }
        root.cardTitles = titles;
    }
    if (cfg.groupTilesEnabled !== undefined) {
        root.groupTilesEnabled = Boolean(cfg.groupTilesEnabled);
    }
    if (Array.isArray(cfg.groupedTileIds)) {
        root.groupedTileIds = cfg.groupedTileIds;
    }
    if (Array.isArray(cfg.secondaryTileIds)) {
        root.secondaryTileIds = cfg.secondaryTileIds;
    }
    if (cfg.quickAppsMaxCount !== undefined) {
        root.quickAppsMaxCount = Math.max(3, Math.min(15, Math.round(Number(cfg.quickAppsMaxCount) || 8)));
    }
    if (Array.isArray(cfg.quickApps) && cfg.quickApps.length > 0) {
        root.quickApps = cfg.quickApps.slice(0, 15);
    }
    if (cfg.mediaWidgetStyle !== undefined) {
        root.mediaWidgetStyle = (cfg.mediaWidgetStyle === "full") ? "full" : ((cfg.mediaWidgetStyle === "compact") ? "compact" : "auto");
    }
    if (cfg.cards) {
        if (cfg.cards.header !== undefined) root.showHeader = Boolean(cfg.cards.header);
    }
    if (cfg.mediaAutoHide !== undefined) root.mediaAutoHide = Boolean(cfg.mediaAutoHide);
    if (cfg.mediaShowCava !== undefined) root.mediaShowCava = Boolean(cfg.mediaShowCava);

    if (Array.isArray(cfg.panel1) || Array.isArray(cfg.panel2) || Array.isArray(cfg.panel3)) {
        var seen = {};
        root.panel1 = sanitizePanelList(root, cfg.panel1, seen);
        root.panel2 = sanitizePanelList(root, cfg.panel2, seen);
        root.panel3 = sanitizePanelList(root, cfg.panel3, seen);
        root.cardOrderRevision++;
        root.cardsUpdated();
    } else if (cfg.cards) {
        var p0 = [];
        var p1 = [];
        var p2 = [];
        if (cfg.cards.quickSettings !== false) {
            if (root.groupTilesEnabled) p0.push("connectivity");
            p0.push("quickSettings");
        }
        if (cfg.cards.systemInfo) p0.push("systemInfo");
        if (cfg.cards.brightness) p1.push("brightness");
        if (cfg.cards.media !== false) p1.push("media");
        if (cfg.cards.audio !== false) p2.push("audio");
        root.panel1 = p0;
        root.panel2 = p1;
        root.panel3 = p2;
        root.panelCount = root.panelLayout === "horizontal" ? 3 : 1;
        root.cardOrderRevision++;
        root.cardsUpdated();
    }

    if (Array.isArray(cfg.tiles)) {
        var knownMap = {};
        var merged = [];
        for (var i = 0; i < cfg.tiles.length; i++) {
            var t = cfg.tiles[i];
            if (t && t.id && root.getTileDef(t.id)) {
                merged.push({ id: t.id, enabled: Boolean(t.enabled) });
                knownMap[t.id] = true;
            }
        }
        for (var j = 0; j < root.allTileDefs.length; j++) {
            var defId = root.allTileDefs[j].id;
            if (!knownMap[defId]) {
                merged.push({ id: defId, enabled: false });
            }
        }
        root.tiles = merged;
    }
}
