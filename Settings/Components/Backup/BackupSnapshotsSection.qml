import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

SectionCard {
    required property var root
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
