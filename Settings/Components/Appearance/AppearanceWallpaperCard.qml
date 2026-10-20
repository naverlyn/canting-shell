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
    Layout.fillWidth: true
    height: 58
    radius: 10
    color: wpMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : root.theme.bgSurface
    border.color: wpMouse.containsMouse ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: wpMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.wpProcRef.running = true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Desktop Wallpaper"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }
            Text {
                text: "Pick background images or set dynamic wallpapers"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
            }
        }

        // Explicit spacer pushes the Browse button to the far right
        Item {
            Layout.fillWidth: true
        }

        // Browse button on the far right
        Rectangle {
            width: 84
            height: 28
            radius: 6
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            color: wpBtnMouse.containsMouse ? root.theme.bgSelected : root.theme.bgBase
            border.color: wpBtnMouse.containsMouse ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.12))
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: "Browse"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: wpBtnMouse.containsMouse ? root.theme.accentPrimary : root.theme.textPrimary
            }

            MouseArea {
                id: wpBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.wpProcRef.running = true
            }
        }
    }
}
