/*
 * HyprlockStageSandbox.qml
 *
 * Interactive visual canvas / sandbox for Hyprlock lock screen layout.
 * Allows users to visually preview and drag-and-drop text/command blocks
 * across a simulated 16:9 screen canvas before applying to hyprlock.conf.
 * Synchronizes Cartesian coordinates (halign, valign, position_x, position_y) in real-time,
 * supports magnetic window/element snapping, live Preview mode (rendering real TIME/DATE),
 * and interactive Password Input coloring.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../wallpaper"

Rectangle {
    id: stageRoot

    property var theme
    property string font: "Lato Nerd Font"
    property var textBlocks: []
    property int selectedIndex: -1
    property bool hasUnsavedMoves: false
    property int refreshTrigger: 0

    // Interactive Stage Controls
    property bool previewMode: false
    property bool snapEnabled: true
    property var currentNow: new Date()

    Timer {
        interval: 15000
        running: stageRoot.previewMode
        repeat: true
        onTriggered: stageRoot.currentNow = new Date()
    }

    property string wallpaperPath: ""
    property real brightness: 0.8
    property real contrast: 1.0
    property int blurPasses: 2

    property int inputWidth: 260
    property int inputHeight: 56
    property int inputOutlineThickness: 2
    property string inputPlaceholder: "Type Password"
    property int inputPosX: 0
    property int inputPosY: -85
    property string inputHalign: "center"
    property string inputValign: "center"
    property string inputOuterColor: "$accent"
    property string inputInnerColor: "$surface0"
    property string inputFontColor: "$text"

    property int liveInputX: 0
    property int liveInputY: -85

    signal blockMoved(int index, int newX, int newY)
    signal inputMoved(int newX, int newY)
    signal inputColorModified(string outerCol, string innerCol, string fontCol)
    signal applyRequested(var blocks)
    signal resetRequested()

    Layout.fillWidth: true
    implicitHeight: mainCol.implicitHeight + 28
    radius: 12
    color: stageRoot.theme ? (stageRoot.theme.bgSurface ?? "#1e1e2e") : "#1e1e2e"
    border.color: stageRoot.theme ? (stageRoot.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)) : Qt.rgba(1, 1, 1, 0.08)
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
        const t = stageRoot.theme || {};
        const pHex   = String(t.accentPrimary ?? "#cba6f7");
        const cHex   = String(t.accentCyan ?? "#89b4fa");
        const gHex   = String(t.accentGreen ?? "#a6e3a1");
        const oHex   = String(t.accentOrange ?? "#fab387");
        const rHex   = String(t.accentRed ?? "#f38ba8");
        const bgBase = String(t.bgBase ?? "#1e1e2e");
        const bgSurf = String(t.bgSurface ?? "#313244");
        const bgHov  = String(t.bgHover ?? "#45475a");
        const bgSel  = String(t.bgSelected ?? "#585b70");
        const txtPri = String(t.textPrimary ?? "#cdd6f4");
        const txtSec = String(t.textSecondary ?? "#bac2de");
        const txtMut = String(t.textMuted ?? "#a6adc8");

        const colorMap = {
            "$color0": bgSurf, "$color1": rHex, "$color2": gHex, "$color3": oHex,
            "$color4": cHex, "$color5": pHex, "$color6": cHex, "$color7": txtSec,
            "$color8": txtMut, "$color9": rHex, "$color10": txtSec, "$color11": oHex,
            "$color12": cHex, "$color13": pHex, "$color14": gHex, "$color15": txtPri,
            "$foreground": txtPri, "$background": bgBase,
            "$accentPrimary": pHex, "$accent": pHex,
            "$mauve": pHex, "$pink": pHex,
            "$blue": cHex, "$sapphire": cHex, "$sky": cHex, "$lavender": cHex,
            "$teal": gHex, "$green": gHex,
            "$yellow": oHex, "$peach": oHex,
            "$maroon": rHex, "$red": rHex, "$flamingo": rHex,
            "$rosewater": txtPri,
            "$text": txtPri, "$subtext1": txtSec, "$subtext0": txtMut,
            "$surface2": bgSel, "$surface1": bgHov, "$surface0": bgSurf,
            "$overlay2": txtMut, "$overlay1": bgSel, "$overlay0": bgHov,
            "$base": bgBase, "$mantle": bgBase, "$crust": bgBase
        };
        if (colorMap[str]) return colorMap[str];
        return "#ffffff";
    }

    function formatBlockText(blockData) {
        if (!blockData) return "";
        let n = String(blockData.name || "").trim();
        let nUp = n.toUpperCase();
        let raw = String(blockData.raw_text || "").trim();

        // When Preview Mode is OFF: show clean structural block labels unless it's a specific script
        if (!stageRoot.previewMode) {
            if (n === "Hour-Time") return "08:22 AM";
            if (n === "Date") return "Sunday, 18 October";
            if (n === "USER") return "$USER";
            if (n === "Keyboard LAYOUT") return "$LAYOUT";
            if (n === "uptime") return "up 9h 50m";
            if (n === "battery information") return "󰂄 95%";
            if (n === "weather") return "⛅ 31°C";
            return n;
        }

        // When Preview Mode is ON: evaluate real live TIME, DATE, USER, LAYOUT, uptime, weather, etc.
        let now = stageRoot.currentNow || new Date();
        if (nUp === "TIME" || nUp === "HOUR-TIME" || nUp === "CLOCK" || raw.indexOf("$TIME") !== -1 || raw.indexOf("%H:%M") !== -1 || raw.indexOf("%I:%M") !== -1) {
            if (raw.indexOf("%I") !== -1) {
                return Qt.formatDateTime(now, "hh:mm AP");
            }
            return Qt.formatDateTime(now, "hh:mm");
        }
        if (nUp === "DATE" || raw.indexOf("%A") !== -1 || raw.indexOf("%B") !== -1 || raw.indexOf("%d") !== -1) {
            return Qt.formatDateTime(now, "dddd, dd MMMM");
        }
        if (nUp === "LAYOUT" || nUp === "KEYBOARD LAYOUT" || raw.indexOf("$LAYOUT") !== -1) {
            if (raw.toLowerCase().indexOf("layout:") !== -1) return "Layout: English (US)";
            return "English (US)";
        }
        if (nUp === "USER" || raw.indexOf("$USER") !== -1) {
            return "xeana";
        }
        if (nUp.indexOf("UPTIME") !== -1 || raw.indexOf("uptime") !== -1) {
            return "up 9h 50m";
        }
        if (nUp.indexOf("BATTERY") !== -1 || raw.indexOf("battery") !== -1) {
            return "󰂄 95%";
        }
        if (nUp.indexOf("WEATHER") !== -1 || raw.indexOf("weather") !== -1) {
            return "⛅ 28°C Clear";
        }
        return n;
    }

    // Compute magnetic snap targets across canvas edges, center axes, and other blocks
    function applyMagneticSnap(itemX, itemY, itemW, itemH, excludeIdx) {
        if (!stageRoot.snapEnabled) {
            dragGuides.snapVerticalActive = false;
            dragGuides.snapHorizontalActive = false;
            return { x: itemX, y: itemY };
        }

        const threshold = 9;
        const cW = canvasBox.width;
        const cH = canvasBox.height;
        const margin = Math.round(30 * canvasBox.scaleFactor);

        let snappedX = itemX;
        let snappedY = itemY;
        let vGuide = -1;
        let hGuide = -1;

        let curLeft = itemX;
        let curCenterX = itemX + itemW / 2;
        let curRight = itemX + itemW;

        let curTop = itemY;
        let curCenterY = itemY + itemH / 2;
        let curBottom = itemY + itemH;

        // 1. Canvas X targets (Center, Left/Right margins, Thirds)
        let xTargets = [
            { pos: cW / 2, type: "center" },
            { pos: margin, type: "left" },
            { pos: cW - margin, type: "right" }
        ];
        // 2. Canvas Y targets (Center, Top/Bottom margins)
        let yTargets = [
            { pos: cH / 2, type: "center" },
            { pos: margin, type: "top" },
            { pos: cH - margin, type: "bottom" }
        ];

        // 3. Add other blocks & password input as alignment targets
        if (excludeIdx !== -2) {
            xTargets.push({ pos: simInputBox.x + simInputBox.width / 2, type: "center" });
            xTargets.push({ pos: simInputBox.x, type: "left" });
            xTargets.push({ pos: simInputBox.x + simInputBox.width, type: "right" });
            yTargets.push({ pos: simInputBox.y + simInputBox.height / 2, type: "center" });
        }

        for (let i = 0; i < blocksRepeater.count; i++) {
            if (i === excludeIdx) continue;
            let other = blocksRepeater.itemAt(i);
            if (!other) continue;
            xTargets.push({ pos: other.x + other.width / 2, type: "center" });
            xTargets.push({ pos: other.x, type: "left" });
            xTargets.push({ pos: other.x + other.width, type: "right" });
            yTargets.push({ pos: other.y + other.height / 2, type: "center" });
            yTargets.push({ pos: other.y, type: "top" });
            yTargets.push({ pos: other.y + other.height, type: "bottom" });
        }

        let bestDx = threshold;
        for (let t of xTargets) {
            if (t.type === "center" && Math.abs(curCenterX - t.pos) < bestDx) {
                bestDx = Math.abs(curCenterX - t.pos);
                snappedX = t.pos - itemW / 2;
                vGuide = t.pos;
            } else if (t.type === "left" && Math.abs(curLeft - t.pos) < bestDx) {
                bestDx = Math.abs(curLeft - t.pos);
                snappedX = t.pos;
                vGuide = t.pos;
            } else if (t.type === "right" && Math.abs(curRight - t.pos) < bestDx) {
                bestDx = Math.abs(curRight - t.pos);
                snappedX = t.pos - itemW;
                vGuide = t.pos;
            }
        }

        let bestDy = threshold;
        for (let t of yTargets) {
            if (t.type === "center" && Math.abs(curCenterY - t.pos) < bestDy) {
                bestDy = Math.abs(curCenterY - t.pos);
                snappedY = t.pos - itemH / 2;
                hGuide = t.pos;
            } else if (t.type === "top" && Math.abs(curTop - t.pos) < bestDy) {
                bestDy = Math.abs(curTop - t.pos);
                snappedY = t.pos;
                hGuide = t.pos;
            } else if (t.type === "bottom" && Math.abs(curBottom - t.pos) < bestDy) {
                bestDy = Math.abs(curBottom - t.pos);
                snappedY = t.pos - itemH;
                hGuide = t.pos;
            }
        }

        dragGuides.snapVerticalActive = (vGuide >= 0);
        dragGuides.snapHorizontalActive = (hGuide >= 0);
        if (vGuide >= 0) dragGuides.snapLineX = vGuide;
        if (hGuide >= 0) dragGuides.snapLineY = hGuide;

        return { x: snappedX, y: snappedY };
    }

    function syncBlocks() {
        if (!stageRoot.hasUnsavedMoves) {
            stageRoot.liveInputX = stageRoot.inputPosX;
            stageRoot.liveInputY = stageRoot.inputPosY;
            if (stageRoot.textBlocks) {
                let arr = [];
                for (let i = 0; i < stageRoot.textBlocks.length; i++) {
                    let b = stageRoot.textBlocks[i];
                    let px = b.position_x !== undefined ? b.position_x : 0;
                    let py = b.position_y !== undefined ? b.position_y : 0;
                    let ha = b.halign || "center";
                    let va = b.valign || "center";

                    // Auto-normalize legacy extreme offsets where center/corner blocks had old edge anchors:
                    // 1. Blocks dragged to center with halign="right" and position_x around -830 -> halign="center", x=0
                    if (ha === "right" && px < -600 && px > -1100) {
                        ha = "center";
                        px = 0;
                    } else if (ha === "left" && px > 600 && px < 1100) {
                        ha = "center";
                        px = 0;
                    }
                    // 2. Blocks dragged to bottom-right with halign="left", valign="top" (e.g. x=1665, y=-988)
                    if (ha === "left" && px > 1200) {
                        ha = "right";
                        px = Math.max(-300, px - 1800);
                    }
                    if (va === "top" && py < -750) {
                        va = "bottom";
                        py = Math.max(20, 1050 + py);
                    }

                    arr.push({
                        index: b.index !== undefined ? b.index : i,
                        name: b.name || ("Block " + (i + 1)),
                        enabled: b.enabled !== undefined ? b.enabled : true,
                        is_cmd: !!b.is_cmd,
                        raw_text: b.raw_text || "",
                        font_size: b.font_size || 14,
                        font_family: b.font_family || "Victor Mono Bold Oblique",
                        position_x: px,
                        position_y: py,
                        halign: ha,
                        valign: va,
                        color: b.color || "$color8"
                    });
                }
                stageRoot.liveBlocks = arr;
            }
        }
    }

    onTextBlocksChanged: syncBlocks()
    onInputPosXChanged: if (!stageRoot.hasUnsavedMoves) stageRoot.liveInputX = stageRoot.inputPosX
    onInputPosYChanged: if (!stageRoot.hasUnsavedMoves) stageRoot.liveInputY = stageRoot.inputPosY
    Component.onCompleted: syncBlocks()

    ColumnLayout {
        id: mainCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 14
        }
        spacing: 10

        // --- Header Bar ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

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
                    text: stageRoot.previewMode
                        ? "Live Preview Mode active: rendering real clock, date, and lock screen typography"
                        : "Drag any label or password box across the screen (snaps to center & sibling edges)"
                    font.family: stageRoot.font
                    font.pixelSize: 11
                    color: stageRoot.theme ? (stageRoot.theme.textSecondary ?? "#a6adc8") : "#a6adc8"
                }
            }

            Item { Layout.fillWidth: true }

            // Action & Mode Buttons
            RowLayout {
                spacing: 6
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                // Snap Toggle Button
                Rectangle {
                    implicitWidth: snapToggleRow.implicitWidth + 16
                    height: 28
                    radius: 7
                    color: stageRoot.snapEnabled
                        ? (stageRoot.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                        : (snapToggleHover.hovered ? (stageRoot.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (stageRoot.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)))
                    border.color: stageRoot.snapEnabled
                        ? (stageRoot.theme.accentPrimary ?? "#7aa2f7")
                        : (stageRoot.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1
                    scale: snapToggleMouse.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    HoverHandler { id: snapToggleHover }

                    RowLayout {
                        id: snapToggleRow
                        anchors.centerIn: parent
                        spacing: 5
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: stageRoot.snapEnabled ? (stageRoot.theme.accentPrimary ?? "#7aa2f7") : (stageRoot.theme.textSecondary ?? "#a6adc8")
                        }
                        Text {
                            text: "Snap"
                            font.family: stageRoot.font
                            font.pixelSize: 10
                            font.bold: stageRoot.snapEnabled
                            color: stageRoot.snapEnabled ? (stageRoot.theme.accentPrimary ?? "#7aa2f7") : (stageRoot.theme.textPrimary ?? "#ffffff")
                        }
                    }

                    MouseArea {
                        id: snapToggleMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: stageRoot.snapEnabled = !stageRoot.snapEnabled
                    }
                }

                // Live Preview Toggle Button (renders real TIME / DATE without block chrome)
                Rectangle {
                    implicitWidth: previewToggleRow.implicitWidth + 18
                    height: 28
                    radius: 7
                    color: stageRoot.previewMode
                        ? (stageRoot.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                        : (previewToggleHover.hovered ? (stageRoot.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (stageRoot.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)))
                    border.color: stageRoot.previewMode
                        ? (stageRoot.theme.accentPrimary ?? "#7aa2f7")
                        : (stageRoot.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1
                    scale: previewToggleMouse.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    HoverHandler { id: previewToggleHover }

                    RowLayout {
                        id: previewToggleRow
                        anchors.centerIn: parent
                        spacing: 5
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: stageRoot.previewMode ? "#a6e3a1" : (stageRoot.theme.textSecondary ?? "#a6adc8")
                        }
                        Text {
                            text: stageRoot.previewMode ? "Preview: ON" : "Preview"
                            font.family: stageRoot.font
                            font.pixelSize: 10
                            font.bold: stageRoot.previewMode
                            color: stageRoot.previewMode ? (stageRoot.theme.accentPrimary ?? "#7aa2f7") : (stageRoot.theme.textPrimary ?? "#ffffff")
                        }
                    }

                    MouseArea {
                        id: previewToggleMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            stageRoot.currentNow = new Date();
                            stageRoot.previewMode = !stageRoot.previewMode;
                        }
                    }
                }

                // Snap Selected to Center X: 0
                Rectangle {
                    visible: (stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < stageRoot.liveBlocks.length) || stageRoot.selectedIndex === -2
                    implicitWidth: snapText.implicitWidth + 16
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
                            if (stageRoot.selectedIndex === -2) {
                                stageRoot.liveInputX = 0;
                                stageRoot.hasUnsavedMoves = true;
                                stageRoot.inputMoved(0, stageRoot.liveInputY);
                                stageRoot.refreshTrigger++;
                            } else if (stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < stageRoot.liveBlocks.length) {
                                let b = stageRoot.liveBlocks[stageRoot.selectedIndex];
                                let curCenterY = 0;
                                let itemEl = blocksRepeater.itemAt(stageRoot.selectedIndex);
                                if (itemEl) {
                                    curCenterY = itemEl.y + itemEl.height / 2;
                                }
                                b.halign = "center";
                                b.position_x = 0;
                                stageRoot.hasUnsavedMoves = true;
                                stageRoot.blockMoved(stageRoot.selectedIndex, 0, b.position_y);
                                stageRoot.liveBlocks = stageRoot.liveBlocks.slice();
                                stageRoot.refreshTrigger++;
                            }
                        }
                    }
                }

                // Reset Positions Button
                Rectangle {
                    visible: stageRoot.hasUnsavedMoves
                    implicitWidth: resetText.implicitWidth + 16
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

        // --- Quick Password Input Color Bar (Visible when Password Input is clicked on stage) ---
        Rectangle {
            visible: stageRoot.selectedIndex === -2
            Layout.fillWidth: true
            height: 36
            radius: 8
            color: stageRoot.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
            border.color: stageRoot.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "Password Box Color:"
                    font.family: stageRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: stageRoot.theme.textSecondary
                }

                Repeater {
                    model: [
                        { name: "Accent", outer: "$accent", inner: "$surface0", font: "$text", hex: String(stageRoot.theme.accentPrimary ?? "#cba6f7") },
                        { name: "Blue / Cyan", outer: "$blue", inner: "$surface0", font: "$text", hex: String(stageRoot.theme.accentCyan ?? "#89b4fa") },
                        { name: "Green", outer: "$green", inner: "$surface0", font: "$text", hex: String(stageRoot.theme.accentGreen ?? "#a6e3a1") },
                        { name: "Orange", outer: "$peach", inner: "$surface0", font: "$text", hex: String(stageRoot.theme.accentOrange ?? "#fab387") },
                        { name: "Red", outer: "$red", inner: "$surface0", font: "$text", hex: String(stageRoot.theme.accentRed ?? "#f38ba8") },
                        { name: "Bright Text", outer: "$text", inner: "$surface0", font: "$text", hex: String(stageRoot.theme.textPrimary ?? "#cdd6f4") },
                        { name: "Minimal Dark", outer: "$surface2", inner: "$base", font: "$text", hex: String(stageRoot.theme.bgSelected ?? "#585b70") }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isSel: stageRoot.inputOuterColor === modelData.outer && stageRoot.inputInnerColor === modelData.inner
                        implicitWidth: pColRow.implicitWidth + 12
                        height: 24
                        radius: 5
                        color: isSel ? stageRoot.theme.bgSelected : (pColHover.hovered ? (stageRoot.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                        border.color: isSel ? stageRoot.theme.accentPrimary : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 140 } }
                        HoverHandler { id: pColHover }

                        RowLayout {
                            id: pColRow
                            anchors.centerIn: parent
                            spacing: 4
                            Rectangle {
                                width: 9; height: 9; radius: 4.5
                                color: modelData.hex
                                border.color: Qt.rgba(0, 0, 0, 0.3); border.width: 1
                            }
                            Text {
                                text: modelData.name
                                font.family: stageRoot.font
                                font.pixelSize: 10
                                font.bold: isSel
                                color: isSel ? stageRoot.theme.accentPrimary : stageRoot.theme.textPrimary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: stageRoot.inputColorModified(modelData.outer, modelData.inner, modelData.font)
                        }
                    }
                }

                Item { Layout.fillWidth: true }
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

            // Click empty background to deselect
            MouseArea {
                anchors.fill: parent
                z: 0
                onClicked: stageRoot.selectedIndex = -1
            }

            // 1. Wallpaper Background with blur & exposure simulation
            Image {
                id: bgImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: stageRoot.wallpaperPath !== "" ? (stageRoot.wallpaperPath.startsWith("/") ? ("file://" + stageRoot.wallpaperPath) : stageRoot.wallpaperPath) : ""
                sourceSize.width: 960
                sourceSize.height: 540
                cache: false
                asynchronous: true
                opacity: Math.max(0.2, Math.min(1.0, stageRoot.brightness))
                visible: source != ""
            }

            // Dark vignette backdrop overlay
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, Math.min(0.65, Math.max(0.2, 0.5 * (1.5 - stageRoot.brightness))))
            }

            // 2. Faint Center Crosshair Guidelines (Hidden in Preview Mode unless dragging)
            Rectangle {
                visible: !stageRoot.previewMode
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            Rectangle {
                visible: !stageRoot.previewMode
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // 3. Central Anchor Marker
            Rectangle {
                visible: !stageRoot.previewMode
                anchors.centerIn: parent
                width: 5
                height: 5
                radius: 2.5
                color: Qt.rgba(1, 1, 1, 0.15)
            }

            // 4. Interactive Draggable Password Input Field (Colored with outer_color, inner_color, font_color)
            Rectangle {
                id: simInputBox
                readonly property real simW: Math.max(70, stageRoot.inputWidth * canvasBox.scaleFactor)
                readonly property real simH: Math.max(16, stageRoot.inputHeight * canvasBox.scaleFactor)
                readonly property bool isInputSelected: stageRoot.selectedIndex === -2
                readonly property color resolvedOuter: stageRoot.resolveColor(stageRoot.inputOuterColor)
                readonly property color resolvedInner: stageRoot.resolveColor(stageRoot.inputInnerColor)
                readonly property color resolvedFont: stageRoot.resolveColor(stageRoot.inputFontColor)

                width: simW
                height: simH
                radius: simH / 2
                z: isInputSelected || inputDragArea.drag.active ? 15 : 3

                function updateInputCoords() {
                    if (inputDragArea.drag.active) return;
                    let sFactor = canvasBox.scaleFactor;
                    let curX = stageRoot.liveInputX;
                    let curY = stageRoot.liveInputY;

                    let targetX = 0;
                    if (stageRoot.inputHalign === "center") {
                        targetX = (canvasBox.width / 2) + (curX * sFactor) - (width / 2);
                    } else if (stageRoot.inputHalign === "right") {
                        targetX = canvasBox.width + (curX * sFactor) - width;
                    } else {
                        targetX = curX * sFactor;
                    }

                    let targetY = 0;
                    if (stageRoot.inputValign === "center") {
                        targetY = (canvasBox.height / 2) - (curY * sFactor) - (height / 2);
                    } else if (stageRoot.inputValign === "bottom") {
                        targetY = canvasBox.height - (curY * sFactor) - height;
                    } else {
                        targetY = -(curY * sFactor);
                    }

                    x = Math.round(targetX);
                    y = Math.round(targetY);
                }

                Component.onCompleted: updateInputCoords()
                onWidthChanged: updateInputCoords()
                onHeightChanged: updateInputCoords()

                Connections {
                    target: canvasBox
                    function onScaleFactorChanged() { simInputBox.updateInputCoords(); }
                }

                Connections {
                    target: stageRoot
                    function onLiveInputXChanged() { simInputBox.updateInputCoords(); }
                    function onLiveInputYChanged() { simInputBox.updateInputCoords(); }
                    function onRefreshTriggerChanged() { simInputBox.updateInputCoords(); }
                }

                color: Qt.rgba(resolvedInner.r, resolvedInner.g, resolvedInner.b, 0.88)
                border.color: (isInputSelected || inputDragArea.drag.active)
                    ? (stageRoot.theme.accentPrimary ?? resolvedOuter)
                    : resolvedOuter
                border.width: Math.max(1.5, Math.round(stageRoot.inputOutlineThickness * canvasBox.scaleFactor * 1.4))

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                HoverHandler { id: inputBoxHover }

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Repeater {
                        model: 5
                        Rectangle {
                            width: 4
                            height: 4
                            radius: 2
                            color: simInputBox.resolvedFont
                            opacity: 0.92
                        }
                    }
                }

                // Floating Coordinates & Color Badge for Password Input
                Rectangle {
                    visible: !stageRoot.previewMode && (simInputBox.isInputSelected || inputDragArea.drag.active || inputBoxHover.hovered)
                    anchors.bottom: parent.top
                    anchors.bottomMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: inputBadgeRow.implicitWidth + 14
                    height: 18
                    radius: 4
                    color: "#1e1e2e"
                    border.color: stageRoot.theme.accentPrimary ?? "#7aa2f7"
                    border.width: 1
                    z: 20

                    RowLayout {
                        id: inputBadgeRow
                        anchors.centerIn: parent
                        spacing: 4
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: simInputBox.resolvedOuter
                        }
                        Text {
                            id: inputBadgeTxt
                            text: "Password (" + stageRoot.liveInputX + ", " + stageRoot.liveInputY + ") • " + stageRoot.inputOuterColor
                            font.family: stageRoot.font
                            font.pixelSize: 9
                            font.bold: true
                            color: stageRoot.theme.accentPrimary ?? "#7aa2f7"
                        }
                    }
                }

                MouseArea {
                    id: inputDragArea
                    anchors.fill: parent
                    preventStealing: true
                    drag.target: simInputBox
                    drag.axis: Drag.XAndYAxis
                    drag.minimumX: 0
                    drag.maximumX: Math.max(0, canvasBox.width - simInputBox.width)
                    drag.minimumY: 0
                    drag.maximumY: Math.max(0, canvasBox.height - simInputBox.height)
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    onPressed: {
                        stageRoot.selectedIndex = -2;
                        dragGuides.targetCenterX = simInputBox.x + simInputBox.width / 2;
                        dragGuides.targetCenterY = simInputBox.y + simInputBox.height / 2;
                    }

                    onPositionChanged: {
                        if (drag.active) {
                            let sFactor = canvasBox.scaleFactor;
                            let snapped = stageRoot.applyMagneticSnap(simInputBox.x, simInputBox.y, simInputBox.width, simInputBox.height, -2);
                            simInputBox.x = snapped.x;
                            simInputBox.y = snapped.y;

                            let curCenterX = simInputBox.x + simInputBox.width / 2;
                            let curCenterY = simInputBox.y + simInputBox.height / 2;

                            dragGuides.targetCenterX = curCenterX;
                            dragGuides.targetCenterY = curCenterY;

                            let rawX = 0;
                            if (stageRoot.inputHalign === "center") {
                                rawX = (curCenterX - (canvasBox.width / 2)) / sFactor;
                            } else if (stageRoot.inputHalign === "right") {
                                rawX = ((simInputBox.x + simInputBox.width) - canvasBox.width) / sFactor;
                            } else {
                                rawX = simInputBox.x / sFactor;
                            }

                            let rawY = 0;
                            if (stageRoot.inputValign === "center") {
                                rawY = ((canvasBox.height / 2) - curCenterY) / sFactor;
                            } else if (stageRoot.inputValign === "bottom") {
                                rawY = (canvasBox.height - (simInputBox.y + simInputBox.height)) / sFactor;
                            } else {
                                rawY = -(simInputBox.y) / sFactor;
                            }

                            let finalX = Math.round(rawX);
                            let finalY = Math.round(rawY);

                            if (stageRoot.liveInputX !== finalX || stageRoot.liveInputY !== finalY) {
                                stageRoot.liveInputX = finalX;
                                stageRoot.liveInputY = finalY;
                                stageRoot.hasUnsavedMoves = true;
                                stageRoot.inputMoved(finalX, finalY);
                            }
                        }
                    }

                    onReleased: {
                        dragGuides.snapVerticalActive = false;
                        dragGuides.snapHorizontalActive = false;
                        dragGuides.targetCenterX = simInputBox.x + simInputBox.width / 2;
                        dragGuides.targetCenterY = simInputBox.y + simInputBox.height / 2;
                        simInputBox.updateInputCoords();
                    }
                }
            }

            // 5. Active Crosshair & Magnetic Snap Guide Lines for Dragged Element
            Item {
                id: dragGuides
                anchors.fill: parent
                visible: (!stageRoot.previewMode && (stageRoot.selectedIndex >= 0 || stageRoot.selectedIndex === -2)) || snapVerticalActive || snapHorizontalActive

                property real targetCenterX: 0
                property real targetCenterY: 0
                property bool snapVerticalActive: false
                property bool snapHorizontalActive: false
                property real snapLineX: 0
                property real snapLineY: 0

                // Element Center Vertical Guide
                Rectangle {
                    visible: !stageRoot.previewMode
                    x: dragGuides.targetCenterX
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: stageRoot.theme.accentPrimary ?? "#7aa2f7"
                    opacity: 0.35
                }

                // Element Center Horizontal Guide
                Rectangle {
                    visible: !stageRoot.previewMode
                    y: dragGuides.targetCenterY
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: stageRoot.theme.accentPrimary ?? "#7aa2f7"
                    opacity: 0.35
                }

                // Highlighted Magnetic Snap Line (Vertical)
                Rectangle {
                    visible: dragGuides.snapVerticalActive
                    x: dragGuides.snapLineX
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1.5
                    color: "#a6e3a1"
                    opacity: 0.85
                    z: 25
                }

                // Highlighted Magnetic Snap Line (Horizontal)
                Rectangle {
                    visible: dragGuides.snapHorizontalActive
                    y: dragGuides.snapLineY
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1.5
                    color: "#a6e3a1"
                    opacity: 0.85
                    z: 25
                }
            }

            // 6. Interactive Draggable Blocks
            Repeater {
                id: blocksRepeater
                model: stageRoot.liveBlocks

                Item {
                    id: blockDelegate
                    property var blockData: modelData
                    property int blockIdx: index
                    readonly property bool isSelected: stageRoot.selectedIndex === blockIdx
                    readonly property real sFactor: canvasBox.scaleFactor

                    // In Preview Mode, hide disabled blocks just like real hyprlock
                    visible: !stageRoot.previewMode || (blockData && blockData.enabled)

                    // Fixed padding so switching Preview ON/OFF never changes box dimensions or shifts halign
                    width: contentRow.implicitWidth + 14
                    height: Math.max(22, contentRow.implicitHeight + 8)

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

                        // Clamp inside stage bounds so offscreen coordinates never clip outside
                        targetX = Math.max(4, Math.min(canvasBox.width - width - 4, targetX));
                        targetY = Math.max(4, Math.min(canvasBox.height - height - 4, targetY));

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
                        function onPreviewModeChanged() {
                            blockDelegate.updateCoords();
                        }
                    }

                    z: isSelected || blockDragArea.drag.active ? 15 : 2

                    // Live Pill Representation (or clean borderless text in Preview Mode)
                    Rectangle {
                        id: blockPill
                        anchors.fill: parent
                        radius: 5
                        color: stageRoot.previewMode
                            ? (blockDragArea.drag.active || blockPillHover.hovered ? Qt.rgba(0, 0, 0, 0.35) : "transparent")
                            : (blockDragArea.drag.active
                                ? Qt.rgba(stageRoot.theme.accentPrimary.r, stageRoot.theme.accentPrimary.g, stageRoot.theme.accentPrimary.b, 0.35)
                                : (isSelected
                                    ? Qt.rgba(stageRoot.theme.accentPrimary.r, stageRoot.theme.accentPrimary.g, stageRoot.theme.accentPrimary.b, 0.22)
                                    : (blockPillHover.hovered ? Qt.rgba(0, 0, 0, 0.7) : Qt.rgba(0, 0, 0, 0.55))))
                        border.color: stageRoot.previewMode
                            ? (blockDragArea.drag.active || blockPillHover.hovered ? Qt.rgba(1, 1, 1, 0.35) : "transparent")
                            : ((isSelected || blockDragArea.drag.active)
                                ? (stageRoot.theme.accentPrimary ?? "#7aa2f7")
                                : (blockPillHover.hovered ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(1, 1, 1, 0.15)))
                        border.width: (isSelected || blockDragArea.drag.active) ? 1.5 : 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        HoverHandler { id: blockPillHover }

                        Row {
                            id: contentRow
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: blockDelegate.blockData.halign === "left" ? parent.left : undefined
                            anchors.leftMargin: blockDelegate.blockData.halign === "left" ? 7 : 0
                            anchors.right: blockDelegate.blockData.halign === "right" ? parent.right : undefined
                            anchors.rightMargin: blockDelegate.blockData.halign === "right" ? 7 : 0
                            anchors.horizontalCenter: blockDelegate.blockData.halign === "center" ? parent.horizontalCenter : undefined
                            spacing: stageRoot.previewMode ? 0 : 6

                            // Color indicator dot (hidden in Preview Mode so it looks like real lockscreen)
                            Rectangle {
                                visible: !stageRoot.previewMode
                                width: 6
                                height: 6
                                radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: stageRoot.resolveColor(blockDelegate.blockData.color)
                            }

                            // Simulated Content Text scaled accurately to real screen proportions
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: {
                                    let f = String(blockDelegate.blockData.font_family || "").trim();
                                    if (!f || f === "$font") return "JetBrainsMono Nerd Font";
                                    return f.replace(/\s+\d+$/, "");
                                }
                                font.pixelSize: Math.max(9, Math.round(blockDelegate.blockData.font_size * blockDelegate.sFactor * 0.95))
                                font.bold: true
                                color: blockDelegate.blockData.enabled
                                    ? ((!stageRoot.previewMode && blockDelegate.isSelected) ? (stageRoot.theme.accentPrimary ?? "#7aa2f7") : stageRoot.resolveColor(blockDelegate.blockData.color))
                                    : "#6c7086"
                                text: stageRoot.formatBlockText(blockDelegate.blockData)
                            }
                        }

                        // Floating Coordinates Badge (Visible when hovered, selected, or dragged)
                        Rectangle {
                            visible: (!stageRoot.previewMode && (blockDelegate.isSelected || blockDragArea.drag.active || blockPillHover.hovered)) || (stageRoot.previewMode && blockDragArea.drag.active)
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
                                let snapped = stageRoot.applyMagneticSnap(blockDelegate.x, blockDelegate.y, blockDelegate.width, blockDelegate.height, blockDelegate.blockIdx);
                                blockDelegate.x = snapped.x;
                                blockDelegate.y = snapped.y;

                                let curCenterX = blockDelegate.x + blockDelegate.width / 2;
                                let curCenterY = blockDelegate.y + blockDelegate.height / 2;

                                dragGuides.targetCenterX = curCenterX;
                                dragGuides.targetCenterY = curCenterY;

                                // Smart auto-halign: if dragged into the middle 30% of the screen, anchor to "center"
                                // so variable-length text (like DATE vs "Tuesday, 27 October") stays centered!
                                let newHalign = blockDelegate.blockData.halign;
                                if (curCenterX > canvasBox.width * 0.35 && curCenterX < canvasBox.width * 0.65) {
                                    newHalign = "center";
                                } else if (curCenterX <= canvasBox.width * 0.35) {
                                    newHalign = "left";
                                } else {
                                    newHalign = "right";
                                }
                                blockDelegate.blockData.halign = newHalign;

                                // Smart auto-valign: top 35% -> "top", middle 30% -> "center", bottom 35% -> "bottom"
                                let newValign = blockDelegate.blockData.valign;
                                if (curCenterY < canvasBox.height * 0.35) {
                                    newValign = "top";
                                } else if (curCenterY > canvasBox.height * 0.65) {
                                    newValign = "bottom";
                                } else {
                                    newValign = "center";
                                }
                                blockDelegate.blockData.valign = newValign;

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

                                if (blockDelegate.blockData.position_x !== finalX || blockDelegate.blockData.position_y !== finalY) {
                                    blockDelegate.blockData.position_x = finalX;
                                    blockDelegate.blockData.position_y = finalY;

                                    if (stageRoot.liveBlocks && blockDelegate.blockIdx >= 0 && blockDelegate.blockIdx < stageRoot.liveBlocks.length) {
                                        stageRoot.liveBlocks[blockDelegate.blockIdx].position_x = finalX;
                                        stageRoot.liveBlocks[blockDelegate.blockIdx].position_y = finalY;
                                        stageRoot.liveBlocks[blockDelegate.blockIdx].halign = newHalign;
                                        stageRoot.liveBlocks[blockDelegate.blockIdx].valign = newValign;
                                    }

                                    stageRoot.hasUnsavedMoves = true;
                                    stageRoot.blockMoved(blockDelegate.blockIdx, finalX, finalY);
                                }
                            }
                        }

                        onReleased: {
                            dragGuides.snapVerticalActive = false;
                            dragGuides.snapHorizontalActive = false;
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

