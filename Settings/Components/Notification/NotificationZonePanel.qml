import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../notifications"
import "../Common"
import ".."

Rectangle {
    id: zonePanel
    required property var hostRoot
    required property int zoneIndex
    readonly property var modelBlocks: NotificationService["zone" + (zoneIndex + 1) + "Blocks"]
    property alias repeater: blocksRepeater

    readonly property string zoneTitle: {
        if (zoneIndex === 0) return "Zone 1 · Header Bar";
        if (zoneIndex === 1) return "Zone 2 · Main Content";
        return "Zone 3 · Footer & Actions";
    }

    readonly property int itemCount: modelBlocks.length
    readonly property bool isZoneDropTarget: hostRoot.isDraggingBlock && hostRoot.dragHoverZoneIndex === zoneIndex

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: Math.max(210, colContent.implicitHeight + 20)
    radius: 10
    color: isZoneDropTarget
        ? hostRoot.withAlpha(hostRoot.theme.accentPrimary, 0.08)
        : hostRoot.theme.bgBase
    border.color: isZoneDropTarget
        ? hostRoot.theme.accentPrimary
        : hostRoot.theme.bgBorder
    border.width: isZoneDropTarget ? 1.5 : 1

    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

    ColumnLayout {
        id: colContent
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
                    text: zonePanel.zoneTitle
                    font.family: hostRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: hostRoot.theme.accentPrimary
                }

                Rectangle {
                    implicitWidth: badgeTxt.implicitWidth + 10
                    implicitHeight: 18
                    radius: 9
                    color: hostRoot.withAlpha(hostRoot.theme.textMuted, 0.12)

                    Text {
                        id: badgeTxt
                        anchors.centerIn: parent
                        text: "(" + zonePanel.itemCount + (zonePanel.itemCount === 1 ? " block)" : " blocks)")
                        font.family: hostRoot.font
                        font.pixelSize: 10
                        color: hostRoot.theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                MiniIconButton {
                    visible: NotificationService.unassignedBlocks.length > 0
                    iconText: "󰐕"
                    onClicked: {
                        const nextBlock = NotificationService.unassignedBlocks[0];
                        if (nextBlock) {
                            NotificationService.moveBlockToZoneAt(nextBlock.id, zoneIndex, zonePanel.itemCount);
                            hostRoot.showToast("Added " + nextBlock.label + " to " + zonePanel.zoneTitle);
                        }
                    }
                }
            }
        }

        Repeater {
            id: blocksRepeater
            model: modelBlocks
            delegate: NotificationBlockCard {
                root: zonePanel.hostRoot
                required property var modelData
                required property int index
                blockId: modelData.id
                blockIcon: modelData.icon !== undefined ? modelData.icon : "󰂚"
                blockLabel: modelData.label || modelData.id
                blockBadge: NotificationService.getBlockBadge(modelData.id)
                badgeClickable: ["icon", "timestamp", "title", "image", "buttons"].indexOf(modelData.id) !== -1
                zoneIdx: zoneIndex
                itemIndex: index
                zoneTotalItems: zonePanel.itemCount
                canMoveUp: index > 0
                canMoveDown: index < zonePanel.itemCount - 1
                canMoveLeft: zoneIndex > 0
                canMoveRight: zoneIndex < 2

                onBadgeClicked: {
                    const msg = NotificationService.cycleBlockQuickOption(modelData.id);
                    if (msg) hostRoot.showToast(msg);
                }
                onMoveUpClicked: NotificationService.moveBlockInZone(zoneIndex, index, index - 1)
                onMoveDownClicked: NotificationService.moveBlockInZone(zoneIndex, index, index + 1)
                onMoveLeftClicked: {
                    NotificationService.moveBlockLeftRight(modelData.id, -1);
                    hostRoot.showToast("Moved " + modelData.label + " to Zone " + zoneIndex);
                }
                onMoveRightClicked: {
                    NotificationService.moveBlockLeftRight(modelData.id, 1);
                    hostRoot.showToast("Moved " + modelData.label + " to Zone " + (zoneIndex + 2));
                }
                onConfigClicked: {
                    hostRoot.selectedInspectorBlock = modelData.id;
                }
                onRemoveClicked: {
                    NotificationService.setBlockVisible(modelData.id, false);
                    hostRoot.showToast("Removed " + modelData.label + " to Available Building Blocks");
                }
            }
        }

        Rectangle {
            visible: zonePanel.itemCount === 0
            Layout.fillWidth: true
            implicitHeight: 68
            radius: 8
            color: zonePanel.isZoneDropTarget
                ? hostRoot.withAlpha(hostRoot.theme.accentPrimary, 0.14)
                : "transparent"
            border.color: zonePanel.isZoneDropTarget ? hostRoot.theme.accentPrimary : hostRoot.theme.bgBorder
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Zone Empty"
                    font.family: hostRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: hostRoot.theme.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Drag any building block here or click +"
                    font.family: hostRoot.font
                    font.pixelSize: 10
                    color: hostRoot.theme.textMuted
                }
            }
        }
    }
}
