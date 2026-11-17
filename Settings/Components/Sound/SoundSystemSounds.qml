import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../../osd"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "System Sounds"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: sysSoundsCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: sysSoundsCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Alert Sound Selector */
            Item {
                Layout.fillWidth: true
                height: 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        spacing: 2
                        Layout.preferredWidth: root.labelColWidth
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Alert Sound"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Theme event sound"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    AppDropdown {
                        theme: root.theme
                        font: root.font
                        width: 220
                        implicitWidth: 220
                        menuWidth: 220
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        options: [
                            { desktop: "bell",               name: "Bell",        desc: "" },
                            { desktop: "dialog-information", name: "Information", desc: "" },
                            { desktop: "window-attention",   name: "Attention",   desc: "" },
                            { desktop: "message",            name: "Message",     desc: "" },
                            { desktop: "complete",           name: "Complete",    desc: "" }
                        ]
                        currentValue: root.selectedAlertSound
                        onSelected: (val) => {
                            root.selectedAlertSound = val;
                            root.playSound(val);
                        }
                    }

                    /* Standardized Play Alert Button */
                    Rectangle {
                        implicitWidth: root.actionBtnWidth
                        implicitHeight: root.btnHeight
                        Layout.preferredWidth: root.actionBtnWidth
                        Layout.preferredHeight: root.btnHeight
                        width: root.actionBtnWidth
                        height: root.btnHeight
                        radius: root.btnRadius
                        color: playAlertHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2))
                        border.color: playAlertHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: playAlertHover }

                        Text {
                            anchors.centerIn: parent
                            text: "Play"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            onClicked: root.playSound(root.selectedAlertSound)
                        }
                    }
                }
            }
        }
    }
}
