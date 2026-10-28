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
import "./Keyboard"

Item {
    id: root
    property alias keyCaptureItemRef: keyCaptureItem
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

    /* Apply live AND persist (Lua or .conf) via manage_hyprland.sh.
       "input:touchpad:natural_scroll" -> section "input.touchpad", key "natural_scroll" */
    readonly property string hyprVarScript: Qt.resolvedUrl("../scripts/manage_hyprland.sh").toString().replace(/^file:\/\//, "")
    function applyHyprKeyword(key, val) {
        const parts = String(key).split(":");
        const k = parts.pop();
        hyprcmd.command = [root.hyprVarScript, "set", parts.join("."), k, String(val)];
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
        if (!item) return "";
        if (item.description && item.description.length > 0 && !item.description.startsWith("__lua") && !item.description.startsWith("Lua ")) {
            return item.description;
        }
        const disp = item.dispatcher || "";
        const arg = item.arg || "";

        if (disp === "killactive" || disp === "closewindow") return "Close Active Window";
        if (disp === "togglefloating") return "Toggle Floating Window";
        if (disp === "fullscreen") return arg === "1" ? "Maximize Window" : "Toggle Fullscreen";
        if (disp === "workspace") return "Switch to Workspace " + arg;
        if (disp === "movetoworkspace") return "Move Window to Workspace " + arg;
        if (disp === "movetoworkspacesilent") return "Move Silently to Workspace " + arg;
        if (disp === "splitratio") return "Adjust Split Ratio";
        if (disp === "movefocus") return "Focus Window" + (arg ? " (" + arg + ")" : "");
        if (disp === "togglesplit") return "Toggle Split Layout";
        if (disp === "pseudo") return "Pseudo Tiling";
        if (disp === "togglespecialworkspace") return "Special Workspace (" + (arg || "Default") + ")";

        if (disp === "exec") {
            // Quickshell desktop shell IPC
            if (arg.includes("launcher toggle")) return "App Launcher";
            if (arg.includes("settings toggle")) return "Settings App";
            if (arg.includes("wallpaper toggle")) return "Wallpaper Switcher";
            if (arg.includes("monitors toggle")) return "Display Settings";
            if (arg.includes("theme toggle")) return "Theme Switcher";
            if (arg.includes("clipboard toggle")) return "Clipboard Manager";
            if (arg.includes("notifications dismiss_all")) return "Dismiss Notifications";

            // Standard volume, brightness, and screenshot utilities
            if (arg.includes("wpctl") || arg.includes("pamixer") || arg.includes("pactl")) return "Volume Control";
            if (arg.includes("brightnessctl") || arg.includes("light")) return "Brightness Control";
            if (arg.includes("ScreenShot.sh") || arg.includes("grim") || arg.includes("slurp") || arg.includes("hyprshot") || arg.includes("grimblast")) return "Take Screenshot";

            // Generic app launchers
            if (arg.includes("rofi") || arg.includes("wofi") || arg.includes("fuzzel") || arg.includes("tofi")) {
                if (arg.includes("window")) return "Window Switcher";
                if (arg.includes("emoji")) return "Emoji Picker";
                return "App Launcher";
            }

            if (arg === "kitty" || arg.includes("kitty")) return "Terminal (kitty)";
            if (arg === "nautilus" || arg.includes("nautilus")) return "File Manager (nautilus)";

            // Dynamic clean title for any application or script path
            return root.formatTitle(arg);
        }

        if (disp === "__lua" || disp === "lua") {
            return "Custom Shortcut (" + (item.key || arg) + ")";
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
        command: ["bash", root.scriptPath, "list"]
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
        contentHeight: keyboardPageContentInst.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !keyboardPageContentInst.keyboardKeyRepeatGroupInstRef.delayMouseRef.pressed && !keyboardPageContentInst.keyboardKeyRepeatGroupInstRef.rateMouseRef.pressed

        KeyboardPageContent {
            id: keyboardPageContentInst
            root: root
        }
    }
}
