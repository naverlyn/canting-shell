import Quickshell
import Quickshell.Io
import QtQuick
import "../ThemeSwitcher"
import "Components"

Scope {
    id: root

    property var theme: Theme
    property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"

    property bool panelVisible: false
    property int selectedIndex: 0
    property int pendingActionIndex: -1
    property int confirmSecondsLeft: 0
    property string userName: "User"
    property string uptimeText: ""

    readonly property var actions: [
        {
            id: "lock",
            label: "Lock",
            subtitle: "Lock session",
            icon: "󰌾",
            hotkey: "L",
            accentKey: "accentPrimary",
            confirm: false,
            cmd: ["qs", "ipc", "call", "lockscreen", "lock"]
        },
        {
            id: "suspend",
            label: "Suspend",
            subtitle: "Sleep to RAM",
            icon: "󰤄",
            hotkey: "S",
            accentKey: "accentCyan",
            confirm: false,
            cmd: ["systemctl", "suspend"]
        },
        {
            id: "hibernate",
            label: "Hibernate",
            subtitle: "Save to disk",
            icon: "󰋊",
            hotkey: "H",
            accentKey: "accentGreen",
            confirm: true,
            cmd: ["systemctl", "hibernate"]
        },
        {
            id: "logout",
            label: "Logout",
            subtitle: "Exit Hyprland",
            icon: "󰍃",
            hotkey: "E",
            accentKey: "accentOrange",
            confirm: true,
            cmd: ["hyprctl", "dispatch", "exit"]
        },
        {
            id: "reboot",
            label: "Reboot",
            subtitle: "Restart system",
            icon: "󰜉",
            hotkey: "R",
            accentKey: "accentOrange",
            confirm: true,
            cmd: ["systemctl", "reboot"]
        },
        {
            id: "shutdown",
            label: "Shutdown",
            subtitle: "Power off",
            icon: "󰐥",
            hotkey: "P",
            accentKey: "accentRed",
            confirm: true,
            cmd: ["systemctl", "poweroff"]
        }
    ]

    function accentFor(action) {
        const t = root.theme || Theme;
        if (!action) return t.accentPrimary;
        const val = t[action.accentKey];
        return val !== undefined ? val : t.accentPrimary;
    }

    function openMenu() {
        root.pendingActionIndex = -1;
        root.confirmSecondsLeft = 0;
        confirmTimer.stop();
        root.selectedIndex = 0;
        root.panelVisible = true;
        uptimeProc.running = true;
    }

    function closeMenu() {
        confirmTimer.stop();
        root.pendingActionIndex = -1;
        root.confirmSecondsLeft = 0;
        root.panelVisible = false;
    }

    function toggleMenu() {
        if (root.panelVisible) {
            closeMenu();
        } else {
            openMenu();
        }
    }

    function triggerAction(index) {
        if (index < 0 || index >= root.actions.length) return;
        root.selectedIndex = index;
        const action = root.actions[index];
        if (action.confirm) {
            if (root.pendingActionIndex === index) {
                executeAction(index);
            } else {
                root.pendingActionIndex = index;
                root.confirmSecondsLeft = 5;
                confirmTimer.restart();
            }
        } else {
            executeAction(index);
        }
    }

    function cancelConfirmation() {
        confirmTimer.stop();
        root.pendingActionIndex = -1;
        root.confirmSecondsLeft = 0;
    }

    function executeAction(index) {
        if (index < 0 || index >= root.actions.length) return;
        const action = root.actions[index];
        closeMenu();
        actionRunner.command = action.cmd;
        actionRunner.running = true;
    }

    IpcHandler {
        target: "powermenu"

        function toggle() { root.toggleMenu(); }
        function open() { root.openMenu(); }
        function close() { root.closeMenu(); }
    }

    Process {
        id: whoamiProc
        command: ["whoami"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim();
                if (name !== "") {
                    root.userName = name.charAt(0).toUpperCase() + name.slice(1);
                }
            }
        }
    }

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.uptimeText = text.trim().replace(/^up\s+/, "");
            }
        }
    }

    Process {
        id: actionRunner
        running: false
    }

    Timer {
        id: confirmTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (root.pendingActionIndex < 0) {
                confirmTimer.stop();
                return;
            }
            if (root.confirmSecondsLeft <= 1) {
                confirmTimer.stop();
                root.executeAction(root.pendingActionIndex);
            } else {
                root.confirmSecondsLeft -= 1;
            }
        }
    }

    Loader {
        active: root.panelVisible
        sourceComponent: PowerMenuOverlay {
            theme: root.theme || Theme
            font: root.font
            actions: root.actions
            selectedIndex: root.selectedIndex
            pendingActionIndex: root.pendingActionIndex
            confirmSecondsLeft: root.confirmSecondsLeft
            userName: root.userName
            uptimeText: root.uptimeText
            accentResolver: root.accentFor

            onCloseRequested: root.closeMenu()
            onCancelConfirmRequested: root.cancelConfirmation()
            onActionTriggered: (index) => root.triggerAction(index)
            onActionConfirmed: (index) => root.executeAction(index)
            onSelectionChanged: (index) => { root.selectedIndex = index; }
        }
    }
}
