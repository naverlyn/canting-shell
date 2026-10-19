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
    property bool showQuickSettings: true
    property bool showBrightness: false
    property bool showAudio: true
    property bool showMedia: true
    property bool showSystemInfo: false
    property bool mediaAutoHide: false
    property string panelLayout: "vertical"
    property bool groupTilesEnabled: true
    property var groupedTileIds: ["wifi", "bluetooth", "dnd", "airplane"]
    property string mediaWidgetStyle: "compact"

    // Master list of all available card metadata
    readonly property var allCardDefs: [
        { id: "quickSettings", label: "Quick Settings",   icon: "󰒓", desc: "Network & system toggle tiles" },
        { id: "brightness",    label: "Brightness",       icon: "󰃠", desc: "Screen backlight brightness slider" },
        { id: "audio",         label: "Volume & Sound",   icon: "󰕾", desc: "Speaker & microphone volume sliders" },
        { id: "media",         label: "Media Player",     icon: "󰝚", desc: "MPRIS playback & controls" },
        { id: "systemInfo",    label: "System Resources", icon: "󰍛", desc: "CPU, memory, disk & thermals overview" }
    ]

    // Active order of card sections (supports up to 5 panels)
    signal cardsUpdated()
    property int cardOrderRevision: 0
    property var cardOrder: ["quickSettings", "brightness", "audio", "media", "systemInfo"]

    function getCardDef(id) {
        for (let i = 0; i < allCardDefs.length; i++) {
            if (allCardDefs[i].id === id) return allCardDefs[i];
        }
        return { id: id, label: id, icon: "󰒓", desc: "" };
    }

    function getEnabledCardIndex(id) {
        for (let i = 0; i < root.enabledCards.length; i++) {
            if (root.enabledCards[i].id === id) return i;
        }
        return -1;
    }

    function isCardVisible(id) {
        switch (id) {
            case "quickSettings": return root.showQuickSettings;
            case "brightness": return root.showBrightness;
            case "audio": return root.showAudio;
            case "media": return root.showMedia;
            case "systemInfo": return root.showSystemInfo;
            default: return false;
        }
    }

    // Filtered list of visible cards in order
    readonly property var enabledCards: {
        let res = [];
        for (let i = 0; i < root.cardOrder.length; i++) {
            const cid = root.cardOrder[i];
            if (root.isCardVisible(cid)) {
                res.push(root.getCardDef(cid));
            }
        }
        return res;
    }

    // Filtered list of hidden/unassigned cards (for the add pool)
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

    function moveCard(fromIndex, toIndex) {
        if (fromIndex < 0 || fromIndex >= root.cardOrder.length) return;
        if (toIndex < 0 || toIndex >= root.cardOrder.length) return;
        if (fromIndex === toIndex) return;

        let copy = [...root.cardOrder];
        const item = copy.splice(fromIndex, 1)[0];
        copy.splice(toIndex, 0, item);
        root.cardOrder = copy;
        root.cardOrderRevision++;
        root.cardsUpdated();
        root.saveConfig();
    }

    function moveEnabledCard(fromEnabledIndex, toEnabledIndex) {
        if (fromEnabledIndex < 0 || fromEnabledIndex >= root.enabledCards.length) return;
        if (toEnabledIndex < 0 || toEnabledIndex >= root.enabledCards.length) return;
        if (fromEnabledIndex === toEnabledIndex) return;

        const fromId = root.enabledCards[fromEnabledIndex].id;
        const toId = root.enabledCards[toEnabledIndex].id;

        let masterFrom = -1;
        let masterTo = -1;
        for (let i = 0; i < root.cardOrder.length; i++) {
            if (root.cardOrder[i] === fromId) masterFrom = i;
            if (root.cardOrder[i] === toId) masterTo = i;
        }

        if (masterFrom >= 0 && masterTo >= 0) {
            root.moveCard(masterFrom, masterTo);
        }
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
        { id: "bluetooth", enabled: false },
        { id: "airplane", enabled: false }
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

    // Ungrouped standalone tiles (Screenshot, Clipboard, etc.)
    readonly property var ungroupedTiles: {
        let res = [];
        for (let i = 0; i < root.enabledTiles.length; i++) {
            const t = root.enabledTiles[i];
            if (!root.groupTilesEnabled || root.groupedTileIds.indexOf(t.id) === -1) {
                res.push(t);
            }
        }
        return res;
    }

    function isTileInGroup(id) {
        return root.groupTilesEnabled && root.groupedTileIds.indexOf(id) !== -1;
    }

    function addTileToGroup(id) {
        if (root.groupedTileIds.indexOf(id) === -1) {
            let copy = [...root.groupedTileIds];
            if (copy.length >= 4) {
                copy[3] = id;
            } else {
                copy.push(id);
            }
            root.groupedTileIds = copy;
            root.setTileEnabled(id, true);
            root.saveConfig();
        }
    }

    function removeTileFromGroup(id) {
        let copy = root.groupedTileIds.filter(tid => tid !== id);
        root.groupedTileIds = copy;
        root.saveConfig();
    }

    function setMediaWidgetStyle(style) {
        const val = (style === "full") ? "full" : "compact";
        if (root.mediaWidgetStyle !== val) {
            root.mediaWidgetStyle = val;
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
        for (let i = 0; i < root.allTileDefs.length; i++) {
            const def = root.allTileDefs[i];
            if (!root.isTileEnabled(def.id)) {
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
        setTileEnabled(id, true);
    }

    function removeTile(id) {
        setTileEnabled(id, false);
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
        let changed = false;
        switch (cardName) {
            case "header":
                if (root.showHeader !== val) { root.showHeader = val; changed = true; }
                break;
            case "viewSwitcher":
                if (root.showViewSwitcher !== val) { root.showViewSwitcher = val; changed = true; }
                break;
            case "quickSettings":
                if (root.showQuickSettings !== val) { root.showQuickSettings = val; changed = true; }
                break;
            case "brightness":
                if (root.showBrightness !== val) { root.showBrightness = val; changed = true; }
                break;
            case "audio":
                if (root.showAudio !== val) { root.showAudio = val; changed = true; }
                break;
            case "media":
                if (root.showMedia !== val) { root.showMedia = val; changed = true; }
                break;
            case "systemInfo":
                if (root.showSystemInfo !== val) { root.showSystemInfo = val; changed = true; }
                break;
            case "mediaAutoHide":
                if (root.mediaAutoHide !== val) { root.mediaAutoHide = val; changed = true; }
                break;
        }
        if (val && root.cardOrder.indexOf(cardName) === -1 && root.getCardDef(cardName)) {
            root.cardOrder = [...root.cardOrder, cardName];
            changed = true;
        }
        if (changed) {
            root.cardOrderRevision++;
            root.cardsUpdated();
            root.saveConfig();
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
        const clamped = Math.max(1, Math.min(5, Math.round(Number(targetCount) || 3)));
        let currentCount = root.enabledCards.length;
        if (currentCount === clamped) return;

        if (currentCount < clamped) {
            for (let i = 0; i < root.cardOrder.length; i++) {
                const cid = root.cardOrder[i];
                if (!root.isCardVisible(cid)) {
                    root.setCardVisible(cid, true);
                    if (root.enabledCards.length >= clamped) break;
                }
            }
        } else {
            while (root.enabledCards.length > clamped) {
                const last = root.enabledCards[root.enabledCards.length - 1];
                root.setCardVisible(last.id, false);
            }
        }
    }

    function resetDefaults() {
        root.panelWidth = 320;
        root.panelLayout = "vertical";
        root.groupTilesEnabled = true;
        root.groupedTileIds = ["wifi", "bluetooth", "dnd", "airplane"];
        root.mediaWidgetStyle = "compact";
        root.showHeader = true;
        root.showViewSwitcher = true;
        root.showQuickSettings = true;
        root.showBrightness = false;
        root.showAudio = true;
        root.showMedia = true;
        root.showSystemInfo = false;
        root.mediaAutoHide = false;
        root.cardOrder = ["quickSettings", "brightness", "audio", "media", "systemInfo"];
        root.tiles = [
            { id: "wifi", enabled: true },
            { id: "nightlight", enabled: true },
            { id: "caffeine", enabled: true },
            { id: "dnd", enabled: true },
            { id: "mic", enabled: true },
            { id: "screenshot", enabled: true },
            { id: "lock", enabled: true },
            { id: "bluetooth", enabled: false },
            { id: "airplane", enabled: false }
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
            groupTilesEnabled: root.groupTilesEnabled,
            groupedTileIds: root.groupedTileIds,
            mediaWidgetStyle: root.mediaWidgetStyle,
            cards: {
                header: root.showHeader,
                viewSwitcher: root.showViewSwitcher,
                quickSettings: root.showQuickSettings,
                brightness: root.showBrightness,
                audio: root.showAudio,
                media: root.showMedia,
                systemInfo: root.showSystemInfo
            },
            mediaAutoHide: root.mediaAutoHide,
            cardOrder: root.cardOrder,
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

    function applyConfig(cfg) {
        if (!cfg) return;
        if (cfg.width !== undefined) {
            root.panelWidth = Math.max(280, Math.min(460, Math.round(Number(cfg.width) || 320)));
        }
        if (cfg.panelLayout !== undefined) {
            root.panelLayout = (cfg.panelLayout === "horizontal") ? "horizontal" : "vertical";
        }
        if (cfg.groupTilesEnabled !== undefined) {
            root.groupTilesEnabled = Boolean(cfg.groupTilesEnabled);
        }
        if (Array.isArray(cfg.groupedTileIds)) {
            root.groupedTileIds = cfg.groupedTileIds;
        }
        if (cfg.mediaWidgetStyle !== undefined) {
            root.mediaWidgetStyle = (cfg.mediaWidgetStyle === "full") ? "full" : "compact";
        }
        if (cfg.cards) {
            if (cfg.cards.header !== undefined) root.showHeader = Boolean(cfg.cards.header);
            if (cfg.cards.viewSwitcher !== undefined) root.showViewSwitcher = Boolean(cfg.cards.viewSwitcher);
            if (cfg.cards.quickSettings !== undefined) root.showQuickSettings = Boolean(cfg.cards.quickSettings);
            if (cfg.cards.brightness !== undefined) root.showBrightness = Boolean(cfg.cards.brightness);
            if (cfg.cards.audio !== undefined) root.showAudio = Boolean(cfg.cards.audio);
            if (cfg.cards.media !== undefined) root.showMedia = Boolean(cfg.cards.media);
            if (cfg.cards.systemInfo !== undefined) root.showSystemInfo = Boolean(cfg.cards.systemInfo);
        }
        if (cfg.mediaAutoHide !== undefined) root.mediaAutoHide = Boolean(cfg.mediaAutoHide);

        if (Array.isArray(cfg.cardOrder)) {
            let knownCard = {};
            let mergedCards = [];
            for (let c = 0; c < cfg.cardOrder.length; c++) {
                const cid = cfg.cardOrder[c];
                if (cid && root.getCardDef(cid) && !knownCard[cid]) {
                    mergedCards.push(cid);
                    knownCard[cid] = true;
                }
            }
            for (let d = 0; d < root.allCardDefs.length; d++) {
                const defId = root.allCardDefs[d].id;
                if (!knownCard[defId]) {
                    mergedCards.push(defId);
                }
            }
            root.cardOrder = mergedCards;
            root.cardOrderRevision++;
            root.cardsUpdated();
        }

        if (Array.isArray(cfg.tiles)) {
            // Merge with all known tile definitions so new tiles appear
            let knownMap = {};
            let merged = [];
            for (let i = 0; i < cfg.tiles.length; i++) {
                const t = cfg.tiles[i];
                if (t && t.id && root.getTileDef(t.id)) {
                    merged.push({ id: t.id, enabled: Boolean(t.enabled) });
                    knownMap[t.id] = true;
                }
            }
            // Append any missing tiles from default definitions
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
