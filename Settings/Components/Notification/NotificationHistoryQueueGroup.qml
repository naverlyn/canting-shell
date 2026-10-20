import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../notifications"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "History"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: historyCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: historyCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            Item {
                Layout.fillWidth: true
                height: 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: root.totalCount > 0 
                                ? "Active Notifications: " + root.totalCount 
                                : "No Active Notifications"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Recent notifications are displayed in the Control Center"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: clearBtn
                        width: 80
                        height: 32
                        radius: 6
                        readonly property bool canClear: root.totalCount > 0
                        opacity: canClear ? 1.0 : 0.4
                        color: clearHover.hovered && canClear ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : root.theme.bgBase
                        border.color: clearHover.hovered && canClear ? (root.theme.accentRed ?? "#f7768e") : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: clearHover }

                        Text {
                            anchors.centerIn: parent
                            text: "Clear All"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: clearBtn.canClear && clearHover.hovered ? (root.theme.accentRed ?? "#f7768e") : root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: clearBtn.canClear ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (clearBtn.canClear) NotificationService.dismissAll();
                            }
                        }
                    }
                }
            }
        }
    }
}
