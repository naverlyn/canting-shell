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
    title: "Hardware Monitor Options (CPU / GPU / RAM / Temp / Disk)"
    contentMargins: 8
    contentSpacing: 0

    SettingToggleRow {
        title: "Show Sensor Glyphs"
        checked: BarConfig.hwShowIcons !== false
        onToggled: (val) => {
            BarConfig.hwShowIcons = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Sensor glyphs visible" : "Sensor glyphs hidden");
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Show GPU Temperature on GPU Pill"
        checked: Boolean(BarConfig.gpuShowTemp)
        onToggled: (val) => {
            BarConfig.gpuShowTemp = val;
            BarConfig.saveConfig();
            root.showToast(val ? "GPU temperature visible on pill" : "GPU temperature hidden on pill");
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "High Load Warning Alerts"
        checked: BarConfig.hwAlertEnabled !== false
        onToggled: (val) => {
            BarConfig.hwAlertEnabled = val;
            BarConfig.saveConfig();
            root.showToast(val ? "High load alerts enabled" : "High load alerts disabled");
        }
    }

    RowDivider {}

    Item {
        Layout.fillWidth: true
        height: 40

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Critical Alert Threshold"
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
                width: 200
                implicitWidth: 200
                menuWidth: 200
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                options: [
                    { desktop: "75", name: "75%", desc: "" },
                    { desktop: "80", name: "80%", desc: "" },
                    { desktop: "85", name: "85%", desc: "" },
                    { desktop: "90", name: "90%", desc: "" }
                ]
                currentValue: String(Number(BarConfig.hwAlertThreshold !== undefined ? BarConfig.hwAlertThreshold : 85))
                onSelected: (val, opt) => {
                    BarConfig.hwAlertThreshold = Number(val);
                    BarConfig.saveConfig();
                    root.showToast("Hardware alert threshold set to: " + (opt ? opt.name : val));
                }
            }
        }
    }

    RowDivider {}

    Item {
        Layout.fillWidth: true
        height: 40

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Hardware Polling Frequency"
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
                width: 200
                implicitWidth: 200
                menuWidth: 200
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                options: [
                    { desktop: "1", name: "1s (Fast)", desc: "" },
                    { desktop: "2", name: "2s (Norm)", desc: "" },
                    { desktop: "5", name: "5s (Eco)",  desc: "" }
                ]
                currentValue: String(Number(BarConfig.hwPollInterval || 2))
                onSelected: (val, opt) => {
                    BarConfig.hwPollInterval = Number(val);
                    BarConfig.saveConfig();
                    root.showToast("Hardware polling interval set to: " + (opt ? opt.name : val));
                }
            }
        }
    }
}
