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
                        text: "MPRIS Player Style"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "Auto switches to Compact when stacked with other modules in a panel, or Big when alone"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                AppDropdown {
                    theme: root.theme
                    font: root.font
                    width: 220
                    implicitWidth: 220
                    menuWidth: 220
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
            desc: "Automatically hide the media card when no MPRIS audio player is active"
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
            desc: "Display live audio spectrum visualizer inside the media player card"
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

    // Card 3: Visible Flyout Sections
    SectionCard {
        title: "Active Flyout Sections"
        subtitle: "Quickly toggle visibility for each modular Control Center section"
        contentMargins: 8
        contentSpacing: 0

        Repeater {
            model: ControlCenterConfig.allCardDefs
            delegate: ColumnLayout {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: 0

                RowDivider {
                    visible: index > 0
                }

                SettingToggleRow {
                    title: modelData.label
                    desc: modelData.desc
                    checked: ControlCenterConfig.isCardVisible(modelData.id)
                    onToggled: (val) => {
                        ControlCenterConfig.setCardVisible(modelData.id, val);
                        root.showToast((val ? "Enabled " : "Hidden ") + modelData.label);
                    }
                }
            }
        }
    }
}

