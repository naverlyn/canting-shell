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

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Display Sync & Refresh"
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
                                font.pixelSize: Style.px(13)
                                font.bold: true
                                color: root.theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "Adaptive sync (G-Sync / FreeSync) for variable refresh rate displays"
                                font.family: root.font
                                font.pixelSize: Style.px(11)
                                color: root.theme.textSecondary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        Item { Layout.fillWidth: true }

                        AppDropdown {
                            theme: root.theme
                            font: root.font
                            Layout.preferredWidth: 380
                            implicitWidth: 380
                            menuWidth: 380
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
                    checked: root.miscMouseMoveDpms
                    onToggled: (val) => {
                        root.miscMouseMoveDpms = val;
                        root.setHyprVar("misc", "mouse_move_enables_dpms", val);
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Interaction & System Branding"
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
                SettingToggleRow {
                    announce: true
                    title: "Middle-Click Paste"
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
                    checked: root.miscDisableSplash
                    onToggled: (val) => {
                        root.miscDisableSplash = val;
                        root.setHyprVar("misc", "disable_splash_rendering", val);
                    }
                }
            }
        }
    }
}
