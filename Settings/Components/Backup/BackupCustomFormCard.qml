import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

Rectangle {
    required property var root
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
                font.pixelSize: Style.px(14)
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
                font.pixelSize: Style.px(12)
                color: root.theme.textSecondary
                Layout.preferredWidth: 72
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: nameInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                TextInput {
                    id: nameInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.font
                    font.pixelSize: Style.px(11)
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
                        font.pixelSize: Style.px(11)
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
                font.pixelSize: Style.px(12)
                color: root.theme.textSecondary
                Layout.preferredWidth: 72
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: descInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                TextInput {
                    id: descInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.font
                    font.pixelSize: Style.px(11)
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
                        font.pixelSize: Style.px(11)
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
                    font.pixelSize: Style.px(12)
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.fillWidth: true
                }

                Text {
                    readonly property bool allOn: root.formSelectedModules.length === root.moduleDefs.length
                    text: allOn ? "Deselect All" : "Select All"
                    font.family: root.font
                    font.pixelSize: Style.px(11)
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
                        border.color: selected ? (root.theme.accentPrimary ?? "#7aa2f7") : root.theme.bgBorder
                        border.width: 1

                        RowLayout {
                            id: formChipRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: selected ? "󰄲" : "󰄱"
                                font.family: root.font
                                font.pixelSize: Style.px(12)
                                color: selected ? root.theme.accentPrimary : root.theme.textMuted
                            }
                            Text {
                                text: modelData.icon + " " + modelData.label
                                font.family: root.font
                                font.pixelSize: Style.px(11)
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
