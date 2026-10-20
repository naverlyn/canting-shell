/*
 * ControlCenterSettings.qml
 *
 * Configures Control Center modular sections, quick toggle tiles,
 * 2x2 connectivity group, panel dimensions, and media player appearance.
 * Styled to match BarSettings.qml with sub-tabs, building block cards, and drag-and-drop.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../bar"
import "../../ControlCenter"
import ".."
import "./Common"
import "./Bar"
import "./ControlCenter"

Item {
    id: root
    property var theme
    property string font: "Hack Nerd Font"

    property int currentSubTab: 0
    property alias subTabContentAnimation: subTabContentAnim

    /* Drag & Drop State for Building Blocks */
    property bool isDraggingBlock: false
    property string draggedBlockId: ""
    property string draggedBlockType: "card" // "card" or "tile"
    property string draggedBlockLabel: ""
    property string draggedBlockIcon: "󰒓"
    property int dragSourcePanelIndex: -1    // -1 = pool, 0 = Panel 1, 1 = Panel 2, 2 = Panel 3, 3 = 2x2 Group, 4 = Standalone Tiles
    property int dragSourceItemIndex: -1
    property real dragMouseX: 0
    property real dragMouseY: 0
    property int dragHoverPanelIndex: -1     // -2 = card pool, -3 = tile pool, -1 = none, 0..2 = Panels 1..3, 3 = 2x2 group, 4 = standalone tiles
    property int dragHoverItemIndex: -1

    /* Feedback Toast Notification State */
    property string toastMessage: ""
    property bool toastVisible: false
    property bool toastIsWarning: false

    Timer {
        id: toastTimer
        interval: 2800
        repeat: false
        onTriggered: root.toastVisible = false
    }

    function showToast(msg, isWarn) {
        root.toastMessage = msg;
        root.toastIsWarning = Boolean(isWarn);
        root.toastVisible = true;
        toastTimer.restart();
    }

    function withAlpha(col, alpha) {
        if (!col) return Qt.rgba(0, 0, 0, alpha);
        const c = Qt.color(col);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    function isDragCompatibleWithPanel(panelIdx) {
        if (!root.isDraggingBlock) return false;
        if (panelIdx >= 0 && panelIdx <= 2) {
            return root.draggedBlockType === "card";
        }
        if (panelIdx === 3) {
            if (root.draggedBlockType !== "tile") return false;
            if (!ControlCenterConfig.groupTilesEnabled) return false;
            if (root.dragSourcePanelIndex === 3) return true;
            return ControlCenterConfig.groupedTiles.length < 4;
        }
        if (panelIdx === 4 || panelIdx === 5) {
            return root.draggedBlockType === "tile";
        }
        return false;
    }

    function startBlockDrag(blockId, blockType, blockLabel, blockIcon, srcPanelIdx, srcItemIdx, rootX, rootY) {
        root.draggedBlockId = blockId;
        root.draggedBlockType = blockType;
        root.draggedBlockLabel = blockLabel;
        root.draggedBlockIcon = blockIcon;
        root.dragSourcePanelIndex = srcPanelIdx;
        root.dragSourceItemIndex = srcItemIdx;
        root.dragMouseX = rootX;
        root.dragMouseY = rootY;
        root.dragHoverPanelIndex = srcPanelIdx;
        root.dragHoverItemIndex = srcItemIdx;
        root.isDraggingBlock = true;
        updateBlockDragHover(rootX, rootY);
    }

    function _checkPanelHit(panelCard, blocksRep, panelIdx, rootX, rootY) {
        if (!panelCard || !panelCard.visible) return false;
        const pt = panelCard.mapFromItem(root, rootX, rootY);
        if (pt.x >= -8 && pt.x <= panelCard.width + 8 && pt.y >= -8 && pt.y <= panelCard.height + 8) {
            root.dragHoverPanelIndex = panelIdx;
            if (!blocksRep || blocksRep.count === 0) {
                root.dragHoverItemIndex = 0;
                return true;
            }
            let foundIdx = blocksRep.count;
            for (let i = 0; i < blocksRep.count; i++) {
                const cItem = blocksRep.itemAt(i);
                if (!cItem) continue;
                const cPt = cItem.mapFromItem(root, rootX, rootY);
                if (cPt.y <= cItem.height * 0.5) {
                    foundIdx = i;
                    break;
                }
            }
            root.dragHoverItemIndex = foundIdx;
            return true;
        }
        return false;
    }

    function updateBlockDragHover(rootX, rootY) {
        root.dragMouseX = rootX;
        root.dragMouseY = rootY;
        if (!root.isDraggingBlock) return;

        // 1. Check Panel 1, Panel 2, Panel 3
        if (_checkPanelHit(layoutCard.panel1Card, layoutCard.panel1Repeater, 0, rootX, rootY)) return;
        if (_checkPanelHit(layoutCard.panel2Card, layoutCard.panel2Repeater, 1, rootX, rootY)) return;
        if (_checkPanelHit(layoutCard.panel3Card, layoutCard.panel3Repeater, 2, rootX, rootY)) return;

        // 2. Check Available Modules Pool
        if (layoutCard.poolCard && root.draggedBlockType === "card" && root.dragSourcePanelIndex >= 0) {
            const poolPt = layoutCard.poolCard.mapFromItem(root, rootX, rootY);
            if (poolPt.x >= -8 && poolPt.x <= layoutCard.poolCard.width + 8 && poolPt.y >= -8 && poolPt.y <= layoutCard.poolCard.height + 8) {
                root.dragHoverPanelIndex = -2;
                root.dragHoverItemIndex = -1;
                return;
            }
        }

        // 3. Check 2x2 Connectivity Group, Quick Tiles 1 & Quick Tiles 2
        if (_checkPanelHit(layoutCard.groupPanel, layoutCard.groupRepeater, 3, rootX, rootY)) return;
        if (_checkPanelHit(layoutCard.standalonePanel, layoutCard.standaloneRepeater, 4, rootX, rootY)) return;
        if (_checkPanelHit(layoutCard.secondaryPanel, layoutCard.secondaryRepeater, 5, rootX, rootY)) return;

        // 4. Check Available Tiles Pool
        if (layoutCard.tilesPoolCard && root.draggedBlockType === "tile" && root.dragSourcePanelIndex >= 3) {
            const tPoolPt = layoutCard.tilesPoolCard.mapFromItem(root, rootX, rootY);
            if (tPoolPt.x >= -8 && tPoolPt.x <= layoutCard.tilesPoolCard.width + 8 && tPoolPt.y >= -8 && tPoolPt.y <= layoutCard.tilesPoolCard.height + 8) {
                root.dragHoverPanelIndex = -3;
                root.dragHoverItemIndex = -1;
                return;
            }
        }

        root.dragHoverPanelIndex = -1;
        root.dragHoverItemIndex = -1;
    }

    function finishBlockDrag() {
        if (!root.isDraggingBlock) return;
        const bId = root.draggedBlockId;
        const bType = root.draggedBlockType;
        const bLabel = root.draggedBlockLabel;
        const targetP = root.dragHoverPanelIndex;
        const targetI = root.dragHoverItemIndex;

        root.isDraggingBlock = false;
        root.dragHoverPanelIndex = -1;
        root.dragHoverItemIndex = -1;

        if (!bId) return;

        if (targetP === -2 && bType === "card") {
            ControlCenterConfig.setCardVisible(bId, false);
            root.showToast("Removed " + bLabel + " to Available Modules");
            return;
        }

        if (targetP === -3 && bType === "tile") {
            ControlCenterConfig.removeTileToPool(bId);
            root.showToast("Removed " + bLabel + " to Available Tiles");
            return;
        }

        if (targetP >= 0) {
            if (!isDragCompatibleWithPanel_Static(bType, targetP)) {
                if (bType === "card") {
                    root.showToast("Modules belong in Panel 1, Panel 2, or Panel 3", true);
                } else if (targetP <= 2) {
                    root.showToast("Quick tiles belong in the Quick Settings Tiles section below", true);
                } else if (targetP === 3 && !ControlCenterConfig.groupTilesEnabled) {
                    root.showToast("Enable 2x2 Connectivity Group first", true);
                } else {
                    root.showToast("2x2 Connectivity Group is maxed out (4/4)", true);
                }
                return;
            }

            if (bType === "card" && targetP >= 0 && targetP <= 2) {
                ControlCenterConfig.moveCardToPanelAt(bId, targetP, targetI);
                if (targetP + 1 > ControlCenterConfig.panelCount && ControlCenterConfig.panelLayout === "horizontal") {
                    ControlCenterConfig.setPanelCount(targetP + 1);
                    root.showToast("Moved " + bLabel + " to Panel " + (targetP + 1) + " (enabled " + (targetP + 1) + " panels)");
                }
            } else if (bType === "tile" && (targetP === 3 || targetP === 4 || targetP === 5)) {
                const mappedPanel = targetP === 3 ? 1 : (targetP === 4 ? 2 : 3);
                if (!ControlCenterConfig.moveTileToPanelAt(bId, mappedPanel, targetI)) {
                    root.showToast("2x2 Connectivity Group is maxed out (4/4)", true);
                }
            }
        }
    }

    function isDragCompatibleWithPanel_Static(bType, panelIdx) {
        if (panelIdx >= 0 && panelIdx <= 2) return bType === "card";
        if (panelIdx === 3) {
            if (bType !== "tile" || !ControlCenterConfig.groupTilesEnabled) return false;
            if (ControlCenterConfig.isTileInGroup(root.draggedBlockId)) return true;
            return ControlCenterConfig.groupedTiles.length < 4;
        }
        if (panelIdx === 4 || panelIdx === 5) return bType === "tile";
        return false;
    }

    Flickable {
        id: ccFlickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 24
        clip: true
        interactive: !root.isDraggingBlock
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder
            }
        }

        ColumnLayout {
            id: mainCol
            width: parent.width - 10
            spacing: 18

            // Page Header Row (matches BarSettings.qml)
            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 3
                    Text {
                        text: "Control Center Settings"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                    Text {
                        text: "Configure modular flyout sections, quick setting tiles, and appearance"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                ActionButton {
                    iconText: "󰦛"
                    label: "Reset to Default"
                    onClicked: {
                        ControlCenterConfig.resetDefaults();
                        root.showToast("Restored default Control Center settings");
                    }
                }
            }

            ParallelAnimation {
                id: subTabContentAnim
                NumberAnimation {
                    target: subTabContentContainer
                    property: "opacity"
                    from: 0.3
                    to: 1.0
                    duration: 210
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: subTabContentTranslate
                    property: "y"
                    from: 6
                    to: 0
                    duration: 210
                    easing.type: Easing.OutCubic
                }
            }

            ControlCenterSubTabSelector {
                root: root
            }

            ColumnLayout {
                id: subTabContentContainer
                Layout.fillWidth: true
                spacing: 20
                transform: Translate { id: subTabContentTranslate; y: 0 }

                // Sub-Tab 0: Modular Layout & Building Blocks (BarLayoutCard style)
                ControlCenterLayoutCard {
                    id: layoutCard
                    root: root
                }

                // Sub-Tab 1: General Appearance, Width, & Media Options (GeneralBarCard style)
                ColumnLayout {
                    visible: root.currentSubTab === 1
                    Layout.fillWidth: true
                    spacing: 20

                    ControlCenterGeneralCard {
                        root: root
                    }

                    ControlCenterMediaOptionsCard {
                        root: root
                    }
                }
            }
        }
    }

    ControlCenterDragGhost {
        root: root
    }

    StatusToast {
        root: root
    }
}
