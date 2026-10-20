/*
 * HyprlockSettings.qml
 *
 * Configuration and customization for Hyprlock Wayland screen locker.
 * Follows Libadwaita / Quickshell preferences design language with strict vertical grid alignment.
 * Includes an integrated wallpaper menu to generate .wallpaper_current for custom backgrounds.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../wallpaper"
import ".."
import "./Common"
import "./Hyprlock"

Item {
    id: root
    property alias wallpaperModalRef: wallpaperModal
    property alias restoreProcRef: restoreProc
    property alias testLockProcRef: testLockProc
    property alias updatePositionsProcRef: updatePositionsProc
    property alias loadSettingsProcRef: loadSettingsProc
    property var theme
    property string font: "Hack Nerd Font"

    /* Internal state synced with hyprlock.conf */
    property bool isLoading: true
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/manage_hyprlock.sh").toString().replace(/^file:\/\//, "")

    property int generalFractionalScaling: 2
    property bool generalImmediateRender: true

    property string backgroundSource: "wallpaper_current" // "wallpaper_current", "wallpaper_modified", "screenshot", "custom"
    property string backgroundCustomPath: ""
    property int blurPasses: 2
    property int blurSize: 3
    property real contrast: 1.3
    property real brightness: 0.8
    property real vibrancy: 0.21

    property string clockFormat: "12h" // "12h" or "24h"
    property int clockFontSize: 110
    property bool showDate: true

    property bool showUser: true
    property bool showLayout: true
    property bool showUptime: true
    property bool showBattery: true
    property bool showWeather: true

    property int inputWidth: 260
    property int inputHeight: 56
    property int inputOutlineThickness: 2
    property real inputDotsSize: 0.2
    property real inputDotsSpacing: 0.2
    property bool inputDotsCenter: true
    property bool inputFadeOnEmpty: false
    property bool inputHideInput: false
    property string inputPlaceholder: "Type Password"
    property int inputPosX: 0
    property int inputPosY: -85
    property string inputHalign: "center"
    property string inputValign: "center"

    /* Modular Text & Command Building Blocks */
    property var textBlocks: []

    /* Status toast notification */
    property string statusMessage: ""
    property bool statusVisible: false

    Timer {
        id: statusTimer
        interval: 2200
        repeat: false
        onTriggered: root.statusVisible = false
    }

    function showStatus(msg) {
        root.statusMessage = msg;
        root.statusVisible = true;
        statusTimer.restart();
    }

    /* Save debounce timer */
    Timer {
        id: saveDebounceTimer
        interval: 300
        repeat: false
        onTriggered: root.saveSettings()
    }

    function scheduleSave() {
        if (root.isLoading) return;
        saveDebounceTimer.restart();
    }

    /* Query configuration from manage_hyprlock.sh */
    Process {
        id: loadSettingsProc
        command: [root.scriptPath, "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data) {
                        root.isLoading = true;
                        if (data.general_fractional_scaling !== undefined) root.generalFractionalScaling = data.general_fractional_scaling;
                        if (data.general_immediate_render !== undefined) root.generalImmediateRender = data.general_immediate_render;
                        if (data.background_source !== undefined) root.backgroundSource = data.background_source;
                        if (data.background_custom_path !== undefined) root.backgroundCustomPath = data.background_custom_path;
                        if (data.blur_passes !== undefined) root.blurPasses = data.blur_passes;
                        if (data.blur_size !== undefined) root.blurSize = data.blur_size;
                        if (data.contrast !== undefined) root.contrast = data.contrast;
                        if (data.brightness !== undefined) root.brightness = data.brightness;
                        if (data.vibrancy !== undefined) root.vibrancy = data.vibrancy;
                        if (data.clock_format !== undefined) root.clockFormat = data.clock_format;
                        if (data.clock_font_size !== undefined) root.clockFontSize = data.clock_font_size;
                        if (data.show_date !== undefined) root.showDate = data.show_date;
                        if (data.show_user !== undefined) root.showUser = data.show_user;
                        if (data.show_layout !== undefined) root.showLayout = data.show_layout;
                        if (data.show_uptime !== undefined) root.showUptime = data.show_uptime;
                        if (data.show_battery !== undefined) root.showBattery = data.show_battery;
                        if (data.show_weather !== undefined) root.showWeather = data.show_weather;
                        if (data.input_width !== undefined) root.inputWidth = data.input_width;
                        if (data.input_height !== undefined) root.inputHeight = data.input_height;
                        if (data.input_outline_thickness !== undefined) root.inputOutlineThickness = data.input_outline_thickness;
                        if (data.input_dots_size !== undefined) root.inputDotsSize = data.input_dots_size;
                        if (data.input_dots_spacing !== undefined) root.inputDotsSpacing = data.input_dots_spacing;
                        if (data.input_dots_center !== undefined) root.inputDotsCenter = data.input_dots_center;
                        if (data.input_fade_on_empty !== undefined) root.inputFadeOnEmpty = data.input_fade_on_empty;
                        if (data.input_hide_input !== undefined) root.inputHideInput = data.input_hide_input;
                        if (data.input_placeholder !== undefined) root.inputPlaceholder = data.input_placeholder;
                        if (data.input_pos_x !== undefined) root.inputPosX = data.input_pos_x;
                        if (data.input_pos_y !== undefined) root.inputPosY = data.input_pos_y;
                        if (data.input_halign !== undefined) root.inputHalign = data.input_halign;
                        if (data.input_valign !== undefined) root.inputValign = data.input_valign;
                        if (data.text_blocks !== undefined) root.textBlocks = data.text_blocks;
                        root.isLoading = false;
                    }
                } catch (e) {
                    root.isLoading = false;
                }
            }
        }
    }

    /* Save process */
    Process {
        id: saveSettingsProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res = JSON.parse(text);
                    if (res && res.status === "ok") {
                        showStatus("Settings saved");
                        if (res.data && res.data.text_blocks) {
                            root.textBlocks = res.data.text_blocks;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    /* Process to update a building block */
    Process {
        id: updateBlockProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res = JSON.parse(text);
                    if (res && res.status === "ok" && res.blocks) {
                        root.textBlocks = res.blocks;
                        showStatus("Block updated");
                    }
                } catch(e) {}
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0) {
                    console.warn("updateBlock error:", text);
                }
            }
        }
    }

    function updateBlock(index, payload) {
        updateBlockProc.running = false;
        updateBlockProc.command = [root.scriptPath, "update-block", String(index), JSON.stringify(payload)];
        updateBlockProc.running = true;
    }

    /* Process to batch update building block positions */
    Process {
        id: updatePositionsProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res = JSON.parse(text);
                    if (res && res.status === "ok") {
                        if (res.blocks) {
                            root.textBlocks = res.blocks;
                        }
                        showStatus("Applied lock screen layout positions");
                    } else if (res && res.message) {
                        showStatus(res.message);
                    } else {
                        showStatus("Applied lock screen layout positions");
                    }
                } catch(e) {
                    showStatus("Applied lock screen layout positions");
                }
            }
        }
    }

    /* Process to add a new custom building block */
    Process {
        id: addBlockProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res = JSON.parse(text);
                    if (res && res.status === "ok" && res.blocks) {
                        root.textBlocks = res.blocks;
                        showStatus("Custom block added");
                    }
                } catch(e) {}
            }
        }
    }

    function addCustomBlock() {
        let newPayload = {
            name: "Custom Command",
            raw_text: "cmd[update:1000] echo \"Hello $USER\"",
            font_size: 14,
            font_family: "Victor Mono Bold Oblique",
            position_x: 0,
            position_y: 60,
            halign: "center",
            valign: "bottom",
            color: "$color8"
        };
        addBlockProc.command = [root.scriptPath, "add-block", JSON.stringify(newPayload)];
        addBlockProc.running = true;
    }

    /* Process to delete a custom building block */
    Process {
        id: deleteBlockProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res = JSON.parse(text);
                    if (res && res.status === "ok" && res.blocks) {
                        root.textBlocks = res.blocks;
                        showStatus("Block deleted");
                    }
                } catch(e) {}
            }
        }
    }

    function deleteBlock(index) {
        deleteBlockProc.command = [root.scriptPath, "delete-block", String(index)];
        deleteBlockProc.running = true;
    }

    function saveSettings() {
        if (root.isLoading) return;
        let payload = {
            "general_fractional_scaling": root.generalFractionalScaling,
            "general_immediate_render": root.generalImmediateRender,
            "background_source": root.backgroundSource,
            "background_custom_path": root.backgroundCustomPath,
            "blur_passes": root.blurPasses,
            "blur_size": root.blurSize,
            "contrast": root.contrast,
            "brightness": root.brightness,
            "vibrancy": root.vibrancy,
            "clock_format": root.clockFormat,
            "clock_font_size": root.clockFontSize,
            "show_date": root.showDate,
            "show_user": root.showUser,
            "show_layout": root.showLayout,
            "show_uptime": root.showUptime,
            "show_battery": root.showBattery,
            "show_weather": root.showWeather,
            "input_width": root.inputWidth,
            "input_height": root.inputHeight,
            "input_outline_thickness": root.inputOutlineThickness,
            "input_dots_size": root.inputDotsSize,
            "input_dots_spacing": root.inputDotsSpacing,
            "input_dots_center": root.inputDotsCenter,
            "input_fade_on_empty": root.inputFadeOnEmpty,
            "input_hide_input": root.inputHideInput,
            "input_placeholder": root.inputPlaceholder,
            "input_pos_x": root.inputPosX,
            "input_pos_y": root.inputPosY
        };
        saveSettingsProc.command = [root.scriptPath, "set", JSON.stringify(payload)];
        saveSettingsProc.running = true;
    }

    /* Process to generate .wallpaper_current */
    Process {
        id: generateWallpaperProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res = JSON.parse(text);
                    if (res && res.status === "ok") {
                        showStatus("Hyprlock wallpaper & palette updated");
                        loadSettingsProc.running = true;
                    } else if (res && res.message) {
                        showStatus(res.message);
                    }
                } catch(e) {}
            }
        }
    }

    function generateCustomWallpaper(imagePath) {
        root.backgroundCustomPath = imagePath;
        generateWallpaperProc.command = [root.scriptPath, "generate-wallpaper", imagePath];
        generateWallpaperProc.running = true;
    }

    /* Test Lock Screen runner */
    Process {
        id: testLockProc
        command: [root.scriptPath, "test"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res = JSON.parse(text);
                    if (res.status === "already_running") {
                        showStatus("Hyprlock is already running");
                    } else {
                        showStatus("Launching lock screen...");
                    }
                } catch(e) {}
            }
        }
    }

    /* Restore Backup runner */
    Process {
        id: restoreProc
        command: [root.scriptPath, "restore"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res = JSON.parse(text);
                    if (res.status === "ok") {
                        showStatus("Restored default configuration");
                        loadSettingsProc.running = true;
                    } else {
                        showStatus(res.message || "Failed to restore");
                    }
                } catch(e) {}
            }
        }
    }

    /* Main Scrollable View */
    Flickable {
        anchors.fill: parent
        contentHeight: hyprlockLockScreenInst.implicitHeight + 36
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.2)
            }
        }

        HyprlockLockScreen {
            id: hyprlockLockScreenInst
            root: root
        }
    }

    // Dedicated Modal Wallpaper Chooser Window
    HyprlockWallpaperModal {
        id: wallpaperModal
        theme: root.theme
        font: root.font
        currentSelected: root.backgroundCustomPath
        onWallpaperSelected: (path) => {
            root.backgroundCustomPath = path;
            root.backgroundSource = "custom";
            root.generateCustomWallpaper(path);
        }
    }

    /* Feedback toast notification */
    Rectangle {
        id: statusToast
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 24
        implicitWidth: toastText.implicitWidth + 32
        height: 36
        radius: 18
        color: root.theme.bgSurface ?? "#1e1e2e"
        border.color: root.theme.accentPrimary ?? "#7aa2f7"
        border.width: 1.5
        z: 9999
        opacity: root.statusVisible ? 1.0 : 0.0
        scale: root.statusVisible ? 1.0 : 0.92

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Text {
            id: toastText
            anchors.centerIn: parent
            text: root.statusMessage
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
            color: root.theme.textPrimary ?? "#c0caf5"
        }
    }
}
