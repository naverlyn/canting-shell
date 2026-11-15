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

// 6. ACTION BUTTONS BUILDING BLOCK OPTIONS
ColumnLayout {
    visible: groupRoot.activeTabId === "buttons"
    Layout.fillWidth: true
    spacing: 0

    SettingToggleRow {
        title: "Show Action Buttons Block"
        desc: "Display interactive action buttons (e.g. Open, Delete, Reply)"
        checked: NotificationService.isBlockVisible("buttons")
        onToggled: (val) => NotificationService.setBlockVisible("buttons", val)
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
                    text: "Button Visual Style"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
                Text {
                    text: "Choose between compact pills, equal full-width buttons, or minimal ghost buttons"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            SegmentedControl {
                trackWidth: 270
                currentId: NotificationService.buttonStyle
                options: [
                    { id: "pill",  label: "Rounded Pill" },
                    { id: "fill",  label: "Full Width" },
                    { id: "ghost", label: "Ghost" }
                ]
                onOptionSelected: (optionId) => NotificationService.setButtonStyle(optionId)
            }
        }
    }

    RowDivider {}

    SettingSliderRow {
        title: "Button Height"
        desc: "Vertical height of each notification action button"
        value: NotificationService.buttonHeight
        minVal: 22
        maxVal: 40
        step: 2
        unit: "px"
        presets: [
            { label: "24px", val: 24 },
            { label: "28px", val: 28 },
            { label: "32px", val: 32 },
            { label: "36px", val: 36 }
        ]
        onValueModified: (val) => NotificationService.setButtonHeight(val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Button Corner Radius"
        desc: "Rounding of action buttons (14px = capsule pill)"
        value: NotificationService.buttonRadius
        minVal: 0
        maxVal: 20
        step: 1
        unit: "px"
        presets: [
            { label: "6px", val: 6 },
            { label: "10px", val: 10 },
            { label: "14px", val: 14 },
            { label: "18px", val: 18 }
        ]
        onValueModified: (val) => NotificationService.setButtonRadius(val)
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
                    text: "Button Row Alignment"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
                Text {
                    text: "Horizontal alignment of compact pill and ghost buttons"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            SegmentedControl {
                trackWidth: 260
                currentId: NotificationService.buttonAlignment
                options: [
                    { id: "left",    label: "Left" },
                    { id: "center",  label: "Center" },
                    { id: "right",   label: "Right" },
                    { id: "stretch", label: "Stretch" }
                ]
                onOptionSelected: (optionId) => NotificationService.setButtonAlignment(optionId)
            }
        }
    }
}

// 7. TIMEOUT PROGRESS BAR BUILDING BLOCK OPTIONS
ColumnLayout {
    visible: groupRoot.activeTabId === "progressBar"
    Layout.fillWidth: true
    spacing: 0

    SettingToggleRow {
        title: "Show Timeout Progress Bar Block"
        desc: "Display animated auto-dismiss countdown bar on notification toasts"
        checked: NotificationService.isBlockVisible("progressBar")
        onToggled: (val) => NotificationService.setBlockVisible("progressBar", val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Auto-Dismiss Duration"
        desc: "Default time before notification toasts automatically dismiss"
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
        title: "Progress Bar Thickness"
        desc: "Height of the countdown progress track in pixels"
        value: NotificationService.progressHeight
        minVal: 2
        maxVal: 8
        step: 1
        unit: "px"
        presets: [
            { label: "2px", val: 2 },
            { label: "3px", val: 3 },
            { label: "4px", val: 4 },
            { label: "6px", val: 6 }
        ]
        onValueModified: (val) => NotificationService.setProgressHeight(val)
    }

    RowDivider {}

    SettingToggleRow {
        title: "Pause Countdown on Hover"
        desc: "Freeze auto-dismiss timer while mouse cursor hovers over the toast"
        checked: NotificationService.pauseOnHover
        onToggled: (val) => NotificationService.setPauseOnHover(val)
    }

    RowDivider {}

    SettingToggleRow {
        title: "Auto-Dismiss Critical Notifications"
        desc: "Show countdown bar and auto-dismiss Critical urgency alerts"
        checked: NotificationService.progressShowCritical
        onToggled: (val) => NotificationService.setProgressShowCritical(val)
    }
}

// 8. CARD CHROME & ACCENT STRIP OPTIONS
ColumnLayout {
    visible: groupRoot.activeTabId === "card"
    Layout.fillWidth: true
    spacing: 0

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
                    text: "Urgency Accent Strip"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
                Text {
                    text: "Position of the colored urgency indicator strip along the card edge"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            SegmentedControl {
                trackWidth: 260
                currentId: NotificationService.showAccentStrip ? NotificationService.accentStripPosition : "none"
                options: [
                    { id: "left",  label: "Left" },
                    { id: "right", label: "Right" },
                    { id: "top",   label: "Top" },
                    { id: "none",  label: "Hidden" }
                ]
                onOptionSelected: (optionId) => NotificationService.setAccentStripPosition(optionId)
            }
        }
    }

    RowDivider {}

    SettingSliderRow {
        title: "Accent Strip Thickness"
        desc: "Width of the urgency indicator bar in pixels"
        value: NotificationService.accentStripWidth
        minVal: 2
        maxVal: 8
        step: 1
        unit: "px"
        presets: [
            { label: "2px", val: 2 },
            { label: "3px", val: 3 },
            { label: "4px", val: 4 },
            { label: "6px", val: 6 }
        ]
        onValueModified: (val) => NotificationService.setAccentStripWidth(val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Toast Card Width"
        desc: "Horizontal width of desktop notification popups in pixels"
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
        title: "Card Corner Radius"
        desc: "Outer rounding of the notification toast popup card"
        value: NotificationService.cardRadius
        minVal: 0
        maxVal: 28
        step: 2
        unit: "px"
        presets: [
            { label: "8px", val: 8 },
            { label: "12px", val: 12 },
            { label: "16px", val: 16 },
            { label: "22px", val: 22 }
        ]
        onValueModified: (val) => NotificationService.setCardRadius(val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Card Inner Padding"
        desc: "Internal padding around notification building blocks"
        value: NotificationService.cardPadding
        minVal: 8
        maxVal: 24
        step: 2
        unit: "px"
        presets: [
            { label: "10px", val: 10 },
            { label: "12px", val: 12 },
            { label: "14px", val: 14 },
            { label: "18px", val: 18 }
        ]
        onValueModified: (val) => NotificationService.setCardPadding(val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Card Opacity"
        desc: "Background opacity of notification toast cards"
        value: Math.round(NotificationService.cardOpacity * 100)
        minVal: 50
        maxVal: 100
        step: 5
        unit: "%"
        presets: [
            { label: "75%", val: 75 },
            { label: "85%", val: 85 },
            { label: "95%", val: 95 },
            { label: "100%", val: 100 }
        ]
        onValueModified: (val) => NotificationService.setCardOpacity(val / 100.0)
    }
}
}
