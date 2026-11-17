import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: self
    title: "Cava Visualizer Options"
    contentMargins: 8
    contentSpacing: 0

    SettingToggleRow {
        title: "Enable Cava Visualizer"
        desc: "Allow audio spectrum streaming when Cava is placed on a bar"
        checked: BarConfig.showCava !== false
        onToggled: (val) => {
            BarConfig.showCava = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Cava visualizer enabled" : "Cava visualizer disabled");
        }
    }



    RowDivider {}

    SettingToggleRow {
        title: "Auto-Hide When Silent"
        desc: "Hide or minimize the spectrum pill when no audio is currently playing"
        checked: BarConfig.cavaAutoHide
        onToggled: (val) => {
            BarConfig.cavaAutoHide = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Auto-hide enabled" : "Auto-hide disabled");
        }
    }

    RowDivider {}

    // Visual Style Selector: Smooth Bars / Glyphs / Line Waves
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

                Text {
                    text: "Visualizer Display Style"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Choose between smooth rounded bars, centered waves, or terminal glyphs"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            AppDropdown {
                theme: root.theme
                font: root.font
                width: 200
                implicitWidth: 200
                menuWidth: 200
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                options: [
                    { desktop: "bars",   name: "Bars",   desc: "" },
                    { desktop: "line",   name: "Line",   desc: "" },
                    { desktop: "glyphs", name: "Glyphs", desc: "" }
                ]
                currentValue: BarConfig.cavaStyle || "bars"
                onSelected: (val, opt) => {
                    BarConfig.cavaStyle = val;
                    BarConfig.saveConfig();
                    root.showToast("Cava style set to: " + (opt ? opt.name : val));
                }
            }
        }
    }

    RowDivider {}

    // Cava Visualizer Mode Selector: Compact (Current) / Medium / Wide
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

                Text {
                    text: "Cava Visualizer Mode"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Choose visualizer size: Compact (current), Medium, or Wide"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            AppDropdown {
                theme: root.theme
                font: root.font
                width: 200
                implicitWidth: 200
                menuWidth: 200
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                options: [
                    { desktop: "compact", name: "Compact", desc: "" },
                    { desktop: "medium",  name: "Medium",  desc: "" },
                    { desktop: "wide",    name: "Wide",    desc: "" }
                ]
                currentValue: BarConfig.cavaMode || "compact"
                onSelected: (val, opt) => {
                    BarConfig.setCavaMode(val);
                    root.showToast("Cava mode set to: " + (opt ? opt.name : val));
                }
            }
        }
    }

    RowDivider {}

    // Refresh Framerate Selector: 20, 30, 60 FPS
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

                Text {
                    text: "Visualizer Framerate"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Update rate in frames per second (higher is smoother, lower uses less CPU)"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            AppDropdown {
                theme: root.theme
                font: root.font
                width: 200
                implicitWidth: 200
                menuWidth: 200
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                options: [
                    { desktop: "20", name: "20 FPS", desc: "" },
                    { desktop: "30", name: "30 FPS", desc: "" },
                    { desktop: "60", name: "60 FPS", desc: "" }
                ]
                currentValue: String(Number(BarConfig.cavaFramerate || 30))
                onSelected: (val, opt) => {
                    BarConfig.cavaFramerate = Number(val);
                    BarConfig.saveConfig();
                    root.showToast("Cava framerate set to: " + (opt ? opt.name : val));
                }
            }
        }
    }
}
