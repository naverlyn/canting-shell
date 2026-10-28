/*
 * MouseSettings.qml
 *
 * Manages pointer speed, primary button, natural scrolling,
 * and touchpad behavior live via Hyprland input keywords.
 *
 * Useful troubleshooting commands:
 *   hyprctl getoption input:sensitivity
 *   hyprctl keyword input:touchpad:natural_scroll true
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."
import "./Mouse"

Item {
    id: root
    property var theme
    property string font

    /* Input State Values */
    property bool leftHanded: false
    property bool naturalScroll: false
    property real pointerSensitivity: 0.0 /* -1.0 to 1.0 in Hyprland */

    property bool touchpadEnabled: true
    property bool touchpadNaturalScroll: false
    property bool tapToClick: true
    property bool disableWhileTyping: true

    readonly property string scriptPath: Qt.resolvedUrl("../scripts/manage_touchpad.sh").toString().replace(/^file:\/\//, "")

    /* Dynamic Hyprland keyword process runner */
    Process {
        id: hyprcmd
        running: false
    }

    /* Apply live AND persist (Lua or .conf) via manage_hyprland.sh.
       "input:touchpad:natural_scroll" -> section "input.touchpad", key "natural_scroll" */
    readonly property string hyprVarScript: Qt.resolvedUrl("../scripts/manage_hyprland.sh").toString().replace(/^file:\/\//, "")
    function applyHyprKeyword(key, val) {
        const parts = String(key).split(":");
        const k = parts.pop();
        hyprcmd.command = [root.hyprVarScript, "set", parts.join("."), k, String(val)];
        hyprcmd.running = true;
    }

    /* Touchpad state control runner */
    Process {
        id: touchpadCmd
        running: false
    }

    function setTouchpadState(enabled) {
        root.touchpadEnabled = enabled;
        touchpadCmd.command = [root.scriptPath, "set", enabled ? "true" : "false"];
        touchpadCmd.running = true;
    }

    /* Query initial touchpad status */
    Process {
        id: queryTouchpadProc
        command: [root.scriptPath, "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const val = text.trim();
                if (val === "true") root.touchpadEnabled = true;
                else if (val === "false") root.touchpadEnabled = false;
            }
        }
    }

    /* Main Scrollable View */
    Flickable {
        id: mouseFlickable
        anchors.fill: parent
        contentHeight: mousePageContentInst.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !mousePageContentInst.speedMouseRef.pressed

        MousePageContent {
            id: mousePageContentInst
            root: root
        }
    }
}
