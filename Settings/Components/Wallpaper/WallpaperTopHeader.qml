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

Item {
    required property var root
    Layout.fillWidth: true
    height: Math.max(headerTitleCol.implicitHeight, 36)

    ColumnLayout {
        id: headerTitleCol
        anchors.left: parent.left
        anchors.right: segmentedPill.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            text: "Wallpaper"
            font.family: root.font
            font.pixelSize: 20
            font.bold: true
            color: root.theme.textPrimary
        }

        Text {
            text: root.currentView === 0
                ? "Choose desktop background image and color theme"
                : "Browse folders and manage wallpaper source directories"
            font.family: root.font
            font.pixelSize: 12
            color: root.theme.textSecondary
            elide: Text.ElideRight
        }
    }

    // Segmented View Switch (Gallery / Folders) - anchored to the far right
    Rectangle {
        id: segmentedPill
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 172
        height: 30
        radius: 6
        color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.08)
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        // Sliding active pill
        Rectangle {
            x: root.currentView === 0 ? 2 : (parent.width / 2)
            y: 2
            width: (parent.width - 4) / 2
            height: parent.height - 4
            radius: 4
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Gallery button
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    text: "Gallery"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: root.currentView === 0
                    color: root.currentView === 0 ? root.theme.accentPrimary : root.theme.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentView = 0;
                        root.previewPath = "";
                    }
                }
            }

            // Folders button
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    text: "Folders"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: root.currentView === 1
                    color: root.currentView === 1 ? root.theme.accentPrimary : root.theme.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentView = 1;
                        root.previewPath = "";
                        WallpaperService.loadBrowseEntries();
                    }
                }
            }
        }
    }
}
