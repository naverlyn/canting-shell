import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../utils/AppFrecencyUtils.js" as AppFrecencyUtils
import Quickshell.Io
import Quickshell.Widgets
import "../../../AppLauncher"
import "../.."
import "../Common"

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 16
    visible: root.currentSubTab === 0

    // Live Interactive Proportions Preview Card
    SectionCard {
        title: "Live Proportions Preview"
        subtitle: root.previewMode === "spotlight"
            ? (AppLauncherConfig.spotlightWidth + " × " + AppLauncherConfig.spotlightHeight + " px • Spotlight Runner")
            : (AppLauncherConfig.gridColumns + " Columns • " + AppLauncherConfig.gridCellSize + " px Cell • App Grid")
        contentMargins: 14
        contentSpacing: 12

        // Toggle Preview Switcher Track
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                implicitHeight: 28
                implicitWidth: previewTrackRow.implicitWidth + 8
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                RowLayout {
                    id: previewTrackRow
                    anchors.centerIn: parent
                    spacing: 2

                    Rectangle {
                        implicitWidth: 124
                        implicitHeight: 22
                        radius: 5
                        color: root.previewMode === "spotlight" ? root.theme.accentPrimary : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰍉"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.previewMode === "spotlight" ? root.theme.bgBase : root.theme.textMuted
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Spotlight Runner"
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: root.previewMode === "spotlight"
                                color: root.previewMode === "spotlight" ? root.theme.bgBase : root.theme.textSecondary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.previewMode = "spotlight"
                        }
                    }

                    Rectangle {
                        implicitWidth: 116
                        implicitHeight: 22
                        radius: 5
                        color: root.previewMode === "grid" ? root.theme.accentPrimary : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰕮"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.previewMode === "grid" ? root.theme.bgBase : root.theme.textMuted
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "App Grid Menu"
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: root.previewMode === "grid"
                                color: root.previewMode === "grid" ? root.theme.bgBase : root.theme.textSecondary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.previewMode = "grid"
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 180
            radius: 12
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1
            clip: true

            // Screen canvas simulation
            Rectangle {
                anchors.centerIn: parent
                width: Math.round(parent.width * 0.90)
                height: 154
                radius: 8
                color: Qt.darker(root.theme.bgBase, 1.25)
                border.color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1

                // -------------------------------------------------------------
                // A. SPOTLIGHT RUNNER PREVIEW
                // -------------------------------------------------------------
                Rectangle {
                    id: mockSpotlightBox
                    visible: root.previewMode === "spotlight"
                    readonly property real scaleRatio: 120 / 620
                    width: Math.max(180, Math.min(parent.width - 24, Math.round(AppLauncherConfig.spotlightWidth * scaleRatio)))
                    height: Math.max(86, Math.min(136, Math.round(AppLauncherConfig.spotlightHeight * scaleRatio)))
                    anchors.centerIn: parent
                    radius: 10
                    color: root.theme.bgSurface
                    border.color: root.theme.accentPrimary
                    border.width: 1.5

                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 5

                        // Mock Spotlight Top Search Bar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 18
                            radius: 5
                            color: root.theme.bgBase
                            border.color: root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 4

                                Text {
                                    text: AppLauncherConfig.defaultMode === "command" ? "$" : "󰍉"
                                    font.family: root.font
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: root.theme.accentPrimary
                                }

                                Text {
                                    text: AppLauncherConfig.defaultMode === "command" ? "run shell command..." : "search applications..."
                                    font.family: root.font
                                    font.pixelSize: 8
                                    color: root.theme.textMuted
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: AppLauncherConfig.defaultMode === "command" ? "Command  Tab" : "Apps  Tab"
                                    font.family: root.font
                                    font.pixelSize: 7
                                    font.bold: true
                                    color: root.theme.textSecondary
                                }
                            }
                        }

                        // Mock Spotlight List Rows (Vertical results list)
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 3

                            // Row 1: Selected
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 4
                                color: root.theme.bgSelected

                                Rectangle {
                                    width: 2
                                    height: parent.height - 4
                                    radius: 1
                                    color: root.theme.accentPrimary
                                    anchors.left: parent.left
                                    anchors.leftMargin: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 7
                                    anchors.rightMargin: 6
                                    spacing: 5

                                    Rectangle {
                                        width: 10; height: 10; radius: 2; color: root.theme.accentPrimary; opacity: 0.9
                                        Text { anchors.centerIn: parent; text: "󰨞"; font.pixelSize: 7; color: root.theme.bgBase; font.family: root.font }
                                    }
                                    Column {
                                        Layout.fillWidth: true
                                        Text { text: "VSCodium"; font.pixelSize: 7; font.bold: true; color: root.theme.textPrimary; font.family: root.font }
                                        Text { text: "Text Editor"; font.pixelSize: 6; color: root.theme.textMuted; font.family: root.font }
                                    }
                                    Text { text: "󰋚"; font.pixelSize: 7; color: root.theme.accentPrimary; font.family: root.font }
                                }
                            }

                            // Row 2: Unselected
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 4
                                color: "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 7
                                    anchors.rightMargin: 6
                                    spacing: 5

                                    Rectangle {
                                        width: 10; height: 10; radius: 2; color: Qt.rgba(1, 1, 1, 0.12)
                                        Text { anchors.centerIn: parent; text: "󰈹"; font.pixelSize: 7; color: root.theme.textPrimary; font.family: root.font }
                                    }
                                    Column {
                                        Layout.fillWidth: true
                                        Text { text: "Brave"; font.pixelSize: 7; color: root.theme.textSecondary; font.family: root.font }
                                        Text { text: "Web Browser"; font.pixelSize: 6; color: root.theme.textMuted; font.family: root.font }
                                    }
                                }
                            }

                            // Row 3: Unselected
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 4
                                color: "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 7
                                    anchors.rightMargin: 6
                                    spacing: 5

                                    Rectangle {
                                        width: 10; height: 10; radius: 2; color: Qt.rgba(1, 1, 1, 0.12)
                                        Text { anchors.centerIn: parent; text: "󰓓"; font.pixelSize: 7; color: root.theme.textPrimary; font.family: root.font }
                                    }
                                    Column {
                                        Layout.fillWidth: true
                                        Text { text: "Steam"; font.pixelSize: 7; color: root.theme.textSecondary; font.family: root.font }
                                        Text { text: "Game Launcher"; font.pixelSize: 6; color: root.theme.textMuted; font.family: root.font }
                                    }
                                }
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // B. APP GRID MENU PREVIEW
                // -------------------------------------------------------------
                Rectangle {
                    id: mockGridBox
                    visible: root.previewMode === "grid"
                    width: Math.min(parent.width - 24, Math.max(170, AppLauncherConfig.gridColumns * (AppLauncherConfig.gridCellSize > 72 ? 30 : 25) + 32))
                    height: Math.min(136, 116)
                    anchors.centerIn: parent
                    radius: 10
                    color: root.theme.bgSurface
                    border.color: root.theme.accentPrimary
                    border.width: 1.5

                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 6

                        // Mock Search Bar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 18
                            radius: 5
                            color: root.theme.bgBase
                            border.color: root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 4

                                Text {
                                    text: "󰍉"
                                    font.family: root.font
                                    font.pixelSize: 9
                                    color: root.theme.accentPrimary
                                }

                                Text {
                                    text: "Search apps..."
                                    font.family: root.font
                                    font.pixelSize: 8
                                    color: root.theme.textMuted
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        // Mock App Grid cells
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 4

                            Repeater {
                                model: Math.min(8, AppLauncherConfig.gridColumns)
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 4
                                    color: index === 0 ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03)

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            width: AppLauncherConfig.gridCellSize > 72 ? 14 : 11
                                            height: AppLauncherConfig.gridCellSize > 72 ? 14 : 11
                                            radius: 3
                                            color: index === 0 ? root.theme.accentPrimary : root.theme.textMuted
                                            opacity: 0.8
                                        }
                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            width: 16
                                            height: 2
                                            radius: 1
                                            color: root.theme.textMuted
                                            opacity: 0.5
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Spotlight Window Sizing Section
    SectionCard {
        title: "Spotlight Runner Dimensions (Center Popup)"
        subtitle: "Adjust the popup box size when opened via shortcut or runner"
        contentMargins: 8
        contentSpacing: 0

        SettingSliderRow {
            title: "Spotlight Width"
            desc: "Width of the center spotlight application launcher"
            value: AppLauncherConfig.spotlightWidth
            minVal: 480
            maxVal: 840
            step: 10
            unit: "px"
            presets: [
                { label: "540px", val: 540 },
                { label: "620px (Default)", val: 620 },
                { label: "720px", val: 720 },
                { label: "800px", val: 800 }
            ]
            onValueModified: (val) => AppLauncherConfig.setSpotlightWidth(val)
        }

        RowDivider {}

        SettingSliderRow {
            title: "Spotlight Height"
            desc: "Maximum vertical height of the spotlight launcher window"
            value: AppLauncherConfig.spotlightHeight
            minVal: 360
            maxVal: 680
            step: 10
            unit: "px"
            presets: [
                { label: "420px", val: 420 },
                { label: "480px (Default)", val: 480 },
                { label: "540px", val: 540 },
                { label: "600px", val: 600 }
            ]
            onValueModified: (val) => AppLauncherConfig.setSpotlightHeight(val)
        }

        RowDivider {}

        // Default Mode Selector
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
                        text: "Default Opening Mode"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "Initial tab active when spotlight launcher opens"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                /* Segmented Track matching SettingSliderRow style */
                Rectangle {
                    id: modeSegmentTrack
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    implicitWidth: 260
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    readonly property int activeIdx: AppLauncherConfig.defaultMode === "command" ? 1 : 0
                    readonly property real cellWidth: (width - 6 - 3) / 2

                    /* Sliding Selection Pill */
                    Rectangle {
                        y: 3
                        height: parent.height - 6
                        width: modeSegmentTrack.cellWidth
                        x: 3 + modeSegmentTrack.activeIdx * (modeSegmentTrack.cellWidth + 3)
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
                                { id: "apps",    label: "Applications" },
                                { id: "command", label: "Execute Command" }
                            ]
                            delegate: Rectangle {
                                id: modeSegBtn
                                required property var modelData
                                required property int index
                                readonly property bool isSel: modeSegmentTrack.activeIdx === modeSegBtn.index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && modeSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: modeSegHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: modeSegBtn.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: modeSegBtn.isSel
                                    color: modeSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                    opacity: modeSegBtn.isSel || modeSegHover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        AppLauncherConfig.setDefaultMode(modeSegBtn.modelData.id);
                                        root.showToast("Default mode set to " + modeSegBtn.modelData.label);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // AppGrid Menu Sizing Section
    SectionCard {
        title: "App Grid Menu Dimensions (Bar Popup)"
        subtitle: "Configure the grid menu launched from the bar launcher button"
        contentMargins: 8
        contentSpacing: 0

        SettingSliderRow {
            title: "Grid Columns"
            desc: "Number of horizontal app columns per row in AppGrid"
            value: AppLauncherConfig.gridColumns
            minVal: 3
            maxVal: 8
            step: 1
            unit: ""
            presets: [
                { label: "4", val: 4 },
                { label: "5 (Default)", val: 5 },
                { label: "6", val: 6 },
                { label: "7", val: 7 }
            ]
            onValueModified: (val) => AppLauncherConfig.setGridColumns(val)
        }

        RowDivider {}

        SettingSliderRow {
            title: "Cell Size"
            desc: "Square dimensions of each application icon cell"
            value: AppLauncherConfig.gridCellSize
            minVal: 72
            maxVal: 128
            step: 4
            unit: "px"
            presets: [
                { label: "80px (Compact)", val: 80 },
                { label: "96px (Default)", val: 96 },
                { label: "112px (Large)", val: 112 }
            ]
            onValueModified: (val) => AppLauncherConfig.setGridCellSize(val)
        }
    }
}
