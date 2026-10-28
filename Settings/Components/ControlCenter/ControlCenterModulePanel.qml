import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../ControlCenter"
import "../Common"
import ".."

Rectangle {
    id: modPanel
    required property var hostRoot
    required property int panelIndex
    readonly property var modelCards: ControlCenterConfig["panel" + (panelIndex + 1) + "Cards"]
    property alias repeater: blocksRepeater

    function getSectionBadge(cardId) {
        switch (cardId) {
            case "connectivity":
                return ControlCenterConfig.groupedTiles.length + "/4 2x2";
            case "quickSettings":
                return (ControlCenterConfig.isCardVisible("connectivity")
                    ? ControlCenterConfig.ungroupedTiles.length
                    : ControlCenterConfig.enabledTiles.length) + " tiles";
            case "quickSettings2":
                return ControlCenterConfig.secondaryTiles.length + " tiles";
            case "media":
                return ControlCenterConfig.mediaEffectiveBadge + " ↻";
            case "audio":
                return "Out & Mic";
            case "brightness":
                return "Backlight";
            case "systemInfo":
                return "Telemetry";
            case "cava":
                return "Spectrum";
            case "weather":
                return "Forecast";
            case "quickApps":
                return ControlCenterConfig.quickApps.length + " Apps";
            default:
                return "";
        }
    }

    readonly property int itemCount: modelCards.length
    readonly property bool isPanelActive: ControlCenterConfig.panelLayout !== "horizontal" || ControlCenterConfig.panelCount >= panelIndex + 1
    readonly property bool isPanelDropTarget: hostRoot.isDraggingBlock && hostRoot.dragHoverPanelIndex === panelIndex
    readonly property bool isIncomingBlocked: isPanelDropTarget && !hostRoot.isDragCompatibleWithPanel(panelIndex)

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: Math.max(240, colContent.implicitHeight + 20)
    radius: 10
    opacity: isPanelActive ? 1.0 : 0.65
    color: isPanelDropTarget
        ? (isIncomingBlocked ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.08) : hostRoot.withAlpha(hostRoot.theme.accentPrimary, 0.08))
        : hostRoot.theme.bgBase
    border.color: isPanelDropTarget
        ? (isIncomingBlocked ? hostRoot.theme.accentRed : hostRoot.theme.accentPrimary)
        : hostRoot.theme.bgBorder
    border.width: isPanelDropTarget ? 1.5 : 1

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
                    text: "Panel " + (panelIndex + 1)
                    font.family: hostRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: modPanel.isPanelActive ? hostRoot.theme.accentPrimary : hostRoot.theme.textMuted
                }

                Rectangle {
                    implicitWidth: badgeTxt.implicitWidth + 10
                    implicitHeight: 18
                    radius: 9
                    color: hostRoot.withAlpha(hostRoot.theme.textMuted, 0.12)

                    Text {
                        id: badgeTxt
                        anchors.centerIn: parent
                        text: modPanel.isPanelActive
                            ? ("(" + modPanel.itemCount + (modPanel.itemCount === 1 ? " module)" : " modules)"))
                            : "(Inactive)"
                        font.family: hostRoot.font
                        font.pixelSize: 10
                        color: hostRoot.theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                MiniIconButton {
                    visible: ControlCenterConfig.unassignedCards.length > 0
                    iconText: "󰐕"
                    onClicked: {
                        const nextCard = ControlCenterConfig.unassignedCards[0];
                        if (nextCard) {
                            if (ControlCenterConfig.panelCount < panelIndex + 1) ControlCenterConfig.setPanelCount(panelIndex + 1);
                            ControlCenterConfig.moveCardToPanelAt(nextCard.id, panelIndex, modPanel.itemCount);
                            hostRoot.showToast("Added " + nextCard.label + " to Panel " + (panelIndex + 1));
                        }
                    }
                }
            }
        }

        Repeater {
            id: blocksRepeater
            model: modelCards
            delegate: ControlCenterBlockCard {
                root: modPanel.hostRoot
                required property var modelData
                required property int index
                blockId: modelData.id
                blockType: "card"
                blockIcon: modelData.icon !== undefined ? modelData.icon : "󰒓"
                blockLabel: modelData.label || modelData.id
                blockBadge: getSectionBadge(modelData.id)
                badgeClickable: modelData.id === "media"
                panelIdx: panelIndex
                itemIndex: index
                panelTotalItems: modPanel.itemCount
                canMoveUp: index > 0
                canMoveDown: index < modPanel.itemCount - 1
                canMoveLeft: panelIndex > 0
                canMoveRight: panelIndex < 2
                showConfigBtn: true
                onBadgeClicked: {
                    ControlCenterConfig.cycleMediaWidgetStyle();
                    hostRoot.showToast("Media Player mode: " + ControlCenterConfig.mediaEffectiveBadge);
                }
                onMoveUpClicked: ControlCenterConfig.moveCardInPanel(panelIndex, index, index - 1)
                onMoveDownClicked: ControlCenterConfig.moveCardInPanel(panelIndex, index, index + 1)
                onMoveLeftClicked: {
                    ControlCenterConfig.moveCardLeftRight(modelData.id, -1);
                    hostRoot.showToast("Moved " + modelData.label + " to Panel " + panelIndex);
                }
                onMoveRightClicked: {
                    if (panelIndex >= 1 && ControlCenterConfig.panelCount < panelIndex + 2) ControlCenterConfig.setPanelCount(panelIndex + 2);
                    ControlCenterConfig.moveCardLeftRight(modelData.id, 1);
                    hostRoot.showToast("Moved " + modelData.label + " to Panel " + (panelIndex + 2));
                }
                onConfigClicked: {
                    hostRoot.currentSubTab = 1;
                    hostRoot.subTabContentAnimation.restart();
                }
                onRemoveClicked: {
                    ControlCenterConfig.setCardVisible(modelData.id, false);
                    hostRoot.showToast("Removed " + modelData.label + " to Available Modules");
                }
            }
        }

        Rectangle {
            visible: modPanel.itemCount === 0
            Layout.fillWidth: true
            implicitHeight: 70
            radius: 8
            color: modPanel.isPanelDropTarget
                ? hostRoot.withAlpha(hostRoot.theme.accentPrimary, 0.14)
                : "transparent"
            border.color: modPanel.isPanelDropTarget ? hostRoot.theme.accentPrimary : hostRoot.theme.bgBorder
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Panel " + (panelIndex + 1) + " Empty"
                    font.family: hostRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: hostRoot.theme.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Drag any module here or click +"
                    font.family: hostRoot.font
                    font.pixelSize: 10
                    color: hostRoot.theme.textMuted
                }
            }
        }
    }
}
