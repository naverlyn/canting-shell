import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    visible: root.currentSubTab === 0
    Layout.fillWidth: true
    spacing: 16

    /* Interactive Live Preview Canvas */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Live Window Layout Preview"
        subtitle: "Simulated layout with active gaps, borders, and rounding"

        Rectangle {
            Layout.fillWidth: true
            height: 140
            radius: 8
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1
            clip: true

            // Monitor outer bezel simulation
            Item {
                id: previewMonitorArea
                anchors.fill: parent

                property real animGapsOut: Math.max(4, root.generalGapsOut * 1.2)
                property real animGapsIn: Math.max(2, root.generalGapsIn * 1.2)
                property real animRounding: Math.min(18, root.decorRounding)
                property real animBorderSize: Math.max(1, root.generalBorderSize)
                property real animInactiveOpacity: root.decorInactiveOpacity

                Behavior on animGapsOut { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on animGapsIn { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on animRounding { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on animBorderSize { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on animInactiveOpacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                anchors.margins: animGapsOut

                // 1. Dwindle or Master layout
                RowLayout {
                    opacity: (root.generalLayout === "dwindle" || root.generalLayout === "master") ? 1.0 : 0.0
                    visible: opacity > 0
                    anchors.fill: parent
                    spacing: previewMonitorArea.animGapsIn

                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    // Primary / Master Window
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: previewMonitorArea.animRounding
                        color: root.theme.bgSelected
                        border.color: root.theme.accentPrimary
                        border.width: previewMonitorArea.animBorderSize

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: root.generalLayout === "master" ? "󰕰 Master Window" : "󰕮 Primary Window"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.accentPrimary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: root.generalLayout.toUpperCase() + " | Active"
                                font.family: root.font
                                font.pixelSize: 9
                                color: root.theme.textSecondary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // Secondary Stack
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: previewMonitorArea.animGapsIn

                        // Window 2
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: previewMonitorArea.animRounding
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: previewMonitorArea.animBorderSize
                            opacity: previewMonitorArea.animInactiveOpacity

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Window 2"
                                font.family: root.font
                                font.pixelSize: 10
                                color: root.theme.textSecondary
                            }
                        }

                        // Window 3
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: previewMonitorArea.animRounding
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: previewMonitorArea.animBorderSize
                            opacity: previewMonitorArea.animInactiveOpacity

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Window 3"
                                font.family: root.font
                                font.pixelSize: 10
                                color: root.theme.textSecondary
                            }
                        }
                    }
                }

                // 2. Scrolling strip layout
                RowLayout {
                    opacity: root.generalLayout === "scrolling" ? 1.0 : 0.0
                    visible: opacity > 0
                    anchors.fill: parent
                    spacing: previewMonitorArea.animGapsIn

                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: previewMonitorArea.animRounding
                        color: root.theme.bgSurface
                        border.color: root.theme.bgBorder
                        border.width: previewMonitorArea.animBorderSize
                        opacity: previewMonitorArea.animInactiveOpacity

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Column 1"
                            font.family: root.font
                            font.pixelSize: 10
                            color: root.theme.textSecondary
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: previewMonitorArea.animRounding
                        color: root.theme.bgSelected
                        border.color: root.theme.accentPrimary
                        border.width: previewMonitorArea.animBorderSize

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "󰍍 Active Column"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.accentPrimary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: "SCROLLING STRIP"
                                font.family: root.font
                                font.pixelSize: 9
                                color: root.theme.textSecondary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: previewMonitorArea.animRounding
                        color: root.theme.bgSurface
                        border.color: root.theme.bgBorder
                        border.width: previewMonitorArea.animBorderSize
                        opacity: previewMonitorArea.animInactiveOpacity

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Column 3"
                            font.family: root.font
                            font.pixelSize: 10
                            color: root.theme.textSecondary
                        }
                    }
                }

                // 3. Monocle fullscreen / stacked layout
                Rectangle {
                    opacity: root.generalLayout === "monocle" ? 1.0 : 0.0
                    visible: opacity > 0
                    anchors.fill: parent
                    radius: previewMonitorArea.animRounding
                    color: root.theme.bgSelected
                    border.color: root.theme.accentPrimary
                    border.width: previewMonitorArea.animBorderSize

                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "󰍹 Focused Window (1 of 3)"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.accentPrimary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "MONOCLE | Fullscreen Focused Window Stack"
                            font.family: root.font
                            font.pixelSize: 9
                            color: root.theme.textSecondary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }

    /* Window Gaps Card */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Window Spacing & Gaps"
        subtitle: "Inner gaps between windows & outer margins to monitor edges"

        SettingSliderRow {
            announce: true
            title: "Inner Window Gaps"
            desc: "Distance in pixels between adjacent tiled windows"
            value: root.generalGapsIn
            minVal: 0
            maxVal: 24
            unit: "px"
            presets: [
                { label: "0px", val: 0 },
                { label: "2px", val: 2 },
                { label: "5px", val: 5 },
                { label: "10px", val: 10 }
            ]
            onValueModified: (v) => {
                root.generalGapsIn = v;
                root.setHyprVar("general", "gaps_in", v);
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingSliderRow {
            announce: true
            title: "Outer Screen Gaps"
            desc: "Distance in pixels between windows and monitor borders"
            value: root.generalGapsOut
            minVal: 0
            maxVal: 40
            unit: "px"
            presets: [
                { label: "0px", val: 0 },
                { label: "4px", val: 4 },
                { label: "10px", val: 10 },
                { label: "20px", val: 20 }
            ]
            onValueModified: (v) => {
                root.generalGapsOut = v;
                root.setHyprVar("general", "gaps_out", v);
            }
        }
    }

    /* Window Borders & Resizing Card */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Window Borders & Sizing"
        subtitle: "Border thickness and edge interaction"

        SettingSliderRow {
            announce: true
            title: "Border Thickness"
            desc: "Width of window outline border"
            value: root.generalBorderSize
            minVal: 0
            maxVal: 6
            unit: "px"
            presets: [
                { label: "0px", val: 0 },
                { label: "1px", val: 1 },
                { label: "2px", val: 2 },
                { label: "3px", val: 3 }
            ]
            onValueModified: (v) => {
                root.generalBorderSize = v;
                root.setHyprVar("general", "border_size", v);
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingToggleRow {
            announce: true
            title: "Resize On Border"
            desc: "Enable clicking and dragging directly on window borders to resize"
            checked: root.generalResizeOnBorder
            onToggled: (val) => {
                root.generalResizeOnBorder = val;
                root.setHyprVar("general", "resize_on_border", val);
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingToggleRow {
            announce: true
            title: "Allow Screen Tearing"
            desc: "Master switch to allow tearing for ultra-low latency gaming"
            checked: root.generalAllowTearing
            onToggled: (val) => {
                root.generalAllowTearing = val;
                root.setHyprVar("general", "allow_tearing", val);
            }
        }
    }

    /* Layout & Snapping Card */
    SectionCard {
        subtitleMaxRatio: 0.55
        title: "Tiling Engine & Snapping"
        subtitle: "Compositor layout algorithm and floating window snapping"

        Item {
            Layout.fillWidth: true
            width: parent ? parent.width : 0
            height: 54

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter
                    readonly property int colWidth: Math.max(260, Math.round(((root.width > 0 ? root.width : 889) - 48) * 0.595))
                    Layout.preferredWidth: colWidth
                    Layout.minimumWidth: colWidth
                    Layout.maximumWidth: colWidth

                    Text {
                        text: "Layout Engine"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "Select default tiling layout algorithm"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    id: layoutSegmentTrack
                    implicitWidth: 340
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    readonly property var layouts: ["dwindle", "master", "scrolling", "monocle"]
                    readonly property int activeIdx: layouts.indexOf(root.generalLayout)
                    readonly property real cellWidth: (width - 6 - 9) / 4

                    /* Sliding Selection Pill */
                    Rectangle {
                        visible: layoutSegmentTrack.activeIdx >= 0
                        y: 3
                        height: parent.height - 6
                        width: layoutSegmentTrack.cellWidth
                        x: 3 + Math.max(0, layoutSegmentTrack.activeIdx) * (layoutSegmentTrack.cellWidth + 3)
                        radius: 5
                        color: root.theme.bgSelected
                        border.color: root.theme.accentPrimary
                        border.width: 1

                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3

                        Repeater {
                            model: [
                                { id: "dwindle", label: "Dwindle" },
                                { id: "master", label: "Master" },
                                { id: "scrolling", label: "Scrolling" },
                                { id: "monocle", label: "Monocle" }
                            ]

                            delegate: Rectangle {
                                id: lSegBtn
                                required property var modelData
                                required property int index
                                readonly property bool isSel: layoutSegmentTrack.activeIdx === lSegBtn.index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && lHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: lHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: lSegBtn.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: lSegBtn.isSel
                                    color: lSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                    opacity: lSegBtn.isSel || lHover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.generalLayout = lSegBtn.modelData.id;
                                        root.setHyprVar("general", "layout", lSegBtn.modelData.id);
                                        root.showToast("Layout engine set to " + lSegBtn.modelData.label);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowDivider { sideMargin: 0; alpha: 1.0 }

        SettingToggleRow {
            announce: true
            title: "Floating Window Snapping"
            desc: "Snap floating windows to adjacent window edges and monitor borders"
            checked: root.generalSnapEnabled
            onToggled: (val) => {
                root.generalSnapEnabled = val;
                root.setHyprVar("general.snap", "enabled", val);
            }
        }
    }
}
