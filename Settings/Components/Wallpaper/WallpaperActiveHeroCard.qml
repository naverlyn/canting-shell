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
    height: 84
    radius: 12
    color: root.theme.bgSurface
    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        // Active wallpaper thumbnail preview
        Rectangle {
            Layout.preferredWidth: 116
            Layout.preferredHeight: 64
            radius: 6
            color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
            clip: true
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            Image {
                anchors.fill: parent
                source: WallpaperService.currentWallpaper ? ("file://" + WallpaperService.currentWallpaper) : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 240
                sourceSize.height: 140
                asynchronous: true
                cache: false
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (WallpaperService.currentWallpaper) {
                        root.previewPath = WallpaperService.currentWallpaper;
                    }
                }
            }
        }

        // Metadata details
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: root.extractFilename(WallpaperService.currentWallpaper)
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: WallpaperService.currentWallpaper || "No background set"
                font.family: root.font
                font.pixelSize: 10
                color: root.theme.textSecondary
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }

            Text {
                text: WallpaperService.generatingTheme
                    ? "󰑮 Extracting palette colors..."
                    : (WallpaperService.autoSyncPalette
                        ? "Colors synced via " + (WallpaperService.backend || "wallust")
                        : "Color sync disabled (static theme active)")
                font.family: root.font
                font.pixelSize: 10
                color: WallpaperService.generatingTheme ? root.theme.accentPrimary : root.theme.textMuted
            }
        }

        // Action buttons & Sync toggle
        RowLayout {
            spacing: 14
            Layout.alignment: Qt.AlignVCenter

            // Random & Rescan buttons
            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    implicitWidth: randBtnText.implicitWidth + 20
                    height: 28
                    radius: 6
                    color: randHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.1)) : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.05))
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    HoverHandler { id: randHover }

                    Text {
                        id: randBtnText
                        anchors.centerIn: parent
                        text: "Random"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectRandomWallpaper()
                    }
                }

                Rectangle {
                    implicitWidth: rescanBtnText.implicitWidth + 20
                    height: 28
                    radius: 6
                    color: rescanHov.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.1)) : "transparent"
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    HoverHandler { id: rescanHov }

                    Text {
                        id: rescanBtnText
                        anchors.centerIn: parent
                        text: "Rescan"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperService.rescan()
                    }
                }
            }

            // Subtle Divider
            Rectangle {
                width: 1
                height: 24
                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
            }

            // Sync Theme Toggle (moved to the right with white knob)
            MouseArea {
                id: syncToggleArea
                implicitWidth: syncToggleRow.implicitWidth
                implicitHeight: 32
                cursorShape: Qt.PointingHandCursor
                onClicked: WallpaperService.setAutoSync(!WallpaperService.autoSyncPalette)

                RowLayout {
                    id: syncToggleRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    ColumnLayout {
                        spacing: 1
                        Layout.alignment: Qt.AlignRight

                        Text {
                            text: "Sync Theme"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textPrimary
                            Layout.alignment: Qt.AlignRight
                        }

                        Text {
                            text: WallpaperService.autoSyncPalette ? "Active palette" : "Disabled"
                            font.family: root.font
                            font.pixelSize: 9
                            color: WallpaperService.autoSyncPalette ? root.theme.accentPrimary : root.theme.textSecondary
                            Layout.alignment: Qt.AlignRight
                        }
                    }

                    Rectangle {
                        width: 44
                        height: 24
                        radius: 12
                        color: WallpaperService.autoSyncPalette ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 160 } }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: WallpaperService.autoSyncPalette ? parent.width - width - 3 : 3
                            color: WallpaperService.autoSyncPalette ? "#ffffff" : (root.theme.textPrimary ?? "#c0caf5")

                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                    }
                }
            }
        }
    }
}
