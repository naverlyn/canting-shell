/*
 * LockscreenStageSandbox.qml
 *
 * Interactive visual canvas / sandbox for Quickshell lock screen layout.
 * Allows users to visually preview and drag-and-drop building block modules
 * across a simulated 16:9 screen canvas with real-time reactive sync.
 * Synchronizes Cartesian coordinates (halign, valign, position_x, position_y) in real-time,
 * supports magnetic window/element snapping, live Preview mode (rendering real TIME/DATE),
 * and interactive Password Input coloring.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../wallpaper"
import "../../bar"
import "../../Lockscreen"
import "../../Lockscreen/Modules"

Rectangle {
    id: stageRoot

    property var theme: DefaultTheme {}
    property string font: "Lato Nerd Font"
    property var textBlocks: []
    property int selectedIndex: -1
    property bool hasUnsavedMoves: false
    property int refreshTrigger: 0

    readonly property bool hasAuthModule: {
        if (!liveBlocks) return false;
        for (let i = 0; i < liveBlocks.length; i++) {
            if (liveBlocks[i] && liveBlocks[i].type === "auth") return true;
        }
        return false;
    }

    // Interactive Stage Controls
    property bool previewMode: false
    property bool snapEnabled: true
    property var currentNow: new Date()
    property bool showUser: true
    property bool showMedia: true
    property string username: Quickshell.env("USER") || "xeana"
    property string keyboardLayout: "English (US)"

    Process {
        id: layoutQueryProc
        command: ["sh", "-c", "hyprctl devices -j 2>/dev/null | jq -r '(.keyboards[] | select(.main == true) | .active_keymap) // \"English (US)\"' 2>/dev/null || echo 'English (US)'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const cleaned = text.trim();
                if (cleaned) stageRoot.keyboardLayout = cleaned;
            }
        }
    }

    Timer {
        interval: 15000
        running: stageRoot.previewMode
        repeat: true
        onTriggered: stageRoot.currentNow = new Date()
    }

    property string wallpaperPath: ""
    property real brightness: 0.8
    property real contrast: 1.25
    property int blurPasses: 2
    property int blurSize: 3
    property real vibrancy: 0.21

    property int inputWidth: 260
    property int inputHeight: 56
    property int inputOutlineThickness: 2
    property string inputPlaceholder: "Type Password"
    property int inputPosX: 0
    property int inputPosY: 0
    property string inputHalign: "center"
    property string inputValign: "center"
    property string inputOuterColor: "$accent"
    property string inputInnerColor: "$surface0"
    property string inputFontColor: "$text"

    property int liveInputX: 0
    property int liveInputY: 0

    signal blockMoved(int index, int newX, int newY, string newHalign, string newValign)
    signal inputMoved(int newX, int newY, string newHalign, string newValign)
    signal inputColorModified(string outerCol, string innerCol, string fontCol)
    signal applyRequested(var blocks)
    signal resetRequested()
    signal deleteBlockRequested(int index)

    property alias canvasBoxRef: canvasBox

    function selectBlock(idx) {
        stageRoot.selectedIndex = idx;
    }

    function getCanvasDropCoords(fromItem, itemX, itemY) {
        const pt = canvasBox.mapFromItem(fromItem, itemX, itemY);
        const inside = (pt.x >= 0 && pt.x <= canvasBox.width && pt.y >= 0 && pt.y <= canvasBox.height);
        if (!inside) return null;

        const sFactor = canvasBox.scaleFactor;
        const curCenterX = pt.x;
        const curCenterY = pt.y;

        let newHalign = "center";
        if (curCenterX <= canvasBox.width * 0.35) newHalign = "left";
        else if (curCenterX >= canvasBox.width * 0.65) newHalign = "right";

        let newValign = "center";
        if (curCenterY <= canvasBox.height * 0.35) newValign = "top";
        else if (curCenterY >= canvasBox.height * 0.65) newValign = "bottom";

        let rawX = 0;
        if (newHalign === "center") rawX = (curCenterX - (canvasBox.width / 2)) / sFactor;
        else if (newHalign === "right") rawX = (curCenterX - canvasBox.width) / sFactor;
        else rawX = curCenterX / sFactor;

        let rawY = 0;
        if (newValign === "center") rawY = ((canvasBox.height / 2) - curCenterY) / sFactor;
        else if (newValign === "bottom") rawY = (canvasBox.height - curCenterY) / sFactor;
        else rawY = -curCenterY / sFactor;

        return {
            halign: newHalign,
            valign: newValign,
            position_x: Math.round(rawX),
            position_y: Math.round(rawY)
        };
    }

    Layout.fillWidth: true
    implicitHeight: mainCol.implicitHeight + 28
    radius: 12
    color: stageRoot.theme.bgSurface
    border.color: stageRoot.theme.bgBorder
    border.width: 1
    clip: true

    // Internal live block working state
    property var liveBlocks: []

    function resolveColor(colStr) {
        const t = stageRoot.theme;
        if (!colStr) return t.textPrimary;
        let str = String(colStr).trim();
        if (str.startsWith("#")) return str;
        if (str.startsWith("rgb(") || str.startsWith("rgba(")) {
            let m = str.match(/rgba?\(\s*([0-9a-fA-F]{6})\s*\)/);
            if (m) return "#" + m[1];
            let m2 = str.match(/rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/);
            if (m2) return Qt.rgba(parseInt(m2[1])/255, parseInt(m2[2])/255, parseInt(m2[3])/255, 1);
        }
        const pHex   = t.accentPrimary;
        const cHex   = t.accentCyan;
        const gHex   = t.accentGreen;
        const oHex   = t.accentOrange;
        const rHex   = t.accentRed;
        const bgBase = t.bgBase;
        const bgSurf = t.bgSurface;
        const bgHov  = t.bgHover;
        const bgSel  = t.bgSelected;
        const txtPri = t.textPrimary;
        const txtSec = t.textSecondary;
        const txtMut = t.textMuted;

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
        return t.textPrimary;
    }

    function formatBlockText(blockData, cmdOutput) {
        if (!blockData) return "";
        let n = String(blockData.name || "").trim();
        let nUp = n.toUpperCase();
        let raw = String(blockData.raw_text || "").trim();

        // If block has active command output (e.g. weather cache, uptime), use it so visual proportions match
        if (blockData.is_cmd && cmdOutput) {
            return cmdOutput;
        }

        // When Preview Mode is OFF: show clean structural block labels unless it's a specific script
        if (!stageRoot.previewMode) {
            if (nUp === "TIME" || raw.indexOf("$TIME") !== -1) return "TIME";
            if (nUp === "DATE" || raw.indexOf("$DATE") !== -1) return "DATE";
            if (nUp === "USER" || raw.indexOf("$USER") !== -1) return stageRoot.username;
            if (nUp === "LAYOUT" || raw.indexOf("$LAYOUT") !== -1) return "LAYOUT";
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
            return Qt.formatDateTime(now, "dddd, dd MMMM yyyy");
        }
        if (nUp === "LAYOUT" || nUp === "KEYBOARD LAYOUT" || raw.indexOf("$LAYOUT") !== -1) {
            if (raw.toLowerCase().indexOf("layout:") !== -1) return "Layout: " + stageRoot.keyboardLayout;
            return stageRoot.keyboardLayout;
        }
        if (nUp === "USER" || raw.indexOf("$USER") !== -1) {
            return stageRoot.username;
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
            xTargets.push({ pos: simAuthBox.x + simAuthBox.width / 2, type: "center" });
            xTargets.push({ pos: simAuthBox.x, type: "left" });
            xTargets.push({ pos: simAuthBox.x + simAuthBox.width, type: "right" });
            yTargets.push({ pos: simAuthBox.y + simAuthBox.height / 2, type: "center" });
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

    function removeModule(idx) {
        if (!stageRoot.liveBlocks || idx < 0 || idx >= stageRoot.liveBlocks.length) return;
        const targetBlock = stageRoot.liveBlocks[idx];
        const targetId = targetBlock ? (targetBlock.id || targetBlock.type) : null;

        stageRoot.selectedIndex = -1;
        stageRoot.hasUnsavedMoves = false;
        let list = [...stageRoot.liveBlocks];
        list.splice(idx, 1);
        for (let i = 0; i < list.length; i++) {
            list[i].index = i;
        }
        stageRoot.liveBlocks = list;
        stageRoot.deleteBlockRequested(idx);
        if (targetId && typeof LockscreenConfig !== "undefined" && LockscreenConfig.deleteModule) {
            LockscreenConfig.deleteModule(targetId);
        }
        stageRoot.refreshTrigger++;
    }

    function syncBlocks() {
        if (stageRoot.hasUnsavedMoves) return;
        stageRoot.liveInputX = stageRoot.inputPosX;
        stageRoot.liveInputY = stageRoot.inputPosY;
        if (stageRoot.textBlocks) {
            let arr = [];
            for (let i = 0; i < stageRoot.textBlocks.length; i++) {
                let b = stageRoot.textBlocks[i];
                let copy = Object.assign({}, b);
                copy.index = b.index !== undefined ? b.index : i;
                copy.type = b.type || "customText";
                copy.name = b.name || copy.type;
                copy.enabled = b.enabled !== undefined ? b.enabled : true;
                copy.position_x = b.position_x !== undefined ? b.position_x : 0;
                copy.position_y = b.position_y !== undefined ? b.position_y : 0;
                copy.halign = b.halign || "center";
                copy.valign = b.valign || "center";
                arr.push(copy);
            }
            stageRoot.liveBlocks = arr;
        } else {
            stageRoot.liveBlocks = [];
        }
    }

    onTextBlocksChanged: syncBlocks()
    onInputPosXChanged: stageRoot.liveInputX = stageRoot.inputPosX
    onInputPosYChanged: stageRoot.liveInputY = stageRoot.inputPosY
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
                        color: stageRoot.theme.textPrimary
                    }

                    // Live Unsaved Pill
                    Rectangle {
                        visible: stageRoot.hasUnsavedMoves
                        height: 18
                        implicitWidth: unBadgeText.implicitWidth + 10
                        radius: 4
                        color: Qt.rgba(stageRoot.theme.accentOrange.r, stageRoot.theme.accentOrange.g, stageRoot.theme.accentOrange.b, 0.18)
                        border.color: Qt.rgba(stageRoot.theme.accentOrange.r, stageRoot.theme.accentOrange.g, stageRoot.theme.accentOrange.b, 0.4)
                        border.width: 1

                        Text {
                            id: unBadgeText
                            anchors.centerIn: parent
                            text: "Unsaved Moves"
                            font.family: stageRoot.font
                            font.pixelSize: 9
                            font.bold: true
                            color: stageRoot.theme.accentOrange
                        }
                    }
                }

                Text {
                    text: stageRoot.previewMode
                        ? "Live Preview Mode active: rendering real clock, date, and lock screen typography"
                        : "Drag any label or password box across the screen (snaps to center & sibling edges)"
                    font.family: stageRoot.font
                    font.pixelSize: 11
                    color: stageRoot.theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Item { Layout.fillWidth: true }

            // Action & Mode Buttons
            RowLayout {
                spacing: 6
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: false
                Layout.preferredWidth: implicitWidth
                Layout.minimumWidth: implicitWidth

                // Snap Toggle Button
                Rectangle {
                    implicitWidth: snapLabel.implicitWidth + 20
                    Layout.preferredWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    height: 30
                    radius: 6
                    color: stageRoot.snapEnabled
                        ? stageRoot.theme.bgSelected
                        : (snapToggleHover.hovered ? stageRoot.theme.bgHover : stageRoot.theme.bgBase)
                    border.color: stageRoot.snapEnabled || snapToggleHover.hovered
                        ? stageRoot.theme.accentPrimary
                        : stageRoot.theme.bgBorder
                    border.width: 1
                    scale: snapToggleMouse.pressed ? 0.95 : 1.0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    HoverHandler { id: snapToggleHover }

                    Text {
                        id: snapLabel
                        anchors.centerIn: parent
                        text: "Snap"
                        font.family: stageRoot.font
                        font.pixelSize: 11
                        font.bold: true
                        color: stageRoot.snapEnabled ? stageRoot.theme.accentPrimary : stageRoot.theme.textPrimary
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                        id: snapToggleMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: stageRoot.snapEnabled = !stageRoot.snapEnabled
                    }
                }

                // Snap Selected to Center X: 0
                Rectangle {
                    visible: (stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < stageRoot.liveBlocks.length) || stageRoot.selectedIndex === -2
                    implicitWidth: snapText.implicitWidth + 20
                    Layout.preferredWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    height: 30
                    radius: 6
                    color: snapHover.hovered ? stageRoot.theme.bgHover : stageRoot.theme.bgBase
                    border.color: snapHover.hovered ? stageRoot.theme.accentPrimary : stageRoot.theme.bgBorder
                    border.width: 1
                    scale: snapMouse.pressed ? 0.95 : 1.0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    HoverHandler { id: snapHover }

                    Text {
                        id: snapText
                        anchors.centerIn: parent
                        text: "Center X: 0"
                        font.family: stageRoot.font
                        font.pixelSize: 11
                        font.bold: true
                        color: stageRoot.theme.textPrimary
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                        id: snapMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (stageRoot.selectedIndex === -2) {
                                stageRoot.liveInputX = 0;
                                stageRoot.inputHalign = "center";
                                stageRoot.hasUnsavedMoves = true;
                                stageRoot.inputMoved(0, stageRoot.liveInputY, "center", stageRoot.inputValign);
                                stageRoot.refreshTrigger++;
                            } else if (stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < stageRoot.liveBlocks.length) {
                                let b = stageRoot.liveBlocks[stageRoot.selectedIndex];
                                b.halign = "center";
                                b.position_x = 0;
                                stageRoot.hasUnsavedMoves = true;
                                stageRoot.blockMoved(stageRoot.selectedIndex, 0, b.position_y, "center", b.valign);
                                stageRoot.liveBlocks = stageRoot.liveBlocks.slice();
                                stageRoot.refreshTrigger++;
                            }
                        }
                    }
                }

                // Remove Selected Module Button
                Rectangle {
                    visible: stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < stageRoot.liveBlocks.length
                    implicitWidth: delSelRow.implicitWidth + 18
                    Layout.preferredWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    height: 30
                    radius: 6
                    color: delSelHover.hovered ? Qt.rgba(stageRoot.theme.accentRed.r, stageRoot.theme.accentRed.g, stageRoot.theme.accentRed.b, 0.22) : Qt.rgba(stageRoot.theme.accentRed.r, stageRoot.theme.accentRed.g, stageRoot.theme.accentRed.b, 0.12)
                    border.color: stageRoot.theme.accentRed
                    border.width: 1
                    scale: delSelMouse.pressed ? 0.95 : 1.0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    HoverHandler { id: delSelHover }

                    RowLayout {
                        id: delSelRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "✕"
                            font.family: stageRoot.font
                            font.pixelSize: 9
                            font.bold: true
                            color: stageRoot.theme.accentRed
                        }

                        Text {
                            text: "Remove"
                            font.family: stageRoot.font
                            font.pixelSize: 11
                            font.bold: true
                            color: stageRoot.theme.accentRed
                        }
                    }

                    MouseArea {
                        id: delSelMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: stageRoot.removeModule(stageRoot.selectedIndex)
                    }
                }

                // Reset Positions Button
                Rectangle {
                    visible: stageRoot.hasUnsavedMoves
                    implicitWidth: resetText.implicitWidth + 20
                    Layout.preferredWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    height: 30
                    radius: 6
                    color: resetHover.hovered ? stageRoot.theme.bgHover : stageRoot.theme.bgBase
                    border.color: resetHover.hovered ? stageRoot.theme.accentPrimary : stageRoot.theme.bgBorder
                    border.width: 1
                    scale: resetMouse.pressed ? 0.95 : 1.0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    HoverHandler { id: resetHover }

                    Text {
                        id: resetText
                        anchors.centerIn: parent
                        text: "Reset"
                        font.family: stageRoot.font
                        font.pixelSize: 11
                        font.bold: true
                        color: stageRoot.theme.textPrimary
                        Behavior on color { ColorAnimation { duration: 140 } }
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

                // Apply Layout / Save Positions Button
                Rectangle {
                    implicitWidth: applyText.implicitWidth + 24
                    Layout.preferredWidth: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    height: 30
                    radius: 6
                    color: stageRoot.hasUnsavedMoves
                        ? (applyHover.hovered ? Qt.rgba(stageRoot.theme.accentPrimary.r, stageRoot.theme.accentPrimary.g, stageRoot.theme.accentPrimary.b, 0.25) : stageRoot.theme.bgSelected)
                        : (applyHover.hovered ? stageRoot.theme.bgHover : stageRoot.theme.bgBase)
                    border.color: stageRoot.hasUnsavedMoves || applyHover.hovered
                        ? stageRoot.theme.accentPrimary
                        : stageRoot.theme.bgBorder
                    border.width: 1
                    scale: applyMouse.pressed ? 0.95 : 1.0

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    HoverHandler { id: applyHover }

                    Text {
                        id: applyText
                        anchors.centerIn: parent
                        text: stageRoot.hasUnsavedMoves ? "Apply Layout" : "Save Positions"
                        font.family: stageRoot.font
                        font.pixelSize: 11
                        font.bold: true
                        color: stageRoot.hasUnsavedMoves ? stageRoot.theme.accentPrimary : stageRoot.theme.textPrimary
                        Behavior on color { ColorAnimation { duration: 140 } }
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
            color: stageRoot.theme.bgBase
            border.color: stageRoot.theme.bgBorder
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
                        { name: "Accent", outer: "$accent", inner: "$surface0", font: "$text", hex: stageRoot.theme.accentPrimary },
                        { name: "Blue / Cyan", outer: "$blue", inner: "$surface0", font: "$text", hex: stageRoot.theme.accentCyan },
                        { name: "Green", outer: "$green", inner: "$surface0", font: "$text", hex: stageRoot.theme.accentGreen },
                        { name: "Orange", outer: "$peach", inner: "$surface0", font: "$text", hex: stageRoot.theme.accentOrange },
                        { name: "Red", outer: "$red", inner: "$surface0", font: "$text", hex: stageRoot.theme.accentRed },
                        { name: "Bright Text", outer: "$text", inner: "$surface0", font: "$text", hex: stageRoot.theme.textPrimary },
                        { name: "Minimal Dark", outer: "$surface2", inner: "$base", font: "$text", hex: stageRoot.theme.bgSelected }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isSel: stageRoot.inputOuterColor === modelData.outer && stageRoot.inputInnerColor === modelData.inner
                        implicitWidth: pColRow.implicitWidth + 12
                        height: 24
                        radius: 5
                        color: isSel ? stageRoot.theme.bgSelected : (pColHover.hovered ? stageRoot.theme.bgHover : "transparent")
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
            property bool isDropTarget: false
            Layout.fillWidth: true
            Layout.preferredHeight: width > 0 ? Math.round(width * (1080.0 / 1920.0)) : 380
            implicitHeight: Layout.preferredHeight
            height: Layout.preferredHeight
            radius: 10
            color: stageRoot.theme.bgBase
            border.color: canvasBox.isDropTarget
                ? stageRoot.theme.accentPrimary
                : (stageHover.hovered ? Qt.rgba(stageRoot.theme.accentPrimary.r, stageRoot.theme.accentPrimary.g, stageRoot.theme.accentPrimary.b, 0.4) : stageRoot.theme.bgBorder)
            border.width: canvasBox.isDropTarget ? 2 : 1
            clip: true

            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on border.width { NumberAnimation { duration: 140 } }
            HoverHandler { id: stageHover }

            readonly property real scaleFactor: width / 1920.0

            // Drop target glowing guide overlay
            Rectangle {
                visible: canvasBox.isDropTarget
                anchors.fill: parent
                radius: parent.radius
                color: Qt.rgba(stageRoot.theme.accentPrimary.r, stageRoot.theme.accentPrimary.g, stageRoot.theme.accentPrimary.b, 0.1)
                border.color: stageRoot.theme.accentPrimary
                border.width: 2
                z: 40

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: stageRoot.theme.accentPrimary
                        Text {
                            anchors.centerIn: parent
                            text: "󰐕"
                            font.family: stageRoot.font
                            font.pixelSize: 16
                            color: stageRoot.theme.bgBase
                        }
                    }

                    Text {
                        text: "Drop to place module on Lock Screen"
                        font.family: stageRoot.font
                        font.pixelSize: 13
                        font.bold: true
                        color: stageRoot.theme.textPrimary
                    }
                }
            }

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
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: stageRoot.blurPasses > 0
                    blurMax: 64
                    blur: Math.min(1.0, (stageRoot.blurSize / 10.0) * Math.min(1.0, stageRoot.blurPasses / 2.0))
                    contrast: stageRoot.contrast - 1.0
                    brightness: stageRoot.brightness - 1.0
                    saturation: stageRoot.vibrancy
                }
            }

            // Dark vignette backdrop overlay (from theme.bgOverlay)
            Rectangle {
                anchors.fill: parent
                color: stageRoot.theme.bgOverlay
            }

            // Screen Border simulation (matches user desktop ScreenBorder when active)
            Rectangle {
                visible: Boolean(BarConfig.screenBorder)
                anchors.fill: parent
                color: "transparent"
                radius: Math.round(16 * canvasBox.scaleFactor)
                border.width: Math.max(2, Math.round(Number(BarConfig.screenBorderThickness || 6) * canvasBox.scaleFactor))
                border.color: stageRoot.theme.accentPrimary
                z: 1
            }

            // 2. Faint Center Crosshair Guidelines (Hidden in Preview Mode unless dragging)
            Rectangle {
                visible: !stageRoot.previewMode
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: Qt.rgba(stageRoot.theme.textPrimary.r, stageRoot.theme.textPrimary.g, stageRoot.theme.textPrimary.b, 0.12)
            }

            Rectangle {
                visible: !stageRoot.previewMode
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.rgba(stageRoot.theme.textPrimary.r, stageRoot.theme.textPrimary.g, stageRoot.theme.textPrimary.b, 0.12)
            }

            // 3. Central Anchor Marker
            Rectangle {
                visible: !stageRoot.previewMode
                anchors.centerIn: parent
                width: 5
                height: 5
                radius: 2.5
                color: Qt.rgba(stageRoot.theme.textPrimary.r, stageRoot.theme.textPrimary.g, stageRoot.theme.textPrimary.b, 0.2)
            }

            // 4. Interactive Draggable Authentication Box (Avatar, Username, & Password Field)
            Item {
                id: simAuthBox
                visible: !stageRoot.hasAuthModule
                readonly property real sFactor: canvasBox.scaleFactor
                readonly property bool isInputSelected: stageRoot.selectedIndex === -2
                readonly property color resolvedOuter: stageRoot.resolveColor(stageRoot.inputOuterColor)
                readonly property color resolvedInner: stageRoot.resolveColor(stageRoot.inputInnerColor)
                readonly property color resolvedFont: stageRoot.resolveColor(stageRoot.inputFontColor)

                readonly property real avatarSize: Math.round(104 * sFactor)
                readonly property real simInputW: Math.max(100, Math.round(stageRoot.inputWidth * sFactor))
                readonly property real simInputH: Math.max(22, Math.round(stageRoot.inputHeight * sFactor))

                width: Math.max(simInputW, avatarSize)
                height: authCol.implicitHeight
                z: isInputSelected || inputDragArea.drag.active ? 15 : 3

                readonly property real targetX: {
                    const curX = Number(stageRoot.liveInputX) || 0;
                    if (stageRoot.inputHalign === "left") {
                        return curX * sFactor;
                    } else if (stageRoot.inputHalign === "right") {
                        return canvasBox.width - width + (curX * sFactor);
                    } else {
                        return (canvasBox.width - width) / 2 + (curX * sFactor);
                    }
                }

                readonly property real targetY: {
                    const curY = Number(stageRoot.liveInputY) || 0;
                    if (stageRoot.inputValign === "top") {
                        return -(curY * sFactor);
                    } else if (stageRoot.inputValign === "bottom") {
                        return canvasBox.height - height - (curY * sFactor);
                    } else {
                        return (canvasBox.height - height) / 2 - (curY * sFactor);
                    }
                }

                Binding on x {
                    when: !inputDragArea.drag.active
                    value: Math.max(2, Math.min(canvasBox.width - simAuthBox.width - 2, Math.round(simAuthBox.targetX)))
                }

                Binding on y {
                    when: !inputDragArea.drag.active
                    value: Math.max(2, Math.min(canvasBox.height - simAuthBox.height - 2, Math.round(simAuthBox.targetY)))
                }

                HoverHandler { id: inputBoxHover }

                ColumnLayout {
                    id: authCol
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Math.max(4, Math.round(14 * simAuthBox.sFactor))

                    // Avatar Circle
                    Item {
                        visible: stageRoot.showUser
                        Layout.alignment: Qt.AlignHCenter
                        width: simAuthBox.avatarSize
                        height: simAuthBox.avatarSize

                        Rectangle {
                            id: avatarCircleBg
                            anchors.fill: parent
                            radius: width / 2
                            color: simAuthBox.resolvedInner
                            border.width: Math.max(1.5, Math.round(3 * simAuthBox.sFactor))
                            border.color: (simAuthBox.isInputSelected || inputDragArea.drag.active)
                                ? stageRoot.theme.accentPrimary
                                : simAuthBox.resolvedOuter

                            Image {
                                id: stageFaceImg
                                anchors.fill: parent
                                anchors.margins: 2
                                source: "file://" + Quickshell.env("HOME") + "/.face"
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: stageFaceImg.status !== Image.Ready
                                text: "󰀉"
                                font.family: stageRoot.font
                                font.pixelSize: Math.round(44 * simAuthBox.sFactor)
                                color: simAuthBox.resolvedOuter
                            }
                        }
                    }

                    // Username Text
                    Text {
                        visible: stageRoot.showUser
                        Layout.alignment: Qt.AlignHCenter
                        text: stageRoot.username
                        font.family: stageRoot.font
                        font.pixelSize: Math.max(9, Math.round(18 * simAuthBox.sFactor))
                        font.bold: true
                        color: stageRoot.resolveColor("$text")
                        style: Text.Outline
                        styleColor: stageRoot.theme.bgOverlay
                    }

                    // Password Box
                    Rectangle {
                        id: inputPill
                        Layout.alignment: Qt.AlignHCenter
                        width: simAuthBox.simInputW
                        height: simAuthBox.simInputH
                        radius: Math.round(14 * simAuthBox.sFactor)
                        color: Qt.rgba(simAuthBox.resolvedInner.r, simAuthBox.resolvedInner.g, simAuthBox.resolvedInner.b, 0.82)
                        border.color: (simAuthBox.isInputSelected || inputDragArea.drag.active)
                            ? stageRoot.theme.accentPrimary
                            : simAuthBox.resolvedOuter
                        border.width: Math.max(1.5, Math.round(stageRoot.inputOutlineThickness * simAuthBox.sFactor * 1.4))

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(12 * simAuthBox.sFactor)
                            anchors.rightMargin: Math.round(12 * simAuthBox.sFactor)
                            spacing: Math.round(8 * simAuthBox.sFactor)

                            Text {
                                text: "󰌾"
                                font.family: stageRoot.font
                                font.pixelSize: Math.max(9, Math.round(16 * simAuthBox.sFactor))
                                color: simAuthBox.resolvedOuter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: stageRoot.inputPlaceholder || "Password"
                                font.family: stageRoot.font
                                font.pixelSize: Math.max(8, Math.round(12 * simAuthBox.sFactor))
                                color: Qt.rgba(simAuthBox.resolvedFont.r, simAuthBox.resolvedFont.g, simAuthBox.resolvedFont.b, 0.5)
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // Floating Coordinates & Color Badge for Password Input
                Rectangle {
                    visible: !stageRoot.previewMode && (simAuthBox.isInputSelected || inputDragArea.drag.active || inputBoxHover.hovered)
                    anchors.bottom: parent.top
                    anchors.bottomMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: inputBadgeRow.implicitWidth + 14
                    height: 18
                    radius: 4
                    color: stageRoot.theme.bgBase
                    border.color: stageRoot.theme.accentPrimary
                    border.width: 1
                    z: 20

                    RowLayout {
                        id: inputBadgeRow
                        anchors.centerIn: parent
                        spacing: 4
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: simAuthBox.resolvedOuter
                        }
                        Text {
                            id: inputBadgeTxt
                            text: "Auth Box (" + stageRoot.liveInputX + ", " + stageRoot.liveInputY + ") • " + stageRoot.inputOuterColor
                            font.family: stageRoot.font
                            font.pixelSize: 9
                            font.bold: true
                            color: stageRoot.theme.accentPrimary
                        }
                    }
                }

                MouseArea {
                    id: inputDragArea
                    anchors.fill: parent
                    preventStealing: true
                    drag.target: simAuthBox
                    drag.axis: Drag.XAndYAxis
                    drag.minimumX: 0
                    drag.maximumX: Math.max(0, canvasBox.width - simAuthBox.width)
                    drag.minimumY: 0
                    drag.maximumY: Math.max(0, canvasBox.height - simAuthBox.height)
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    onPressed: {
                        stageRoot.selectedIndex = -2;
                        dragGuides.targetCenterX = simAuthBox.x + simAuthBox.width / 2;
                        dragGuides.targetCenterY = simAuthBox.y + simAuthBox.height / 2;
                    }

                    onPositionChanged: {
                        if (drag.active) {
                            let curCenterX = simAuthBox.x + simAuthBox.width / 2;
                            let curCenterY = simAuthBox.y + simAuthBox.height / 2;
                            dragGuides.targetCenterX = curCenterX;
                            dragGuides.targetCenterY = curCenterY;
                            stageRoot.applyMagneticSnap(simAuthBox.x, simAuthBox.y, simAuthBox.width, simAuthBox.height, -2);
                        }
                    }

                    onReleased: {
                        dragGuides.snapVerticalActive = false;
                        dragGuides.snapHorizontalActive = false;

                        let snapped = stageRoot.applyMagneticSnap(simAuthBox.x, simAuthBox.y, simAuthBox.width, simAuthBox.height, -2);
                        simAuthBox.x = snapped.x;
                        simAuthBox.y = snapped.y;

                        let sFactor = canvasBox.scaleFactor;
                        let curCenterX = simAuthBox.x + simAuthBox.width / 2;
                        let curCenterY = simAuthBox.y + simAuthBox.height / 2;

                        let newHalign = "center";
                        if (curCenterX > canvasBox.width * 0.35 && curCenterX < canvasBox.width * 0.65) {
                            newHalign = "center";
                        } else if (curCenterX <= canvasBox.width * 0.35) {
                            newHalign = "left";
                        } else {
                            newHalign = "right";
                        }

                        let newValign = "center";
                        if (curCenterY < canvasBox.height * 0.35) {
                            newValign = "top";
                        } else if (curCenterY > canvasBox.height * 0.65) {
                            newValign = "bottom";
                        } else {
                            newValign = "center";
                        }

                        let rawX = 0;
                        if (newHalign === "center") {
                            rawX = (curCenterX - (canvasBox.width / 2)) / sFactor;
                        } else if (newHalign === "right") {
                            rawX = ((simAuthBox.x + simAuthBox.width) - canvasBox.width) / sFactor;
                        } else {
                            rawX = simAuthBox.x / sFactor;
                        }

                        let rawY = 0;
                        if (newValign === "center") {
                            rawY = ((canvasBox.height / 2) - curCenterY) / sFactor;
                        } else if (newValign === "bottom") {
                            rawY = (canvasBox.height - (simAuthBox.y + simAuthBox.height)) / sFactor;
                        } else {
                            rawY = -(simAuthBox.y) / sFactor;
                        }

                        let finalX = Math.round(rawX);
                        let finalY = Math.round(rawY);

                        stageRoot.liveInputX = finalX;
                        stageRoot.liveInputY = finalY;
                        stageRoot.inputHalign = newHalign;
                        stageRoot.inputValign = newValign;
                        stageRoot.hasUnsavedMoves = false;
                        stageRoot.inputMoved(finalX, finalY, newHalign, newValign);
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
                    color: stageRoot.theme.accentPrimary
                    opacity: 0.35
                }

                // Element Center Horizontal Guide
                Rectangle {
                    visible: !stageRoot.previewMode
                    y: dragGuides.targetCenterY
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: stageRoot.theme.accentPrimary
                    opacity: 0.35
                }

                // Highlighted Magnetic Snap Line (Vertical)
                Rectangle {
                    visible: dragGuides.snapVerticalActive
                    x: dragGuides.snapLineX
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1.5
                    color: stageRoot.theme.accentGreen
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
                    color: stageRoot.theme.accentGreen
                    opacity: 0.85
                    z: 25
                }
            }

            // 6. Interactive Draggable Modules
            Repeater {
                id: blocksRepeater
                model: stageRoot.liveBlocks

                Item {
                    id: blockDelegate
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
                        font: stageRoot.font
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
            }

            // Floating Active Coordinates Badge & Quick Delete (direct child of canvasBox to prevent click interception)
            Rectangle {
                id: activeBadge
                visible: !stageRoot.previewMode && stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < stageRoot.liveBlocks.length
                z: 300
                property var activeDelegate: (stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < blocksRepeater.count)
                    ? blocksRepeater.itemAt(stageRoot.selectedIndex)
                    : null
                property var activeBlockData: (stageRoot.selectedIndex >= 0 && stageRoot.selectedIndex < stageRoot.liveBlocks.length)
                    ? stageRoot.liveBlocks[stageRoot.selectedIndex]
                    : null

                x: activeDelegate ? Math.max(4, Math.min(canvasBox.width - width - 4, activeDelegate.x + (activeDelegate.width - width) / 2)) : 0
                y: activeDelegate ? (activeDelegate.y >= height + 6 ? activeDelegate.y - height - 4 : activeDelegate.y + activeDelegate.height + 4) : 0
                implicitWidth: activeBadgeRow.implicitWidth + 16
                height: 22
                radius: 6
                color: stageRoot.theme.bgBase
                border.color: stageRoot.theme.accentPrimary
                border.width: 1

                RowLayout {
                    id: activeBadgeRow
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: stageRoot.resolveColor(activeBadge.activeBlockData ? activeBadge.activeBlockData.color : "$accent")
                    }

                    Text {
                        text: (activeBadge.activeBlockData ? (activeBadge.activeBlockData.name || activeBadge.activeBlockData.type) : "Module") + " (" + (activeBadge.activeBlockData ? activeBadge.activeBlockData.position_x : 0) + ", " + (activeBadge.activeBlockData ? activeBadge.activeBlockData.position_y : 0) + ") • " + (activeBadge.activeBlockData ? activeBadge.activeBlockData.halign : "center") + "/" + (activeBadge.activeBlockData ? activeBadge.activeBlockData.valign : "center")
                        font.family: stageRoot.font
                        font.pixelSize: 9
                        font.bold: true
                        color: stageRoot.theme.accentPrimary
                    }

                    // Dedicated Quick Delete / Remove Button
                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: activeDelHover.hovered ? stageRoot.theme.accentRed : Qt.rgba(stageRoot.theme.accentRed.r, stageRoot.theme.accentRed.g, stageRoot.theme.accentRed.b, 0.25)
                        border.color: stageRoot.theme.accentRed
                        border.width: 1

                        HoverHandler { id: activeDelHover }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.family: stageRoot.font
                            font.pixelSize: 9
                            font.bold: true
                            color: activeDelHover.hovered ? stageRoot.theme.bgBase : stageRoot.theme.accentRed
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            onPressed: (mouse) => mouse.accepted = true
                            onClicked: (mouse) => {
                                mouse.accepted = true;
                                stageRoot.removeModule(stageRoot.selectedIndex);
                            }
                        }
                    }
                }
            }
        }
    }
}

