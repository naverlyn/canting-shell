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
    Layout.fillWidth: true
    spacing: 12

    // Close Studio Button
    Rectangle {
        height: 32
        implicitWidth: footerCloseText.implicitWidth + 24
        radius: 7
        color: footerCloseMouse.containsMouse ? root.theme.bgHover : root.theme.bgSelected
        border.color: root.theme.bgBorder
        border.width: 1

        Text {
            id: footerCloseText
            anchors.centerIn: parent
            text: "Close Studio"
            font.family: root.font
            font.pixelSize: Style.px(11)
            font.bold: true
            color: root.theme.textSecondary
        }

        MouseArea {
            id: footerCloseMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.isCreatingCustom = false
        }
    }

    Item { Layout.fillWidth: true }

    // Test Live Motion on Hyprland
    Rectangle {
        height: 32
        implicitWidth: footerTestText.implicitWidth + 24
        radius: 7
        color: footerTestMouse.containsMouse ? root.theme.bgHover : root.theme.bgSelected
        border.color: footerTestMouse.containsMouse ? root.theme.accentPrimary : root.theme.bgBorder
        border.width: 1

        Text {
            id: footerTestText
            anchors.centerIn: parent
            text: "Test Live Motion on Hyprland"
            font.family: root.font
            font.pixelSize: Style.px(11)
            font.bold: true
            color: footerTestMouse.containsMouse ? root.theme.accentPrimary : root.theme.textPrimary
        }

        MouseArea {
            id: footerTestMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.testLiveMotion()
        }
    }

    // Save & Apply Profile
    Rectangle {
        height: 32
        implicitWidth: footerSaveText.implicitWidth + 24
        radius: 7
        color: footerSaveMouse.containsMouse ? Qt.darker(root.theme.accentPrimary, 1.1) : root.theme.accentPrimary

        Text {
            id: footerSaveText
            anchors.centerIn: parent
            text: "Save & Apply Profile"
            font.family: root.font
            font.pixelSize: Style.px(11)
            font.bold: true
            color: "#ffffff"
        }

        MouseArea {
            id: footerSaveMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.saveCustomAnimation()
        }
    }
}
