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
    title: "Global Menu (AppMenu) Options"
    contentMargins: 8
    contentSpacing: 0

    SettingToggleRow {
        title: "Show Menu Glyph (󰍜)"
        desc: "Display application menu indicator icon before File, Edit, Help menus"
        checked: BarConfig.showGlobalMenuIcon
        onToggled: (val) => {
            BarConfig.showGlobalMenuIcon = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Global menu glyph enabled" : "Global menu glyph hidden");
        }
    }
}
