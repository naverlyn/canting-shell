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

    // File picker via zenity
    Process {
        id: filePickerProc
        command: [
            "zenity", "--file-selection",
            "--title=Select Quickshell Backup Archive",
            "--file-filter=Backup Archives (*.tar.gz *.tgz) | *.tar.gz *.tgz",
            "--file-filter=All Files | *"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const picked = text.trim();
                if (picked) {
                    root.importFilePath = picked;
                }
            }
        }
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

                    Text {
                        text: "Save snapshots of your setup, restore previous states, or reset individual components."
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

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

            // Inline Import Archive Card
            Rectangle {
                visible: root.showImportForm
                Layout.fillWidth: true
                implicitHeight: importCol.implicitHeight + 24
                radius: 12
                color: root.theme.bgSurface
                border.color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.45)
                border.width: 1

                ColumnLayout {
                    id: importCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Import Backup Archive (.tar.gz)"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                            Layout.fillWidth: true
                        }
                        MiniIconButton {
                            iconText: "󰅖"
                            onClicked: root.showImportForm = false
                        }
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
                                    text: "Choose a .tar.gz archive or paste its path..."
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textMuted
                                }
                            }
                        }

                        ActionButton {
                            iconText: "󰉋"
                            label: "Browse..."
                            btnHeight: 32
                            onClicked: {
                                if (!filePickerProc.running) {
                                    filePickerProc.running = true;
                                }
                            }
                        }

                        ActionButton {
                            iconText: "󰋺"
                            label: "Import"
                            btnHeight: 32
                            btnEnabled: root.importFilePath.trim() !== ""
                            onClicked: root.submitImport()
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
                border.color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.45)
                border.width: 1

                ColumnLayout {
                    id: formCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Create Custom Backup"
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

                    // Backup Name & Note
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: "Name"
                            font.family: root.font
                            font.pixelSize: 12
                            color: root.theme.textSecondary
                            Layout.preferredWidth: 72
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
                                    text: "e.g. Clean Minimal Setup (optional)"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textMuted
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: "Note"
                            font.family: root.font
                            font.pixelSize: 12
                            color: root.theme.textSecondary
                            Layout.preferredWidth: 72
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
                                    text: "Optional context about what changed"
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
                                text: "Components to include"
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: true
                                color: root.theme.textSecondary
                                Layout.fillWidth: true
                            }

                            Text {
                                readonly property bool allOn: root.formSelectedModules.length === root.moduleDefs.length
                                text: allOn ? "Deselect All" : "Select All"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.accentPrimary ?? "#7aa2f7"
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (parent.allOn) {
                                            root.formSelectedModules = [];
                                        } else {
                                            root.formSelectedModules = root.moduleDefs.map(m => m.id);
                                        }
                                    }
                                }
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: root.moduleDefs
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool selected: root.formSelectedModules.indexOf(modelData.id) !== -1
                                    implicitWidth: formChipRow.implicitWidth + 20
                                    height: 30
                                    radius: 15
                                    color: selected ? Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.2) : root.theme.bgBase
                                    border.color: selected ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                    border.width: 1

                                    RowLayout {
                                        id: formChipRow
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text {
                                            text: selected ? "󰄲" : "󰄱"
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: selected ? root.theme.accentPrimary : root.theme.textMuted
                                        }
                                        Text {
                                            text: modelData.icon + " " + modelData.label
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.textPrimary
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleFormModule(modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        ActionButton {
                            label: "Cancel"
                            btnHeight: 32
                            onClicked: root.showCustomForm = false
                        }

                        ActionButton {
                            iconText: "󰐕"
                            label: "Save Backup"
                            btnHeight: 32
                            onClicked: root.submitCustomBackup()
                        }
                    }
                }
            }

            // Saved Snapshots Section
            SectionCard {
                title: "Saved Snapshots"
                subtitle: root.snapshots.length === 0
                    ? "None saved yet"
                    : (root.snapshots.length === 1 ? "1 snapshot" : root.snapshots.length + " snapshots")

                // Filter Bar
                RowLayout {
                    visible: root.snapshots.length > 0
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Show:"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Repeater {
                        model: [
                            { id: "all", label: "All", count: root.snapshots.length },
                            { id: "manual", label: "Manual", count: root.snapshots.filter(s => s.type === "manual" || s.type === "imported").length },
                            { id: "safety", label: "Safety Backups", count: root.snapshots.filter(s => s.type && s.type.indexOf("auto_pre_") === 0).length }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: root.activeFilter === modelData.id
                            implicitWidth: filterPillText.implicitWidth + 16
                            height: 24
                            radius: 12
                            Layout.alignment: Qt.AlignVCenter
                            color: active ? root.theme.bgSelected : "transparent"
                            border.color: active ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                            border.width: 1

                            Text {
                                id: filterPillText
                                anchors.centerIn: parent
                                text: modelData.label + " (" + modelData.count + ")"
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: active
                                color: active ? root.theme.accentPrimary : root.theme.textSecondary
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeFilter = modelData.id
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Snapshots List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: root.filteredSnapshots

                        delegate: Rectangle {
                            id: snapItemCard
                            required property var modelData
                            required property int index

                            readonly property bool isSelectedForRestore: root.selectedRestoreSnapshotId === snapItemCard.modelData.id
                            readonly property bool isConfirmDelete: root.confirmDeleteId === snapItemCard.modelData.id
                            readonly property bool isSafetyBackup: snapItemCard.modelData.type && snapItemCard.modelData.type.indexOf("auto_pre_") === 0
                            readonly property bool isImported: snapItemCard.modelData.type === "imported"
                            readonly property var availMods: root.availableModulesForSnapshot(snapItemCard.modelData)

                            Layout.fillWidth: true
                            implicitHeight: snapCol.implicitHeight + 24
                            radius: 10
                            color: isSelectedForRestore
                                ? Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.10)
                                : (isConfirmDelete ? Style.withAlpha(root.theme.accentRed ?? "#f7768e", 0.10) : root.theme.bgBase)
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
                                spacing: 10

                                // Top Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Text {
                                        Layout.preferredWidth: 20
                                        Layout.alignment: Qt.AlignTop
                                        Layout.topMargin: 2
                                        horizontalAlignment: Text.AlignHCenter
                                        text: snapItemCard.isSafetyBackup ? "󰌢" : (snapItemCard.isImported ? "󰋺" : "󰁯")
                                        font.family: root.font
                                        font.pixelSize: 16
                                        color: snapItemCard.isSafetyBackup
                                            ? (root.theme.accentOrange ?? "#ff9e64")
                                            : (snapItemCard.isImported ? (root.theme.accentGreen ?? "#9ece6a") : (root.theme.accentPrimary ?? "#7aa2f7"))
                                    }

                                    // Name, Badge, Metadata & Description
                                    ColumnLayout {
                                        spacing: 4
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Text {
                                                text: snapItemCard.modelData.name || snapItemCard.modelData.id
                                                font.family: root.font
                                                font.pixelSize: 13
                                                font.bold: true
                                                color: root.theme.textPrimary
                                                elide: Text.ElideRight
                                                Layout.maximumWidth: 420
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Rectangle {
                                                height: 18
                                                implicitWidth: typeBadgeText.implicitWidth + 10
                                                radius: 9
                                                Layout.alignment: Qt.AlignVCenter
                                                color: snapItemCard.isSafetyBackup
                                                    ? Style.withAlpha(root.theme.accentOrange ?? "#ff9e64", 0.18)
                                                    : (snapItemCard.isImported
                                                        ? Style.withAlpha(root.theme.accentGreen ?? "#9ece6a", 0.18)
                                                        : Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.18))
                                                border.color: snapItemCard.isSafetyBackup
                                                    ? (root.theme.accentOrange ?? "#ff9e64")
                                                    : (snapItemCard.isImported
                                                        ? (root.theme.accentGreen ?? "#9ece6a")
                                                        : (root.theme.accentPrimary ?? "#7aa2f7"))
                                                border.width: 1

                                                Text {
                                                    id: typeBadgeText
                                                    anchors.centerIn: parent
                                                    text: snapItemCard.isSafetyBackup ? "Safety" : (snapItemCard.isImported ? "Imported" : "Manual")
                                                    font.family: root.font
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: snapItemCard.isSafetyBackup
                                                        ? (root.theme.accentOrange ?? "#ff9e64")
                                                        : (snapItemCard.isImported ? (root.theme.accentGreen ?? "#9ece6a") : (root.theme.accentPrimary ?? "#7aa2f7"))
                                                }
                                            }

                                            Item { Layout.fillWidth: true }
                                        }

                                        // Date, Size, Module count
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                text: snapItemCard.modelData.dateFormatted || ""
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                            }
                                            Text { text: "•"; font.family: root.font; font.pixelSize: 10; color: root.theme.textMuted }
                                            Text {
                                                text: snapItemCard.modelData.sizeFormatted || ""
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                            }
                                            Text { text: "•"; font.family: root.font; font.pixelSize: 10; color: root.theme.textMuted }
                                            Text {
                                                text: snapItemCard.availMods.length === root.moduleDefs.length
                                                    ? "All components"
                                                    : (snapItemCard.availMods.length + " component" + (snapItemCard.availMods.length === 1 ? "" : "s"))
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                            }
                                        }

                                        // Full wrapped description (if any)
                                        Text {
                                            visible: Boolean(snapItemCard.modelData.description)
                                            text: snapItemCard.modelData.description || ""
                                            font.family: root.font
                                            font.pixelSize: 11
                                            color: root.theme.textSecondary
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }

                                    // Clear, Labeled Action Buttons
                                    RowLayout {
                                        spacing: 6
                                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                        ActionButton {
                                            iconText: snapItemCard.isSelectedForRestore ? "󰅖" : "󰁯"
                                            label: snapItemCard.isSelectedForRestore ? "Close" : "Restore"
                                            btnHeight: 28
                                            onClicked: root.openRestoreTray(snapItemCard.modelData)
                                        }

                                        ActionButton {
                                            iconText: "󰇚"
                                            label: "Export"
                                            btnHeight: 28
                                            onClicked: root.exportSnapshot(snapItemCard.modelData.id)
                                        }

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

                                // Expandable Selective Restore Tray
                                Rectangle {
                                    visible: snapItemCard.isSelectedForRestore
                                    Layout.fillWidth: true
                                    implicitHeight: restoreOptionsCol.implicitHeight + 20
                                    radius: 8
                                    color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.08)
                                    border.color: Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.25)
                                    border.width: 1

                                    ColumnLayout {
                                        id: restoreOptionsCol
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 10

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: "Select components to restore"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.accentPrimary ?? "#7aa2f7"
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                visible: snapItemCard.availMods.length > 1
                                                readonly property bool allChecked: root.restoreSelectedModules.length === snapItemCard.availMods.length
                                                text: allChecked ? "Select None" : "Select All"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.accentPrimary ?? "#7aa2f7"
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (parent.allChecked) {
                                                            root.restoreSelectedModules = [];
                                                        } else {
                                                            root.restoreSelectedModules = snapItemCard.availMods.slice();
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Repeater {
                                                model: snapItemCard.availMods
                                                delegate: Rectangle {
                                                    required property string modelData
                                                    readonly property bool checked: root.restoreSelectedModules.indexOf(modelData) !== -1
                                                    implicitWidth: restoreChipRow.implicitWidth + 16
                                                    height: 26
                                                    radius: 13
                                                    color: checked ? Style.withAlpha(root.theme.accentPrimary ?? "#7aa2f7", 0.22) : root.theme.bgBase
                                                    border.color: checked ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                                    border.width: 1

                                                    RowLayout {
                                                        id: restoreChipRow
                                                        anchors.centerIn: parent
                                                        spacing: 5
                                                        Text {
                                                            text: checked ? "󰄲" : "󰄱"
                                                            font.family: root.font
                                                            font.pixelSize: 11
                                                            color: checked ? root.theme.accentPrimary : root.theme.textMuted
                                                        }
                                                        Text {
                                                            text: root.moduleIcon(modelData) + " " + root.moduleLabel(modelData)
                                                            font.family: root.font
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: root.theme.textPrimary
                                                        }
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.toggleRestoreModule(modelData)
                                                    }
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Text {
                                                text: "󰌢 Your current setup is backed up automatically before restoring."
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                                Layout.fillWidth: true
                                                wrapMode: Text.WordWrap
                                            }

                                            ActionButton {
                                                label: "Cancel"
                                                btnHeight: 28
                                                onClicked: {
                                                    root.selectedRestoreSnapshotId = "";
                                                    root.restoreSelectedModules = [];
                                                }
                                            }

                                            ActionButton {
                                                iconText: "󰁯"
                                                label: root.restoreSelectedModules.length === snapItemCard.availMods.length
                                                    ? "Restore All"
                                                    : ("Restore (" + root.restoreSelectedModules.length + ")")
                                                btnHeight: 28
                                                btnEnabled: root.restoreSelectedModules.length > 0 && !root.loading
                                                onClicked: root.restoreSelected(snapItemCard.modelData)
                                            }
                                        }
                                    }
                                }

                                // Expandable Confirm Delete Tray
                                Rectangle {
                                    visible: snapItemCard.isConfirmDelete
                                    Layout.fillWidth: true
                                    implicitHeight: deleteConfirmRow.implicitHeight + 20
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
                                            text: "Delete '" + (snapItemCard.modelData.name || snapItemCard.modelData.id) + "' permanently?"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.accentRed ?? "#f7768e"
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                        }

                                        ActionButton {
                                            label: "Cancel"
                                            btnHeight: 26
                                            onClicked: root.confirmDeleteId = ""
                                        }

                                        ActionButton {
                                            iconText: "󰆴"
                                            label: "Delete"
                                            danger: true
                                            btnHeight: 26
                                            onClicked: root.deleteSnapshot(snapItemCard.modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Empty State (no snapshots at all OR filter has 0 results)
                    Rectangle {
                        visible: root.filteredSnapshots.length === 0
                        Layout.fillWidth: true
                        height: 84
                        radius: 10
                        color: root.theme.bgBase
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.activeFilter === "safety" ? "󰌢" : "󰁯"
                                font.family: root.font
                                font.pixelSize: 20
                                color: root.theme.textMuted
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.snapshots.length === 0
                                    ? "No snapshots yet. Click 'Quick Snapshot' above to save your current setup."
                                    : (root.activeFilter === "safety"
                                        ? "No safety backups yet — they are created automatically before any restore or reset."
                                        : "No manual snapshots match this filter.")
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textMuted
                            }
                        }
                    }
                }
            }

            // Factory Defaults Section (with safe inline confirmation)
            SectionCard {
                title: "Factory Defaults"
                subtitle: "Reset components to clean defaults (saves a safety backup first)"
                contentMargins: 4
                contentSpacing: 0

                Repeater {
                    model: root.resetDefs

                    delegate: ColumnLayout {
                        required property var modelData
                        required property int index
                        readonly property bool isConfirming: root.confirmResetModule === modelData.id

                        Layout.fillWidth: true
                        spacing: 0

                        RowDivider { visible: index > 0 }

                        PreferenceRow {
                            title: modelData.title
                            subtitle: modelData.subtitle

                            ActionButton {
                                visible: !isConfirming
                                iconText: "󰑓"
                                label: modelData.btnLabel
                                minWidth: 104
                                danger: true
                                onClicked: root.confirmResetModule = modelData.id
                            }

                            RowLayout {
                                visible: isConfirming
                                spacing: 6

                                ActionButton {
                                    label: "Cancel"
                                    btnHeight: 28
                                    onClicked: root.confirmResetModule = ""
                                }

                                ActionButton {
                                    iconText: "󰑓"
                                    label: "Confirm Reset"
                                    danger: true
                                    btnHeight: 28
                                    onClicked: root.resetFactoryDefaults(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ToastBanner {
        id: toastBanner
        theme: root.theme
        font: root.font
        durationMs: 3400
    }
}
