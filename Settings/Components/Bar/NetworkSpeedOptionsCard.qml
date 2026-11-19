import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
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
            text: "Network Speed Options"
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
    }
}
