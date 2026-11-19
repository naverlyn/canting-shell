import QtQuick
import QtQuick.Layouts
import "../Common"

Rectangle {
    id: tile
    required property var theme
    required property string font
    property string iconText: ""
    property string label: ""
    property string value: ""

    signal copied(string label, string value)

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: 68
    radius: 12
    color: tileMouse.pressed
        ? Style.withAlpha(tile.theme.accentPrimary, 0.14)
        : (tileHover.hovered ? (tile.theme.bgHover ?? tile.theme.bgSurface) : tile.theme.bgSurface)
    border.color: tileHover.hovered
        ? Style.withAlpha(tile.theme.accentPrimary, 0.45)
        : (tile.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    HoverHandler { id: tileHover }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 11
        anchors.bottomMargin: 11
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: tile.iconText
                font.family: tile.font
                font.pixelSize: 13
                color: tile.theme.accentPrimary
            }

            Text {
                text: tile.label
                font.family: tile.font
                font.pixelSize: Style.px(11)
                color: tile.theme.textSecondary
                Layout.fillWidth: true
            }
        }

        Text {
            text: tile.value
            font.family: tile.font
            font.pixelSize: Style.px(13)
            font.bold: true
            color: tile.theme.textPrimary
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (tile.value !== "") {
                tile.copied(tile.label, tile.value);
            }
        }
    }
}
