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
    title: "Clock Options"
    contentMargins: 8
    contentSpacing: 0

    SettingToggleRow {
        title: "Show Seconds in Clock"
        desc: "Display precision seconds format (hh:mm:ss)"
        checked: BarConfig.showSeconds
        onToggled: (val) => {
            BarConfig.showSeconds = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Clock seconds visible" : "Clock seconds hidden");
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Show Date in Clock"
        desc: "Display weekday and calendar date alongside the time"
        checked: BarConfig.showDate
        onToggled: (val) => {
            BarConfig.showDate = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Clock date visible" : "Clock date hidden");
        }
    }
}
