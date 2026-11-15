import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "../ThemeSwitcher" as TS
import "Components"

Scope {
    id: root

    TS.DefaultTheme { id: defaultTheme }
    property var theme: defaultTheme
    property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"

    property bool panelVisible: false
    property string mode: "workspaces" // "switcher" | "workspaces"
    property int selectedIndex: 0
    property string searchQuery: ""

    readonly property var sortedWorkspaces: {
        if (!root.panelVisible) return [];
        return [...Hyprland.workspaces.values]
            .filter(w => w && w.id > 0)
            .sort((a, b) => a.id - b.id);
    }

    readonly property var sortedToplevels: {
        if (!root.panelVisible) return [];
        const list = [...Hyprland.toplevels.values].filter(t => t && t.address);
        return list.sort((a, b) => {
            const wsA = a.workspace ? a.workspace.id : 999;
            const wsB = b.workspace ? b.workspace.id : 999;
            if (wsA !== wsB) return wsA - wsB;
            if (a.activated !== b.activated) return a.activated ? -1 : 1;
            return (a.title || "").localeCompare(b.title || "");
        });
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
        if (addr !== "") {
            Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + addr]);
        } else if (toplevel.wayland && typeof toplevel.wayland.activate === "function") {
            toplevel.wayland.activate();
        }
    }

    function closeToplevel(toplevel) {
        if (!toplevel) return;
        if (toplevel.address) {
            const addr = String(toplevel.address).startsWith("0x")
                ? toplevel.address
                : ("0x" + toplevel.address);
            Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "address:" + addr]);
        } else if (toplevel.wayland && typeof toplevel.wayland.close === "function") {
            toplevel.wayland.close();
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
            theme: root.theme || defaultTheme
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
            onWorkspaceSwitched: (wsId) => root.switchWorkspace(wsId)
            onCloseRequested: root.closeOverview()
        }
    }
}
