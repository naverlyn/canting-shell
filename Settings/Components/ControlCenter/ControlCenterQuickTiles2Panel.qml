import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../ControlCenter"
import "../Common"
import ".."

Rectangle {
    id: quick2Panel
    required property var hostRoot
    property alias repeater: secondaryBlocksRepeater
    readonly property var activeTileList: ControlCenterConfig.secondaryTiles
    readonly property int itemCount: activeTileList.length
    readonly property bool isPanelDropTarget: hostRoot.isDraggingBlock && hostRoot.dragHoverPanelIndex === 5
    readonly property bool isIncomingBlocked: isPanelDropTarget && !hostRoot.isDragCompatibleWithPanel(5)

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: Math.max(220, secondaryColContent.implicitHeight + 20)
    radius: 10
    color: isPanelDropTarget
        ? (isIncomingBlocked ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.08) : hostRoot.withAlpha(hostRoot.theme.accentPrimary, 0.08))
        : hostRoot.theme.bgBase
    border.color: isPanelDropTarget
        ? (isIncomingBlocked ? hostRoot.theme.accentRed : hostRoot.theme.accentPrimary)
        : hostRoot.theme.bgBorder
    border.width: isPanelDropTarget ? 1.5 : 1

    ColumnLayout {
        id: secondaryColContent
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
                    text: "Quick Tiles 2"
                    font.family: hostRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: hostRoot.theme.accentPrimary
                }

                Rectangle {
                    implicitWidth: secTileBadgeTxt.implicitWidth + 10
                    implicitHeight: 18
                    radius: 9
                    color: hostRoot.withAlpha(hostRoot.theme.textMuted, 0.12)

                    Text {
                        id: secTileBadgeTxt
                        anchors.centerIn: parent
                        text: "(" + quick2Panel.itemCount + " tiles)"
                        font.family: hostRoot.font
                        font.pixelSize: 10
                        color: hostRoot.theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                MiniIconButton {
                    iconText: "󰐕"
                    onClicked: {
                        for (let i = 0; i < ControlCenterConfig.allTileDefs.length; i++) {
                            const t = ControlCenterConfig.allTileDefs[i];
                            if ((ControlCenterConfig.secondaryTileIds || []).indexOf(t.id) === -1) {
                                ControlCenterConfig.addTileToSecondary(t.id);
                                hostRoot.showToast("Added " + t.label + " to Quick Tiles 2");
                                break;
                            }
                        }
                    }
                }
            }
        }

        Repeater {
            id: secondaryBlocksRepeater
            model: quick2Panel.activeTileList
            delegate: ControlCenterBlockCard {
                root: quick2Panel.hostRoot
                required property var modelData
                required property int index
                blockId: modelData.id
                blockType: "tile"
                blockIcon: modelData.icon || "󰒓"
                blockLabel: modelData.label || modelData.id
                blockBadge: "Grid 2"
                panelIdx: 5
                itemIndex: index
                panelTotalItems: quick2Panel.itemCount
                canMoveUp: index > 0
                canMoveDown: index < quick2Panel.itemCount - 1
                canMoveLeft: true
                canMoveRight: false
                showConfigBtn: false
                onMoveUpClicked: ControlCenterConfig.moveSecondaryTile(index, index - 1)
                onMoveDownClicked: ControlCenterConfig.moveSecondaryTile(index, index + 1)
                onMoveLeftClicked: {
                    ControlCenterConfig.removeTileFromSecondary(modelData.id);
                    ControlCenterConfig.addTile(modelData.id);
                    hostRoot.showToast("Moved " + modelData.label + " to Quick Tiles");
                }
                onRemoveClicked: {
                    ControlCenterConfig.removeTileFromSecondary(modelData.id);
                    hostRoot.showToast("Removed " + modelData.label + " from Quick Tiles 2");
                }
            }
        }

        Rectangle {
            visible: quick2Panel.itemCount === 0
            Layout.fillWidth: true
            implicitHeight: 70
            radius: 8
            color: quick2Panel.isPanelDropTarget
                ? hostRoot.withAlpha(hostRoot.theme.accentPrimary, 0.14)
                : "transparent"
            border.color: quick2Panel.isPanelDropTarget ? hostRoot.theme.accentPrimary : hostRoot.theme.bgBorder
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No Quick Tiles 2"
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
