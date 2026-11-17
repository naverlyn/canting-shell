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
    title: "Battery Pill Options"
    contentMargins: 8
    contentSpacing: 0

    SettingToggleRow {
        title: "Show Battery Percentage"
        desc: "Display numerical charge percentage text alongside the battery status icon"
        checked: BarConfig.batteryShowPercentage !== false
        onToggled: (val) => {
            BarConfig.batteryShowPercentage = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Battery percentage visible" : "Battery percentage hidden");
        }
    }

    RowDivider {}

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
                    text: "Low Battery Alert Level"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Percentage at which battery icon turns red to warn about low charge"
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
                    { desktop: "15", name: "15%", desc: "" },
                    { desktop: "20", name: "20%", desc: "" },
                    { desktop: "25", name: "25%", desc: "" },
                    { desktop: "30", name: "30%", desc: "" }
                ]
                currentValue: String(Number(BarConfig.batteryLowThreshold !== undefined ? BarConfig.batteryLowThreshold : 20))
                onSelected: (val, opt) => {
                    BarConfig.batteryLowThreshold = Number(val);
                    BarConfig.saveConfig();
                    root.showToast("Battery warning threshold set to: " + (opt ? opt.name : val));
                }
            }
        }
    }
}
