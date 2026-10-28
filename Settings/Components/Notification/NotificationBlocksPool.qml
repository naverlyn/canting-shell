import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../notifications"
import "../Common"
import ".."

Rectangle {
    id: availPoolCard
    required property var hostRoot
    readonly property bool isPoolDropTarget: hostRoot.isDraggingBlock
        && hostRoot.dragHoverZoneIndex === -2
        && hostRoot.dragSourceZoneIndex >= 0

    Layout.fillWidth: true
    implicitHeight: poolInnerCol.implicitHeight + 24
    radius: 10
    color: isPoolDropTarget
        ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.08)
        : hostRoot.theme.bgBase
    border.color: isPoolDropTarget
        ? hostRoot.theme.accentRed
        : hostRoot.theme.bgBorder
    border.width: isPoolDropTarget ? 1.5 : 1

    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

    ColumnLayout {
        id: poolInnerCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: availPoolCard.isPoolDropTarget
                    ? "󰩺  Drop Here to Remove Building Block from Toast"
                    : "Available Building Blocks (" + NotificationService.unassignedBlocks.length + ")"
                font.family: hostRoot.font
                font.pixelSize: 12
                font.bold: true
                color: availPoolCard.isPoolDropTarget
                    ? hostRoot.theme.accentRed
                    : hostRoot.theme.textPrimary
            }

            Text {
                visible: !availPoolCard.isPoolDropTarget
                text: "·  Drag any block into Header, Content, or Footer — or click + to restore"
                font.family: hostRoot.font
                font.pixelSize: 11
                color: hostRoot.theme.textMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Flow {
            id: poolFlow
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: NotificationService.unassignedBlocks

                delegate: Rectangle {
                    id: poolChip
                    required property var modelData

                    readonly property bool isBeingDragged: hostRoot.isDraggingBlock
                        && hostRoot.draggedBlockId === modelData.id

                    implicitWidth: chipRow.implicitWidth + 20
                    height: 36
                    radius: 8
                    opacity: isBeingDragged ? 0.35 : 1.0
                    scale: isBeingDragged ? 0.95 : (chipHover.hovered ? 1.03 : 1.0)
                    color: chipHover.hovered ? hostRoot.theme.bgHover : hostRoot.theme.bgSurface
                    border.color: chipHover.hovered ? hostRoot.theme.accentPrimary : hostRoot.theme.bgBorder
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 130 } }

                    HoverHandler { id: chipHover }

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰍜"
                            font.family: hostRoot.font
                            font.pixelSize: 10
                            color: hostRoot.theme.textMuted
                            opacity: chipHover.hovered ? 0.9 : 0.45
                        }

                        Text {
                            visible: poolChip.modelData.icon !== ""
                            text: poolChip.modelData.icon
                            font.family: hostRoot.font
                            font.pixelSize: 13
                            color: hostRoot.theme.accentPrimary
                        }

                        Text {
                            text: poolChip.modelData.label
                            font.family: hostRoot.font
                            font.pixelSize: 11
                            font.bold: true
                            color: hostRoot.theme.textPrimary
                        }

                        Rectangle {
                            id: quickAddBtn
                            width: 20
                            height: 20
                            radius: 5
                            color: addHover.hovered ? hostRoot.theme.accentPrimary : hostRoot.theme.bgSelected
                            Behavior on color { ColorAnimation { duration: 120 } }

                            HoverHandler { id: addHover }

                            Text {
                                anchors.centerIn: parent
                                text: "󰐕"
                                font.family: hostRoot.font
                                font.pixelSize: 10
                                color: addHover.hovered ? hostRoot.theme.bgBase : hostRoot.theme.accentPrimary
                            }
                        }
                    }

                    MouseArea {
                        id: poolDragArea
                        anchors.fill: parent
                        preventStealing: true
                        cursorShape: hostRoot.isDraggingBlock ? Qt.ClosedHandCursor : Qt.PointingHandCursor

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
                            const pt = poolDragArea.mapToItem(hostRoot, mouse.x, mouse.y);
                            if (!dragStarted && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
                                dragStarted = true;
                                hostRoot.startBlockDrag(
                                    poolChip.modelData.id,
                                    poolChip.modelData.label,
                                    poolChip.modelData.icon,
                                    -1,
                                    -1,
                                    pt.x,
                                    pt.y
                                );
                            } else if (dragStarted) {
                                hostRoot.updateBlockDragHover(pt.x, pt.y);
                            }
                        }

                        onReleased: (mouse) => {
                            if (dragStarted) {
                                const pt = poolDragArea.mapToItem(hostRoot, mouse.x, mouse.y);
                                hostRoot.updateBlockDragHover(pt.x, pt.y);
                                hostRoot.finishBlockDrag();
                                dragStarted = false;
                            } else {
                                NotificationService.setBlockVisible(poolChip.modelData.id, true);
                                hostRoot.showToast("Added " + poolChip.modelData.label + " to Notification Toast");
                            }
                        }

                        onCanceled: {
                            if (dragStarted) {
                                hostRoot.finishBlockDrag();
                                dragStarted = false;
                            }
                        }
                    }
                }
            }

            Text {
                visible: NotificationService.unassignedBlocks.length === 0
                text: "All 9 notification building blocks are currently active on the toast card."
                font.family: hostRoot.font
                font.pixelSize: 11
                color: hostRoot.theme.textMuted
            }
        }
    }
}
