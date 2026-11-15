import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var theme
    required property string font
    required property var actionData
    required property color accent
    required property bool isSelected
    required property bool isPending

    signal hovered()
    signal triggered()

    Layout.fillWidth: true
    implicitHeight: 112
    radius: 14
    color: root.isPending
        ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
        : (tileMouse.containsMouse || root.isSelected)
            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12)
            : root.theme.bgSurface
    border.width: (root.isSelected || root.isPending) ? 2 : 1
    border.color: (root.isSelected || root.isPending)
        ? root.accent
        : (tileMouse.containsMouse ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55) : root.theme.bgBorder)

    scale: tileMouse.pressed ? 0.96 : 1.0
    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

    // Hotkey badge in top-right corner
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        width: 20
        height: 20
        radius: 6
        color: (root.isSelected || root.isPending)
            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
            : root.theme.bgBase
        border.width: 1
        border.color: root.theme.bgBorder

        Text {
            anchors.centerIn: parent
            text: root.actionData.hotkey
            font.family: root.font
            font.pixelSize: 10
            font.bold: true
            color: (root.isSelected || root.isPending) ? root.accent : root.theme.textMuted
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.actionData.icon
            font.family: root.font
            font.pixelSize: 28
            color: (root.isSelected || root.isPending || tileMouse.containsMouse)
                ? root.accent
                : root.theme.textPrimary
            Behavior on color { ColorAnimation { duration: 140 } }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.actionData.label
            font.family: root.font
            font.pixelSize: 13
            font.bold: true
            color: root.theme.textPrimary
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.actionData.subtitle
            font.family: root.font
            font.pixelSize: 10
            color: root.theme.textSecondary
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: root.triggered()
    }
}
