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
    Layout.fillWidth: true
    height: 42
    radius: 8
    color: root.theme.bgSurface
    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        Text {
            text: "Active:"
            color: root.theme.textSecondary
            font.pixelSize: 11
            font.family: root.font
            font.bold: true
        }

        Flickable {
            Layout.fillWidth: true
            height: 26
            contentWidth: activeChipsRow.implicitWidth
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: activeChipsRow
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: WallpaperService.directories

                    delegate: Rectangle {
                        required property string modelData
                        height: 24
                        width: chipRow.implicitWidth + 14
                        radius: 6
                        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: WallpaperService.displayPath(modelData)
                                color: root.theme.textPrimary
                                font.pixelSize: 11
                                font.family: root.font
                            }

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: chipRemHover.hovered ? (root.theme.accentRed ?? "#ef4444") : "transparent"
                                scale: chipRemHover.hovered ? 1.15 : 1.0
                                HoverHandler { id: chipRemHover }

                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: chipRemHover.hovered ? "#ffffff" : root.theme.textMuted
                                    font.pixelSize: 11
                                    font.family: root.font
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: WallpaperService.removeDirectory(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Reset defaults link
        Text {
            text: "Reset"
            color: resetHover.hovered ? root.theme.accentPrimary : root.theme.textMuted
            font.pixelSize: 11
            font.family: root.font
            font.underline: true
            scale: resetHover.hovered ? 1.05 : 1.0
            HoverHandler { id: resetHover }

            Behavior on scale { NumberAnimation { duration: 120 } }
            Behavior on color { ColorAnimation { duration: 150 } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: WallpaperService.resetDefaultDirectories()
            }
        }
    }
}
