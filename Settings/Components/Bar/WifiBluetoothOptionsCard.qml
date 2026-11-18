import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: self
    title: "Wi-Fi & Bluetooth Pill Options"
    contentMargins: 8
    contentSpacing: 0

    SettingToggleRow {
        title: "Show Network SSID & Connected Device Labels"
        checked: Boolean(BarConfig.wifiBtShowLabels)
        onToggled: (val) => {
            BarConfig.wifiBtShowLabels = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Wi-Fi & Bluetooth text labels enabled" : "Compact icon-only mode enabled");
        }
    }
}
