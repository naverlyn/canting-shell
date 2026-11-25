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
        checked: NotificationService.isBlockVisible("icon")
        onToggled: (val) => NotificationService.setBlockVisible("icon", val)
    }

    RowDivider {}

    // Icon Layout Mode (Auto / Inline Header / Left Avatar)
    Item {
        Layout.fillWidth: true
        height: 44

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Text {
                text: "Icon Placement Mode"
                font.family: root.font
                font.pixelSize: Style.px(13)
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
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
        checked: NotificationService.isBlockVisible("appName")
        onToggled: (val) => NotificationService.setBlockVisible("appName", val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "App Name Font Size"
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
        checked: NotificationService.isBlockVisible("timestamp")
        onToggled: (val) => NotificationService.setBlockVisible("timestamp", val)
    }

    RowDivider {}

    Item {
        Layout.fillWidth: true
        height: 44

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Text {
                text: "Timestamp Format"
                font.family: root.font
                font.pixelSize: Style.px(13)
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
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
        checked: NotificationService.isBlockVisible("closeBtn")
        onToggled: (val) => NotificationService.setBlockVisible("closeBtn", val)
    }
}

}
