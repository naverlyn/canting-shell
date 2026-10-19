pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configPath: Qt.resolvedUrl("../osd_config.json").toString().replace(/^file:\/\//, "")

    property string position: "right" // "right" | "left" | "center" | "top" | "bottom"
    property string orientation: "auto" // "auto" | "horizontal" | "vertical"
    property int marginX: 12
    property int marginY: 12
    property int timeoutMs: 1500
    property bool _loaded: false

    signal testTriggered()

    readonly property var validPositions: [
        "right", "left", "center", "top", "bottom"
    ]

    readonly property var validOrientations: [
        "auto", "horizontal", "vertical"
    ]

    readonly property var positionOptions: [
        { id: "left",        label: "Left",          icon: "󰁙" },
        { id: "center",      label: "Center",        icon: "󰓏" },
        { id: "right",       label: "Right",         icon: "󰁚" },
        { id: "top",         label: "Top",           icon: "󰁝" },
        { id: "bottom",      label: "Bottom",        icon: "󰁅" }
    ]

    readonly property var orientationOptions: [
        { id: "auto",        label: "Auto (Adaptive)",  desc: "Horizontal in center/top/bottom, vertical on edges" },
        { id: "horizontal",  label: "Horizontal",       desc: "Always display as a horizontal bar" },
        { id: "vertical",    label: "Vertical",         desc: "Always display as a vertical pill" }
    ]

    // Resolved actual orientation
    readonly property bool isHorizontal: {
        if (root.orientation === "horizontal") return true;
        if (root.orientation === "vertical") return false;
        return root.position === "center" || root.position === "top" || root.position === "bottom";
    }

    function getPositionLabel(posId) {
        for (let i = 0; i < root.positionOptions.length; i++) {
            if (root.positionOptions[i].id === posId) return root.positionOptions[i].label;
        }
        return "Right";
    }

    function setPosition(pos) {
        const clean = String(pos || "right").trim().toLowerCase();
        if (root.validPositions.indexOf(clean) === -1) return;
        if (root.position !== clean) {
            root.position = clean;
            if (clean === "center") {
                root.marginX = 0;
                root.marginY = 0;
            } else if (clean === "top" || clean === "bottom") {
                root.marginX = 0;
                root.marginY = 16;
            } else {
                root.marginX = 16;
                root.marginY = 0;
            }
            root.saveConfig();
        }
    }

    function setOrientation(orient) {
        const clean = String(orient || "auto").trim().toLowerCase();
        if (root.validOrientations.indexOf(clean) === -1) return;
        if (root.orientation !== clean) {
            root.orientation = clean;
            root.saveConfig();
        }
    }

    function setMarginX(val) {
        const clamped = Math.max(-2500, Math.min(2500, Math.round(Number(val) || 0)));
        if (root.marginX !== clamped) {
            root.marginX = clamped;
            root.saveConfig();
        }
    }

    function setMarginY(val) {
        const clamped = Math.max(-2500, Math.min(2500, Math.round(Number(val) || 0)));
        if (root.marginY !== clamped) {
            root.marginY = clamped;
            root.saveConfig();
        }
    }

    function setTimeoutMs(val) {
        const clamped = Math.max(800, Math.min(5000, Math.round(Number(val) || 1500)));
        if (root.timeoutMs !== clamped) {
            root.timeoutMs = clamped;
            root.saveConfig();
        }
    }

    function testOSD() {
        root.testTriggered();
    }

    function saveConfig() {
        if (!root._loaded) return;
        const data = {
            position: root.position,
            orientation: root.orientation,
            marginX: root.marginX,
            marginY: root.marginY,
            timeoutMs: root.timeoutMs
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
        if (cfg.position !== undefined) {
            const p = String(cfg.position).trim().toLowerCase();
            if (root.validPositions.indexOf(p) !== -1) root.position = p;
        }
        if (cfg.orientation !== undefined) {
            const o = String(cfg.orientation).trim().toLowerCase();
            if (root.validOrientations.indexOf(o) !== -1) root.orientation = o;
        }
        if (cfg.marginX !== undefined) {
            root.marginX = Math.max(-400, Math.min(400, Math.round(Number(cfg.marginX) || 0)));
        }
        if (cfg.marginY !== undefined) {
            root.marginY = Math.max(-400, Math.min(400, Math.round(Number(cfg.marginY) || 0)));
        }
        if (cfg.timeoutMs !== undefined) {
            root.timeoutMs = Math.max(800, Math.min(5000, Math.round(Number(cfg.timeoutMs) || 1500)));
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
