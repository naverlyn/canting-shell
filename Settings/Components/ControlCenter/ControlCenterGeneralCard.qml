import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../ControlCenter"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: generalSection
    title: "General Appearance & Dimensions"
    subtitle: "Configure flyout layout orientation, width, and chrome elements"
    contentMargins: 8
    contentSpacing: 0

    // Row 1: Flyout Layout Orientation (Vertical Stack vs Horizontal Grid)
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
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true

                Text {
                    text: "Flyout Layout Orientation"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Arrange active sections in a single vertical stack or multi-column horizontal grid"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                id: layoutSegTrack
                implicitWidth: 220
                implicitHeight: 32
                width: 220
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
                                font.pixelSize: 11
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
        desc: "Horizontal width of each Control Center column in pixels"
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
        desc: "Display top bar with user avatar, uptime, battery status, and power actions"
        checked: ControlCenterConfig.showHeader
        onToggled: (val) => {
            ControlCenterConfig.setCardVisible("header", val);
            root.showToast(val ? "Header & Profile enabled" : "Header & Profile hidden");
        }
    }

    RowDivider {}

    // Row 4: View Switcher
    SettingToggleRow {
        title: "Show View Switcher"
        desc: "Display navigation tabs to switch between Control Center and Notifications"
        checked: ControlCenterConfig.showViewSwitcher
        onToggled: (val) => {
            ControlCenterConfig.setCardVisible("viewSwitcher", val);
            root.showToast(val ? "View Switcher enabled" : "View Switcher hidden");
        }
    }

    RowDivider {}

    // Row 5: 2x2 Connectivity Group
    SettingToggleRow {
        title: "2x2 Connectivity Group"
        desc: "Group up to 4 primary quick tiles into a compact squircle card (iOS/Android style)"
        checked: ControlCenterConfig.groupTilesEnabled
        onToggled: (val) => {
            ControlCenterConfig.setGroupTilesEnabled(val);
            root.showToast(val ? "2x2 Connectivity Group enabled" : "2x2 Connectivity Group disabled");
        }
    }
}
