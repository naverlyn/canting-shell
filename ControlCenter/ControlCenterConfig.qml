pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "ControlCenterConfigUtils.js" as ConfigUtils

Singleton {
    id: root

    readonly property string configPath: Qt.resolvedUrl("../configs/control_center_config.json").toString().replace(/^file:\/\//, "")

    property int panelWidth: 320
    property bool showHeader: true
    property bool mediaAutoHide: true
    property bool mediaShowCava: false
    property string panelLayout: "horizontal"
    property int panelCount: 3
    property var panel1: ["connectivity", "quickSettings", "systemInfo"]
    property var panel2: ["brightness", "media"]
    property var panel3: ["audio"]
    property bool groupTilesEnabled: true

    // Connectivity group grid size: N columns, up to N x N tiles (2x2 .. 6x6)
    property int groupSize: 2
    readonly property int groupCapacity: root.groupSize * root.groupSize

    function setGroupSize(n) {
        const size = Math.max(2, Math.min(6, Math.round(Number(n) || 2)));
        if (size === root.groupSize) return;
        root.groupSize = size;
        const cap = size * size;
        if (root.groupedTileIds.length > cap) {
            // Tiles that no longer fit go back to the Available Tiles pool
            const overflow = root.groupedTileIds.slice(cap);
            root.groupedTileIds = root.groupedTileIds.slice(0, cap);
            for (let i = 0; i < overflow.length; i++) root.setTileEnabled(overflow[i], false);
        }
        root.saveConfig();
    }

    function cycleGroupSize() {
        root.setGroupSize(root.groupSize >= 6 ? 2 : root.groupSize + 1);
        return root.groupSize;
    }

    // User-editable titles for the tile cards (empty string hides the title)
    property var cardTitles: ({})
    readonly property var defaultCardTitles: ({ connectivity: "Connectivity", quickSettings: "Quick Tiles", quickSettings2: "Quick Tiles 2" })

    function getCardTitle(id) {
        if (root.cardTitles && root.cardTitles[id] !== undefined) return root.cardTitles[id];
        return root.defaultCardTitles[id] !== undefined ? root.defaultCardTitles[id] : "";
    }

    function setCardTitle(id, text) {
        const t = String(text).trim();
        if (t === root.getCardTitle(id)) return;
        let copy = Object.assign({}, root.cardTitles);
        copy[id] = t;
        root.cardTitles = copy;
        root.saveConfig();
    }
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
    readonly property bool showNotifications: isCardVisible("notifications")

    // Master list of all available building-block modules
    readonly property var allCardDefs: [
        { id: "connectivity",   label: "Connectivity",       icon: "󰖩", desc: "Wi-Fi, Bluetooth, DND & Airplane tile grid (2x2 up to 6x6)" },
        { id: "quickSettings",  label: "Quick Tiles",        icon: "󰒓", desc: "Primary system toggle tiles grid" },
        { id: "quickSettings2", label: "Quick Tiles 2",      icon: "󰕰", desc: "Secondary quick toggle tiles grid for another panel" },
        { id: "brightness",     label: "Brightness",         icon: "󰃠", desc: "Screen backlight brightness slider" },
        { id: "audio",          label: "Volume & Sound",     icon: "󰕾", desc: "Speaker & microphone volume sliders" },
        { id: "media",          label: "Media Player",       icon: "󰝚", desc: "MPRIS playback & controls (Auto / Compact / Full)" },
        { id: "systemInfo",     label: "System Resources",   icon: "󰍛", desc: "CPU, memory, disk & thermals overview" },
        { id: "cava",           label: "Cava Visualizer",    icon: "",   desc: "Real-time Cava audio spectrum visualizer" },
        { id: "weather",        label: "Weather",            icon: "󰖐", desc: "Live weather conditions, temperature & wind" },
        { id: "quickApps",      label: "Quick Launch",       icon: "󰀻", desc: "Fast shortcuts to favorite desktop apps" },
        { id: "notifications",  label: "Notifications",      icon: "󰂚", desc: "Notification history, grouped alerts & actions" }
    ]

    signal cardsUpdated()
    property int cardOrderRevision: 0

    // Individual quick tiles can be placed straight into a panel as "tile:<tileId>" modules.
    function isTileCardId(id) {
        return typeof id === "string" && id.indexOf("tile:") === 0;
    }

    function tileInPanel(tileId) {
        return root.isCardVisible("tile:" + tileId);
    }

    // Remove a tile module from every panel (does not save; callers save).
    function dropTileFromPanels(tileId) {
        const cid = "tile:" + tileId;
        const p0 = root.panel1.filter(id => id !== cid);
        const p1 = root.panel2.filter(id => id !== cid);
        const p2 = root.panel3.filter(id => id !== cid);
        if (p0.length === root.panel1.length && p1.length === root.panel2.length && p2.length === root.panel3.length) return;
        root.panel1 = p0;
        root.panel2 = p1;
        root.panel3 = p2;
        root.cardOrderRevision++;
        root.cardsUpdated();
    }

    function getCardDef(id) {
        if (root.isTileCardId(id)) {
            const td = root.getTileDef(id.substring(5));
            if (!td) return null;
            return { id: id, label: td.label, icon: td.icon, desc: td.desc, isTile: true };
        }
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

        // A tile placed in a panel no longer belongs to any Quick Tiles card
        if (root.isTileCardId(cardId) && targetPanelIdx >= 0 && targetPanelIdx < 3) {
            const tid = cardId.substring(5);
            root.groupedTileIds = root.groupedTileIds.filter(t => t !== tid);
            root.secondaryTileIds = root.secondaryTileIds.filter(t => t !== tid);
            root.setTileEnabled(tid, false);
        }

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
        return root.groupedTileIds.length < root.groupCapacity;
    }

    function addTileToGroup(id) {
        root.dropTileFromPanels(id);
        if (root.groupedTileIds.indexOf(id) === -1) {
            if (root.groupedTileIds.length >= root.groupCapacity) return false;
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
        root.dropTileFromPanels(id);
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
        root.dropTileFromPanels(id);
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
        if (targetPanel !== -1) root.dropTileFromPanels(tileId);
        // targetPanel: -1 = pool, 1 = connectivity group (2x2), 2 = primary quick tiles, 3 = secondary quick tiles
        if (targetPanel === -1) {
            root.removeTileToPool(tileId);
            return true;
        }
        if (targetPanel === 1) {
            if (!root.groupTilesEnabled) return false;
            const inGroup = root.groupedTileIds.indexOf(tileId) !== -1;
            if (!inGroup && root.groupedTileIds.length >= root.groupCapacity) return false;
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
        return ConfigUtils.addQuickApp(root, label, icon, cmd, desktopId);
    }

    function replaceQuickAppAt(index, label, icon, cmd, desktopId, fallbackList) {
        return ConfigUtils.replaceQuickAppAt(root, index, label, icon, cmd, desktopId, fallbackList);
    }

    function moveQuickAppInFullList(fromIdx, toIdx, fallbackList) {
        ConfigUtils.moveQuickAppInFullList(root, fromIdx, toIdx, fallbackList);
    }

    function updateQuickApp(index, label, icon, cmd, desktopId) {
        return ConfigUtils.updateQuickApp(root, index, label, icon, cmd, desktopId);
    }

    function removeQuickApp(index) {
        ConfigUtils.removeQuickApp(root, index);
    }

    function moveQuickApp(fromIdx, toIdx) {
        ConfigUtils.moveQuickApp(root, fromIdx, toIdx);
    }

    function resetQuickApps() {
        ConfigUtils.resetQuickApps(root);
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
            if (!root.isTileEnabled(def.id) && !inGroup && !inSec && !root.tileInPanel(def.id)) {
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
        if (enabled) root.dropTileFromPanels(id);
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
        if (cardName === "mediaAutoHide") {
            if (root.mediaAutoHide !== val) { root.mediaAutoHide = val; root.saveConfig(); }
            return;
        }
        if (!root.getCardDef(cardName)) return;
        if (val) {
            if (!root.isCardVisible(cardName)) {
                // Re-adding an emptied Connectivity card restores its default 2x2 tiles
                if (cardName === "connectivity" && root.groupedTileIds.length === 0) {
                    const defaults = ["wifi", "bluetooth", "dnd", "airplane"];
                    root.secondaryTileIds = root.secondaryTileIds.filter(t => defaults.indexOf(t) === -1);
                    for (let i = 0; i < defaults.length; i++) root.dropTileFromPanels(defaults[i]);
                    root.groupTilesEnabled = true;
                    root.groupedTileIds = defaults;
                    for (let i = 0; i < defaults.length; i++) root.setTileEnabled(defaults[i], true);
                }
                root.insertCardAtEnabledIndex(cardName, -1);
            }
        } else {
            if (root.isCardVisible(cardName)) {
                // Removing a tile card detaches its tiles: they return to the Available Tiles pool
                let released = [];
                if (cardName === "connectivity") {
                    released = root.groupedTileIds.slice();
                    root.groupedTileIds = [];
                } else if (cardName === "quickSettings2") {
                    released = root.secondaryTileIds.slice();
                    root.secondaryTileIds = [];
                } else if (cardName === "quickSettings") {
                    released = root.ungroupedTiles.map(t => t.id);
                }
                root.moveCardToPanelAt(cardName, -1, -1);
                for (let i = 0; i < released.length; i++) root.setTileEnabled(released[i], false);
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
        ConfigUtils.resetDefaults(root);
    }

    property bool _loaded: false
    property string _lastSavedJson: ""
    property bool _savePending: false

    Timer {
        id: saveDebounceTimer
        interval: 150
        repeat: false
        onTriggered: root._flushSaveConfig()
    }

    function saveConfig() {
        if (!root._loaded) return;
        saveDebounceTimer.restart();
    }

    function _flushSaveConfig() {
        if (!root._loaded) return;
        if (saveProcess.running) {
            root._savePending = true;
            return;
        }
        root._savePending = false;
        const jsonStr = JSON.stringify(ConfigUtils.buildConfigData(root), null, 2);
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
        return ConfigUtils.sanitizePanelList(root, arr, seenMap);
    }

    function applyConfig(cfg) {
        ConfigUtils.applyConfig(root, cfg);
    }

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        onFileChanged: configFile.reload()
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
        onExited: {
            if (root._savePending) {
                root._savePending = false;
                root._flushSaveConfig();
            }
        }
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
