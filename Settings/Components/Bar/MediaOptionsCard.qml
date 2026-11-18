import QtQuick
import "../../../bar"
import "../Common"

SectionCard {
    required property var root
    id: self
    title: "Media Player Options"
    contentMargins: 8
    contentSpacing: 0

    PreferenceRow {
        title: "Popup Layout Style"

        SegmentedControl {
            trackWidth: 200
            options: [
                { id: "full",    label: "Full" },
                { id: "compact", label: "Compact" }
            ]
            currentId: BarConfig.mediaPopupStyle
            onOptionSelected: (optionId, optionLabel) => {
                BarConfig.mediaPopupStyle = optionId;
                BarConfig.saveConfig();
                self.root.showToast("Bar media popup: " + optionLabel);
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
