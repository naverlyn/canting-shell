import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../Common"

Rectangle {
    required property var root
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
