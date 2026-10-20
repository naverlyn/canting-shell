/*
 * PowerSettings.qml
 *
 * Manages display power saving, Wayland idle inhibition (Caffeine),
 * and system power controls (suspend, reboot, poweroff).
 *
 * Useful troubleshooting commands:
 *   hyprctl dispatch dpms off
 *   systemctl suspend
 *   qs ipc call idle toggle
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../bar"
import ".."
import "./Power"

Item {
    id: root
    property alias turnOffDisplaysProcRef: turnOffDisplaysProc
    property alias lockDebounceTimerRef: lockDebounceTimer
    property alias poweroffProcRef: poweroffProc
    property alias rebootProcRef: rebootProc
    property alias suspendProcRef: suspendProc
    property var theme
    property string font

    /* Wayland idle inhibitor state */
    readonly property bool keepAwake: SystemInfo.idleInhibited

    /* Inactivity Screen Lock Management (hypridle) */
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/manage_hypridle.sh").toString().replace(/^file:\/\//, "")
    property int lockTimeoutMinutes: 10
    property bool isLoadingLock: true

    function setLockTimeout(mins) {
        root.lockTimeoutMinutes = mins;
        setLockTimeoutProc.command = [root.scriptPath, "set", String(mins)];
        setLockTimeoutProc.running = true;
    }

    Timer {
        id: lockDebounceTimer
        interval: 350
        repeat: false
        onTriggered: {
            setLockTimeoutProc.command = [root.scriptPath, "set", String(root.lockTimeoutMinutes)];
            setLockTimeoutProc.running = true;
        }
    }

    function queueLockTimeout(mins) {
        root.lockTimeoutMinutes = mins;
        lockDebounceTimer.restart();
    }

    Process {
        id: loadLockTimeoutProc
        command: [root.scriptPath, "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text.trim());
                    if (data && data.timeout_minutes !== undefined) {
                        root.lockTimeoutMinutes = data.timeout_minutes;
                    }
                } catch (e) {}
                root.isLoadingLock = false;
            }
        }
    }

    Process {
        id: setLockTimeoutProc
        command: [root.scriptPath, "set", String(root.lockTimeoutMinutes)]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text.trim());
                    if (data && data.timeout_minutes !== undefined) {
                        root.lockTimeoutMinutes = data.timeout_minutes;
                    }
                } catch (e) {}
            }
        }
    }

    /* Power action processes */
    Process {
        id: turnOffDisplaysProc
        command: ["hyprctl", "dispatch", "dpms", "off"]
        running: false
    }

    Process {
        id: suspendProc
        command: ["systemctl", "suspend"]
        running: false
    }

    Process {
        id: rebootProc
        command: ["systemctl", "reboot"]
        running: false
    }

    Process {
        id: poweroffProc
        command: ["systemctl", "poweroff"]
        running: false
    }

    Process {
        id: toggleIdleProc
        command: ["qs", "ipc", "call", "idle", "toggle"]
        running: false
    }

    /* Main Scrollable View */
    Flickable {
        id: powerFlickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !powerScreenIdleSleepGroupInst.lockMouseRef.pressed

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 20

            Text {
                text: "Power"
                font.family: root.font
                font.pixelSize: 20
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }

            /* Screen & Idle Sleep Group */
            PowerScreenIdleSleepGroup {
                id: powerScreenIdleSleepGroupInst
                root: root
            }

            /* System Power Controls Group */
            PowerSystemPowerControlsGroup {
                root: root
            }
        }
    }
}
