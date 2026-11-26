/*
 * AutostartSettings.qml
 *
 * Comprehensive Autostart Applications & Startup Services Manager for Quickshell Settings.
 * Supports:
 *   - Freedesktop XDG autostart applications (~/.config/autostart & /etc/xdg/autostart)
 *   - Hyprland launch commands & daemons (~/.config/hypr/Configs/AutoStart.lua & custom_autostart.lua)
 *   - Session and Wayland environment variables from AutoStart.lua
 *   - Interactive "+ Add Application" modal from installed system applications
 *   - "+ Add Custom Command" dialog with immediate test-run capability
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "Common"

import "./Autostart"
import "./Common"
Item {
    id: root

    property var theme
    property string font: "Lato Nerd Font"

    /* Sub-tabs: 0: Applications, 1: Startup Commands, 2: Environment Variables */
    property int currentSubTab: 0

    /* Loading state & data arrays */
    property bool isLoading: true
    property var appsList: []
    property var hyprCommands: []
    property var envsList: []

    /* Search & Filter states */
    property string appSearchQuery: ""
    property string appFilterMode: "all" // "all", "enabled", "disabled"
    property string cmdSearchQuery: ""
    property string envSearchQuery: ""

    /* Modals state */
    property bool addAppModalOpen: false
    property bool addCmdModalOpen: false
    property string addAppQuery: ""
    property string newCmdName: ""
    property string newCmdExec: ""

    function showToast(msg, isWarn) {
        Style.notify(msg, isWarn);
    }

    readonly property string scriptPath: Qt.resolvedUrl("../scripts/manage_autostart.py").toString().replace(/^file:\/\//, "")

    /* Process runner for fetching autostart state */
    Process {
        id: listProc
        command: ["python3", root.scriptPath, "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.isLoading = false;
                try {
                    const data = JSON.parse(text);
                    if (data.success) {
                        root.appsList = data.apps || [];
                        root.hyprCommands = data.hypr_commands || [];
                        root.envsList = data.envs || [];
                    }
                } catch(e) {
                    console.error("Failed to parse autostart list:", e);
                }
            }
        }
    }

    function reload() {
        if (!listProc.running) {
            listProc.running = true;
        }
    }

    Component.onCompleted: {
        root.reload();
    }

    /* Process runner for mutations */
    Process {
        id: actionProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.reload();
            }
        }
    }

    function toggleApp(appId, enabled) {
        actionProc.command = ["python3", root.scriptPath, "toggle_app", appId, enabled ? "true" : "false"];
        actionProc.running = true;
        root.showToast(enabled ? "Application enabled on startup" : "Application disabled on startup");
    }

    function addApp(name, execCmd, icon, comment) {
        actionProc.command = ["python3", root.scriptPath, "add_app", name, execCmd, icon || "", comment || ""];
        actionProc.running = true;
        root.addAppModalOpen = false;
        root.showToast("Added '" + name + "' to autostart");
    }

    function deleteApp(appId, name) {
        actionProc.command = ["python3", root.scriptPath, "delete_app", appId];
        actionProc.running = true;
        root.showToast("Removed '" + name + "' from startup applications");
    }

    function toggleHyprCommand(cmdId, enabled, name) {
        actionProc.command = ["python3", root.scriptPath, "toggle_hypr_cmd", cmdId, enabled ? "true" : "false"];
        actionProc.running = true;
        root.showToast((enabled ? "Enabled " : "Disabled ") + name);
    }

    function addCustomCommand(name, execCmd) {
        if (!name.trim() || !execCmd.trim()) return;
        actionProc.command = ["python3", root.scriptPath, "add_hypr_cmd", name.trim(), execCmd.trim()];
        actionProc.running = true;
        root.addCmdModalOpen = false;
        root.newCmdName = "";
        root.newCmdExec = "";
        root.showToast("Added startup command '" + name.trim() + "'");
    }

    function deleteCustomCommand(cmdId, name) {
        actionProc.command = ["python3", root.scriptPath, "delete_hypr_cmd", cmdId];
        actionProc.running = true;
        root.showToast("Deleted startup command '" + name + "'");
    }

    function testRun(execCmd) {
        actionProc.command = ["python3", root.scriptPath, "test_run", execCmd];
        actionProc.running = true;
        root.showToast("Testing '" + execCmd + "' in background...");
    }

    /* Filtered lists */
    readonly property var filteredApps: {
        const q = root.appSearchQuery.toLowerCase().trim();
        const mode = root.appFilterMode;
        return (root.appsList || []).filter(a => {
            if (mode === "enabled" && !a.enabled) return false;
            if (mode === "disabled" && a.enabled) return false;
            if (!q) return true;
            return (a.name || "").toLowerCase().includes(q) ||
                   (a.exec || "").toLowerCase().includes(q) ||
                   (a.comment || "").toLowerCase().includes(q);
        });
    }

    readonly property var filteredCommands: {
        const q = root.cmdSearchQuery.toLowerCase().trim();
        return (root.hyprCommands || []).filter(c => {
            if (!q) return true;
            return (c.name || "").toLowerCase().includes(q) ||
                   (c.cmd || "").toLowerCase().includes(q);
        });
    }

    readonly property var filteredEnvs: {
        const q = root.envSearchQuery.toLowerCase().trim();
        return (root.envsList || []).filter(e => {
            if (!q) return true;
            return (e.key || "").toLowerCase().includes(q) ||
                   (e.value || "").toLowerCase().includes(q);
        });
    }

    readonly property int enabledAppsCount: {
        let c = 0;
        for (let i = 0; i < root.appsList.length; i++) {
            if (root.appsList[i].enabled) c++;
        }
        return c;
    }

    readonly property int enabledCmdsCount: {
        let c = 0;
        for (let i = 0; i < root.hyprCommands.length; i++) {
            if (root.hyprCommands[i].enabled) c++;
        }
        return c;
    }

    // Installed system applications list for the Add Modal
    readonly property var allInstalledApps: {
        try {
            const list = [...DesktopEntries.applications.values];
            return list.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        } catch(e) {
            return [];
        }
    }

    readonly property var filteredAvailableApps: {
        const q = root.addAppQuery.toLowerCase().trim();
        return (root.allInstalledApps || []).filter(app => {
            if (!q) return true;
            return (app.name || "").toLowerCase().includes(q) ||
                   (app.genericName || "").toLowerCase().includes(q) ||
                   (app.comment || "").toLowerCase().includes(q);
        });
    }

    // Main UI Layout
    Flickable {
        id: mainScroll
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: vertScroll
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder
            }
        }

        ColumnLayout {
            id: mainCol
            width: mainScroll.width - (vertScroll.visible ? 12 : 0)
            spacing: 20

            // Header Section
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                Text {
                    text: "Autostart Applications & Daemons"
                    font.family: root.font
                    font.pixelSize: Style.px(20)
                    font.bold: true
                    color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                }
            }

            /* Sub-Tab Switch Transition Animation (Matching HyprlandSettings) */
            ParallelAnimation {
                id: subTabContentAnim
                NumberAnimation {
                    target: subTabContentContainer
                    property: "opacity"
                    from: 0.35
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: subTabContentTranslate
                    property: "y"
                    from: 8
                    to: 0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            /* Sub-Tab Navigation Bar */
            SubTabBar {
                currentIndex: root.currentSubTab
                tabs: [
                    { idx: 0, label: "Applications (" + root.appsList.length + ")", icon: "󰵆" },
                    { idx: 1, label: "Startup Commands (" + root.hyprCommands.length + ")", icon: "" },
                    { idx: 2, label: "Environment Variables (" + root.envsList.length + ")", icon: "󰒲" }
                ]
                onTabSelected: (idx) => {
                    root.currentSubTab = idx;
                    subTabContentAnim.restart();
                }
            }

            /* Sub-Tab Dynamic Animated Container */
            ColumnLayout {
                id: subTabContentContainer
                Layout.fillWidth: true
                spacing: 16
                transform: Translate { id: subTabContentTranslate; y: 0 }

            AutostartAppsTab { root: root }
            AutostartCommandsTab { root: root }
            AutostartEnvTab { root: root }
            }
        }
    }

    AutostartAddAppModal { root: root }
    AutostartAddCmdModal { root: root }

    // FLOATING TOAST
}
