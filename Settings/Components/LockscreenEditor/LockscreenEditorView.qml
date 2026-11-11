import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../wallpaper"
import "../.."
import "../Common"
import ".."
import "../../../Lockscreen"

ColumnLayout {
    required property var root
    id: mainCol
    property alias stageSandboxRef: stageSandbox
    property alias modulesPoolRef: modulesPool
    property var expandedById: ({})
    width: parent.width
    spacing: 20

    // Header Row: Title & Action Buttons (Strictly NO icons)
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Text {
                Layout.fillWidth: true
                text: "Lock Screen"
                font.family: root.font
                font.pixelSize: 20
                font.bold: true
                color: root.theme.textPrimary
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: "Configure lock screen appearance, visual filters and interactive layout"
                font.family: root.font
                font.pixelSize: 12
                color: root.theme.textSecondary
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillWidth: true }

        Process {
            id: openBackupProc
            command: ["qs", "ipc", "call", "settings", "open", "backup"]
            running: false
        }

        // Backup & Restore Button
        Rectangle {
            id: backupBtn
            implicitWidth: backupText.implicitWidth + 24
            height: 32
            radius: 6
            color: backupHover.hovered ? root.theme.bgHover : root.theme.bgBase
            border.color: backupHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder
            border.width: 1
            scale: backupMouse.pressed ? 0.95 : 1.0
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            HoverHandler { id: backupHover }

            Text {
                id: backupText
                anchors.centerIn: parent
                text: "Backup & Restore"
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.theme.textPrimary
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: backupMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: openBackupProc.running = true
            }
        }

        // Restore Defaults Button
        Rectangle {
            id: restoreBtn
            implicitWidth: restoreText.implicitWidth + 24
            height: 32
            radius: 6
            color: restoreHover.hovered ? root.theme.bgHover : root.theme.bgBase
            border.color: restoreHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder
            border.width: 1
            scale: restoreMouse.pressed ? 0.95 : 1.0
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            HoverHandler { id: restoreHover }

            Text {
                id: restoreText
                anchors.centerIn: parent
                text: "Restore Defaults"
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.theme.textPrimary
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: restoreMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.restoreProcRef.running = true
            }
        }

        // Test Lock Button
        Rectangle {
            id: testLockBtn
            implicitWidth: testLockText.implicitWidth + 24
            height: 32
            radius: 6
            color: testLockHover.hovered ? root.theme.bgHover : root.theme.bgBase
            border.color: testLockHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder
            border.width: 1
            scale: testLockMouse.pressed ? 0.95 : 1.0
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            HoverHandler { id: testLockHover }

            Text {
                id: testLockText
                anchors.centerIn: parent
                text: "Test Lock"
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.theme.textPrimary
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: testLockMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.testLockProcRef.running = true
            }
        }
    }

    /* --- 1. Interactive Lock Screen Stage & Building Blocks (On Top) --- */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Lock Screen Modules & Building Blocks"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: "Drag any building block into the live preview stage below to place it, or click to add"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textMuted
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Interactive Visual Preview Canvas Stage
        LockscreenStageSandbox {
            id: stageSandbox
            Layout.fillWidth: true
            theme: root.theme
            font: root.font
            textBlocks: root.textBlocks
            showUser: root.showUser
            showMedia: root.showMedia
            wallpaperPath: {
                const home = Quickshell.env("HOME") || "";
                if (root.backgroundSource === "custom" && root.backgroundCustomPath !== "")
                    return root.backgroundCustomPath;
                if (root.backgroundSource === "effects")
                    return home + "/.cache/quickshell/wallpaper_effects/wallpaper_modified.png";
                if (root.backgroundSource === "screenshot")
                    return "/tmp/lockscreen_screenshot.png";
                const cur = (typeof WallpaperService !== "undefined")
                    ? (WallpaperService.currentWallpaper || WallpaperService.wallpaperA || "")
                    : "";
                if (cur !== "") return cur;
                return home + "/.config/hypr/wallpaper_effects/.wallpaper_current";
            }
            brightness: root.brightness
            contrast: root.contrast
            blurPasses: root.blurPasses
            blurSize: root.blurSize
            vibrancy: root.vibrancy
            inputWidth: root.inputWidth
            inputHeight: root.inputHeight
            inputPlaceholder: root.inputPlaceholder
            inputPosX: root.inputPosX
            inputPosY: root.inputPosY
            inputHalign: root.inputHalign
            inputValign: root.inputValign
            inputOuterColor: root.inputOuterColor
            inputInnerColor: root.inputInnerColor
            inputFontColor: root.inputFontColor

            onInputColorModified: (outerCol, innerCol, fontCol) => {
                root.inputOuterColor = outerCol;
                root.inputInnerColor = innerCol;
                root.inputFontColor = fontCol;
                root.scheduleSave();
            }
            onInputMoved: (newX, newY, newHalign, newValign) => {
                root.inputPosX = newX;
                root.inputPosY = newY;
                if (newHalign) root.inputHalign = newHalign;
                if (newValign) root.inputValign = newValign;
                root.scheduleSave();
            }
            onBlockMoved: (idx, newX, newY, newHalign, newValign) => {
                if (root.textBlocks && idx >= 0 && idx < root.textBlocks.length) {
                    let blocksCopy = [...root.textBlocks];
                    let updatedItem = Object.assign({}, blocksCopy[idx], {
                        position_x: newX,
                        position_y: newY,
                        halign: newHalign || blocksCopy[idx].halign,
                        valign: newValign || blocksCopy[idx].valign
                    });
                    blocksCopy[idx] = updatedItem;
                    root.textBlocks = blocksCopy;

                    // Automatically persist position to LockscreenConfig immediately
                    if (typeof LockscreenConfig !== "undefined" && LockscreenConfig.updateModule) {
                        LockscreenConfig.updateModule(idx, {
                            position_x: newX,
                            position_y: newY,
                            halign: newHalign || blocksCopy[idx].halign,
                            valign: newValign || blocksCopy[idx].valign
                        });
                    }
                }
            }
            onDeleteBlockRequested: (idx) => {
                if (root.deleteModule) root.deleteModule(idx);
                else if (root.deleteBlock) root.deleteBlock(idx);
            }
            onApplyRequested: (blocks) => {
                let list = (blocks && blocks.length > 0) ? blocks : (root.textBlocks ?? []);
                let payload = [
                    {
                        index: -1,
                        position_x: stageSandbox.liveInputX,
                        position_y: stageSandbox.liveInputY,
                        halign: stageSandbox.inputHalign || "center",
                        valign: stageSandbox.inputValign || "center"
                    }
                ];
                for (let i = 0; i < list.length; i++) {
                    let b = list[i];
                    payload.push({
                        index: b.index !== undefined ? b.index : i,
                        id: b.id,
                        position_x: b.position_x !== undefined ? b.position_x : 0,
                        position_y: b.position_y !== undefined ? b.position_y : 0,
                        halign: b.halign || "center",
                        valign: b.valign || "center"
                    });
                }
                root.inputPosX = stageSandbox.liveInputX;
                root.inputPosY = stageSandbox.liveInputY;
                root.inputHalign = stageSandbox.inputHalign || "center";
                root.inputValign = stageSandbox.inputValign || "center";
                if (root.updatePositions) {
                    root.updatePositions(payload);
                } else if (typeof LockscreenConfig !== "undefined" && LockscreenConfig.updatePositions) {
                    LockscreenConfig.updatePositions(payload);
                }
                if (root.showStatus) root.showStatus("Positions saved to Quickshell lock screen");
            }
            onResetRequested: {
                stageSandbox.hasUnsavedMoves = false;
                stageSandbox.syncBlocks();
                if (root.showStatus) root.showStatus("Reset stage sandbox to saved positions");
            }
        }

        // Available Building Blocks Tray (matches Picture 2)
        AvailableModulesPool {
            id: modulesPool
            hostRoot: mainCol.root
        }

        // Active Configured Modules List with Edit / Custom Cmd Capabilities
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: LockscreenConfig.modules && LockscreenConfig.modules.length > 0

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4

                Text {
                    text: "Configured Modules (" + (LockscreenConfig.modules ? LockscreenConfig.modules.length : 0) + ")"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                }

                Item { Layout.fillWidth: true }
            }

            Repeater {
                model: LockscreenConfig.modules ? LockscreenConfig.modules.length : 0

                LockscreenModuleCard {
                    required property int index
                    readonly property var itemData: (LockscreenConfig.modules && index >= 0 && index < LockscreenConfig.modules.length)
                        ? LockscreenConfig.modules[index]
                        : ({})
                    readonly property string modKey: (itemData && itemData.id) ? String(itemData.id) : ("idx_" + index)

                    moduleData: itemData
                    moduleIndex: index
                    theme: root.theme
                    font: root.font
                    isExpanded: Boolean(mainCol.expandedById && mainCol.expandedById[modKey])

                    onExpandedToggled: (exp) => {
                        let mapCopy = Object.assign({}, mainCol.expandedById || {});
                        if (exp) mapCopy[modKey] = true;
                        else delete mapCopy[modKey];
                        mainCol.expandedById = mapCopy;
                    }

                    onModuleSaved: (idx, payload) => {
                        if (root.updateModule) root.updateModule(idx, payload);
                        else LockscreenConfig.updateModule(idx, payload);
                    }
                    onModuleDeleted: (idx) => {
                        if (root.deleteModule) root.deleteModule(idx);
                        else LockscreenConfig.deleteModule(idx);
                    }
                }
            }
        }
    }

    /* --- 2. Background & Visual Filters Group (Below Stage) --- */
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
            border.color: root.theme.bgBorder
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

                // Wallpaper Source Segmented Track
                PreferenceRow {
                    title: "Wallpaper Source"
                    subtitle: "Select background image rendering mode"

                    Rectangle {
                        id: wpSourceSegmentTrack
                        width: 320
                        height: 32
                        radius: 7
                        color: root.theme.bgBase
                        border.color: root.theme.bgBorder
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        readonly property var modes: [
                            { label: "Current", value: "wallpaper" },
                            { label: "Effects", value: "effects" },
                            { label: "Screenshot", value: "screenshot" },
                            { label: "Custom", value: "custom" }
                        ]

                        readonly property int activeIdx: {
                            if (root.backgroundSource === "effects") return 1;
                            if (root.backgroundSource === "screenshot") return 2;
                            if (root.backgroundSource === "custom") return 3;
                            return 0; // "wallpaper" default
                        }

                        readonly property real cellWidth: (width - 6 - (modes.length - 1) * 3) / modes.length

                        /* Sliding Selection Pill (Matching SettingSliderRow / Image 4) */
                        Rectangle {
                            visible: wpSourceSegmentTrack.activeIdx >= 0
                            y: 3
                            height: parent.height - 6
                            width: wpSourceSegmentTrack.cellWidth
                            x: 3 + Math.max(0, wpSourceSegmentTrack.activeIdx) * (wpSourceSegmentTrack.cellWidth + 3)
                            radius: 5
                            color: root.theme.bgSelected
                            border.color: root.theme.accentPrimary
                            border.width: 1

                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Repeater {
                                model: wpSourceSegmentTrack.modes

                                delegate: Rectangle {
                                    id: wpSegBtn
                                    required property var modelData
                                    required property int index
                                    readonly property bool isSel: wpSourceSegmentTrack.activeIdx === wpSegBtn.index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isSel && wpSegHover.hovered ? root.theme.bgHover : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: wpSegHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: wpSegBtn.modelData.label
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: wpSegBtn.isSel
                                        color: wpSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                        opacity: wpSegBtn.isSel || wpSegHover.hovered ? 1.0 : 0.75
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        id: wpSegMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.backgroundSource = wpSegBtn.modelData.value;
                                            root.scheduleSave();
                                            if (wpSegBtn.modelData.value === "custom" && root.wallpaperModalRef) {
                                                root.wallpaperModalRef.visible = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Custom Wallpaper Selector Row (shown when Custom is active)
                ColumnLayout {
                    visible: root.backgroundSource === "custom"
                    Layout.fillWidth: true
                    spacing: 0

                    RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

                    PreferenceRow {
                        title: "Custom Wallpaper"
                        subtitle: root.backgroundCustomPath !== "" ? root.backgroundCustomPath.split("/").pop() : "No custom wallpaper chosen"

                        Rectangle {
                            implicitWidth: customWpText.implicitWidth + 24
                            height: 32
                            radius: 6
                            color: customWpHover.hovered ? root.theme.bgHover : root.theme.bgBase
                            border.color: customWpHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1
                            scale: customWpMouse.pressed ? 0.95 : 1.0
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                            Behavior on scale { NumberAnimation { duration: 100 } }
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: customWpHover }

                            Text {
                                id: customWpText
                                anchors.centerIn: parent
                                text: root.backgroundCustomPath !== "" ? "Change Wallpaper..." : "Choose Wallpaper..."
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: true
                                color: root.theme.textPrimary
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: customWpMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.wallpaperModalRef) root.wallpaperModalRef.visible = true;
                                }
                            }
                        }
                    }
                }

                RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

                // Blur Passes Slider
                PreferenceSlider {
                    title: "Blur Passes"
                    subtitle: "Number of blur filter passes (0 disables blur)"
                    minVal: 0
                    maxVal: 5
                    unit: ""
                    currentVal: root.blurPasses
                    onValueChanged: (val) => {
                        root.blurPasses = val;
                        root.scheduleSave();
                    }
                }

                RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

                // Blur Size Slider
                PreferenceSlider {
                    title: "Blur Radius"
                    subtitle: "Sampling radius for gaussian blur filter"
                    minVal: 1
                    maxVal: 10
                    unit: ""
                    currentVal: root.blurSize
                    onValueChanged: (val) => {
                        root.blurSize = val;
                        root.scheduleSave();
                    }
                }

                RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

                // Brightness Slider
                PreferenceSlider {
                    title: "Brightness"
                    subtitle: "Background image exposure adjustment"
                    minVal: 0.1
                    maxVal: 2.0
                    decimalPlaces: 2
                    unit: ""
                    currentVal: root.brightness
                    onValueChanged: (val) => {
                        root.brightness = val;
                        root.scheduleSave();
                    }
                }

                RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

                // Contrast Slider
                PreferenceSlider {
                    title: "Contrast"
                    subtitle: "Background color contrast level"
                    minVal: 0.1
                    maxVal: 2.0
                    decimalPlaces: 2
                    unit: ""
                    currentVal: root.contrast
                    onValueChanged: (val) => {
                        root.contrast = val;
                        root.scheduleSave();
                    }
                }

                RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

                // Vibrancy Slider
                PreferenceSlider {
                    title: "Vibrancy"
                    subtitle: "Color saturation intensity multiplier"
                    minVal: 0.0
                    maxVal: 1.0
                    decimalPlaces: 2
                    unit: ""
                    currentVal: root.vibrancy
                    onValueChanged: (val) => {
                        root.vibrancy = val;
                        root.scheduleSave();
                    }
                }
            }
        }
    }

    /* --- 3. Input Field & Authentication Group (Below Stage) --- */
    LockscreenInputFieldAuthentication {
        root: mainCol.root
    }
}
