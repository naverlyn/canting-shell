import QtQuick

Rectangle {
    id: root

    required property var theme
    required property string font
    required property string label
    property bool isPrimary: false

    implicitWidth: Math.max(26, keyText.implicitWidth + 14)
    height: 24
    radius: 6
    color: root.isPrimary ? root.theme.bgHover : root.theme.bgSurface
    border.color: root.isPrimary ? root.theme.accentPrimary : root.theme.bgBorder
    border.width: 1

    Text {
        id: keyText
        anchors.centerIn: parent
        text: root.label
        font.family: root.font
        font.pixelSize: 11
        font.bold: true
        color: root.isPrimary ? root.theme.accentPrimary : root.theme.textPrimary
    }
}
