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
    id: blockCard
    property string widgetId: ""
    property int panelIdx: 0
    property int itemIndex: 0
    property int panelTotalItems: 1

    readonly property var meta: BarConfig.getWidgetMeta(widgetId)
    readonly property bool isVisible: BarConfig.isWidgetVisible(widgetId, root.currentBarId())
    readonly property string colorSpec: root.getBlockColorSpec(widgetId)
    readonly property color activeColor: root.resolveThemeSpec(colorSpec, root.theme.accentPrimary)
    readonly property bool isBeingDragged: root.isDraggingBlock && root.draggedWidgetId === blockCard.widgetId
    readonly property bool isPanelMaxedForDrag: blockCard.panelIdx !== root.dragSourcePanelIndex && !BarConfig.canAddWidgetToPanel(root.draggedWidgetId, blockCard.panelIdx)
    readonly property bool isTargetPanel: root.isDraggingBlock && root.dragHoverPanelIndex === blockCard.panelIdx && root.draggedWidgetId !== blockCard.widgetId && !isPanelMaxedForDrag
    readonly property bool isBeforeThis: isTargetPanel && root.dragHoverItemIndex === blockCard.itemIndex
    readonly property bool isAfterThis: isTargetPanel && (
        (root.dragHoverItemIndex === blockCard.itemIndex + 1) ||
        (blockCard.itemIndex === blockCard.panelTotalItems - 1 && root.dragHoverItemIndex >= blockCard.panelTotalItems)
    )
    readonly property bool isDropTarget: isBeforeThis || isAfterThis

    Layout.fillWidth: true
    height: 38
    radius: 8
    scale: isBeingDragged ? 0.96 : 1.0
    color: isDropTarget
        ? root.theme.bgSelected
        : (cardHover.hovered ? root.theme.bgHover : root.theme.bgBase)
    border.color: isDropTarget || isBeingDragged
        ? root.theme.accentPrimary
        : (isVisible ? (cardHover.hovered ? activeColor : root.theme.bgBorder) : root.withAlpha(root.theme.bgBorder, 0.5))
    border.width: isDropTarget ? 1.5 : 1
    opacity: isBeingDragged ? 0.35 : (isVisible ? 1.0 : 0.55)

    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    HoverHandler { id: cardHover }

    Rectangle {
        visible: blockCard.isDropTarget
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        y: blockCard.isAfterThis ? parent.height - 3 : 1
        height: 2
        radius: 1
        color: root.theme.accentPrimary
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 6

        Text {
            text: "󰍜"
            font.family: root.font
            font.pixelSize: 11
            color: cardHover.hovered ? root.theme.textSecondary : root.theme.textMuted
            opacity: cardHover.hovered ? 0.85 : 0.35
            Layout.preferredWidth: 12
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: blockCard.meta.icon
            font.family: root.font
            font.pixelSize: 13
            color: blockCard.isVisible ? blockCard.activeColor : root.theme.textMuted
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredWidth: 18
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: blockCard.meta.name
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: blockCard.isVisible ? root.theme.textPrimary : root.theme.textMuted
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        RowLayout {
            id: cardBtnRow
            z: 2
            spacing: 3
            Layout.alignment: Qt.AlignVCenter

            MiniIconButton {
                visible: cardHover.hovered && blockCard.itemIndex > 0
                iconText: "󰅃"
                onClicked: BarConfig.moveWidgetUp(blockCard.widgetId)
            }

            MiniIconButton {
                visible: cardHover.hovered && blockCard.itemIndex < blockCard.panelTotalItems - 1
                iconText: "󰅀"
                onClicked: BarConfig.moveWidgetDown(blockCard.widgetId)
            }

            MiniIconButton {
                visible: cardHover.hovered && blockCard.panelIdx > 0
                iconText: "󰅁"
                onClicked: {
                    if (!BarConfig.moveWidgetSectionLeft(blockCard.widgetId)) {
                        root.showToast("Already maxed out, please move somewhere else", true);
                    }
                }
            }

            MiniIconButton {
                visible: cardHover.hovered && blockCard.panelIdx < BarConfig.panels.length - 1
                iconText: "󰅂"
                onClicked: {
                    if (!BarConfig.moveWidgetSectionRight(blockCard.widgetId)) {
                        root.showToast("Already maxed out, please move somewhere else", true);
                    }
                }
            }

            MiniIconButton {
                visible: cardHover.hovered
                iconText: "󰏘"
                onClicked: {
                    root.selectedColorTargetType = "block";
                    root.selectedColorWidgetId = blockCard.widgetId;
                    root.currentSubTab = 1;
                    root.subTabContentAnimation.restart();
                }
            }

            MiniIconButton {
                iconText: blockCard.isVisible ? "󰈈" : "󰈉"
                onClicked: BarConfig.setWidgetVisible(blockCard.widgetId, !blockCard.isVisible, root.currentBarId())
            }

            MiniIconButton {
                iconText: "󰅖"
                dangerHover: true
                onClicked: BarConfig.removeWidgetFromBar(blockCard.widgetId)
            }
        }
    }

    BlockDragArea {
        root: blockCard.root
        anchors.fill: parent
        anchors.rightMargin: cardBtnRow.width + 10
        widgetId: blockCard.widgetId
        panelIdx: blockCard.panelIdx
        itemIdx: blockCard.itemIndex
        onClickedWithoutDrag: {
            root.selectedColorTargetType = "block";
            root.selectedColorWidgetId = blockCard.widgetId;
        }
    }
}
