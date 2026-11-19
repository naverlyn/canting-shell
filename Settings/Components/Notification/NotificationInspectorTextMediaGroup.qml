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

// 3. TITLE NOTIFICATION BUILDING BLOCK OPTIONS
ColumnLayout {
    visible: groupRoot.activeTabId === "title"
    Layout.fillWidth: true
    spacing: 0

    SettingToggleRow {
        title: "Show Title Notification Block"
        checked: NotificationService.isBlockVisible("title")
        onToggled: (val) => NotificationService.setBlockVisible("title", val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Title Font Size"
        value: NotificationService.titleFontSize
        minVal: 11
        maxVal: 22
        step: 1
        unit: "px"
        presets: [
            { label: "13px", val: 13 },
            { label: "14px", val: 14 },
            { label: "16px", val: 16 },
            { label: "18px", val: 18 }
        ]
        onValueModified: (val) => NotificationService.setTitleFontSize(val)
    }

    RowDivider {}

    SettingToggleRow {
        title: "Bold Title Typography"
        checked: NotificationService.titleBold
        onToggled: (val) => NotificationService.setTitleBold(val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Maximum Title Lines"
        value: NotificationService.titleMaxLines
        minVal: 1
        maxVal: 4
        step: 1
        unit: ""
        presets: [
            { label: "1 Line", val: 1 },
            { label: "2 Lines", val: 2 },
            { label: "3 Lines", val: 3 }
        ]
        onValueModified: (val) => NotificationService.setTitleMaxLines(val)
    }

    RowDivider {}

    // Title Alignment
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
                    text: "Title Text Alignment"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
                Text {
                    text: "Horizontal alignment of the notification summary text"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            SegmentedControl {
                trackWidth: 210
                currentId: NotificationService.titleAlignment
                options: [
                    { id: "left",   label: "Left" },
                    { id: "center", label: "Center" },
                    { id: "right",  label: "Right" }
                ]
                onOptionSelected: (optionId) => NotificationService.setTitleAlignment(optionId)
            }
        }
    }
}

// 4. BODY MESSAGE BUILDING BLOCK OPTIONS
ColumnLayout {
    visible: groupRoot.activeTabId === "body"
    Layout.fillWidth: true
    spacing: 0

    SettingToggleRow {
        title: "Show Body Message Block"
        checked: NotificationService.isBlockVisible("body")
        onToggled: (val) => NotificationService.setBlockVisible("body", val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Body Font Size"
        value: NotificationService.bodyFontSize
        minVal: 10
        maxVal: 18
        step: 1
        unit: "px"
        presets: [
            { label: "11px", val: 11 },
            { label: "12px", val: 12 },
            { label: "13px", val: 13 },
            { label: "14px", val: 14 }
        ]
        onValueModified: (val) => NotificationService.setBodyFontSize(val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Maximum Body Lines"
        value: NotificationService.bodyMaxLines
        minVal: 1
        maxVal: 8
        step: 1
        unit: ""
        presets: [
            { label: "2 Lines", val: 2 },
            { label: "3 Lines", val: 3 },
            { label: "4 Lines", val: 4 },
            { label: "6 Lines", val: 6 }
        ]
        onValueModified: (val) => NotificationService.setBodyMaxLines(val)
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
                    text: "Body Text Alignment"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
                Text {
                    text: "Horizontal alignment of the notification body paragraph"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            SegmentedControl {
                trackWidth: 210
                currentId: NotificationService.bodyAlignment
                options: [
                    { id: "left",   label: "Left" },
                    { id: "center", label: "Center" },
                    { id: "right",  label: "Right" }
                ]
                onOptionSelected: (optionId) => NotificationService.setBodyAlignment(optionId)
            }
        }
    }
}

// 5. PREVIEW IMAGE BUILDING BLOCK OPTIONS
ColumnLayout {
    visible: groupRoot.activeTabId === "image"
    Layout.fillWidth: true
    spacing: 0

    SettingToggleRow {
        title: "Show Preview Image Block"
        checked: NotificationService.isBlockVisible("image")
        onToggled: (val) => NotificationService.setBlockVisible("image", val)
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
                    text: "Preview Image Position"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
                Text {
                    text: "Place thumbnail beside the body text or expand as a full-width banner"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            SegmentedControl {
                trackWidth: 270
                currentId: NotificationService.imagePosition
                options: [
                    { id: "right",  label: "Right Thumb" },
                    { id: "left",   label: "Left Thumb" },
                    { id: "banner", label: "Full Banner" }
                ]
                onOptionSelected: (optionId) => NotificationService.setImagePosition(optionId)
            }
        }
    }

    RowDivider {}

    SettingSliderRow {
        title: "Thumbnail / Banner Size"
        value: NotificationService.imageSize
        minVal: 28
        maxVal: 110
        step: 4
        unit: "px"
        presets: [
            { label: "36px", val: 36 },
            { label: "44px", val: 44 },
            { label: "56px", val: 56 },
            { label: "72px", val: 72 }
        ]
        onValueModified: (val) => NotificationService.setImageSize(val)
    }

    RowDivider {}

    SettingSliderRow {
        title: "Image Corner Radius"
        value: NotificationService.imageRadius
        minVal: 0
        maxVal: 48
        step: 1
        unit: "px"
        presets: [
            { label: "6px", val: 6 },
            { label: "10px", val: 10 },
            { label: "16px", val: 16 },
            { label: "Circle", val: 48 }
        ]
        onValueModified: (val) => NotificationService.setImageRadius(val)
    }

    RowDivider {}

    SettingToggleRow {
        title: "Show Image Background"
        checked: NotificationService.imageShowBg
        onToggled: (val) => NotificationService.setImageShowBg(val)
    }
}

}
