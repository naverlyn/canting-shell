import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../../wallpaper"
import "../.."
import "../Common"
import ".."

RowLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    // Home
    Rectangle {
        implicitWidth: homeText.implicitWidth + 24
        height: 30
        radius: 6
        color: homeHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.1)) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05))
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        scale: homeHover.hovered ? 1.04 : 1.0
        HoverHandler { id: homeHover }

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            id: homeText
            anchors.centerIn: parent
            text: "Home"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.textPrimary
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: WallpaperService.navigateTo(Quickshell.env("HOME"))
        }
    }

    // Pictures
    Rectangle {
        implicitWidth: picText.implicitWidth + 24
        height: 30
        radius: 6
        color: picHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.1)) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05))
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        scale: picHover.hovered ? 1.04 : 1.0
        HoverHandler { id: picHover }

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            id: picText
            anchors.centerIn: parent
            text: "Pictures"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.textPrimary
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: WallpaperService.navigateTo(Quickshell.env("HOME") + "/Pictures")
        }
    }

    // Downloads
    Rectangle {
        implicitWidth: dlText.implicitWidth + 24
        height: 30
        radius: 6
        color: dlHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.1)) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05))
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        scale: dlHover.hovered ? 1.04 : 1.0
        HoverHandler { id: dlHover }

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            id: dlText
            anchors.centerIn: parent
            text: "Downloads"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.textPrimary
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: WallpaperService.navigateTo(Quickshell.env("HOME") + "/Downloads")
        }
    }

    // Up
    Rectangle {
        implicitWidth: upText.implicitWidth + 22
        height: 30
        radius: 6
        color: upHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.1)) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05))
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        scale: upHover.hovered ? 1.04 : 1.0
        HoverHandler { id: upHover }

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Text {
            id: upText
            anchors.centerIn: parent
            text: "Up"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.textPrimary
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: WallpaperService.navigateUp()
        }
    }

    // Jump to path text field
    Rectangle {
        Layout.fillWidth: true
        height: 30
        radius: 6
        color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.04)
        border.color: jumpInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 6

            TextInput {
                id: jumpInput
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: root.theme.textPrimary
                font.pixelSize: 11
                font.family: root.font
                clip: true
                selectByMouse: true
                onAccepted: {
                    if (text.trim() !== "") {
                        WallpaperService.navigateTo(text.trim());
                        text = "";
                    }
                }
            }

            Text {
                text: "Jump to path (e.g. ~/Wallpapers)..."
                color: root.theme.textMuted
                font.pixelSize: 11
                font.family: root.font
                visible: jumpInput.text === "" && !jumpInput.activeFocus
            }
        }
    }
}
