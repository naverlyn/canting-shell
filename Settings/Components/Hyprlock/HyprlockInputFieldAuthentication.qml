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

            function resolveAuthColor(colStr) {
                if (!colStr) return "#ffffff";
                let str = String(colStr).trim();
                if (str.startsWith("#")) return str;
                if (str.startsWith("rgb(") || str.startsWith("rgba(")) {
                    let m = str.match(/rgba?\(\s*([0-9a-fA-F]{6})\s*\)/);
                    if (m) return "#" + m[1];
                }
                const t = root.theme || {};
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

            // Placeholder Text Input (Refined Libadwaita styling)
            PreferenceRow {
                title: "Placeholder Text"
                subtitle: "Text shown inside empty password field"

                Rectangle {
                    width: 240
                    height: 32
                    radius: 7
                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                    border.color: placeholderInput.activeFocus ? (root.theme.accentPrimary ?? "#7aa2f7") : (phHover.hovered ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
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
                title: "Horizontal Position (X)"
                subtitle: "Horizontal offset of the password entry box"
                minVal: -800
                maxVal: 800
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
                title: "Vertical Position (Y)"
                subtitle: "Vertical offset of the password entry box"
                minVal: -500
                maxVal: 500
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
                            text: "Password Box Border Color (outer_color)"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                        Text {
                            text: "Outline ring color of the password input box"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
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
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    readonly property var swatches: [
                        { name: "Accent", val: "$accent", color: String(root.theme.accentPrimary ?? "#cba6f7") },
                        { name: "Blue / Cyan", val: "$blue", color: String(root.theme.accentCyan ?? "#89b4fa") },
                        { name: "Green", val: "$green", color: String(root.theme.accentGreen ?? "#a6e3a1") },
                        { name: "Orange", val: "$peach", color: String(root.theme.accentOrange ?? "#fab387") },
                        { name: "Red", val: "$red", color: String(root.theme.accentRed ?? "#f38ba8") },
                        { name: "Text", val: "$text", color: String(root.theme.textPrimary ?? "#cdd6f4") },
                        { name: "Muted", val: "$color8", color: String(root.theme.textMuted ?? "#a6adc8") }
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
                                color: !isSel && oSwHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
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
                            text: "Password Box Fill & Dots Color (inner_color / font_color)"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                        Text {
                            text: "Inner pill background fill and password character dot color"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
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
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    readonly property var swatches: [
                        { name: "Surface 0", val: "$surface0", color: String(root.theme.bgSurface ?? "#313244") },
                        { name: "Surface 1", val: "$surface1", color: String(root.theme.bgHover ?? "#45475a") },
                        { name: "Surface 2", val: "$surface2", color: String(root.theme.bgSelected ?? "#585b70") },
                        { name: "Base", val: "$base", color: String(root.theme.bgBase ?? "#1e1e2e") },
                        { name: "Color 0", val: "$color0", color: String(root.theme.bgSurface ?? "#404145") }
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
                                color: !isSel && iSwHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
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
