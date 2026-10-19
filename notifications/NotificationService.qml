pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property string configPath: Qt.resolvedUrl("../notifications_config.json").toString().replace(/^file:\/\//, "")

    property var notifications: []
    property bool doNotDisturb: false
    property string toastPosition: "top-right" // "top-left" | "top-center" | "top-right" | "bottom-left" | "bottom-center" | "bottom-right"
    property int toastMarginX: 10
    property int toastMarginY: 10

    readonly property int count: notifications.length
    property int _seqCounter: 0
    property bool _loaded: false
    property string _lastSavedJson: ""

    readonly property var validPositions: [
        "top-left", "top-center", "top-right",
        "bottom-left", "bottom-center", "bottom-right"
    ]

    onDoNotDisturbChanged: {
        if (root._loaded) root.saveConfig();
    }

    function setToastPosition(pos) {
        const clean = String(pos || "top-right").trim().toLowerCase();
        if (root.validPositions.indexOf(clean) === -1) return;
        if (root.toastPosition !== clean) {
            root.toastPosition = clean;
            root.saveConfig();
        }
    }

    function setToastMarginX(val) {
        const clamped = Math.max(0, Math.min(200, Math.round(Number(val) || 0)));
        if (root.toastMarginX !== clamped) {
            root.toastMarginX = clamped;
            root.saveConfig();
        }
    }

    function setToastMarginY(val) {
        const clamped = Math.max(0, Math.min(200, Math.round(Number(val) || 0)));
        if (root.toastMarginY !== clamped) {
            root.toastMarginY = clamped;
            root.saveConfig();
        }
    }

    function resetPositionDefaults() {
        root.toastPosition = "top-right";
        root.toastMarginX = 10;
        root.toastMarginY = 10;
        root.saveConfig();
    }

    function saveConfig() {
        if (!root._loaded) return;
        const data = {
            doNotDisturb: root.doNotDisturb,
            toastPosition: root.toastPosition,
            toastMarginX: root.toastMarginX,
            toastMarginY: root.toastMarginY
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
        if (cfg.doNotDisturb !== undefined) root.doNotDisturb = Boolean(cfg.doNotDisturb);
        if (cfg.toastPosition !== undefined) {
            const p = String(cfg.toastPosition).trim().toLowerCase();
            if (root.validPositions.indexOf(p) !== -1) root.toastPosition = p;
        }
        if (cfg.toastMarginX !== undefined) {
            root.toastMarginX = Math.max(0, Math.min(200, Math.round(Number(cfg.toastMarginX) || 0)));
        }
        if (cfg.toastMarginY !== undefined) {
            root.toastMarginY = Math.max(0, Math.min(200, Math.round(Number(cfg.toastMarginY) || 0)));
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
                console.error("Failed to parse notifications_config.json:", e);
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
        if (!configFile.text()) {
            root._loaded = true;
        }
    }

    Component {
        id: notifDataComp
        NotificationData {}
    }

    function isOsdNotification(notification) {
        if (!notification) return false;
        const app = String(notification.appName || "").toLowerCase();
        const summary = String(notification.summary || "").toLowerCase();
        const body = String(notification.body || "").toLowerCase();

        // 1. Volume level or Volume: or Microphone: notifications
        if (summary.includes("volume level") || summary.includes("volume:") || summary.includes("microphone:") || summary.includes("mic mute")) {
            return true;
        }
        if (body.includes("volume level") || body.includes("volume:")) {
            return true;
        }

        // 2. notify-send specifically sending volume or brightness
        if (app.includes("notify-send") || app === "" || app === "volume") {
            if (summary.includes("volume") || summary.includes("mute") || summary.includes("brightness") || summary.includes("microphone")) {
                return true;
            }
            if (body.includes("volume") || body.includes("brightness") || body.includes("switched on") || body.includes("switched off")) {
                return true;
            }
        }

        // 3. Brightness level notifications
        if (summary.includes("brightness level") || summary.includes("brightness:")) {
            return true;
        }

        return false;
    }

    NotificationServer {
        id: server
        actionsSupported:    true
        bodySupported:       true
        bodyMarkupSupported: true
        imageSupported:      true
        keepOnReload:        false

        onNotification: function(notification) {
            if (root.doNotDisturb) return;

            if (!notification.appName && !notification.summary
                && !notification.body && !notification.image) return;

            // Suppress volume and brightness notifications that duplicate Quickshell's OSD
            if (root.isOsdNotification(notification)) {
                try { notification.dismiss(); } catch(e) {}
                return;
            }

            notification.tracked = true;

            const idStr = String(notification.id || "");
            if (idStr !== "") {
                const existing = root.notifications.find(function(n) {
                    return n.notifId === idStr;
                });
                if (existing && !existing.closed) {
                    existing.closed = true;
                    root.notifications = root.notifications.filter(function(n) {
                        return n !== existing;
                    });
                    existing.destroy();
                }
            }

            const data = notifDataComp.createObject(root, {
                notification: notification,
                seqId: String(root._seqCounter++)
            });

            root.notifications = [data, ...root.notifications];

            if (root.notifications.length > 5) {
                root.notifications[root.notifications.length - 1].dismiss();
            }
        }
    }

    function _remove(notifData) {
        root.notifications = root.notifications.filter(function(n) {
            return n !== notifData;
        });
    }

    function _bump(notifData) {
        if (!notifData || notifData.closed) return;
        notifData.seqId = String(root._seqCounter++);
        const rest = root.notifications.filter(function(n) {
            return n !== notifData;
        });
        root.notifications = [notifData, ...rest];
    }

    function dismiss(notifData) {
        if (notifData) notifData.dismiss();
    }

    function dismissAll() {
        const toRemove = [...root.notifications];
        root.notifications = [];
        for (const n of toRemove) {
            if (!n.closed) {
                n.closed = true;
                if (n.notification) try { n.notification.dismiss(); } catch(e) {}
                n.destroy();
            }
        }
    }
}
