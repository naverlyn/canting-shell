import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

RowLayout {
    required property var root
    spacing: 8

    // Test Live Motion
    Rectangle {
        height: 32
        implicitWidth: topTestText.implicitWidth + 24
        radius: 8
        color: topTestHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase
        border.color: topTestHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        HoverHandler { id: topTestHover }

        Text {
            id: topTestText
            anchors.centerIn: parent
            text: "Test Live Motion"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: topTestHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.testLiveMotion()
        }
    }

    // Save & Apply Profile
    Rectangle {
        height: 32
        implicitWidth: topSaveText.implicitWidth + 24
        radius: 8
        color: topSaveHover.hovered ? Qt.darker(root.theme.accentPrimary, 1.1) : root.theme.accentPrimary
        Behavior on color { ColorAnimation { duration: 140 } }

        HoverHandler { id: topSaveHover }

        Text {
            id: topSaveText
            anchors.centerIn: parent
            text: "Save & Apply Profile"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: "#ffffff"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.saveCustomAnimation()
        }
    }

    // Close Button
    Rectangle {
        height: 32
        implicitWidth: topCloseText.implicitWidth + 22
        radius: 8
        color: topCloseHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase
        border.color: topCloseHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        HoverHandler { id: topCloseHover }

        Text {
            id: topCloseText
            anchors.centerIn: parent
            text: "Close"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: topCloseHover.hovered ? root.theme.accentPrimary : root.theme.textSecondary
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.isCreatingCustom = false
        }
    }
}
