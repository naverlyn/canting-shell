/*
 * BackupRestoreSettings.qml
 *
 * Dedicated Settings page for Quickshell configuration backup and restoration.
 * Provides 1-click quick snapshots, custom selective backups, intuitive
 * selective restore, archive import/export with file picker, and confirmed
 * factory defaults reset.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Common"
import "Backup"

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
    property var restoreSelectedModules: []
    property string confirmDeleteId: ""
    property string confirmResetModule: "" // "" | "bar" | "notifications" | "osd" | "lockscreen" | "all"

    // Form state
    property string formBackupName: ""
    property string formBackupDesc: ""
    property var formSelectedModules: ["bar", "notifications", "osd", "controlcenter", "lockscreen", "appearance", "wallpaper"]

    property string importFilePath: ""

    // Toast feedback state
    property string statusMessage: ""
    property bool statusVisible: false
    property bool statusIsWarning: false

    readonly property string scriptPath: Qt.resolvedUrl("../scripts/manage_backup.py").toString().replace(/^file:\/\//, "")

    readonly property var moduleDefs: [
        { id: "bar", label: "Bar", icon: "󰮲" },
        { id: "notifications", label: "Notifications", icon: "󰂚" },
        { id: "osd", label: "OSD", icon: "󰍹" },
        { id: "controlcenter", label: "Control Center", icon: "󰕮" },
        { id: "lockscreen", label: "Lock Screen", icon: "󰌾" },
        { id: "appearance", label: "Appearance & Theme", icon: "󰏘" },
        { id: "wallpaper", label: "Wallpaper", icon: "󰸉" }
    ]

    readonly property var resetDefs: [
        { id: "bar", title: "Bar Configuration", subtitle: "Top bar layout, panel arrangements, and widget positions", btnLabel: "Reset" },
        { id: "notifications", title: "Notification Settings", subtitle: "Toast anchor, position, styling, and margins", btnLabel: "Reset" },
        { id: "osd", title: "On-Screen Display (OSD)", subtitle: "OSD position, adaptive orientation, and timeout", btnLabel: "Reset" },
        { id: "lockscreen", title: "Lock Screen Configuration", subtitle: "Lock screen modules, visual filters, and password box layout", btnLabel: "Reset" },
        { id: "all", title: "All Quickshell Settings", subtitle: "Reset Bar, Notifications, OSD, and Lock Screen together", btnLabel: "Reset All" }
    ]

    readonly property var filteredSnapshots: {
        return root.snapshots.filter(s => {
            if (root.activeFilter === "manual") return s.type === "manual" || s.type === "imported";
            if (root.activeFilter === "safety") return s.type && s.type.indexOf("auto_pre_") === 0;
            return true;
        });
    }

    function moduleLabel(modId) {
        for (let i = 0; i < moduleDefs.length; i++) {
            if (moduleDefs[i].id === modId) return moduleDefs[i].label;
        }
        return modId;
    }

    function moduleIcon(modId) {
        for (let i = 0; i < moduleDefs.length; i++) {
            if (moduleDefs[i].id === modId) return moduleDefs[i].icon;
        }
        return "󰒓";
    }

    function availableModulesForSnapshot(snap) {
        const mods = snap.modules || [];
        if (mods.length === 0 || mods.indexOf("all") !== -1) {
            return moduleDefs.map(m => m.id);
        }
        // Keep only known modules in canonical order
        return moduleDefs.map(m => m.id).filter(id => mods.indexOf(id) !== -1);
    }

    function toggleRestoreModule(modId) {
        let next = root.restoreSelectedModules.slice();
        const idx = next.indexOf(modId);
        if (idx !== -1) {
            next.splice(idx, 1);
        } else {
            next.push(modId);
        }
        root.restoreSelectedModules = next;
    }

    function toggleFormModule(modId) {
        let next = root.formSelectedModules.slice();
        const idx = next.indexOf(modId);
        if (idx !== -1) {
            next.splice(idx, 1);
        } else {
            next.push(modId);
        }
        root.formSelectedModules = next;
    }

    function showToast(msg, isWarn) {
        toastBanner.show(msg, isWarn);
    }

    function openFilePicker() {
        archivePickerModal.openPicker();
    }

    FilePickerModal {
        id: archivePickerModal
        root: root
        title: "Select Quickshell Backup Archive"
        extensions: [".tar.gz", ".tgz"]
        showThumbnails: false
        fileGlyph: "󰗄"
        emptyText: "No folders or backup archives (.tar.gz / .tgz) found here"
        hintText: "Click a folder to open, or select a .tar.gz / .tgz archive"
        searchPlaceholder: "Filter folders or backup archives..."
        quickPlaces: [
            { label: "Home", path: archivePickerModal.homeDir },
            { label: "Downloads", path: archivePickerModal.homeDir + "/Downloads" },
            { label: "Backups", path: archivePickerModal.homeDir + "/.config/quickshell/backups" },
            { label: "Quickshell", path: archivePickerModal.homeDir + "/.config/quickshell" }
        ]
        onFileSelected: (path) => root.importFilePath = path
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
                        root.refreshSnapshots();
                    }
                } catch (e) {
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
        if (root.formSelectedModules.length === 0) {
            root.showToast("Select at least one component to back up.", true);
            return;
        }
        const name = root.formBackupName.trim();
        const desc = root.formBackupDesc.trim();
        runBackupCommand(["create", name, root.formSelectedModules.join(","), desc], "create");
        root.showCustomForm = false;
        root.formBackupName = "";
        root.formBackupDesc = "";
    }

    function openRestoreTray(snap) {
        if (root.selectedRestoreSnapshotId === snap.id) {
            root.selectedRestoreSnapshotId = "";
            root.restoreSelectedModules = [];
        } else {
            root.selectedRestoreSnapshotId = snap.id;
            root.restoreSelectedModules = root.availableModulesForSnapshot(snap);
            root.confirmDeleteId = "";
        }
    }

    function restoreSelected(snap) {
        if (root.restoreSelectedModules.length === 0) {
            root.showToast("Select at least one component to restore.", true);
            return;
        }
        const avail = root.availableModulesForSnapshot(snap);
        const csv = root.restoreSelectedModules.length === avail.length
            ? "all"
            : root.restoreSelectedModules.join(",");
        runBackupCommand(["restore", snap.id, csv], "restore");
        root.selectedRestoreSnapshotId = "";
        root.restoreSelectedModules = [];
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
            root.showToast("Choose or enter an archive file path first.", true);
            return;
        }
        runBackupCommand(["import", path], "import");
        root.showImportForm = false;
        root.importFilePath = "";
    }

    function resetFactoryDefaults(modId) {
        runBackupCommand(["reset_defaults", modId || "all"], "reset_defaults");
        root.confirmResetModule = "";
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
            id: vertScroll
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15)
            }
        }

        ColumnLayout {
            id: mainCol
            width: flickable.width - (vertScroll.visible ? 12 : 0)
            spacing: 16

            // Unified Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    spacing: 3
                    Layout.fillWidth: true

                    Text {
                        text: "Backup & Restore"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 8
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                    ActionButton {
                        iconText: "󰁯"
                        label: "Quick Snapshot"
                        btnHeight: 32
                        btnEnabled: !root.loading
                        onClicked: root.createQuickSnapshot()
                    }

                    ActionButton {
                        iconText: root.showCustomForm ? "󰅖" : "󰐕"
                        label: root.showCustomForm ? "Cancel" : "New Backup"
                        btnHeight: 32
                        onClicked: {
                            root.showCustomForm = !root.showCustomForm;
                            if (root.showCustomForm) root.showImportForm = false;
                        }
                    }

                    ActionButton {
                        iconText: root.showImportForm ? "󰅖" : "󰋺"
                        label: root.showImportForm ? "Cancel" : "Import"
                        btnHeight: 32
                        onClicked: {
                            root.showImportForm = !root.showImportForm;
                            if (root.showImportForm) root.showCustomForm = false;
                        }
                    }

                    // Refresh Button
                    Rectangle {
                        id: headerRefreshBtn
                        implicitWidth: 32
                        implicitHeight: 32
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignVCenter
                        radius: 8
                        scale: headerRefreshMouse.pressed ? 0.95 : (headerRefreshHover.hovered ? 1.02 : 1.0)
                        color: headerRefreshMouse.pressed
                            ? Style.theme.bgSelected
                            : (headerRefreshHover.hovered ? Style.withAlpha(Style.theme.accentPrimary, 0.14) : Style.theme.bgBase)
                        border.color: headerRefreshHover.hovered ? Style.withAlpha(Style.theme.accentPrimary, 0.5) : Style.theme.bgBorder
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        HoverHandler { id: headerRefreshHover }

                        Text {
                            anchors.centerIn: parent
                            text: "󰑓"
                            font.family: root.font
                            font.pixelSize: 13
                            color: headerRefreshHover.hovered ? Style.theme.accentPrimary : Style.theme.textSecondary
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: headerRefreshMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refreshSnapshots()
                        }
                    }
                }
            }

            BackupImportCard { root: root }
            BackupCustomFormCard { root: root }
            BackupSnapshotsSection { root: root }
            BackupFactoryDefaultsSection { root: root }
        }
    }

    ToastBanner {
        id: toastBanner
        theme: root.theme
        font: root.font
        durationMs: 3400
    }
}
