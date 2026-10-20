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
    height: 52
    radius: 10
    color: root.theme.bgSurface
    border.color: WallpaperService.isConfigured(WallpaperService.browsePath)
        ? (root.theme.accentGreen ?? root.theme.accentPrimary)
        : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            // Breadcrumbs path
            Flickable {
                Layout.fillWidth: true
                height: 20
                contentWidth: crumbRow.implicitWidth
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: crumbRow
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: WallpaperService.getBreadcrumbs(WallpaperService.browsePath)

                        delegate: Row {
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                height: 20
                                width: crumbLabel.implicitWidth + 8
                                radius: 4
                                color: crumbMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.1)) : "transparent"
                                scale: crumbMouse.containsMouse ? 1.05 : 1.0

                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    id: crumbLabel
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: index === WallpaperService.getBreadcrumbs(WallpaperService.browsePath).length - 1
                                        ? root.theme.accentPrimary
                                        : root.theme.textPrimary
                                    font.pixelSize: 12
                                    font.family: root.font
                                    font.bold: index === WallpaperService.getBreadcrumbs(WallpaperService.browsePath).length - 1
                                }

                                MouseArea {
                                    id: crumbMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: WallpaperService.navigateTo(modelData.path)
                                }
                            }

                            Text {
                                text: "/"
                                color: root.theme.textMuted
                                font.pixelSize: 11
                                font.family: root.font
                                anchors.verticalCenter: parent.verticalCenter
                                visible: index < WallpaperService.getBreadcrumbs(WallpaperService.browsePath).length - 1
                            }
                        }
                    }
                }
            }

            // Images count
            Text {
                text: WallpaperService.browseLoading
                    ? "Scanning images..."
                    : (WallpaperService.browseImageCount + " images in this folder")
                color: root.theme.textSecondary
                font.pixelSize: 10
                font.family: root.font
            }
        }

        // Add / Remove Folder action button (Text only)
        Rectangle {
            readonly property bool isAdded: WallpaperService.isConfigured(WallpaperService.browsePath)
            implicitWidth: toggleBtnText.implicitWidth + 24
            height: 32
            radius: 6
            color: isAdded
                ? (currRemoveHover.containsMouse ? (root.theme.accentRed ?? "#ef4444") : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.1)))
                : root.theme.accentPrimary
            border.color: isAdded
                ? (root.theme.accentGreen ?? root.theme.accentPrimary)
                : "transparent"
            border.width: 1
            scale: currRemoveHover.containsMouse ? 1.03 : 1.0

            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                id: toggleBtnText
                anchors.centerIn: parent
                text: parent.isAdded
                    ? (currRemoveHover.containsMouse ? "Remove Folder" : "Added as Source")
                    : "+ Add This Folder"
                color: parent.isAdded
                    ? (currRemoveHover.containsMouse ? "#ffffff" : root.theme.textPrimary)
                    : (root.theme.bgBase ?? "#161313")
                font.pixelSize: 11
                font.family: root.font
                font.bold: true
            }

            MouseArea {
                id: currRemoveHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (parent.isAdded) {
                        WallpaperService.removeDirectory(WallpaperService.browsePath);
                    } else {
                        WallpaperService.addDirectory(WallpaperService.browsePath);
                    }
                }
            }
        }
    }
}
