import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../notifications"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: "General Behavior & Queue Limits"
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
                title: "Do Not Disturb"
                checked: root.isDnd
                onToggled: (val) => {
                    NotificationService.doNotDisturb = val;
                    root.showToast(val ? "Do Not Disturb enabled" : "Do Not Disturb disabled");
                }
            }

            RowDivider {}

            SettingToggleRow {
                title: "Pause Timeout on Hover"
                checked: NotificationService.pauseOnHover
                onToggled: (val) => NotificationService.setPauseOnHover(val)
            }

            RowDivider {}

            SettingSliderRow {
                title: "Auto-Dismiss Timeout"
                value: NotificationService.defaultTimeout
                minVal: 2000
                maxVal: 15000
                step: 500
                unit: "ms"
                presets: [
                    { label: "3s", val: 3000 },
                    { label: "5s", val: 5000 },
                    { label: "8s", val: 8000 },
                    { label: "10s", val: 10000 }
                ]
                onValueModified: (val) => NotificationService.setDefaultTimeout(val)
            }

            RowDivider {}

            SettingSliderRow {
                title: "Max Visible Toasts"
                value: NotificationService.maxVisibleToasts
                minVal: 1
                maxVal: 10
                step: 1
                unit: ""
                presets: [
                    { label: "3", val: 3 },
                    { label: "5", val: 5 },
                    { label: "7", val: 7 },
                    { label: "10", val: 10 }
                ]
                onValueModified: (val) => NotificationService.setMaxVisibleToasts(val)
            }

            RowDivider {}

            SettingSliderRow {
                title: "Toast Card Width"
                value: NotificationService.toastWidth
                minVal: 280
                maxVal: 500
                step: 10
                unit: "px"
                presets: [
                    { label: "320px", val: 320 },
                    { label: "360px", val: 360 },
                    { label: "400px", val: 400 },
                    { label: "440px", val: 440 }
                ]
                onValueModified: (val) => NotificationService.setToastWidth(val)
            }

            RowDivider {}

            SettingSliderRow {
                title: "Stack Spacing"
                value: NotificationService.cardSpacing
                minVal: 4
                maxVal: 24
                step: 2
                unit: "px"
                presets: [
                    { label: "6px", val: 6 },
                    { label: "8px", val: 8 },
                    { label: "12px", val: 12 },
                    { label: "16px", val: 16 }
                ]
                onValueModified: (val) => NotificationService.setCardSpacing(val)
            }
        }
    }
}
