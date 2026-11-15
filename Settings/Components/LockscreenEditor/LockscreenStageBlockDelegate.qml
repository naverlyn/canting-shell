import QtQuick
import "../../../Lockscreen"
import "../Lockscreen"
import "../../../Lockscreen/Modules"

Item {
    id: blockDelegate
    required property var stageRoot
    required property var canvasBox
    required property var dragGuides
    required property var simAuthBox
    required property var modelData
    required property int index
    property var blockData: modelData
    property int blockIdx: index
    readonly property bool isSelected: stageRoot.selectedIndex === blockIdx
    readonly property real sFactor: canvasBox.scaleFactor

    // In Preview Mode, hide disabled blocks just like real lockscreen
    visible: !stageRoot.previewMode || (blockData && blockData.enabled)

    width: Math.max(20, Math.round(moduleHost.implicitWidth + (stageRoot.previewMode ? 0 : 6)))
    height: Math.max(20, Math.round(moduleHost.implicitHeight + (stageRoot.previewMode ? 0 : 6)))

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
            return canvasBox.width - width + (curPosX * sFactor);
        } else {
            return (canvasBox.width - width) / 2 + (curPosX * sFactor);
        }
    }

    readonly property real targetY: {
        if (curValign === "top") {
            return -(curPosY * sFactor);
        } else if (curValign === "bottom") {
            return canvasBox.height - height - (curPosY * sFactor);
        } else {
            return (canvasBox.height - height) / 2 - (curPosY * sFactor);
        }
    }

    Binding on x {
        when: !blockDragArea.drag.active
        value: Math.max(2, Math.min(canvasBox.width - blockDelegate.width - 2, Math.round(blockDelegate.targetX)))
    }

    Binding on y {
        when: !blockDragArea.drag.active
        value: Math.max(2, Math.min(canvasBox.height - blockDelegate.height - 2, Math.round(blockDelegate.targetY)))
    }

    z: isSelected || blockDragArea.drag.active ? 15 : 2
    opacity: stageRoot.animModsOpacity
    scale: stageRoot.animModsScale
    transform: Translate {
        x: {
            let dx = 0;
            if (stageRoot.animStaggerProgress !== 0) {
                if (blockDelegate.curHalign === "left") dx -= 60 * stageRoot.animStaggerProgress;
                else if (blockDelegate.curHalign === "right") dx += 60 * stageRoot.animStaggerProgress;
            }
            if (stageRoot.animPortalPull !== 0) {
                dx += ((simAuthBox.x + simAuthBox.width / 2) - (blockDelegate.x + blockDelegate.width / 2)) * stageRoot.animPortalPull;
            }
            return dx;
        }
        y: {
            let dy = 0;
            if (stageRoot.animStaggerProgress !== 0) {
                if (blockDelegate.curValign === "top") dy -= 45 * stageRoot.animStaggerProgress;
                else if (blockDelegate.curValign === "bottom") dy += 45 * stageRoot.animStaggerProgress;
                else dy += 30 * stageRoot.animStaggerProgress;
            }
            if (stageRoot.animCurtainSplit !== 0) {
                const topHalf = (blockDelegate.y + blockDelegate.height / 2) <= (canvasBox.height / 2);
                dy += (topHalf ? -65 : 65) * stageRoot.animCurtainSplit;
            }
            if (stageRoot.animPortalPull !== 0) {
                dy += ((simAuthBox.y + simAuthBox.height / 2) - (blockDelegate.y + blockDelegate.height / 2)) * stageRoot.animPortalPull;
            }
            return dy;
        }
    }

    // Drag / Selection Outline in Editor Mode
    Rectangle {
        id: editOutline
        anchors.fill: parent
        radius: Math.max(4, Math.round(8 * blockDelegate.sFactor))
        visible: !stageRoot.previewMode
        color: blockDragArea.drag.active
            ? Qt.rgba(stageRoot.theme.accentPrimary.r, stageRoot.theme.accentPrimary.g, stageRoot.theme.accentPrimary.b, 0.22)
            : (blockDelegate.isSelected
                ? Qt.rgba(stageRoot.theme.accentPrimary.r, stageRoot.theme.accentPrimary.g, stageRoot.theme.accentPrimary.b, 0.12)
                : (blockHover.hovered ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(0, 0, 0, 0.18)))
        border.color: (blockDelegate.isSelected || blockDragArea.drag.active)
            ? stageRoot.theme.accentPrimary
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
        theme: stageRoot.theme
        font: (stageRoot.theme && stageRoot.theme.lockscreenFont)
            ? stageRoot.theme.lockscreenFont
            : ((stageRoot.theme && stageRoot.theme.monoFont) ? stageRoot.theme.monoFont : "JetBrainsMono Nerd Font")
        moduleData: blockDelegate.blockData
        previewMode: stageRoot.previewMode
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
        drag.maximumX: Math.max(0, canvasBox.width - blockDelegate.width)
        drag.minimumY: 0
        drag.maximumY: Math.max(0, canvasBox.height - blockDelegate.height)
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        onPressed: {
            stageRoot.selectedIndex = blockDelegate.blockIdx;
            dragGuides.targetCenterX = blockDelegate.x + blockDelegate.width / 2;
            dragGuides.targetCenterY = blockDelegate.y + blockDelegate.height / 2;
        }

        onPositionChanged: {
            if (drag.active) {
                let curCenterX = blockDelegate.x + blockDelegate.width / 2;
                let curCenterY = blockDelegate.y + blockDelegate.height / 2;
                dragGuides.targetCenterX = curCenterX;
                dragGuides.targetCenterY = curCenterY;
                stageRoot.applyMagneticSnap(blockDelegate.x, blockDelegate.y, blockDelegate.width, blockDelegate.height, blockDelegate.blockIdx);
            }
        }

        onReleased: {
            dragGuides.snapVerticalActive = false;
            dragGuides.snapHorizontalActive = false;

            let snapped = stageRoot.applyMagneticSnap(blockDelegate.x, blockDelegate.y, blockDelegate.width, blockDelegate.height, blockDelegate.blockIdx);
            blockDelegate.x = snapped.x;
            blockDelegate.y = snapped.y;

            let curCenterX = blockDelegate.x + blockDelegate.width / 2;
            let curCenterY = blockDelegate.y + blockDelegate.height / 2;

            let newHalign = blockDelegate.blockData ? blockDelegate.blockData.halign : "center";
            if (curCenterX > canvasBox.width * 0.35 && curCenterX < canvasBox.width * 0.65) {
                newHalign = "center";
            } else if (curCenterX <= canvasBox.width * 0.35) {
                newHalign = "left";
            } else {
                newHalign = "right";
            }

            let newValign = blockDelegate.blockData ? blockDelegate.blockData.valign : "center";
            if (curCenterY < canvasBox.height * 0.35) {
                newValign = "top";
            } else if (curCenterY > canvasBox.height * 0.65) {
                newValign = "bottom";
            } else {
                newValign = "center";
            }

            let rawX = 0;
            if (newHalign === "center") {
                rawX = (curCenterX - (canvasBox.width / 2)) / blockDelegate.sFactor;
            } else if (newHalign === "right") {
                rawX = ((blockDelegate.x + blockDelegate.width) - canvasBox.width) / blockDelegate.sFactor;
            } else {
                rawX = blockDelegate.x / blockDelegate.sFactor;
            }

            let rawY = 0;
            if (newValign === "center") {
                rawY = ((canvasBox.height / 2) - curCenterY) / blockDelegate.sFactor;
            } else if (newValign === "bottom") {
                rawY = (canvasBox.height - (blockDelegate.y + blockDelegate.height)) / blockDelegate.sFactor;
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

            if (stageRoot.liveBlocks && blockDelegate.blockIdx >= 0 && blockDelegate.blockIdx < stageRoot.liveBlocks.length) {
                let liveList = [...stageRoot.liveBlocks];
                liveList[blockDelegate.blockIdx] = Object.assign({}, liveList[blockDelegate.blockIdx], {
                    position_x: finalX,
                    position_y: finalY,
                    halign: newHalign,
                    valign: newValign
                });
                stageRoot.liveBlocks = liveList;
            }

            stageRoot.hasUnsavedMoves = false;
            stageRoot.blockMoved(blockDelegate.blockIdx, finalX, finalY, newHalign, newValign);
        }
    }
}
