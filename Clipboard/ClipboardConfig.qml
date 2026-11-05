pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configPath: Qt.resolvedUrl("../clipboard_config.json").toString().replace(/^file:\/\//, "")
    readonly property string serviceScript: Qt.resolvedUrl("scripts/clip_service.py").toString().replace(/^file:\/\//, "")

    // Configuration Properties
    property int windowWidth: 840
    property int windowHeight: 640
    property int maxItems: 100
    property bool closeOnCopy: true
    property bool clearSearchOnClose: true
    property bool autoPasteOnSelect: false
    property bool generateThumbnails: true
    property bool detectColors: true
    property bool detectLinks: true
    property bool detectCode: true
    property string defaultCategory: "all" // "all", "text", "image", "link", "code", "color"

    property bool _loaded: false

    signal configChanged()
    signal historyWiped()

    readonly property var categoryOptions: [
        { id: "all",   label: "All Items", icon: "󰅌" },
        { id: "text",  label: "Text",      icon: "󰬴" },
        { id: "image", label: "Images",    icon: "󰋩" },
        { id: "link",  label: "Links",     icon: "󰌹" },
        { id: "code",  label: "Code",      icon: "󰅩" },
        { id: "color", label: "Colors",    icon: "󰏘" }
    ]

    function setWindowWidth(val) {
        const clamped = Math.max(640, Math.min(1000, Math.round(Number(val) || 840)));
        if (root.windowWidth !== clamped) {
            root.windowWidth = clamped;
            saveDebounceTimer.restart();
        }
    }

    function setWindowHeight(val) {
        const clamped = Math.max(480, Math.min(760, Math.round(Number(val) || 640)));
        if (root.windowHeight !== clamped) {
            root.windowHeight = clamped;
            saveDebounceTimer.restart();
        }
    }

    function setMaxItems(val) {
        const clamped = Math.max(25, Math.min(500, Math.round(Number(val) || 100)));
        if (root.maxItems !== clamped) {
            root.maxItems = clamped;
            saveDebounceTimer.restart();
        }
    }

    function setCloseOnCopy(val) {
        root.closeOnCopy = Boolean(val);
        root.saveConfig();
    }

    function setClearSearchOnClose(val) {
        root.clearSearchOnClose = Boolean(val);
        root.saveConfig();
    }

    function setAutoPasteOnSelect(val) {
        root.autoPasteOnSelect = Boolean(val);
        root.saveConfig();
    }

    function setGenerateThumbnails(val) {
        root.generateThumbnails = Boolean(val);
        root.saveConfig();
    }

    function setDetectColors(val) {
        root.detectColors = Boolean(val);
        root.saveConfig();
    }

    function setDetectLinks(val) {
        root.detectLinks = Boolean(val);
        root.saveConfig();
    }

    function setDetectCode(val) {
        root.detectCode = Boolean(val);
        root.saveConfig();
    }

    function setDefaultCategory(cat) {
        if (["all", "text", "image", "link", "code", "color"].indexOf(cat) !== -1) {
            if (root.defaultCategory !== cat) {
                root.defaultCategory = cat;
                root.saveConfig();
            }
        }
    }

    function resetDefaults() {
        root.windowWidth = 840;
        root.windowHeight = 640;
        root.maxItems = 100;
        root.closeOnCopy = true;
        root.clearSearchOnClose = true;
        root.autoPasteOnSelect = false;
        root.generateThumbnails = true;
        root.detectColors = true;
        root.detectLinks = true;
        root.detectCode = true;
        root.defaultCategory = "all";
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
            windowWidth: root.windowWidth,
            windowHeight: root.windowHeight,
            maxItems: root.maxItems,
            closeOnCopy: root.closeOnCopy,
            clearSearchOnClose: root.clearSearchOnClose,
            autoPasteOnSelect: root.autoPasteOnSelect,
            generateThumbnails: root.generateThumbnails,
            detectColors: root.detectColors,
            detectLinks: root.detectLinks,
            detectCode: root.detectCode,
            defaultCategory: root.defaultCategory
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
        if (cfg.windowWidth !== undefined) root.windowWidth = Math.max(640, Math.min(1000, Number(cfg.windowWidth) || 840));
        if (cfg.windowHeight !== undefined) root.windowHeight = Math.max(480, Math.min(760, Number(cfg.windowHeight) || 640));
        if (cfg.maxItems !== undefined) root.maxItems = Math.max(25, Math.min(500, Number(cfg.maxItems) || 100));
        if (cfg.closeOnCopy !== undefined) root.closeOnCopy = Boolean(cfg.closeOnCopy);
        if (cfg.clearSearchOnClose !== undefined) root.clearSearchOnClose = Boolean(cfg.clearSearchOnClose);
        if (cfg.autoPasteOnSelect !== undefined) root.autoPasteOnSelect = Boolean(cfg.autoPasteOnSelect);
        if (cfg.generateThumbnails !== undefined) root.generateThumbnails = Boolean(cfg.generateThumbnails);
        if (cfg.detectColors !== undefined) root.detectColors = Boolean(cfg.detectColors);
        if (cfg.detectLinks !== undefined) root.detectLinks = Boolean(cfg.detectLinks);
        if (cfg.detectCode !== undefined) root.detectCode = Boolean(cfg.detectCode);
        if (cfg.defaultCategory !== undefined) {
            const dc = String(cfg.defaultCategory);
            if (["all", "text", "image", "link", "code", "color"].indexOf(dc) !== -1) root.defaultCategory = dc;
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
        running: false
        onExited: root.configChanged()
    }

    Component.onCompleted: {
        root._loaded = true;
    }
}

