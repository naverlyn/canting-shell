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
    spacing: 8

    // Family category pills
    Row {
        spacing: 5
        Layout.alignment: Qt.AlignVCenter

        Repeater {
            model: root.families

            Rectangle {
                required property var modelData
                height: 24
                implicitWidth: pillText.implicitWidth + 14
                radius: 12
                color: root.selectedFamily === modelData ? root.theme.bgSelected : root.theme.bgSurface
                border.color: root.selectedFamily === modelData ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    id: pillText
                    anchors.centerIn: parent
                    text: modelData
                    font.family: root.font
                    font.pixelSize: 10
                    font.bold: root.selectedFamily === modelData
                    color: root.selectedFamily === modelData ? root.theme.accentPrimary : root.theme.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedFamily = modelData
                }
            }
        }

        // Wallpaper palette mode pill
        Rectangle {
            visible: root.theme.wallpaperFeatureEnabled
            height: 24
            implicitWidth: wpPillText.implicitWidth + 14
            radius: 12
            color: root.theme.wallpaperMode ? root.theme.bgSelected : root.theme.bgSurface
            border.color: root.theme.wallpaperMode ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Text {
                id: wpPillText
                anchors.centerIn: parent
                text: "Wallpaper"
                font.family: root.font
                font.pixelSize: 10
                font.bold: root.theme.wallpaperMode
                color: root.theme.wallpaperMode ? root.theme.accentPrimary : root.theme.textSecondary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.theme.previewIndex = -1;
                    root.theme.setWallpaperMode();
                }
            }
        }
    }

    Item { Layout.fillWidth: true }

    // Search input
    Rectangle {
        width: 180
        height: 26
        radius: 13
        color: root.theme.bgSurface
        border.color: searchInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4

            Text {
                text: "󰍉"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textMuted
            }

            TextInput {
                id: searchInput
                Layout.fillWidth: true
                color: root.theme.textPrimary
                font.family: root.font
                font.pixelSize: 10
                clip: true
                selectByMouse: true

                onTextChanged: root.searchText = text

                Text {
                    text: "Search..."
                    font.family: root.font
                    font.pixelSize: 10
                    color: root.theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchInput.text === ""
                }
            }

            Text {
                text: "󰅖"
                font.family: root.font
                font.pixelSize: 10
                color: root.theme.textMuted
                visible: searchInput.text !== ""

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        searchInput.text = "";
                        root.searchText = "";
                    }
                }
            }
        }
    }
}
