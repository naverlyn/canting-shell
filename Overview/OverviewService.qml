import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "../ThemeSwitcher"
import "Components"

Scope {
    id: root

    property var theme: Theme
    property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"

    property bool panelVisible: false
    property string mode: "workspaces" // "switcher" | "workspaces"
    property int selectedIndex: 0
    property string searchQuery: ""
    property bool isLua: true

    Process {
        id: configFormatCheck
        command: ["sh", "-c", "[ -f \"$HOME/.config/hypr/hyprland.lua\" ] && echo lua || echo conf"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.isLua = (text.trim() === "lua");
            }
        }
    }

    readonly property var sortedWorkspaces: {
        if (!root.panelVisible) return [];
        return [...Hyprland.workspaces.values]
            .filter(w => w && w.id > 0)
            .sort((a, b) => a.id - b.id);
    }

    function isValidToplevel(t) {
        if (!t || !t.address) return false;

        const ws = t.workspace;
        const wsId = ws ? ws.id : -1;
        const wsName = ws && ws.name ? String(ws.name) : "";
        if (!ws || (wsId <= 0 && !wsName.startsWith("special:"))) return false;

        const ipc = t.lastIpcObject;
        if (ipc) {
            if (ipc.mapped === false || ipc.hidden === true) return false;
            if (Array.isArray(ipc.size) && (ipc.size[0] <= 1 || ipc.size[1] <= 1)) return false;
            const cls = String(ipc.class || ipc.initialClass || "").toLowerCase();
            if (cls === "xsettingsd" || cls === "xwaylandvideobridge") return false;
        } else if (!t.wayland) {
            return false;
        }

        const title = String(t.title || "").trim().toLowerCase();
        if (title === "xsettingsd") return false;

        return true;
    }

    property var sortedToplevels: []

    function rebuildSortedToplevels() {
        if (!root.panelVisible) {
            if (root.sortedToplevels.length > 0) root.sortedToplevels = [];
            return;
        }
        const list = [...Hyprland.toplevels.values].filter(t => root.isValidToplevel(t));
        list.sort((a, b) => {
            const wsA = a.workspace ? a.workspace.id : 999;
            const wsB = b.workspace ? b.workspace.id : 999;
            if (wsA !== wsB) return wsA - wsB;
            return String(a.address).localeCompare(String(b.address));
        });

        // Only replace the array when window membership/workspace order actually changes
        // so focus or title changes update cards in-place without flickering ScreencopyView.
        const prev = root.sortedToplevels;
        if (prev.length === list.length) {
            let same = true;
            for (let i = 0; i < list.length; i++) {
                const pa = prev[i];
                const pb = list[i];
                const wa = pa && pa.workspace ? pa.workspace.id : -1;
                const wb = pb && pb.workspace ? pb.workspace.id : -1;
                if (pa !== pb || wa !== wb) {
                    same = false;
                    break;
                }
            }
            if (same) return;
        }
        root.sortedToplevels = list;
    }

    onPanelVisibleChanged: rebuildSortedToplevels()

    Connections {
        target: Hyprland.toplevels
        function onValuesChanged() {
            root.rebuildSortedToplevels();
        }
    }

    function openWithMode(targetMode) {
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
        root.mode = targetMode;
        root.searchQuery = "";
        root.selectedIndex = 0;
        root.panelVisible = true;
    }

    function closeOverview() {
        root.panelVisible = false;
        root.searchQuery = "";
    }

    function focusToplevel(toplevel) {
        if (!toplevel) return;
        const addr = toplevel.address
            ? (String(toplevel.address).startsWith("0x") ? toplevel.address : ("0x" + toplevel.address))
            : "";
        const wsObj = toplevel.workspace;
        closeOverview();
        if (wsObj && typeof wsObj.activate === "function") {
            wsObj.activate();
        }
        if (toplevel.wayland && typeof toplevel.wayland.activate === "function") {
            toplevel.wayland.activate();
        }
        if (addr !== "") {
            if (root.isLua) {
                Hyprland.dispatch('hl.dsp.focus({ window = "address:' + addr + '" })');
            } else {
                Hyprland.dispatch("focuswindow address:" + addr);
            }
        }
    }

    function closeToplevel(toplevel) {
        if (!toplevel) return;
        if (toplevel.wayland && typeof toplevel.wayland.close === "function") {
            toplevel.wayland.close();
            refreshTimer.restart();
            return;
        }
        if (toplevel.address) {
            const addr = String(toplevel.address).startsWith("0x")
                ? toplevel.address
                : ("0x" + toplevel.address);
            if (root.isLua) {
                Hyprland.dispatch('hl.dsp.window.close({ window = "address:' + addr + '" })');
            } else {
                Hyprland.dispatch("closewindow address:" + addr);
            }
            refreshTimer.restart();
        }
    }

    function switchWorkspace(wsId) {
        if (wsId <= 0) return;
        const wsObj = root.sortedWorkspaces.find(w => w && w.id === wsId);
        closeOverview();
        if (wsObj && typeof wsObj.activate === "function") {
            wsObj.activate();
            return;
        }
        Hyprland.dispatch("workspace " + wsId);
    }

    property int pendingMoveWsId: -1

    function moveToplevelToWorkspace(toplevel, wsId) {
        if (!toplevel || !toplevel.address || wsId <= 0) return;
        const addr = String(toplevel.address).startsWith("0x")
            ? toplevel.address
            : ("0x" + toplevel.address);
        if (root.isLua) {
            Hyprland.dispatch('hl.dsp.focus({ window = "address:' + addr + '" })');
            root.pendingMoveWsId = wsId;
            moveTimer.restart();
        } else {
            Hyprland.dispatch("movetoworkspacesilent " + wsId + ",address:" + addr);
            refreshTimer.restart();
        }
    }

    Timer {
        id: moveTimer
        interval: 40
        repeat: false
        onTriggered: {
            if (root.pendingMoveWsId > 0) {
                Hyprland.dispatch("hl.dsp.window.move({ workspace = " + root.pendingMoveWsId + ", silent = true })");
                root.pendingMoveWsId = -1;
            }
            refreshTimer.restart();
        }
    }

    Timer {
        id: refreshTimer
        interval: 120
        repeat: false
        onTriggered: {
            Hyprland.refreshToplevels();
            Hyprland.refreshWorkspaces();
        }
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            if (root.panelVisible && root.mode === "workspaces") {
                root.closeOverview();
            } else {
                root.openWithMode("workspaces");
            }
        }

        function switcher() {
            if (root.panelVisible && root.mode === "switcher") {
                if (root.sortedToplevels.length > 0) {
                    root.selectedIndex = (root.selectedIndex + 1) % root.sortedToplevels.length;
                }
            } else {
                root.openWithMode("switcher");
                if (root.sortedToplevels.length > 1) {
                    root.selectedIndex = 1;
                }
            }
        }

        function close() {
            root.closeOverview();
        }
    }

    Loader {
        active: root.panelVisible
        sourceComponent: OverviewOverlay {
            theme: root.theme || Theme
            font: root.font
            mode: root.mode
            toplevels: root.sortedToplevels
            workspaces: root.sortedWorkspaces
            selectedIndex: Math.min(root.selectedIndex, Math.max(0, root.sortedToplevels.length - 1))
            searchQuery: root.searchQuery

            onModeChangedByUser: (nextMode) => { root.mode = nextMode; }
            onSearchQueryChangedByUser: (q) => { root.searchQuery = q; }
            onSelectionChanged: (idx) => { root.selectedIndex = idx; }
            onWindowFocused: (t) => root.focusToplevel(t)
            onWindowClosed: (t) => root.closeToplevel(t)
            onWindowMoved: (t, wsId) => root.moveToplevelToWorkspace(t, wsId)
            onWorkspaceSwitched: (wsId) => root.switchWorkspace(wsId)
            onCloseRequested: root.closeOverview()
        }
    }
}
