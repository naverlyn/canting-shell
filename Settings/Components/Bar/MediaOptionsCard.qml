import QtQuick
import QtQuick.Layouts
import "../../../bar"
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: self
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: "Media Player Options"
            font.family: Style.font
            font.pixelSize: Style.px(13)
            font.bold: Style.boldHeadings
            font.letterSpacing: Style.letterSpacing
            font.hintingPreference: Style.fontHintingEnum
            antialiasing: Style.fontAntialiasing
            renderType: Style.fontRenderTypeEnum
            color: Style.theme.textSecondary
            Layout.minimumWidth: implicitWidth
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }
        Item { Layout.fillWidth: true }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: innerCol.implicitHeight + 8 * 2
        radius: 12
        color: Style.theme.bgSurface
        border.color: Style.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: innerCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0
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
    }
}
