import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../notifications"
import "../.."
import "../Common"
import ".."


ColumnLayout {
    id: groupRoot
    required property var root
    required property string activeTabId
    Layout.fillWidth: true
    spacing: 0

// 1. APP ICON BUILDING BLOCK OPTIONS
ColumnLayout {
    visible: groupRoot.activeTabId === "icon"
    Layout.fillWidth: true
    spacing: 0

    SettingToggleRow {
        title: "Show App Icon Block"
        desc: "Display application icon badge or glyph on notification cards"
        checked: NotificationService.isBlockVisible("icon")
        onToggled: (val) => NotificationService.setBlockVisible("icon", val)
    }

    RowDivider {}

    // Icon Layout Mode (Auto / Inline Header / Left Avatar)
    Item {
        Layout.fillWidth: true
        height: 52

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text {
                    text: "Icon Placement Mode"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
                Text {
                    text: "Render compact in Header row or as a prominent Left Avatar column"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            SegmentedControl {
                trackWidth: 260
                currentId: NotificationService.iconMode
                options: [
                    { id: "auto",   label: "Auto (Zone)" },
                    { id: "inline", label: "Header" },
                    { id: "avatar", label: "Avatar Left" }
                ]
                onOptionSelected: (optionId) => NotificationService.setIconMode(optionId)
            }
        }
    }

    RowDivider {}

    SettingSliderRow {
        title: "Icon Badge Size"
        desc: "Outer dimensions of the app icon container in pixels"
        value: NotificationService.iconSize
        minVal: 16
        maxVal: 48
        step: 2
        unit: "px"
        presets: [
            { label: "20px", val: 20 },
            { label: "24px", val: 24 },
            { label: "32px", val: 32 },
            { label: "40px", val: 40 }
        ]
        onValueModified: (val) => NotificationService.setIconSize(val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Icon Corner Radius"
        desc: "Rounding of the icon badge background (0 = square, 20 = circle)"
        value: NotificationService.iconRadius
        minVal: 0
        maxVal: 24
        step: 1
        unit: "px"
        presets: [
            { label: "Square (4px)", val: 4 },
            { label: "Rounded (8px)", val: 8 },
            { label: "Squircle (12px)", val: 12 },
            { label: "Circle (20px)", val: 20 }
        ]
        onValueModified: (val) => NotificationService.setIconRadius(val)
    }

    RowDivider {}

    SettingToggleRow {
        title: "Tinted Icon Badge Background"
        desc: "Show a subtle urgency/accent-tinted container behind the icon"
        checked: NotificationService.iconShowBg
        onToggled: (val) => NotificationService.setIconShowBg(val)
    }
}

// 2. HEADER, APP NAME, TIMESTAMP & CLOSE BUTTON OPTIONS
ColumnLayout {
    visible: groupRoot.activeTabId === "appName"
    Layout.fillWidth: true
    spacing: 0

    SettingToggleRow {
        title: "Show App Name Block"
        desc: "Display source application name (e.g. notify-send, Spotify)"
        checked: NotificationService.isBlockVisible("appName")
        onToggled: (val) => NotificationService.setBlockVisible("appName", val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "App Name Font Size"
        desc: "Typography size for application title and header metadata"
        value: NotificationService.appNameFontSize
        minVal: 9
        maxVal: 16
        step: 1
        unit: "px"
        presets: [
            { label: "10px", val: 10 },
            { label: "11px", val: 11 },
            { label: "12px", val: 12 },
            { label: "14px", val: 14 }
        ]
        onValueModified: (val) => NotificationService.setAppNameFontSize(val)
    }

    RowDivider {}

    SettingToggleRow {
        title: "Show Timestamp Block"
        desc: "Display notification arrival time in the header row"
        checked: NotificationService.isBlockVisible("timestamp")
        onToggled: (val) => NotificationService.setBlockVisible("timestamp", val)
    }

    RowDivider {}

    Item {
        Layout.fillWidth: true
        height: 52

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text {
                    text: "Timestamp Format"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
                Text {
                    text: "Choose between relative label ('Now') or 24-hour clock ('HH:mm')"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            SegmentedControl {
                trackWidth: 220
                currentId: NotificationService.timestampFormat
                options: [
                    { id: "relative", label: "Relative (Now)" },
                    { id: "time",     label: "Clock (HH:mm)" }
                ]
                onOptionSelected: (optionId) => NotificationService.setTimestampFormat(optionId)
            }
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Show Dismiss (✕) Button Block"
        desc: "Display quick close button on the notification card"
        checked: NotificationService.isBlockVisible("closeBtn")
        onToggled: (val) => NotificationService.setBlockVisible("closeBtn", val)
    }
}

}
