import QtQuick
import QtQuick.Layouts

Rectangle {
    id: infoRow
    required property var theme
    required property string font
    property string label: ""
    property string value: ""
    property bool showDivider: true

    Layout.fillWidth: true
    height: 38
    radius: 6
    color: rowHover.hovered ? (theme.bgHover ?? Qt.rgba(1, 1, 1, 0.04)) : "transparent"

    Behavior on color { ColorAnimation { duration: 120 } }

    HoverHandler { id: rowHover }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Text {
            text: infoRow.label
            font.family: infoRow.font
            font.pixelSize: 13
            color: infoRow.theme.textSecondary
        }

        Item { Layout.fillWidth: true }

        Text {
            text: infoRow.value
            font.family: infoRow.font
            font.pixelSize: 13
            font.bold: true
            color: infoRow.theme.textPrimary
            elide: Text.ElideRight
            Layout.maximumWidth: 320
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 1
        color: Qt.rgba(1, 1, 1, 0.05)
        visible: infoRow.showDivider
    }
}
