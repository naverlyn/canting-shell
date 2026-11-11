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
        border.color: root.theme.bgBorder
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

            function resolveAuthColor(colStr) {
                const t = root.theme;
                if (!colStr) return t.textPrimary;
                let str = String(colStr).trim();
                if (str.startsWith("#")) return str;
                if (str.startsWith("rgb(") || str.startsWith("rgba(")) {
                    let m = str.match(/rgba?\(\s*([0-9a-fA-F]{6})\s*\)/);
                    if (m) return "#" + m[1];
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

                const cmap = {
                    "$accent": pHex, "$accentPrimary": pHex,
                    "$mauve": pHex, "$pink": pHex,
                    "$blue": cHex, "$sapphire": cHex, "$sky": cHex, "$lavender": cHex,
                    "$teal": gHex, "$green": gHex,
                    "$yellow": oHex, "$peach": oHex,
                    "$maroon": rHex, "$red": rHex, "$flamingo": rHex,
                    "$rosewater": txtPri,
                    "$text": txtPri, "$subtext1": txtSec, "$subtext0": txtMut,
                    "$surface2": bgSel, "$surface1": bgHov, "$surface0": bgSurf,
                    "$base": bgBase, "$mantle": bgBase, "$crust": bgBase,
                    "$color0": bgSurf, "$color1": rHex, "$color2": gHex, "$color3": oHex,
                    "$color4": cHex, "$color5": pHex, "$color6": cHex, "$color7": txtSec,
                    "$color8": txtMut, "$color9": rHex, "$color10": txtSec, "$color11": oHex,
                    "$color12": cHex, "$color13": pHex, "$color14": gHex, "$color15": txtPri
                };
                return cmap[str] || pHex;
            }

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

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Lock & Unlock Animation Toggle
            PreferenceRow {
                title: "Lock & Unlock Animation"
                subtitle: "Play entrance and unlock success transitions on the lock screen"

                SwitchToggle {
                    checked: root.unlockAnimation
                    onToggled: (st) => {
                        root.unlockAnimation = st;
                        root.scheduleSave();
                    }
                }
            }

            // Lock Screen Animation Style Preset Selector (Spacious 2-Row Layout)
            ColumnLayout {
                visible: root.unlockAnimation
                Layout.fillWidth: true
                spacing: 0

                RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.topMargin: 10
                    Layout.bottomMargin: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: "Lock Screen Animation Style"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: {
                                    const st = root.animationStyle || "default";
                                    if (st === "staggered") return "Modules fly in & cascade out from their screen edges with spring physics";
                                    if (st === "curtain") return "Cinematic split shutter curtains with glowing horizontal laser seam";
                                    if (st === "depth") return "Dramatic camera zoom with progressive depth-of-field blur & focus pull";
                                    if (st === "portal") return "Radial shockwave iris expanding & collapsing from the password box";
                                    return "Default smooth fade, subtle background zoom, and expanding success ripple";
                                }
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                                elide: Text.ElideRight
                            }
                        }

                        // Live Preview Button on Stage
                        Rectangle {
                            id: previewAnimBtn
                            implicitWidth: previewAnimText.implicitWidth + 24
                            height: 30
                            radius: 6
                            color: previewAnimHover.hovered ? root.theme.bgHover : root.theme.bgBase
                            border.color: previewAnimHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1
                            scale: previewAnimMouse.pressed ? 0.95 : 1.0
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            HoverHandler { id: previewAnimHover }

                            Text {
                                id: previewAnimText
                                anchors.centerIn: parent
                                text: "Preview on Stage"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: previewAnimHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: previewAnimMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.previewLockAnimation) {
                                        root.previewLockAnimation(root.animationStyle);
                                    }
                                }
                            }
                        }
                    }

                    // Full-Width 5-Preset Segmented Track
                    Rectangle {
                        id: animStyleSegmentTrack
                        Layout.fillWidth: true
                        height: 34
                        radius: 7
                        color: root.theme.bgBase
                        border.color: root.theme.bgBorder
                        border.width: 1

                        readonly property var modes: [
                            { label: "Default", value: "default" },
                            { label: "Staggered Cascade", value: "staggered" },
                            { label: "Cinema Curtain", value: "curtain" },
                            { label: "Zoom & Depth", value: "depth" },
                            { label: "Portal Iris", value: "portal" }
                        ]

                        readonly property int activeIdx: {
                            const st = root.animationStyle || "default";
                            if (st === "staggered") return 1;
                            if (st === "curtain") return 2;
                            if (st === "depth") return 3;
                            if (st === "portal") return 4;
                            return 0;
                        }

                        readonly property real cellWidth: (width - 6 - (modes.length - 1) * 3) / modes.length

                        Rectangle {
                            visible: animStyleSegmentTrack.activeIdx >= 0
                            y: 3
                            height: parent.height - 6
                            width: animStyleSegmentTrack.cellWidth
                            x: 3 + Math.max(0, animStyleSegmentTrack.activeIdx) * (animStyleSegmentTrack.cellWidth + 3)
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
                                model: animStyleSegmentTrack.modes

                                delegate: Rectangle {
                                    id: animSegBtn
                                    required property var modelData
                                    required property int index
                                    readonly property bool isSel: animStyleSegmentTrack.activeIdx === animSegBtn.index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isSel && animSegHover.hovered ? root.theme.bgHover : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: animSegHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: animSegBtn.modelData.label
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: animSegBtn.isSel
                                        color: animSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                        opacity: animSegBtn.isSel || animSegHover.hovered ? 1.0 : 0.75
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.animationStyle = animSegBtn.modelData.value;
                                            root.scheduleSave();
                                            if (root.previewLockAnimation) {
                                                root.previewLockAnimation(animSegBtn.modelData.value);
                                            }
                                            if (root.showStatus) {
                                                root.showStatus("Lock screen animation set to " + animSegBtn.modelData.label);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Show User Profile Toggle
            PreferenceRow {
                title: "Show User Profile"
                subtitle: "Display user avatar picture and account username above password field"

                SwitchToggle {
                    checked: root.showUser
                    onToggled: (st) => {
                        root.showUser = st;
                        root.scheduleSave();
                    }
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Show Media Player Toggle
            PreferenceRow {
                title: "Show Media Player"
                subtitle: "Display floating MPRIS media playback widget on lock screen"

                SwitchToggle {
                    checked: root.showMedia
                    onToggled: (st) => {
                        root.showMedia = st;
                        root.scheduleSave();
                    }
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Placeholder Text Input (Refined Libadwaita styling)
            PreferenceRow {
                title: "Placeholder Text"
                subtitle: "Text shown inside empty password field"

                Rectangle {
                    width: 240
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: placeholderInput.activeFocus ? root.theme.accentPrimary : (phHover.hovered ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4) : root.theme.bgBorder)
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    HoverHandler { id: phHover }

                    TextInput {
                        id: placeholderInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.inputPlaceholder
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textPrimary
                        selectByMouse: true
                        onEditingFinished: {
                            root.inputPlaceholder = text.trim();
                            root.scheduleSave();
                        }
                    }
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

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

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

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

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

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

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Input Box Horizontal Position (X)
            PreferenceSlider {
                title: "Center Offset X"
                subtitle: "Horizontal offset from screen center (0 = centered)"
                minVal: -960
                maxVal: 960
                unit: "px"
                currentVal: root.inputPosX
                onValueChanged: (val) => {
                    root.inputPosX = val;
                    root.scheduleSave();
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Input Box Vertical Position (Y)
            PreferenceSlider {
                title: "Center Offset Y"
                subtitle: "Vertical offset from screen center (0 = centered)"
                minVal: -540
                maxVal: 540
                unit: "px"
                currentVal: root.inputPosY
                onValueChanged: (val) => {
                    root.inputPosY = val;
                    root.scheduleSave();
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

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

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

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

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Password Input Outer Border Color
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Password Box Border Color (outer_color)"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Outline ring color of the password input box"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            elide: Text.ElideRight
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: authCol.resolveAuthColor(root.inputOuterColor)
                        border.color: Qt.rgba(1, 1, 1, 0.3)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    }

                    Rectangle {
                        width: 115
                        height: 30
                        radius: 6
                        color: root.theme.bgBase
                        border.color: outerColInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: outerColInput.activeFocus ? 2 : 1
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        TextInput {
                            id: outerColInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            text: root.inputOuterColor
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textPrimary
                            selectByMouse: true
                            onEditingFinished: {
                                if (text.trim().length > 0) {
                                    root.inputOuterColor = text.trim();
                                    root.scheduleSave();
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: outerSwTrack
                    Layout.fillWidth: true
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder
                    border.width: 1

                    readonly property var swatches: [
                        { name: "Accent", val: "$accent", color: root.theme.accentPrimary },
                        { name: "Blue / Cyan", val: "$blue", color: root.theme.accentCyan },
                        { name: "Green", val: "$green", color: root.theme.accentGreen },
                        { name: "Orange", val: "$peach", color: root.theme.accentOrange },
                        { name: "Red", val: "$red", color: root.theme.accentRed },
                        { name: "Text", val: "$text", color: root.theme.textPrimary },
                        { name: "Muted", val: "$color8", color: root.theme.textMuted }
                    ]
                    readonly property int count: swatches.length
                    readonly property int activeIdx: {
                        for (let i = 0; i < swatches.length; i++) {
                            if (swatches[i].val === root.inputOuterColor) return i;
                        }
                        return -1;
                    }
                    readonly property real cellWidth: (width - 6 - Math.max(0, count - 1) * 3) / Math.max(1, count)

                    Rectangle {
                        visible: outerSwTrack.activeIdx >= 0
                        y: 3
                        height: parent.height - 6
                        width: outerSwTrack.cellWidth
                        x: 3 + Math.max(0, outerSwTrack.activeIdx) * (outerSwTrack.cellWidth + 3)
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
                            model: outerSwTrack.swatches
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool isSel: outerSwTrack.activeIdx === index
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && oSwHover.hovered ? root.theme.bgHover : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }
                                HoverHandler { id: oSwHover }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Rectangle {
                                        width: 9; height: 9; radius: 4.5
                                        color: modelData.color
                                        border.color: Qt.rgba(0, 0, 0, 0.3); border.width: 1
                                    }
                                    Text {
                                        text: modelData.name
                                        font.family: root.font
                                        font.pixelSize: 10
                                        font.bold: isSel
                                        color: isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                        opacity: isSel || oSwHover.hovered ? 1.0 : 0.75
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.inputOuterColor = modelData.val;
                                        root.scheduleSave();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Password Input Inner Background & Font Color
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "Password Box Fill & Dots Color (inner_color / font_color)"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Inner pill background fill and password character dot color"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            elide: Text.ElideRight
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Fill:"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                    Rectangle {
                        width: 20; height: 20; radius: 10
                        color: authCol.resolveAuthColor(root.inputInnerColor)
                        border.color: Qt.rgba(1, 1, 1, 0.3); border.width: 1
                    }
                    Rectangle {
                        width: 95; height: 28; radius: 6
                        color: root.theme.bgBase
                        border.color: innerColInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: innerColInput.activeFocus ? 2 : 1
                        TextInput {
                            id: innerColInput
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            text: root.inputInnerColor
                            font.family: root.font; font.pixelSize: 11; font.bold: true
                            color: root.theme.textPrimary; selectByMouse: true
                            onEditingFinished: {
                                if (text.trim().length > 0) {
                                    root.inputInnerColor = text.trim();
                                    root.scheduleSave();
                                }
                            }
                        }
                    }

                    Text {
                        text: "Dots:"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                    Rectangle {
                        width: 20; height: 20; radius: 10
                        color: authCol.resolveAuthColor(root.inputFontColor)
                        border.color: Qt.rgba(1, 1, 1, 0.3); border.width: 1
                    }
                    Rectangle {
                        width: 95; height: 28; radius: 6
                        color: root.theme.bgBase
                        border.color: fontColInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: fontColInput.activeFocus ? 2 : 1
                        TextInput {
                            id: fontColInput
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            text: root.inputFontColor
                            font.family: root.font; font.pixelSize: 11; font.bold: true
                            color: root.theme.textPrimary; selectByMouse: true
                            onEditingFinished: {
                                if (text.trim().length > 0) {
                                    root.inputFontColor = text.trim();
                                    root.scheduleSave();
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: innerSwTrack
                    Layout.fillWidth: true
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder
                    border.width: 1

                    readonly property var swatches: [
                        { name: "Surface 0", val: "$surface0", color: root.theme.bgSurface },
                        { name: "Surface 1", val: "$surface1", color: root.theme.bgHover },
                        { name: "Surface 2", val: "$surface2", color: root.theme.bgSelected },
                        { name: "Base", val: "$base", color: root.theme.bgBase },
                        { name: "Color 0", val: "$color0", color: root.theme.bgSurface }
                    ]
                    readonly property int count: swatches.length
                    readonly property int activeIdx: {
                        for (let i = 0; i < swatches.length; i++) {
                            if (swatches[i].val === root.inputInnerColor) return i;
                        }
                        return -1;
                    }
                    readonly property real cellWidth: (width - 6 - Math.max(0, count - 1) * 3) / Math.max(1, count)

                    Rectangle {
                        visible: innerSwTrack.activeIdx >= 0
                        y: 3
                        height: parent.height - 6
                        width: innerSwTrack.cellWidth
                        x: 3 + Math.max(0, innerSwTrack.activeIdx) * (innerSwTrack.cellWidth + 3)
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
                            model: innerSwTrack.swatches
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool isSel: innerSwTrack.activeIdx === index
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && iSwHover.hovered ? root.theme.bgHover : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }
                                HoverHandler { id: iSwHover }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Rectangle {
                                        width: 9; height: 9; radius: 4.5
                                        color: modelData.color
                                        border.color: Qt.rgba(1, 1, 1, 0.25); border.width: 1
                                    }
                                    Text {
                                        text: modelData.name
                                        font.family: root.font
                                        font.pixelSize: 10
                                        font.bold: isSel
                                        color: isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                        opacity: isSel || iSwHover.hovered ? 1.0 : 0.75
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.inputInnerColor = modelData.val;
                                        if (root.inputFontColor === modelData.val) {
                                            root.inputFontColor = "$text";
                                        }
                                        root.scheduleSave();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
