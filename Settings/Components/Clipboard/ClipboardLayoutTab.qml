import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../Clipboard"
import "../Common"

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 16
    visible: root.currentSubTab === 0

    // Live Proportions Preview Canvas
    Rectangle {
        Layout.fillWidth: true
        height: 200
        radius: 8
        color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
        border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        clip: true

        // Dimensions info pill top right
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 10
            implicitWidth: dimLabel.implicitWidth + 12
            height: 22
            radius: 5
            color: (root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.08)
            border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            z: 10

            Text {
                id: dimLabel
                anchors.centerIn: parent
                text: ClipboardConfig.windowWidth + " × " + ClipboardConfig.windowHeight + " px"
                font.family: Style.monoFont
                font.pixelSize: 11
                color: Style.theme.accentPrimary
            }
        }

        // Scaled Mockup Container
        Rectangle {
            id: mockWin
            anchors.centerIn: parent
            readonly property real scaleFactor: 0.22
            width: Math.round(ClipboardConfig.windowWidth * scaleFactor)
            height: Math.round(ClipboardConfig.windowHeight * scaleFactor)
            radius: 8
            color: root.theme.bgSurface
            border.color: root.theme.accentPrimary
            border.width: 1.5

            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                // Mock Search Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 16
                    radius: 4
                    color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                    border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        spacing: 4

                        Text {
                            text: "󰍉"
                            font.family: root.font
                            font.pixelSize: 8
                            color: root.theme.textMuted
                        }

                        Text {
                            text: "search clipboard..."
                            font.family: root.font
                            font.pixelSize: 8
                            color: root.theme.textMuted
                        }
                    }
                }

                // Mock Category Filter Chips
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 10
                            radius: 3
                            color: index === 0
                                ? (root.theme.accentPrimary)
                                : ((root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(1, 1, 1, 0.08))
                            opacity: index === 0 ? 0.9 : 0.5
                        }
                    }
                }

                // Mock Item Rows
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    Repeater {
                        model: Math.max(0, Math.min(4, Math.floor((mockWin.height - 50) / 18)))
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 14
                            radius: 3
                            color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.2)
                            border.color: index === 0
                                ? (root.theme.accentPrimary)
                                : ((root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.05))
                            border.width: index === 0 ? 1 : 0.5

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 4

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: index === 0 ? root.theme.accentPrimary : (index === 1 ? root.theme.accentGreen : root.theme.accentOrange)
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 4
                                    radius: 2
                                    color: root.theme.textSecondary
                                    opacity: 0.6
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Window Dimensions Section
    SectionCard {
        title: "Clipboard Window Dimensions (Center Popup)"
        subtitle: "Adjust the popup box size when opened via Super+V or global menu"
        contentMargins: 8
        contentSpacing: 0

        SettingSliderRow {
            title: "Popup Width"
            desc: "Width of the center clipboard history popup window"
            value: ClipboardConfig.windowWidth
            minVal: 640
            maxVal: 960
            step: 20
            unit: "px"
            presets: [
                { label: "680px", val: 680 },
                { label: "840px (Default)", val: 840 },
                { label: "960px", val: 960 }
            ]
            onValueModified: (val) => ClipboardConfig.setWindowWidth(val)
        }

        RowDivider {}

        SettingSliderRow {
            title: "Popup Height"
            desc: "Vertical height of the clipboard history window"
            value: ClipboardConfig.windowHeight
            minVal: 480
            maxVal: 760
            step: 20
            unit: "px"
            presets: [
                { label: "520px", val: 520 },
                { label: "640px (Default)", val: 640 },
                { label: "740px", val: 740 }
            ]
            onValueModified: (val) => ClipboardConfig.setWindowHeight(val)
        }

        RowDivider {}

        // Default Category Segmented Row
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
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Default Opening Category"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "Initial filter tab active when clipboard window opens"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }

                SegmentedControl {
                    trackWidth: 320
                    currentId: ClipboardConfig.defaultCategory
                    options: [
                        { id: "all",   label: "All" },
                        { id: "text",  label: "Text" },
                        { id: "image", label: "Images" },
                        { id: "link",  label: "Links" },
                        { id: "code",  label: "Code" },
                        { id: "color", label: "Colors" }
                    ]
                    onOptionSelected: (optionId) => ClipboardConfig.setDefaultCategory(optionId)
                }
            }
        }
    }
}
