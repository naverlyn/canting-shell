/*
 * BackupRestoreSettings.qml
 *
 * Dedicated Settings page for Quickshell configuration backup and restoration.
 * Provides 1-click quick snapshots, custom selective backups (Bar, Notifications,
 * OSD, Control Center, Appearance, Wallpaper), instant zero-risk restore with
 * automatic pre-restore safety backups, export/import, and factory defaults.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Common"

Item {
    id: root
    property var theme
    property string font

    property var snapshots: []
    property bool loading: false
    property string activeFilter: "all" // "all" | "manual" | "safety"
    property bool showCustomForm: false
    property bool showImportForm: false
    property string selectedRestoreSnapshotId: ""
    property string confirmDeleteId: ""

    // Form state
    property string formBackupName: ""
    property string formBackupDesc: ""
    property bool formIncBar: true
    property bool formIncNotif: true
    property bool formIncOsd: true
    property bool formIncCc: true
    property bool formIncTheme: true
    property bool formIncWallpaper: true

    property string importFilePath: ""

    // Toast feedback state
    property string statusMessage: ""
    property bool statusVisible: false
    property bool statusIsWarning: false

    readonly property string scriptPath: Qt.resolvedUrl("../scripts/manage_backup.py").toString().replace(/^file:\/\//, "")

    Timer {
        id: toastTimer
        interval: 3200
        repeat: false
        onTriggered: root.statusVisible = false
    }

    function showToast(msg, isWarn) {
        root.statusMessage = msg;
        root.statusIsWarning = Boolean(isWarn);
        root.statusVisible = true;
        toastTimer.restart();
    }

    // Process to run backup CLI commands
    Process {
        id: backupProc
        command: []
        running: false
        property string action: ""

        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                const raw = text.trim();
                if (!raw) return;
                try {
                    const res = JSON.parse(raw);
                    if (backupProc.action === "list") {
                        if (Array.isArray(res)) {
                            root.snapshots = res;
                        }
                    } else {
                        if (res.message) {
                            root.showToast(res.message, !res.success);
                        }
                        // Refresh snapshot list after any modification
                        root.refreshSnapshots();
                    }
                } catch(e) {
                    console.error("Backup JSON parse error:", e, raw);
                }
            }
        }
    }

    function runBackupCommand(args, actionName) {
        if (backupProc.running) return;
        root.loading = true;
        backupProc.action = actionName || "";
        backupProc.command = ["python3", root.scriptPath].concat(args);
        backupProc.running = true;
    }

    function refreshSnapshots() {
        runBackupCommand(["list"], "list");
    }

    function createQuickSnapshot() {
        runBackupCommand(["create", "", "all"], "create");
    }

    function submitCustomBackup() {
        let mods = [];
        if (formIncBar) mods.push("bar");
        if (formIncNotif) mods.push("notifications");
        if (formIncOsd) mods.push("osd");
        if (formIncCc) mods.push("controlcenter");
        if (formIncTheme) mods.push("appearance");
        if (formIncWallpaper) mods.push("wallpaper");

        if (mods.length === 0) {
            root.showToast("Please select at least one component to back up.", true);
            return;
        }

        const name = root.formBackupName.trim();
        const desc = root.formBackupDesc.trim();
        runBackupCommand(["create", name, mods.join(","), desc], "create");
        root.showCustomForm = false;
        root.formBackupName = "";
        root.formBackupDesc = "";
    }

    function restoreSnapshot(snapId, modulesCsv) {
        runBackupCommand(["restore", snapId, modulesCsv || "all"], "restore");
        root.selectedRestoreSnapshotId = "";
    }

    function deleteSnapshot(snapId) {
        runBackupCommand(["delete", snapId], "delete");
        root.confirmDeleteId = "";
    }

    function exportSnapshot(snapId) {
        runBackupCommand(["export", snapId], "export");
    }

    function submitImport() {
        const path = root.importFilePath.trim();
        if (!path) {
            root.showToast("Please enter a valid archive path.", true);
            return;
        }
        runBackupCommand(["import", path], "import");
        root.showImportForm = false;
        root.importFilePath = "";
    }

    function resetFactoryDefaults(modulesCsv) {
        runBackupCommand(["reset_defaults", modulesCsv || "all"], "reset_defaults");
    }

    Component.onCompleted: {
        root.refreshSnapshots();
    }

    /* Main Scrollable Layout */
    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15)
            }
        }

        ColumnLayout {
            id: mainCol
            width: parent.width - 10
            spacing: 16

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    spacing: 3
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8
                        Text {
                            text: "Backup & Restore"
                            font.family: root.font
                            font.pixelSize: 20
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                        Rectangle {
                            height: 20
                            implicitWidth: snapCountText.implicitWidth + 12
                            radius: 10
                            color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.15)
                            border.color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.3)
                            border.width: 1
                            Text {
                                id: snapCountText
                                anchors.centerIn: parent
                                text: root.snapshots.length + " saved"
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: root.theme.accentPrimary ?? "#7aa2f7"
                            }
                        }
                    }

                    Text {
                        text: "Manage snapshots, create backups, and restore configuration settings for Bar, Notifications, OSD, and Control Center."
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

                // Quick Snapshot Button
                ActionButton {
                    iconText: "󰁯"
                    label: "Quick Snapshot"
                    onClicked: root.createQuickSnapshot()
                }

                // Custom Backup Button
                ActionButton {
                    iconText: root.showCustomForm ? "󰅖" : "󰐕"
                    label: root.showCustomForm ? "Cancel" : "New Backup"
                    onClicked: root.showCustomForm = !root.showCustomForm
                }

                // Refresh Button
                MiniIconButton {
                    iconText: "󰑓"
                    onClicked: root.refreshSnapshots()
                }
            }

            // Top Status / Overview Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: statusRow.implicitHeight + 24
                radius: 12
                color: root.theme.bgSurface
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    id: statusRow
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 16

                    // Stat 1: Total Backups
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "TOTAL BACKUPS"
                            font.family: root.font
                            font.pixelSize: 9
                            font.bold: true
                            color: root.theme.textMuted
                        }
                        Text {
                            text: String(root.snapshots.length)
                            font.family: root.font
                            font.pixelSize: 16
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 28
                        color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                    }

                    // Stat 2: Latest Backup
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text {
                            text: "LATEST SNAPSHOT"
                            font.family: root.font
                            font.pixelSize: 9
                            font.bold: true
                            color: root.theme.textMuted
                        }
                        Text {
                            text: root.snapshots.length > 0 ? (root.snapshots[0].name + " (" + root.snapshots[0].dateFormatted + ")") : "None"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.accentPrimary ?? "#7aa2f7"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Quick Actions
                    RowLayout {
                        spacing: 8
                        ActionButton {
                            iconText: "󰁞"
                            label: "Import Archive"
                            btnHeight: 28
                            onClicked: root.showImportForm = !root.showImportForm
                        }
                    }
                }
            }

            // Inline Import Archive Card
            Rectangle {
                visible: root.showImportForm
                Layout.fillWidth: true
                implicitHeight: importCol.implicitHeight + 24
                radius: 12
                color: root.theme.bgSurface
                border.color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.4)
                border.width: 1

                ColumnLayout {
                    id: importCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Text {
                        text: "Import Configuration Archive (.tar.gz)"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 7
                            color: root.theme.bgBase
                            border.color: importInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                            border.width: 1

                            TextInput {
                                id: importInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textPrimary
                                selectByMouse: true
                                text: root.importFilePath
                                onTextChanged: root.importFilePath = text

                                Text {
                                    visible: parent.text === "" && !parent.activeFocus
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Enter full path to archive, e.g. ~/Downloads/quickshell_backup.tar.gz"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textMuted
                                }
                            }
                        }

                        ActionButton {
                            iconText: "󰁞"
                            label: "Import"
                            btnHeight: 32
                            onClicked: root.submitImport()
                        }

                        ActionButton {
                            label: "Cancel"
                            btnHeight: 32
                            onClicked: root.showImportForm = false
                        }
                    }
                }
            }

            // Inline Custom Backup Form Card
            Rectangle {
                visible: root.showCustomForm
                Layout.fillWidth: true
                implicitHeight: formCol.implicitHeight + 28
                radius: 12
                color: root.theme.bgSurface
                border.color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.5)
                border.width: 1

                ColumnLayout {
                    id: formCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Create Custom Backup Snapshot"
                            font.family: root.font
                            font.pixelSize: 14
                            font.bold: true
                            color: root.theme.textPrimary
                            Layout.fillWidth: true
                        }
                        MiniIconButton {
                            iconText: "󰅖"
                            onClicked: root.showCustomForm = false
                        }
                    }

                    // Backup Name input
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: "Backup Name:"
                            font.family: root.font
                            font.pixelSize: 12
                            color: root.theme.textSecondary
                            Layout.preferredWidth: 100
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 7
                            color: root.theme.bgBase
                            border.color: nameInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                            border.width: 1

                            TextInput {
                                id: nameInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textPrimary
                                selectByMouse: true
                                text: root.formBackupName
                                onTextChanged: root.formBackupName = text

                                Text {
                                    visible: parent.text === "" && !parent.activeFocus
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "e.g. Clean Minimal Setup or Before Theme Experiment"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textMuted
                                }
                            }
                        }
                    }

                    // Optional Description input
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: "Note / Memo:"
                            font.family: root.font
                            font.pixelSize: 12
                            color: root.theme.textSecondary
                            Layout.preferredWidth: 100
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 7
                            color: root.theme.bgBase
                            border.color: descInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                            border.width: 1

                            TextInput {
                                id: descInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textPrimary
                                selectByMouse: true
                                text: root.formBackupDesc
                                onTextChanged: root.formBackupDesc = text

                                Text {
                                    visible: parent.text === "" && !parent.activeFocus
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Optional description or context"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textMuted
                                }
                            }
                        }
                    }

                    // Component Selection Chips
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Select Configuration Modules to Include:"
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: true
                                color: root.theme.textSecondary
                                Layout.fillWidth: true
                            }

                            // Select All / Deselect All
                            Text {
                                text: (root.formIncBar && root.formIncNotif && root.formIncOsd && root.formIncCc && root.formIncTheme && root.formIncWallpaper) ? "Deselect All" : "Select All"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.accentPrimary ?? "#7aa2f7"
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const allOn = root.formIncBar && root.formIncNotif && root.formIncOsd && root.formIncCc && root.formIncTheme && root.formIncWallpaper;
                                        root.formIncBar = !allOn;
                                        root.formIncNotif = !allOn;
                                        root.formIncOsd = !allOn;
                                        root.formIncCc = !allOn;
                                        root.formIncTheme = !allOn;
                                        root.formIncWallpaper = !allOn;
                                    }
                                }
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8

                            // Bar chip
                            Rectangle {
                                implicitWidth: barChipRow.implicitWidth + 20
                                height: 30
                                radius: 15
                                color: root.formIncBar ? Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.2) : root.theme.bgBase
                                border.color: root.formIncBar ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                border.width: 1
                                RowLayout {
                                    id: barChipRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: root.formIncBar ? "󰄲" : "󰄱"; font.family: root.font; font.pixelSize: 12; color: root.formIncBar ? root.theme.accentPrimary : root.theme.textMuted }
                                    Text { text: "󰮲 Bar"; font.family: root.font; font.pixelSize: 11; font.bold: true; color: root.theme.textPrimary }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.formIncBar = !root.formIncBar }
                            }

                            // Notifications chip
                            Rectangle {
                                implicitWidth: notifChipRow.implicitWidth + 20
                                height: 30
                                radius: 15
                                color: root.formIncNotif ? Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.2) : root.theme.bgBase
                                border.color: root.formIncNotif ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                border.width: 1
                                RowLayout {
                                    id: notifChipRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: root.formIncNotif ? "󰄲" : "󰄱"; font.family: root.font; font.pixelSize: 12; color: root.formIncNotif ? root.theme.accentPrimary : root.theme.textMuted }
                                    Text { text: "󰂚 Notifications"; font.family: root.font; font.pixelSize: 11; font.bold: true; color: root.theme.textPrimary }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.formIncNotif = !root.formIncNotif }
                            }

                            // OSD chip
                            Rectangle {
                                implicitWidth: osdChipRow.implicitWidth + 20
                                height: 30
                                radius: 15
                                color: root.formIncOsd ? Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.2) : root.theme.bgBase
                                border.color: root.formIncOsd ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                border.width: 1
                                RowLayout {
                                    id: osdChipRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: root.formIncOsd ? "󰄲" : "󰄱"; font.family: root.font; font.pixelSize: 12; color: root.formIncOsd ? root.theme.accentPrimary : root.theme.textMuted }
                                    Text { text: "󰍹 OSD"; font.family: root.font; font.pixelSize: 11; font.bold: true; color: root.theme.textPrimary }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.formIncOsd = !root.formIncOsd }
                            }

                            // Control Center chip
                            Rectangle {
                                implicitWidth: ccChipRow.implicitWidth + 20
                                height: 30
                                radius: 15
                                color: root.formIncCc ? Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.2) : root.theme.bgBase
                                border.color: root.formIncCc ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                border.width: 1
                                RowLayout {
                                    id: ccChipRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: root.formIncCc ? "󰄲" : "󰄱"; font.family: root.font; font.pixelSize: 12; color: root.formIncCc ? root.theme.accentPrimary : root.theme.textMuted }
                                    Text { text: "󰕮 Control Center"; font.family: root.font; font.pixelSize: 11; font.bold: true; color: root.theme.textPrimary }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.formIncCc = !root.formIncCc }
                            }

                            // Appearance & Theme chip
                            Rectangle {
                                implicitWidth: themeChipRow.implicitWidth + 20
                                height: 30
                                radius: 15
                                color: root.formIncTheme ? Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.2) : root.theme.bgBase
                                border.color: root.formIncTheme ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                border.width: 1
                                RowLayout {
                                    id: themeChipRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: root.formIncTheme ? "󰄲" : "󰄱"; font.family: root.font; font.pixelSize: 12; color: root.formIncTheme ? root.theme.accentPrimary : root.theme.textMuted }
                                    Text { text: "󰏘 Appearance & Theme"; font.family: root.font; font.pixelSize: 11; font.bold: true; color: root.theme.textPrimary }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.formIncTheme = !root.formIncTheme }
                            }

                            // Wallpaper chip
                            Rectangle {
                                implicitWidth: wallChipRow.implicitWidth + 20
                                height: 30
                                radius: 15
                                color: root.formIncWallpaper ? Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.2) : root.theme.bgBase
                                border.color: root.formIncWallpaper ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                border.width: 1
                                RowLayout {
                                    id: wallChipRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: root.formIncWallpaper ? "󰄲" : "󰄱"; font.family: root.font; font.pixelSize: 12; color: root.formIncWallpaper ? root.theme.accentPrimary : root.theme.textMuted }
                                    Text { text: "󰸉 Wallpaper"; font.family: root.font; font.pixelSize: 11; font.bold: true; color: root.theme.textPrimary }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.formIncWallpaper = !root.formIncWallpaper }
                            }
                        }
                    }

                    // Form Action Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 10

                        Item { Layout.fillWidth: true }

                        ActionButton {
                            label: "Cancel"
                            btnHeight: 32
                            onClicked: root.showCustomForm = false
                        }

                        ActionButton {
                            iconText: "󰐕"
                            label: "Save Snapshot"
                            btnHeight: 32
                            onClicked: root.submitCustomBackup()
                        }
                    }
                }
            }

            // Snapshots List Section
            SectionCard {
                title: "Saved Snapshots"
                subtitle: root.snapshots.length + " snapshots available"

                // Filter Bar
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    spacing: 8

                    Text {
                        text: "Filter:"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                    }

                    // "All" filter
                    Rectangle {
                        implicitWidth: allFilterText.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: root.activeFilter === "all" ? root.theme.bgSelected : "transparent"
                        border.color: root.activeFilter === "all" ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                        border.width: 1
                        Text {
                            id: allFilterText
                            anchors.centerIn: parent
                            text: "All (" + root.snapshots.length + ")"
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: root.activeFilter === "all"
                            color: root.activeFilter === "all" ? root.theme.accentPrimary : root.theme.textSecondary
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.activeFilter = "all" }
                    }

                    // "Manual" filter
                    Rectangle {
                        readonly property int count: root.snapshots.filter(s => s.type === "manual").length
                        implicitWidth: manualFilterText.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: root.activeFilter === "manual" ? root.theme.bgSelected : "transparent"
                        border.color: root.activeFilter === "manual" ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                        border.width: 1
                        Text {
                            id: manualFilterText
                            anchors.centerIn: parent
                            text: "Manual (" + parent.count + ")"
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: root.activeFilter === "manual"
                            color: root.activeFilter === "manual" ? root.theme.accentPrimary : root.theme.textSecondary
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.activeFilter = "manual" }
                    }

                    // "Safety Backups" filter
                    Rectangle {
                        readonly property int count: root.snapshots.filter(s => s.type && s.type.indexOf("auto_pre_") === 0).length
                        implicitWidth: safetyFilterText.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: root.activeFilter === "safety" ? root.theme.bgSelected : "transparent"
                        border.color: root.activeFilter === "safety" ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                        border.width: 1
                        Text {
                            id: safetyFilterText
                            anchors.centerIn: parent
                            text: "Safety Backups (" + parent.count + ")"
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: root.activeFilter === "safety"
                            color: root.activeFilter === "safety" ? root.theme.accentPrimary : root.theme.textSecondary
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.activeFilter = "safety" }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Snapshots List Repeater
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: root.snapshots.filter(s => {
                            if (root.activeFilter === "manual") return s.type === "manual";
                            if (root.activeFilter === "safety") return s.type && s.type.indexOf("auto_pre_") === 0;
                            return true;
                        })

                        delegate: Rectangle {
                            id: snapItemCard
                            required property var modelData
                            required property int index

                            readonly property bool isSelectedForRestore: root.selectedRestoreSnapshotId === snapItemCard.modelData.id
                            readonly property bool isConfirmDelete: root.confirmDeleteId === snapItemCard.modelData.id
                            readonly property bool isSafetyBackup: snapItemCard.modelData.type && snapItemCard.modelData.type.indexOf("auto_pre_") === 0

                            Layout.fillWidth: true
                            implicitHeight: snapCol.implicitHeight + (isSelectedForRestore ? 56 : 0) + (isConfirmDelete ? 44 : 0) + 20
                            radius: 10
                            color: isSelectedForRestore
                                ? Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.12)
                                : (isConfirmDelete ? Style.withAlpha(root.theme.accentRed ?? "#f7768e", 0.12) : root.theme.bgBase)
                            border.color: isSelectedForRestore
                                ? (root.theme.accentPrimary ?? "#7aa2f7")
                                : (isConfirmDelete ? (root.theme.accentRed ?? "#f7768e") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
                            border.width: 1

                            Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            ColumnLayout {
                                id: snapCol
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                // Top row: Name, Type tag, Date, Size, Action buttons
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    // Icon indicator
                                    Text {
                                        text: snapItemCard.isSafetyBackup ? "󰌢" : "󰁯"
                                        font.family: root.font
                                        font.pixelSize: 14
                                        color: snapItemCard.isSafetyBackup ? (root.theme.accentOrange ?? "#ff9e64") : (root.theme.accentPrimary ?? "#7aa2f7")
                                    }

                                    // Snapshot Name
                                    ColumnLayout {
                                        spacing: 2
                                        Layout.fillWidth: true

                                        RowLayout {
                                            spacing: 6
                                            Text {
                                                text: snapItemCard.modelData.name || snapItemCard.modelData.id
                                                font.family: root.font
                                                font.pixelSize: 13
                                                font.bold: true
                                                color: root.theme.textPrimary
                                                elide: Text.ElideRight
                                            }

                                            // Type badge
                                            Rectangle {
                                                height: 18
                                                implicitWidth: typeBadgeText.implicitWidth + 10
                                                radius: 9
                                                color: snapItemCard.isSafetyBackup
                                                    ? Style.withAlpha(root.theme.accentOrange ?? "#ff9e64", 0.2)
                                                    : (snapItemCard.modelData.type === "imported"
                                                        ? Style.withAlpha(root.theme.accentGreen ?? "#9ece6a", 0.2)
                                                        : Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.2))
                                                border.color: snapItemCard.isSafetyBackup
                                                    ? (root.theme.accentOrange ?? "#ff9e64")
                                                    : (snapItemCard.modelData.type === "imported"
                                                        ? (root.theme.accentGreen ?? "#9ece6a")
                                                        : (root.theme.accentPrimary ?? "#7aa2f7"))
                                                border.width: 1

                                                Text {
                                                    id: typeBadgeText
                                                    anchors.centerIn: parent
                                                    text: snapItemCard.isSafetyBackup ? "Safety Backup" : (snapItemCard.modelData.type === "imported" ? "Imported" : "Manual")
                                                    font.family: root.font
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: snapItemCard.isSafetyBackup
                                                        ? (root.theme.accentOrange ?? "#ff9e64")
                                                        : (snapItemCard.modelData.type === "imported" ? (root.theme.accentGreen ?? "#9ece6a") : (root.theme.accentPrimary ?? "#7aa2f7"))
                                                }
                                            }
                                        }

                                        // Date & ID
                                        RowLayout {
                                            spacing: 8
                                            Text {
                                                text: "󰸗 " + (snapItemCard.modelData.dateFormatted || "")
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                            }
                                            Text {
                                                text: "•"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                            }
                                            Text {
                                                text: "󰋊 " + (snapItemCard.modelData.sizeFormatted || "")
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                            }
                                            Text {
                                                visible: Boolean(snapItemCard.modelData.description)
                                                text: "• " + (snapItemCard.modelData.description || "")
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                                elide: Text.ElideRight
                                                Layout.maximumWidth: 200
                                            }
                                        }
                                    }

                                    // Action Buttons
                                    RowLayout {
                                        spacing: 6

                                        // Restore Button
                                        ActionButton {
                                            iconText: "󰁯"
                                            label: snapItemCard.isSelectedForRestore ? "Cancel" : "Restore"
                                            btnHeight: 28
                                            onClicked: {
                                                if (root.selectedRestoreSnapshotId === snapItemCard.modelData.id) {
                                                    root.selectedRestoreSnapshotId = "";
                                                } else {
                                                    root.selectedRestoreSnapshotId = snapItemCard.modelData.id;
                                                    root.confirmDeleteId = "";
                                                }
                                            }
                                        }

                                        // Export Button
                                        MiniIconButton {
                                            iconText: "󰁞"
                                            onClicked: root.exportSnapshot(snapItemCard.modelData.id)
                                        }

                                        // Delete Button
                                        MiniIconButton {
                                            iconText: "󰆴"
                                            dangerHover: true
                                            onClicked: {
                                                if (root.confirmDeleteId === snapItemCard.modelData.id) {
                                                    root.confirmDeleteId = "";
                                                } else {
                                                    root.confirmDeleteId = snapItemCard.modelData.id;
                                                    root.selectedRestoreSnapshotId = "";
                                                }
                                            }
                                        }
                                    }
                                }

                                // Module Pills row
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    readonly property var mods: snapItemCard.modelData.modules || []

                                    Repeater {
                                        model: snapItemCard.mods
                                        delegate: Rectangle {
                                            required property string modelData
                                            implicitWidth: pillText.implicitWidth + 14
                                            height: 20
                                            radius: 10
                                            color: Style.withAlpha(root.theme.bgSurface, 0.9)
                                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                            border.width: 1

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text {
                                                    id: pillText
                                                    text: {
                                                        switch (modelData) {
                                                            case "bar": return "󰮲 Bar";
                                                            case "notifications": return "󰂚 Notifications";
                                                            case "osd": return "󰍹 OSD";
                                                            case "controlcenter": return "󰕮 Control Center";
                                                            case "appearance": return "󰏘 Theme";
                                                            case "wallpaper": return "󰸉 Wallpaper";
                                                            default: return modelData;
                                                        }
                                                    }
                                                    font.family: root.font
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: root.theme.textSecondary
                                                }
                                            }
                                        }
                                    }
                                }

                                // Expandable Restore Options Tray
                                Rectangle {
                                    visible: snapItemCard.isSelectedForRestore
                                    Layout.fillWidth: true
                                    implicitHeight: restoreOptionsCol.implicitHeight + 12
                                    radius: 8
                                    color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.08)
                                    border.color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.25)
                                    border.width: 1

                                    ColumnLayout {
                                        id: restoreOptionsCol
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 8

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: "Choose what to restore from this snapshot:"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.accentPrimary ?? "#7aa2f7"
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: "A safety backup of your current setup will be taken automatically."
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            // Restore Everything
                                            ActionButton {
                                                iconText: "󰁯"
                                                label: "Restore All Settings"
                                                btnHeight: 28
                                                onClicked: root.restoreSnapshot(snapItemCard.modelData.id, "all")
                                            }

                                            // Granular pills
                                            ActionButton {
                                                label: "Bar Only"
                                                btnHeight: 28
                                                onClicked: root.restoreSnapshot(snapItemCard.modelData.id, "bar")
                                            }

                                            ActionButton {
                                                label: "Notifications Only"
                                                btnHeight: 28
                                                onClicked: root.restoreSnapshot(snapItemCard.modelData.id, "notifications")
                                            }

                                            ActionButton {
                                                label: "OSD Only"
                                                btnHeight: 28
                                                onClicked: root.restoreSnapshot(snapItemCard.modelData.id, "osd")
                                            }

                                            ActionButton {
                                                label: "Control Center Only"
                                                btnHeight: 28
                                                onClicked: root.restoreSnapshot(snapItemCard.modelData.id, "controlcenter")
                                            }

                                            Item { Layout.fillWidth: true }
                                        }
                                    }
                                }

                                // Expandable Confirm Delete Tray
                                Rectangle {
                                    visible: snapItemCard.isConfirmDelete
                                    Layout.fillWidth: true
                                    implicitHeight: deleteConfirmRow.implicitHeight + 12
                                    radius: 8
                                    color: Style.withAlpha(root.theme.accentRed ?? "#f7768e", 0.08)
                                    border.color: Style.withAlpha(root.theme.accentRed ?? "#f7768e", 0.3)
                                    border.width: 1

                                    RowLayout {
                                        id: deleteConfirmRow
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 12

                                        Text {
                                            text: "Permanently delete this snapshot (" + (snapItemCard.modelData.name || snapItemCard.modelData.id) + ")?"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.accentRed ?? "#f7768e"
                                            Layout.fillWidth: true
                                        }

                                        ActionButton {
                                            label: "Cancel"
                                            btnHeight: 26
                                            onClicked: root.confirmDeleteId = ""
                                        }

                                        ActionButton {
                                            iconText: "󰆴"
                                            label: "Confirm Delete"
                                            danger: true
                                            btnHeight: 26
                                            onClicked: root.deleteSnapshot(snapItemCard.modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Empty State
                    Rectangle {
                        visible: root.snapshots.length === 0
                        Layout.fillWidth: true
                        height: 90
                        radius: 10
                        color: root.theme.bgBase
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰁯"
                                font.family: root.font
                                font.pixelSize: 22
                                color: root.theme.textMuted
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No snapshots saved yet. Click 'Quick Snapshot' above to create one."
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textMuted
                            }
                        }
                    }
                }
            }

            // Zero-Risk Protection Info Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: infoRow.implicitHeight + 20
                radius: 12
                color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.06)
                border.color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.2)
                border.width: 1

                RowLayout {
                    id: infoRow
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Text {
                        text: "󰋼"
                        font.family: root.font
                        font.pixelSize: 22
                        color: root.theme.accentPrimary ?? "#7aa2f7"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        Text {
                            text: "Automatic Pre-Restore Safety Snapshots"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Every restore or reset operation automatically creates a safety snapshot before modifying configuration files. Your current layout and customizations can be restored at any time with zero risk."
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // Factory Defaults & Reset Section
            SectionCard {
                title: "Factory Defaults"
                subtitle: "Reset configuration components back to clean default states"

                PreferenceRow {
                    title: "Reset Bar Configuration"
                    subtitle: "Restore default top bar layout, panel arrangements, and widget positions"
                    ActionButton {
                        iconText: "󰁯"
                        label: "Reset Bar"
                        danger: true
                        onClicked: root.resetFactoryDefaults("bar")
                    }
                }

                RowDivider {}

                PreferenceRow {
                    title: "Reset Notification Settings"
                    subtitle: "Restore default toast notification anchor, position, and margins"
                    ActionButton {
                        iconText: "󰁯"
                        label: "Reset Notifications"
                        danger: true
                        onClicked: root.resetFactoryDefaults("notifications")
                    }
                }

                RowDivider {}

                PreferenceRow {
                    title: "Reset On-Screen Display (OSD)"
                    subtitle: "Restore default OSD position, adaptive orientation, and timeout"
                    ActionButton {
                        iconText: "󰁯"
                        label: "Reset OSD"
                        danger: true
                        onClicked: root.resetFactoryDefaults("osd")
                    }
                }

                RowDivider {}

                PreferenceRow {
                    title: "Reset All Quickshell Configurations"
                    subtitle: "Reset Bar, Notifications, and OSD to factory defaults (with safety backup)"
                    ActionButton {
                        iconText: "󰑓"
                        label: "Reset All to Defaults"
                        danger: true
                        onClicked: root.resetFactoryDefaults("all")
                    }
                }
            }
        }
    }

    /* Feedback Toast Notification Banner */
    Rectangle {
        id: statusToast
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        z: 100
        implicitWidth: toastText.implicitWidth + 32
        height: 36
        radius: 18
        color: root.statusIsWarning
            ? (root.theme.bgSurface ?? "#24283b")
            : (root.theme.bgSelected ?? "#283457")
        border.color: root.statusIsWarning
            ? (root.theme.accentOrange ?? "#ff9e64")
            : (root.theme.accentPrimary ?? "#7aa2f7")
        border.width: 1
        opacity: root.statusVisible ? 1.0 : 0.0
        scale: root.statusVisible ? 1.0 : 0.92

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: root.statusIsWarning ? "󰀪" : "󰄬"
                font.family: root.font
                font.pixelSize: 13
                color: root.statusIsWarning ? (root.theme.accentOrange ?? "#ff9e64") : (root.theme.accentGreen ?? "#9ece6a")
            }

            Text {
                id: toastText
                text: root.statusMessage
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textPrimary ?? "#c0caf5"
            }
        }
    }
}
