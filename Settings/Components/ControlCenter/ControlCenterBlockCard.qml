import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../ControlCenter"
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    id: blockCard
    property string blockId: ""
    property string blockType: "tile" // "card" or "tile"
    property string blockIcon: "󰒓"
    property string blockLabel: ""
    property string blockBadge: ""
    property int panelIdx: 0          // 0 = Flyout Sections, 1 = 2x2 Connectivity Group, 2 = Standalone Tiles
    property int itemIndex: 0
    property int panelTotalItems: 1
    property bool canMoveUp: itemIndex > 0
    property bool canMoveDown: itemIndex < panelTotalItems - 1
    property bool canMoveLeft: false
    property bool canMoveRight: false
    property bool showConfigBtn: false
    property bool badgeClickable: false

    signal moveUpClicked()
    signal moveDownClicked()
    signal moveLeftClicked()
    signal moveRightClicked()
    signal configClicked()
    signal badgeClicked()
    signal removeClicked()

    readonly property bool isBeingDragged: root.isDraggingBlock
        && root.draggedBlockId === blockCard.blockId
        && root.draggedBlockType === blockCard.blockType
    readonly property bool isTargetPanel: root.isDraggingBlock
        && root.dragHoverPanelIndex === blockCard.panelIdx
        && root.isDragCompatibleWithPanel(blockCard.panelIdx)
        && !(root.draggedBlockId === blockCard.blockId && root.draggedBlockType === blockCard.blockType)
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
        : (cardHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder)
    border.width: isDropTarget ? 1.5 : 1
    opacity: isBeingDragged ? 0.35 : 1.0

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
            visible: blockCard.blockIcon !== ""
            text: blockCard.blockIcon
            font.family: root.font
            font.pixelSize: 13
            color: root.theme.accentPrimary
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredWidth: 18
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: blockCard.blockLabel
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.textPrimary
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            id: badgeRect
            z: 2
            visible: blockCard.blockBadge !== "" && (blockCard.badgeClickable || !cardHover.hovered)
            implicitWidth: badgeTxt.implicitWidth + 10
            implicitHeight: 18
            radius: 9
            color: blockCard.badgeClickable && badgeMouse.containsMouse
                ? root.withAlpha(root.theme.accentPrimary, 0.25)
                : root.withAlpha(root.theme.accentPrimary, 0.12)
            border.color: blockCard.badgeClickable ? root.withAlpha(root.theme.accentPrimary, 0.45) : "transparent"
            border.width: blockCard.badgeClickable ? 1 : 0
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: badgeTxt
                anchors.centerIn: parent
                text: blockCard.blockBadge
                font.family: root.font
                font.pixelSize: 9
                font.bold: true
                color: root.theme.accentPrimary
            }

            MouseArea {
                id: badgeMouse
                anchors.fill: parent
                enabled: blockCard.badgeClickable
                hoverEnabled: blockCard.badgeClickable
                cursorShape: blockCard.badgeClickable ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: blockCard.badgeClicked()
            }
        }

        RowLayout {
            id: cardBtnRow
            z: 2
            spacing: 3
            Layout.alignment: Qt.AlignVCenter

            MiniIconButton {
                visible: cardHover.hovered && blockCard.canMoveUp
                iconText: "󰅃"
                onClicked: blockCard.moveUpClicked()
            }

            MiniIconButton {
                visible: cardHover.hovered && blockCard.canMoveDown
                iconText: "󰅀"
                onClicked: blockCard.moveDownClicked()
            }

            MiniIconButton {
                visible: cardHover.hovered && blockCard.canMoveLeft
                iconText: "󰅁"
                onClicked: blockCard.moveLeftClicked()
            }

            MiniIconButton {
                visible: cardHover.hovered && blockCard.canMoveRight
                iconText: "󰅂"
                onClicked: blockCard.moveRightClicked()
            }

            MiniIconButton {
                visible: cardHover.hovered && blockCard.showConfigBtn
                iconText: "󰒓"
                onClicked: blockCard.configClicked()
            }

            MiniIconButton {
                iconText: "󰅖"
                dangerHover: true
                onClicked: blockCard.removeClicked()
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.rightMargin: cardBtnRow.width + 10
        preventStealing: true
        cursorShape: root.isDraggingBlock ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property real pressX: 0
        property real pressY: 0
        property bool dragStarted: false

        onPressed: (mouse) => {
            pressX = mouse.x;
            pressY = mouse.y;
            dragStarted = false;
        }

        onPositionChanged: (mouse) => {
            if (!pressed) return;
            const pt = dragArea.mapToItem(root, mouse.x, mouse.y);
            if (!dragStarted && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
                dragStarted = true;
                root.startBlockDrag(
                    blockCard.blockId,
                    blockCard.blockType,
                    blockCard.blockLabel,
                    blockCard.blockIcon,
                    blockCard.panelIdx,
                    blockCard.itemIndex,
                    pt.x,
                    pt.y
                );
            } else if (dragStarted) {
                root.updateBlockDragHover(pt.x, pt.y);
            }
        }

        onReleased: (mouse) => {
            if (dragStarted) {
                const pt = dragArea.mapToItem(root, mouse.x, mouse.y);
                root.updateBlockDragHover(pt.x, pt.y);
                root.finishBlockDrag();
                dragStarted = false;
            }
        }

        onCanceled: {
            if (dragStarted) {
                root.finishBlockDrag();
                dragStarted = false;
            }
        }
    }
}

