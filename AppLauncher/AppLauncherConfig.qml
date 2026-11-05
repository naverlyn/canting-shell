pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configPath: Qt.resolvedUrl("../app_launcher_config.json").toString().replace(/^file:\/\//, "")
    readonly property string usageCachePath: "$HOME/.cache/qs_app_usage.json"

    // Configuration Properties
    property int spotlightWidth: 620
    property int spotlightHeight: 480
    property string defaultMode: "apps" // "apps" or "command"
    property string sortMode: "frecency" // "frecency", "alphabetical", "recent"
    property bool matchGenericName: true
    property bool matchKeywords: true
    property bool matchCategories: true
    property bool clearSearchOnClose: true
    property int gridColumns: 5
    property int gridCellSize: 96
    property var hiddenApps: []
    property var favoriteApps: []

    property bool _loaded: false

    signal configChanged()
    signal usageCleared()

    readonly property var sortOptions: [
        { id: "frecency",     label: "Frecency (Smart)",  desc: "Combines frequency and recency of launches" },
        { id: "alphabetical", label: "Alphabetical (A-Z)", desc: "Sorts applications from A to Z" },
        { id: "recent",       label: "Recently Used",     desc: "Shows most recently launched applications first" }
    ]

    readonly property var modeOptions: [
        { id: "apps",    label: "Applications",    desc: "Open directly in application search mode" },
        { id: "command", label: "Execute Command", desc: "Open directly in terminal command runner mode" }
    ]

    function isAppHidden(appKey) {
        if (!appKey || !root.hiddenApps) return false;
        return root.hiddenApps.indexOf(appKey) !== -1;
    }

    function toggleHiddenApp(appKey) {
        if (!appKey) return;
        let list = [...(root.hiddenApps || [])];
        const idx = list.indexOf(appKey);
        if (idx !== -1) {
            list.splice(idx, 1);
        } else {
            list.push(appKey);
        }
        root.hiddenApps = list;
        root.saveConfig();
        root.configChanged();
    }

    function isAppFavorite(appKey) {
        if (!appKey || !root.favoriteApps) return false;
        return root.favoriteApps.indexOf(appKey) !== -1;
    }

    function toggleFavoriteApp(appKey) {
        if (!appKey) return;
        let list = [...(root.favoriteApps || [])];
        const idx = list.indexOf(appKey);
        if (idx !== -1) {
            list.splice(idx, 1);
        } else {
            list.push(appKey);
        }
        root.favoriteApps = list;
        root.saveConfig();
        root.configChanged();
    }

    function setSpotlightWidth(val) {
        const clamped = Math.max(480, Math.min(840, Math.round(Number(val) || 620)));
        if (root.spotlightWidth !== clamped) {
            root.spotlightWidth = clamped;
            saveDebounceTimer.restart();
        }
    }

    function setSpotlightHeight(val) {
        const clamped = Math.max(360, Math.min(680, Math.round(Number(val) || 480)));
        if (root.spotlightHeight !== clamped) {
            root.spotlightHeight = clamped;
            saveDebounceTimer.restart();
        }
    }

    function setDefaultMode(mode) {
        if (mode === "apps" || mode === "command") {
            if (root.defaultMode !== mode) {
                root.defaultMode = mode;
                root.saveConfig();
            }
        }
    }

    function setSortMode(sMode) {
        if (["frecency", "alphabetical", "recent"].indexOf(sMode) !== -1) {
            if (root.sortMode !== sMode) {
                root.sortMode = sMode;
                root.saveConfig();
            }
        }
    }

    function setGridColumns(cols) {
        const clamped = Math.max(3, Math.min(8, Math.round(Number(cols) || 5)));
        if (root.gridColumns !== clamped) {
            root.gridColumns = clamped;
            saveDebounceTimer.restart();
        }
    }

    function setGridCellSize(size) {
        const clamped = Math.max(72, Math.min(128, Math.round(Number(size) || 96)));
        if (root.gridCellSize !== clamped) {
            root.gridCellSize = clamped;
            saveDebounceTimer.restart();
        }
    }

    function setMatchGenericName(val) {
        root.matchGenericName = Boolean(val);
        root.saveConfig();
    }

    function setMatchKeywords(val) {
        root.matchKeywords = Boolean(val);
        root.saveConfig();
    }

    function setMatchCategories(val) {
        root.matchCategories = Boolean(val);
        root.saveConfig();
    }

    function setClearSearchOnClose(val) {
        root.clearSearchOnClose = Boolean(val);
        root.saveConfig();
    }

    function clearAppUsage() {
        clearUsageProcess.command = ["sh", "-c", "echo '{}' > ~/.cache/qs_app_usage.json"];
        clearUsageProcess.running = true;
    }

    function resetDefaults() {
        root.spotlightWidth = 620;
        root.spotlightHeight = 480;
        root.defaultMode = "apps";
        root.sortMode = "frecency";
        root.matchGenericName = true;
        root.matchKeywords = true;
        root.matchCategories = true;
        root.clearSearchOnClose = true;
        root.gridColumns = 5;
        root.gridCellSize = 96;
        root.hiddenApps = [];
        root.favoriteApps = [];
        root.saveConfig();
        root.configChanged();
    }

    Timer {
        id: saveDebounceTimer
        interval: 350
        repeat: false
        onTriggered: root.saveConfig()
    }

    function saveConfig() {
        if (!root._loaded) return;
        const data = {
            spotlightWidth: root.spotlightWidth,
            spotlightHeight: root.spotlightHeight,
            defaultMode: root.defaultMode,
            sortMode: root.sortMode,
            matchGenericName: root.matchGenericName,
            matchKeywords: root.matchKeywords,
            matchCategories: root.matchCategories,
            clearSearchOnClose: root.clearSearchOnClose,
            gridColumns: root.gridColumns,
            gridCellSize: root.gridCellSize,
            hiddenApps: root.hiddenApps,
            favoriteApps: root.favoriteApps
        };
        const jsonStr = JSON.stringify(data, null, 2);
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
        if (cfg.spotlightWidth !== undefined) root.spotlightWidth = Math.max(480, Math.min(840, Number(cfg.spotlightWidth) || 620));
        if (cfg.spotlightHeight !== undefined) root.spotlightHeight = Math.max(360, Math.min(680, Number(cfg.spotlightHeight) || 480));
        if (cfg.defaultMode !== undefined) root.defaultMode = String(cfg.defaultMode) === "command" ? "command" : "apps";
        if (cfg.sortMode !== undefined) {
            const sm = String(cfg.sortMode);
            if (["frecency", "alphabetical", "recent"].indexOf(sm) !== -1) root.sortMode = sm;
        }
        if (cfg.matchGenericName !== undefined) root.matchGenericName = Boolean(cfg.matchGenericName);
        if (cfg.matchKeywords !== undefined) root.matchKeywords = Boolean(cfg.matchKeywords);
        if (cfg.matchCategories !== undefined) root.matchCategories = Boolean(cfg.matchCategories);
        if (cfg.clearSearchOnClose !== undefined) root.clearSearchOnClose = Boolean(cfg.clearSearchOnClose);
        if (cfg.gridColumns !== undefined) root.gridColumns = Math.max(3, Math.min(8, Number(cfg.gridColumns) || 5));
        if (cfg.gridCellSize !== undefined) root.gridCellSize = Math.max(72, Math.min(128, Number(cfg.gridCellSize) || 96));
        if (Array.isArray(cfg.hiddenApps)) root.hiddenApps = cfg.hiddenApps;
        if (Array.isArray(cfg.favoriteApps)) root.favoriteApps = cfg.favoriteApps;
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
            try {
                const parsed = JSON.parse(raw);
                root.applyConfig(parsed);
                root.configChanged();
            } catch(e) {
            } finally {
                root._loaded = true;
            }
        }
    }

    Process {
        id: saveProcess
        command: []
        running: false
    }

    Process {
        id: clearUsageProcess
        command: []
        running: false
        onExited: (code) => {
            if (code === 0) root.usageCleared();
        }
    }

    Component.onCompleted: {
        try {
            const text = configFile.text();
            if (text && text.trim().length > 0) {
                root.applyConfig(JSON.parse(text));
            }
        } catch(e) {}
        root._loaded = true;
    }
}
