import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../wallpaper"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
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

        // Restore Defaults Button (Modern secondary action button)
        Rectangle {
            id: restoreBtn
            implicitWidth: restoreText.implicitWidth + 24
            height: 32
            radius: 8
            color: restoreHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25))
            border.color: restoreHover.hovered ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
            border.width: 1
            scale: restoreMouse.pressed ? 0.96 : 1.0
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 80 } }

            HoverHandler { id: restoreHover }

            Text {
                id: restoreText
                anchors.centerIn: parent
                text: "Restore Defaults"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: restoreHover.hovered ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: restoreMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.restoreProcRef.running = true
            }
        }

        // Test Lock Screen Button (Modern primary action button)
        Rectangle {
            id: testLockBtn
            implicitWidth: testLockText.implicitWidth + 26
            height: 32
            radius: 8
            color: testLockHover.hovered ? Qt.darker(root.theme.accentPrimary ?? "#7aa2f7", 1.1) : (root.theme.accentPrimary ?? "#7aa2f7")
            scale: testLockMouse.pressed ? 0.96 : 1.0
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 80 } }

            HoverHandler { id: testLockHover }

            Text {
                id: testLockText
                anchors.centerIn: parent
                text: "Test Lock"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: "#ffffff"
            }

            MouseArea {
                id: testLockMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.testLockProcRef.running = true
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

                // Background Source Row (Segmented track with sliding pill)
                PreferenceRow {
                    title: "Wallpaper Source"
                    subtitle: "Select background image rendering mode"

                    Rectangle {
                        id: wpSourceTrack
                        readonly property var modes: [
                            { id: "wallpaper_current", label: "Current" },
                            { id: "wallpaper_modified", label: "Effects" },
                            { id: "screenshot", label: "Screenshot" },
                            { id: "custom", label: "Custom" }
                        ]
                        readonly property int activeIdx: {
                            for (let i = 0; i < modes.length; i++) {
                                if (modes[i].id === root.backgroundSource) return i;
                            }
                            return 0;
                        }
                        readonly property int count: modes.length
                        readonly property real cellWidth: count > 0 ? ((width - 6 - (count - 1) * 3) / count) : 0
                        width: 280
                        height: 32
                        radius: 7
                        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        /* Sliding Selection Pill */
                        Rectangle {
                            y: 3
                            height: parent.height - 6
                            width: wpSourceTrack.cellWidth
                            x: 3 + Math.max(0, wpSourceTrack.activeIdx) * (wpSourceTrack.cellWidth + 3)
                            radius: 5
                            color: root.theme.bgSelected
                            border.color: root.theme.accentPrimary ?? "#7aa2f7"
                            border.width: 1

                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 3

                            Repeater {
                                model: wpSourceTrack.modes
                                delegate: Rectangle {
                                    id: wpModeBtn
                                    required property var modelData
                                    required property int index
                                    readonly property bool isSel: wpSourceTrack.activeIdx === wpModeBtn.index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isSel && segHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: segHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: wpModeBtn.modelData.label
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: wpModeBtn.isSel
                                        color: wpModeBtn.isSel ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.backgroundSource = wpModeBtn.modelData.id;
                                            if (wpModeBtn.modelData.id === "custom" && root.backgroundCustomPath === "") {
                                                root.wallpaperModalRef.visible = true;
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

                // Custom Wallpaper Selector Row (Refined action button)
                PreferenceRow {
                    visible: root.backgroundSource === "custom"
                    title: "Custom Wallpaper"
                    subtitle: root.backgroundCustomPath !== "" ? root.backgroundCustomPath.split("/").pop() : "Click to select a wallpaper"

                    Rectangle {
                        id: chooseWpBtn
                        implicitWidth: chooseWpTxt.implicitWidth + 24
                        height: 32
                        radius: 7
                        color: chooseWpHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25))
                        border.color: chooseWpHover.hovered ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                        border.width: 1
                        scale: chooseWpMouse.pressed ? 0.96 : 1.0
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        HoverHandler { id: chooseWpHover }

                        Text {
                            id: chooseWpTxt
                            anchors.centerIn: parent
                            text: root.backgroundCustomPath !== "" ? "Change Wallpaper..." : "Choose Wallpaper..."
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: chooseWpHover.hovered ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: chooseWpMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.wallpaperModalRef.visible = true
                        }
                    }
                }

                RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

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

                RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

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

                RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

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

                RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

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

                RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

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
    HyprlockClockDateFormatting {
        root: mainCol.root
    }

    /* --- 3. Authentication & Input Field Group --- */
    HyprlockInputFieldAuthentication {
        root: mainCol.root
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

            // Add Custom Block Button (Modern secondary action button)
            Rectangle {
                implicitWidth: addBtnText.implicitWidth + 24
                height: 30
                radius: 7
                color: addBtnHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25))
                border.color: addBtnHover.hovered ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                border.width: 1
                scale: addBtnMouse.pressed ? 0.96 : 1.0
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }
                Behavior on scale { NumberAnimation { duration: 80 } }

                HoverHandler { id: addBtnHover }

                Text {
                    id: addBtnText
                    anchors.centerIn: parent
                    text: "+ Add Custom Block"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: addBtnHover.hovered ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                MouseArea {
                    id: addBtnMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.addCustomBlock()
                }
            }
        }

        // Interactive Visual Preview Canvas Stage
        HyprlockStageSandbox {
            id: stageSandbox
            Layout.fillWidth: true
            theme: root.theme
            font: root.font
            textBlocks: root.textBlocks
            wallpaperPath: (root.backgroundSource === "custom" && root.backgroundCustomPath !== "") ? root.backgroundCustomPath : (WallpaperService.currentWallpaper ?? "")
            brightness: root.brightness
            contrast: root.contrast
            blurPasses: root.blurPasses
            inputWidth: root.inputWidth
            inputHeight: root.inputHeight
            inputPlaceholder: root.inputPlaceholder
            inputPosX: root.inputPosX
            inputPosY: root.inputPosY
            inputHalign: root.inputHalign
            inputValign: root.inputValign
            onInputMoved: (newX, newY) => {
                root.inputPosX = newX;
                root.inputPosY = newY;
            }
            onBlockMoved: (idx, newX, newY) => {
                if (root.textBlocks && idx >= 0 && idx < root.textBlocks.length) {
                    let blocksCopy = [...root.textBlocks];
                    let b = Object.assign({}, blocksCopy[idx]);
                    b.position_x = newX;
                    b.position_y = newY;
                    blocksCopy[idx] = b;
                    root.textBlocks = blocksCopy;
                }
            }
            onApplyRequested: (blocks) => {
                let list = (blocks && blocks.length > 0) ? blocks : (root.textBlocks ?? []);
                let payload = [
                    {
                        index: -1,
                        position_x: stageSandbox.liveInputX,
                        position_y: stageSandbox.liveInputY
                    }
                ];
                for (let i = 0; i < list.length; i++) {
                    let b = list[i];
                    payload.push({
                        index: b.index !== undefined ? b.index : i,
                        position_x: b.position_x !== undefined ? b.position_x : 0,
                        position_y: b.position_y !== undefined ? b.position_y : 0
                    });
                }
                root.updatePositionsProcRef.running = false;
                root.updatePositionsProcRef.command = [root.scriptPath, "update-positions", JSON.stringify(payload)];
                root.updatePositionsProcRef.running = true;
            }
            onResetRequested: {
                root.loadSettingsProcRef.running = true;
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
