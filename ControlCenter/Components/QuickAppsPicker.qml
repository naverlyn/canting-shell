import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import ".."
import "../../ThemeSwitcher"

Rectangle {
    id: root

    property var theme: Theme
    property string font: "Lato Nerd Font"
    property int targetSlotIndex: -1
    property var appsModel: []
    property string searchText: ""

    signal appPicked(var entry)
    signal fullAppGridRequested()
    signal resetRequested()

    implicitHeight: pickerCol.implicitHeight + 20
    radius: 10
    color: root.theme.bgBase
    border.color: root.theme.accentPrimary
    border.width: 1

    ColumnLayout {
        id: pickerCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: root.targetSlotIndex >= 0
                    ? ("Pick app for Slot " + (root.targetSlotIndex + 1) + " (click any tile above to switch slot)")
                    : "Click an app below to add to Quick Launch"
                font.family: root.font
                font.pixelSize: 10
                font.bold: true
                color: root.theme.accentPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Open full bar AppGrid button
            Rectangle {
                height: 20
                implicitWidth: openGridTxt.implicitWidth + 12
                radius: 5
                color: openGridMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                border.color: root.theme.bgBorder
                border.width: 1

                Text {
                    id: openGridTxt
                    anchors.centerIn: parent
                    text: "Full AppGrid"
                    font.family: root.font
                    font.pixelSize: 9
                    font.bold: true
                    color: root.theme.textSecondary
                }

                MouseArea {
                    id: openGridMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.fullAppGridRequested()
                }
            }

            // Reset defaults button
            Rectangle {
                height: 20
                implicitWidth: resetAppsTxt.implicitWidth + 12
                radius: 5
                color: resetAppsMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                border.color: root.theme.bgBorder
                border.width: 1

                Text {
                    id: resetAppsTxt
                    anchors.centerIn: parent
                    text: "Reset"
                    font.family: root.font
                    font.pixelSize: 9
                    font.bold: true
                    color: root.theme.textSecondary
                }

                MouseArea {
                    id: resetAppsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetRequested()
                }
            }
        }

        // AppGrid Search Bar (uses theme.bgSurface, theme.textPrimary, theme.textMuted)
        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: 8
            color: root.theme.bgSurface
            border.color: appSearchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "󰍉"
                    color: root.theme.textMuted
                    font.pixelSize: 12
                    font.family: root.font
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: appSearchInput.implicitHeight

                    TextInput {
                        id: appSearchInput
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.theme.textPrimary
                        font.pixelSize: 11
                        font.family: root.font
                        clip: true
                        selectByMouse: true
                        onTextChanged: root.searchText = text
                    }

                    Text {
                        text: "Search applications..."
                        color: root.theme.textMuted
                        font.pixelSize: 11
                        font.family: root.font
                        anchors.verticalCenter: parent.verticalCenter
                        visible: appSearchInput.text === ""
                    }
                }
            }
        }

        // AppGrid GridView of Installed Desktop Applications
        GridView {
            id: pickerGrid
            Layout.fillWidth: true
            Layout.preferredHeight: 168
            cellWidth: Math.floor(width / 4)
            cellHeight: 56
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.appsModel

            delegate: Item {
                id: pickerCell
                required property var modelData
                required property int index
                width: pickerGrid.cellWidth
                height: pickerGrid.cellHeight

                readonly property bool hasIcon: (pickerCell.modelData.icon ?? "") !== "" && Quickshell.iconPath(pickerCell.modelData.icon ?? "", true) !== ""

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 8
                    color: pickerCellMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                    border.color: pickerCellMouse.containsMouse ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        spacing: 3

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            width: 22
                            height: 22

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 22
                                source: pickerCell.hasIcon ? Quickshell.iconPath(pickerCell.modelData.icon ?? "", true) : ""
                                visible: pickerCell.hasIcon
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰀻"
                                color: root.theme.accentPrimary
                                font.pixelSize: 15
                                font.family: root.font
                                visible: !pickerCell.hasIcon
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: pickerCell.modelData.name ?? ""
                            color: pickerCellMouse.containsMouse ? root.theme.textPrimary : root.theme.textSecondary
                            font.pixelSize: 9
                            font.family: root.font
                            font.bold: pickerCellMouse.containsMouse
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: pickerCellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.appPicked(pickerCell.modelData)
                    }
                }
            }
        }
    }
}
