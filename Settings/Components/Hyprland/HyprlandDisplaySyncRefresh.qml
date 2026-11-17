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
    visible: root.currentSubTab === 4
    Layout.fillWidth: true
    spacing: 16

    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Display Sync & Refresh"
        subtitle: "Adaptive sync (VRR) and variable frame rate performance"

        Item {
            Layout.fillWidth: true
            height: 52

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true

                    Text {
                        text: "Variable Refresh Rate (VRR)"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "Adaptive sync (G-Sync / FreeSync) for variable refresh rate displays"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Item { Layout.fillWidth: true }

                AppDropdown {
                    theme: root.theme
                    font: root.font
                    width: 220
                    implicitWidth: 220
                    menuWidth: 220
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    options: [
                        { desktop: "0", name: "Off",        desc: "" },
                        { desktop: "1", name: "Always On",  desc: "" },
                        { desktop: "2", name: "Fullscreen", desc: "" }
                    ]
                    currentValue: String(root.miscVrr)
                    onSelected: (val, opt) => {
                        root.miscVrr = Number(val);
                        root.setHyprVar("misc", "vrr", Number(val));
                        root.showToast("VRR set to " + (opt ? opt.name : val));
                    }
                }
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingToggleRow {
            announce: true
            title: "Variable Frame Rate (VFR)"
            desc: "Drop rendering rate when screen is static to significantly reduce GPU and battery usage"
            checked: root.miscVfr
            onToggled: (val) => {
                root.miscVfr = val;
                root.setHyprVar("misc", "vfr", val);
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingToggleRow {
            announce: true
            title: "Mouse Movement Wakes Monitors"
            desc: "Wake screens from DPMS / display standby sleep when mouse moves"
            checked: root.miscMouseMoveDpms
            onToggled: (val) => {
                root.miscMouseMoveDpms = val;
                root.setHyprVar("misc", "mouse_move_enables_dpms", val);
            }
        }
    }

    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Interaction & System Branding"
        subtitle: "Clipboard behavior and compositor boot elements"

        SettingToggleRow {
            announce: true
            title: "Middle-Click Paste"
            desc: "Paste primary selection buffer when clicking middle mouse button"
            checked: root.miscMiddleClickPaste
            onToggled: (val) => {
                root.miscMiddleClickPaste = val;
                root.setHyprVar("misc", "middle_click_paste", val);
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingToggleRow {
            announce: true
            title: "Hide Hyprland Boot Logo"
            desc: "Suppress default Hyprland anime mascot logo on compositor startup"
            checked: root.miscDisableLogo
            onToggled: (val) => {
                root.miscDisableLogo = val;
                root.setHyprVar("misc", "disable_hyprland_logo", val);
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingToggleRow {
            announce: true
            title: "Hide Splash Rendering"
            desc: "Disable random witty splash text rendering on startup screen"
            checked: root.miscDisableSplash
            onToggled: (val) => {
                root.miscDisableSplash = val;
                root.setHyprVar("misc", "disable_splash_rendering", val);
            }
        }
    }
}
