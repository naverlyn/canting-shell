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

        // Bottom bar with Filename & Apply Button
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
                    color: "#ffffff"
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

            Rectangle {
                implicitWidth: cancelPrevText.implicitWidth + 24
                height: 36
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
                    color: "#ffffff"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.previewPath = ""
                }
            }

            Rectangle {
                implicitWidth: applyPrevText.implicitWidth + 28
                height: 36
                radius: 8
                color: applyPrevHov.hovered ? root.theme.accentCyan : root.theme.accentPrimary
                scale: applyPrevHov.hovered ? 1.03 : 1.0
                HoverHandler { id: applyPrevHov }

                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    id: applyPrevText
                    anchors.centerIn: parent
                    text: "Apply Wallpaper"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.bgBase
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        WallpaperService.setWallpaper(root.previewPath);
                        root.previewPath = "";
                    }
                }
            }
        }
    }
}
