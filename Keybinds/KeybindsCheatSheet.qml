import Quickshell
import Quickshell.Io
import QtQuick
import "KeybindUtils.js" as KeybindUtils
import "Components"

Scope {
    id: root

    property var theme: Theme
    property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"
    property bool panelVisible: false
    property bool loading: false
    property var binds: []

    readonly property string scriptPath: Quickshell.shellPath("Settings/scripts/manage_keybind.py")

    function reloadBinds() {
        root.loading = true;
        queryBindsProc.running = true;
    }

    IpcHandler {
        target: "keybinds"

        function toggle() {
            if (!root.panelVisible) {
                root.reloadBinds();
                root.panelVisible = true;
            } else {
                root.panelVisible = false;
            }
        }
    }

    Process {
        id: queryBindsProc
        command: ["python3", root.scriptPath, "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    const parsed = JSON.parse(text.trim() || "[]");
                    root.binds = KeybindUtils.normalizeBinds(parsed);
                } catch (e) {
                    console.warn("KeybindsCheatSheet: failed to parse binds:", e);
                    root.binds = [];
                }
            }
        }
    }

    Loader {
        active: root.panelVisible
        sourceComponent: Component {
            KeybindsWindow {
                theme: root.theme
                font: root.font
                binds: root.binds
                loading: root.loading

                onOverlayClosed: root.panelVisible = false
                onRefreshRequested: root.reloadBinds()
            }
        }
    }
}
