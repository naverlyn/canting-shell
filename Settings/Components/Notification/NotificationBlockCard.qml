import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../notifications"
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    id: blockCard
    property string blockId: ""
    property string blockIcon: "󰂚"
    property string blockLabel: ""
    property string blockBadge: ""
    property int zoneIdx: 0
    property int itemIndex: 0
    property int zoneTotalItems: 1
    property bool canMoveUp: itemIndex > 0
    property bool canMoveDown: itemIndex < zoneTotalItems - 1
    property bool canMoveLeft: false
    property bool canMoveRight: false
    property bool badgeClickable: false

    signal moveUpClicked()
    signal moveDownClicked()
    signal moveLeftClicked()
    signal moveRightClicked()
    signal configClicked()
    signal badgeClicked()
    signal removeClicked()

    readonly property bool isSelectedInInspector: root.selectedInspectorBlock === blockCard.blockId
    readonly property bool isBeingDragged: root.isDraggingBlock
        && root.draggedBlockId === blockCard.blockId
    readonly property bool isTargetZone: root.isDraggingBlock
        && root.dragHoverZoneIndex === blockCard.zoneIdx
        && root.draggedBlockId !== blockCard.blockId
    readonly property bool isBeforeThis: isTargetZone && root.dragHoverItemIndex === blockCard.itemIndex
    readonly property bool isAfterThis: isTargetZone && (
        (root.dragHoverItemIndex === blockCard.itemIndex + 1) ||
        (blockCard.itemIndex === blockCard.zoneTotalItems - 1 && root.dragHoverItemIndex >= blockCard.zoneTotalItems)
    )
    readonly property bool isDropTarget: isBeforeThis || isAfterThis

    Layout.fillWidth: true
    height: 38
    radius: 8
    scale: isBeingDragged ? 0.96 : 1.0
    color: isDropTarget || isSelectedInInspector
        ? root.theme.bgSelected
        : (cardHover.hovered ? root.theme.bgHover : root.theme.bgBase)
    border.color: isDropTarget || isBeingDragged || isSelectedInInspector
        ? root.theme.accentPrimary
        : (cardHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder)
    border.width: (isDropTarget || isSelectedInInspector) ? 1.5 : 1
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
            font.pixelSize: Style.px(11)
            color: cardHover.hovered ? root.theme.textSecondary : root.theme.textMuted
            opacity: cardHover.hovered ? 0.85 : 0.35
            Layout.preferredWidth: 12
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: blockCard.blockIcon !== ""
            text: blockCard.blockIcon
            font.family: root.font
            font.pixelSize: Style.px(13)
            color: root.theme.accentPrimary
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredWidth: 18
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: blockCard.blockLabel
            font.family: root.font
            font.pixelSize: Style.px(11)
            font.bold: true
            color: root.theme.textPrimary
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
                opacity: (cardHover.hovered || blockCard.isSelectedInInspector) ? 1.0 : 0.0
                visible: opacity > 0.01
                iconText: "󰒓"
                onClicked: blockCard.configClicked()

                Behavior on opacity { NumberAnimation { duration: 120 } }
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
                    blockCard.blockLabel,
                    blockCard.blockIcon,
                    blockCard.zoneIdx,
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
            } else {
                blockCard.configClicked();
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
