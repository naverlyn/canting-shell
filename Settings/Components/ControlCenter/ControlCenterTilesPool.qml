import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../ControlCenter"
import "../Common"
import ".."

Rectangle {
    id: tilesPool
    required property var hostRoot
    readonly property bool isPoolDropTarget: hostRoot.isDraggingBlock && hostRoot.dragHoverPanelIndex === -3 && hostRoot.draggedBlockType === "tile"
    readonly property int totalAvailCount: ControlCenterConfig.unassignedTiles.length
    Layout.fillWidth: true
    implicitHeight: availTilesPoolCol.implicitHeight + 20
    radius: 10
    color: isPoolDropTarget
        ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.12)
        : hostRoot.theme.bgBase
    border.color: isPoolDropTarget
        ? hostRoot.theme.accentRed
        : hostRoot.theme.bgBorder
    border.width: isPoolDropTarget ? 1.5 : 1

    ColumnLayout {
        id: availTilesPoolCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Available Quick Tiles"
                font.family: hostRoot.font
                font.pixelSize: 11
                font.bold: true
                color: tilesPool.isPoolDropTarget ? hostRoot.theme.accentRed : hostRoot.theme.accentPrimary
            }

            Text {
                text: "(" + tilesPool.totalAvailCount + " available)"
                font.family: hostRoot.font
                font.pixelSize: 11
                color: hostRoot.theme.textMuted
            }

            Item { Layout.fillWidth: true }

            Text {
                text: tilesPool.isPoolDropTarget
                    ? "Release here to remove tile"
                    : (tilesPool.totalAvailCount > 0
                        ? "Drag into Connectivity (2x2) or Quick Tiles above, or click to add"
                        : "All 8 quick tiles are active (drag here or click ✕ to remove)")
                font.family: hostRoot.font
                font.pixelSize: 10
                font.bold: tilesPool.isPoolDropTarget
                color: tilesPool.isPoolDropTarget ? hostRoot.theme.accentRed : hostRoot.theme.textMuted
            }
        }

        Flow {
            visible: tilesPool.totalAvailCount > 0
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: ControlCenterConfig.unassignedTiles
                delegate: Rectangle {
                    id: tilePoolChip
                    required property var modelData
                    readonly property bool isBeingDragged: hostRoot.isDraggingBlock
                        && hostRoot.draggedBlockType === "tile"
                        && hostRoot.draggedBlockId === tilePoolChip.modelData.id

                    implicitWidth: tilePoolRow.implicitWidth + 22
                    implicitHeight: 34
                    width: implicitWidth
                    height: implicitHeight
                    radius: 8
                    scale: isBeingDragged ? 0.94 : (tilePoolHover.hovered ? 1.02 : 1.0)
                    opacity: isBeingDragged ? 0.35 : 1.0
                    color: tilePoolHover.hovered ? hostRoot.theme.bgHover : hostRoot.theme.bgSurface
                    border.color: tilePoolHover.hovered ? hostRoot.theme.accentPrimary : hostRoot.theme.bgBorder
                    border.width: 1

                    HoverHandler { id: tilePoolHover }

                    Row {
                        id: tilePoolRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            width: 16
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: tilePoolChip.modelData.icon || "󰒓"
                            font.family: hostRoot.font
                            font.pixelSize: 13
                            color: hostRoot.theme.accentPrimary
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tilePoolChip.modelData.label
                            font.family: hostRoot.font
                            font.pixelSize: 11
                            font.bold: true
                            color: hostRoot.theme.textPrimary
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰐕"
                            font.family: hostRoot.font
                            font.pixelSize: 10
                            color: tilePoolHover.hovered ? hostRoot.theme.accentPrimary : hostRoot.theme.textMuted
                            opacity: tilePoolHover.hovered ? 1.0 : 0.6
                        }
                    }

                    MouseArea {
                        id: tilePoolDragArea
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
                            const pt = tilePoolDragArea.mapToItem(hostRoot, mouse.x, mouse.y);
                            if (!dragStarted && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
                                dragStarted = true;
                                hostRoot.startBlockDrag(
                                    tilePoolChip.modelData.id,
                                    "tile",
                                    tilePoolChip.modelData.label,
                                    tilePoolChip.modelData.icon || "󰒓",
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
                                const pt = tilePoolDragArea.mapToItem(hostRoot, mouse.x, mouse.y);
                                hostRoot.updateBlockDragHover(pt.x, pt.y);
                                hostRoot.finishBlockDrag();
                                dragStarted = false;
                            } else {
                                ControlCenterConfig.addTile(tilePoolChip.modelData.id);
                                hostRoot.showToast("Added " + tilePoolChip.modelData.label + " to Quick Tiles");
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
        }
    }
}
