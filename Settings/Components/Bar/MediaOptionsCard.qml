import QtQuick
import QtQuick.Layouts
import "../../../bar"
import "../Common"
import ".."

SectionCard {
    required property var root
    id: self
    title: "Media Player Options"
    contentMargins: 8
    contentSpacing: 0

    PreferenceRow {
        title: "Popup Layout Style"

        AppDropdown {
            theme: self.root.theme
            font: self.root.font
            Layout.preferredWidth: 380
            implicitWidth: 380
            menuWidth: 380
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            options: [
                { desktop: "full",    name: "Full",    desc: "" },
                { desktop: "compact", name: "Compact", desc: "" }
            ]
            currentValue: BarConfig.mediaPopupStyle
            onSelected: (val, opt) => {
                BarConfig.mediaPopupStyle = val;
                BarConfig.saveConfig();
                self.root.showToast("Bar media popup: " + (opt ? opt.name : val));
            }
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Show Album Art"
        checked: BarConfig.mediaShowAlbumArt
        onToggled: (val) => {
            BarConfig.mediaShowAlbumArt = val;
            BarConfig.saveConfig();
            self.root.showToast(val ? "Media album art visible" : "Media album art hidden");
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Show Seekbar"
        checked: BarConfig.mediaShowSeekbar
        onToggled: (val) => {
            BarConfig.mediaShowSeekbar = val;
            BarConfig.saveConfig();
            self.root.showToast(val ? "Media seekbar visible" : "Media seekbar hidden");
        }
    }
}
