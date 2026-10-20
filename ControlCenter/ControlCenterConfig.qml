pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configPath: Qt.resolvedUrl("../control_center_config.json").toString().replace(/^file:\/\//, "")

    property int panelWidth: 320
    property bool showHeader: true
    property bool showViewSwitcher: true
    property bool mediaAutoHide: true
    property bool mediaShowCava: false
    property string panelLayout: "horizontal"
    property int panelCount: 3
    property var panel1: ["connectivity", "quickSettings", "systemInfo"]
    property var panel2: ["brightness", "media"]
    property var panel3: ["audio"]
    property bool groupTilesEnabled: true
    property var groupedTileIds: ["wifi", "bluetooth", "dnd", "airplane"]
    property var secondaryTileIds: ["mute", "gamemode", "clipboard", "darkmode"]
    property string mediaWidgetStyle: "auto" // "auto", "compact", or "full"
    property int quickAppsMaxCount: 8

    readonly property var defaultQuickApps: [
        { id: "terminal", label: "Terminal", icon: "󰆍", cmd: "kitty || alacritty || foot || wezterm || xdg-terminal-exec" },
        { id: "browser",  label: "Browser",  icon: "󰈹", cmd: "xdg-open https:// || firefox || brave || google-chrome-stable || chromium" },
        { id: "files",    label: "Files",    icon: "󰉋", cmd: "thunar || nautilus || dolphin || nemo || pcmanfm" },
        { id: "editor",   label: "Code",     icon: "󰨞", cmd: "codium || code || zeditor || kate || nvim" },
        { id: "launcher", label: "Apps",     icon: "󰀻", cmd: "__appgrid__" },
        { id: "music",    label: "Music",    icon: "󰝚", cmd: "spotify || Amberol || rhythmbox || Elisa" },
        { id: "monitor",  label: "Monitor",  icon: "󰍛", cmd: "missioncenter || gnome-system-monitor || kitty -e btop || alacritty -e btop" },
        { id: "settings", label: "Settings", icon: "󰒓", cmd: "__settings__" }
    ]

    property var quickApps: [
        { id: "terminal", label: "Terminal", icon: "󰆍", cmd: "kitty || alacritty || foot || wezterm || xdg-terminal-exec" },
        { id: "browser",  label: "Browser",  icon: "󰈹", cmd: "xdg-open https:// || firefox || brave || google-chrome-stable || chromium" },
        { id: "files",    label: "Files",    icon: "󰉋", cmd: "thunar || nautilus || dolphin || nemo || pcmanfm" },
        { id: "editor",   label: "Code",     icon: "󰨞", cmd: "codium || code || zeditor || kate || nvim" },
        { id: "launcher", label: "Apps",     icon: "󰀻", cmd: "__appgrid__" },
        { id: "music",    label: "Music",    icon: "󰝚", cmd: "spotify || Amberol || rhythmbox || Elisa" },
        { id: "monitor",  label: "Monitor",  icon: "󰍛", cmd: "missioncenter || gnome-system-monitor || kitty -e btop || alacritty -e btop" },
        { id: "settings", label: "Settings", icon: "󰒓", cmd: "__settings__" }
    ]

    // Legacy compatibility boolean properties (computed from active panels)
    readonly property bool showConnectivity: isCardVisible("connectivity")
    readonly property bool showQuickSettings: isCardVisible("quickSettings")
    readonly property bool showQuickSettings2: isCardVisible("quickSettings2")
    readonly property bool showBrightness: isCardVisible("brightness")
    readonly property bool showAudio: isCardVisible("audio")
    readonly property bool showMedia: isCardVisible("media")
    readonly property bool showSystemInfo: isCardVisible("systemInfo")
    readonly property bool showCava: isCardVisible("cava")
    readonly property bool showWeather: isCardVisible("weather")
    readonly property bool showQuickApps: isCardVisible("quickApps")

    // Master list of all available building-block modules
    readonly property var allCardDefs: [
        { id: "connectivity",   label: "Connectivity (2x2)", icon: "󰖩", desc: "2x2 Wi-Fi, Bluetooth, DND & Airplane card" },
        { id: "quickSettings",  label: "Quick Tiles",        icon: "󰒓", desc: "Primary system toggle tiles grid" },
        { id: "quickSettings2", label: "Quick Tiles 2",      icon: "󰕰", desc: "Secondary quick toggle tiles grid for another panel" },
        { id: "brightness",     label: "Brightness",         icon: "󰃠", desc: "Screen backlight brightness slider" },
        { id: "audio",          label: "Volume & Sound",     icon: "󰕾", desc: "Speaker & microphone volume sliders" },
        { id: "media",          label: "Media Player",       icon: "󰝚", desc: "MPRIS playback & controls (Auto / Compact / Full)" },
        { id: "systemInfo",     label: "System Resources",   icon: "󰍛", desc: "CPU, memory, disk & thermals overview" },
        { id: "cava",           label: "Cava Visualizer",    icon: "",   desc: "Real-time Cava audio spectrum visualizer" },
        { id: "weather",        label: "Weather",            icon: "󰖐", desc: "Live weather conditions, temperature & wind" },
        { id: "quickApps",      label: "Quick Launch",       icon: "󰀻", desc: "Fast shortcuts to favorite desktop apps" }
    ]

    signal cardsUpdated()
    property int cardOrderRevision: 0

    function getCardDef(id) {
        for (let i = 0; i < allCardDefs.length; i++) {
            if (allCardDefs[i].id === id) return allCardDefs[i];
        }
        return null;
    }

    function getPanelIds(pIdx) {
        if (pIdx === 0) return root.panel1 || [];
        if (pIdx === 1) return root.panel2 || [];
        if (pIdx === 2) return root.panel3 || [];
        return [];
    }

    function setPanelIds(pIdx, list) {
        if (pIdx === 0) root.panel1 = list;
        else if (pIdx === 1) root.panel2 = list;
        else if (pIdx === 2) root.panel3 = list;
    }

    function getPanelCards(pIdx) {
        const ids = root.getPanelIds(pIdx);
        let res = [];
        for (let i = 0; i < ids.length; i++) {
            const def = root.getCardDef(ids[i]);
            if (def) {
                res.push({
                    id: def.id,
                    label: def.label,
                    icon: def.icon,
                    desc: def.desc,
                    panelIndex: pIdx,
                    itemIndex: res.length
                });
            }
        }
        return res;
    }

    readonly property var panel1Cards: getPanelCards(0)
    readonly property var panel2Cards: getPanelCards(1)
    readonly property var panel3Cards: getPanelCards(2)

    function getCardPanelIndex(id) {
        const activeCount = root.panelLayout === "horizontal" ? Math.max(1, Math.min(3, root.panelCount)) : 1;
        for (let p = 0; p < activeCount; p++) {
            const list = root.getPanelIds(p);
            if (list.indexOf(id) !== -1) return p;
        }
        return -1;
    }

    function isCardVisible(id) {
        for (let p = 0; p < Math.max(1, Math.min(3, root.panelCount)); p++) {
            const list = root.getPanelIds(p);
            if (list.indexOf(id) !== -1) return true;
        }
        return false;
    }

    // Smart Auto / Compact / Full calculation for Media Player
    readonly property bool isMediaEffectiveCompact: {
        if (root.mediaWidgetStyle === "compact") return true;
        if (root.mediaWidgetStyle === "full") return false;
        // "auto": compact when sharing a panel with another module (e.g. Brightness + Media, or QuickSettings + Media)
        for (let p = 0; p < 3; p++) {
            const list = root.getPanelIds(p);
            if (list.indexOf("media") !== -1) {
                return list.length >= 2;
            }
        }
        return true;
    }

    readonly property string mediaEffectiveBadge: {
        if (root.mediaWidgetStyle === "compact") return "Compact";
        if (root.mediaWidgetStyle === "full") return "Big";
        return root.isMediaEffectiveCompact ? "Auto (Compact)" : "Auto (Big)";
    }

    function cycleMediaWidgetStyle() {
        if (root.mediaWidgetStyle === "auto") root.setMediaWidgetStyle("compact");
        else if (root.mediaWidgetStyle === "compact") root.setMediaWidgetStyle("full");
        else root.setMediaWidgetStyle("auto");
        return root.mediaEffectiveBadge;
    }

    // Flattened list of active cards across active panels
    readonly property var enabledCards: {
        let res = [];
        const maxP = Math.max(1, Math.min(3, root.panelCount));
        for (let p = 0; p < maxP; p++) {
            const list = root.getPanelIds(p);
            for (let i = 0; i < list.length; i++) {
                const def = root.getCardDef(list[i]);
                if (def) {
                    res.push({
                        id: def.id,
                        label: def.label,
                        icon: def.icon,
                        desc: def.desc,
                        panelIndex: p,
                        itemIndex: i
                    });
                }
            }
        }
        return res;
    }

    readonly property var cardOrder: {
        let res = [];
        for (let i = 0; i < root.enabledCards.length; i++) {
            res.push(root.enabledCards[i].id);
        }
        return res;
    }

    // Filtered list of unassigned cards (Available Modules Pool)
    readonly property var unassignedCards: {
        let res = [];
        for (let i = 0; i < root.allCardDefs.length; i++) {
            const def = root.allCardDefs[i];
            if (!root.isCardVisible(def.id)) {
                res.push(def);
            }
        }
        return res;
    }

    function getEnabledCardIndex(id) {
        for (let i = 0; i < root.enabledCards.length; i++) {
            if (root.enabledCards[i].id === id) return i;
        }
        return -1;
    }

    function moveCardInPanel(panelIdx, fromIdx, toIdx) {
        let list = [...root.getPanelIds(panelIdx)];
        if (fromIdx < 0 || fromIdx >= list.length) return;
        if (toIdx < 0 || toIdx >= list.length) return;
        if (fromIdx === toIdx) return;
        const item = list.splice(fromIdx, 1)[0];
        list.splice(toIdx, 0, item);
        root.setPanelIds(panelIdx, list);
        root.cardOrderRevision++;
        root.cardsUpdated();
        root.saveConfig();
    }

    function moveCardLeftRight(cardId, delta) {
        let curPanel = -1;
        for (let p = 0; p < 3; p++) {
            if (root.getPanelIds(p).indexOf(cardId) !== -1) { curPanel = p; break; }
        }
        if (curPanel === -1) return false;
        const targetPanel = curPanel + delta;
        if (targetPanel < 0 || targetPanel >= root.panelCount) return false;
        return root.moveCardToPanelAt(cardId, targetPanel, -1);
    }

    function moveCardToPanelAt(cardId, targetPanelIdx, targetItemIdx) {
        if (!root.getCardDef(cardId)) return false;
        let p0 = root.panel1.filter(id => id !== cardId);
        let p1 = root.panel2.filter(id => id !== cardId);
        let p2 = root.panel3.filter(id => id !== cardId);

        if (targetPanelIdx >= 0 && targetPanelIdx < 3) {
            let targetList = targetPanelIdx === 0 ? p0 : (targetPanelIdx === 1 ? p1 : p2);
            const ins = (targetItemIdx >= 0 && targetItemIdx <= targetList.length)
                ? targetItemIdx
                : targetList.length;
            targetList.splice(ins, 0, cardId);
        }

        root.panel1 = p0;
        root.panel2 = p1;
        root.panel3 = p2;
        root.cardOrderRevision++;
        root.cardsUpdated();
        root.saveConfig();
        return true;
    }

    function moveEnabledCard(fromEnabledIndex, toEnabledIndex) {
        if (fromEnabledIndex < 0 || fromEnabledIndex >= root.enabledCards.length) return;
        if (toEnabledIndex < 0 || toEnabledIndex >= root.enabledCards.length) return;
        if (fromEnabledIndex === toEnabledIndex) return;
        const fromItem = root.enabledCards[fromEnabledIndex];
        const toItem = root.enabledCards[toEnabledIndex];
        root.moveCardToPanelAt(fromItem.id, toItem.panelIndex, toItem.itemIndex);
    }

    function insertCardAtEnabledIndex(cardId, targetEnabledIndex) {
        if (!root.getCardDef(cardId)) return false;
        if (targetEnabledIndex >= 0 && targetEnabledIndex < root.enabledCards.length) {
            const target = root.enabledCards[targetEnabledIndex];
            return root.moveCardToPanelAt(cardId, target.panelIndex, target.itemIndex);
        }
        // Default: add to first panel with fewest items
        let bestPanel = 0;
        let minLen = 999;
        for (let p = 0; p < Math.max(1, Math.min(3, root.panelCount)); p++) {
            const len = root.getPanelIds(p).length;
            if (len < minLen) { minLen = len; bestPanel = p; }
        }
        return root.moveCardToPanelAt(cardId, bestPanel, -1);
    }

    // Master list of all available tile metadata
    readonly property var allTileDefs: [
        { id: "wifi",        label: "Wi-Fi",          icon: "󰖩", desc: "Network connection & selector" },
        { id: "nightlight",  label: "Night Light",    icon: "󰛨", desc: "Warm blue-light screen filter" },
        { id: "caffeine",    label: "Keep Awake",     icon: "󰅶", desc: "Inhibit idle sleep & blanking" },
        { id: "dnd",         label: "Do Not Disturb", icon: "󰂛", desc: "Mute desktop notification popups" },
        { id: "mic",         label: "Microphone",     icon: "󰍬", desc: "Mute or unmute audio input" },
        { id: "mute",        label: "Mute Audio",     icon: "󰝟", desc: "Mute or unmute speaker output" },
        { id: "gamemode",    label: "Game Mode",      icon: "󰊴", desc: "Disable animations & blur for gaming" },
        { id: "clipboard",   label: "Clipboard",      icon: "󰅍", desc: "Clipboard history & manager" },
        { id: "darkmode",    label: "Dark / Light",   icon: "󰔎", desc: "Toggle dark or light theme" },
        { id: "emoji",       label: "Emoji Picker",   icon: "󰞅", desc: "Search and insert emojis" },
        { id: "screenshot",  label: "Screenshot",     icon: "󰄄", desc: "Capture rectangular screen area" },
        { id: "lock",        label: "Lock Screen",    icon: "󰌾", desc: "Immediately lock session" },
        { id: "bluetooth",   label: "Bluetooth",      icon: "󰂯", desc: "Bluetooth power & devices" },
        { id: "airplane",    label: "Airplane Mode",  icon: "󰀝", desc: "Disable all wireless radios" }
    ]

    // Active tiles configuration (ordered list with enabled boolean)
    property var tiles: [
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
    ]

    // Filtered list of currently enabled tiles in order
    readonly property var enabledTiles: {
        let res = [];
        for (let i = 0; i < root.tiles.length; i++) {
            const t = root.tiles[i];
            if (t && t.enabled) {
                const def = root.getTileDef(t.id);
                if (def) {
                    res.push({
                        id: t.id,
                        label: def.label,
                        icon: def.icon,
                        desc: def.desc
                    });
                }
            }
        }
        return res;
    }

    // 4-tile connectivity group (e.g. Wi-Fi, Bluetooth, DND, Airplane Mode)
    readonly property var groupedTiles: {
        let res = [];
        if (!root.groupTilesEnabled) return res;
        for (let i = 0; i < root.groupedTileIds.length; i++) {
            const tid = root.groupedTileIds[i];
            const def = root.getTileDef(tid);
            if (def) {
                res.push({
                    id: def.id,
                    label: def.label,
                    icon: def.icon,
                    desc: def.desc
                });
            }
        }
        return res;
    }

    // Primary ungrouped standalone tiles (for "quickSettings")
    readonly property var ungroupedTiles: {
        let res = [];
        const qs2Active = root.isCardVisible("quickSettings2");
        for (let i = 0; i < root.enabledTiles.length; i++) {
            const t = root.enabledTiles[i];
            const inGroup = root.groupTilesEnabled && root.groupedTileIds.indexOf(t.id) !== -1;
            const inSec = qs2Active && root.secondaryTileIds.indexOf(t.id) !== -1;
            if (!inGroup && !inSec) {
                res.push(t);
            }
        }
        return res;
    }

    // Secondary quick tiles (for "quickSettings2")
    readonly property var secondaryTiles: {
        let res = [];
        for (let i = 0; i < root.secondaryTileIds.length; i++) {
            const tid = root.secondaryTileIds[i];
            const def = root.getTileDef(tid);
            if (def && (!root.groupTilesEnabled || root.groupedTileIds.indexOf(tid) === -1)) {
                res.push({
                    id: def.id,
                    label: def.label,
                    icon: def.icon,
                    desc: def.desc
                });
            }
        }
        return res;
    }

    function isTileInGroup(id) {
        return root.groupTilesEnabled && root.groupedTileIds.indexOf(id) !== -1;
    }

    function isTileInSecondary(id) {
        return root.isCardVisible("quickSettings2") && root.secondaryTileIds.indexOf(id) !== -1;
    }

    function canAddTileToGroup(id) {
        if (!root.groupTilesEnabled) return false;
        if (root.groupedTileIds.indexOf(id) !== -1) return true;
        return root.groupedTileIds.length < 4;
    }

    function addTileToGroup(id) {
        if (root.groupedTileIds.indexOf(id) === -1) {
            if (root.groupedTileIds.length >= 4) return false;
            root.secondaryTileIds = root.secondaryTileIds.filter(tid => tid !== id);
            let copy = [...root.groupedTileIds, id];
            root.groupedTileIds = copy;
            root.setTileEnabled(id, true);
            root.saveConfig();
            return true;
        }
        return true;
    }

    function addTileToSecondary(id) {
        if (!root.getTileDef(id)) return false;
        root.groupedTileIds = root.groupedTileIds.filter(tid => tid !== id);
        if (root.secondaryTileIds.indexOf(id) === -1) {
            root.secondaryTileIds = [...root.secondaryTileIds, id];
        }
        root.setTileEnabled(id, false);
        if (!root.isCardVisible("quickSettings2")) {
            root.setCardVisible("quickSettings2", true);
        }
        root.saveConfig();
        return true;
    }

    function removeTileFromSecondary(id) {
        root.secondaryTileIds = root.secondaryTileIds.filter(tid => tid !== id);
        root.saveConfig();
    }

    function moveSecondaryTile(fromIdx, toIdx) {
        if (fromIdx < 0 || fromIdx >= root.secondaryTileIds.length) return;
        if (toIdx < 0 || toIdx >= root.secondaryTileIds.length) return;
        if (fromIdx === toIdx) return;
        let copy = [...root.secondaryTileIds];
        const item = copy.splice(fromIdx, 1)[0];
        copy.splice(toIdx, 0, item);
        root.secondaryTileIds = copy;
        root.saveConfig();
    }

    // Move tile from 2x2 Connectivity Group to Standalone Tiles (keeps tile enabled)
    function removeTileFromGroup(id) {
        let copy = root.groupedTileIds.filter(tid => tid !== id);
        root.groupedTileIds = copy;
        root.setTileEnabled(id, true);
        root.saveConfig();
    }

    // Remove tile completely from Connectivity Group, Primary Tiles, or Secondary Tiles to Available Pool
    function removeTileToPool(id) {
        if (root.groupedTileIds.indexOf(id) !== -1) {
            root.groupedTileIds = root.groupedTileIds.filter(tid => tid !== id);
        }
        if (root.secondaryTileIds.indexOf(id) !== -1) {
            root.secondaryTileIds = root.secondaryTileIds.filter(tid => tid !== id);
        }
        root.setTileEnabled(id, false);
        root.saveConfig();
    }

    function moveGroupedTile(fromIdx, toIdx) {
        if (fromIdx < 0 || fromIdx >= root.groupedTileIds.length) return;
        if (toIdx < 0 || toIdx >= root.groupedTileIds.length) return;
        if (fromIdx === toIdx) return;
        let copy = [...root.groupedTileIds];
        const item = copy.splice(fromIdx, 1)[0];
        copy.splice(toIdx, 0, item);
        root.groupedTileIds = copy;
        root.saveConfig();
    }

    function moveUngroupedTile(fromUngroupedIdx, toUngroupedIdx) {
        const list = root.groupTilesEnabled ? root.ungroupedTiles : root.enabledTiles;
        if (fromUngroupedIdx < 0 || fromUngroupedIdx >= list.length) return;
        if (toUngroupedIdx < 0 || toUngroupedIdx >= list.length) return;
        if (fromUngroupedIdx === toUngroupedIdx) return;

        const fromId = list[fromUngroupedIdx].id;
        const toId = list[toUngroupedIdx].id;

        let masterFrom = -1;
        let masterTo = -1;
        for (let i = 0; i < root.tiles.length; i++) {
            if (root.tiles[i].id === fromId) masterFrom = i;
            if (root.tiles[i].id === toId) masterTo = i;
        }
        if (masterFrom >= 0 && masterTo >= 0) {
            root.moveTile(masterFrom, masterTo);
        }
    }

    function moveTileToPanelAt(tileId, targetPanel, targetIdx) {
        if (!root.getTileDef(tileId)) return false;
        // targetPanel: -1 = pool, 1 = connectivity group (2x2), 2 = primary quick tiles, 3 = secondary quick tiles
        if (targetPanel === -1) {
            root.removeTileToPool(tileId);
            return true;
        }
        if (targetPanel === 1) {
            if (!root.groupTilesEnabled) return false;
            const inGroup = root.groupedTileIds.indexOf(tileId) !== -1;
            if (!inGroup && root.groupedTileIds.length >= 4) return false;
            root.secondaryTileIds = root.secondaryTileIds.filter(id => id !== tileId);
            let copy = root.groupedTileIds.filter(id => id !== tileId);
            const ins = (targetIdx >= 0 && targetIdx <= copy.length) ? targetIdx : copy.length;
            copy.splice(ins, 0, tileId);
            root.groupedTileIds = copy;
            root.setTileEnabled(tileId, true);
            root.saveConfig();
            return true;
        }
        if (targetPanel === 2) {
            if (root.groupedTileIds.indexOf(tileId) !== -1) {
                root.groupedTileIds = root.groupedTileIds.filter(id => id !== tileId);
            }
            if (root.secondaryTileIds.indexOf(tileId) !== -1) {
                root.secondaryTileIds = root.secondaryTileIds.filter(id => id !== tileId);
            }
            root.setTileEnabled(tileId, true);
            const list = root.groupTilesEnabled ? root.ungroupedTiles : root.enabledTiles;
            let curIdx = -1;
            for (let i = 0; i < list.length; i++) {
                if (list[i].id === tileId) { curIdx = i; break; }
            }
            if (curIdx >= 0 && targetIdx >= 0) {
                const clamped = Math.max(0, Math.min(list.length - 1, targetIdx));
                if (curIdx !== clamped) {
                    root.moveUngroupedTile(curIdx, clamped);
                }
            }
            return true;
        }
        if (targetPanel === 3) {
            if (root.groupedTileIds.indexOf(tileId) !== -1) {
                root.groupedTileIds = root.groupedTileIds.filter(id => id !== tileId);
            }
            root.setTileEnabled(tileId, false);
            let copy = root.secondaryTileIds.filter(id => id !== tileId);
            const ins = (targetIdx >= 0 && targetIdx <= copy.length) ? targetIdx : copy.length;
            copy.splice(ins, 0, tileId);
            root.secondaryTileIds = copy;
            root.saveConfig();
            return true;
        }
        return false;
    }

    // Quick Launch Apps Management (3 to 15 apps)
    function setQuickAppsMaxCount(val) {
        const clamped = Math.max(3, Math.min(15, Math.round(Number(val) || 8)));
        if (root.quickAppsMaxCount !== clamped) {
            root.quickAppsMaxCount = clamped;
            root.saveConfig();
        }
    }

    function addQuickApp(label, icon, cmd, desktopId) {
        const cleanLabel = String(label || "App").trim() || "App";
        const cleanIcon = String(icon || "󰀻").trim() || "󰀻";
        const cleanCmd = String(cmd || "").trim();
        const cleanDesktop = String(desktopId || "").trim();
        if (!cleanCmd && !cleanDesktop) return false;
        let copy = [...root.quickApps];
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

    function replaceQuickAppAt(index, label, icon, cmd, desktopId, fallbackList) {
        let copy = (fallbackList && fallbackList.length > root.quickApps.length)
            ? fallbackList.map(a => ({
                id: a.id || a.desktopId || ("app_" + Math.random()),
                desktopId: a.desktopId || "",
                label: a.label || "App",
                icon: a.icon || "󰀻",
                cmd: a.cmd || ""
            }))
            : [...root.quickApps];
        if (index < 0 || index >= 15) return false;
        const item = {
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

    function moveQuickAppInFullList(fromIdx, toIdx, fallbackList) {
        let copy = (fallbackList && fallbackList.length > root.quickApps.length)
            ? fallbackList.map(a => ({
                id: a.id || a.desktopId || ("app_" + Math.random()),
                desktopId: a.desktopId || "",
                label: a.label || "App",
                icon: a.icon || "󰀻",
                cmd: a.cmd || ""
            }))
            : [...root.quickApps];
        if (fromIdx < 0 || fromIdx >= copy.length) return;
        if (toIdx < 0 || toIdx >= copy.length) return;
        if (fromIdx === toIdx) return;
        const item = copy.splice(fromIdx, 1)[0];
        copy.splice(toIdx, 0, item);
        root.quickApps = copy.slice(0, 15);
        root.saveConfig();
    }

    function updateQuickApp(index, label, icon, cmd, desktopId) {
        if (index < 0 || index >= root.quickApps.length) return false;
        let copy = [...root.quickApps];
        const prev = copy[index];
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

    function removeQuickApp(index) {
        if (index < 0 || index >= root.quickApps.length) return;
        let copy = [...root.quickApps];
        copy.splice(index, 1);
        root.quickApps = copy;
        if (root.quickAppsMaxCount > Math.max(3, copy.length) && copy.length >= 3) {
            root.quickAppsMaxCount = copy.length;
        }
        root.saveConfig();
    }

    function moveQuickApp(fromIdx, toIdx) {
        if (fromIdx < 0 || fromIdx >= root.quickApps.length) return;
        if (toIdx < 0 || toIdx >= root.quickApps.length) return;
        if (fromIdx === toIdx) return;
        let copy = [...root.quickApps];
        const item = copy.splice(fromIdx, 1)[0];
        copy.splice(toIdx, 0, item);
        root.quickApps = copy;
        root.saveConfig();
    }

    function resetQuickApps() {
        root.quickAppsMaxCount = 8;
        root.quickApps = JSON.parse(JSON.stringify(root.defaultQuickApps));
        root.saveConfig();
    }

    function setMediaWidgetStyle(style) {
        const val = (style === "full") ? "full" : ((style === "compact") ? "compact" : "auto");
        if (root.mediaWidgetStyle !== val) {
            root.mediaWidgetStyle = val;
            root.saveConfig();
        }
    }

    function setMediaShowCava(enabled) {
        const val = Boolean(enabled);
        if (root.mediaShowCava !== val) {
            root.mediaShowCava = val;
            root.saveConfig();
        }
    }

    function setGroupTilesEnabled(enabled) {
        const val = Boolean(enabled);
        if (root.groupTilesEnabled !== val) {
            root.groupTilesEnabled = val;
            root.saveConfig();
        }
    }

    // Interactive live edit state on the control center UI
    property bool isLiveEdit: false

    // Filtered list of currently unassigned / available tiles (available pool)
    readonly property var unassignedTiles: {
        let res = [];
        const qs2Active = root.isCardVisible("quickSettings2");
        for (let i = 0; i < root.allTileDefs.length; i++) {
            const def = root.allTileDefs[i];
            const inGroup = (root.isCardVisible("connectivity") || root.groupTilesEnabled) && root.groupedTileIds.indexOf(def.id) !== -1;
            const inSec = qs2Active && root.secondaryTileIds.indexOf(def.id) !== -1;
            if (!root.isTileEnabled(def.id) && !inGroup && !inSec) {
                res.push({
                    id: def.id,
                    label: def.label,
                    icon: def.icon,
                    desc: def.desc
                });
            }
        }
        return res;
    }

    function addTile(id) {
        if (root.isCardVisible("quickSettings2") && (!root.isCardVisible("quickSettings") || root.secondaryTiles.length < root.ungroupedTiles.length)) {
            root.addTileToSecondary(id);
            return;
        }
        setTileEnabled(id, true);
    }

    function removeTile(id) {
        removeTileToPool(id);
    }

    function getTileDef(id) {
        for (let i = 0; i < allTileDefs.length; i++) {
            if (allTileDefs[i].id === id) return allTileDefs[i];
        }
        return null;
    }

    function isTileEnabled(id) {
        for (let i = 0; i < root.tiles.length; i++) {
            if (root.tiles[i].id === id) return Boolean(root.tiles[i].enabled);
        }
        return false;
    }

    function setTileEnabled(id, enabled) {
        let copy = [];
        let found = false;
        for (let i = 0; i < root.tiles.length; i++) {
            let item = Object.assign({}, root.tiles[i]);
            if (item.id === id) {
                item.enabled = Boolean(enabled);
                found = true;
            }
            copy.push(item);
        }
        if (!found) {
            copy.push({ id: id, enabled: Boolean(enabled) });
        }
        root.tiles = copy;
        root.saveConfig();
    }

    function moveTile(fromIndex, toIndex) {
        if (fromIndex < 0 || fromIndex >= root.tiles.length) return;
        if (toIndex < 0 || toIndex >= root.tiles.length) return;
        if (fromIndex === toIndex) return;

        let copy = [...root.tiles];
        const item = copy.splice(fromIndex, 1)[0];
        copy.splice(toIndex, 0, item);
        root.tiles = copy;
        root.saveConfig();
    }

    function moveEnabledTile(fromEnabledIndex, toEnabledIndex) {
        if (fromEnabledIndex < 0 || fromEnabledIndex >= root.enabledTiles.length) return;
        if (toEnabledIndex < 0 || toEnabledIndex >= root.enabledTiles.length) return;
        if (fromEnabledIndex === toEnabledIndex) return;

        const fromId = root.enabledTiles[fromEnabledIndex].id;
        const toId = root.enabledTiles[toEnabledIndex].id;

        let masterFrom = -1;
        let masterTo = -1;
        for (let i = 0; i < root.tiles.length; i++) {
            if (root.tiles[i].id === fromId) masterFrom = i;
            if (root.tiles[i].id === toId) masterTo = i;
        }

        if (masterFrom >= 0 && masterTo >= 0) {
            root.moveTile(masterFrom, masterTo);
        }
    }

    function setPanelWidth(val) {
        const clamped = Math.max(280, Math.min(460, Math.round(Number(val) || 320)));
        if (root.panelWidth !== clamped) {
            root.panelWidth = clamped;
            root.saveConfig();
        }
    }

    function setCardVisible(cardName, visible) {
        const val = Boolean(visible);
        if (cardName === "header") {
            if (root.showHeader !== val) { root.showHeader = val; root.saveConfig(); }
            return;
        }
        if (cardName === "viewSwitcher") {
            if (root.showViewSwitcher !== val) { root.showViewSwitcher = val; root.saveConfig(); }
            return;
        }
        if (cardName === "mediaAutoHide") {
            if (root.mediaAutoHide !== val) { root.mediaAutoHide = val; root.saveConfig(); }
            return;
        }
        if (!root.getCardDef(cardName)) return;
        if (val) {
            if (!root.isCardVisible(cardName)) {
                root.insertCardAtEnabledIndex(cardName, -1);
            }
        } else {
            if (root.isCardVisible(cardName)) {
                root.moveCardToPanelAt(cardName, -1, -1);
            }
        }
    }

    function setPanelLayout(layout) {
        const val = (layout === "horizontal") ? "horizontal" : "vertical";
        if (root.panelLayout !== val) {
            root.panelLayout = val;
            root.saveConfig();
        }
    }

    function setPanelCount(targetCount) {
        const clamped = Math.max(1, Math.min(3, Math.round(Number(targetCount) || 3)));
        if (root.panelCount === clamped && root.panelLayout === (clamped > 1 ? "horizontal" : "vertical")) return;
        root.panelCount = clamped;
        root.panelLayout = clamped > 1 ? "horizontal" : "vertical";
        root.cardOrderRevision++;
        root.cardsUpdated();
        root.saveConfig();
    }

    function resetDefaults() {
        root.panelWidth = 320;
        root.panelLayout = "horizontal";
        root.panelCount = 3;
        root.panel1 = ["connectivity", "quickSettings", "systemInfo"];
        root.panel2 = ["brightness", "media"];
        root.panel3 = ["audio"];
        root.groupTilesEnabled = true;
        root.groupedTileIds = ["wifi", "bluetooth", "dnd", "airplane"];
        root.secondaryTileIds = ["mute", "gamemode", "clipboard", "darkmode"];
        root.quickAppsMaxCount = 8;
        root.quickApps = JSON.parse(JSON.stringify(root.defaultQuickApps));
        root.mediaWidgetStyle = "auto";
        root.showHeader = true;
        root.showViewSwitcher = true;
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

    property bool _loaded: false
    property string _lastSavedJson: ""

    function saveConfig() {
        if (!root._loaded) return;
        const data = {
            width: root.panelWidth,
            panelLayout: root.panelLayout,
            panelCount: root.panelCount,
            panel1: root.panel1,
            panel2: root.panel2,
            panel3: root.panel3,
            groupTilesEnabled: root.groupTilesEnabled,
            groupedTileIds: root.groupedTileIds,
            secondaryTileIds: root.secondaryTileIds,
            quickAppsMaxCount: root.quickAppsMaxCount,
            quickApps: root.quickApps,
            mediaWidgetStyle: root.mediaWidgetStyle,
            cards: {
                header: root.showHeader,
                viewSwitcher: root.showViewSwitcher
            },
            mediaAutoHide: root.mediaAutoHide,
            mediaShowCava: root.mediaShowCava,
            tiles: root.tiles
        };
        const jsonStr = JSON.stringify(data, null, 2);
        root._lastSavedJson = jsonStr;
        saveProcess.command = [
            "python3", "-c",
            "import os, sys; p = sys.argv[1]; tmp = p + '.tmp'; open(tmp, 'w').write(sys.argv[2] + '\\n'); os.replace(tmp, p)",
            root.configPath,
            jsonStr
        ];
        saveProcess.running = true;
    }

    function sanitizePanelList(arr, seenMap) {
        let res = [];
        if (!Array.isArray(arr)) return res;
        for (let i = 0; i < arr.length; i++) {
            const cid = arr[i];
            if (cid && root.getCardDef(cid) && !seenMap[cid]) {
                res.push(cid);
                seenMap[cid] = true;
            }
        }
        return res;
    }

    function applyConfig(cfg) {
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
            if (cfg.cards.viewSwitcher !== undefined) root.showViewSwitcher = Boolean(cfg.cards.viewSwitcher);
        }
        if (cfg.mediaAutoHide !== undefined) root.mediaAutoHide = Boolean(cfg.mediaAutoHide);
        if (cfg.mediaShowCava !== undefined) root.mediaShowCava = Boolean(cfg.mediaShowCava);

        if (Array.isArray(cfg.panel1) || Array.isArray(cfg.panel2) || Array.isArray(cfg.panel3)) {
            let seen = {};
            root.panel1 = root.sanitizePanelList(cfg.panel1, seen);
            root.panel2 = root.sanitizePanelList(cfg.panel2, seen);
            root.panel3 = root.sanitizePanelList(cfg.panel3, seen);
            root.cardOrderRevision++;
            root.cardsUpdated();
        } else if (cfg.cards) {
            // Migrate legacy single-list config into 3 balanced panel columns
            let p0 = [];
            let p1 = [];
            let p2 = [];
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
            let knownMap = {};
            let merged = [];
            for (let i = 0; i < cfg.tiles.length; i++) {
                const t = cfg.tiles[i];
                if (t && t.id && root.getTileDef(t.id)) {
                    merged.push({ id: t.id, enabled: Boolean(t.enabled) });
                    knownMap[t.id] = true;
                }
            }
            for (let j = 0; j < root.allTileDefs.length; j++) {
                const defId = root.allTileDefs[j].id;
                if (!knownMap[defId]) {
                    merged.push({ id: defId, enabled: false });
                }
            }
            root.tiles = merged;
        }
    }

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        onTextChanged: {
            const raw = configFile.text();
            if (!raw) {
                root._loaded = true;
                return;
            }
            if (root._lastSavedJson !== "" && raw.trim() === root._lastSavedJson.trim()) {
                root._loaded = true;
                return;
            }
            try {
                const parsed = JSON.parse(raw);
                root.applyConfig(parsed);
            } catch (e) {
                console.error("Failed to parse control_center_config.json:", e);
            } finally {
                root._loaded = true;
            }
        }
    }

    Process {
        id: saveProcess
        running: false
    }

    Component.onCompleted: {
        const raw = configFile.text();
        if (raw) {
            try {
                root.applyConfig(JSON.parse(raw));
            } catch (e) {}
        }
        root._loaded = true;
    }
}
