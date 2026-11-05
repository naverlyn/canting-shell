/*
 * LockscreenSettings.qml
 *
 * Native Quickshell Lock Screen Editor & Stage Sandbox.
 * Provides interactive 16:9 canvas drag-and-drop preview, building blocks management,
 * and visual filters configuration, saved directly to lockscreen_config.json.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../wallpaper"
import "../../Lockscreen"
import "Common"
import "./LockscreenEditor"

Item {
    id: root
    property alias wallpaperModalRef: wallpaperModal
    property alias addModuleModalRef: addModuleModal
    property alias restoreProcRef: restoreProc
    property alias testLockProcRef: testLockProc
    property alias updatePositionsProcRef: updatePositionsProc
    property alias loadSettingsProcRef: loadSettingsProc
    property var theme: Style.theme
    property string font: Style.font
    readonly property string scriptPath: "/usr/bin/true"

    /* State bound directly to native LockscreenConfig */
    property var textBlocks: LockscreenConfig.text_blocks || []
    property int autoExpandBlockIndex: -1

    /* Drag-and-drop state for Available Building Blocks -> Stage */
    property bool isDraggingBlock: false
    property string draggedModType: ""
    property string draggedModName: ""
    property string draggedModIcon: ""
    property real dragMouseX: 0
    property real dragMouseY: 0
    property bool isOverStage: false
    property bool isOverPool: false

    property string backgroundSource: LockscreenConfig.background_source
    property string backgroundCustomPath: LockscreenConfig.background_custom_path
    property int blurPasses: LockscreenConfig.blur_passes
    property int blurSize: LockscreenConfig.blur_size
    property real contrast: LockscreenConfig.contrast
    property real brightness: LockscreenConfig.brightness
    property real vibrancy: LockscreenConfig.vibrancy
    property bool generalImmediateRender: LockscreenConfig.general_immediate_render
    property bool unlockAnimation: LockscreenConfig.unlock_animation

    property string clockFormat: LockscreenConfig.clock_format
    property int clockFontSize: LockscreenConfig.clock_font_size
    property bool showDate: LockscreenConfig.show_date
    property bool showUser: LockscreenConfig.show_user
    property bool showMedia: LockscreenConfig.show_media
    property bool showLayout: LockscreenConfig.show_layout
    property bool showUptime: LockscreenConfig.show_uptime
    property bool showWeather: LockscreenConfig.show_weather
    property bool showBattery: false

    property int inputWidth: LockscreenConfig.input_width
    property int inputHeight: LockscreenConfig.input_height
    property int inputOutlineThickness: LockscreenConfig.input_outline_thickness
    property real inputDotsSize: 0.2
    property real inputDotsSpacing: 0.2
    property bool inputDotsCenter: true
    property bool inputFadeOnEmpty: false
    property bool inputHideInput: false
    property string inputPlaceholder: LockscreenConfig.input_placeholder
    property int inputPosX: LockscreenConfig.input_pos_x
    property int inputPosY: LockscreenConfig.input_pos_y
    property string inputHalign: LockscreenConfig.input_halign
    property string inputValign: LockscreenConfig.input_valign
    property string inputOuterColor: LockscreenConfig.input_outer_color
    property string inputInnerColor: LockscreenConfig.input_inner_color
    property string inputFontColor: LockscreenConfig.input_font_color
    property string inputCheckColor: "$accent"
    property string inputFailColor: "$red"

    Connections {
        target: LockscreenConfig
        function onConfigChanged() {
            root.textBlocks = LockscreenConfig.text_blocks;
            root.inputPosX = LockscreenConfig.input_pos_x;
            root.inputPosY = LockscreenConfig.input_pos_y;
            root.inputWidth = LockscreenConfig.input_width;
            root.inputHeight = LockscreenConfig.input_height;
            root.inputPlaceholder = LockscreenConfig.input_placeholder;
            root.blurPasses = LockscreenConfig.blur_passes;
            root.blurSize = LockscreenConfig.blur_size;
            root.contrast = LockscreenConfig.contrast;
            root.brightness = LockscreenConfig.brightness;
            root.vibrancy = LockscreenConfig.vibrancy;
            root.generalImmediateRender = LockscreenConfig.general_immediate_render;
            root.unlockAnimation = LockscreenConfig.unlock_animation;
            root.clockFormat = LockscreenConfig.clock_format;
            root.clockFontSize = LockscreenConfig.clock_font_size;
            root.backgroundSource = LockscreenConfig.background_source;
            root.backgroundCustomPath = LockscreenConfig.background_custom_path;
            root.showUser = LockscreenConfig.show_user;
            root.showMedia = LockscreenConfig.show_media;
            root.showDate = LockscreenConfig.show_date;
            root.showLayout = LockscreenConfig.show_layout;
            root.showUptime = LockscreenConfig.show_uptime;
            root.showWeather = LockscreenConfig.show_weather;
            root.inputOutlineThickness = LockscreenConfig.input_outline_thickness;
            root.inputHalign = LockscreenConfig.input_halign;
            root.inputValign = LockscreenConfig.input_valign;
            root.inputOuterColor = LockscreenConfig.input_outer_color;
            root.inputInnerColor = LockscreenConfig.input_inner_color;
            root.inputFontColor = LockscreenConfig.input_font_color;
        }
    }

    function scheduleSave() {
        LockscreenConfig.background_source = root.backgroundSource;
        LockscreenConfig.background_custom_path = root.backgroundCustomPath;
        LockscreenConfig.blur_passes = root.blurPasses;
        LockscreenConfig.blur_size = root.blurSize;
        LockscreenConfig.contrast = root.contrast;
        LockscreenConfig.brightness = root.brightness;
        LockscreenConfig.vibrancy = root.vibrancy;
        LockscreenConfig.general_immediate_render = root.generalImmediateRender;
        LockscreenConfig.unlock_animation = root.unlockAnimation;
        LockscreenConfig.clock_format = root.clockFormat;
        LockscreenConfig.clock_font_size = root.clockFontSize;
        LockscreenConfig.show_date = root.showDate;
        LockscreenConfig.show_user = root.showUser;
        LockscreenConfig.show_media = root.showMedia;
        LockscreenConfig.show_layout = root.showLayout;
        LockscreenConfig.show_uptime = root.showUptime;
        LockscreenConfig.show_weather = root.showWeather;
        LockscreenConfig.input_width = root.inputWidth;
        LockscreenConfig.input_height = root.inputHeight;
        LockscreenConfig.input_outline_thickness = root.inputOutlineThickness;
        LockscreenConfig.input_placeholder = root.inputPlaceholder;
        LockscreenConfig.input_pos_x = root.inputPosX;
        LockscreenConfig.input_pos_y = root.inputPosY;
        LockscreenConfig.input_halign = root.inputHalign;
        LockscreenConfig.input_valign = root.inputValign;
        LockscreenConfig.input_outer_color = root.inputOuterColor;
        LockscreenConfig.input_inner_color = root.inputInnerColor;
        LockscreenConfig.input_font_color = root.inputFontColor;
        LockscreenConfig.saveConfig();
    }

    function addModule(mType) {
        const sBox = lockScreenInst.stageSandboxRef;
        const newIdx = LockscreenConfig.addModule(mType);
        root.autoExpandBlockIndex = LockscreenConfig.modules.length - 1;
        if (sBox && sBox.selectBlock) sBox.selectBlock(newIdx);
        showStatus("Added " + mType + " module");
    }

    function updateModule(idx, payload) {
        LockscreenConfig.updateModule(idx, payload);
        showStatus("Module saved");
    }

    function deleteModule(idx) {
        LockscreenConfig.deleteModule(idx);
        showStatus("Deleted module");
    }

    function updatePositions(payload) {
        LockscreenConfig.updatePositions(payload);
        showStatus("Positions saved to Quickshell lock screen");
    }

    function startModuleDrag(mType, mName, mIcon, mouseX, mouseY) {
        root.isDraggingBlock = true;
        root.draggedModType = mType;
        root.draggedModName = mName;
        root.draggedModIcon = mIcon;
        root.updateModuleDrag(mouseX, mouseY);
    }

    function updateModuleDrag(mouseX, mouseY) {
        root.dragMouseX = mouseX;
        root.dragMouseY = mouseY;
        if (!root.isDraggingBlock) return;

        const sBox = lockScreenInst.stageSandboxRef;
        if (sBox && sBox.canvasBoxRef) {
            const cBox = sBox.canvasBoxRef;
            const pt = cBox.mapFromItem(root, mouseX, mouseY);
            root.isOverStage = (pt.x >= 0 && pt.x <= cBox.width && pt.y >= 0 && pt.y <= cBox.height);
            cBox.isDropTarget = root.isOverStage;
        } else {
            root.isOverStage = false;
        }

        const mPool = lockScreenInst.modulesPoolRef;
        if (mPool) {
            const pt = mPool.mapFromItem(root, mouseX, mouseY);
            root.isOverPool = (pt.x >= 0 && pt.x <= mPool.width && pt.y >= 0 && pt.y <= mPool.height);
        } else {
            root.isOverPool = false;
        }
    }

    function finishModuleDrag() {
        if (!root.isDraggingBlock) return;
        const mType = root.draggedModType;
        const mName = root.draggedModName;
        const wasOverStage = root.isOverStage;

        root.isDraggingBlock = false;
        root.draggedModType = "";
        root.draggedModName = "";
        root.draggedModIcon = "";
        root.isOverStage = false;
        root.isOverPool = false;

        const sBox = lockScreenInst.stageSandboxRef;
        if (sBox && sBox.canvasBoxRef) {
            sBox.canvasBoxRef.isDropTarget = false;
        }

        if (wasOverStage && mType && sBox) {
            const coords = sBox.getCanvasDropCoords(root, root.dragMouseX, root.dragMouseY);
            if (coords) {
                const newIdx = LockscreenConfig.addModule(mType, coords);
                if (sBox.selectBlock) sBox.selectBlock(newIdx);
                showStatus("Placed " + mName + " on Lock Screen");
            } else {
                const newIdx = LockscreenConfig.addModule(mType);
                if (sBox.selectBlock) sBox.selectBlock(newIdx);
                showStatus("Added " + mName + " to Lock Screen");
            }
        }
    }

    function selectStageBlock(idx) {
        const sBox = lockScreenInst.stageSandboxRef;
        if (sBox && sBox.selectBlock) sBox.selectBlock(idx);
    }

    function addCustomBlock() {
        LockscreenConfig.addBlock({
            name: "Custom Block",
            raw_text: "echo 'Custom Block'",
            cmd_body: "echo 'Custom Block'",
            is_cmd: true,
            cmd_interval: 5000,
            position_x: 0,
            position_y: 50,
            halign: "center",
            valign: "center",
            font_size: 14,
            color: "$accent"
        });
        root.autoExpandBlockIndex = LockscreenConfig.text_blocks.length - 1;
        showStatus("Added new building block");
    }

    function updateBlock(idx, payload) {
        LockscreenConfig.updateBlock(idx, payload);
        showStatus("Block saved");
    }

    function deleteBlock(idx) {
        LockscreenConfig.deleteBlock(idx);
        showStatus("Deleted building block");
    }

    function generateCustomWallpaper(path) {
        root.backgroundCustomPath = path;
        root.backgroundSource = "custom";
        scheduleSave();
    }

    /* Process runners for actions */
    Process {
        id: testLockProc
        command: ["qs", "ipc", "call", "lockscreen", "lock"]
        running: false
        onExited: showStatus("Launching Quickshell lock screen...")
    }

    Process {
        id: restoreProc
        command: ["/usr/bin/true"]
        running: false
        onExited: {
            LockscreenConfig.resetDefaults();
            showStatus("Restored default lock screen settings");
        }
    }

    Process {
        id: updatePositionsProc
        command: ["/usr/bin/true"]
        running: false
        onCommandChanged: {
            if (command && command.length >= 3 && (command[1] === "update-positions" || command[1] === "update_positions")) {
                try {
                    const payload = JSON.parse(command[2]);
                    LockscreenConfig.updatePositions(payload);
                    showStatus("Positions saved to Quickshell lock screen");
                } catch(e) {
                    console.error("Failed to parse update-positions payload:", e);
                }
            }
        }
    }

    Process {
        id: loadSettingsProc
        command: ["/usr/bin/true"]
        running: false
        onExited: {
            root.textBlocks = LockscreenConfig.text_blocks;
            showStatus("Reset stage sandbox to saved positions");
        }
    }

    /* Main Scrollable View */
    Flickable {
        id: lockFlickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: lockScreenInst.implicitHeight + 120
        flickableDirection: Flickable.VerticalFlick
        clip: true
        interactive: !root.isDraggingBlock
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: vertScroll
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder
            }
        }

        LockscreenEditorView {
            id: lockScreenInst
            root: root
            width: lockFlickable.width - (vertScroll.visible ? 12 : 0)
        }
    }

    // Floating drag ghost for dragging modules into the live preview stage
    ModuleDragGhost {
        hostRoot: root
    }

    // Dedicated Modal Wallpaper Chooser Window
    LockscreenWallpaperModal {
        id: wallpaperModal
        theme: root.theme
        font: root.font
        currentSelected: root.backgroundCustomPath
        onWallpaperSelected: (path) => {
            root.backgroundCustomPath = path;
            root.backgroundSource = "custom";
            root.scheduleSave();
        }
    }

    // Modal Module Chooser Window
    AddModuleModal {
        id: addModuleModal
        theme: root.theme
        font: root.font
        onModuleChosen: (mType) => root.addModule(mType)
    }

    /* Feedback toast notification */
    Rectangle {
        id: statusToast
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 24
        height: 36
        implicitWidth: toastLabel.implicitWidth + 32
        radius: 8
        color: root.theme.bgBase
        border.color: root.theme.accentPrimary
        border.width: 1
        opacity: toastTimer.running ? 1.0 : 0.0
        visible: opacity > 0
        z: 999

        Behavior on opacity { NumberAnimation { duration: 160 } }

        Text {
            id: toastLabel
            anchors.centerIn: parent
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
            color: root.theme.textPrimary
        }

        Timer {
            id: toastTimer
            interval: 2200
            repeat: false
        }
    }

    function showStatus(msg) {
        toastLabel.text = msg;
        toastTimer.restart();
    }
}
