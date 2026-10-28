import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    required property var root
    id: dragGhostCard
    visible: root.isDraggingBlock
    z: 9999
    x: root.dragMouseX - width * 0.5
    y: root.dragMouseY - height * 0.5
    width: 195
    height: 36
    radius: 8
    color: root.theme.bgSelected
    border.color: root.theme.accentPrimary
    border.width: 1.5
    opacity: 0.94
    scale: 1.03

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6

        Text {
            text: "󰍜"
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.accentPrimary
        }

        Text {
            visible: root.draggedBlockIcon !== ""
            text: root.draggedBlockIcon
            font.family: root.font
            font.pixelSize: 13
            color: root.theme.accentPrimary
        }

        Text {
            text: root.draggedBlockLabel
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.textPrimary
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Rectangle {
            visible: root.dragHoverZoneIndex >= -2 && root.dragHoverZoneIndex !== -1
            implicitWidth: ghostTargetTxt.implicitWidth + 10
            implicitHeight: 18
            radius: 9
            color: root.withAlpha(root.theme.accentPrimary, 0.22)

            Text {
                id: ghostTargetTxt
                anchors.centerIn: parent
                text: {
                    if (root.dragHoverZoneIndex === -2) return "Pool";
                    if (root.dragHoverZoneIndex === 0) return "→ Header";
                    if (root.dragHoverZoneIndex === 1) return "→ Content";
                    if (root.dragHoverZoneIndex === 2) return "→ Footer";
                    return "";
                }
                font.family: root.font
                font.pixelSize: 9
                font.bold: true
                color: root.theme.accentPrimary
            }
        }
    }
}
