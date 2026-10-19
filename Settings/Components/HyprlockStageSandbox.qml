/*
 * HyprlockStageSandbox.qml
 *
 * Interactive visual canvas / sandbox for Hyprlock lock screen layout.
 * Allows users to visually preview and drag-and-drop text/command blocks
 * across a simulated 16:9 screen canvas before applying to hyprlock.conf.
 * Synchronizes Cartesian coordinates (halign, valign, position_x, position_y) in real-time.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../wallpaper"

Rectangle {
    id: stageRoot

    property var theme
    property string font: "Hack Nerd Font"
    property var textBlocks: []
    property int selectedIndex: -1
    property bool hasUnsavedMoves: false
    property int refreshTrigger: 0

    property string wallpaperPath: ""
    property real brightness: 0.8
    property real contrast: 1.0
    property int blurPasses: 2

    property int inputWidth: 260
    property int inputHeight: 56
    property string inputPlaceholder: "Type Password"

    signal blockMoved(int index, int newX, int newY)
    signal applyRequested(var blocks)
    signal resetRequested()

    Layout.fillWidth: true
    implicitHeight: mainCol.implicitHeight + 28
    radius: 12
    color: root.theme.bgSurface ?? "#1e1e2e"
    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
    border.width: 1
    clip: true

    // Internal live block working state
    property var liveBlocks: []

    function resolveColor(colStr) {
        if (!colStr) return "#ffffff";
        let str = String(colStr).trim();
        if (str.startsWith("#")) return str;
        if (str.startsWith("rgb(") || str.startsWith("rgba(")) {
            let m = str.match(/rgba?\(\s*([0-9a-fA-F]{6})\s*\)/);
            if (m) return "#" + m[1];
            let m2 = str.match(/rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/);
            if (m2) return Qt.rgba(parseInt(m2[1])/255, parseInt(m2[2])/255, parseInt(m2[3])/255, 1);
        }
        const wallustMap = {
            "$color0": "#404145", "$color1": "#131B43", "$color2": "#464F58", "$color3": "#4D576B",
            "$color4": "#6B777D", "$color5": "#A2B3B5", "$color6": "#A2B3B5", "$color7": "#E3EEF0",
            "$color8": "#9FA7A8", "$color9": "#828bb8", "$color10": "#5E6A76", "$color11": "#67748F",
            "$color12": "#8F9EA7", "$color13": "#D8EEF1", "$color14": "#D8EEF1", "$color15": "#E3EEF0",
            "$foreground": "#F1F9FA", "$background": "#1A1A1E",
            "$accentPrimary": (stageRoot.theme && stageRoot.theme.accentPrimary) ? String(stageRoot.theme.accentPrimary) : "#7aa2f7"
        };
        if (wallustMap[str]) return wallustMap[str];
        return "#ffffff";
    }

    function syncBlocks() {
        if (!stageRoot.hasUnsavedMoves && stageRoot.textBlocks) {
            let arr = [];
            for (let i = 0; i < stageRoot.textBlocks.length; i++) {
                let b = stageRoot.textBlocks[i];
                arr.push({
                    index: b.index !== undefined ? b.index : i,
                    name: b.name || ("Block " + (i + 1)),
                    enabled: b.enabled !== undefined ? b.enabled : true,
                    is_cmd: !!b.is_cmd,
                    raw_text: b.raw_text || "",
                    font_size: b.font_size || 14,
                    font_family: b.font_family || "Victor Mono Bold Oblique",
                    position_x: b.position_x !== undefined ? b.position_x : 0,
                    position_y: b.position_y !== undefined ? b.position_y : 0,
                    halign: b.halign || "center",
                    valign: b.valign || "center",
                    color: b.color || "$color8"
                });
            }
            stageRoot.liveBlocks = arr;
        }
    }

    onTextBlocksChanged: syncBlocks()
    Component.onCompleted: syncBlocks()

    ColumnLayout {
        id: mainCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 12

        // --- Header Bar ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                RowLayout {
                    spacing: 8
                    Text {
                        text: "Interactive Lock Screen Stage"
                        font.family: stageRoot.font
                        font.pixelSize: 13
                        font.bold: true
                        color: stageRoot.theme ? (stageRoot.theme.textPrimary ?? "#ffffff") : "#ffffff"
                    }

                    // Live Unsaved Pill
                    Rectangle {
                        visible: stageRoot.hasUnsavedMoves
                        height: 18
                        implicitWidth: unBadgeText.implicitWidth + 10
                        radius: 4
                        color: Qt.rgba(0.9, 0.7, 0.2, 0.18)
                        border.color: Qt.rgba(0.9, 0.7, 0.2, 0.4)
                        border.width: 1

                        Text {
                            id: unBadgeText
                            anchors.centerIn: parent
                            text: "Unsaved Moves"
                            font.family: stageRoot.font
                            font.pixelSize: 9
                            font.bold: true
                            color: "#e0af68"
                        }
                    }
                }

                Text {
                    text: "Drag any label or block across the simulated screen to adjust positions live before applying"
                    font.family: stageRoot.font
                    font.pixelSize: 11
                    color: stageRoot.theme ? (stageRoot.theme.textSecondary ?? "#a6adc8") : "#a6adc8"
                }
            }

            // Expanding spacer pushing buttons to far right
            Item {
                Layout.fillWidth: true
            }

            // Action Buttons
            RowLayout {
                spacing: 6
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                // Snap Selected to Center
                Rectangle {
                    visible: stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < stageRoot.liveBlocks.length
                    implicitWidth: snapText.implicitWidth + 18
                    height: 28
                    radius: 7
                    color: snapHover.hovered ? (stageRoot.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (stageRoot.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25))
                    border.color: snapHover.hovered ? (stageRoot.theme.accentPrimary ?? "#7aa2f7") : (stageRoot.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1
                    scale: snapMouse.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    HoverHandler { id: snapHover }

                    Text {
                        id: snapText
                        anchors.centerIn: parent
                        text: "Center X: 0"
                        font.family: stageRoot.font
                        font.pixelSize: 10
                        font.bold: true
                        color: snapHover.hovered ? (stageRoot.theme.accentPrimary ?? "#7aa2f7") : (stageRoot.theme.textPrimary ?? "#ffffff")
                    }

                    MouseArea {
                        id: snapMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < stageRoot.liveBlocks.length) {
                                let b = stageRoot.liveBlocks[stageRoot.selectedIndex];
                                b.position_x = 0;
                                stageRoot.hasUnsavedMoves = true;
                                stageRoot.blockMoved(stageRoot.selectedIndex, 0, b.position_y);
                                // Trigger QML property update
                                stageRoot.liveBlocks = stageRoot.liveBlocks.slice();
                                stageRoot.refreshTrigger++;
                            }
                        }
                    }
                }

                // Reset Positions Button
                Rectangle {
                    visible: stageRoot.hasUnsavedMoves
                    implicitWidth: resetText.implicitWidth + 18
                    height: 28
                    radius: 7
                    color: resetHover.hovered ? (stageRoot.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (stageRoot.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25))
                    border.color: resetHover.hovered ? (stageRoot.theme.accentRed ?? "#f7768e") : (stageRoot.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1
                    scale: resetMouse.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    HoverHandler { id: resetHover }

                    Text {
                        id: resetText
                        anchors.centerIn: parent
                        text: "Reset"
                        font.family: stageRoot.font
                        font.pixelSize: 10
                        font.bold: true
                        color: resetHover.hovered ? (stageRoot.theme.accentRed ?? "#f7768e") : (stageRoot.theme.textPrimary ?? "#ffffff")
                    }

                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            stageRoot.hasUnsavedMoves = false;
                            stageRoot.syncBlocks();
                            stageRoot.resetRequested();
                            stageRoot.refreshTrigger++;
                        }
                    }
                }

                // Apply Layout Button
                Rectangle {
                    implicitWidth: applyText.implicitWidth + 22
                    height: 28
                    radius: 7
                    color: applyHover.hovered ? Qt.darker(stageRoot.theme.accentPrimary ?? "#7aa2f7", 1.1) : (stageRoot.theme.accentPrimary ?? "#7aa2f7")
                    scale: applyMouse.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    HoverHandler { id: applyHover }

                    Text {
                        id: applyText
                        anchors.centerIn: parent
                        text: stageRoot.hasUnsavedMoves ? "Apply Layout" : "Save Positions"
                        font.family: stageRoot.font
                        font.pixelSize: 11
                        font.bold: true
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: applyMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            stageRoot.hasUnsavedMoves = false;
                            stageRoot.applyRequested(stageRoot.liveBlocks);
                        }
                    }
                }
            }
        }

        // --- 16:9 Simulated Lock Screen Monitor Stage ---
        Rectangle {
            id: canvasBox
            Layout.fillWidth: true
            Layout.preferredHeight: width > 0 ? Math.round(width * (1080.0 / 1920.0)) : 380
            implicitHeight: Layout.preferredHeight
            radius: 10
            color: "#0a0c14"
            border.color: stageHover.hovered ? Qt.rgba(stageRoot.theme.accentPrimary.r, stageRoot.theme.accentPrimary.g, stageRoot.theme.accentPrimary.b, 0.4) : (stageRoot.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
            border.width: 1
            clip: true

            Behavior on border.color { ColorAnimation { duration: 140 } }
            HoverHandler { id: stageHover }

            readonly property real scaleFactor: width / 1920.0

            // 1. Wallpaper Background with blur & exposure simulation
            Image {
                id: bgImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: stageRoot.wallpaperPath !== "" ? (stageRoot.wallpaperPath.startsWith("/") ? ("file://" + stageRoot.wallpaperPath) : stageRoot.wallpaperPath) : ""
                asynchronous: true
                opacity: Math.max(0.2, Math.min(1.0, stageRoot.brightness))
                visible: source != ""
            }

            // Dark vignette backdrop overlay
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, Math.min(0.65, Math.max(0.2, 0.5 * (1.5 - stageRoot.brightness))))
            }

            // 2. Faint Center Crosshair Guidelines (X = 0, Y = 0)
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // 3. Central Anchor Marker
            Rectangle {
                anchors.centerIn: parent
                width: 5
                height: 5
                radius: 2.5
                color: Qt.rgba(1, 1, 1, 0.15)
            }

            // 4. Simulated Password Input Field (Reference Box at 0, -85)
            Rectangle {
                id: simInputBox
                readonly property real simW: Math.max(70, stageRoot.inputWidth * canvasBox.scaleFactor)
                readonly property real simH: Math.max(16, stageRoot.inputHeight * canvasBox.scaleFactor)
                width: simW
                height: simH
                radius: simH / 2
                x: (canvasBox.width / 2) - (width / 2)
                y: (canvasBox.height / 2) - (-85 * canvasBox.scaleFactor) - (height / 2)
                color: Qt.rgba(0, 0, 0, 0.5)
                border.color: Qt.rgba(stageRoot.theme.accentPrimary.r, stageRoot.theme.accentPrimary.g, stageRoot.theme.accentPrimary.b, 0.5)
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 3
                    Repeater {
                        model: 5
                        Rectangle {
                            width: 3
                            height: 3
                            radius: 1.5
                            color: "#ffffff"
                            opacity: 0.7
                        }
                    }
                }
            }

            // 5. Active Crosshair Guide for Dragged Element
            Item {
                id: dragGuides
                anchors.fill: parent
                visible: stageRoot.selectedIndex >= 0

                property real targetCenterX: 0
                property real targetCenterY: 0

                // Vertical Guide
                Rectangle {
                    x: dragGuides.targetCenterX
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: stageRoot.theme.accentPrimary ?? "#7aa2f7"
                    opacity: 0.4
                    visible: dragGuides.visible
                }

                // Horizontal Guide
                Rectangle {
                    y: dragGuides.targetCenterY
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: stageRoot.theme.accentPrimary ?? "#7aa2f7"
                    opacity: 0.4
                    visible: dragGuides.visible
                }
            }

            // 6. Interactive Draggable Blocks
            Repeater {
                model: stageRoot.liveBlocks

                Item {
                    id: blockDelegate
                    property var blockData: modelData
                    property int blockIdx: index
                    readonly property bool isSelected: stageRoot.selectedIndex === blockIdx
                    readonly property real sFactor: canvasBox.scaleFactor

                    // Content dimensions
                    width: blockPill.width
                    height: blockPill.height

                    function updateCoords() {
                        if (blockDragArea.drag.active) return;
                        if (!blockData) return;

                        let curX = blockData.position_x !== undefined ? blockData.position_x : 0;
                        let curY = blockData.position_y !== undefined ? blockData.position_y : 0;

                        let targetX = 0;
                        if (blockData.halign === "center") {
                            targetX = (canvasBox.width / 2) + (curX * sFactor) - (width / 2);
                        } else if (blockData.halign === "right") {
                            targetX = canvasBox.width + (curX * sFactor) - width;
                        } else {
                            targetX = curX * sFactor;
                        }

                        let targetY = 0;
                        if (blockData.valign === "center") {
                            targetY = (canvasBox.height / 2) - (curY * sFactor) - (height / 2);
                        } else if (blockData.valign === "bottom") {
                            targetY = canvasBox.height - (curY * sFactor) - height;
                        } else {
                            targetY = -(curY * sFactor);
                        }

                        x = Math.round(targetX);
                        y = Math.round(targetY);
                    }

                    Component.onCompleted: updateCoords()
                    onWidthChanged: updateCoords()
                    onHeightChanged: updateCoords()
                    onSFactorChanged: updateCoords()

                    Connections {
                        target: stageRoot
                        function onRefreshTriggerChanged() {
                            blockDelegate.updateCoords();
                        }
                        function onLiveBlocksChanged() {
                            blockDelegate.updateCoords();
                        }
                    }

                    z: isSelected || blockDragArea.drag.active ? 15 : 2

                    // Live Pill Representation
                    Rectangle {
                        id: blockPill
                        implicitWidth: contentRow.implicitWidth + 14
                        implicitHeight: Math.max(22, contentRow.implicitHeight + 8)
                        radius: 5
                        color: blockDragArea.drag.active
                            ? Qt.rgba(stageRoot.theme.accentPrimary.r, stageRoot.theme.accentPrimary.g, stageRoot.theme.accentPrimary.b, 0.35)
                            : (isSelected
                                ? Qt.rgba(stageRoot.theme.accentPrimary.r, stageRoot.theme.accentPrimary.g, stageRoot.theme.accentPrimary.b, 0.22)
                                : (blockPillHover.hovered ? Qt.rgba(0, 0, 0, 0.7) : Qt.rgba(0, 0, 0, 0.55)))
                        border.color: (isSelected || blockDragArea.drag.active)
                            ? (stageRoot.theme.accentPrimary ?? "#7aa2f7")
                            : (blockPillHover.hovered ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(1, 1, 1, 0.15))
                        border.width: (isSelected || blockDragArea.drag.active) ? 1.5 : 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        HoverHandler { id: blockPillHover }

                        Row {
                            id: contentRow
                            anchors.centerIn: parent
                            spacing: 6

                            // Color indicator dot
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: stageRoot.resolveColor(blockDelegate.blockData.color)
                            }

                            // Simulated Content Text scaled accurately to real screen proportions
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: stageRoot.font
                                font.pixelSize: Math.max(9, Math.round(blockDelegate.blockData.font_size * blockDelegate.sFactor * 0.95))
                                font.bold: true
                                color: blockDelegate.blockData.enabled ? (blockDelegate.isSelected ? (stageRoot.theme.accentPrimary ?? "#7aa2f7") : stageRoot.resolveColor(blockDelegate.blockData.color)) : "#6c7086"
                                text: {
                                    let n = blockDelegate.blockData.name;
                                    if (n === "Hour-Time") return "08:22 AM";
                                    if (n === "Date") return "Sunday, 18 October";
                                    if (n === "USER") return "$USER";
                                    if (n === "Keyboard LAYOUT") return "$LAYOUT";
                                    if (n === "uptime") return "up 9h 50m";
                                    if (n === "battery information") return "󰂄 95%";
                                    if (n === "weather") return "⛅ 31°C";
                                    return n;
                                }
                            }
                        }

                        // Floating Coordinates Badge (Visible when hovered, selected, or dragged)
                        Rectangle {
                            visible: blockDelegate.isSelected || blockDragArea.drag.active || blockPillHover.hovered
                            anchors.bottom: parent.top
                            anchors.bottomMargin: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitWidth: badgeRow.implicitWidth + 12
                            height: 18
                            radius: 4
                            color: "#1e1e2e"
                            border.color: stageRoot.theme.accentPrimary ?? "#7aa2f7"
                            border.width: 1
                            z: 20

                            RowLayout {
                                id: badgeRow
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: stageRoot.resolveColor(blockDelegate.blockData.color)
                                }

                                Text {
                                    id: badgeTxt
                                    text: blockDelegate.blockData.name + " (" + blockDelegate.blockData.position_x + ", " + blockDelegate.blockData.position_y + ") • " + (blockDelegate.blockData.color || "$color8")
                                    font.family: stageRoot.font
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: stageRoot.theme.accentPrimary ?? "#7aa2f7"
                                }
                            }
                        }
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

                                let rawX = 0;
                                if (blockDelegate.blockData.halign === "center") {
                                    rawX = (curCenterX - (canvasBox.width / 2)) / blockDelegate.sFactor;
                                } else if (blockDelegate.blockData.halign === "right") {
                                    rawX = ((blockDelegate.x + blockDelegate.width) - canvasBox.width) / blockDelegate.sFactor;
                                } else {
                                    rawX = blockDelegate.x / blockDelegate.sFactor;
                                }

                                let rawY = 0;
                                if (blockDelegate.blockData.valign === "center") {
                                    rawY = ((canvasBox.height / 2) - curCenterY) / blockDelegate.sFactor;
                                } else if (blockDelegate.blockData.valign === "bottom") {
                                    rawY = (canvasBox.height - (blockDelegate.y + blockDelegate.height)) / blockDelegate.sFactor;
                                } else {
                                    rawY = -(blockDelegate.y) / blockDelegate.sFactor;
                                }

                                // Magnetic snap to 0 within 14px threshold
                                if (blockDelegate.blockData.halign === "center" && Math.abs(rawX) < 14) rawX = 0;
                                if (blockDelegate.blockData.valign === "center" && Math.abs(rawY) < 14) rawY = 0;

                                let finalX = Math.round(rawX);
                                let finalY = Math.round(rawY);

                                if (blockDelegate.blockData.position_x !== finalX || blockDelegate.blockData.position_y !== finalY) {
                                    blockDelegate.blockData.position_x = finalX;
                                    blockDelegate.blockData.position_y = finalY;

                                    if (stageRoot.liveBlocks && blockDelegate.blockIdx >= 0 && blockDelegate.blockIdx < stageRoot.liveBlocks.length) {
                                        stageRoot.liveBlocks[blockDelegate.blockIdx].position_x = finalX;
                                        stageRoot.liveBlocks[blockDelegate.blockIdx].position_y = finalY;
                                    }

                                    stageRoot.hasUnsavedMoves = true;
                                    stageRoot.blockMoved(blockDelegate.blockIdx, finalX, finalY);
                                }
                            }
                        }

                        onReleased: {
                            dragGuides.targetCenterX = blockDelegate.x + blockDelegate.width / 2;
                            dragGuides.targetCenterY = blockDelegate.y + blockDelegate.height / 2;
                            blockDelegate.updateCoords();
                        }
                    }
                }
            }
        }
    }
}
