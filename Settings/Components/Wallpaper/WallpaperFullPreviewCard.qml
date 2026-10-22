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

Rectangle {
    id: previewCardRoot
    required property var root
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.88)
    visible: root.previewPath !== ""
    z: 99

    MouseArea {
        anchors.fill: parent
        onClicked: root.previewPath = ""
    }

    // Preview Content Container
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.88
        height: parent.height * 0.88
        spacing: 12

        // Preview Image
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "transparent"
            clip: true

            Image {
                anchors.fill: parent
                source: root.previewPath !== "" ? ("file://" + root.previewPath) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
        }

        // Bottom Bar Container
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            // Row 1: Filename / Path & Wallpaper Type Selector
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.extractFilename(root.previewPath)
                        font.family: root.font
                        font.pixelSize: 14
                        font.bold: true
                        color: root.theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.previewPath
                        font.family: root.font
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.6)
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                }
            }

            // Row 2: Close & Action Buttons (Text-only, no icons, prettier labels)
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Close Button
                Rectangle {
                    implicitWidth: cancelPrevText.implicitWidth + 24
                    height: 34
                    radius: 8
                    color: cancelPrevHov.hovered ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1
                    scale: cancelPrevHov.hovered ? 1.03 : 1.0
                    HoverHandler { id: cancelPrevHov }

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: cancelPrevText
                        anchors.centerIn: parent
                        text: "Close"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.previewPath = ""
                    }
                }

                Item { Layout.fillWidth: true }

                // Set Primary Button
                Rectangle {
                    implicitWidth: dispAText.implicitWidth + 24
                    height: 34
                    radius: 8
                    color: dispAHov.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.15)) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.08))
                    border.color: root.theme.accentPrimary
                    border.width: 1
                    scale: dispAHov.hovered ? 1.03 : 1.0
                    HoverHandler { id: dispAHov }

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: dispAText
                        anchors.centerIn: parent
                        text: WallpaperService.hasMultipleMonitors
                            ? "Set Primary (" + WallpaperService.displayAName + ")"
                            : "Set Wallpaper"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            WallpaperService.setWallpaper(root.previewPath, WallpaperService.hasMultipleMonitors ? "primary" : "all", WallpaperService.resizeMode);
                            root.previewPath = "";
                        }
                    }
                }

                // Set Secondary Button (only shown if multiple monitors are connected!)
                Rectangle {
                    visible: WallpaperService.hasMultipleMonitors
                    implicitWidth: dispBText.implicitWidth + 24
                    height: 34
                    radius: 8
                    color: dispBHov.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.15)) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.08))
                    border.color: root.theme.accentCyan ?? root.theme.accentPrimary
                    border.width: 1
                    scale: dispBHov.hovered ? 1.03 : 1.0
                    HoverHandler { id: dispBHov }

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: dispBText
                        anchors.centerIn: parent
                        text: "Set Secondary (" + WallpaperService.displayBName + ")"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            WallpaperService.setWallpaper(root.previewPath, "secondary", WallpaperService.resizeMode);
                            root.previewPath = "";
                        }
                    }
                }

                // Apply to All Displays Button (only shown if multiple monitors are connected!)
                Rectangle {
                    visible: WallpaperService.hasMultipleMonitors
                    implicitWidth: applyBothText.implicitWidth + 26
                    height: 34
                    radius: 8
                    color: applyBothHov.hovered ? (root.theme.accentCyan ?? root.theme.accentPrimary) : root.theme.accentPrimary
                    scale: applyBothHov.hovered ? 1.03 : 1.0
                    HoverHandler { id: applyBothHov }

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: applyBothText
                        anchors.centerIn: parent
                        text: "Apply to All Displays"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.bgBase
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            WallpaperService.setWallpaper(root.previewPath, "all", WallpaperService.resizeMode);
                            root.previewPath = "";
                        }
                    }
                }
            }
        }
    }
}
