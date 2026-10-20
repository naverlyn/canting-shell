import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    id: dragGhostCard
    readonly property bool activeDrag: root.isDraggingBlock && root.draggedWidgetId !== ""
    readonly property bool isRemoving: root.dragHoverPanelIndex === -2 && root.dragSourcePanelIndex >= 0
    readonly property bool isTargetMaxed: root.isDraggingBlock
        && root.dragHoverPanelIndex >= 0
        && root.dragHoverPanelIndex !== root.dragSourcePanelIndex
        && !BarConfig.canAddWidgetToPanel(root.draggedWidgetId, root.dragHoverPanelIndex)
    readonly property var dragMeta: BarConfig.getWidgetMeta(root.draggedWidgetId)
    readonly property color dragColor: root.resolveThemeSpec(root.getBlockColorSpec(root.draggedWidgetId), root.theme.accentPrimary)

    visible: opacity > 0.01
    z: 9999
    implicitWidth: ghostRow.implicitWidth + 24
    width: implicitWidth
    height: 36
    radius: 8
    x: Math.max(4, Math.min(root.width - width - 4, root.dragMouseX - (width / 2)))
    y: Math.max(4, Math.min(root.height - height - 4, root.dragMouseY - (height / 2)))
    scale: activeDrag ? 1.04 : 0.92
    opacity: activeDrag ? 0.96 : 0.0
    color: (isRemoving || isTargetMaxed) ? root.withAlpha(root.theme.accentRed, 0.18) : root.theme.bgSelected
    border.color: (isRemoving || isTargetMaxed) ? root.theme.accentRed : dragColor
    border.width: 1.5

    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Row {
        id: ghostRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: dragGhostCard.isRemoving ? "󰅖" : (dragGhostCard.isTargetMaxed ? "󰀪" : dragGhostCard.dragMeta.icon)
            font.family: root.font
            font.pixelSize: 13
            color: (dragGhostCard.isRemoving || dragGhostCard.isTargetMaxed) ? root.theme.accentRed : dragGhostCard.dragColor
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: dragGhostCard.isTargetMaxed
                ? (dragGhostCard.dragMeta.name + " (Maxed out)")
                : (dragGhostCard.isRemoving ? ("Remove " + dragGhostCard.dragMeta.name) : dragGhostCard.dragMeta.name)
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: (dragGhostCard.isRemoving || dragGhostCard.isTargetMaxed) ? root.theme.accentRed : root.theme.textPrimary
        }
    }
}
