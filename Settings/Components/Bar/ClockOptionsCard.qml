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
            text: "Clock Options"
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
                title: "Show Seconds in Clock"
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
                checked: BarConfig.showDate
                onToggled: (val) => {
                    BarConfig.showDate = val;
                    BarConfig.saveConfig();
                    root.showToast(val ? "Clock date visible" : "Clock date hidden");
                }
            }

            RowDivider {}

            SettingToggleRow {
                title: "Show Year in Clock"
                checked: BarConfig.showYear
                onToggled: (val) => {
                    BarConfig.showYear = val;
                    BarConfig.saveConfig();
                    root.showToast(val ? "Clock year visible" : "Clock year hidden");
                }
            }
        }
    }
}
