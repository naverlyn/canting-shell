import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 16

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Size, Scale & Spacing"
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
                    title: "Global Font Scale"
                    value: Math.round(root.theme.fontScale * 100)
                    minVal: 85
                    maxVal: 125
                    step: 5
                    unit: "%"
                    announce: true
                    presets: [
                        { label: "Small (90%)",   val: 90 },
                        { label: "Default (100%)", val: 100 },
                        { label: "Medium (105%)", val: 105 },
                        { label: "Large (110%)",  val: 110 },
                        { label: "Extra (120%)",  val: 120 }
                    ]
                    onValueModified: (val) => root.theme.setFontScale(val / 100.0)
                }

                RowDivider {}

                SettingSliderRow {
                    title: "Letter Spacing (Tracking)"
                    value: root.theme.letterSpacing
                    minVal: -0.5
                    maxVal: 2.0
                    step: 0.1
                    isFloat: true
                    unit: "px"
                    announce: true
                    presets: [
                        { label: "Tight (-0.2)",  val: -0.2 },
                        { label: "Normal (0.0)",  val: 0.0 },
                        { label: "Relaxed (0.4)", val: 0.4 },
                        { label: "Wide (0.8)",    val: 0.8 }
                    ]
                    onValueModified: (val) => root.theme.setLetterSpacing(val)
                }
            }
        }
    }

    // 7. Font Weight & Rendering Preferences
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Weight & Rendering Preferences"
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
                // Base Font Weight Dropdown Row
                PreferenceRow {
                    title: "Base Font Weight"

                    AppDropdown {
                        theme: root.theme
                        font: Style.font
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        menuWidth: 380
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        currentValue: root.theme.fontWeight
                        options: [
                            { desktop: "light",    name: "Light",    desc: "" },
                            { desktop: "normal",   name: "Normal",   desc: "" },
                            { desktop: "medium",   name: "Medium",   desc: "" },
                            { desktop: "demibold", name: "SemiBold", desc: "" },
                            { desktop: "bold",     name: "Bold",     desc: "" }
                        ]
                        onSelected: (val, opt) => {
                            root.theme.setFontWeight(val);
                            root.showToast("Base font weight: " + (opt ? opt.name : val));
                        }
                    }
                }

                RowDivider {}

                SettingToggleRow {
                    title: "Bold Section Headings & Titles"
                    checked: root.theme.boldHeadings
                    announce: true
                    onToggled: (val) => root.theme.setBoldHeadings(val)
                }

                RowDivider {}

                // Font Hinting Dropdown Row
                PreferenceRow {
                    title: "Glyph Hinting"

                    AppDropdown {
                        theme: root.theme
                        font: Style.font
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        menuWidth: 380
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        currentValue: root.theme.fontHinting
                        options: [
                            { desktop: "default",  name: "Default",  desc: "" },
                            { desktop: "none",     name: "None",     desc: "" },
                            { desktop: "vertical", name: "Vertical", desc: "" },
                            { desktop: "full",     name: "Full",     desc: "" }
                        ]
                        onSelected: (val, opt) => {
                            root.theme.setFontHinting(val);
                            root.showToast("Font hinting: " + (opt ? opt.name : val));
                        }
                    }
                }

                RowDivider {}

                SettingToggleRow {
                    title: "Smooth Font Antialiasing"
                    checked: root.theme.fontAntialiasing
                    announce: true
                    onToggled: (val) => root.theme.setFontAntialiasing(val)
                }

                RowDivider {}

                // Text Rendering Engine Dropdown Row
                PreferenceRow {
                    title: "Text Rasterizer Engine"

                    AppDropdown {
                        theme: root.theme
                        font: Style.font
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        menuWidth: 380
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        currentValue: root.theme.fontRenderType
                        options: [
                            { desktop: "qt",     name: "Qt Vector (Smooth)",      desc: "" },
                            { desktop: "native", name: "Native FreeType (Crisp)", desc: "" }
                        ]
                        onSelected: (val, opt) => {
                            root.theme.setFontRenderType(val);
                            root.showToast("Text rasterizer: " + (opt ? opt.name : val));
                        }
                    }
                }
            }
        }
    }
}
