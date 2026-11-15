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
import "../../utils/ColorUtils.js" as ColorUtils
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../wallpaper"
import "../../bar"
import "../../Lockscreen"
import "Lockscreen"
import "../../Lockscreen/Modules"
import "LockscreenEditor"

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

    // Stage Animation Preview State
    property string activePreviewStyle: LockscreenConfig.animation_style || "default"
    property real animBgZoom: 1.0
    property real animBlurMult: 1.0
    property real animModsOpacity: 1.0
    property real animModsScale: 1.0
    property real animAuthOffsetY: 0.0
    property real animAuthScale: 1.0
    property real animStaggerProgress: 0.0
    property real animCurtainProgress: 0.0
    property real animCurtainSplit: 0.0
    property real animCurtainSeamOpacity: 0.0
    property real animCurtainSeamWidth: 0.0
    property real animFlashOpacity: 0.0
    property real animPortalPull: 0.0
    property real animPortalRingRadius: 0.0
    property real animPortalRingOpacity: 0.0
    property real animRippleScale: 0.85
    property real animRippleOpacity: 0.0

    function resetStageAnimState() {
        stageDefaultAnim.stop();
        stageStaggeredAnim.stop();
        stageCurtainAnim.stop();
        stageDepthAnim.stop();
        stagePortalAnim.stop();
        animBgZoom = 1.0;
        animBlurMult = 1.0;
        animModsOpacity = 1.0;
        animModsScale = 1.0;
        animAuthOffsetY = 0.0;
        animAuthScale = 1.0;
        animStaggerProgress = 0.0;
        animCurtainProgress = 0.0;
        animCurtainSplit = 0.0;
        animCurtainSeamOpacity = 0.0;
        animCurtainSeamWidth = 0.0;
        animFlashOpacity = 0.0;
        animPortalPull = 0.0;
        animPortalRingRadius = 0.0;
        animPortalRingOpacity = 0.0;
        animRippleScale = 0.85;
        animRippleOpacity = 0.0;
    }

    function playAnimationPreview(styleOverride) {
        resetStageAnimState();
        const st = styleOverride || LockscreenConfig.animation_style || "default";
        activePreviewStyle = st;
        if (st === "staggered") stageStaggeredAnim.start();
        else if (st === "curtain") stageCurtainAnim.start();
        else if (st === "depth") stageDepthAnim.start();
        else if (st === "portal") stagePortalAnim.start();
        else stageDefaultAnim.start();
    }

    // 1. Default Stage Preview (Entrance + Ripple)
    ParallelAnimation {
        id: stageDefaultAnim
        NumberAnimation { target: stageRoot; property: "animBgZoom"; from: 1.08; to: 1.0; duration: 480; easing.type: Easing.OutCubic }
        NumberAnimation { target: stageRoot; property: "animModsOpacity"; from: 0.0; to: 1.0; duration: 360; easing.type: Easing.OutCubic }
        NumberAnimation { target: stageRoot; property: "animModsScale"; from: 0.94; to: 1.0; duration: 420; easing.type: Easing.OutBack }
        NumberAnimation { target: stageRoot; property: "animAuthScale"; from: 0.92; to: 1.0; duration: 420; easing.type: Easing.OutBack }
        NumberAnimation { target: stageRoot; property: "animRippleScale"; from: 0.85; to: 2.3; duration: 520; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: stageRoot; property: "animRippleOpacity"; from: 0.0; to: 0.85; duration: 100; easing.type: Easing.OutQuad }
            NumberAnimation { target: stageRoot; property: "animRippleOpacity"; from: 0.85; to: 0.0; duration: 420; easing.type: Easing.OutCubic }
        }
    }

    // 2. Staggered Cascade Stage Preview
    ParallelAnimation {
        id: stageStaggeredAnim
        NumberAnimation { target: stageRoot; property: "animBgZoom"; from: 1.08; to: 1.0; duration: 500; easing.type: Easing.OutCubic }
        NumberAnimation { target: stageRoot; property: "animBlurMult"; from: 0.0; to: 1.0; duration: 440; easing.type: Easing.OutCubic }
        NumberAnimation { target: stageRoot; property: "animStaggerProgress"; from: 1.0; to: 0.0; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.35 }
        NumberAnimation { target: stageRoot; property: "animModsOpacity"; from: 0.0; to: 1.0; duration: 340; easing.type: Easing.OutCubic }
        NumberAnimation { target: stageRoot; property: "animModsScale"; from: 0.86; to: 1.0; duration: 460; easing.type: Easing.OutBack }
        NumberAnimation { target: stageRoot; property: "animAuthOffsetY"; from: 45; to: 0; duration: 480; easing.type: Easing.OutBack; easing.overshoot: 1.35 }
        NumberAnimation { target: stageRoot; property: "animAuthScale"; from: 0.86; to: 1.0; duration: 440; easing.type: Easing.OutBack }
    }

    // 3. Cinema Curtain Stage Preview
    ParallelAnimation {
        id: stageCurtainAnim
        NumberAnimation { target: stageRoot; property: "animCurtainProgress"; from: 1.0; to: 0.0; duration: 520; easing.type: Easing.OutExpo }
        NumberAnimation { target: stageRoot; property: "animCurtainSplit"; from: 1.0; to: 0.0; duration: 480; easing.type: Easing.OutQuart }
        NumberAnimation { target: stageRoot; property: "animBgZoom"; from: 1.06; to: 1.0; duration: 500; easing.type: Easing.OutQuart }
        NumberAnimation { target: stageRoot; property: "animModsOpacity"; from: 0.0; to: 1.0; duration: 360; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: stageRoot; property: "animCurtainSeamWidth"; from: 0.2; to: 1.0; duration: 180; easing.type: Easing.OutQuad }
            NumberAnimation { target: stageRoot; property: "animCurtainSeamWidth"; to: 0.0; duration: 320; easing.type: Easing.InQuad }
        }
        NumberAnimation { target: stageRoot; property: "animCurtainSeamOpacity"; from: 0.95; to: 0.0; duration: 460; easing.type: Easing.OutCubic }
    }

    // 4. Zoom & Depth Stage Preview
    ParallelAnimation {
        id: stageDepthAnim
        NumberAnimation { target: stageRoot; property: "animBgZoom"; from: 1.28; to: 1.0; duration: 560; easing.type: Easing.OutExpo }
        NumberAnimation { target: stageRoot; property: "animBlurMult"; from: 0.0; to: 1.0; duration: 500; easing.type: Easing.OutCubic }
        NumberAnimation { target: stageRoot; property: "animModsScale"; from: 1.26; to: 1.0; duration: 500; easing.type: Easing.OutExpo }
        NumberAnimation { target: stageRoot; property: "animAuthScale"; from: 1.24; to: 1.0; duration: 500; easing.type: Easing.OutExpo }
        NumberAnimation { target: stageRoot; property: "animModsOpacity"; from: 0.0; to: 1.0; duration: 360; easing.type: Easing.OutCubic }
        NumberAnimation { target: stageRoot; property: "animFlashOpacity"; from: 0.32; to: 0.0; duration: 440; easing.type: Easing.OutCubic }
    }

    // 5. Portal Iris Stage Preview
    ParallelAnimation {
        id: stagePortalAnim
        NumberAnimation { target: stageRoot; property: "animBgZoom"; from: 1.10; to: 1.0; duration: 500; easing.type: Easing.OutQuart }
        NumberAnimation { target: stageRoot; property: "animBlurMult"; from: 0.0; to: 1.0; duration: 440; easing.type: Easing.OutCubic }
        NumberAnimation { target: stageRoot; property: "animPortalPull"; from: 0.45; to: 0.0; duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        NumberAnimation { target: stageRoot; property: "animModsScale"; from: 0.72; to: 1.0; duration: 480; easing.type: Easing.OutBack }
        NumberAnimation { target: stageRoot; property: "animAuthScale"; from: 0.65; to: 1.0; duration: 440; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
        NumberAnimation { target: stageRoot; property: "animModsOpacity"; from: 0.0; to: 1.0; duration: 340; easing.type: Easing.OutCubic }
        NumberAnimation { target: stageRoot; property: "animPortalRingRadius"; from: 20; to: Math.max(400, canvasBox.width * 0.85); duration: 560; easing.type: Easing.OutQuart }
        NumberAnimation { target: stageRoot; property: "animPortalRingOpacity"; from: 0.9; to: 0.0; duration: 540; easing.type: Easing.OutCubic }
    }

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

    function resolveColor(colStr) { return ColorUtils.resolveColorToken(stageRoot.theme, colStr, stageRoot.theme.textPrimary); }

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

        LockscreenSandboxHeader { stageRoot: stageRoot }
        LockscreenSandboxColorBar { stageRoot: stageRoot }

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
                scale: stageRoot.animBgZoom
                source: stageRoot.wallpaperPath !== "" ? (stageRoot.wallpaperPath.startsWith("/") ? ("file://" + stageRoot.wallpaperPath) : stageRoot.wallpaperPath) : ""
                sourceSize.width: 960
                sourceSize.height: 540
                cache: false
                asynchronous: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: stageRoot.blurPasses > 0
                    blurMax: 64
                    blur: Math.min(1.0, (stageRoot.blurSize / 10.0) * Math.min(1.0, stageRoot.blurPasses / 2.0)) * stageRoot.animBlurMult
                    contrast: stageRoot.contrast - 1.0
                    brightness: stageRoot.brightness - 1.0
                    saturation: stageRoot.vibrancy
                }
            }

            // Dark vignette backdrop overlay (from theme.bgOverlay)
            Rectangle {
                anchors.fill: parent
                color: stageRoot.theme.bgOverlay
                opacity: stageRoot.animBlurMult
            }

            // Depth / Lens Flash Overlay
            Rectangle {
                anchors.fill: parent
                color: stageRoot.theme.accentPrimary
                opacity: stageRoot.animFlashOpacity
                visible: opacity > 0
                z: 4
            }

            // Portal Shockwave Ring Overlay
            Rectangle {
                x: (simAuthBox.x + simAuthBox.width / 2) - width / 2
                y: (simAuthBox.y + simAuthBox.height / 2) - height / 2
                width: stageRoot.animPortalRingRadius * 2
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 2.5
                border.color: stageRoot.theme.accentPrimary
                opacity: stageRoot.animPortalRingOpacity
                visible: opacity > 0
                z: 5
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
            LockscreenStageAuthBox {
                id: simAuthBox
                stageRoot: stageRoot
                canvasBox: canvasBox
                dragGuides: dragGuides
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

                delegate: LockscreenStageBlockDelegate {
                    stageRoot: stageRoot
                    canvasBox: canvasBox
                    dragGuides: dragGuides
                    simAuthBox: simAuthBox
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

            // Cinema Curtain Split Preview Overlay
            Item {
                anchors.fill: parent
                visible: stageRoot.animCurtainProgress > 0.001 || stageRoot.animCurtainSeamOpacity > 0.001
                z: 400

                Rectangle {
                    width: parent.width
                    height: (parent.height / 2) * stageRoot.animCurtainProgress
                    anchors.top: parent.top
                    color: stageRoot.theme.bgBase
                    opacity: 0.94
                }

                Rectangle {
                    width: parent.width
                    height: (parent.height / 2) * stageRoot.animCurtainProgress
                    anchors.bottom: parent.bottom
                    color: stageRoot.theme.bgBase
                    opacity: 0.94
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * stageRoot.animCurtainSeamWidth
                    height: 2
                    radius: 1
                    color: stageRoot.theme.accentPrimary
                    opacity: stageRoot.animCurtainSeamOpacity
                }
            }
        }
    }
}

