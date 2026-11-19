import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    visible: root.currentSubTab === 1
    Layout.fillWidth: true
    spacing: 16

    /* Corner Rounding Card */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Window Corner Rounding"
                font.family: Style.font
                font.pixelSize: Style.px(13)
                font.bold: Style.boldHeadings
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textSecondary
                Layout.minimumWidth: implicitWidth
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: innerCol1.implicitHeight + 8 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol1
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0
                SettingSliderRow {
                    announce: true
                    title: "Rounding Radius"
                    value: root.decorRounding
                    minVal: 0
                    maxVal: 24
                    unit: "px"
                    presets: [
                        { label: "0px", val: 0 },
                        { label: "6px", val: 6 },
                        { label: "10px", val: 10 },
                        { label: "16px", val: 16 }
                    ]
                    onValueModified: (v) => {
                        root.decorRounding = v;
                        root.setHyprVar("decoration", "rounding", v);
                    }
                }
            }
        }
    }

    /* Opacity & Dimming Card */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Window Opacity & Focus Dimming"
                font.family: Style.font
                font.pixelSize: Style.px(13)
                font.bold: Style.boldHeadings
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textSecondary
                Layout.minimumWidth: implicitWidth
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: innerCol2.implicitHeight + 8 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol2
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0
                SettingSliderRow {
                    announce: true
                    title: "Active Window Opacity"
                    value: root.decorActiveOpacity
                    minVal: 0.50
                    maxVal: 1.00
                    isFloat: true
                    presets: [
                        { label: "85%", val: 0.85 },
                        { label: "90%", val: 0.90 },
                        { label: "95%", val: 0.95 },
                        { label: "100%", val: 1.00 }
                    ]
                    onValueModified: (v) => {
                        root.decorActiveOpacity = v;
                        root.setHyprVar("decoration", "active_opacity", v);
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0 }

                SettingSliderRow {
                    announce: true
                    title: "Inactive Window Opacity"
                    value: root.decorInactiveOpacity
                    minVal: 0.50
                    maxVal: 1.00
                    isFloat: true
                    presets: [
                        { label: "75%", val: 0.75 },
                        { label: "80%", val: 0.80 },
                        { label: "90%", val: 0.90 },
                        { label: "100%", val: 1.00 }
                    ]
                    onValueModified: (v) => {
                        root.decorInactiveOpacity = v;
                        root.setHyprVar("decoration", "inactive_opacity", v);
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0 }

                SettingToggleRow {
                    announce: true
                    title: "Dim Inactive Windows"
                    checked: root.decorDimInactive
                    onToggled: (val) => {
                        root.decorDimInactive = val;
                        root.setHyprVar("decoration", "dim_inactive", val);
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0; visible: root.decorDimInactive }

                SettingSliderRow {
                    announce: true
                    visible: root.decorDimInactive
                    title: "Dim Strength"
                    value: root.decorDimStrength
                    minVal: 0.05
                    maxVal: 0.60
                    isFloat: true
                    presets: [
                        { label: "10%", val: 0.10 },
                        { label: "20%", val: 0.20 },
                        { label: "35%", val: 0.35 }
                    ]
                    onValueModified: (v) => {
                        root.decorDimStrength = v;
                        root.setHyprVar("decoration", "dim_strength", v);
                    }
                }
            }
        }
    }

    /* Background Blur Card */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Window Background Blur"
                font.family: Style.font
                font.pixelSize: Style.px(13)
                font.bold: Style.boldHeadings
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textSecondary
                Layout.minimumWidth: implicitWidth
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: innerCol3.implicitHeight + 8 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol3
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0
                SettingToggleRow {
                    announce: true
                    title: "Enable Window Blur"
                    checked: root.decorBlurEnabled
                    onToggled: (val) => {
                        root.decorBlurEnabled = val;
                        root.setHyprVar("decoration.blur", "enabled", val);
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0; visible: root.decorBlurEnabled }

                SettingSliderRow {
                    announce: true
                    visible: root.decorBlurEnabled
                    title: "Blur Size"
                    value: root.decorBlurSize
                    minVal: 1
                    maxVal: 12
                    unit: "px"
                    presets: [
                        { label: "3px", val: 3 },
                        { label: "6px", val: 6 },
                        { label: "9px", val: 9 }
                    ]
                    onValueModified: (v) => {
                        root.decorBlurSize = v;
                        root.setHyprVar("decoration.blur", "size", v);
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0; visible: root.decorBlurEnabled }

                SettingSliderRow {
                    announce: true
                    visible: root.decorBlurEnabled
                    title: "Blur Passes"
                    value: root.decorBlurPasses
                    minVal: 1
                    maxVal: 5
                    unit: ""
                    presets: [
                        { label: "2", val: 2 },
                        { label: "3", val: 3 },
                        { label: "4", val: 4 }
                    ]
                    onValueModified: (v) => {
                        root.decorBlurPasses = v;
                        root.setHyprVar("decoration.blur", "passes", v);
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0; visible: root.decorBlurEnabled }

                SettingToggleRow {
                    announce: true
                    visible: root.decorBlurEnabled
                    title: "Blur Popups & Menus"
                    checked: root.decorBlurPopups
                    onToggled: (val) => {
                        root.decorBlurPopups = val;
                        root.setHyprVar("decoration.blur", "popups", val);
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0; visible: root.decorBlurEnabled }

                SettingToggleRow {
                    announce: true
                    visible: root.decorBlurEnabled
                    title: "X-Ray Mode"
                    checked: root.decorBlurXray
                    onToggled: (val) => {
                        root.decorBlurXray = val;
                        root.setHyprVar("decoration.blur", "xray", val);
                    }
                }
            }
        }
    }

    /* Drop Shadows Card */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Window Drop Shadows"
                font.family: Style.font
                font.pixelSize: Style.px(13)
                font.bold: Style.boldHeadings
                font.letterSpacing: Style.letterSpacing
                font.hintingPreference: Style.fontHintingEnum
                antialiasing: Style.fontAntialiasing
                renderType: Style.fontRenderTypeEnum
                color: Style.theme.textSecondary
                Layout.minimumWidth: implicitWidth
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: innerCol4.implicitHeight + 8 * 2
            radius: 12
            color: Style.theme.bgSurface
            border.color: Style.theme.bgBorder
            border.width: 1

            ColumnLayout {
                id: innerCol4
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0
                SettingToggleRow {
                    announce: true
                    title: "Enable Window Shadows"
                    checked: root.decorShadowEnabled
                    onToggled: (val) => {
                        root.decorShadowEnabled = val;
                        root.setHyprVar("decoration.shadow", "enabled", val);
                    }
                }

                RowDivider { sideMargin: 0; alpha: 1.0; visible: root.decorShadowEnabled }

                SettingSliderRow {
                    announce: true
                    visible: root.decorShadowEnabled
                    title: "Shadow Range"
                    value: root.decorShadowRange
                    minVal: 1
                    maxVal: 20
                    unit: "px"
                    presets: [
                        { label: "3px", val: 3 },
                        { label: "6px", val: 6 },
                        { label: "12px", val: 12 }
                    ]
                    onValueModified: (v) => {
                        root.decorShadowRange = v;
                        root.setHyprVar("decoration.shadow", "range", v);
                    }
                }
            }
        }
    }
}
