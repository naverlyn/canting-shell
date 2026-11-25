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
    spacing: 8

    Text {
        text: "Available Wallpapers"
        font.family: root.font
        font.pixelSize: Style.px(12)
        font.bold: true
        color: root.theme.textSecondary
        Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
        Layout.preferredHeight: 20
        Layout.preferredWidth: galleryCountText.implicitWidth + 14
        Layout.alignment: Qt.AlignVCenter
        radius: 10
        color: Qt.rgba(1, 1, 1, 0.06)

        Text {
            id: galleryCountText
            anchors.centerIn: parent
            text: (root.filteredWallpapers ? root.filteredWallpapers.length : 0) + " available"
            font.family: root.font
            font.pixelSize: Style.px(10)
            color: root.theme.textSecondary
        }
    }

    Item { Layout.fillWidth: true }

    // Search field
    Rectangle {
        Layout.preferredWidth: 200
        Layout.preferredHeight: 28
        Layout.alignment: Qt.AlignVCenter
        radius: 6
        color: root.theme.bgSurface
        border.color: searchTextInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
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
                    font.pixelSize: Style.px(11)
                    font.family: root.font
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    selectByMouse: true
                    onTextChanged: root.searchFilter = text
                }

                Text {
                    text: "Search wallpapers..."
                    color: root.theme.textMuted
                    font.pixelSize: Style.px(11)
                    font.family: root.font
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchTextInput.text === "" && !searchTextInput.activeFocus
                }
            }

            Rectangle {
                visible: searchTextInput.text !== ""
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                Layout.alignment: Qt.AlignVCenter
                radius: 8
                color: clearSearchHover.hovered ? root.theme.bgHover : "transparent"
                HoverHandler { id: clearSearchHover }

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.family: root.font
                    font.pixelSize: Style.px(12)
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
