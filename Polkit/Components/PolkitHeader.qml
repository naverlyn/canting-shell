import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property var theme
    required property string font
    required property string actionId

    signal closeRequested()

    Layout.fillWidth: true
    spacing: 12

    Rectangle {
        width: 38
        height: 38
        radius: 19
        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.16)
        border.width: 1
        border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.45)

        Text {
            anchors.centerIn: parent
            text: "󰒃"
            font.family: root.font
            font.pixelSize: 18
            color: root.theme.accentPrimary
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            text: "Authentication Required"
            font.family: root.font
            font.pixelSize: 16
            font.bold: true
            color: root.theme.textPrimary
        }

        Text {
            visible: root.actionId !== ""
            text: root.actionId
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textMuted
            maximumLineCount: 1
            elide: Text.ElideMiddle
            Layout.fillWidth: true
        }
    }
}
