import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../ControlCenter"
import "../Common"
import ".."

Rectangle {
    id: quickPanel
    required property var hostRoot
    property alias repeater: standaloneBlocksRepeater
    readonly property var activeTileList: ControlCenterConfig.ungroupedTiles
    readonly property int itemCount: activeTileList.length
    readonly property bool isPanelDropTarget: hostRoot.isDraggingBlock && hostRoot.dragHoverPanelIndex === 4
    readonly property bool isIncomingBlocked: isPanelDropTarget && !hostRoot.isDragCompatibleWithPanel(4)

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: Math.max(220, standaloneColContent.implicitHeight + 20)
    radius: 10
    color: isPanelDropTarget
        ? (isIncomingBlocked ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.08) : hostRoot.withAlpha(hostRoot.theme.accentPrimary, 0.08))
        : hostRoot.theme.bgBase
    border.color: isPanelDropTarget
        ? (isIncomingBlocked ? hostRoot.theme.accentRed : hostRoot.theme.accentPrimary)
        : hostRoot.theme.bgBorder
    border.width: isPanelDropTarget ? 1.5 : 1

    ColumnLayout {
        id: standaloneColContent
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: 7
            color: hostRoot.theme.bgSelected

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 4
                spacing: 6

                Text {
                    text: "Quick Tiles"
                    font.family: hostRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: hostRoot.theme.accentPrimary
                }

                Rectangle {
                    implicitWidth: stdBadgeTxt.implicitWidth + 10
                    implicitHeight: 18
                    radius: 9
                    color: hostRoot.withAlpha(hostRoot.theme.textMuted, 0.12)

                    Text {
                        id: stdBadgeTxt
                        anchors.centerIn: parent
                        text: "(" + quickPanel.itemCount + " tiles)"
                        font.family: hostRoot.font
                        font.pixelSize: 10
                        color: hostRoot.theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                MiniIconButton {
                    visible: ControlCenterConfig.unassignedTiles.length > 0
                    iconText: "󰐕"
                    onClicked: {
                        const nextTile = ControlCenterConfig.unassignedTiles[0];
                        if (nextTile) {
                            ControlCenterConfig.addTile(nextTile.id);
                            hostRoot.showToast("Added " + nextTile.label + " to Quick Tiles");
                        }
                    }
                }
            }
        }

        Repeater {
            id: standaloneBlocksRepeater
            model: quickPanel.activeTileList
            delegate: ControlCenterBlockCard {
                root: quickPanel.hostRoot
                required property var modelData
                required property int index
                blockId: modelData.id
                blockType: "tile"
                blockIcon: modelData.icon || "󰒓"
                blockLabel: modelData.label || modelData.id
                blockBadge: ""
                panelIdx: 4
                itemIndex: index
                panelTotalItems: quickPanel.itemCount
                canMoveUp: index > 0
                canMoveDown: index < quickPanel.itemCount - 1
                canMoveLeft: ControlCenterConfig.groupedTiles.length < 4
                canMoveRight: true
                showConfigBtn: false
                onMoveUpClicked: ControlCenterConfig.moveUngroupedTile(index, index - 1)
                onMoveDownClicked: ControlCenterConfig.moveUngroupedTile(index, index + 1)
                onMoveLeftClicked: {
                    if (ControlCenterConfig.addTileToGroup(modelData.id)) {
                        hostRoot.showToast("Moved " + modelData.label + " to Connectivity (2x2)");
                    } else {
                        hostRoot.showToast("Connectivity (2x2) is full (4/4)", true);
                    }
                }
                onMoveRightClicked: {
                    ControlCenterConfig.addTileToSecondary(modelData.id);
                    hostRoot.showToast("Added " + modelData.label + " to Quick Tiles 2");
                }
                onRemoveClicked: {
                    ControlCenterConfig.removeTileToPool(modelData.id);
                    hostRoot.showToast("Removed " + modelData.label + " to Available Tiles");
                }
            }
        }

        Rectangle {
            visible: quickPanel.itemCount === 0
            Layout.fillWidth: true
            implicitHeight: 70
            radius: 8
            color: quickPanel.isPanelDropTarget
                ? hostRoot.withAlpha(hostRoot.theme.accentPrimary, 0.14)
                : "transparent"
            border.color: quickPanel.isPanelDropTarget ? hostRoot.theme.accentPrimary : hostRoot.theme.bgBorder
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No Quick Tiles"
                    font.family: hostRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: hostRoot.theme.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Drag any quick tile here or click +"
                    font.family: hostRoot.font
                    font.pixelSize: 10
                    color: hostRoot.theme.textMuted
                }
            }
        }
    }
}
