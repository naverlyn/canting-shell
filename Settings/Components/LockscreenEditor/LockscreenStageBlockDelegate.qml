import QtQuick
import "../../../Lockscreen"
import "../Lockscreen"
import "../../../Lockscreen/Modules"

Item {
    id: blockDelegate
    required property var hostStage
    required property var hostCanvas
    required property var hostGuides
    required property var hostAuthBox
    required property var modelData
    required property int index
    property var blockData: modelData
    property int blockIdx: index
    readonly property bool isSelected: blockDelegate.hostStage.selectedIndex === blockIdx
    readonly property real sFactor: blockDelegate.hostCanvas.scaleFactor

    // In Preview Mode, hide disabled blocks just like real lockscreen
    visible: !blockDelegate.hostStage.previewMode || (blockData && blockData.enabled)

    width: Math.max(20, Math.round(moduleHost.implicitWidth + (blockDelegate.hostStage.previewMode ? 0 : 6)))
    height: Math.max(20, Math.round(moduleHost.implicitHeight + (blockDelegate.hostStage.previewMode ? 0 : 6)))

    // Explicit reactive coordinate properties
    property int curPosX: blockData && blockData.position_x !== undefined ? Number(blockData.position_x) : 0
    property int curPosY: blockData && blockData.position_y !== undefined ? Number(blockData.position_y) : 0
    property string curHalign: blockData && blockData.halign ? blockData.halign : "center"
    property string curValign: blockData && blockData.valign ? blockData.valign : "center"

    onBlockDataChanged: {
        if (!blockDragArea.drag.active && blockData) {
            curPosX = Number(blockData.position_x) || 0;
            curPosY = Number(blockData.position_y) || 0;
            curHalign = blockData.halign || "center";
            curValign = blockData.valign || "center";
        }
    }

    readonly property real targetX: {
        if (curHalign === "left") {
            return curPosX * sFactor;
        } else if (curHalign === "right") {
            return blockDelegate.hostCanvas.width - width + (curPosX * sFactor);
        } else {
            return (blockDelegate.hostCanvas.width - width) / 2 + (curPosX * sFactor);
        }
    }

    readonly property real targetY: {
        if (curValign === "top") {
            return -(curPosY * sFactor);
        } else if (curValign === "bottom") {
            return blockDelegate.hostCanvas.height - height - (curPosY * sFactor);
        } else {
            return (blockDelegate.hostCanvas.height - height) / 2 - (curPosY * sFactor);
        }
    }

    Binding on x {
        when: !blockDragArea.drag.active
        value: Math.max(2, Math.min(blockDelegate.hostCanvas.width - blockDelegate.width - 2, Math.round(blockDelegate.targetX)))
    }

    Binding on y {
        when: !blockDragArea.drag.active
        value: Math.max(2, Math.min(blockDelegate.hostCanvas.height - blockDelegate.height - 2, Math.round(blockDelegate.targetY)))
    }

    z: isSelected || blockDragArea.drag.active ? 15 : 2
    opacity: blockDelegate.hostStage.animModsOpacity
    scale: blockDelegate.hostStage.animModsScale
    transform: Translate {
        x: {
            let dx = 0;
            if (blockDelegate.hostStage.animStaggerProgress !== 0) {
                if (blockDelegate.curHalign === "left") dx -= 60 * blockDelegate.hostStage.animStaggerProgress;
                else if (blockDelegate.curHalign === "right") dx += 60 * blockDelegate.hostStage.animStaggerProgress;
            }
            if (blockDelegate.hostStage.animPortalPull !== 0) {
                dx += ((blockDelegate.hostAuthBox.x + blockDelegate.hostAuthBox.width / 2) - (blockDelegate.x + blockDelegate.width / 2)) * blockDelegate.hostStage.animPortalPull;
            }
            return dx;
        }
        y: {
            let dy = 0;
            if (blockDelegate.hostStage.animStaggerProgress !== 0) {
                if (blockDelegate.curValign === "top") dy -= 45 * blockDelegate.hostStage.animStaggerProgress;
                else if (blockDelegate.curValign === "bottom") dy += 45 * blockDelegate.hostStage.animStaggerProgress;
                else dy += 30 * blockDelegate.hostStage.animStaggerProgress;
            }
            if (blockDelegate.hostStage.animCurtainSplit !== 0) {
                const topHalf = (blockDelegate.y + blockDelegate.height / 2) <= (blockDelegate.hostCanvas.height / 2);
                dy += (topHalf ? -65 : 65) * blockDelegate.hostStage.animCurtainSplit;
            }
            if (blockDelegate.hostStage.animPortalPull !== 0) {
                dy += ((blockDelegate.hostAuthBox.y + blockDelegate.hostAuthBox.height / 2) - (blockDelegate.y + blockDelegate.height / 2)) * blockDelegate.hostStage.animPortalPull;
            }
            return dy;
        }
    }

    // Drag / Selection Outline in Editor Mode
    Rectangle {
        id: editOutline
        anchors.fill: parent
        radius: Math.max(4, Math.round(8 * blockDelegate.sFactor))
        visible: !blockDelegate.hostStage.previewMode
        color: blockDragArea.drag.active
            ? Qt.rgba(blockDelegate.hostStage.theme.accentPrimary.r, blockDelegate.hostStage.theme.accentPrimary.g, blockDelegate.hostStage.theme.accentPrimary.b, 0.22)
            : (blockDelegate.isSelected
                ? Qt.rgba(blockDelegate.hostStage.theme.accentPrimary.r, blockDelegate.hostStage.theme.accentPrimary.g, blockDelegate.hostStage.theme.accentPrimary.b, 0.12)
                : (blockHover.hovered ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(0, 0, 0, 0.18)))
        border.color: (blockDelegate.isSelected || blockDragArea.drag.active)
            ? blockDelegate.hostStage.theme.accentPrimary
            : (blockHover.hovered ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(1, 1, 1, 0.12))
        border.width: (blockDelegate.isSelected || blockDragArea.drag.active) ? 1.5 : 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        HoverHandler { id: blockHover }
    }

    // Render LockModuleHost identically to LockSurfaceView
    LockModuleHost {
        id: moduleHost
        anchors.centerIn: parent
        theme: blockDelegate.hostStage.theme
        font: (blockDelegate.hostStage.theme && blockDelegate.hostStage.theme.lockscreenFont)
            ? blockDelegate.hostStage.theme.lockscreenFont
            : ((blockDelegate.hostStage.theme && blockDelegate.hostStage.theme.monoFont) ? blockDelegate.hostStage.theme.monoFont : "JetBrainsMono Nerd Font")
        moduleData: blockDelegate.blockData
        previewMode: blockDelegate.hostStage.previewMode
        scaleFactor: blockDelegate.sFactor
    }

    // Native C++ Drag & Click Area
    MouseArea {
        id: blockDragArea
        anchors.fill: parent
        preventStealing: true
        drag.target: blockDelegate
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 0
        drag.maximumX: Math.max(0, blockDelegate.hostCanvas.width - blockDelegate.width)
        drag.minimumY: 0
        drag.maximumY: Math.max(0, blockDelegate.hostCanvas.height - blockDelegate.height)
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        onPressed: {
            blockDelegate.hostStage.selectedIndex = blockDelegate.blockIdx;
            blockDelegate.hostGuides.targetCenterX = blockDelegate.x + blockDelegate.width / 2;
            blockDelegate.hostGuides.targetCenterY = blockDelegate.y + blockDelegate.height / 2;
        }

        onPositionChanged: {
            if (drag.active) {
                let curCenterX = blockDelegate.x + blockDelegate.width / 2;
                let curCenterY = blockDelegate.y + blockDelegate.height / 2;
                blockDelegate.hostGuides.targetCenterX = curCenterX;
                blockDelegate.hostGuides.targetCenterY = curCenterY;
                blockDelegate.hostStage.applyMagneticSnap(blockDelegate.x, blockDelegate.y, blockDelegate.width, blockDelegate.height, blockDelegate.blockIdx);
            }
        }

        onReleased: {
            blockDelegate.hostGuides.snapVerticalActive = false;
            blockDelegate.hostGuides.snapHorizontalActive = false;

            let snapped = blockDelegate.hostStage.applyMagneticSnap(blockDelegate.x, blockDelegate.y, blockDelegate.width, blockDelegate.height, blockDelegate.blockIdx);
            blockDelegate.x = snapped.x;
            blockDelegate.y = snapped.y;

            let curCenterX = blockDelegate.x + blockDelegate.width / 2;
            let curCenterY = blockDelegate.y + blockDelegate.height / 2;

            let newHalign = blockDelegate.blockData ? blockDelegate.blockData.halign : "center";
            if (curCenterX > blockDelegate.hostCanvas.width * 0.35 && curCenterX < blockDelegate.hostCanvas.width * 0.65) {
                newHalign = "center";
            } else if (curCenterX <= blockDelegate.hostCanvas.width * 0.35) {
                newHalign = "left";
            } else {
                newHalign = "right";
            }

            let newValign = blockDelegate.blockData ? blockDelegate.blockData.valign : "center";
            if (curCenterY < blockDelegate.hostCanvas.height * 0.35) {
                newValign = "top";
            } else if (curCenterY > blockDelegate.hostCanvas.height * 0.65) {
                newValign = "bottom";
            } else {
                newValign = "center";
            }

            let rawX = 0;
            if (newHalign === "center") {
                rawX = (curCenterX - (blockDelegate.hostCanvas.width / 2)) / blockDelegate.sFactor;
            } else if (newHalign === "right") {
                rawX = ((blockDelegate.x + blockDelegate.width) - blockDelegate.hostCanvas.width) / blockDelegate.sFactor;
            } else {
                rawX = blockDelegate.x / blockDelegate.sFactor;
            }

            let rawY = 0;
            if (newValign === "center") {
                rawY = ((blockDelegate.hostCanvas.height / 2) - curCenterY) / blockDelegate.sFactor;
            } else if (newValign === "bottom") {
                rawY = (blockDelegate.hostCanvas.height - (blockDelegate.y + blockDelegate.height)) / blockDelegate.sFactor;
            } else {
                rawY = -(blockDelegate.y) / blockDelegate.sFactor;
            }

            let finalX = Math.round(rawX);
            let finalY = Math.round(rawY);

            blockDelegate.curPosX = finalX;
            blockDelegate.curPosY = finalY;
            blockDelegate.curHalign = newHalign;
            blockDelegate.curValign = newValign;

            if (blockDelegate.blockData) {
                blockDelegate.blockData = Object.assign({}, blockDelegate.blockData, {
                    position_x: finalX,
                    position_y: finalY,
                    halign: newHalign,
                    valign: newValign
                });
            }

            if (blockDelegate.hostStage.liveBlocks && blockDelegate.blockIdx >= 0 && blockDelegate.blockIdx < blockDelegate.hostStage.liveBlocks.length) {
                let liveList = [...blockDelegate.hostStage.liveBlocks];
                liveList[blockDelegate.blockIdx] = Object.assign({}, liveList[blockDelegate.blockIdx], {
                    position_x: finalX,
                    position_y: finalY,
                    halign: newHalign,
                    valign: newValign
                });
                blockDelegate.hostStage.liveBlocks = liveList;
            }

            blockDelegate.hostStage.hasUnsavedMoves = false;
            blockDelegate.hostStage.blockMoved(blockDelegate.blockIdx, finalX, finalY, newHalign, newValign);
        }
    }
}
