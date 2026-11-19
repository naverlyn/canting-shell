import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 16

    SectionCard {
        title: "Size, Scale & Spacing"
        subtitle: "Global typography proportions across Settings & Shell"
        contentMargins: 8
        contentSpacing: 0

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

    // 7. Font Weight & Rendering Preferences
    SectionCard {
        title: "Weight & Rendering Preferences"
        subtitle: "Control boldness, glyph hinting, and subpixel antialiasing"
        contentMargins: 8
        contentSpacing: 0

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
