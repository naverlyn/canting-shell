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
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Window Corner Rounding"
        subtitle: "Corner radius applied to all managed application windows"

        SettingSliderRow {
            announce: true
            title: "Rounding Radius"
            desc: "Window corner rounding radius in pixels"
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

    /* Opacity & Dimming Card */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Window Opacity & Focus Dimming"
        subtitle: "Active vs inactive window transparency and focus contrast"

        SettingSliderRow {
            announce: true
            title: "Active Window Opacity"
            desc: "Opacity of the currently focused application window"
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
            desc: "Opacity of background, unfocused application windows"
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
            desc: "Slightly darken unfocused windows to bring attention to active window"
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
            desc: "Darkening intensity applied to unfocused windows"
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

    /* Background Blur Card */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Window Background Blur"
        subtitle: "Dual-kawase blur behind transparent windows and popups"

        SettingToggleRow {
            announce: true
            title: "Enable Window Blur"
            desc: "Render background blur behind transparent windows and shell layers"
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
            desc: "Radius of the blur kernel (blur spread)"
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
            desc: "Number of rendering passes (higher = smoother, more GPU usage)"
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
            desc: "Apply blur behind context menus, tooltips, and overlay popups"
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
            desc: "Floating windows blur only the desktop wallpaper instead of underlying windows"
            checked: root.decorBlurXray
            onToggled: (val) => {
                root.decorBlurXray = val;
                root.setHyprVar("decoration.blur", "xray", val);
            }
        }
    }

    /* Drop Shadows Card */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Window Drop Shadows"
        subtitle: "Compositor drop shadows around windows"

        SettingToggleRow {
            announce: true
            title: "Enable Window Shadows"
            desc: "Render drop shadows around application windows"
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
            desc: "Spread and size of the window shadow"
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
