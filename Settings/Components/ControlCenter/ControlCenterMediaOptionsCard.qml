import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../../../bar"
import "../../../ControlCenter"
import "../.."
import "../Common"
import ".."
import "../../../utils/AppFrecencyUtils.js" as AppFrecencyUtils

ColumnLayout {
    required property var root
    id: optionsCol
    Layout.fillWidth: true
    spacing: 20

    // Card 1: Media Player & Visualizer Options
    SectionCard {
        title: "Media Player & Visualizer Options"
        subtitle: "Configure MPRIS playback card style, auto-hide behavior, and Cava spectrum"
        contentMargins: 8
        contentSpacing: 0

        // Row 1: MPRIS Player Style (Compact vs Full Banner)
        Item {
            Layout.fillWidth: true
            height: 44

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "MPRIS Player Style"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
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
                        { desktop: "auto",    name: "Auto",       desc: "" },
                        { desktop: "compact", name: "Compact",    desc: "" },
                        { desktop: "full",    name: "Big Banner", desc: "" }
                    ]
                    currentValue: ControlCenterConfig.mediaWidgetStyle || "auto"
                    onSelected: (val, opt) => {
                        ControlCenterConfig.setMediaWidgetStyle(val);
                        root.showToast("MPRIS style set to " + (opt ? opt.name : val));
                    }
                }
            }
        }

        RowDivider {}

        // Row 2: Auto-Hide Media Player
        SettingToggleRow {
            title: "Auto-Hide Media Player"
            checked: ControlCenterConfig.mediaAutoHide
            onToggled: (val) => {
                ControlCenterConfig.setCardVisible("mediaAutoHide", val);
                root.showToast(val ? "Media auto-hide enabled" : "Media auto-hide disabled");
            }
        }

        RowDivider {}

        // Row 3: Show Cava Equalizer in Media Player
        SettingToggleRow {
            title: "Show Cava Equalizer in Media Player"
            checked: ControlCenterConfig.mediaShowCava
            onToggled: (val) => {
                ControlCenterConfig.setMediaShowCava(val);
                root.showToast(val ? "Media Cava equalizer enabled" : "Media Cava equalizer disabled");
            }
        }
    }

    // Card 2: Polished Quick Launch & App Grid Configuration
    // Card 2: Polished Quick Launch & App Grid Configuration
    ControlCenterQuickLaunchCard {
        root: optionsCol.root
    }
}

