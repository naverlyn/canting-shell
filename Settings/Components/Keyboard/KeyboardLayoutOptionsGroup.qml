import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Layout & Options"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: layoutCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: layoutCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Current Keyboard Layout Row */
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
                            text: "Keyboard Layout"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Active Hyprland compositor layout"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: layoutBadgeText.implicitWidth + 18
                        height: 28
                        radius: 6
                        color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.1)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            id: layoutBadgeText
                            anchors.centerIn: parent
                            text: root.getLayoutDisplayName(root.activeLayout)
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }
                }
            }

            /* Row Divider */
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
            }

            /* NumLock by Default Row */
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
                            text: "NumLock on Startup"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Enable numeric keypad lock on login"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 44
                        height: 24
                        radius: 12
                        color: root.numlockByDefault ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 160 } }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.numlockByDefault ? parent.width - width - 3 : 3
                            color: root.numlockByDefault ? "#ffffff" : root.theme.textPrimary

                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.numlockByDefault = !root.numlockByDefault;
                                root.applyHyprKeyword("input:numlock_by_default", root.numlockByDefault ? "true" : "false");
                            }
                        }
                    }
                }
            }

        }
    }
}
