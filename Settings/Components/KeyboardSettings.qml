/*
 * KeyboardSettings.qml
 *
 * Manages keyboard repeat delay, repeat rate, layout, numlock behavior,
 * and allows searching, editing, and creating Hyprland shortcuts.
 *
 * Fully portable across vanilla Hyprland and custom dotfiles:
 * - Detects user keybind override files or automatically manages custom_keybinds.conf.
 * - Dynamically parses script names into clean human titles without hardcoded assumptions.
 *
 * Useful troubleshooting commands:
 *   hyprctl getoption input:repeat_delay -j
 *   hyprctl getoption input:repeat_rate -j
 *   hyprctl binds -j
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root
    property var theme
    property string font

    /* Input State Values */
    property int repeatDelay: 300 /* ms (150 to 1000) */
    property int repeatRate: 50   /* char/s (10 to 100) */
    property string activeLayout: "us"
    property bool numlockByDefault: true

    readonly property string scriptPath: Qt.resolvedUrl("../scripts/manage_keybind.sh").toString().replace(/^file:\/\//, "")

    /* Keybindings State */
    property var rawBinds: []
    property string searchQuery: ""
    property bool showAllShortcuts: false

    /* Keybinding Editor State (Editing existing shortcut) */
    property int editingUid: -1
    property int confirmingUnbindUid: -1
    property var editingItem: null
    property string editName: ""
    property string editDispatcher: "exec"
    property string editCustomDisp: ""
    property string editArg: ""
    property bool editSuper: false
    property bool editCtrl: false
    property bool editAlt: false
    property bool editShift: false
    property string editKey: ""
    property bool isCapturingKey: false

    /* New Keybinding State (Adding new shortcut) */
    property bool isAddingKeybind: false
    property string addName: ""
    property string addDispatcher: "exec"
    property string addCustomDisp: ""
    property string addArg: ""
    property bool addSuper: true
    property bool addCtrl: false
    property bool addAlt: false
    property bool addShift: false
    property string addKey: ""
    property bool isCapturingAddKey: false

    readonly property var editDispatcherOptions: {
        let base = [
            { name: "Execute App", val: "exec" },
            { name: "Close Window", val: "killactive" },
            { name: "Toggle Float", val: "togglefloating" },
            { name: "Fullscreen", val: "fullscreen" },
            { name: "Workspace", val: "workspace" }
        ];
        const orig = root.editingItem ? (root.editingItem.dispatcher || "") : "";
        if (orig && !base.some(o => o.val === orig)) {
            base.push({ name: root.formatTitle(orig), val: orig });
        }
        base.push({ name: "Custom", val: "custom" });
        return base;
    }

    readonly property var addDispatcherOptions: [
        { name: "Execute App", val: "exec" },
        { name: "Close Window", val: "killactive" },
        { name: "Toggle Float", val: "togglefloating" },
        { name: "Fullscreen", val: "fullscreen" },
        { name: "Workspace", val: "workspace" },
        { name: "Custom", val: "custom" }
    ]

    /* Dynamic Hyprland keyword process runner */
    Process {
        id: hyprcmd
        running: false
    }

    function applyHyprKeyword(key, val) {
        hyprcmd.command = ["hyprctl", "keyword", key, String(val)];
        hyprcmd.running = true;
    }

    /* Process runner for applying and persisting keybind changes */
    Process {
        id: rebindProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                reloadTimer.restart();
            }
        }
    }

    Timer {
        id: reloadTimer
        interval: 100
        repeat: false
        onTriggered: {
            queryBindsProc.running = false;
            queryBindsProc.running = true;
        }
    }

    /* Helper: Clean Title Formatter for arbitrary scripts and binaries */
    function formatTitle(str) {
        if (!str) return "";
        let s = str.replace(/\.sh$/, "").replace(/^[.\/]+/, "");
        if (s.includes("/")) {
            const parts = s.split("/");
            s = parts[parts.length - 1].replace(/\.sh$/, "");
        }
        // Split camelCase and PascalCase
        s = s.replace(/([a-z])([A-Z])/g, "$1 $2");
        // Replace underscores and hyphens
        s = s.replace(/[_-]+/g, " ");
        // Capitalize words
        return s.split(" ").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ").trim();
    }

    /* Helper: Human-friendly action title (dynamic and distro-agnostic) */
    function getFriendlyAction(item) {
        if (item.description && item.description.length > 0) {
            return item.description;
        }
        const disp = item.dispatcher || "";
        const arg = item.arg || "";

        if (disp === "killactive") return "Close Active Window";
        if (disp === "togglefloating") return "Toggle Floating Window";
        if (disp === "fullscreen") return arg === "1" ? "Maximize Window" : "Toggle Fullscreen";
        if (disp === "workspace") return "Switch to Workspace " + arg;
        if (disp === "movetoworkspace") return "Move Window to Workspace " + arg;
        if (disp === "movetoworkspacesilent") return "Move Silently to Workspace " + arg;
        if (disp === "splitratio") return "Adjust Split Ratio";
        if (disp === "movefocus") return "Focus Window (" + arg + ")";
        if (disp === "togglespecialworkspace") return "Special Workspace (" + (arg || "Default") + ")";

        if (disp === "exec") {
            // Quickshell desktop shell IPC
            if (arg.includes("launcher toggle")) return "App Launcher";
            if (arg.includes("monitors toggle")) return "Display Settings";
            if (arg.includes("theme toggle")) return "Theme Switcher";
            if (arg.includes("notifications dismiss_all")) return "Dismiss Notifications";

            // Standard volume, brightness, and screenshot utilities
            if (arg.includes("wpctl") || arg.includes("pamixer") || arg.includes("pactl")) return "Volume Control";
            if (arg.includes("brightnessctl") || arg.includes("light")) return "Brightness Control";
            if (arg.includes("grim") || arg.includes("slurp") || arg.includes("hyprshot")) return "Take Screenshot";

            // Generic app launchers
            if (arg.includes("rofi") || arg.includes("wofi") || arg.includes("fuzzel") || arg.includes("tofi")) {
                if (arg.includes("window")) return "Window Switcher";
                if (arg.includes("emoji")) return "Emoji Picker";
                return "App Launcher";
            }

            // Dynamic clean title for any application or script path
            return root.formatTitle(arg);
        }

        return root.formatTitle(disp + (arg ? " " + arg : ""));
    }

    /* Helper: Layout display name */
    function getLayoutDisplayName(code) {
        const map = {
            "us": "English (US)",
            "gb": "English (UK)",
            "de": "German",
            "fr": "French",
            "es": "Spanish",
            "it": "Italian",
            "pt": "Portuguese",
            "ru": "Russian",
            "jp": "Japanese"
        };
        return map[code.toLowerCase()] || code.toUpperCase();
    }

    /* Helper: Keyboard badge pill breakdown */
    function getModPills(modmask, key) {
        let pills = [];
        if (modmask & 64) pills.push("Super");
        if (modmask & 4) pills.push("Ctrl");
        if (modmask & 8) pills.push("Alt");
        if (modmask & 1) pills.push("Shift");

        let cleanKey = key;
        if (cleanKey === "SPACE") cleanKey = "Space";
        if (cleanKey === "Return") cleanKey = "Enter";
        if (cleanKey.startsWith("XF86Audio")) cleanKey = cleanKey.replace("XF86Audio", "");
        if (cleanKey.startsWith("XF86MonBrightness")) cleanKey = cleanKey.replace("XF86MonBrightness", "Brightness ");
        pills.push(cleanKey);
        return pills;
    }

    /* Keybinding Editor Functions */
    function isSameItem(a, b) {
        if (!a || !b) return false;
        return a.dispatcher === b.dispatcher && a.arg === b.arg && a.key === b.key && a.modmask === b.modmask;
    }

    function startEditing(item) {
        if (root.editingUid === item.uid && root.editingUid !== -1) {
            root.editingUid = -1;
            root.editingItem = null;
            root.isCapturingKey = false;
            root.confirmingUnbindUid = -1;
            return;
        }
        root.editingUid = item.uid;
        root.editingItem = item;
        root.confirmingUnbindUid = -1;
        root.editName = (item.description && item.description.length > 0) ? item.description : root.getFriendlyAction(item);
        const disp = item.dispatcher || "exec";
        root.editDispatcher = disp;
        root.editCustomDisp = disp;
        root.editArg = item.arg || "";
        root.editSuper = (item.modmask & 64) !== 0;
        root.editCtrl = (item.modmask & 4) !== 0;
        root.editAlt = (item.modmask & 8) !== 0;
        root.editShift = (item.modmask & 1) !== 0;
        root.editKey = item.key;
        root.isCapturingKey = false;
        root.isAddingKeybind = false;
    }

    function getEditPreviewPills() {
        let pills = [];
        if (root.editSuper) pills.push("Super");
        if (root.editCtrl) pills.push("Ctrl");
        if (root.editAlt) pills.push("Alt");
        if (root.editShift) pills.push("Shift");
        if (root.editKey && root.editKey.trim().length > 0) {
            pills.push(root.editKey.trim());
        }
        return pills;
    }

    function getAddPreviewPills() {
        let pills = [];
        if (root.addSuper) pills.push("Super");
        if (root.addCtrl) pills.push("Ctrl");
        if (root.addAlt) pills.push("Alt");
        if (root.addShift) pills.push("Shift");
        if (root.addKey && root.addKey.trim().length > 0) {
            pills.push(root.addKey.trim());
        }
        return pills;
    }

    function applyEditedKeybind() {
        if (!root.editingItem || !root.editKey.trim()) return;

        const oldItem = root.editingItem;

        let oldMods = [];
        if (oldItem.modmask & 64) oldMods.push("SUPER");
        if (oldItem.modmask & 4) oldMods.push("CTRL");
        if (oldItem.modmask & 8) oldMods.push("ALT");
        if (oldItem.modmask & 1) oldMods.push("SHIFT");
        const oldModStr = oldMods.join(" ");

        let newMods = [];
        if (root.editSuper) newMods.push("SUPER");
        if (root.editCtrl) newMods.push("CTRL");
        if (root.editAlt) newMods.push("ALT");
        if (root.editShift) newMods.push("SHIFT");
        const newModStr = newMods.join(" ");

        const newKey = root.editKey.trim();
        let newDisp = root.editDispatcher;
        if (newDisp === "custom") {
            newDisp = root.editCustomDisp.trim() || "exec";
        }
        if (!newDisp) newDisp = oldItem.dispatcher || "exec";

        let newArg = "";
        if (newDisp !== "killactive" && newDisp !== "togglefloating") {
            newArg = root.editArg.trim();
        }

        const newDesc = root.editName.trim() || root.formatTitle(newArg || newDisp);

        // Optimistically update in-memory item for instantaneous UI response
        oldItem.description = newDesc;
        oldItem.key = newKey;
        oldItem.dispatcher = newDisp;
        oldItem.arg = newArg;
        let newMask = 0;
        if (root.editSuper) newMask |= 64;
        if (root.editCtrl) newMask |= 4;
        if (root.editAlt) newMask |= 8;
        if (root.editShift) newMask |= 1;
        oldItem.modmask = newMask;

        root.editingUid = -1;
        root.editingItem = null;
        root.isCapturingKey = false;
        root.confirmingUnbindUid = -1;

        rebindProc.command = [
            "bash",
            root.scriptPath,
            "rebind",
            oldModStr,
            oldItem.key,
            newModStr,
            newKey,
            newDisp,
            newArg,
            newDesc,
            oldItem.arg || "",
            oldItem.dispatcher || ""
        ];
        rebindProc.running = true;
    }

    function deleteKeybind(item) {
        let mods = [];
        if (item.modmask & 64) mods.push("SUPER");
        if (item.modmask & 4) mods.push("CTRL");
        if (item.modmask & 8) mods.push("ALT");
        if (item.modmask & 1) mods.push("SHIFT");
        const modStr = mods.join(" ");

        // Immediately remove from in-memory UI list for instantaneous response
        root.rawBinds = root.rawBinds.filter(b => b.uid !== item.uid);
        root.editingUid = -1;
        root.editingItem = null;
        root.isCapturingKey = false;
        root.confirmingUnbindUid = -1;

        rebindProc.command = [
            "bash",
            root.scriptPath,
            "delete",
            modStr,
            item.key,
            item.dispatcher,
            item.arg || ""
        ];
        rebindProc.running = true;
    }

    function saveNewKeybind() {
        if (!root.addKey.trim()) return;

        let mods = [];
        if (root.addSuper) mods.push("SUPER");
        if (root.addCtrl) mods.push("CTRL");
        if (root.addAlt) mods.push("ALT");
        if (root.addShift) mods.push("SHIFT");
        const modStr = mods.join(" ");

        const key = root.addKey.trim();
        let disp = root.addDispatcher.trim();
        if (disp === "custom") {
            disp = root.addCustomDisp.trim() || "exec";
        }
        if (!disp) disp = "exec";

        let arg = "";
        if (disp !== "killactive" && disp !== "togglefloating") {
            arg = root.addArg.trim();
        }

        const desc = root.addName.trim() || root.formatTitle(arg || disp);

        rebindProc.command = [
            "bash",
            root.scriptPath,
            "add",
            modStr,
            key,
            disp,
            arg,
            desc
        ];
        rebindProc.running = true;

        root.isAddingKeybind = false;
        root.isCapturingAddKey = false;
        root.addName = "";
        root.addArg = "";
        root.addCustomDisp = "";
        root.addKey = "";
    }

    /* Filtered shortcuts list */
    readonly property var filteredBinds: {
        if (!root.rawBinds || root.rawBinds.length === 0) return [];
        const q = root.searchQuery.toLowerCase().trim();
        if (!q) {
            return root.showAllShortcuts ? root.rawBinds : root.rawBinds.slice(0, 15);
        }
        return root.rawBinds.filter(b => {
            const title = root.getFriendlyAction(b).toLowerCase();
            const key = (b.key || "").toLowerCase();
            const disp = (b.dispatcher || "").toLowerCase();
            const arg = (b.arg || "").toLowerCase();
            return title.includes(q) || key.includes(q) || disp.includes(q) || arg.includes(q);
        });
    }

    /* Global key capture for recording new shortcut */
    Item {
        id: keyCaptureItem
        focus: root.isCapturingKey || root.isCapturingAddKey
        Keys.onPressed: (event) => {
            if (!root.isCapturingKey && !root.isCapturingAddKey) return;
            event.accepted = true;

            if (event.key === Qt.Key_Escape) {
                root.isCapturingKey = false;
                root.isCapturingAddKey = false;
                return;
            }

            const isMeta = (event.modifiers & Qt.MetaModifier) !== 0;
            const isCtrl = (event.modifiers & Qt.ControlModifier) !== 0;
            const isAlt = (event.modifiers & Qt.AltModifier) !== 0;
            const isShift = (event.modifiers & Qt.ShiftModifier) !== 0;

            let k = "";
            if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
                k = String.fromCharCode(event.key);
            } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                k = String.fromCharCode(event.key);
            } else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12) {
                k = "F" + (event.key - Qt.Key_F1 + 1);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                k = "Return";
            } else if (event.key === Qt.Key_Space) {
                k = "Space";
            } else if (event.key === Qt.Key_Tab) {
                k = "Tab";
            } else if (event.key === Qt.Key_Backspace) {
                k = "BackSpace";
            } else if (event.key === Qt.Key_Delete) {
                k = "Delete";
            } else if (event.key === Qt.Key_Left) {
                k = "left";
            } else if (event.key === Qt.Key_Right) {
                k = "right";
            } else if (event.key === Qt.Key_Up) {
                k = "up";
            } else if (event.key === Qt.Key_Down) {
                k = "down";
            } else if (event.text && event.text.length === 1 && event.text >= ' ' && event.text <= '~') {
                k = event.text.toUpperCase();
            }

            if (root.isCapturingAddKey) {
                root.addSuper = isMeta;
                root.addCtrl = isCtrl;
                root.addAlt = isAlt;
                root.addShift = isShift;
                if (k.length > 0) {
                    root.addKey = k;
                    root.isCapturingAddKey = false;
                }
            } else if (root.isCapturingKey) {
                root.editSuper = isMeta;
                root.editCtrl = isCtrl;
                root.editAlt = isAlt;
                root.editShift = isShift;
                if (k.length > 0) {
                    root.editKey = k;
                    root.isCapturingKey = false;
                }
            }
        }
    }

    /* Initial state queries from Hyprland IPC */

    Process {
        id: queryDelayProc
        command: ["hyprctl", "getoption", "input:repeat_delay", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data && data.int !== undefined) root.repeatDelay = data.int;
                } catch (e) {}
            }
        }
    }

    Process {
        id: queryRateProc
        command: ["hyprctl", "getoption", "input:repeat_rate", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data && data.int !== undefined) root.repeatRate = data.int;
                } catch (e) {}
            }
        }
    }

    Process {
        id: queryLayoutProc
        command: ["hyprctl", "getoption", "input:kb_layout", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data && data.str !== undefined && data.str.length > 0) root.activeLayout = data.str;
                } catch (e) {}
            }
        }
    }

    Process {
        id: queryNumlockProc
        command: ["hyprctl", "getoption", "input:numlock_by_default", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data && data.int !== undefined) root.numlockByDefault = (data.int === 1);
                } catch (e) {}
            }
        }
    }

    Process {
        id: queryBindsProc
        command: ["hyprctl", "binds", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (Array.isArray(data)) {
                        const kbList = [];
                        for (let i = 0; i < data.length; i++) {
                            const b = data[i];
                            if (!b.mouse && b.key && !b.key.startsWith("mouse")) {
                                kbList.push({
                                    uid: i,
                                    modmask: b.modmask || 0,
                                    key: b.key,
                                    dispatcher: b.dispatcher || "",
                                    arg: b.arg || "",
                                    description: b.description || ""
                                });
                            }
                        }
                        root.rawBinds = kbList;
                    }
                } catch (e) {
                    console.warn("Failed to parse hyprctl binds:", e);
                }
            }
        }
    }

    /* Main Scrollable View */
    Flickable {
        id: kbFlickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !delayMouse.pressed && !rateMouse.pressed

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 20

            Text {
                text: "Keyboard"
                font.family: root.font
                font.pixelSize: 20
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }

            /* Key Repeat Group */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Key Repeat"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: repeatCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: repeatCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Repeat Delay Row */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                Text {
                                    text: "Repeat Delay"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Rectangle {
                                    id: delayTrack
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected
                                    Layout.alignment: Qt.AlignVCenter

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: Math.max(0, Math.min(parent.width, parent.width * ((root.repeatDelay - 150) / 850)))
                                        color: root.theme.accentPrimary
                                    }

                                    // Outer halo ring on hover/press
                                    Rectangle {
                                        anchors.centerIn: delayKnob
                                        width: delayKnob.width + (delayMouse.pressed ? 8 : (delayMouse.containsMouse ? 6 : 0))
                                        height: width
                                        radius: width / 2
                                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, delayMouse.pressed ? 0.35 : (delayMouse.containsMouse ? 0.2 : 0))
                                        z: 1

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    // Tactile white knob
                                    Rectangle {
                                        id: delayKnob
                                        width: delayMouse.containsMouse || delayMouse.pressed ? 17 : 15
                                        height: width
                                        radius: width / 2
                                        color: "#ffffff"
                                        border.color: root.theme.accentPrimary
                                        border.width: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(delayTrack.width - width, (delayTrack.width * ((root.repeatDelay - 150) / 850)) - (width / 2)))
                                        z: 2

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on x {
                                            enabled: !delayMouse.pressed
                                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    MouseArea {
                                        id: delayMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        preventStealing: true
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: (mouse) => {
                                            mouse.accepted = true;
                                            const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                            root.repeatDelay = Math.round(150 + frac * 850);
                                            root.applyHyprKeyword("input:repeat_delay", root.repeatDelay);
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (pressed) {
                                                mouse.accepted = true;
                                                const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                                root.repeatDelay = Math.round(150 + frac * 850);
                                                root.applyHyprKeyword("input:repeat_delay", root.repeatDelay);
                                            }
                                        }
                                        onClicked: (mouse) => {
                                            mouse.accepted = true;
                                            const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                            root.repeatDelay = Math.round(150 + frac * 850);
                                            root.applyHyprKeyword("input:repeat_delay", root.repeatDelay);
                                        }
                                    }
                                }

                                Text {
                                    text: root.repeatDelay + " ms"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textSecondary
                                    Layout.preferredWidth: 64
                                    horizontalAlignment: Text.AlignRight
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Repeat Speed / Rate Row */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                Text {
                                    text: "Repeat Speed"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Rectangle {
                                    id: rateTrack
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected
                                    Layout.alignment: Qt.AlignVCenter

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: Math.max(0, Math.min(parent.width, parent.width * ((root.repeatRate - 10) / 90)))
                                        color: root.theme.accentPrimary
                                    }

                                    // Outer halo ring on hover/press
                                    Rectangle {
                                        anchors.centerIn: rateKnob
                                        width: rateKnob.width + (rateMouse.pressed ? 8 : (rateMouse.containsMouse ? 6 : 0))
                                        height: width
                                        radius: width / 2
                                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, rateMouse.pressed ? 0.35 : (rateMouse.containsMouse ? 0.2 : 0))
                                        z: 1

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    // Tactile white knob
                                    Rectangle {
                                        id: rateKnob
                                        width: rateMouse.containsMouse || rateMouse.pressed ? 17 : 15
                                        height: width
                                        radius: width / 2
                                        color: "#ffffff"
                                        border.color: root.theme.accentPrimary
                                        border.width: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(rateTrack.width - width, (rateTrack.width * ((root.repeatRate - 10) / 90)) - (width / 2)))
                                        z: 2

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on x {
                                            enabled: !rateMouse.pressed
                                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    MouseArea {
                                        id: rateMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        preventStealing: true
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: (mouse) => {
                                            mouse.accepted = true;
                                            const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                            root.repeatRate = Math.round(10 + frac * 90);
                                            root.applyHyprKeyword("input:repeat_rate", root.repeatRate);
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (pressed) {
                                                mouse.accepted = true;
                                                const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                                root.repeatRate = Math.round(10 + frac * 90);
                                                root.applyHyprKeyword("input:repeat_rate", root.repeatRate);
                                            }
                                        }
                                        onClicked: (mouse) => {
                                            mouse.accepted = true;
                                            const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                            root.repeatRate = Math.round(10 + frac * 90);
                                            root.applyHyprKeyword("input:repeat_rate", root.repeatRate);
                                        }
                                    }
                                }

                                Text {
                                    text: root.repeatRate + " / sec"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textSecondary
                                    Layout.preferredWidth: 64
                                    horizontalAlignment: Text.AlignRight
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Interactive Test Field Row */
                        Item {
                            Layout.fillWidth: true
                            height: 60

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    text: "Test Repeat"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: 8
                                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                                    border.color: testInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                    border.width: testInput.activeFocus ? 2 : 1
                                    Layout.alignment: Qt.AlignVCenter

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        TextInput {
                                            id: testInput
                                            Layout.fillWidth: true
                                            font.family: root.font
                                            font.pixelSize: 13
                                            color: root.theme.textPrimary
                                            clip: true
                                            selectByMouse: true

                                            Text {
                                                text: "Type here to test key repeat speed..."
                                                font.family: root.font
                                                font.pixelSize: 12
                                                color: root.theme.textSecondary
                                                visible: !testInput.text && !testInput.activeFocus
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        Text {
                                            text: "✕"
                                            font.family: root.font
                                            font.pixelSize: 13
                                            color: clearMouse.containsMouse ? root.theme.textPrimary : root.theme.textSecondary
                                            visible: testInput.text.length > 0

                                            MouseArea {
                                                id: clearMouse
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: testInput.text = ""
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* Layout & Options Group */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Layout & Options"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: layoutCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: layoutCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Current Keyboard Layout Row */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Keyboard Layout"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Active Hyprland compositor layout"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: layoutBadgeText.implicitWidth + 18
                                    height: 28
                                    radius: 6
                                    color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.1)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        id: layoutBadgeText
                                        anchors.centerIn: parent
                                        text: root.getLayoutDisplayName(root.activeLayout)
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* NumLock by Default Row */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "NumLock on Startup"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Enable numeric keypad lock on login"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: root.numlockByDefault ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 160 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.numlockByDefault ? parent.width - width - 3 : 3
                                        color: root.numlockByDefault ? "#ffffff" : root.theme.textPrimary

                                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.numlockByDefault = !root.numlockByDefault;
                                            root.applyHyprKeyword("input:numlock_by_default", root.numlockByDefault ? "true" : "false");
                                        }
                                    }
                                }
                            }
                        }

                    }
                }
            }

            /* Shortcuts Group */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 8

                    Text {
                        text: "Hyprland Keybindings"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    Text {
                        text: "(" + root.rawBinds.length + ")"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                        opacity: 0.7
                    }

                    Item { Layout.fillWidth: true }

                    /* Add Keybind Toggle Button (Text-only, no icon) */
                    Rectangle {
                        implicitWidth: addBtnText.implicitWidth + 24
                        height: 30
                        radius: 7
                        color: addBtnHover.hovered
                            ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08))
                            : (root.isAddingKeybind ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.04)))
                        border.color: root.isAddingKeybind || addBtnHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: addBtnHover }

                        Text {
                            id: addBtnText
                            anchors.centerIn: parent
                            text: root.isAddingKeybind ? "Close Form" : "Add Keybind"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.isAddingKeybind || addBtnHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isAddingKeybind = !root.isAddingKeybind;
                                if (root.isAddingKeybind) {
                                    root.editingItem = null;
                                }
                                root.isCapturingAddKey = false;
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: shortcutsCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: shortcutsCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Add Keybind Form Drawer */
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: root.isAddingKeybind ? (addDrawerRect.implicitHeight + 12) : 0
                            visible: implicitHeight > 0
                            opacity: root.isAddingKeybind ? 1.0 : 0.0
                            clip: true

                            Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 160 } }

                            Rectangle {
                                id: addDrawerRect
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                    margins: 4
                                }
                                implicitHeight: addCol.implicitHeight + 20
                                radius: 10
                                color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                                border.color: root.theme.accentPrimary
                                border.width: 1

                                ColumnLayout {
                                    id: addCol
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 12
                                    }
                                    spacing: 12

                                    Text {
                                        text: "Create New Keybinding"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    /* Form Row 1: Name / Description */
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Text {
                                            text: "Name:"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.textSecondary
                                            Layout.preferredWidth: 70
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 32
                                            radius: 6
                                            color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                                            border.color: addNameInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                            border.width: addNameInput.activeFocus ? 2 : 1

                                            TextInput {
                                                id: addNameInput
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                verticalAlignment: TextInput.AlignVCenter
                                                font.family: root.font
                                                font.pixelSize: 12
                                                color: root.theme.textPrimary
                                                clip: true
                                                onTextChanged: root.addName = text

                                                Text {
                                                    text: "Shortcut Name (e.g. Browser, Terminal, Screenshot)"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    color: root.theme.textSecondary
                                                    visible: !addNameInput.text && !addNameInput.activeFocus
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }
                                    }

                                    /* Form Row 2: Dispatcher & Command */
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Text {
                                            text: "Action:"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.textSecondary
                                            Layout.preferredWidth: 70
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Rectangle {
                                            id: addActionSegmentTrack
                                            implicitWidth: 620
                                            Layout.preferredWidth: 620
                                            height: 32
                                            radius: 7
                                            color: root.theme.bgBase
                                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                            border.width: 1
                                            Layout.alignment: Qt.AlignVCenter

                                            readonly property var options: root.addDispatcherOptions
                                            readonly property int activeIdx: {
                                                for (let i = 0; i < options.length; i++) {
                                                    if (options[i].val === root.addDispatcher) return i;
                                                }
                                                return 0;
                                            }
                                            readonly property real cellWidth: (width - 6 - ((options.length - 1) * 4)) / Math.max(1, options.length)

                                            /* Sliding Pill */
                                            Rectangle {
                                                y: 3
                                                height: parent.height - 6
                                                width: addActionSegmentTrack.cellWidth
                                                x: 3 + addActionSegmentTrack.activeIdx * (addActionSegmentTrack.cellWidth + 4)
                                                radius: 5
                                                color: root.theme.bgSelected
                                                border.color: root.theme.accentPrimary
                                                border.width: 1

                                                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                            }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 3
                                                spacing: 4

                                                Repeater {
                                                    model: addActionSegmentTrack.options

                                                    delegate: Rectangle {
                                                        id: aSegBtn
                                                        required property var modelData
                                                        required property int index
                                                        readonly property bool isSel: addActionSegmentTrack.activeIdx === index

                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        radius: 5
                                                        color: !isSel && aSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                                        Behavior on color { ColorAnimation { duration: 140 } }

                                                        HoverHandler { id: aSegHover }

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: aSegBtn.modelData.name
                                                            font.family: root.font
                                                            font.pixelSize: 11
                                                            font.bold: aSegBtn.isSel
                                                            color: aSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                            opacity: aSegBtn.isSel || aSegHover.hovered ? 1.0 : 0.75
                                                            Behavior on color { ColorAnimation { duration: 140 } }
                                                            Behavior on opacity { NumberAnimation { duration: 140 } }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: root.addDispatcher = aSegBtn.modelData.val
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Item { Layout.fillWidth: true }
                                    }

                                    /* Form Row 2b: Custom Dispatcher Name (if custom selected) */
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10
                                        visible: root.addDispatcher === "custom"

                                        Text {
                                            text: "Dispatcher:"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.textSecondary
                                            Layout.preferredWidth: 70
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 32
                                            radius: 6
                                            color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                                            border.color: addCustomDispInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                            border.width: addCustomDispInput.activeFocus ? 2 : 1

                                            TextInput {
                                                id: addCustomDispInput
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                verticalAlignment: TextInput.AlignVCenter
                                                font.family: root.font
                                                font.pixelSize: 12
                                                color: root.theme.textPrimary
                                                clip: true
                                                onTextChanged: root.addCustomDisp = text

                                                Text {
                                                    text: "Hyprland dispatcher name (e.g. splitratio, movetoworkspace, pin)"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    color: root.theme.textSecondary
                                                    visible: !addCustomDispInput.text && !addCustomDispInput.activeFocus
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }
                                    }

                                    /* Form Row 2c: Command / Argument */
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10
                                        visible: root.addDispatcher !== "killactive" && root.addDispatcher !== "togglefloating"

                                        Text {
                                            text: root.addDispatcher === "workspace" ? "Workspace:" :
                                                  (root.addDispatcher === "fullscreen" ? "Mode:" :
                                                  (root.addDispatcher === "custom" ? "Argument:" : "Command:"))
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.textSecondary
                                            Layout.preferredWidth: 70
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 32
                                            radius: 6
                                            color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                                            border.color: addArgInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                            border.width: addArgInput.activeFocus ? 2 : 1

                                            TextInput {
                                                id: addArgInput
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                verticalAlignment: TextInput.AlignVCenter
                                                font.family: root.font
                                                font.pixelSize: 12
                                                color: root.theme.textPrimary
                                                clip: true
                                                onTextChanged: root.addArg = text

                                                Text {
                                                    text: root.addDispatcher === "workspace" ? "Workspace number or name (e.g. 1, 2, m+1)" :
                                                          (root.addDispatcher === "fullscreen" ? "0 (toggle fullscreen) or 1 (maximize)" :
                                                          (root.addDispatcher === "custom" ? "Optional argument (e.g. 1, +0.1, or l)" : "Command to run (e.g. firefox, kitty, grim -g ...)"))
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    color: root.theme.textSecondary
                                                    visible: !addArgInput.text && !addArgInput.activeFocus
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }
                                    }

                                    /* Form Row 2d: Static Dispatcher Info */
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10
                                        visible: root.addDispatcher === "killactive" || root.addDispatcher === "togglefloating"

                                        Text {
                                            text: "Detail:"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.textSecondary
                                            Layout.preferredWidth: 70
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: root.addDispatcher === "killactive" ? "Closes the active window (no extra parameters needed)." : "Toggles window floating / tiling state (no extra parameters needed)."
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.italic: true
                                            color: root.theme.textSecondary
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }

                                    /* Form Row 3: Modifiers Selection */
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Text {
                                            text: "Modifiers:"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.textSecondary
                                            Layout.preferredWidth: 70
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Rectangle {
                                            implicitWidth: 280
                                            height: 32
                                            radius: 7
                                            color: root.theme.bgBase
                                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                            border.width: 1
                                            Layout.alignment: Qt.AlignVCenter

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 3
                                                spacing: 4

                                                Repeater {
                                                    model: [
                                                        { label: "Super", id: "super" },
                                                        { label: "Ctrl",  id: "ctrl" },
                                                        { label: "Alt",   id: "alt" },
                                                        { label: "Shift", id: "shift" }
                                                    ]

                                                    delegate: Rectangle {
                                                        id: addModBtn
                                                        required property var modelData
                                                        readonly property bool isActive: {
                                                            if (modelData.id === "super") return root.addSuper;
                                                            if (modelData.id === "ctrl")  return root.addCtrl;
                                                            if (modelData.id === "alt")   return root.addAlt;
                                                            if (modelData.id === "shift") return root.addShift;
                                                            return false;
                                                        }

                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        radius: 5
                                                        color: isActive ? root.theme.bgSelected : (addModHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                                                        border.color: isActive ? root.theme.accentPrimary : "transparent"
                                                        border.width: isActive ? 1 : 0

                                                        Behavior on color { ColorAnimation { duration: 140 } }
                                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                                        HoverHandler { id: addModHover }

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: addModBtn.modelData.label
                                                            font.family: root.font
                                                            font.pixelSize: 11
                                                            font.bold: addModBtn.isActive
                                                            color: addModBtn.isActive ? root.theme.accentPrimary : root.theme.textPrimary
                                                            opacity: addModBtn.isActive || addModHover.hovered ? 1.0 : 0.75
                                                            Behavior on color { ColorAnimation { duration: 140 } }
                                                            Behavior on opacity { NumberAnimation { duration: 140 } }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                if (addModBtn.modelData.id === "super") root.addSuper = !root.addSuper;
                                                                else if (addModBtn.modelData.id === "ctrl")  root.addCtrl = !root.addCtrl;
                                                                else if (addModBtn.modelData.id === "alt")   root.addAlt = !root.addAlt;
                                                                else if (addModBtn.modelData.id === "shift") root.addShift = !root.addShift;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Item { Layout.fillWidth: true }
                                    }

                                    /* Form Row 4: Key Input + Record Button + Live Preview */
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: "Key:"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.textSecondary
                                            Layout.preferredWidth: 70
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Rectangle {
                                            width: 110
                                            height: 30
                                            radius: 6
                                            color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                                            border.color: addKeyInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                            border.width: addKeyInput.activeFocus ? 2 : 1

                                            TextInput {
                                                id: addKeyInput
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                verticalAlignment: TextInput.AlignVCenter
                                                text: root.addKey
                                                font.family: root.font
                                                font.pixelSize: 12
                                                font.bold: true
                                                color: root.theme.textPrimary
                                                clip: true
                                                onTextChanged: {
                                                    if (text !== root.addKey) root.addKey = text;
                                                }
                                            }
                                        }

                                        // Record Key Button
                                        Rectangle {
                                            implicitWidth: addRecLabel.implicitWidth + 16
                                            height: 30
                                            radius: 6
                                            color: root.isCapturingAddKey ? root.theme.accentPrimary : (addRecMouse.containsMouse ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)))
                                            border.color: root.isCapturingAddKey ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                            border.width: 1

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 6

                                                Text {
                                                    id: addRecLabel
                                                    text: root.isCapturingAddKey ? "Listening... Press keys (Esc cancels)" : "Record Key"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: root.isCapturingAddKey ? root.theme.bgBase : root.theme.textPrimary
                                                }
                                            }

                                            MouseArea {
                                                id: addRecMouse
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.isCapturingAddKey = !root.isCapturingAddKey;
                                                    if (root.isCapturingAddKey) {
                                                        keyCaptureItem.forceActiveFocus();
                                                    }
                                                }
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Preview Pills
                                        RowLayout {
                                            spacing: 4
                                            Layout.alignment: Qt.AlignVCenter

                                            Text {
                                                text: "Preview:"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                color: root.theme.textSecondary
                                            }

                                            Repeater {
                                                model: root.getAddPreviewPills()
                                                Rectangle {
                                                    required property var modelData
                                                    implicitWidth: addPrevPillText.implicitWidth + 10
                                                    height: 22
                                                    radius: 5
                                                    color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)
                                                    border.color: root.theme.accentPrimary
                                                    border.width: 1

                                                    Text {
                                                        id: addPrevPillText
                                                        anchors.centerIn: parent
                                                        text: modelData
                                                        font.family: root.font
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                        color: root.theme.textPrimary
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    /* Form Row 5: Action Buttons & Target Notice */
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Item { Layout.fillWidth: true }

                                        // Cancel
                                        Rectangle {
                                            implicitWidth: cancelAddText.implicitWidth + 24
                                            height: 30
                                            radius: 7
                                            color: cancelAddHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase
                                            border.color: cancelAddHover.hovered ? root.theme.textSecondary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                            border.width: 1

                                            Behavior on color { ColorAnimation { duration: 140 } }
                                            Behavior on border.color { ColorAnimation { duration: 140 } }

                                            HoverHandler { id: cancelAddHover }

                                            Text {
                                                id: cancelAddText
                                                anchors.centerIn: parent
                                                text: "Cancel"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: cancelAddHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.isAddingKeybind = false;
                                                    root.isCapturingAddKey = false;
                                                }
                                            }
                                        }

                                        // Add & Save
                                        Rectangle {
                                            implicitWidth: saveAddText.implicitWidth + 28
                                            height: 30
                                            radius: 7
                                            readonly property bool canSave: root.addKey.trim().length > 0
                                            color: canSave
                                                ? (saveAddHover.hovered ? Qt.lighter(root.theme.accentPrimary, 1.1) : root.theme.accentPrimary)
                                                : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                                            opacity: canSave ? 1.0 : 0.5

                                            Behavior on color { ColorAnimation { duration: 140 } }
                                            Behavior on opacity { NumberAnimation { duration: 140 } }

                                            HoverHandler { id: saveAddHover }

                                            Text {
                                                id: saveAddText
                                                anchors.centerIn: parent
                                                text: "Add Keybind"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: parent.canSave ? root.theme.bgBase : root.theme.textMuted
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: parent.canSave ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                enabled: parent.canSave
                                                onClicked: root.saveNewKeybind()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        /* Search Bar Row */
                        Item {
                            Layout.fillWidth: true
                            height: 48

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: 8
                                color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                                border.color: searchInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                border.width: searchInput.activeFocus ? 2 : 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: "󰍉"
                                        font.family: root.font
                                        font.pixelSize: 14
                                        color: root.theme.textSecondary
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    TextInput {
                                        id: searchInput
                                        Layout.fillWidth: true
                                        font.family: root.font
                                        font.pixelSize: 13
                                        color: root.theme.textPrimary
                                        clip: true
                                        selectByMouse: true
                                        onTextChanged: root.searchQuery = text

                                        Text {
                                            text: "Search shortcuts (e.g. kitty, workspace, toggle)..."
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: root.theme.textSecondary
                                            visible: !searchInput.text && !searchInput.activeFocus
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Text {
                                        text: "✕"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        color: clearSearchMouse.containsMouse ? root.theme.textPrimary : root.theme.textSecondary
                                        visible: searchInput.text.length > 0

                                        MouseArea {
                                            id: clearSearchMouse
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                searchInput.text = "";
                                                root.searchQuery = "";
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        /* Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Shortcuts Repeater */
                        Repeater {
                            model: root.filteredBinds

                            Item {
                                id: rowItem
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                clip: true
                                readonly property bool isEditing: root.editingUid === modelData.uid && root.editingUid !== -1
                                readonly property bool isConfirmingUnbind: root.confirmingUnbindUid === modelData.uid

                                implicitHeight: isEditing ? (50 + editDrawer.implicitHeight + 8) : 50

                                Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                /* Main Shortcut Row */
                                Rectangle {
                                    id: mainRowRect
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                        leftMargin: 4
                                        rightMargin: 4
                                    }
                                    height: 50
                                    radius: 8
                                    color: rowItem.isEditing ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.08)) : (shortcutMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.04)) : "transparent")

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 12

                                        ColumnLayout {
                                            spacing: 2
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter

                                            Text {
                                                text: root.getFriendlyAction(modelData)
                                                font.family: root.font
                                                font.pixelSize: 13
                                                font.bold: true
                                                color: root.theme.textPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: (modelData.dispatcher || "") + (modelData.arg ? " " + modelData.arg : "")
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textSecondary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                opacity: 0.8
                                            }
                                        }

                                        /* Keyboard Pills & Edit Trigger */
                                        RowLayout {
                                            spacing: 8
                                            Layout.alignment: Qt.AlignVCenter

                                            RowLayout {
                                                spacing: 4
                                                Repeater {
                                                    model: root.getModPills(modelData.modmask, modelData.key)

                                                    Rectangle {
                                                        required property var modelData
                                                        implicitWidth: keyLabel.implicitWidth + 12
                                                        height: 24
                                                        radius: 6
                                                        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3)
                                                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12)
                                                        border.width: 1

                                                        Text {
                                                            id: keyLabel
                                                            anchors.centerIn: parent
                                                            text: modelData
                                                            font.family: root.font
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            color: root.theme.textPrimary
                                                        }
                                                    }
                                                }
                                            }

                                            /* Edit Button */
                                            Rectangle {
                                                width: 26
                                                height: 24
                                                radius: 6
                                                color: rowItem.isEditing ? root.theme.accentPrimary : (editHoverMouse.containsMouse ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)))
                                                border.color: rowItem.isEditing ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰏫"
                                                    font.family: root.font
                                                    font.pixelSize: 12
                                                    color: rowItem.isEditing ? root.theme.bgBase : root.theme.textPrimary
                                                }

                                                MouseArea {
                                                    id: editHoverMouse
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    hoverEnabled: true
                                                    onClicked: root.startEditing(modelData)
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: shortcutMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.startEditing(modelData)
                                    }
                                }

                                /* Expandable Edit Drawer */
                                Rectangle {
                                    id: editDrawer
                                    anchors {
                                        top: mainRowRect.bottom
                                        left: parent.left
                                        right: parent.right
                                        leftMargin: 8
                                        rightMargin: 8
                                        topMargin: 2
                                    }
                                    implicitHeight: rowItem.isEditing ? (drawerCol.implicitHeight + 20) : 0
                                    visible: opacity > 0 || implicitHeight > 0
                                    opacity: rowItem.isEditing ? 1.0 : 0.0
                                    radius: 8
                                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3)
                                    border.color: root.theme.accentPrimary
                                    border.width: 1
                                    clip: true

                                    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 160 } }

                                    ColumnLayout {
                                        id: drawerCol
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            top: parent.top
                                            margins: 10
                                        }
                                        spacing: 10

                                        /* Row 0: Keybinding Name / Label */
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Text {
                                                text: "Name:"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.textSecondary
                                                Layout.preferredWidth: 70
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 32
                                                radius: 7
                                                color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                                                border.color: editNameInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                                border.width: editNameInput.activeFocus ? 2 : 1

                                                TextInput {
                                                    id: editNameInput
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 8
                                                    anchors.rightMargin: 8
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    text: root.editName
                                                    font.family: root.font
                                                    font.pixelSize: 12
                                                    color: root.theme.textPrimary
                                                    clip: true
                                                    onTextChanged: {
                                                        if (text !== root.editName) root.editName = text;
                                                    }

                                                    Text {
                                                        text: "Shortcut Name (e.g. Browser, Terminal, Screenshot)"
                                                        font.family: root.font
                                                        font.pixelSize: 11
                                                        color: root.theme.textSecondary
                                                        visible: !editNameInput.text && !editNameInput.activeFocus
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                }
                                            }
                                        }

                                        /* Row 0a: Action Dispatcher Selection */
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Text {
                                                text: "Action:"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.textSecondary
                                                Layout.preferredWidth: 70
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Rectangle {
                                                id: editActionSegmentTrack
                                                implicitWidth: 620
                                                Layout.preferredWidth: 620
                                                height: 32
                                                radius: 7
                                                color: root.theme.bgBase
                                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                                border.width: 1
                                                Layout.alignment: Qt.AlignVCenter

                                                readonly property var options: root.editDispatcherOptions
                                                readonly property int activeIdx: {
                                                    for (let i = 0; i < options.length; i++) {
                                                        if (options[i].val === root.editDispatcher) return i;
                                                    }
                                                    return 0;
                                                }
                                                readonly property real cellWidth: (width - 6 - ((options.length - 1) * 4)) / Math.max(1, options.length)

                                                /* Sliding Pill */
                                                Rectangle {
                                                    y: 3
                                                    height: parent.height - 6
                                                    width: editActionSegmentTrack.cellWidth
                                                    x: 3 + editActionSegmentTrack.activeIdx * (editActionSegmentTrack.cellWidth + 4)
                                                    radius: 5
                                                    color: root.theme.bgSelected
                                                    border.color: root.theme.accentPrimary
                                                    border.width: 1

                                                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                                }

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 3
                                                    spacing: 4

                                                    Repeater {
                                                        model: editActionSegmentTrack.options

                                                        delegate: Rectangle {
                                                            id: eSegBtn
                                                            required property var modelData
                                                            required property int index
                                                            readonly property bool isSel: editActionSegmentTrack.activeIdx === index

                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            radius: 5
                                                            color: !isSel && eSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                                            Behavior on color { ColorAnimation { duration: 140 } }

                                                            HoverHandler { id: eSegHover }

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: eSegBtn.modelData.name
                                                                font.family: root.font
                                                                font.pixelSize: 11
                                                                font.bold: eSegBtn.isSel
                                                                color: eSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                                opacity: eSegBtn.isSel || eSegHover.hovered ? 1.0 : 0.75
                                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                                Behavior on opacity { NumberAnimation { duration: 140 } }
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    root.editDispatcher = eSegBtn.modelData.val;
                                                                    if (eSegBtn.modelData.val === "custom" && !root.editCustomDisp) {
                                                                        root.editCustomDisp = root.editingItem ? (root.editingItem.dispatcher || "") : "";
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Item { Layout.fillWidth: true }
                                        }

                                        /* Row 0b: Custom Dispatcher Name (if custom selected) */
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10
                                            visible: root.editDispatcher === "custom"

                                            Text {
                                                text: "Dispatcher:"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.textSecondary
                                                Layout.preferredWidth: 70
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 32
                                                radius: 7
                                                color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                                                border.color: customDispEditInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                                border.width: customDispEditInput.activeFocus ? 2 : 1

                                                TextInput {
                                                    id: customDispEditInput
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 8
                                                    anchors.rightMargin: 8
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    text: root.editCustomDisp
                                                    font.family: root.font
                                                    font.pixelSize: 12
                                                    color: root.theme.textPrimary
                                                    clip: true
                                                    onTextChanged: {
                                                        if (text !== root.editCustomDisp) root.editCustomDisp = text;
                                                    }

                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        visible: !customDispEditInput.text && !customDispEditInput.activeFocus
                                                        text: "Hyprland dispatcher name (e.g. splitratio, layoutmsg, movetoworkspace)"
                                                        font.family: root.font
                                                        font.pixelSize: 11
                                                        color: root.theme.textSecondary
                                                    }
                                                }
                                            }
                                        }

                                        /* Row 0c: Command / Argument / Parameter Input */
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10
                                            visible: root.editDispatcher !== "killactive" && root.editDispatcher !== "togglefloating"

                                            Text {
                                                text: root.editDispatcher === "exec" ? "Command:" :
                                                      (root.editDispatcher === "workspace" ? "Workspace:" :
                                                      (root.editDispatcher === "fullscreen" ? "Mode:" :
                                                      (root.editDispatcher === "custom" ? "Argument:" : "Parameter:")))
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.textSecondary
                                                Layout.preferredWidth: 70
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 32
                                                radius: 7
                                                color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                                                border.color: cmdEditInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                                border.width: cmdEditInput.activeFocus ? 2 : 1

                                                TextInput {
                                                    id: cmdEditInput
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 8
                                                    anchors.rightMargin: 8
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    text: root.editArg
                                                    font.family: root.font
                                                    font.pixelSize: 12
                                                    color: root.theme.textPrimary
                                                    clip: true
                                                    onTextChanged: {
                                                        if (text !== root.editArg) root.editArg = text;
                                                    }

                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        visible: !cmdEditInput.text && !cmdEditInput.activeFocus
                                                        text: root.editDispatcher === "exec" ? "Application or command (e.g. kitty, thunar)" :
                                                              (root.editDispatcher === "workspace" ? "Workspace index or name (e.g. 1, 2, m+1)" :
                                                              (root.editDispatcher === "fullscreen" ? "0 (toggle fullscreen) or 1 (maximize)" : "Optional arguments"))
                                                        font.family: root.font
                                                        font.pixelSize: 11
                                                        color: root.theme.textSecondary
                                                    }
                                                }
                                            }
                                        }

                                        /* Row 0d: Static Dispatcher Info */
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10
                                            visible: root.editDispatcher === "killactive" || root.editDispatcher === "togglefloating"

                                            Text {
                                                text: "Detail:"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.textSecondary
                                                Layout.preferredWidth: 70
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Text {
                                                text: root.editDispatcher === "killactive" ? "Closes the active window (no extra parameters needed)." : "Toggles window floating / tiling state (no extra parameters needed)."
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.italic: true
                                                color: root.theme.textSecondary
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }

                                        /* Row 1: Modifiers Selection */
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Text {
                                                text: "Modifiers:"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.textSecondary
                                                Layout.preferredWidth: 70
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Rectangle {
                                                implicitWidth: 280
                                                height: 32
                                                radius: 7
                                                color: root.theme.bgBase
                                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                                border.width: 1
                                                Layout.alignment: Qt.AlignVCenter

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 3
                                                    spacing: 4

                                                    Repeater {
                                                        model: [
                                                            { label: "Super", id: "super" },
                                                            { label: "Ctrl",  id: "ctrl" },
                                                            { label: "Alt",   id: "alt" },
                                                            { label: "Shift", id: "shift" }
                                                        ]

                                                        delegate: Rectangle {
                                                            id: editModBtn
                                                            required property var modelData
                                                            readonly property bool isActive: {
                                                                if (modelData.id === "super") return root.editSuper;
                                                                if (modelData.id === "ctrl")  return root.editCtrl;
                                                                if (modelData.id === "alt")   return root.editAlt;
                                                                if (modelData.id === "shift") return root.editShift;
                                                                return false;
                                                            }

                                                            Layout.fillWidth: true
                                                            Layout.fillHeight: true
                                                            radius: 5
                                                            color: isActive ? root.theme.bgSelected : (editModHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                                                            border.color: isActive ? root.theme.accentPrimary : "transparent"
                                                            border.width: isActive ? 1 : 0

                                                            Behavior on color { ColorAnimation { duration: 140 } }
                                                            Behavior on border.color { ColorAnimation { duration: 140 } }

                                                            HoverHandler { id: editModHover }

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: editModBtn.modelData.label
                                                                font.family: root.font
                                                                font.pixelSize: 11
                                                                font.bold: editModBtn.isActive
                                                                color: editModBtn.isActive ? root.theme.accentPrimary : root.theme.textPrimary
                                                                opacity: editModBtn.isActive || editModHover.hovered ? 1.0 : 0.75
                                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                                Behavior on opacity { NumberAnimation { duration: 140 } }
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    if (editModBtn.modelData.id === "super") root.editSuper = !root.editSuper;
                                                                    else if (editModBtn.modelData.id === "ctrl")  root.editCtrl = !root.editCtrl;
                                                                    else if (editModBtn.modelData.id === "alt")   root.editAlt = !root.editAlt;
                                                                    else if (editModBtn.modelData.id === "shift") root.editShift = !root.editShift;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Item { Layout.fillWidth: true }
                                        }

                                        /* Row 2: Key Text Input + Record Key Button + Live Preview */
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Text {
                                                text: "Key:"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.textSecondary
                                                Layout.preferredWidth: 70
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Rectangle {
                                                width: 110
                                                height: 32
                                                radius: 7
                                                color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                                                border.color: keyEditInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                                border.width: keyEditInput.activeFocus ? 2 : 1

                                                TextInput {
                                                    id: keyEditInput
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 8
                                                    anchors.rightMargin: 8
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    text: root.editKey
                                                    font.family: root.font
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: root.theme.textPrimary
                                                    clip: true
                                                    onTextChanged: {
                                                        if (text !== root.editKey) root.editKey = text;
                                                    }
                                                }
                                            }

                                            /* Record Shortcut Button */
                                            Rectangle {
                                                implicitWidth: recLabel.implicitWidth + 24
                                                height: 32
                                                radius: 7
                                                color: root.isCapturingKey
                                                    ? root.theme.accentPrimary
                                                    : (recHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase)
                                                border.color: root.isCapturingKey
                                                    ? root.theme.accentPrimary
                                                    : (recHover.hovered ? root.theme.textSecondary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: recHover }

                                                Text {
                                                    id: recLabel
                                                    anchors.centerIn: parent
                                                    text: root.isCapturingKey ? "Listening... (Esc cancels)" : "Record Key"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: root.isCapturingKey ? root.theme.bgBase : (recHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.isCapturingKey = !root.isCapturingKey;
                                                        if (root.isCapturingKey) {
                                                            keyCaptureItem.forceActiveFocus();
                                                        }
                                                    }
                                                }
                                            }

                                            Item { Layout.fillWidth: true }

                                            /* Preview Pills */
                                            RowLayout {
                                                spacing: 4
                                                Layout.alignment: Qt.AlignVCenter

                                                Text {
                                                    text: "New:"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    color: root.theme.textSecondary
                                                }

                                                Repeater {
                                                    model: root.getEditPreviewPills()
                                                    Rectangle {
                                                        required property var modelData
                                                        implicitWidth: prevPillText.implicitWidth + 12
                                                        height: 24
                                                        radius: 5
                                                        color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)
                                                        border.color: root.theme.accentPrimary
                                                        border.width: 1

                                                        Text {
                                                            id: prevPillText
                                                            anchors.centerIn: parent
                                                            text: modelData
                                                            font.family: root.font
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: root.theme.textPrimary
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        /* Row 3: Action Buttons */
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: visible ? 30 : 0
                                            spacing: 8
                                            visible: !rowItem.isConfirmingUnbind

                                            // Unbind Button (Text-only, danger hover)
                                            Rectangle {
                                                implicitWidth: delText.implicitWidth + 24
                                                height: 30
                                                radius: 7
                                                color: delHover.hovered ? Qt.rgba(0.9, 0.2, 0.2, 0.15) : root.theme.bgBase
                                                border.color: delHover.hovered ? Qt.rgba(0.9, 0.2, 0.2, 0.5) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: delHover }

                                                Text {
                                                    id: delText
                                                    anchors.centerIn: parent
                                                    text: "Unbind"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: delHover.hovered ? "#ff5555" : root.theme.textSecondary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.confirmingUnbindUid = rowItem.modelData.uid
                                                }
                                            }

                                            Item { Layout.fillWidth: true }

                                            // Cancel
                                            Rectangle {
                                                implicitWidth: cancelText.implicitWidth + 24
                                                height: 30
                                                radius: 7
                                                color: cancelHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase
                                                border.color: cancelHover.hovered ? root.theme.textSecondary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: cancelHover }

                                                Text {
                                                    id: cancelText
                                                    anchors.centerIn: parent
                                                    text: "Cancel"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: cancelHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.editingUid = -1;
                                                        root.editingItem = null;
                                                        root.isCapturingKey = false;
                                                        root.confirmingUnbindUid = -1;
                                                    }
                                                }
                                            }

                                            // Save & Apply
                                            Rectangle {
                                                implicitWidth: saveText.implicitWidth + 28
                                                height: 30
                                                radius: 7
                                                readonly property bool canSave: root.editKey.trim().length > 0
                                                color: canSave
                                                    ? (saveHover.hovered ? Qt.lighter(root.theme.accentPrimary, 1.1) : root.theme.accentPrimary)
                                                    : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                                                opacity: canSave ? 1.0 : 0.5

                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                Behavior on opacity { NumberAnimation { duration: 140 } }

                                                HoverHandler { id: saveHover }

                                                Text {
                                                    id: saveText
                                                    anchors.centerIn: parent
                                                    text: "Save & Apply"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: parent.canSave ? root.theme.bgBase : root.theme.textMuted
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: parent.canSave ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                    enabled: parent.canSave
                                                    onClicked: root.applyEditedKeybind()
                                                }
                                            }
                                        }

                                        /* Row 3b: Inline Confirmation Bar (When Unbind is clicked) */
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: visible ? 34 : 0
                                            height: 34
                                            radius: 7
                                            color: Qt.rgba(0.9, 0.2, 0.2, 0.1)
                                            border.color: Qt.rgba(0.9, 0.2, 0.2, 0.35)
                                            border.width: 1
                                            visible: rowItem.isConfirmingUnbind

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 8
                                                spacing: 10

                                                Text {
                                                    text: "Are you sure you want to remove this keybind?"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: "#ff6b6b"
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                Item { Layout.fillWidth: true }

                                                // Cancel Button
                                                Rectangle {
                                                    implicitWidth: cancelPromptText.implicitWidth + 20
                                                    height: 26
                                                    radius: 6
                                                    color: confCancelHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : root.theme.bgBase
                                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                                                    border.width: 1

                                                    Behavior on color { ColorAnimation { duration: 140 } }

                                                    HoverHandler { id: confCancelHover }

                                                    Text {
                                                        id: cancelPromptText
                                                        anchors.centerIn: parent
                                                        text: "Cancel"
                                                        font.family: root.font
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: root.theme.textPrimary
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.confirmingUnbindUid = -1
                                                    }
                                                }

                                                // Confirm Yes Button
                                                Rectangle {
                                                    implicitWidth: yesBtnText.implicitWidth + 20
                                                    height: 26
                                                    radius: 6
                                                    color: confYesHover.hovered ? "#ee3333" : "#ff5555"

                                                    Behavior on color { ColorAnimation { duration: 140 } }

                                                    HoverHandler { id: confYesHover }

                                                    Text {
                                                        id: yesBtnText
                                                        anchors.centerIn: parent
                                                        text: "Yes, Unbind"
                                                        font.family: root.font
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: "#ffffff"
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            root.confirmingUnbindUid = -1;
                                                            root.deleteKeybind(rowItem.modelData);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        /* Empty State if no match */
                        Item {
                            Layout.fillWidth: true
                            height: 60
                            visible: root.filteredBinds.length === 0

                            Text {
                                anchors.centerIn: parent
                                text: "No matching shortcuts found"
                                font.family: root.font
                                font.pixelSize: 13
                                color: root.theme.textSecondary
                            }
                        }

                        /* "Show All" toggle button if list is truncated and no active search */
                        Item {
                            Layout.fillWidth: true
                            height: 44
                            visible: !root.showAllShortcuts && !root.searchQuery && root.rawBinds.length > 15

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: 8
                                color: showAllMouse.containsMouse ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"

                                Behavior on color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: "Show all " + root.rawBinds.length + " shortcuts"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.accentPrimary
                                    }

                                    Text {
                                        text: "󰅀"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        color: root.theme.accentPrimary
                                    }
                                }

                                MouseArea {
                                    id: showAllMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.showAllShortcuts = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
