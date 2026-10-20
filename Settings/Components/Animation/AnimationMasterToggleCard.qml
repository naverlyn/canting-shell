import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    id: masterSwitchCard
    Layout.fillWidth: true
    height: 68
    radius: 12
    color: switchCardMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.04)) : root.theme.bgSurface
    border.color: switchCardMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: switchCardMouse
        anchors.fill: parent
        z: 10
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.setAnimationsEnabled(!root.animationsEnabled)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 18
        spacing: 14

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: 8
                Text {
                    text: "Enable Compositor Animations"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Rectangle {
                    height: 18
                    implicitWidth: globalBadgeText.implicitWidth + 12
                    radius: 9
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1

                    Text {
                        id: globalBadgeText
                        anchors.centerIn: parent
                        text: "Global Scope"
                        font.family: root.font
                        font.pixelSize: 10
                        font.bold: true
                        color: root.theme.textSecondary
                    }
                }

                Rectangle {
                    height: 18
                    implicitWidth: statusBadgeText.implicitWidth + 12
                    radius: 9
                    color: root.animationsEnabled
                        ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.15)
                        : Qt.rgba(1, 1, 1, 0.06)
                    border.color: root.animationsEnabled ? root.theme.accentPrimary : Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1

                    Text {
                        id: statusBadgeText
                        anchors.centerIn: parent
                        text: root.animationsEnabled ? "Active" : "Disabled"
                        font.family: root.font
                        font.pixelSize: 10
                        font.bold: true
                        color: root.animationsEnabled ? root.theme.accentPrimary : root.theme.textMuted
                    }
                }
            }

            Text {
                text: "Global Master Switch: controls whether Hyprland plays animations for windows, workspaces, and fades globally"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
            }
        }

        // Modern Toggle Switch
        Rectangle {
            width: 48
            height: 26
            radius: 13
            color: root.animationsEnabled ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
            Layout.alignment: Qt.AlignVCenter

            Behavior on color { ColorAnimation { duration: 160 } }

            Rectangle {
                width: 20
                height: 20
                radius: 10
                anchors.verticalCenter: parent.verticalCenter
                x: root.animationsEnabled ? parent.width - width - 3 : 3
                color: root.animationsEnabled ? "#ffffff" : root.theme.textPrimary

                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }
        }
    }
}
