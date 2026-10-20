import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../ControlCenter"
import "../Common"
import ".."

Rectangle {
    id: modulesPool
    required property var hostRoot
    readonly property bool isPoolDropTarget: hostRoot.isDraggingBlock && hostRoot.dragHoverPanelIndex === -2 && hostRoot.draggedBlockType === "card"
    readonly property int totalAvailCount: ControlCenterConfig.unassignedCards.length
    Layout.fillWidth: true
    implicitHeight: availPoolCol.implicitHeight + 20
    radius: 10
    color: isPoolDropTarget
        ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.12)
        : hostRoot.theme.bgBase
    border.color: isPoolDropTarget
        ? hostRoot.theme.accentRed
        : hostRoot.theme.bgBorder
    border.width: isPoolDropTarget ? 1.5 : 1

    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

    ColumnLayout {
        id: availPoolCol
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
                text: "Available Modules"
                font.family: hostRoot.font
                font.pixelSize: 11
                font.bold: true
                color: modulesPool.isPoolDropTarget ? hostRoot.theme.accentRed : hostRoot.theme.accentPrimary
            }

            Text {
                text: "(" + modulesPool.totalAvailCount + " available)"
                font.family: hostRoot.font
                font.pixelSize: 11
                color: hostRoot.theme.textMuted
            }

            Item { Layout.fillWidth: true }

            Text {
                text: modulesPool.isPoolDropTarget
                    ? "Release here to remove module from Control Center"
                    : (modulesPool.totalAvailCount > 0
                        ? "Drag a module into Panel 1, Panel 2, or Panel 3 above, or click to add"
                        : "All 10 modules are placed in Panels 1–3 (drag here or click ✕ to remove)")
                font.family: hostRoot.font
                font.pixelSize: 10
                font.bold: modulesPool.isPoolDropTarget
                color: modulesPool.isPoolDropTarget ? hostRoot.theme.accentRed : hostRoot.theme.textMuted
            }
        }

        Flow {
            visible: modulesPool.totalAvailCount > 0
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: ControlCenterConfig.unassignedCards
                delegate: Rectangle {
                    id: secPoolChip
                    required property var modelData
                    readonly property bool isBeingDragged: hostRoot.isDraggingBlock
                        && hostRoot.draggedBlockType === "card"
                        && hostRoot.draggedBlockId === secPoolChip.modelData.id

                    implicitWidth: secPoolRow.implicitWidth + 22
                    implicitHeight: 34
                    width: implicitWidth
                    height: implicitHeight
                    radius: 8
                    scale: isBeingDragged ? 0.94 : (secPoolHover.hovered ? 1.02 : 1.0)
                    opacity: isBeingDragged ? 0.35 : 1.0
                    color: secPoolHover.hovered ? hostRoot.theme.bgHover : hostRoot.theme.bgSurface
                    border.color: secPoolHover.hovered ? hostRoot.theme.accentPrimary : hostRoot.theme.bgBorder
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    HoverHandler { id: secPoolHover }

                    Row {
                        id: secPoolRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            visible: (secPoolChip.modelData.icon ?? "") !== ""
                            width: 16
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: secPoolChip.modelData.icon || ""
                            font.family: hostRoot.font
                            font.pixelSize: 13
                            color: hostRoot.theme.accentPrimary
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: secPoolChip.modelData.label
                            font.family: hostRoot.font
                            font.pixelSize: 11
                            font.bold: true
                            color: hostRoot.theme.textPrimary
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: secTagTxt.implicitWidth + 8
                            implicitHeight: 16
                            radius: 8
                            color: hostRoot.withAlpha(hostRoot.theme.accentPrimary, 0.14)

                            Text {
                                id: secTagTxt
                                anchors.centerIn: parent
                                text: "Module"
                                font.family: hostRoot.font
                                font.pixelSize: 9
                                font.bold: true
                                color: hostRoot.theme.accentPrimary
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰐕"
                            font.family: hostRoot.font
                            font.pixelSize: 10
                            color: secPoolHover.hovered ? hostRoot.theme.accentPrimary : hostRoot.theme.textMuted
                            opacity: secPoolHover.hovered ? 1.0 : 0.6
                        }
                    }

                    MouseArea {
                        id: secPoolDragArea
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
                            const pt = secPoolDragArea.mapToItem(hostRoot, mouse.x, mouse.y);
                            if (!dragStarted && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
                                dragStarted = true;
                                hostRoot.startBlockDrag(
                                    secPoolChip.modelData.id,
                                    "card",
                                    secPoolChip.modelData.label,
                                    secPoolChip.modelData.icon ?? "",
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
                                const pt = secPoolDragArea.mapToItem(hostRoot, mouse.x, mouse.y);
                                hostRoot.updateBlockDragHover(pt.x, pt.y);
                                hostRoot.finishBlockDrag();
                                dragStarted = false;
                            } else {
                                ControlCenterConfig.setCardVisible(secPoolChip.modelData.id, true);
                                hostRoot.showToast("Added " + secPoolChip.modelData.label + " to Control Center");
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
