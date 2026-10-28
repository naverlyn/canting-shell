import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../ControlCenter"
import "../Common"
import ".."

Rectangle {
    id: connPanel
    required property var hostRoot
    property alias repeater: groupBlocksRepeater
    readonly property int itemCount: ControlCenterConfig.groupedTiles.length
    readonly property bool isMaxedOut: itemCount >= 4
    readonly property bool isPanelDropTarget: hostRoot.isDraggingBlock && hostRoot.dragHoverPanelIndex === 3
    readonly property bool isIncomingBlocked: isPanelDropTarget && !hostRoot.isDragCompatibleWithPanel(3)

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: Math.max(220, groupColContent.implicitHeight + 20)
    radius: 10
    color: isPanelDropTarget
        ? (isIncomingBlocked ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.08) : hostRoot.withAlpha(hostRoot.theme.accentPrimary, 0.08))
        : hostRoot.theme.bgBase
    border.color: isPanelDropTarget
        ? (isIncomingBlocked ? hostRoot.theme.accentRed : hostRoot.theme.accentPrimary)
        : (isMaxedOut ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.35) : hostRoot.theme.bgBorder)
    border.width: isPanelDropTarget ? 1.5 : 1

    ColumnLayout {
        id: groupColContent
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
                    text: "Connectivity (2x2)"
                    font.family: hostRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: connPanel.isMaxedOut ? hostRoot.theme.accentRed : hostRoot.theme.accentPrimary
                }

                Rectangle {
                    implicitWidth: grpBadgeTxt.implicitWidth + 10
                    implicitHeight: 18
                    radius: 9
                    color: connPanel.isMaxedOut
                        ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.18)
                        : hostRoot.withAlpha(hostRoot.theme.textMuted, 0.12)

                    Text {
                        id: grpBadgeTxt
                        anchors.centerIn: parent
                        text: connPanel.isMaxedOut ? "MAX (4/4)" : ("(" + connPanel.itemCount + "/4)")
                        font.family: hostRoot.font
                        font.pixelSize: 10
                        font.bold: connPanel.isMaxedOut
                        color: connPanel.isMaxedOut ? hostRoot.theme.accentRed : hostRoot.theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                MiniIconButton {
                    visible: !connPanel.isMaxedOut && (ControlCenterConfig.ungroupedTiles.length > 0 || ControlCenterConfig.unassignedTiles.length > 0)
                    iconText: "󰐕"
                    onClicked: {
                        const candidate = ControlCenterConfig.unassignedTiles.length > 0
                            ? ControlCenterConfig.unassignedTiles[0]
                            : ControlCenterConfig.ungroupedTiles[0];
                        if (candidate && ControlCenterConfig.addTileToGroup(candidate.id)) {
                            hostRoot.showToast("Added " + candidate.label + " to Connectivity (2x2)");
                        }
                    }
                }
            }
        }

        Repeater {
            id: groupBlocksRepeater
            model: ControlCenterConfig.groupedTiles
            delegate: ControlCenterBlockCard {
                root: connPanel.hostRoot
                required property var modelData
                required property int index
                blockId: modelData.id
                blockType: "tile"
                blockIcon: modelData.icon || "󰒓"
                blockLabel: modelData.label || modelData.id
                blockBadge: "2x2"
                panelIdx: 3
                itemIndex: index
                panelTotalItems: connPanel.itemCount
                canMoveUp: index > 0
                canMoveDown: index < connPanel.itemCount - 1
                canMoveLeft: false
                canMoveRight: true
                showConfigBtn: false
                onMoveUpClicked: ControlCenterConfig.moveGroupedTile(index, index - 1)
                onMoveDownClicked: ControlCenterConfig.moveGroupedTile(index, index + 1)
                onMoveRightClicked: {
                    ControlCenterConfig.removeTileFromGroup(modelData.id);
                    hostRoot.showToast("Moved " + modelData.label + " to Quick Tiles");
                }
                onRemoveClicked: {
                    ControlCenterConfig.removeTileToPool(modelData.id);
                    hostRoot.showToast("Removed " + modelData.label + " to Available Tiles");
                }
            }
        }

        Rectangle {
            visible: connPanel.itemCount === 0
            Layout.fillWidth: true
            implicitHeight: 70
            radius: 8
            color: connPanel.isPanelDropTarget
                ? hostRoot.withAlpha(hostRoot.theme.accentPrimary, 0.14)
                : "transparent"
            border.color: connPanel.isPanelDropTarget ? hostRoot.theme.accentPrimary : hostRoot.theme.bgBorder
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Empty Connectivity (2x2)"
                    font.family: hostRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: hostRoot.theme.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Drag up to 4 quick tiles here"
                    font.family: hostRoot.font
                    font.pixelSize: 10
                    color: hostRoot.theme.textMuted
                }
            }
        }
    }
}
