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
    Layout.leftMargin: 4
    Layout.rightMargin: 4

    Text {
        text: "Available Wallpapers"
        font.family: root.font
        font.pixelSize: 12
        font.bold: true
        color: root.theme.textSecondary
    }

    Rectangle {
        height: 18
        width: galleryCountText.implicitWidth + 12
        radius: 9
        color: Qt.rgba(1, 1, 1, 0.06)

        Text {
            id: galleryCountText
            anchors.centerIn: parent
            text: (root.filteredWallpapers ? root.filteredWallpapers.length : 0) + " available"
            font.family: root.font
            font.pixelSize: 10
            color: root.theme.textSecondary
        }
    }

    Item { Layout.fillWidth: true }

    // Search field
    Rectangle {
        width: 200
        height: 28
        radius: 6
        color: root.theme.bgSurface
        border.color: searchTextInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 6

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextInput {
                    id: searchTextInput
                    anchors.fill: parent
                    color: root.theme.textPrimary
                    font.pixelSize: 11
                    font.family: root.font
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    selectByMouse: true
                    onTextChanged: root.searchFilter = text
                }

                Text {
                    text: "Search wallpapers..."
                    color: root.theme.textMuted
                    font.pixelSize: 11
                    font.family: root.font
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchTextInput.text === "" && !searchTextInput.activeFocus
                }
            }

            Rectangle {
                visible: searchTextInput.text !== ""
                width: 16
                height: 16
                radius: 8
                color: clearSearchHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.15)) : "transparent"
                HoverHandler { id: clearSearchHover }

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.family: root.font
                    font.pixelSize: 12
                    color: clearSearchHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        searchTextInput.text = "";
                        root.searchFilter = "";
                    }
                }
            }
        }
    }
}
