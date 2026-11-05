import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: ghostRoot
    required property var hostRoot

    readonly property bool activeDrag: hostRoot.isDraggingBlock && hostRoot.draggedModType !== ""
    readonly property bool isOverStage: hostRoot.isOverStage

    visible: opacity > 0.01
    z: 99999
    implicitWidth: ghostRow.implicitWidth + 24
    width: implicitWidth
    height: 36
    radius: 8

    x: Math.max(4, Math.min(hostRoot.width - width - 4, hostRoot.dragMouseX - (width / 2)))
    y: Math.max(4, Math.min(hostRoot.height - height - 4, hostRoot.dragMouseY - (height / 2)))

    scale: activeDrag ? 1.05 : 0.92
    opacity: activeDrag ? 0.95 : 0.0

    color: isOverStage
        ? Qt.rgba(hostRoot.theme.accentPrimary.r, hostRoot.theme.accentPrimary.g, hostRoot.theme.accentPrimary.b, 0.25)
        : hostRoot.theme.bgSelected
    border.color: hostRoot.theme.accentPrimary
    border.width: 1.5

    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        id: ghostRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: hostRoot.draggedModIcon || "󰆍"
            font.family: hostRoot.font
            font.pixelSize: 14
            color: hostRoot.theme.accentPrimary
        }

        Text {
            text: hostRoot.isOverStage
                ? (hostRoot.draggedModName + " (Drop to Place)")
                : hostRoot.draggedModName
            font.family: hostRoot.font
            font.pixelSize: 11
            font.bold: true
            color: hostRoot.theme.textPrimary
        }

        Text {
            visible: hostRoot.isOverStage
            text: "󰐕"
            font.family: hostRoot.font
            font.pixelSize: 11
            color: hostRoot.theme.accentPrimary
        }
    }
}

