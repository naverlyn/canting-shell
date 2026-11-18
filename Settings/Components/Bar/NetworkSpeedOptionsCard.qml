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
    title: "Network Speed Options"
    contentMargins: 8
    contentSpacing: 0

    SettingToggleRow {
        title: "Show Download Speed (󰇚)"
        checked: BarConfig.showNetDown
        onToggled: (val) => {
            if (!val && !BarConfig.showNetUp) BarConfig.showNetUp = true;
            BarConfig.showNetDown = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Download speed visible" : "Download speed hidden");
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Show Upload Speed (󰕒)"
        checked: BarConfig.showNetUp
        onToggled: (val) => {
            if (!val && !BarConfig.showNetDown) BarConfig.showNetDown = true;
            BarConfig.showNetUp = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Upload speed visible" : "Upload speed hidden");
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Compact Speed Format"
        checked: BarConfig.netCompact
        onToggled: (val) => {
            BarConfig.netCompact = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Compact speed format enabled" : "Standard speed format enabled");
        }
    }
}
