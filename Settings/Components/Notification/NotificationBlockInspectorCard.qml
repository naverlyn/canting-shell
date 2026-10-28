import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../notifications"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: inspectorSection
    title: "Building Block Inspector & Styling"
    subtitle: "Fine-tune typography, dimensions, alignment, and visual styling for each notification building block"

    readonly property var inspectorTabs: [
        { id: "icon",        label: "App Icon",       icon: "󰂚" },
        { id: "appName",     label: "Header & Time",  icon: "󰀻" },
        { id: "title",       label: "Title",          icon: "󰗴" },
        { id: "body",        label: "Body Message",   icon: "󰦨" },
        { id: "image",       label: "Preview Image",  icon: "󰋩" },
        { id: "buttons",     label: "Action Buttons", icon: "󰘊" },
        { id: "progressBar", label: "Timeout Bar",    icon: "󰔟" },
        { id: "card",        label: "Card & Accent",  icon: "󰒓" }
    ]

    readonly property string activeTabId: {
        const cur = root.selectedInspectorBlock;
        if (cur === "timestamp" || cur === "closeBtn") return "appName";
        return cur || "icon";
    }

    // Top Selector Pill Strip
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 42
        radius: 9
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 4

            Repeater {
                model: inspectorSection.inspectorTabs
                delegate: Rectangle {
                    id: tabPill
                    required property var modelData
                    readonly property bool isSel: inspectorSection.activeTabId === modelData.id

                    Layout.fillWidth: true
                    height: 30
                    radius: 6
                    color: isSel
                        ? root.theme.bgSelected
                        : (pillHover.hovered ? root.theme.bgHover : "transparent")
                    border.color: isSel ? root.theme.accentPrimary : "transparent"
                    border.width: isSel ? 1 : 0
                    scale: pillMouse.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 130 } }
                    Behavior on scale { NumberAnimation { duration: 90 } }

                    HoverHandler { id: pillHover }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: tabPill.modelData.icon
                            font.family: root.font
                            font.pixelSize: 12
                            color: tabPill.isSel ? root.theme.accentPrimary : root.theme.textSecondary
                        }

                        Text {
                            text: tabPill.modelData.label
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: tabPill.isSel
                            color: tabPill.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: pillMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedInspectorBlock = tabPill.modelData.id
                    }
                }
            }
        }
    }

    // Inspector Content Container
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: inspectorContentCol.implicitHeight + 16
        radius: 10
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: inspectorContentCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            // =================================================================
            // 1. APP ICON BUILDING BLOCK OPTIONS
            // =================================================================
            ColumnLayout {
                visible: inspectorSection.activeTabId === "icon"
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

                        Rectangle {
                            width: 240
                            height: 32
                            radius: 7
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 3

                                Repeater {
                                    model: [
                                        { id: "auto",   label: "Auto (Zone)" },
                                        { id: "inline", label: "Header" },
                                        { id: "avatar", label: "Avatar Left" }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool isCur: NotificationService.iconMode === modelData.id
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 5
                                        color: isCur ? root.theme.bgSelected : "transparent"
                                        border.color: isCur ? root.theme.accentPrimary : "transparent"
                                        border.width: isCur ? 1 : 0

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: isCur
                                            color: isCur ? root.theme.accentPrimary : root.theme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.setIconMode(modelData.id)
                                        }
                                    }
                                }
                            }
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

            // =================================================================
            // 2. HEADER, APP NAME, TIMESTAMP & CLOSE BUTTON OPTIONS
            // =================================================================
            ColumnLayout {
                visible: inspectorSection.activeTabId === "appName"
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

                        Rectangle {
                            width: 190
                            height: 32
                            radius: 7
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 3

                                Repeater {
                                    model: [
                                        { id: "relative", label: "Relative (Now)" },
                                        { id: "time",     label: "Clock (HH:mm)" }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool isCur: NotificationService.timestampFormat === modelData.id
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 5
                                        color: isCur ? root.theme.bgSelected : "transparent"
                                        border.color: isCur ? root.theme.accentPrimary : "transparent"
                                        border.width: isCur ? 1 : 0

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: isCur
                                            color: isCur ? root.theme.accentPrimary : root.theme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.setTimestampFormat(modelData.id)
                                        }
                                    }
                                }
                            }
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

            // =================================================================
            // 3. TITLE NOTIFICATION BUILDING BLOCK OPTIONS
            // =================================================================
            ColumnLayout {
                visible: inspectorSection.activeTabId === "title"
                Layout.fillWidth: true
                spacing: 0

                SettingToggleRow {
                    title: "Show Title Notification Block"
                    desc: "Display primary notification summary headline (e.g. 'Screenshot:')"
                    checked: NotificationService.isBlockVisible("title")
                    onToggled: (val) => NotificationService.setBlockVisible("title", val)
                }

                RowDivider {}

                SettingSliderRow {
                    title: "Title Font Size"
                    desc: "Pixel size of the notification summary headline"
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
                    desc: "Render the notification title in bold weight for visual hierarchy"
                    checked: NotificationService.titleBold
                    onToggled: (val) => NotificationService.setTitleBold(val)
                }

                RowDivider {}

                SettingSliderRow {
                    title: "Maximum Title Lines"
                    desc: "Number of lines before truncating long titles with an ellipsis"
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

                        Rectangle {
                            width: 195
                            height: 32
                            radius: 7
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 3

                                Repeater {
                                    model: [
                                        { id: "left",   label: "Left" },
                                        { id: "center", label: "Center" },
                                        { id: "right",  label: "Right" }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool isCur: NotificationService.titleAlignment === modelData.id
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 5
                                        color: isCur ? root.theme.bgSelected : "transparent"
                                        border.color: isCur ? root.theme.accentPrimary : "transparent"
                                        border.width: isCur ? 1 : 0

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: isCur
                                            color: isCur ? root.theme.accentPrimary : root.theme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.setTitleAlignment(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 4. BODY MESSAGE BUILDING BLOCK OPTIONS
            // =================================================================
            ColumnLayout {
                visible: inspectorSection.activeTabId === "body"
                Layout.fillWidth: true
                spacing: 0

                SettingToggleRow {
                    title: "Show Body Message Block"
                    desc: "Display detailed notification body text (e.g. 'Captured by Swappy')"
                    checked: NotificationService.isBlockVisible("body")
                    onToggled: (val) => NotificationService.setBlockVisible("body", val)
                }

                RowDivider {}

                SettingSliderRow {
                    title: "Body Font Size"
                    desc: "Typography size for the notification body message"
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
                    desc: "Maximum wrapped lines shown before truncating long messages"
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

                        Rectangle {
                            width: 195
                            height: 32
                            radius: 7
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 3

                                Repeater {
                                    model: [
                                        { id: "left",   label: "Left" },
                                        { id: "center", label: "Center" },
                                        { id: "right",  label: "Right" }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool isCur: NotificationService.bodyAlignment === modelData.id
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 5
                                        color: isCur ? root.theme.bgSelected : "transparent"
                                        border.color: isCur ? root.theme.accentPrimary : "transparent"
                                        border.width: isCur ? 1 : 0

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: isCur
                                            color: isCur ? root.theme.accentPrimary : root.theme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.setBodyAlignment(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 5. PREVIEW IMAGE BUILDING BLOCK OPTIONS
            // =================================================================
            ColumnLayout {
                visible: inspectorSection.activeTabId === "image"
                Layout.fillWidth: true
                spacing: 0

                SettingToggleRow {
                    title: "Show Preview Image Block"
                    desc: "Display screenshot thumbnail, album art, or media preview image"
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

                        Rectangle {
                            width: 240
                            height: 32
                            radius: 7
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 3

                                Repeater {
                                    model: [
                                        { id: "right",  label: "Right Thumb" },
                                        { id: "left",   label: "Left Thumb" },
                                        { id: "banner", label: "Full Banner" }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool isCur: NotificationService.imagePosition === modelData.id
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 5
                                        color: isCur ? root.theme.bgSelected : "transparent"
                                        border.color: isCur ? root.theme.accentPrimary : "transparent"
                                        border.width: isCur ? 1 : 0

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: isCur
                                            color: isCur ? root.theme.accentPrimary : root.theme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.setImagePosition(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                RowDivider {}

                SettingSliderRow {
                    title: "Thumbnail / Banner Size"
                    desc: "Size of the thumbnail square (or height when in Full Banner mode)"
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
                    desc: "Rounding applied to the preview thumbnail corners"
                    value: NotificationService.imageRadius
                    minVal: 0
                    maxVal: 24
                    step: 1
                    unit: "px"
                    presets: [
                        { label: "6px", val: 6 },
                        { label: "10px", val: 10 },
                        { label: "14px", val: 14 },
                        { label: "20px", val: 20 }
                    ]
                    onValueModified: (val) => NotificationService.setImageRadius(val)
                }
            }

            // =================================================================
            // 6. ACTION BUTTONS BUILDING BLOCK OPTIONS
            // =================================================================
            ColumnLayout {
                visible: inspectorSection.activeTabId === "buttons"
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

                        Rectangle {
                            width: 240
                            height: 32
                            radius: 7
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 3

                                Repeater {
                                    model: [
                                        { id: "pill",  label: "Rounded Pill" },
                                        { id: "fill",  label: "Full Width" },
                                        { id: "ghost", label: "Ghost" }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool isCur: NotificationService.buttonStyle === modelData.id
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 5
                                        color: isCur ? root.theme.bgSelected : "transparent"
                                        border.color: isCur ? root.theme.accentPrimary : "transparent"
                                        border.width: isCur ? 1 : 0

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: isCur
                                            color: isCur ? root.theme.accentPrimary : root.theme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.setButtonStyle(modelData.id)
                                        }
                                    }
                                }
                            }
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

                        Rectangle {
                            width: 240
                            height: 32
                            radius: 7
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 3

                                Repeater {
                                    model: [
                                        { id: "left",    label: "Left" },
                                        { id: "center",  label: "Center" },
                                        { id: "right",   label: "Right" },
                                        { id: "stretch", label: "Stretch" }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool isCur: NotificationService.buttonAlignment === modelData.id
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 5
                                        color: isCur ? root.theme.bgSelected : "transparent"
                                        border.color: isCur ? root.theme.accentPrimary : "transparent"
                                        border.width: isCur ? 1 : 0

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: isCur
                                            color: isCur ? root.theme.accentPrimary : root.theme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.setButtonAlignment(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 7. TIMEOUT PROGRESS BAR BUILDING BLOCK OPTIONS
            // =================================================================
            ColumnLayout {
                visible: inspectorSection.activeTabId === "progressBar"
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

            // =================================================================
            // 8. CARD CHROME & ACCENT STRIP OPTIONS
            // =================================================================
            ColumnLayout {
                visible: inspectorSection.activeTabId === "card"
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

                        Rectangle {
                            width: 240
                            height: 32
                            radius: 7
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 3

                                Repeater {
                                    model: [
                                        { id: "left",  label: "Left" },
                                        { id: "right", label: "Right" },
                                        { id: "top",   label: "Top" },
                                        { id: "none",  label: "Hidden" }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property string curStrip: NotificationService.showAccentStrip ? NotificationService.accentStripPosition : "none"
                                        readonly property bool isCur: curStrip === modelData.id
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 5
                                        color: isCur ? root.theme.bgSelected : "transparent"
                                        border.color: isCur ? root.theme.accentPrimary : "transparent"
                                        border.width: isCur ? 1 : 0

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: isCur
                                            color: isCur ? root.theme.accentPrimary : root.theme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.setAccentStripPosition(modelData.id)
                                        }
                                    }
                                }
                            }
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
    }
}
