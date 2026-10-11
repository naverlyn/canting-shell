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

Item {
    id: root
    property var theme
    property string font: "Hack Nerd Font"

    /* Internal state synced with hyprlock.conf */
    property bool isLoading: true

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
        command: ["/home/xeana/.config/quickshell/Settings/scripts/manage_hyprlock.sh", "get"]
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
    }

    function updateBlock(index, payload) {
        updateBlockProc.command = ["/home/xeana/.config/quickshell/Settings/scripts/manage_hyprlock.sh", "update-block", String(index), JSON.stringify(payload)];
        updateBlockProc.running = true;
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
        addBlockProc.command = ["/home/xeana/.config/quickshell/Settings/scripts/manage_hyprlock.sh", "add-block", JSON.stringify(newPayload)];
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
        deleteBlockProc.command = ["/home/xeana/.config/quickshell/Settings/scripts/manage_hyprlock.sh", "delete-block", String(index)];
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
            "input_placeholder": root.inputPlaceholder
        };
        saveSettingsProc.command = ["/home/xeana/.config/quickshell/Settings/scripts/manage_hyprlock.sh", "set", JSON.stringify(payload)];
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
        generateWallpaperProc.command = ["/home/xeana/.config/quickshell/Settings/scripts/manage_hyprlock.sh", "generate-wallpaper", imagePath];
        generateWallpaperProc.running = true;
    }

    /* Test Lock Screen runner */
    Process {
        id: testLockProc
        command: ["/home/xeana/.config/quickshell/Settings/scripts/manage_hyprlock.sh", "test"]
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
        command: ["/home/xeana/.config/quickshell/Settings/scripts/manage_hyprlock.sh", "restore"]
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

    /* --- Standardized Alignment Subcomponents --- */

    // Clean Toggle Switch Component (width: 44, height: 24)
    component SwitchToggle: Rectangle {
        id: sw
        property bool checked: false
        signal toggled(bool newState)

        width: 44
        height: 24
        radius: 12
        color: sw.checked ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

        Behavior on color { ColorAnimation { duration: 160 } }

        Rectangle {
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 3 : 3
            color: sw.checked ? "#ffffff" : (root.theme.textPrimary ?? "#c0caf5")

            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                sw.checked = !sw.checked;
                sw.toggled(sw.checked);
            }
        }
    }

    // Standardized Preference Row with strictly aligned right container
    component PreferenceRow: Item {
        id: pr
        property string title: ""
        property string subtitle: ""
        default property alias content: rowSlot.data

        Layout.fillWidth: true
        height: 52

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 16

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true

                Text {
                    text: pr.title
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    visible: pr.subtitle !== ""
                    text: pr.subtitle
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                id: rowSlot
                spacing: 8
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            }
        }
    }

    // Standardized Slider Row aligned with SoundSettings layout (fixed label width, fillWidth track, fixed value badge)
    component PreferenceSlider: Item {
        id: ps
        property string title: ""
        property string subtitle: ""
        property string unit: ""
        property real minVal: 0
        property real maxVal: 100
        property real currentVal: 0
        property int decimalPlaces: 0
        signal valueChanged(real newVal)

        Layout.fillWidth: true
        height: 52

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 16

            // Left Label Column (Fixed width: guarantees 100% vertical alignment of seekbars)
            Item {
                Layout.preferredWidth: 320
                Layout.minimumWidth: 320
                Layout.maximumWidth: 320
                Layout.fillHeight: true

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    spacing: 2

                    Text {
                        width: parent.width
                        text: ps.title
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        visible: ps.subtitle !== ""
                        width: parent.width
                        text: ps.subtitle
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }
            }

            // Seekbar Track Area: Fills all remaining width across the card (matches SoundSettings)
            Rectangle {
                id: track
                Layout.fillWidth: true
                height: 7
                radius: 3.5
                color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14)
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                // Active progress fill bar
                Rectangle {
                    id: fillBar
                    height: parent.height
                    radius: parent.radius
                    width: Math.max(0, Math.min(parent.width, parent.width * ((ps.currentVal - ps.minVal) / Math.max(0.0001, ps.maxVal - ps.minVal))))
                    color: root.theme.accentPrimary ?? "#7aa2f7"

                    Behavior on width {
                        enabled: !sliderMouse.pressed
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }
                }

                // Soft glow halo ring around knob on hover / press
                Rectangle {
                    anchors.centerIn: knob
                    width: knob.width + (sliderMouse.pressed ? 8 : (sliderMouse.containsMouse ? 6 : 0))
                    height: width
                    radius: width / 2
                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, sliderMouse.pressed ? 0.35 : (sliderMouse.containsMouse ? 0.2 : 0))
                    z: 1

                    Behavior on width { NumberAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                // High-contrast, tactile knob handle
                Rectangle {
                    id: knob
                    width: sliderMouse.containsMouse || sliderMouse.pressed ? 17 : 15
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(track.width - width, (track.width * ((ps.currentVal - ps.minVal) / Math.max(0.0001, ps.maxVal - ps.minVal))) - width / 2))
                    color: "#ffffff"
                    border.color: root.theme.accentPrimary ?? "#7aa2f7"
                    border.width: 3
                    z: 2

                    Behavior on width { NumberAnimation { duration: 120 } }
                    Behavior on x {
                        enabled: !sliderMouse.pressed
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: sliderMouse
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: 3

                    function updateValue(mouseX) {
                        let ratio = Math.max(0, Math.min(1, mouseX / width));
                        let raw = ps.minVal + ratio * (ps.maxVal - ps.minVal);
                        let val = ps.decimalPlaces > 0 ? parseFloat(raw.toFixed(ps.decimalPlaces)) : Math.round(raw);
                        ps.currentVal = val;
                        ps.valueChanged(val);
                    }

                    onPressed: (m) => updateValue(m.x)
                    onPositionChanged: (m) => { if (pressed) updateValue(m.x); }
                }
            }

            // Value Label (Fixed width, right-aligned clean text without background)
            Text {
                Layout.preferredWidth: 50
                Layout.minimumWidth: 50
                Layout.maximumWidth: 50
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: (ps.decimalPlaces > 0 ? ps.currentVal.toFixed(ps.decimalPlaces) : String(Math.round(ps.currentVal))) + (ps.unit !== "" ? (" " + ps.unit) : "")
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.theme.accentPrimary ?? "#7aa2f7"
            }
        }
    }

    // Divider
    component RowDivider: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        height: 1
        color: Qt.rgba(1, 1, 1, 0.05)
    }

    /* Main Scrollable View */
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 36
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

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 20

            // Header Row: Title & Action Buttons (Strictly NO icons)
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Lock Screen"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "Configure lock screen appearance and behavior"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                // Restore Defaults Button (Clean Text)
                Rectangle {
                    id: restoreBtn
                    implicitWidth: restoreText.implicitWidth + 24
                    implicitHeight: 32
                    radius: 7
                    color: restoreHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : (root.theme.bgSurface ?? Qt.rgba(0,0,0,0.25))
                    border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    HoverHandler { id: restoreHover }

                    Text {
                        id: restoreText
                        anchors.centerIn: parent
                        text: "Restore Defaults"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: restoreProc.running = true
                    }
                }

                // Test Lock Screen Button (Clean Text)
                Rectangle {
                    id: testLockBtn
                    implicitWidth: testLockText.implicitWidth + 26
                    implicitHeight: 32
                    radius: 7
                    color: testLockHover.hovered ? (root.theme.accentPrimary ?? "#7aa2f7") : Qt.rgba(0.48, 0.63, 0.97, 0.85)
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    Behavior on color { ColorAnimation { duration: 140 } }
                    HoverHandler { id: testLockHover }

                    Text {
                        id: testLockText
                        anchors.centerIn: parent
                        text: "Test Lock"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: testLockProc.running = true
                    }
                }
            }

            /* --- 1. Background & Visual Filters Group --- */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Background & Visual Filters"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: bgCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: bgCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        // Background Source Row (260px wide segmented picker)
                        PreferenceRow {
                            title: "Wallpaper Source"
                            subtitle: "Select background image rendering mode"

                            Rectangle {
                                width: 260
                                height: 32
                                radius: 7
                                color: root.theme.bgBase ?? Qt.rgba(0,0,0,0.25)
                                border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.08)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 3

                                    Repeater {
                                        model: [
                                            { id: "wallpaper_current", label: "Current" },
                                            { id: "wallpaper_modified", label: "Effects" },
                                            { id: "screenshot", label: "Screenshot" },
                                            { id: "custom", label: "Custom" }
                                        ]
                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: root.backgroundSource === modelData.id ? root.theme.bgSelected : (segHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")
                                            border.color: root.backgroundSource === modelData.id ? root.theme.accentPrimary : "transparent"
                                            border.width: root.backgroundSource === modelData.id ? 1 : 0

                                            HoverHandler { id: segHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: root.backgroundSource === modelData.id
                                                color: root.backgroundSource === modelData.id ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.backgroundSource = modelData.id;
                                                    if (modelData.id === "custom" && root.backgroundCustomPath === "") {
                                                        wallpaperModal.visible = true;
                                                    } else {
                                                        root.scheduleSave();
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Custom Wallpaper Selector Row (Clean Libadwaita layout)
                        PreferenceRow {
                            visible: root.backgroundSource === "custom"
                            title: "Custom Wallpaper"
                            subtitle: root.backgroundCustomPath !== "" ? root.backgroundCustomPath.split("/").pop() : "Click to select a wallpaper"

                            Rectangle {
                                width: 260
                                height: 32
                                radius: 7
                                color: chooseWpHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : (root.theme.bgBase ?? Qt.rgba(0,0,0,0.25))
                                border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)
                                border.width: 1

                                HoverHandler { id: chooseWpHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.backgroundCustomPath !== "" ? "Change Wallpaper..." : "Choose Wallpaper..."
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.accentPrimary ?? "#7aa2f7"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: wallpaperModal.visible = true
                                }
                            }
                        }

                        RowDivider {}

                        // Blur Passes
                        PreferenceSlider {
                            title: "Blur Passes"
                            subtitle: "Number of blur filter passes (0 disables blur)"
                            minVal: 0
                            maxVal: 5
                            currentVal: root.blurPasses
                            unit: currentVal === 0 ? "(Off)" : ""
                            onValueChanged: (val) => {
                                root.blurPasses = val;
                                root.scheduleSave();
                            }
                        }

                        RowDivider {}

                        // Blur Size
                        PreferenceSlider {
                            title: "Blur Radius"
                            subtitle: "Sampling radius for gaussian blur filter"
                            minVal: 1
                            maxVal: 15
                            currentVal: root.blurSize
                            onValueChanged: (val) => {
                                root.blurSize = val;
                                root.scheduleSave();
                            }
                        }

                        RowDivider {}

                        // Brightness
                        PreferenceSlider {
                            title: "Brightness"
                            subtitle: "Background image exposure adjustment"
                            minVal: 0.2
                            maxVal: 1.5
                            decimalPlaces: 2
                            currentVal: root.brightness
                            onValueChanged: (val) => {
                                root.brightness = val;
                                root.scheduleSave();
                            }
                        }

                        RowDivider {}

                        // Contrast
                        PreferenceSlider {
                            title: "Contrast"
                            subtitle: "Background color contrast level"
                            minVal: 0.5
                            maxVal: 2.0
                            decimalPlaces: 2
                            currentVal: root.contrast
                            onValueChanged: (val) => {
                                root.contrast = val;
                                root.scheduleSave();
                            }
                        }

                        RowDivider {}

                        // Vibrancy
                        PreferenceSlider {
                            title: "Vibrancy"
                            subtitle: "Color saturation intensity multiplier"
                            minVal: 0.0
                            maxVal: 1.0
                            decimalPlaces: 2
                            currentVal: root.vibrancy
                            onValueChanged: (val) => {
                                root.vibrancy = val;
                                root.scheduleSave();
                            }
                        }
                    }
                }
            }

            /* --- 2. Clock & Date Group --- */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Clock & Date Formatting"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: clockCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: clockCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        // Clock Time Format Row (200px wide segmented picker)
                        PreferenceRow {
                            title: "Time Format"
                            subtitle: "12-Hour AM/PM or 24-Hour standard format"

                            Rectangle {
                                width: 200
                                height: 32
                                radius: 7
                                color: root.theme.bgBase ?? Qt.rgba(0,0,0,0.25)
                                border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.08)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 4

                                    // 12-Hour
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 5
                                        color: root.clockFormat === "12h" ? root.theme.bgSelected : (h12Hover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")
                                        border.color: root.clockFormat === "12h" ? root.theme.accentPrimary : "transparent"
                                        border.width: root.clockFormat === "12h" ? 1 : 0

                                        HoverHandler { id: h12Hover }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "12-Hour"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: root.clockFormat === "12h"
                                            color: root.clockFormat === "12h" ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.clockFormat = "12h";
                                                root.scheduleSave();
                                            }
                                        }
                                    }

                                    // 24-Hour
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 5
                                        color: root.clockFormat === "24h" ? root.theme.bgSelected : (h24Hover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")
                                        border.color: root.clockFormat === "24h" ? root.theme.accentPrimary : "transparent"
                                        border.width: root.clockFormat === "24h" ? 1 : 0

                                        HoverHandler { id: h24Hover }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "24-Hour"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: root.clockFormat === "24h"
                                            color: root.clockFormat === "24h" ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.clockFormat = "24h";
                                                root.scheduleSave();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        // Clock Font Size
                        PreferenceSlider {
                            title: "Clock Font Size"
                            subtitle: "Typography scale of the central time indicator"
                            minVal: 60
                            maxVal: 160
                            unit: "pt"
                            currentVal: root.clockFontSize
                            onValueChanged: (val) => {
                                root.clockFontSize = val;
                                root.scheduleSave();
                            }
                        }

                        RowDivider {}

                        // Show Date Toggle
                        PreferenceRow {
                            title: "Show Date"
                            subtitle: "Display weekday and calendar day beneath time"

                            SwitchToggle {
                                checked: root.showDate
                                onToggled: (st) => {
                                    root.showDate = st;
                                    root.scheduleSave();
                                }
                            }
                        }
                    }
                }
            }

            /* --- 3. Authentication & Input Field Group --- */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Input Field & Authentication"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: authCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: authCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        // Immediate Render Toggle
                        PreferenceRow {
                            title: "Immediate Render"
                            subtitle: "Render background instantly without waiting for graphical resources"

                            SwitchToggle {
                                checked: root.generalImmediateRender
                                onToggled: (st) => {
                                    root.generalImmediateRender = st;
                                    root.scheduleSave();
                                }
                            }
                        }

                        RowDivider {}

                        // Placeholder Text Input (260px wide, NO icon)
                        PreferenceRow {
                            title: "Placeholder Text"
                            subtitle: "Text shown inside empty password field"

                            Rectangle {
                                width: 260
                                height: 32
                                radius: 6
                                color: root.theme.bgBase ?? Qt.rgba(0,0,0,0.2)
                                border.color: placeholderInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.08))
                                border.width: 1

                                TextInput {
                                    id: placeholderInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.inputPlaceholder
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textPrimary
                                    selectByMouse: true
                                    onEditingFinished: {
                                        root.inputPlaceholder = text.trim();
                                        root.scheduleSave();
                                    }
                                }
                            }
                        }

                        RowDivider {}

                        // Input Field Width
                        PreferenceSlider {
                            title: "Input Box Width"
                            subtitle: "Horizontal dimensions of the password entry box"
                            minVal: 180
                            maxVal: 380
                            unit: "px"
                            currentVal: root.inputWidth
                            onValueChanged: (val) => {
                                root.inputWidth = val;
                                root.scheduleSave();
                            }
                        }

                        RowDivider {}

                        // Input Field Height
                        PreferenceSlider {
                            title: "Input Box Height"
                            subtitle: "Vertical dimensions of the password entry box"
                            minVal: 40
                            maxVal: 80
                            unit: "px"
                            currentVal: root.inputHeight
                            onValueChanged: (val) => {
                                root.inputHeight = val;
                                root.scheduleSave();
                            }
                        }

                        RowDivider {}

                        // Outline Thickness
                        PreferenceSlider {
                            title: "Outline Border Thickness"
                            subtitle: "Border stroke width around input field"
                            minVal: 0
                            maxVal: 6
                            unit: "px"
                            currentVal: root.inputOutlineThickness
                            onValueChanged: (val) => {
                                root.inputOutlineThickness = val;
                                root.scheduleSave();
                            }
                        }

                        RowDivider {}

                        // Fade on Empty
                        PreferenceRow {
                            title: "Fade on Empty"
                            subtitle: "Fade out field outline when no characters are entered"

                            SwitchToggle {
                                checked: root.inputFadeOnEmpty
                                onToggled: (st) => {
                                    root.inputFadeOnEmpty = st;
                                    root.scheduleSave();
                                }
                            }
                        }

                        RowDivider {}

                        // Center Password Dots
                        PreferenceRow {
                            title: "Center Password Dots"
                            subtitle: "Center typed characters horizontally inside the box"

                            SwitchToggle {
                                checked: root.inputDotsCenter
                                onToggled: (st) => {
                                    root.inputDotsCenter = st;
                                    root.scheduleSave();
                                }
                            }
                        }
                    }
                }
            }

            /* --- 4. Text & Command Building Blocks --- */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "Text & Command Building Blocks"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textSecondary
                        }
                        Text {
                            text: "Modular lock screen text labels, variables ($USER, $LAYOUT), and executable shell scripts"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Add Custom Block Button (Clean Text)
                    Rectangle {
                        implicitWidth: addBtnText.implicitWidth + 24
                        height: 30
                        radius: 6
                        color: addBtnHover.hovered ? (root.theme.accentPrimary ?? "#7aa2f7") : Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.15)
                        border.color: root.theme.accentPrimary ?? "#7aa2f7"
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        HoverHandler { id: addBtnHover }

                        Text {
                            id: addBtnText
                            anchors.centerIn: parent
                            text: "+ Add Custom Block"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: addBtnHover.hovered ? "#ffffff" : (root.theme.accentPrimary ?? "#7aa2f7")
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.addCustomBlock()
                        }
                    }
                }

                // Empty state placeholder
                Rectangle {
                    visible: !root.textBlocks || root.textBlocks.length === 0
                    Layout.fillWidth: true
                    height: 60
                    radius: 10
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Loading building blocks..."
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                    }
                }

                // List of Building Block Cards
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: root.textBlocks
                        delegate: HyprlockBlockCard {
                            required property var modelData
                            required property int index
                            blockData: modelData
                            blockIndex: index
                            theme: root.theme
                            font: root.font
                            onBlockSaved: (idx, payload) => root.updateBlock(idx, payload)
                            onBlockDeleted: (idx) => root.deleteBlock(idx)
                        }
                    }
                }
            }
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
        anchors.bottomMargin: 16
        implicitWidth: toastText.implicitWidth + 28
        height: 34
        radius: 17
        color: root.theme.bgSelected ?? "#283457"
        border.color: root.theme.accentPrimary ?? "#7aa2f7"
        border.width: 1
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
