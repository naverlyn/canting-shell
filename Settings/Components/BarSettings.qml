/*
 * BarSettings.qml
 *
 * GNOME-style grouped card layout for customizing the Quickshell Top Bar.
 * Features:
 *   - General layout: visibility, top/bottom position, height presets, floating style, opacity
 *   - Multi-monitor display preference
 *   - Left section widget toggles: Applications, CPU, Temp, Memory, Disk
 *   - Center section: Active Window Title
 *   - Right section widget toggles: Workspaces, Weather, Clock, Seconds, Date, System Tray, Control Center
 *   - Real-time reactive updates via BarConfig singleton
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../bar"
import ".."

Item {
    id: root
    property var theme
    property string font

    /* Reusable Toggle Row Component */
    component SettingToggleRow: Item {
        id: toggleRow
        property string title: ""
        property string desc: ""
        property string icon: ""
        property color iconColor: root.theme.accentPrimary
        property bool checked: false
        property bool rowEnabled: true
        signal toggled(bool val)

        Layout.fillWidth: true
        height: 52
        opacity: rowEnabled ? 1.0 : 0.45

        Behavior on opacity { NumberAnimation { duration: 140 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Rectangle {
                visible: toggleRow.icon !== ""
                width: 32
                height: 32
                radius: 8
                color: Qt.rgba(toggleRow.iconColor.r, toggleRow.iconColor.g, toggleRow.iconColor.b, 0.12)
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: toggleRow.icon
                    font.family: root.font
                    font.pixelSize: 15
                    color: toggleRow.iconColor
                }
            }

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: toggleRow.title
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    visible: toggleRow.desc !== ""
                    text: toggleRow.desc
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillWidth: true }

            /* Toggle Switch matching MouseSettings */
            Rectangle {
                id: switchTrack
                width: 44
                height: 24
                radius: 12
                color: toggleRow.checked ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                Behavior on color { ColorAnimation { duration: 160 } }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: toggleRow.checked ? parent.width - width - 3 : 3
                    color: toggleRow.checked ? "#ffffff" : root.theme.textPrimary

                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: toggleRow.rowEnabled
                    cursorShape: toggleRow.rowEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: toggleRow.toggled(!toggleRow.checked)
                }
            }
        }
    }

    /* Main Scrollable View */
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 20

            // Header Row: Title & Reset Button on the right
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Bar Settings"
                    font.family: root.font
                    font.pixelSize: 20
                    font.bold: true
                    color: root.theme.textPrimary
                    Layout.alignment: Qt.AlignVCenter
                }

                // Spacer pushing the button all the way to the right
                Item { Layout.fillWidth: true }

                Rectangle {
                    id: resetBtn
                    implicitWidth: resetContent.implicitWidth + 24
                    height: 32
                    radius: 7
                    color: resetHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : (root.theme.bgSurface ?? Qt.rgba(1,1,1,0.04))
                    border.color: resetHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: resetHover }

                    RowLayout {
                        id: resetContent
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰑐"
                            font.family: root.font
                            font.pixelSize: 13
                            color: resetHover.hovered ? root.theme.accentPrimary : root.theme.textSecondary
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        Text {
                            text: "Reset to Default"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BarConfig.resetDefaults()
                    }
                }
            }

            /* Group 1: General & Layout */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "General"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: generalCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: generalCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        // Master Bar Visibility
                        SettingToggleRow {
                            title: "Show Top Bar"
                            desc: "Display the desktop status bar"
                            icon: "󰮲"
                            checked: BarConfig.barVisible
                            onToggled: (val) => {
                                BarConfig.barVisible = val;
                                BarConfig.saveConfig();
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        // Bar Position Selector
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 8
                                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.12)
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰞵"
                                        font.family: root.font
                                        font.pixelSize: 15
                                        color: root.theme.accentPrimary
                                    }
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Bar Position"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Dock to top or bottom edge of the screen"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 170
                                    height: 32
                                    radius: 7
                                    color: root.theme.bgBase ?? Qt.rgba(0,0,0,0.25)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        // Top Button
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: BarConfig.position === "top" ? root.theme.bgSelected : (posTopHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")
                                            border.color: BarConfig.position === "top" ? root.theme.accentPrimary : "transparent"
                                            border.width: BarConfig.position === "top" ? 1 : 0

                                            HoverHandler { id: posTopHover }

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 6

                                                Text {
                                                    text: "󰮲"
                                                    font.family: root.font
                                                    font.pixelSize: 12
                                                    color: BarConfig.position === "top" ? root.theme.accentPrimary : root.theme.textSecondary
                                                }

                                                Text {
                                                    text: "Top"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: BarConfig.position === "top"
                                                    color: BarConfig.position === "top" ? root.theme.textPrimary : root.theme.textSecondary
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    BarConfig.position = "top";
                                                    BarConfig.saveConfig();
                                                }
                                            }
                                        }

                                        // Bottom Button
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: BarConfig.position === "bottom" ? root.theme.bgSelected : (posBotHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")
                                            border.color: BarConfig.position === "bottom" ? root.theme.accentPrimary : "transparent"
                                            border.width: BarConfig.position === "bottom" ? 1 : 0

                                            HoverHandler { id: posBotHover }

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 6

                                                Text {
                                                    text: "󰞵"
                                                    font.family: root.font
                                                    font.pixelSize: 12
                                                    color: BarConfig.position === "bottom" ? root.theme.accentPrimary : root.theme.textSecondary
                                                }

                                                Text {
                                                    text: "Bottom"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: BarConfig.position === "bottom"
                                                    color: BarConfig.position === "bottom" ? root.theme.textPrimary : root.theme.textSecondary
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    BarConfig.position = "bottom";
                                                    BarConfig.saveConfig();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        // Bar Height Presets
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 8
                                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.12)
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰹞"
                                        font.family: root.font
                                        font.pixelSize: 15
                                        color: root.theme.accentPrimary
                                    }
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Bar Height"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Vertical thickness in pixels"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                RowLayout {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                    Repeater {
                                        model: [
                                            { label: "28px", value: 28 },
                                            { label: "32px", value: 32 },
                                            { label: "36px", value: 36 },
                                            { label: "40px", value: 40 }
                                        ]

                                        delegate: Rectangle {
                                            width: 52
                                            height: 28
                                            radius: 6
                                            readonly property bool isSelected: BarConfig.barHeight === modelData.value
                                            color: isSelected ? root.theme.bgSelected : (hHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : root.theme.bgBase)
                                            border.color: isSelected ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                            border.width: 1

                                            HoverHandler { id: hHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: isSelected
                                                color: isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    BarConfig.barHeight = modelData.value;
                                                    BarConfig.saveConfig();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        // Floating Style Toggle
                        SettingToggleRow {
                            title: "Floating Bar"
                            desc: "Add screen margins and rounded outer corners"
                            icon: "󰞵"
                            checked: BarConfig.floating
                            onToggled: (val) => {
                                BarConfig.floating = val;
                                BarConfig.saveConfig();
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        // Bar Opacity Slider
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 8
                                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.12)
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰃠"
                                        font.family: root.font
                                        font.pixelSize: 15
                                        color: root.theme.accentPrimary
                                    }
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: 160
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Bar Opacity"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Background transparency"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Rectangle {
                                    id: opacityTrack
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected
                                    Layout.alignment: Qt.AlignVCenter

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: Math.max(0, Math.min(parent.width, parent.width * BarConfig.barOpacity))
                                        color: root.theme.accentPrimary
                                    }

                                    Rectangle {
                                        width: opMouse.containsMouse || opMouse.pressed ? 16 : 14
                                        height: width
                                        radius: width / 2
                                        color: root.theme.accentPrimary
                                        border.color: root.theme.bgBase
                                        border.width: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(opacityTrack.width - width, (opacityTrack.width * BarConfig.barOpacity) - (width / 2)))

                                        Behavior on width { NumberAnimation { duration: 100 } }
                                    }

                                    MouseArea {
                                        id: opMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        function updateFromPos(xPos) {
                                            const frac = Math.max(0.1, Math.min(1.0, xPos / opacityTrack.width));
                                            BarConfig.barOpacity = Math.round(frac * 100) / 100;
                                            BarConfig.saveConfig();
                                        }
                                        onPositionChanged: (mouse) => { if (pressed) updateFromPos(mouse.x); }
                                        onClicked: (mouse) => updateFromPos(mouse.x)
                                    }
                                }

                                Text {
                                    text: Math.round(BarConfig.barOpacity * 100) + "%"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textSecondary
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        // Multi-Monitor Display
                        SettingToggleRow {
                            title: "Show on All Displays"
                            desc: "Display status bar across all connected monitors"
                            icon: "󰍹"
                            checked: BarConfig.allMonitors
                            onToggled: (val) => {
                                BarConfig.allMonitors = val;
                                BarConfig.saveConfig();
                            }
                        }
                    }
                }
            }

            /* Group 2: Left Section Widgets */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Left Section Widgets"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: leftCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: leftCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        SettingToggleRow {
                            title: "Applications Launcher"
                            desc: "Quick access button for the application launcher grid"
                            icon: "󰀻"
                            checked: BarConfig.showAppGrid
                            onToggled: (val) => {
                                BarConfig.showAppGrid = val;
                                BarConfig.saveConfig();
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        SettingToggleRow {
                            title: "CPU Monitor"
                            desc: "Live processor usage pill with details popup"
                            icon: "󰻠"
                            iconColor: root.theme.accentOrange ?? "#ff9e64"
                            checked: BarConfig.showCpu
                            onToggled: (val) => {
                                BarConfig.showCpu = val;
                                BarConfig.saveConfig();
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        SettingToggleRow {
                            title: "CPU Temperature"
                            desc: "Thermal sensor status pill with breakdown popup"
                            icon: "󰔏"
                            iconColor: root.theme.accentRed ?? "#f7768e"
                            checked: BarConfig.showTemp
                            onToggled: (val) => {
                                BarConfig.showTemp = val;
                                BarConfig.saveConfig();
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        SettingToggleRow {
                            title: "Memory (RAM)"
                            desc: "Live memory utilization percentage and process popup"
                            icon: ""
                            checked: BarConfig.showMemory
                            onToggled: (val) => {
                                BarConfig.showMemory = val;
                                BarConfig.saveConfig();
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        SettingToggleRow {
                            title: "Disk Usage"
                            desc: "Root partition storage utilization pill"
                            icon: ""
                            checked: BarConfig.showDisk
                            onToggled: (val) => {
                                BarConfig.showDisk = val;
                                BarConfig.saveConfig();
                            }
                        }
                    }
                }
            }

            /* Group 3: Center Section Widget */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Center Section"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: centerCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: centerCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        SettingToggleRow {
                            title: "Active Window Title"
                            desc: "Show the title of the currently focused window in the center"
                            icon: "󰖲"
                            checked: BarConfig.showWindowTitle
                            onToggled: (val) => {
                                BarConfig.showWindowTitle = val;
                                BarConfig.saveConfig();
                            }
                        }
                    }
                }
            }

            /* Group 4: Right Section Widgets */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Right Section Widgets"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: rightCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: rightCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        SettingToggleRow {
                            title: "Workspaces"
                            desc: "Desktop workspace switcher pills with active and urgent indicators"
                            icon: "󰮲"
                            checked: BarConfig.showWorkspaces
                            onToggled: (val) => {
                                BarConfig.showWorkspaces = val;
                                BarConfig.saveConfig();
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        SettingToggleRow {
                            title: "Weather Info"
                            desc: "Live weather conditions and temperature readout"
                            icon: "󰖐"
                            checked: BarConfig.showWeather
                            onToggled: (val) => {
                                BarConfig.showWeather = val;
                                BarConfig.saveConfig();
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        SettingToggleRow {
                            title: "Clock & Calendar"
                            desc: "Time widget pill with interactive calendar popup on hover"
                            icon: "󰥔"
                            checked: BarConfig.showTime
                            onToggled: (val) => {
                                BarConfig.showTime = val;
                                BarConfig.saveConfig();
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        SettingToggleRow {
                            title: "Show Seconds in Clock"
                            desc: "Display precision seconds format (hh:mm:ss)"
                            icon: "󱑎"
                            rowEnabled: BarConfig.showTime
                            checked: BarConfig.showSeconds
                            onToggled: (val) => {
                                BarConfig.showSeconds = val;
                                BarConfig.saveConfig();
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        SettingToggleRow {
                            title: "Show Date in Clock"
                            desc: "Display weekday and date alongside the time"
                            icon: "󰸗"
                            rowEnabled: BarConfig.showTime
                            checked: BarConfig.showDate
                            onToggled: (val) => {
                                BarConfig.showDate = val;
                                BarConfig.saveConfig();
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        SettingToggleRow {
                            title: "System Tray"
                            desc: "Background application status indicators and context menus"
                            icon: "󰚥"
                            checked: BarConfig.showTray
                            onToggled: (val) => {
                                BarConfig.showTray = val;
                                BarConfig.saveConfig();
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        SettingToggleRow {
                            title: "Control Center Button"
                            desc: "Quick settings gear toggle for volume, mic, wifi, and bluetooth"
                            icon: ""
                            checked: BarConfig.showControlCenter
                            onToggled: (val) => {
                                BarConfig.showControlCenter = val;
                                BarConfig.saveConfig();
                            }
                        }
                    }
                }
            }
        }
    }
}
