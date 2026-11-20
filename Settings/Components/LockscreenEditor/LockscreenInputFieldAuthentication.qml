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

                SwitchToggle {
                    checked: root.unlockAnimation
                    onToggled: (st) => {
                        root.unlockAnimation = st;
                        root.scheduleSave();
                    }
                }
            }

            // Lock Screen Animation Style Dropdown Row
            ColumnLayout {
                visible: root.unlockAnimation
                Layout.fillWidth: true
                spacing: 0

                RowDivider { sideMargin: 12; color: Qt.rgba(1, 1, 1, 0.05) }

                Item {
                    Layout.fillWidth: true
                    height: 44

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            text: "Lock Screen Animation Style"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 8
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                            AppDropdown {
                                theme: root.theme
                                font: root.font
                                Layout.preferredWidth: 276
                                implicitWidth: 276
                                menuWidth: 276
                                Layout.alignment: Qt.AlignVCenter
                                options: [
                                    { desktop: "default",   name: "Default",           desc: "" },
                                    { desktop: "staggered", name: "Staggered Cascade", desc: "" },
                                    { desktop: "curtain",   name: "Cinema Curtain",    desc: "" },
                                    { desktop: "depth",     name: "Zoom & Depth",      desc: "" },
                                    { desktop: "portal",    name: "Portal Iris",       desc: "" }
                                ]
                                currentValue: root.animationStyle || "default"
                                onSelected: (val, opt) => {
                                    root.animationStyle = val;
                                    root.scheduleSave();
                                    if (root.previewLockAnimation) {
                                        root.previewLockAnimation(val);
                                    }
                                    if (root.showStatus) {
                                        root.showStatus("Lock screen animation set to " + (opt ? opt.name : val));
                                    }
                                }
                            }

                            ActionButton {
                                iconText: "󰐊"
                                label: "Preview"
                                btnHeight: 32
                                onClicked: {
                                    if (root.previewLockAnimation) {
                                        root.previewLockAnimation(root.animationStyle);
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
            LockscreenColorDropdownRow {
                title: "Password Box Border Color"
                currentValue: root.inputOuterColor
                resolvedColor: authCol.resolveAuthColor(root.inputOuterColor)
                swatches: [
                    { name: "Accent", val: "$accent", color: Style.theme.accentPrimary },
                    { name: "Cyan",   val: "$blue",   color: Style.theme.accentCyan },
                    { name: "Green",  val: "$green",  color: Style.theme.accentGreen },
                    { name: "Orange", val: "$peach",  color: Style.theme.accentOrange },
                    { name: "Red",    val: "$red",    color: Style.theme.accentRed },
                    { name: "Text",   val: "$text",   color: Style.theme.textPrimary },
                    { name: "Muted",  val: "$color8", color: Style.theme.textMuted }
                ]
                onValueSelected: val => {
                    root.inputOuterColor = val;
                    root.scheduleSave();
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Password Input Inner Fill Color
            LockscreenColorDropdownRow {
                title: "Password Box Fill Color"
                currentValue: root.inputInnerColor
                resolvedColor: authCol.resolveAuthColor(root.inputInnerColor)
                swatches: [
                    { name: "Surface",  val: "$surface0", color: Style.theme.bgSurface },
                    { name: "Hover",    val: "$surface1", color: Style.theme.bgHover },
                    { name: "Selected", val: "$surface2", color: Style.theme.bgSelected },
                    { name: "Base",     val: "$base",     color: Style.theme.bgBase }
                ]
                onValueSelected: val => {
                    root.inputInnerColor = val;
                    if (root.inputFontColor === val) {
                        root.inputFontColor = "$text";
                    }
                    root.scheduleSave();
                }
            }

            RowDivider { sideMargin: 16; color: Qt.rgba(1, 1, 1, 0.05) }

            // Password Input Dots / Font Color
            LockscreenColorDropdownRow {
                title: "Password Dots Color"
                currentValue: root.inputFontColor
                resolvedColor: authCol.resolveAuthColor(root.inputFontColor)
                swatches: [
                    { name: "Text",      val: "$text",     color: Style.theme.textPrimary },
                    { name: "Secondary", val: "$subtext1", color: Style.theme.textSecondary },
                    { name: "Muted",     val: "$subtext0", color: Style.theme.textMuted },
                    { name: "Accent",    val: "$accent",   color: Style.theme.accentPrimary },
                    { name: "Cyan",      val: "$blue",     color: Style.theme.accentCyan },
                    { name: "Green",     val: "$green",    color: Style.theme.accentGreen },
                    { name: "Orange",    val: "$peach",    color: Style.theme.accentOrange },
                    { name: "Red",       val: "$red",      color: Style.theme.accentRed }
                ]
                onValueSelected: val => {
                    root.inputFontColor = val;
                    root.scheduleSave();
                }
            }
        }
    }
}
