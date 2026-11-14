import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../Common"

ColumnLayout {
    required property var root
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
