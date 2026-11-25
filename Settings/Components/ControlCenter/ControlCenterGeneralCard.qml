import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../ControlCenter"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: generalSection
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: "General Appearance & Dimensions"
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
            // Row 1: Flyout Layout Orientation (Vertical Stack vs Horizontal Grid)
            Item {
                Layout.fillWidth: true
                height: 44

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Flyout Layout Orientation"
                            font.family: root.font
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: layoutSegTrack
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        implicitHeight: 32
                        height: 32
                        radius: 7
                        color: root.theme.bgBase
                        border.color: root.theme.bgBorder
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        readonly property int activeIdx: ControlCenterConfig.panelLayout === "horizontal" ? 1 : 0
                        readonly property real cellWidth: (width - 6 - 4) / 2

                        Rectangle {
                            y: 3
                            height: parent.height - 6
                            width: layoutSegTrack.cellWidth
                            x: 3 + layoutSegTrack.activeIdx * (layoutSegTrack.cellWidth + 4)
                            radius: 5
                            color: root.theme.bgSelected
                            border.color: root.theme.accentPrimary
                            border.width: 1

                            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 4

                            Repeater {
                                model: [
                                    { label: "Vertical", value: "vertical" },
                                    { label: "Horizontal", value: "horizontal" }
                                ]

                                delegate: Rectangle {
                                    id: layBtn
                                    required property var modelData
                                    readonly property bool isSel: ControlCenterConfig.panelLayout === modelData.value

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    scale: layMouse.pressed ? 0.95 : 1.0
                                    color: !isSel && layHover.hovered ? root.theme.bgHover : "transparent"

                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: layHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: layBtn.modelData.label
                                        font.family: root.font
                                        font.pixelSize: Style.px(11)
                                        font.bold: layBtn.isSel
                                        color: layBtn.isSel ? root.theme.accentPrimary : root.theme.textSecondary
                                        opacity: layBtn.isSel || layHover.hovered ? 1.0 : 0.75
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on opacity { NumberAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        id: layMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            ControlCenterConfig.setPanelLayout(layBtn.modelData.value);
                                            root.showToast("Flyout layout set to " + (layBtn.modelData.value === "horizontal" ? "Horizontal" : "Vertical"));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowDivider {}

            // Row 2: Panel Width (Standard SettingSliderRow with Presets + Custom slider)
            SettingSliderRow {
                title: "Panel Width"
                value: ControlCenterConfig.panelWidth
                minVal: 280
                maxVal: 460
                step: 4
                unit: "px"
                presets: [
                    { label: "300px", val: 300 },
                    { label: "320px", val: 320 },
                    { label: "360px", val: 360 },
                    { label: "400px", val: 400 }
                ]
                onValueModified: (val) => ControlCenterConfig.setPanelWidth(val)
            }

            RowDivider {}

            // Row 3: Header & Profile
            SettingToggleRow {
                title: "Show Header & Profile"
                checked: ControlCenterConfig.showHeader
                onToggled: (val) => {
                    ControlCenterConfig.setCardVisible("header", val);
                    root.showToast(val ? "Header & Profile enabled" : "Header & Profile hidden");
                }
            }

            RowDivider {}

            // Row 4: 2x2 Connectivity Group
            SettingToggleRow {
                title: "2x2 Connectivity Group"
                checked: ControlCenterConfig.groupTilesEnabled
                onToggled: (val) => {
                    ControlCenterConfig.setGroupTilesEnabled(val);
                    root.showToast(val ? "2x2 Connectivity Group enabled" : "2x2 Connectivity Group disabled");
                }
            }
        }
    }
}
