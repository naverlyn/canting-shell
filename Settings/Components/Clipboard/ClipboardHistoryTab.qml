import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../../../Clipboard"
import "../Common"

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 16
    visible: root.currentSubTab === 1

    // History Capacity Card
    SectionCard {
        title: "History Capacity & Retention"
        subtitle: "Control how many clipboard items are stored in memory and displayed"
        contentMargins: 8
        contentSpacing: 0

        SettingSliderRow {
            title: "Max History Items"
            desc: "Maximum number of past clips loaded into the Quickshell clipboard UI"
            value: ClipboardConfig.maxItems
            minVal: 25
            maxVal: 500
            step: 25
            unit: " items"
            presets: [
                { label: "50", val: 50 },
                { label: "100 (Default)", val: 100 },
                { label: "250", val: 250 },
                { label: "500", val: 500 }
            ]
            onValueModified: (val) => ClipboardConfig.setMaxItems(val)
        }
    }

    // Window & Selection Behavior Card
    SectionCard {
        title: "Window & Copying Behavior"
        subtitle: "Preferences for modal dismissal and search state retention"
        contentMargins: 8
        contentSpacing: 0

        SettingToggleRow {
            title: "Close Popup on Copy"
            desc: "Automatically close the clipboard window when an item is copied"
            checked: ClipboardConfig.closeOnCopy
            onToggled: (val) => ClipboardConfig.setCloseOnCopy(val)
        }

        RowDivider {}

        SettingToggleRow {
            title: "Clear Search Query on Close"
            desc: "Reset the search bar and filter text whenever the clipboard modal is dismissed"
            checked: ClipboardConfig.clearSearchOnClose
            onToggled: (val) => ClipboardConfig.setClearSearchOnClose(val)
        }
    }

    // Content Recognition & Badges Card
    SectionCard {
        title: "Content Detection & Visual Thumbnails"
        subtitle: "Automatic categorization for media, code, web links, and hex color values"
        contentMargins: 8
        contentSpacing: 0

        SettingToggleRow {
            title: "Generate Image Preview Thumbnails"
            desc: "Decode clipboard binary PNG/JPEG images into instant visual preview thumbnails"
            checked: ClipboardConfig.generateThumbnails
            onToggled: (val) => ClipboardConfig.setGenerateThumbnails(val)
        }

        RowDivider {}

        SettingToggleRow {
            title: "Detect Hex Color Codes"
            desc: "Recognize color strings (e.g. #7aa2f7) and display live color swatch badges"
            checked: ClipboardConfig.detectColors
            onToggled: (val) => ClipboardConfig.setDetectColors(val)
        }

        RowDivider {}

        SettingToggleRow {
            title: "Detect Web Links & URLs"
            desc: "Identify http/https URLs and show globe link indicators with open actions"
            checked: ClipboardConfig.detectLinks
            onToggled: (val) => ClipboardConfig.setDetectLinks(val)
        }

        RowDivider {}

        SettingToggleRow {
            title: "Detect Code Snippets"
            desc: "Inspect snippet contents for syntax keywords (functions, imports, classes)"
            checked: ClipboardConfig.detectCode
            onToggled: (val) => ClipboardConfig.setDetectCode(val)
        }
    }

    // Cache & Danger Actions Card
    SectionCard {
        title: "Actions & Cache Management"
        subtitle: "Wipe recorded clipboard items or restore default preferences"
        contentMargins: 8
        contentSpacing: 0

        Item {
            Layout.fillWidth: true
            height: 52

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: wipeBtn.left
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: "Wipe Clipboard History"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.accentRed
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: "Permanently delete all stored clips in ~/.cache/cliphist/db and thumbnail cache"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textMuted
                    elide: Text.ElideRight
                }
            }

            ActionButton {
                id: wipeBtn
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                label: "Wipe History"
                danger: true
                btnHeight: 30
                onClicked: root.wipeHistory()
            }
        }

        RowDivider {}

        Item {
            Layout.fillWidth: true
            height: 52

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: resetDefaultsBtn.left
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: "Reset All Clipboard Settings"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: "Revert dimensions, category filters, and detection toggles to default values"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textMuted
                    elide: Text.ElideRight
                }
            }

            ActionButton {
                id: resetDefaultsBtn
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                label: "Reset Defaults"
                btnHeight: 30
                onClicked: {
                    ClipboardConfig.resetDefaults();
                    root.showToast("Clipboard preferences reset to defaults");
                }
            }
        }
    }
}
