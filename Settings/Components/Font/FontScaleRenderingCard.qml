import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../Common"

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 16

    SectionCard {
        title: "Size, Scale & Spacing"
        subtitle: "Global typography proportions across Settings & Shell"
        contentMargins: 8
        contentSpacing: 4

        SettingSliderRow {
            title: "Global Font Scale"
            desc: "Proportional size multiplier applied to text across Quickshell (85% – 125%)"
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
            desc: "Adjust horizontal character spacing in pixels (-0.5px to +2.0px)"
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

    // ---------------------------------------------------------
    // 7. Font Weight & Rendering Preferences
    // ---------------------------------------------------------
    SectionCard {
        title: "Weight & Rendering Preferences"
        subtitle: "Control boldness, glyph hinting, and subpixel antialiasing"
        contentMargins: 8
        contentSpacing: 4

        // Base Font Weight Segmented Row
        PreferenceRow {
            title: "Base Font Weight"
            subtitle: "Default stroke weight for body text, descriptions, and controls"

            SegmentedControl {
                trackWidth: 360
                currentId: root.theme.fontWeight
                options: [
                    { id: "light",    label: "Light" },
                    { id: "normal",   label: "Normal" },
                    { id: "medium",   label: "Medium" },
                    { id: "demibold", label: "SemiBold" },
                    { id: "bold",     label: "Bold" }
                ]
                onOptionSelected: (optionId, optionLabel) => {
                    root.theme.setFontWeight(optionId);
                    root.showToast("Base font weight: " + optionLabel);
                }
            }
        }

        RowDivider {}

        SettingToggleRow {
            title: "Bold Section Headings & Titles"
            desc: "Emphasize page headers, card titles, and active navigation items with bold weight"
            checked: root.theme.boldHeadings
            announce: true
            onToggled: (val) => root.theme.setBoldHeadings(val)
        }

        RowDivider {}

        // Font Hinting Segmented Row
        PreferenceRow {
            title: "Glyph Hinting"
            subtitle: "Grid-fitting alignment for sharper text stems on standard and HiDPI displays"

            SegmentedControl {
                trackWidth: 300
                currentId: root.theme.fontHinting
                options: [
                    { id: "default",  label: "Default" },
                    { id: "none",     label: "None" },
                    { id: "vertical", label: "Vertical" },
                    { id: "full",     label: "Full" }
                ]
                onOptionSelected: (optionId, optionLabel) => {
                    root.theme.setFontHinting(optionId);
                    root.showToast("Font hinting: " + optionLabel);
                }
            }
        }

        RowDivider {}

        SettingToggleRow {
            title: "Smooth Font Antialiasing"
            desc: "Enable smooth edge antialiasing across shell text surfaces"
            checked: root.theme.fontAntialiasing
            announce: true
            onToggled: (val) => root.theme.setFontAntialiasing(val)
        }

        RowDivider {}

        // Text Rendering Engine Row
        PreferenceRow {
            title: "Text Rasterizer Engine"
            subtitle: "Choose between Qt distance-field vector curves or native platform FreeType rasterization"

            SegmentedControl {
                trackWidth: 330
                currentId: root.theme.fontRenderType
                options: [
                    { id: "qt",     label: "Qt Vector (Smooth)" },
                    { id: "native", label: "Native FreeType (Crisp)" }
                ]
                onOptionSelected: (optionId, optionLabel) => {
                    root.theme.setFontRenderType(optionId);
                    root.showToast("Text rasterizer: " + optionLabel);
                }
            }
        }
    }
}
