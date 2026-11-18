import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card

    required property var theme
    required property string font
    required property var themeObj
    required property bool isSelected

    signal clicked()

    radius: 10
    color: themeObj ? themeObj.bgSurface : theme.bgSurface
    border.color: isSelected
        ? theme.accentPrimary
        : (tileMouse.containsMouse ? Qt.rgba(theme.accentPrimary.r, theme.accentPrimary.g, theme.accentPrimary.b, 0.55) : theme.bgBorder)
    border.width: isSelected ? 2 : 1
    z: tileMouse.containsMouse ? 2 : (isSelected ? 1 : 0)
    scale: tileMouse.pressed ? 0.96 : (tileMouse.containsMouse ? 1.03 : 1.0)
    Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
    Behavior on border.width { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 7
        implicitWidth: selectedBadgeText.implicitWidth + 10
        height: 16
        radius: 8
        color: card.theme.accentPrimary
        opacity: card.isSelected ? 1.0 : 0.0
        scale: card.isSelected ? 1.0 : 0.5
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

        Text {
            id: selectedBadgeText
            anchors.centerIn: parent
            text: "Selected"
            font.family: card.font
            font.pixelSize: 9
            font.bold: true
            color: card.theme.bgBase
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        Row {
            spacing: 4
            Rectangle { width: 12; height: 12; radius: 6; color: card.themeObj ? card.themeObj.bgBase : card.theme.bgBase }
            Rectangle { width: 12; height: 12; radius: 6; color: card.themeObj ? card.themeObj.accentPrimary : card.theme.accentPrimary }
            Rectangle { width: 12; height: 12; radius: 6; color: card.themeObj ? card.themeObj.accentGreen : card.theme.accentGreen }
            Rectangle { width: 12; height: 12; radius: 6; color: card.themeObj ? card.themeObj.accentOrange : card.theme.accentOrange }
            Rectangle { width: 12; height: 12; radius: 6; color: card.themeObj ? card.themeObj.accentRed : card.theme.accentRed }
        }

        Text {
            Layout.fillWidth: true
            text: card.themeObj ? card.themeObj.name : ""
            font.family: card.font
            font.pixelSize: 11
            font.bold: card.isSelected
            color: card.themeObj ? card.themeObj.textPrimary : card.theme.textPrimary
            elide: Text.ElideRight
        }
    }
}
