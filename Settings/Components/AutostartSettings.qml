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

    /* Toast notification */
    property string toastMessage: ""
    property bool toastVisible: false

    Timer {
        id: toastTimer
        interval: 2500
        repeat: false
        onTriggered: root.toastVisible = false
    }

    function showToast(msg) {
        root.toastMessage = msg;
        root.toastVisible = true;
        toastTimer.restart();
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

    // -------------------------------------------------------------------------
    // Main UI Layout
    // -------------------------------------------------------------------------
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
                color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.15)
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
                    font.pixelSize: 20
                    font.bold: true
                    color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                }

                Text {
                    text: "Manage desktop applications, background daemons, and Hyprland launch processes"
                    font.family: root.font
                    font.pixelSize: 12
                    color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
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

            /* Sub-Tab Navigation Bar (Underline indicator matching HyprlandSettings) */
            Rectangle {
                id: subTabTrack
                Layout.fillWidth: true
                height: 40
                radius: 10
                color: (root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.04)
                border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Repeater {
                        model: [
                            { idx: 0, label: "Applications (" + root.appsList.length + ")", icon: "󰵆" },
                            { idx: 1, label: "Startup Commands (" + root.hyprCommands.length + ")", icon: "" },
                            { idx: 2, label: "Environment Variables (" + root.envsList.length + ")", icon: "󰒲" }
                        ]

                        delegate: Rectangle {
                            id: subTabItem
                            required property var modelData
                            readonly property bool isCurrent: root.currentSubTab === modelData.idx

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                            border.width: 0

                            HoverHandler { id: subTabHover }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 2
                                radius: 1
                                width: subTabItem.isCurrent
                                    ? subTabRow.implicitWidth + 16
                                    : (subTabHover.hovered ? (subTabRow.implicitWidth + 16) * 0.5 : 0)
                                opacity: subTabItem.isCurrent ? 1.0 : (subTabHover.hovered ? 0.5 : 0.0)
                                color: subTabItem.isCurrent
                                    ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                    : ((root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0")

                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 160 } }
                                Behavior on color { ColorAnimation { duration: 160 } }
                            }

                            Row {
                                id: subTabRow
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    width: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: subTabItem.modelData.icon
                                    font.family: root.font
                                    font.pixelSize: 13
                                    color: subTabItem.isCurrent
                                        ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                        : (subTabHover.hovered
                                            ? ((root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff")
                                            : ((root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"))
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: subTabItem.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: subTabItem.isCurrent
                                    color: subTabItem.isCurrent
                                        ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                        : (subTabHover.hovered
                                            ? ((root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff")
                                            : ((root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"))
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.currentSubTab !== subTabItem.modelData.idx) {
                                        root.currentSubTab = subTabItem.modelData.idx;
                                        subTabContentAnim.restart();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* Sub-Tab Dynamic Animated Container */
            ColumnLayout {
                id: subTabContentContainer
                Layout.fillWidth: true
                spacing: 16
                transform: Translate { id: subTabContentTranslate; y: 0 }

            // =====================================================================
            // SUB-TAB 0: APPLICATIONS (XDG AUTOSTART)
            // =====================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14
                visible: root.currentSubTab === 0

                // Search & Filter Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Search Input Box
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 7
                        color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                        border.color: appSearchInput.activeFocus
                            ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                            : ((root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08))
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: "󰍉"
                                font.family: root.font
                                font.pixelSize: 13
                                color: appSearchInput.activeFocus
                                    ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                    : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060")
                            }

                            TextInput {
                                id: appSearchInput
                                Layout.fillWidth: true
                                font.family: root.font
                                font.pixelSize: 12
                                color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                                clip: true
                                selectByMouse: true
                                text: root.appSearchQuery
                                onTextChanged: root.appSearchQuery = text

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !parent.text && !parent.activeFocus
                                    text: "Filter startup applications..."
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060"
                                }
                            }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                color: clearAppSearchHover.hovered ? ((root.theme && root.theme.bgHover) ? root.theme.bgHover : Qt.rgba(1, 1, 1, 0.1)) : "transparent"
                                visible: appSearchInput.text.length > 0

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                                }

                                HoverHandler { id: clearAppSearchHover }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: appSearchInput.text = ""
                                }
                            }
                        }
                    }

                    // Filter Segmented Track
                    Rectangle {
                        id: appFilterSeg
                        implicitWidth: 260
                        height: 36
                        radius: 7
                        color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                        border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        readonly property var modes: ["all", "enabled", "disabled"]
                        readonly property int activeIdx: Math.max(0, modes.indexOf(root.appFilterMode))
                        readonly property real cellWidth: (width - 6 - 2 * 3) / 3

                        Rectangle {
                            y: 3
                            height: parent.height - 6
                            width: appFilterSeg.cellWidth
                            x: 3 + appFilterSeg.activeIdx * (appFilterSeg.cellWidth + 3)
                            radius: 5
                            color: (root.theme && root.theme.bgSelected) ? root.theme.bgSelected : Qt.rgba(1, 1, 1, 0.15)
                            border.color: (root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7"
                            border.width: 1
                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Repeater {
                                model: [
                                    { id: "all",      label: "All (" + root.appsList.length + ")" },
                                    { id: "enabled",  label: "Active (" + root.enabledAppsCount + ")" },
                                    { id: "disabled", label: "Off (" + (root.appsList.length - root.enabledAppsCount) + ")" }
                                ]
                                delegate: Rectangle {
                                    id: fBtn
                                    required property var modelData
                                    required property int index
                                    readonly property bool isSel: appFilterSeg.activeIdx === index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isSel && fHover.hovered ? ((root.theme && root.theme.bgHover) ? root.theme.bgHover : Qt.rgba(1, 1, 1, 0.08)) : "transparent"

                                    HoverHandler { id: fHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.appFilterMode = fBtn.modelData.id
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: fBtn.modelData.label
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: fBtn.isSel
                                        color: fBtn.isSel
                                            ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                            : ((root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff")
                                        opacity: fBtn.isSel || fHover.hovered ? 1.0 : 0.75
                                    }
                                }
                            }
                        }
                    }

                    // Add Application Button
                    ActionButton {
                        label: "Add Application"
                        iconText: "󰐕"
                        btnHeight: 36
                        onClicked: {
                            root.addAppQuery = "";
                            root.addAppModalOpen = true;
                        }
                    }
                }

                // Applications List View Box
                Rectangle {
                    Layout.fillWidth: true
                    height: 440
                    radius: 8
                    color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.2)
                    border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    clip: true

                    ListView {
                        id: appsListView
                        anchors.fill: parent
                        anchors.margins: 8
                        model: root.filteredApps
                        spacing: 6
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.15)
                            }
                        }

                        // Empty State
                        Item {
                            anchors.centerIn: parent
                            visible: appsListView.count === 0
                            width: 280
                            height: 120

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "󰵆"
                                    font.family: root.font
                                    font.pixelSize: 32
                                    color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060"
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.appSearchQuery ? "No matching startup applications" : "No startup applications configured"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                                }
                            }
                        }

                        delegate: Rectangle {
                            id: appItemRow
                            required property var modelData

                            width: appsListView.width - 8
                            height: 58
                            radius: 6
                            color: appItemHover.hovered ? ((root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.05)) : "transparent"
                            border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            HoverHandler { id: appItemHover }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                // Icon Box
                                Rectangle {
                                    id: appIconBox
                                    width: 36
                                    height: 36
                                    radius: 7
                                    color: (root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.08)
                                    border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    readonly property string resolvedIcon: {
                                        const raw = (appItemRow.modelData && appItemRow.modelData.icon) ? appItemRow.modelData.icon : "";
                                        if (raw) {
                                            const p = Quickshell.iconPath(raw, true);
                                            if (p) return p;
                                        }
                                        return Quickshell.iconPath("application-x-executable", true);
                                    }

                                    IconImage {
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
                                        source: appIconBox.resolvedIcon
                                        visible: appIconBox.resolvedIcon !== ""
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰵆"
                                        font.family: root.font
                                        font.pixelSize: 18
                                        color: (root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7"
                                        visible: appIconBox.resolvedIcon === ""
                                    }
                                }

                                // Application Info
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            text: appItemRow.modelData.name || "Unknown Application"
                                            font.family: root.font
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: appItemRow.modelData.enabled
                                                ? ((root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff")
                                                : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#707070")
                                        }

                                        // Scope badge
                                        Rectangle {
                                            implicitWidth: scopeText.implicitWidth + 10
                                            implicitHeight: 18
                                            radius: 4
                                            color: appItemRow.modelData.scope === "user"
                                                ? Qt.rgba(0.4, 0.7, 1.0, 0.15)
                                                : Qt.rgba(0.5, 0.5, 0.5, 0.15)

                                            Text {
                                                id: scopeText
                                                anchors.centerIn: parent
                                                text: appItemRow.modelData.scope === "user" ? "User" : "System"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: appItemRow.modelData.scope === "user"
                                                    ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                                    : ((root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0")
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: appItemRow.modelData.comment || appItemRow.modelData.exec || ""
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#707070"
                                        elide: Text.ElideRight
                                    }
                                }

                                // Actions
                                RowLayout {
                                    spacing: 12
                                    Layout.alignment: Qt.AlignVCenter

                                    // Delete user app button
                                    Rectangle {
                                        visible: appItemRow.modelData.scope === "user"
                                        width: 28
                                        height: 28
                                        radius: 6
                                        color: delAppHover.hovered ? Qt.rgba(1, 0.3, 0.3, 0.2) : "transparent"
                                        border.color: delAppHover.hovered ? ((root.theme && root.theme.accentRed) ? root.theme.accentRed : "#f7768e") : "transparent"
                                        border.width: 1

                                        HoverHandler { id: delAppHover }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.deleteApp(appItemRow.modelData.id, appItemRow.modelData.name)
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰆴"
                                            font.family: root.font
                                            font.pixelSize: 14
                                            color: delAppHover.hovered
                                                ? ((root.theme && root.theme.accentRed) ? root.theme.accentRed : "#f7768e")
                                                : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#707070")
                                        }
                                    }

                                    // Switch Toggle
                                    SwitchToggle {
                                        checked: appItemRow.modelData.enabled
                                        onToggled: function(newState) {
                                            root.toggleApp(appItemRow.modelData.id, newState);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =====================================================================
            // SUB-TAB 1: HYPRLAND STARTUP COMMANDS (AutoStart.lua)
            // =====================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14
                visible: root.currentSubTab === 1

                // Top Toolbar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Search input
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 7
                        color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                        border.color: cmdSearchInput.activeFocus
                            ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                            : ((root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08))
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: "󰍉"
                                font.family: root.font
                                font.pixelSize: 13
                                color: cmdSearchInput.activeFocus
                                    ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                    : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060")
                            }

                            TextInput {
                                id: cmdSearchInput
                                Layout.fillWidth: true
                                font.family: root.font
                                font.pixelSize: 12
                                color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                                clip: true
                                selectByMouse: true
                                text: root.cmdSearchQuery
                                onTextChanged: root.cmdSearchQuery = text

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !parent.text && !parent.activeFocus
                                    text: "Filter startup commands or daemons..."
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060"
                                }
                            }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                color: clearCmdSearchHover.hovered ? ((root.theme && root.theme.bgHover) ? root.theme.bgHover : Qt.rgba(1, 1, 1, 0.1)) : "transparent"
                                visible: cmdSearchInput.text.length > 0

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                                }

                                HoverHandler { id: clearCmdSearchHover }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: cmdSearchInput.text = ""
                                }
                            }
                        }
                    }

                    // Add Custom Command Button
                    ActionButton {
                        label: "Add Command"
                        iconText: "󰐕"
                        btnHeight: 36
                        onClicked: {
                            root.newCmdName = "";
                            root.newCmdExec = "";
                            root.addCmdModalOpen = true;
                        }
                    }
                }

                // Hyprland Commands List View Box
                Rectangle {
                    Layout.fillWidth: true
                    height: 440
                    radius: 8
                    color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.2)
                    border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    clip: true

                    ListView {
                        id: cmdsListView
                        anchors.fill: parent
                        anchors.margins: 8
                        model: root.filteredCommands
                        spacing: 6
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.15)
                            }
                        }

                        delegate: Rectangle {
                            id: cmdItemRow
                            required property var modelData

                            width: cmdsListView.width - 8
                            height: 62
                            radius: 6
                            color: cmdHover.hovered ? ((root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.05)) : "transparent"
                            border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            HoverHandler { id: cmdHover }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                // Command Icon Box
                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 7
                                    color: (root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.08)
                                    border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: cmdItemRow.modelData.is_system ? "" : "󰆍"
                                        font.family: root.font
                                        font.pixelSize: 16
                                        color: cmdItemRow.modelData.is_system
                                            ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                            : ((root.theme && root.theme.accentCyan) ? root.theme.accentCyan : "#7dcfff")
                                    }
                                }

                                // Command Details
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            text: cmdItemRow.modelData.name
                                            font.family: root.font
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: cmdItemRow.modelData.enabled
                                                ? ((root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff")
                                                : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#707070")
                                        }

                                        // Source Badge
                                        Rectangle {
                                            implicitWidth: srcTxt.implicitWidth + 8
                                            implicitHeight: 18
                                            radius: 4
                                            color: cmdItemRow.modelData.is_system
                                                ? Qt.rgba(0.5, 0.5, 0.8, 0.15)
                                                : Qt.rgba(0.2, 0.8, 0.5, 0.15)

                                            Text {
                                                id: srcTxt
                                                anchors.centerIn: parent
                                                text: cmdItemRow.modelData.file
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: cmdItemRow.modelData.is_system
                                                    ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                                    : ((root.theme && root.theme.accentGreen) ? root.theme.accentGreen : "#9ece6a")
                                            }
                                        }
                                    }

                                    // Command string
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 22
                                        radius: 4
                                        color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.25)

                                        Text {
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            verticalAlignment: Text.AlignVCenter
                                            text: cmdItemRow.modelData.cmd
                                            font.family: "JetBrains Mono, monospace"
                                            font.pixelSize: 10
                                            color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                // Right Controls
                                RowLayout {
                                    spacing: 8
                                    Layout.alignment: Qt.AlignVCenter

                                    // Test Run Button
                                    Rectangle {
                                        width: 68
                                        height: 28
                                        radius: 6
                                        color: testBtnHover.hovered
                                            ? ((root.theme && root.theme.bgHover) ? root.theme.bgHover : Qt.rgba(1, 1, 1, 0.1))
                                            : ((root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.05))
                                        border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 1

                                        HoverHandler { id: testBtnHover }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.testRun(cmdItemRow.modelData.cmd)
                                        }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text {
                                                text: "󰐊"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                color: (root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7"
                                            }
                                            Text {
                                                text: "Test"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                                            }
                                        }
                                    }

                                    // Delete button (custom commands only)
                                    Rectangle {
                                        visible: !cmdItemRow.modelData.is_system
                                        width: 28
                                        height: 28
                                        radius: 6
                                        color: delCmdHover.hovered ? Qt.rgba(1, 0.3, 0.3, 0.2) : "transparent"
                                        border.color: delCmdHover.hovered ? ((root.theme && root.theme.accentRed) ? root.theme.accentRed : "#f7768e") : "transparent"
                                        border.width: 1

                                        HoverHandler { id: delCmdHover }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.deleteCustomCommand(cmdItemRow.modelData.id, cmdItemRow.modelData.name)
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰆴"
                                            font.family: root.font
                                            font.pixelSize: 14
                                            color: delCmdHover.hovered
                                                ? ((root.theme && root.theme.accentRed) ? root.theme.accentRed : "#f7768e")
                                                : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#707070")
                                        }
                                    }

                                    // Switch Toggle
                                    SwitchToggle {
                                        checked: cmdItemRow.modelData.enabled
                                        onToggled: function(newState) {
                                            root.toggleHyprCommand(cmdItemRow.modelData.id, newState, cmdItemRow.modelData.name);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =====================================================================
            // SUB-TAB 2: ENVIRONMENT VARIABLES
            // =====================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14
                visible: root.currentSubTab === 2

                // Search Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 7
                    color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                    border.color: envSearchInput.activeFocus
                        ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                        : ((root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.family: root.font
                            font.pixelSize: 13
                            color: envSearchInput.activeFocus
                                ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060")
                        }

                        TextInput {
                            id: envSearchInput
                            Layout.fillWidth: true
                            font.family: root.font
                            font.pixelSize: 12
                            color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                            clip: true
                            selectByMouse: true
                            text: root.envSearchQuery
                            onTextChanged: root.envSearchQuery = text

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !parent.text && !parent.activeFocus
                                text: "Filter environment variables..."
                                font.family: root.font
                                font.pixelSize: 12
                                color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060"
                            }
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: clearEnvSearchHover.hovered ? ((root.theme && root.theme.bgHover) ? root.theme.bgHover : Qt.rgba(1, 1, 1, 0.1)) : "transparent"
                            visible: envSearchInput.text.length > 0

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.family: root.font
                                font.pixelSize: 11
                                color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                            }

                            HoverHandler { id: clearEnvSearchHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: envSearchInput.text = ""
                            }
                        }
                    }
                }

                // Environment Variables Table Card Box
                Rectangle {
                    Layout.fillWidth: true
                    height: 440
                    radius: 8
                    color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.2)
                    border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    clip: true

                    ListView {
                        id: envListView
                        anchors.fill: parent
                        anchors.margins: 8
                        model: root.filteredEnvs
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.15)
                            }
                        }

                        delegate: Rectangle {
                            id: envRow
                            required property var modelData

                            width: envListView.width - 8
                            height: 42
                            radius: 6
                            color: envHover.hovered ? ((root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.05)) : "transparent"
                            border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1

                            HoverHandler { id: envHover }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    Layout.preferredWidth: 260
                                    text: envRow.modelData.key
                                    font.family: "JetBrains Mono, monospace"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: (root.theme && root.theme.accentCyan) ? root.theme.accentCyan : "#7dcfff"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "="
                                    font.family: "JetBrains Mono, monospace"
                                    font.pixelSize: 12
                                    color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#707070"
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: envRow.modelData.value
                                    font.family: "JetBrains Mono, monospace"
                                    font.pixelSize: 12
                                    color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
            }
        }
    }

    // =========================================================================
    // MODAL: ADD INSTALLED APPLICATION
    // =========================================================================
    Rectangle {
        id: addAppModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        visible: root.addAppModalOpen
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 160 } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.addAppModalOpen = false
        }

        Rectangle {
            width: 500
            height: 520
            radius: 12
            color: (root.theme && root.theme.bgSurface) ? root.theme.bgSurface : "#1e1e2e"
            border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
            anchors.centerIn: parent

            MouseArea {
                anchors.fill: parent
                // absorb clicks inside modal dialog
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Modal Header
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Add Application to Autostart"
                            font.family: root.font
                            font.pixelSize: 16
                            font.bold: true
                            color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                        }

                        Text {
                            text: "Choose an installed desktop application to launch on login"
                            font.family: root.font
                            font.pixelSize: 11
                            color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                        }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: closeAddHover.hovered ? ((root.theme && root.theme.bgHover) ? root.theme.bgHover : Qt.rgba(1, 1, 1, 0.1)) : "transparent"

                        HoverHandler { id: closeAddHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.addAppModalOpen = false
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.family: root.font
                            font.pixelSize: 12
                            color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                        }
                    }
                }

                // Search box
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 7
                    color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                    border.color: addSearchInput.activeFocus
                        ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                        : ((root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "󰍉"
                            font.family: root.font
                            font.pixelSize: 13
                            color: addSearchInput.activeFocus
                                ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                : ((root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060")
                        }

                        TextInput {
                            id: addSearchInput
                            Layout.fillWidth: true
                            font.family: root.font
                            font.pixelSize: 12
                            color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                            clip: true
                            selectByMouse: true
                            text: root.addAppQuery
                            onTextChanged: root.addAppQuery = text

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !parent.text && !parent.activeFocus
                                text: "Search applications..."
                                font.family: root.font
                                font.pixelSize: 12
                                color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060"
                            }
                        }
                    }
                }

                // Applications List View Box
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.25)
                    border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    clip: true

                    ListView {
                        id: modalAppList
                        anchors.fill: parent
                        anchors.margins: 6
                        model: root.filteredAvailableApps
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.15)
                            }
                        }

                        delegate: Rectangle {
                            id: mAppRow
                            required property var modelData

                            width: modalAppList.width - 8
                            height: 48
                            radius: 6
                            color: mAppHover.hovered ? ((root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.08)) : "transparent"

                            HoverHandler { id: mAppHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const app = mAppRow.modelData;
                                    root.addApp(app.name || "App", app.exec || "", app.icon || "", app.comment || "");
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 10

                                // App Icon
                                Rectangle {
                                    id: mIconBox
                                    width: 30
                                    height: 30
                                    radius: 6
                                    color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.2)
                                    border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.06)
                                    border.width: 1

                                    readonly property string resIcon: {
                                        const raw = (mAppRow.modelData && mAppRow.modelData.icon) ? mAppRow.modelData.icon : "";
                                        if (raw) {
                                            const p = Quickshell.iconPath(raw, true);
                                            if (p) return p;
                                        }
                                        return Quickshell.iconPath("application-x-executable", true);
                                    }

                                    IconImage {
                                        anchors.centerIn: parent
                                        width: 20
                                        height: 20
                                        source: mIconBox.resIcon
                                        visible: mIconBox.resIcon !== ""
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰵆"
                                        font.family: root.font
                                        font.pixelSize: 14
                                        color: (root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7"
                                        visible: mIconBox.resIcon === ""
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: mAppRow.modelData.name || "Unknown App"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: mAppRow.modelData.comment || mAppRow.modelData.exec || ""
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#707070"
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    text: "󰐕 Add"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: mAppHover.hovered
                                        ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                                        : ((root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // MODAL: ADD HYPRLAND STARTUP COMMAND
    // =========================================================================
    Rectangle {
        id: addCmdModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        visible: root.addCmdModalOpen
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 160 } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.addCmdModalOpen = false
        }

        Rectangle {
            width: 460
            height: 270
            radius: 12
            color: (root.theme && root.theme.bgSurface) ? root.theme.bgSurface : "#1e1e2e"
            border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
            anchors.centerIn: parent

            MouseArea {
                anchors.fill: parent
                // absorb clicks inside dialog
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Add Startup Command"
                            font.family: root.font
                            font.pixelSize: 16
                            font.bold: true
                            color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                        }

                        Text {
                            text: "Runs automatically via hl.exec_cmd() when Hyprland starts"
                            font.family: root.font
                            font.pixelSize: 11
                            color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                        }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: closeCmdHover.hovered ? ((root.theme && root.theme.bgHover) ? root.theme.bgHover : Qt.rgba(1, 1, 1, 0.1)) : "transparent"

                        HoverHandler { id: closeCmdHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.addCmdModalOpen = false
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.family: root.font
                            font.pixelSize: 12
                            color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                        }
                    }
                }

                // Name Input
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Command Name / Description"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 6
                        color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                        border.color: nameInput.activeFocus
                            ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                            : ((root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08))
                        border.width: 1

                        TextInput {
                            id: nameInput
                            anchors.fill: parent
                            anchors.margins: 8
                            font.family: root.font
                            font.pixelSize: 12
                            color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                            clip: true
                            selectByMouse: true
                            text: root.newCmdName
                            onTextChanged: root.newCmdName = text

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !parent.text && !parent.activeFocus
                                text: "e.g. Discord in Background"
                                font.family: root.font
                                font.pixelSize: 12
                                color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060"
                            }
                        }
                    }
                }

                // Exec Command Input
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Executable Command Line"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: (root.theme && root.theme.textSecondary) ? root.theme.textSecondary : "#a0a0a0"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 6
                        color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                        border.color: execInput.activeFocus
                            ? ((root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7")
                            : ((root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08))
                        border.width: 1

                        TextInput {
                            id: execInput
                            anchors.fill: parent
                            anchors.margins: 8
                            font.family: "JetBrains Mono, monospace"
                            font.pixelSize: 11
                            color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
                            clip: true
                            selectByMouse: true
                            text: root.newCmdExec
                            onTextChanged: root.newCmdExec = text

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !parent.text && !parent.activeFocus
                                text: "e.g. discord --start-minimized"
                                font.family: "JetBrains Mono, monospace"
                                font.pixelSize: 11
                                color: (root.theme && root.theme.textMuted) ? root.theme.textMuted : "#606060"
                            }
                        }
                    }
                }

                // Dialog Buttons
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    spacing: 8

                    ActionButton {
                        label: "Cancel"
                        btnHeight: 32
                        onClicked: root.addCmdModalOpen = false
                    }

                    ActionButton {
                        label: "Save Command"
                        iconText: "󰄬"
                        btnHeight: 32
                        btnEnabled: root.newCmdName.trim().length > 0 && root.newCmdExec.trim().length > 0
                        onClicked: root.addCustomCommand(root.newCmdName, root.newCmdExec)
                    }
                }
            }
        }
    }

    // =========================================================================
    // FLOATING TOAST
    // =========================================================================
    Rectangle {
        id: toastPill
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: toastText.implicitWidth + 32
        height: 36
        radius: 18
        color: (root.theme && root.theme.bgSurface) ? root.theme.bgSurface : "#1e1e2e"
        border.color: (root.theme && root.theme.accentPrimary) ? root.theme.accentPrimary : "#7aa2f7"
        border.width: 1
        opacity: root.toastVisible ? 1.0 : 0.0
        scale: root.toastVisible ? 1.0 : 0.95
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.centerIn: parent
            Text {
                id: toastText
                text: root.toastMessage
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: (root.theme && root.theme.textPrimary) ? root.theme.textPrimary : "#ffffff"
            }
        }
    }
}
