/*
 * ControlCenterSettings.qml
 *
 * Configures Control Center layout, card visibility, panel width,
 * and quick toggle tiles (Wi-Fi, Night Light, Caffeine, DND, Mic, Screenshot, etc.).
 * Inspired by GNOME Settings / Libadwaita (AdwPreferencesPage, AdwPreferencesGroup, AdwActionRow).
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../bar"
import "../../ControlCenter"
import ".."

Item {
    id: root
    property var theme
    property string font: "Hack Nerd Font"

    readonly property int labelColWidth: 150
    readonly property int btnHeight: 32
    readonly property int btnRadius: 6

    Flickable {
        id: ccFlickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !widthMouse.pressed

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 20

            // Page Header
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                Text {
                    text: "Control Center"
                    font.family: root.font
                    font.pixelSize: 20
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Customize quick settings toggles, section visibility, and layout"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textSecondary
                }
            }

            /* ========================================================= */
            /* 1. PANEL METRICS & DIMENSIONS                             */
            /* ========================================================= */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Dimensions & Placement"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: dimCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: dimCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        // Row: Panel Width Slider
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: root.labelColWidth
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Panel Width"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Flyout horizontal size"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                // Interactive Slider Track
                                Rectangle {
                                    id: widthSeekTrack
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)
                                    Layout.alignment: Qt.AlignVCenter

                                    readonly property real minVal: 280.0
                                    readonly property real maxVal: 440.0
                                    readonly property real frac: Math.max(0.0, Math.min(1.0, (ControlCenterConfig.panelWidth - minVal) / (maxVal - minVal)))

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: Math.max(0, Math.min(parent.width, parent.width * widthSeekTrack.frac))
                                        color: root.theme.accentPrimary

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: widthMouse.pressed ? 0 : 140
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    // Outer halo ring
                                    Rectangle {
                                        anchors.centerIn: widthKnob
                                        width: widthKnob.width + (widthMouse.pressed ? 8 : (widthMouse.containsMouse ? 6 : 0))
                                        height: width
                                        radius: width / 2
                                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, widthMouse.pressed ? 0.35 : (widthMouse.containsMouse ? 0.2 : 0.0))
                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    // Solid knob ball
                                    Rectangle {
                                        id: widthKnob
                                        width: 16
                                        height: 16
                                        radius: 8
                                        color: "#ffffff"
                                        border.color: root.theme.accentPrimary
                                        border.width: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(parent.width - width, Math.round(parent.width * widthSeekTrack.frac) - (width / 2)))

                                        Behavior on x {
                                            NumberAnimation {
                                                duration: widthMouse.pressed ? 0 : 140
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: widthMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        preventStealing: true

                                        function updateFromMouse(mouseX) {
                                            const clampedX = Math.max(0, Math.min(widthSeekTrack.width, mouseX));
                                            const ratio = clampedX / widthSeekTrack.width;
                                            const newVal = Math.round(widthSeekTrack.minVal + ratio * (widthSeekTrack.maxVal - widthSeekTrack.minVal));
                                            ControlCenterConfig.setPanelWidth(newVal);
                                        }

                                        onPressed: (mouse) => updateFromMouse(mouse.x)
                                        onPositionChanged: (mouse) => {
                                            if (pressed) updateFromMouse(mouse.x);
                                        }
                                    }
                                }

                                Text {
                                    text: ControlCenterConfig.panelWidth + " px"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.accentPrimary
                                    Layout.preferredWidth: 60
                                    horizontalAlignment: Text.AlignRight
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }
                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        // Row: Header & Profile
                        Item {
                            Layout.fillWidth: true
                            height: 48

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Header & Profile"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Top bar showing user profile, clock, battery, and power button"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle {
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: ControlCenterConfig.showHeader ? root.theme.accentPrimary : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3))
                                    border.color: ControlCenterConfig.showHeader ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: ControlCenterConfig.showHeader ? (parent.width - width - 3) : 3
                                        color: ControlCenterConfig.showHeader ? (root.theme.bgBase ?? "#ffffff") : root.theme.textPrimary
                                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ControlCenterConfig.showHeader = !ControlCenterConfig.showHeader
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        // Row: View Switcher
                        Item {
                            Layout.fillWidth: true
                            height: 48

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "View Switcher"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Toggle tabs between Control Center and Notifications view"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle {
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: ControlCenterConfig.showViewSwitcher ? root.theme.accentPrimary : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3))
                                    border.color: ControlCenterConfig.showViewSwitcher ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: ControlCenterConfig.showViewSwitcher ? (parent.width - width - 3) : 3
                                        color: ControlCenterConfig.showViewSwitcher ? (root.theme.bgBase ?? "#ffffff") : root.theme.textPrimary
                                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ControlCenterConfig.showViewSwitcher = !ControlCenterConfig.showViewSwitcher
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        // Row: Auto-Hide Media Player
                        Item {
                            Layout.fillWidth: true
                            height: 48

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Auto-Hide Media Player"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Automatically hide media widget when no audio player is active"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle {
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: ControlCenterConfig.mediaAutoHide ? root.theme.accentPrimary : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3))
                                    border.color: ControlCenterConfig.mediaAutoHide ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: ControlCenterConfig.mediaAutoHide ? (parent.width - width - 3) : 3
                                        color: ControlCenterConfig.mediaAutoHide ? (root.theme.bgBase ?? "#ffffff") : root.theme.textPrimary
                                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ControlCenterConfig.mediaAutoHide = !ControlCenterConfig.mediaAutoHide
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* ========================================================= */
            /* 2. MODULAR PANELS & BUILDING BLOCKS                       */
            /* ========================================================= */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                // Top Controls Bar: Panel Count Selector & Layout Orientation
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 16

                        // Panel Count Header
                        Text {
                            text: "Control Center Panels:"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        // Panel Count Buttons: [2 Panels] [3 Panels] [4 Panels] [5 Panels]
                        RowLayout {
                            spacing: 8

                            Repeater {
                                model: [2, 3, 4, 5]
                                delegate: Rectangle {
                                    id: pCountBtn
                                    required property int modelData
                                    readonly property bool isCurrent: ControlCenterConfig.enabledCards.length === modelData
                                    implicitWidth: pCountTxt.implicitWidth + 18
                                    implicitHeight: 30
                                    color: "transparent"

                                    HoverHandler { id: pCountHover }

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        height: 2
                                        radius: 1
                                        width: pCountBtn.isCurrent ? parent.width - 6 : (pCountHover.hovered ? parent.width * 0.5 : 0)
                                        opacity: pCountBtn.isCurrent ? 1.0 : (pCountHover.hovered ? 0.5 : 0.0)
                                        color: pCountBtn.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary

                                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                        Behavior on opacity { NumberAnimation { duration: 140 } }
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    Text {
                                        id: pCountTxt
                                        anchors.centerIn: parent
                                        text: pCountBtn.modelData + " Panels"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: pCountBtn.isCurrent
                                        color: pCountBtn.isCurrent
                                            ? root.theme.accentPrimary
                                            : (pCountHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ControlCenterConfig.setPanelCount(pCountBtn.modelData)
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // MPRIS Style Selector
                        RowLayout {
                            spacing: 6

                            Text {
                                text: "MPRIS:"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textSecondary
                            }

                            // Compact Square Pill
                            Rectangle {
                                implicitWidth: mCompactTxt.implicitWidth + 14
                                height: 28
                                radius: 6
                                color: ControlCenterConfig.mediaWidgetStyle === "compact"
                                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.18)
                                    : (mCompactMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                                border.color: ControlCenterConfig.mediaWidgetStyle === "compact" ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12))
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                Text {
                                    id: mCompactTxt
                                    anchors.centerIn: parent
                                    text: "󰝚 Compact"
                                    font.family: root.font
                                    font.pixelSize: 10
                                    font.bold: ControlCenterConfig.mediaWidgetStyle === "compact"
                                    color: ControlCenterConfig.mediaWidgetStyle === "compact" ? root.theme.accentPrimary : root.theme.textSecondary
                                }

                                MouseArea {
                                    id: mCompactMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ControlCenterConfig.setMediaWidgetStyle("compact")
                                }
                            }

                            // Full Banner Pill
                            Rectangle {
                                implicitWidth: mFullTxt.implicitWidth + 14
                                height: 28
                                radius: 6
                                color: ControlCenterConfig.mediaWidgetStyle === "full"
                                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.18)
                                    : (mFullMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                                border.color: ControlCenterConfig.mediaWidgetStyle === "full" ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12))
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                Text {
                                    id: mFullTxt
                                    anchors.centerIn: parent
                                    text: "󰐊 Full"
                                    font.family: root.font
                                    font.pixelSize: 10
                                    font.bold: ControlCenterConfig.mediaWidgetStyle === "full"
                                    color: ControlCenterConfig.mediaWidgetStyle === "full" ? root.theme.accentPrimary : root.theme.textSecondary
                                }

                                MouseArea {
                                    id: mFullMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ControlCenterConfig.setMediaWidgetStyle("full")
                                }
                            }
                        }

                        // Orientation Switcher (Vertical / Horizontal)
                        RowLayout {
                            spacing: 6

                            Text {
                                text: "Layout:"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textSecondary
                            }

                            // Vertical Pill
                            Rectangle {
                                implicitWidth: vertTxt.implicitWidth + 14
                                height: 28
                                radius: 6
                                color: ControlCenterConfig.panelLayout === "vertical"
                                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.18)
                                    : (vertMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                                border.color: ControlCenterConfig.panelLayout === "vertical" ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12))
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                Text {
                                    id: vertTxt
                                    anchors.centerIn: parent
                                    text: "󰝘 Vertical"
                                    font.family: root.font
                                    font.pixelSize: 10
                                    font.bold: ControlCenterConfig.panelLayout === "vertical"
                                    color: ControlCenterConfig.panelLayout === "vertical" ? root.theme.accentPrimary : root.theme.textSecondary
                                }

                                MouseArea {
                                    id: vertMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ControlCenterConfig.setPanelLayout("vertical")
                                }
                            }

                            // Horizontal Pill
                            Rectangle {
                                implicitWidth: horizTxt.implicitWidth + 14
                                height: 28
                                radius: 6
                                color: ControlCenterConfig.panelLayout === "horizontal"
                                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.18)
                                    : (horizMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                                border.color: ControlCenterConfig.panelLayout === "horizontal" ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12))
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                Text {
                                    id: horizTxt
                                    anchors.centerIn: parent
                                    text: "󰝙 Horizontal"
                                    font.family: root.font
                                    font.pixelSize: 10
                                    font.bold: ControlCenterConfig.panelLayout === "horizontal"
                                    color: ControlCenterConfig.panelLayout === "horizontal" ? root.theme.accentPrimary : root.theme.textSecondary
                                }

                                MouseArea {
                                    id: horizMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ControlCenterConfig.setPanelLayout("horizontal")
                                }
                            }
                        }
                    }
                }

                // Modular Multi-Column Panels Grid
                GridLayout {
                    id: ccPanelsGrid
                    Layout.fillWidth: true
                    columns: ControlCenterConfig.enabledCards.length > 3 ? 2 : Math.max(1, ControlCenterConfig.enabledCards.length)
                    columnSpacing: 12
                    rowSpacing: 12

                    Repeater {
                        model: ControlCenterConfig.enabledCards

                        delegate: Rectangle {
                            id: panelColCard
                            required property var modelData
                            required property int index
                            readonly property string cardId: modelData.id

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignTop
                            implicitHeight: panelColContent.implicitHeight + 20
                            radius: 12
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1

                            ColumnLayout {
                                id: panelColContent
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: 10
                                }
                                spacing: 10

                                // Top Header Bar of Panel Column
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: 8
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 6
                                        spacing: 8

                                        // Panel Icon Badge
                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 5
                                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.16)
                                            border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.3)
                                            border.width: 1
                                            Layout.alignment: Qt.AlignVCenter

                                            Text {
                                                anchors.centerIn: parent
                                                text: panelColCard.modelData.icon ?? "󰒓"
                                                font.family: root.font
                                                font.pixelSize: 12
                                                color: root.theme.accentPrimary
                                            }
                                        }

                                        // Panel Title
                                        Text {
                                            text: "Panel " + (panelColCard.index + 1) + ": " + (panelColCard.modelData.label ?? "")
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.textPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        // Move Left ◀
                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 5
                                            color: pMoveLeftMouse.containsMouse ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12) : "transparent"
                                            opacity: panelColCard.index > 0 ? 1.0 : 0.25
                                            Layout.alignment: Qt.AlignVCenter

                                            Text {
                                                anchors.centerIn: parent
                                                text: "◀"
                                                font.family: root.font
                                                font.pixelSize: 9
                                                color: root.theme.textPrimary
                                            }

                                            MouseArea {
                                                id: pMoveLeftMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: panelColCard.index > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                enabled: panelColCard.index > 0
                                                preventStealing: true
                                                onClicked: ControlCenterConfig.moveEnabledCard(panelColCard.index, panelColCard.index - 1)
                                            }
                                        }

                                        // Move Right ▶
                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 5
                                            color: pMoveRightMouse.containsMouse ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12) : "transparent"
                                            opacity: panelColCard.index < (ControlCenterConfig.enabledCards.length - 1) ? 1.0 : 0.25
                                            Layout.alignment: Qt.AlignVCenter

                                            Text {
                                                anchors.centerIn: parent
                                                text: "▶"
                                                font.family: root.font
                                                font.pixelSize: 9
                                                color: root.theme.textPrimary
                                            }

                                            MouseArea {
                                                id: pMoveRightMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: panelColCard.index < (ControlCenterConfig.enabledCards.length - 1) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                enabled: panelColCard.index < (ControlCenterConfig.enabledCards.length - 1)
                                                preventStealing: true
                                                onClicked: ControlCenterConfig.moveEnabledCard(panelColCard.index, panelColCard.index + 1)
                                            }
                                        }

                                        // Remove ✕
                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 5
                                            color: pRemoveMouse.containsMouse ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.22) : Qt.rgba(1, 1, 1, 0.05)
                                            border.color: pRemoveMouse.containsMouse ? root.theme.accentRed : "transparent"
                                            border.width: 1
                                            Layout.alignment: Qt.AlignVCenter

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✕"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: pRemoveMouse.containsMouse ? root.theme.accentRed : root.theme.textMuted
                                            }

                                            MouseArea {
                                                id: pRemoveMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                preventStealing: true
                                                onClicked: ControlCenterConfig.setCardVisible(panelColCard.cardId, false)
                                            }
                                        }
                                    }
                                }

                                /* ------------------------------------------------------------- */
                                /* ------------------------------------------------------------- */
                                /* A. QUICK SETTINGS PANEL (GROUPED & UNGROUPED TILES)          */
                                /* ------------------------------------------------------------- */
                                ColumnLayout {
                                    visible: panelColCard.cardId === "quickSettings"
                                    Layout.fillWidth: true
                                    spacing: 10

                                    // Grouping Mode Toggle Row
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 38
                                        radius: 7
                                        color: root.theme.bgBase
                                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            ColumnLayout {
                                                spacing: 1
                                                Layout.fillWidth: true

                                                Text {
                                                    text: "2x2 Connectivity Group"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: root.theme.textPrimary
                                                }

                                                Text {
                                                    text: "Group 4 tiles into a squircle card (iOS/Android style)"
                                                    font.family: root.font
                                                    font.pixelSize: 9
                                                    color: root.theme.textSecondary
                                                }
                                            }

                                            // Switch Toggle
                                            Rectangle {
                                                width: 36
                                                height: 20
                                                radius: 10
                                                color: ControlCenterConfig.groupTilesEnabled ? root.theme.accentPrimary : (root.theme.bgSurface ?? Qt.rgba(0, 0, 0, 0.3))
                                                border.color: ControlCenterConfig.groupTilesEnabled ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15))
                                                border.width: 1

                                                Rectangle {
                                                    width: 14
                                                    height: 14
                                                    radius: 7
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    x: ControlCenterConfig.groupTilesEnabled ? (parent.width - width - 3) : 3
                                                    color: ControlCenterConfig.groupTilesEnabled ? (root.theme.bgBase ?? "#ffffff") : root.theme.textPrimary
                                                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: ControlCenterConfig.setGroupTilesEnabled(!ControlCenterConfig.groupTilesEnabled)
                                                }
                                            }
                                        }
                                    }

                                    // GROUP 1: 4-Tile Connectivity Container (Shown if grouping enabled)
                                    ColumnLayout {
                                        visible: ControlCenterConfig.groupTilesEnabled
                                        Layout.fillWidth: true
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                text: "Group 1: Connectivity"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.accentPrimary
                                            }

                                            Text {
                                                text: "(" + ControlCenterConfig.groupedTiles.length + "/4 tiles · 2x2 squircle)"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                                Layout.fillWidth: true
                                            }
                                        }

                                        // 2x2 Grouped Tiles Grid Preview
                                        GridLayout {
                                            Layout.fillWidth: true
                                            columns: 2
                                            columnSpacing: 6
                                            rowSpacing: 6

                                            Repeater {
                                                model: ControlCenterConfig.groupedTiles

                                                delegate: Rectangle {
                                                    id: gTileCard
                                                    required property var modelData
                                                    required property int index

                                                    Layout.fillWidth: true
                                                    height: 44
                                                    radius: 8
                                                    color: root.theme.bgBase
                                                    border.color: root.theme.accentPrimary
                                                    border.width: 1

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 6
                                                        anchors.rightMargin: 6
                                                        spacing: 6

                                                        Rectangle {
                                                            width: 28
                                                            height: 28
                                                            radius: 6
                                                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.18)
                                                            Layout.alignment: Qt.AlignVCenter

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: gTileCard.modelData.icon ?? "󰒓"
                                                                font.family: root.font
                                                                font.pixelSize: 13
                                                                color: root.theme.accentPrimary
                                                            }
                                                        }

                                                        ColumnLayout {
                                                            spacing: 1
                                                            Layout.fillWidth: true
                                                            Layout.alignment: Qt.AlignVCenter

                                                            Text {
                                                                text: gTileCard.modelData.label ?? ""
                                                                font.family: root.font
                                                                font.pixelSize: 10
                                                                font.bold: true
                                                                color: root.theme.textPrimary
                                                                elide: Text.ElideRight
                                                                Layout.fillWidth: true
                                                            }

                                                            Text {
                                                                text: "Grouped"
                                                                font.family: root.font
                                                                font.pixelSize: 9
                                                                color: root.theme.accentPrimary
                                                            }
                                                        }

                                                        // Ungroup Button
                                                        Rectangle {
                                                            width: 20
                                                            height: 20
                                                            radius: 4
                                                            color: gUngroupMouse.containsMouse ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.22) : Qt.rgba(1, 1, 1, 0.06)
                                                            border.color: gUngroupMouse.containsMouse ? root.theme.accentRed : "transparent"
                                                            border.width: 1
                                                            Layout.alignment: Qt.AlignVCenter

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "✕"
                                                                font.pixelSize: 9
                                                                font.bold: true
                                                                color: gUngroupMouse.containsMouse ? root.theme.accentRed : root.theme.textMuted
                                                            }

                                                            MouseArea {
                                                                id: gUngroupMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: ControlCenterConfig.removeTileFromGroup(gTileCard.modelData.id)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // UNGROUPED TILES SECTION
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                text: ControlCenterConfig.groupTilesEnabled ? "Ungrouped Standalone Tiles" : "Placed Quick Tiles"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: root.theme.textPrimary
                                            }

                                            Text {
                                                text: "(" + (ControlCenterConfig.groupTilesEnabled ? ControlCenterConfig.ungroupedTiles.length : ControlCenterConfig.enabledTiles.length) + " tiles · 2-col)"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                color: root.theme.textMuted
                                                Layout.fillWidth: true
                                            }
                                        }

                                        // 2-Column Grid of Ungrouped Tiles
                                        GridLayout {
                                            Layout.fillWidth: true
                                            columns: 2
                                            columnSpacing: 6
                                            rowSpacing: 6
                                            visible: (ControlCenterConfig.groupTilesEnabled ? ControlCenterConfig.ungroupedTiles.length : ControlCenterConfig.enabledTiles.length) > 0

                                            Repeater {
                                                model: ControlCenterConfig.groupTilesEnabled ? ControlCenterConfig.ungroupedTiles : ControlCenterConfig.enabledTiles

                                                delegate: Rectangle {
                                                    id: tileCard
                                                    required property var modelData
                                                    required property int index

                                                    Layout.fillWidth: true
                                                    height: 42
                                                    radius: 7
                                                    color: tileHover.hovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08) : root.theme.bgBase
                                                    border.color: tileHover.hovered ? (root.theme.accentPrimary ?? Qt.rgba(1, 1, 1, 0.15)) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                                    border.width: 1

                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                                    HoverHandler { id: tileHover }

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 6
                                                        anchors.rightMargin: 6
                                                        spacing: 6

                                                        // Tile Icon Badge
                                                        Rectangle {
                                                            width: 26
                                                            height: 26
                                                            radius: 5
                                                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.14)
                                                            border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.28)
                                                            border.width: 1
                                                            Layout.alignment: Qt.AlignVCenter

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: tileCard.modelData.icon ?? "󰒓"
                                                                font.family: root.font
                                                                font.pixelSize: 12
                                                                color: root.theme.accentPrimary
                                                            }
                                                        }

                                                        // Tile Name
                                                        Text {
                                                            text: tileCard.modelData.label ?? ""
                                                            font.family: root.font
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: root.theme.textPrimary
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                        }

                                                        // Add to Group Button (shown if grouping enabled and group has room)
                                                        Rectangle {
                                                            visible: ControlCenterConfig.groupTilesEnabled && ControlCenterConfig.groupedTiles.length < 4
                                                            width: 18
                                                            height: 18
                                                            radius: 4
                                                            color: gAddMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.25) : Qt.rgba(1, 1, 1, 0.06)
                                                            border.color: gAddMouse.containsMouse ? root.theme.accentPrimary : "transparent"
                                                            border.width: 1
                                                            Layout.alignment: Qt.AlignVCenter

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "⊞"
                                                                font.pixelSize: 9
                                                                color: root.theme.accentPrimary
                                                            }

                                                            MouseArea {
                                                                id: gAddMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: ControlCenterConfig.addTileToGroup(tileCard.modelData.id)
                                                            }
                                                        }

                                                        // Reorder ◀
                                                        Rectangle {
                                                            width: 18
                                                            height: 18
                                                            radius: 4
                                                            color: tMoveLeftMouse.containsMouse ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12) : "transparent"
                                                            opacity: tileCard.index > 0 ? 1.0 : 0.25
                                                            Layout.alignment: Qt.AlignVCenter

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "◀"
                                                                font.family: root.font
                                                                font.pixelSize: 8
                                                                color: root.theme.textPrimary
                                                            }

                                                            MouseArea {
                                                                id: tMoveLeftMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: tileCard.index > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                                enabled: tileCard.index > 0
                                                                preventStealing: true
                                                                onClicked: ControlCenterConfig.moveEnabledTile(tileCard.index, tileCard.index - 1)
                                                            }
                                                        }

                                                        // Reorder ▶
                                                        Rectangle {
                                                            width: 18
                                                            height: 18
                                                            radius: 4
                                                            color: tMoveRightMouse.containsMouse ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12) : "transparent"
                                                            opacity: tileCard.index < ((ControlCenterConfig.groupTilesEnabled ? ControlCenterConfig.ungroupedTiles.length : ControlCenterConfig.enabledTiles.length) - 1) ? 1.0 : 0.25
                                                            Layout.alignment: Qt.AlignVCenter

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "▶"
                                                                font.family: root.font
                                                                font.pixelSize: 8
                                                                color: root.theme.textPrimary
                                                            }

                                                            MouseArea {
                                                                id: tMoveRightMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: tileCard.index < ((ControlCenterConfig.groupTilesEnabled ? ControlCenterConfig.ungroupedTiles.length : ControlCenterConfig.enabledTiles.length) - 1) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                                enabled: tileCard.index < ((ControlCenterConfig.groupTilesEnabled ? ControlCenterConfig.ungroupedTiles.length : ControlCenterConfig.enabledTiles.length) - 1)
                                                                preventStealing: true
                                                                onClicked: ControlCenterConfig.moveEnabledTile(tileCard.index, tileCard.index + 1)
                                                            }
                                                        }

                                                        // Remove ✕
                                                        Rectangle {
                                                            width: 18
                                                            height: 18
                                                            radius: 4
                                                            color: tRemoveMouse.containsMouse ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.22) : Qt.rgba(1, 1, 1, 0.05)
                                                            border.color: tRemoveMouse.containsMouse ? root.theme.accentRed : "transparent"
                                                            border.width: 1
                                                            Layout.alignment: Qt.AlignVCenter

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: "✕"
                                                                font.pixelSize: 9
                                                                font.bold: true
                                                                color: tRemoveMouse.containsMouse ? root.theme.accentRed : root.theme.textMuted
                                                            }

                                                            MouseArea {
                                                                id: tRemoveMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                preventStealing: true
                                                                onClicked: ControlCenterConfig.removeTile(tileCard.modelData.id)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Divider inside Quick Settings Panel
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Qt.rgba(1, 1, 1, 0.06)
                                    }

                                    // Available Quick Settings Pool Header (matches user's sketch)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: "Available Quick Settings"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.accentPrimary
                                        }

                                        Text {
                                            text: "(" + ControlCenterConfig.unassignedTiles.length + " left)"
                                            font.family: root.font
                                            font.pixelSize: 10
                                            color: root.theme.textMuted
                                            Layout.fillWidth: true
                                        }
                                    }

                                    // Available Quick Settings Chips Flow
                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        visible: ControlCenterConfig.unassignedTiles.length > 0

                                        Repeater {
                                            model: ControlCenterConfig.unassignedTiles

                                            delegate: Rectangle {
                                                id: qPoolChip
                                                required property var modelData
                                                implicitWidth: qChipRow.implicitWidth + 14
                                                height: 28
                                                radius: 6
                                                color: qChipMouse.containsMouse
                                                    ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12)
                                                    : root.theme.bgBase
                                                border.color: qChipMouse.containsMouse
                                                    ? root.theme.accentPrimary
                                                    : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 120 } }
                                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                                RowLayout {
                                                    id: qChipRow
                                                    anchors.centerIn: parent
                                                    spacing: 4

                                                    Text {
                                                        text: "+"
                                                        font.family: root.font
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: root.theme.accentPrimary
                                                    }

                                                    Text {
                                                        text: qPoolChip.modelData.icon ?? ""
                                                        font.family: root.font
                                                        font.pixelSize: 11
                                                        color: root.theme.textPrimary
                                                    }

                                                    Text {
                                                        text: qPoolChip.modelData.label ?? ""
                                                        font.family: root.font
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                        color: root.theme.textPrimary
                                                    }
                                                }

                                                MouseArea {
                                                    id: qChipMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    preventStealing: true
                                                    onClicked: ControlCenterConfig.addTile(qPoolChip.modelData.id)
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        visible: ControlCenterConfig.unassignedTiles.length === 0
                                        Layout.fillWidth: true
                                        text: "(All quick setting tiles placed)"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textMuted
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                /* ------------------------------------------------------------- */
                                /* B. VOLUME & SOUND PANEL PREVIEW                               */
                                /* ------------------------------------------------------------- */
                                ColumnLayout {
                                    visible: panelColCard.cardId === "audio"
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Text {
                                        text: "Speaker & Microphone Volume Control"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        Layout.fillWidth: true
                                    }

                                    // Speaker Slider Preview
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: "󰕾 Speaker Volume"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.theme.textPrimary
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: "75%"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.theme.accentPrimary
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 6
                                            radius: 3
                                            color: root.theme.bgBase
                                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                                            border.width: 1

                                            Rectangle {
                                                height: parent.height
                                                width: parent.width * 0.75
                                                radius: parent.radius
                                                color: root.theme.accentPrimary
                                            }
                                        }
                                    }

                                    // Microphone Slider Preview
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: "󰍬 Microphone Volume"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.theme.textPrimary
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: "60%"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.theme.accentPrimary
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 6
                                            radius: 3
                                            color: root.theme.bgBase
                                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                                            border.width: 1

                                            Rectangle {
                                                height: parent.height
                                                width: parent.width * 0.60
                                                radius: parent.radius
                                                color: root.theme.accentPrimary
                                            }
                                        }
                                    }

                                    // Device Status Note
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 30
                                        radius: 6
                                        color: root.theme.bgBase
                                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 6

                                            Text {
                                                text: "󰋋"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                color: root.theme.accentPrimary
                                            }

                                            Text {
                                                text: "Outputs: Speaker, Headphones · Live dropdown in flyout"
                                                font.family: root.font
                                                font.pixelSize: 9
                                                color: root.theme.textMuted
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }
                                }

                                /* ------------------------------------------------------------- */
                                /* C. MEDIA PLAYER PANEL PREVIEW                                 */
                                /* ------------------------------------------------------------- */
                                ColumnLayout {
                                    visible: panelColCard.cardId === "media"
                                    Layout.fillWidth: true
                                    spacing: 10

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: "MPRIS Player Style:"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.textPrimary
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Style Toggle: Compact vs Full
                                        RowLayout {
                                            spacing: 4

                                            Rectangle {
                                                implicitWidth: colMedCompTxt.implicitWidth + 12
                                                height: 24
                                                radius: 4
                                                color: ControlCenterConfig.mediaWidgetStyle === "compact"
                                                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.2)
                                                    : (colMedCompMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                                                border.color: ControlCenterConfig.mediaWidgetStyle === "compact" ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                                border.width: 1

                                                Text {
                                                    id: colMedCompTxt
                                                    anchors.centerIn: parent
                                                    text: "󰝚 Compact"
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                    font.bold: ControlCenterConfig.mediaWidgetStyle === "compact"
                                                    color: ControlCenterConfig.mediaWidgetStyle === "compact" ? root.theme.accentPrimary : root.theme.textSecondary
                                                }

                                                MouseArea {
                                                    id: colMedCompMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: ControlCenterConfig.setMediaWidgetStyle("compact")
                                                }
                                            }

                                            Rectangle {
                                                implicitWidth: colMedFullTxt.implicitWidth + 12
                                                height: 24
                                                radius: 4
                                                color: ControlCenterConfig.mediaWidgetStyle === "full"
                                                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.2)
                                                    : (colMedFullMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                                                border.color: ControlCenterConfig.mediaWidgetStyle === "full" ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                                border.width: 1

                                                Text {
                                                    id: colMedFullTxt
                                                    anchors.centerIn: parent
                                                    text: "󰐊 Full"
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                    font.bold: ControlCenterConfig.mediaWidgetStyle === "full"
                                                    color: ControlCenterConfig.mediaWidgetStyle === "full" ? root.theme.accentPrimary : root.theme.textSecondary
                                                }

                                                MouseArea {
                                                    id: colMedFullMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: ControlCenterConfig.setMediaWidgetStyle("full")
                                                }
                                            }
                                        }
                                    }

                                    // Compact Style Preview Card
                                    Rectangle {
                                        visible: ControlCenterConfig.mediaWidgetStyle === "compact"
                                        Layout.fillWidth: true
                                        implicitHeight: compactPreviewCol.implicitHeight + 16
                                        radius: 10
                                        color: root.theme.bgBase
                                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 1

                                        ColumnLayout {
                                            id: compactPreviewCol
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 6

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Rectangle {
                                                    width: 38
                                                    height: 38
                                                    radius: 8
                                                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.18)
                                                    border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.35)
                                                    border.width: 1

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "󰝚"
                                                        font.family: root.font
                                                        font.pixelSize: 16
                                                        color: root.theme.accentPrimary
                                                    }
                                                }

                                                ColumnLayout {
                                                    spacing: 1
                                                    Layout.fillWidth: true

                                                    Text {
                                                        text: "Starlight"
                                                        font.family: root.font
                                                        font.pixelSize: 11
                                                        font.bold: true
                                                        color: root.theme.textPrimary
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        text: "Muse · Black Holes and Revelations"
                                                        font.family: root.font
                                                        font.pixelSize: 9
                                                        color: root.theme.textSecondary
                                                        elide: Text.ElideRight
                                                    }
                                                }

                                                // Mini Transport Buttons
                                                RowLayout {
                                                    spacing: 4

                                                    Text {
                                                        text: "󰒮"
                                                        font.family: root.font
                                                        font.pixelSize: 13
                                                        color: root.theme.textSecondary
                                                    }

                                                    Rectangle {
                                                        width: 24
                                                        height: 24
                                                        radius: 12
                                                        color: root.theme.accentPrimary

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "󰏤"
                                                            font.family: root.font
                                                            font.pixelSize: 11
                                                            color: root.theme.bgBase ?? "#ffffff"
                                                        }
                                                    }

                                                    Text {
                                                        text: "󰒭"
                                                        font.family: root.font
                                                        font.pixelSize: 13
                                                        color: root.theme.textSecondary
                                                    }
                                                }
                                            }

                                            // Compact Progress Line
                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 3
                                                radius: 1.5
                                                color: Qt.rgba(1, 1, 1, 0.08)

                                                Rectangle {
                                                    height: parent.height
                                                    width: parent.width * 0.42
                                                    radius: parent.radius
                                                    color: root.theme.accentPrimary
                                                }
                                            }
                                        }
                                    }

                                    // Full Detailed Banner Preview Card
                                    Rectangle {
                                        visible: ControlCenterConfig.mediaWidgetStyle !== "compact"
                                        Layout.fillWidth: true
                                        implicitHeight: fullPreviewCol.implicitHeight + 16
                                        radius: 10
                                        color: root.theme.bgBase
                                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 1

                                        ColumnLayout {
                                            id: fullPreviewCol
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 8

                                            // Header row with album art
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 10

                                                Rectangle {
                                                    width: 48
                                                    height: 48
                                                    radius: 8
                                                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.18)
                                                    border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.35)
                                                    border.width: 1

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "󰝚"
                                                        font.family: root.font
                                                        font.pixelSize: 22
                                                        color: root.theme.accentPrimary
                                                    }
                                                }

                                                ColumnLayout {
                                                    spacing: 2
                                                    Layout.fillWidth: true

                                                    Text {
                                                        text: "Starlight"
                                                        font.family: root.font
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        color: root.theme.textPrimary
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        text: "Muse"
                                                        font.family: root.font
                                                        font.pixelSize: 10
                                                        color: root.theme.accentPrimary
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        text: "Black Holes and Revelations"
                                                        font.family: root.font
                                                        font.pixelSize: 9
                                                        color: root.theme.textMuted
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                            }

                                            // Progress bar with timestamps
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 3

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    height: 4
                                                    radius: 2
                                                    color: Qt.rgba(1, 1, 1, 0.08)

                                                    Rectangle {
                                                        height: parent.height
                                                        width: parent.width * 0.42
                                                        radius: parent.radius
                                                        color: root.theme.accentPrimary
                                                    }
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true

                                                    Text {
                                                        text: "01:24"
                                                        font.family: root.font
                                                        font.pixelSize: 9
                                                        color: root.theme.textMuted
                                                    }

                                                    Item { Layout.fillWidth: true }

                                                    Text {
                                                        text: "03:45"
                                                        font.family: root.font
                                                        font.pixelSize: 9
                                                        color: root.theme.textMuted
                                                    }
                                                }
                                            }

                                            // Transport controls
                                            RowLayout {
                                                Layout.alignment: Qt.AlignHCenter
                                                spacing: 16

                                                Text {
                                                    text: "󰒮"
                                                    font.family: root.font
                                                    font.pixelSize: 15
                                                    color: root.theme.textSecondary
                                                }

                                                Rectangle {
                                                    width: 28
                                                    height: 28
                                                    radius: 14
                                                    color: root.theme.accentPrimary

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "󰏤"
                                                        font.family: root.font
                                                        font.pixelSize: 13
                                                        color: root.theme.bgBase ?? "#ffffff"
                                                    }
                                                }

                                                Text {
                                                    text: "󰒭"
                                                    font.family: root.font
                                                    font.pixelSize: 15
                                                    color: root.theme.textSecondary
                                                }
                                            }
                                        }
                                    }

                                    // Auto-Hide Switch
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 36
                                        radius: 6
                                        color: root.theme.bgBase
                                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Text {
                                                text: "Auto-Hide Media when inactive"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.theme.textPrimary
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                width: 36
                                                height: 20
                                                radius: 10
                                                color: ControlCenterConfig.mediaAutoHide ? root.theme.accentPrimary : (root.theme.bgSurface ?? Qt.rgba(0, 0, 0, 0.3))
                                                border.color: ControlCenterConfig.mediaAutoHide ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15))
                                                border.width: 1

                                                Rectangle {
                                                    width: 14
                                                    height: 14
                                                    radius: 7
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    x: ControlCenterConfig.mediaAutoHide ? (parent.width - width - 3) : 3
                                                    color: ControlCenterConfig.mediaAutoHide ? (root.theme.bgBase ?? "#ffffff") : root.theme.textPrimary
                                                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: ControlCenterConfig.mediaAutoHide = !ControlCenterConfig.mediaAutoHide
                                                }
                                            }
                                        }
                                    }

                                    // Show Cava Equalizer Wave Switch
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 36
                                        radius: 6
                                        color: root.theme.bgBase
                                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Text {
                                                text: "Show Cava Equalizer in Media Player"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.theme.textPrimary
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                width: 36
                                                height: 20
                                                radius: 10
                                                color: ControlCenterConfig.mediaShowCava ? root.theme.accentPrimary : (root.theme.bgSurface ?? Qt.rgba(0, 0, 0, 0.3))
                                                border.color: ControlCenterConfig.mediaShowCava ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15))
                                                border.width: 1

                                                Rectangle {
                                                    width: 14
                                                    height: 14
                                                    radius: 7
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    x: ControlCenterConfig.mediaShowCava ? (parent.width - width - 3) : 3
                                                    color: ControlCenterConfig.mediaShowCava ? (root.theme.bgBase ?? "#ffffff") : root.theme.textPrimary
                                                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: ControlCenterConfig.setMediaShowCava(!ControlCenterConfig.mediaShowCava)
                                                }
                                            }
                                        }
                                    }
                                }

                                /* ------------------------------------------------------------- */
                                /* CAVA VISUALIZER PANEL PREVIEW                                 */
                                /* ------------------------------------------------------------- */
                                ColumnLayout {
                                    visible: panelColCard.cardId === "cava"
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Text {
                                        text: "Live Audio Spectrum Equalizer Visualizer"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        Layout.fillWidth: true
                                    }

                                    // Cava Preview Card
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 64
                                        radius: 8
                                        color: root.theme.bgBase
                                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                        border.width: 1
                                        clip: true

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Repeater {
                                                model: 16
                                                delegate: Rectangle {
                                                    required property int index
                                                    width: 8
                                                    height: [8, 14, 22, 34, 46, 38, 26, 18, 12, 28, 42, 36, 24, 16, 10, 6][index]
                                                    radius: 2
                                                    color: root.theme.accentPrimary
                                                    opacity: 0.85
                                                    anchors.bottom: parent.bottom
                                                }
                                            }
                                        }
                                    }

                                    // Style and Config info row
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            text: "Style: " + BarConfig.cavaStyle + " · " + (BarConfig.cavaBars || 8) + " Bars · " + (BarConfig.cavaStereo ? "Stereo" : "Mono")
                                            font.family: root.font
                                            font.pixelSize: 10
                                            color: root.theme.textSecondary
                                            Layout.fillWidth: true
                                        }

                                        // Cycle Style Button
                                        Rectangle {
                                            implicitWidth: cycleStyleTxt.implicitWidth + 12
                                            height: 22
                                            radius: 4
                                            color: cycleStyleMouse.containsMouse ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.1) : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
                                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                                            border.width: 1

                                            Text {
                                                id: cycleStyleTxt
                                                anchors.centerIn: parent
                                                text: "Change Style"
                                                font.family: root.font
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: root.theme.textPrimary
                                            }

                                            MouseArea {
                                                id: cycleStyleMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (BarConfig.cavaStyle === "bars") BarConfig.cavaStyle = "glyphs";
                                                    else if (BarConfig.cavaStyle === "glyphs") BarConfig.cavaStyle = "line";
                                                    else BarConfig.cavaStyle = "bars";
                                                }
                                            }
                                        }
                                    }
                                }

                                /* ------------------------------------------------------------- */
                                /* D. BRIGHTNESS PANEL PREVIEW                                   */
                                /* ------------------------------------------------------------- */
                                ColumnLayout {
                                    visible: panelColCard.cardId === "brightness"
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Text {
                                        text: "Screen Backlight Brightness Slider"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        Layout.fillWidth: true
                                    }

                                    // Brightness Slider Preview
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: "󰃠 Screen Brightness"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.theme.textPrimary
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: "80%"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.theme.accentPrimary
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 6
                                            radius: 3
                                            color: root.theme.bgBase
                                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                                            border.width: 1

                                            Rectangle {
                                                height: parent.height
                                                width: parent.width * 0.80
                                                radius: parent.radius
                                                color: root.theme.accentPrimary
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Smooth hardware backlight control via brightnessctl"
                                        font.family: root.font
                                        font.pixelSize: 9
                                        color: root.theme.textMuted
                                        Layout.fillWidth: true
                                    }
                                }

                                /* ------------------------------------------------------------- */
                                /* E. SYSTEM INFO PANEL PREVIEW                                  */
                                /* ------------------------------------------------------------- */
                                ColumnLayout {
                                    visible: panelColCard.cardId === "systemInfo"
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: "CPU, Memory, Disk & Thermals Telemetry"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        Layout.fillWidth: true
                                    }

                                    // Metric Rows Preview
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        // CPU
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            Text { text: "󰍛 CPU"; font.family: root.font; font.pixelSize: 10; font.bold: true; color: root.theme.textPrimary; Layout.preferredWidth: 60 }
                                            Rectangle {
                                                Layout.fillWidth: true; height: 5; radius: 2.5; color: root.theme.bgBase; border.color: root.theme.bgBorder; border.width: 1
                                                Rectangle { height: parent.height; width: parent.width * 0.22; radius: parent.radius; color: root.theme.accentPrimary }
                                            }
                                            Text { text: "22%"; font.family: root.font; font.pixelSize: 9; color: root.theme.accentPrimary; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                                        }

                                        // RAM
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            Text { text: "󰘚 RAM"; font.family: root.font; font.pixelSize: 10; font.bold: true; color: root.theme.textPrimary; Layout.preferredWidth: 60 }
                                            Rectangle {
                                                Layout.fillWidth: true; height: 5; radius: 2.5; color: root.theme.bgBase; border.color: root.theme.bgBorder; border.width: 1
                                                Rectangle { height: parent.height; width: parent.width * 0.45; radius: parent.radius; color: root.theme.accentPrimary }
                                            }
                                            Text { text: "45%"; font.family: root.font; font.pixelSize: 9; color: root.theme.accentPrimary; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                                        }

                                        // Disk
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            Text { text: "󰋊 Disk"; font.family: root.font; font.pixelSize: 10; font.bold: true; color: root.theme.textPrimary; Layout.preferredWidth: 60 }
                                            Rectangle {
                                                Layout.fillWidth: true; height: 5; radius: 2.5; color: root.theme.bgBase; border.color: root.theme.bgBorder; border.width: 1
                                                Rectangle { height: parent.height; width: parent.width * 0.62; radius: parent.radius; color: root.theme.accentPrimary }
                                            }
                                            Text { text: "62%"; font.family: root.font; font.pixelSize: 9; color: root.theme.accentPrimary; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                                        }

                                        // Temp
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            Text { text: "󰔏 Temp"; font.family: root.font; font.pixelSize: 10; font.bold: true; color: root.theme.textPrimary; Layout.preferredWidth: 60 }
                                            Rectangle {
                                                Layout.fillWidth: true; height: 5; radius: 2.5; color: root.theme.bgBase; border.color: root.theme.bgBorder; border.width: 1
                                                Rectangle { height: parent.height; width: parent.width * 0.38; radius: parent.radius; color: root.theme.accentPrimary }
                                            }
                                            Text { text: "44°C"; font.family: root.font; font.pixelSize: 9; color: root.theme.accentPrimary; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Available Panels Pool Card (for unassigned panels)
                Rectangle {
                    visible: ControlCenterConfig.unassignedCards.length > 0
                    Layout.fillWidth: true
                    implicitHeight: availCardsCol.implicitHeight + 20
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: availCardsCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 12
                        }
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Available Panels (" + ControlCenterConfig.unassignedCards.length + " available)"
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: true
                                color: root.theme.accentPrimary
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "Click any panel to place back into Control Center"
                                font.family: root.font
                                font.pixelSize: 10
                                color: root.theme.textMuted
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: ControlCenterConfig.unassignedCards

                                delegate: Rectangle {
                                    id: availCardChip
                                    required property var modelData
                                    implicitWidth: aChipRow.implicitWidth + 20
                                    height: 34
                                    radius: 8
                                    color: aChipMouse.containsMouse
                                        ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12)
                                        : root.theme.bgBase
                                    border.color: aChipMouse.containsMouse
                                        ? root.theme.accentPrimary
                                        : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    RowLayout {
                                        id: aChipRow
                                        anchors.centerIn: parent
                                        spacing: 8

                                        Text {
                                            text: "+"
                                            font.family: root.font
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: root.theme.accentPrimary
                                        }

                                        Text {
                                            text: availCardChip.modelData.icon ?? ""
                                            font.family: root.font
                                            font.pixelSize: 14
                                            color: root.theme.textPrimary
                                        }

                                        Text {
                                            text: availCardChip.modelData.label ?? ""
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.textPrimary
                                        }
                                    }

                                    MouseArea {
                                        id: aChipMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        preventStealing: true
                                        onClicked: ControlCenterConfig.setCardVisible(availCardChip.modelData.id, true)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* ========================================================= */
            /* 3. ACTIONS & RESET                                        */
            /* ========================================================= */
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 12
                color: root.theme.bgSurface
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Restore Defaults"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Reset width, card visibility, and quick tile order"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    Rectangle {
                        width: 110
                        height: root.btnHeight
                        radius: root.btnRadius
                        color: resetBtnMouse.containsMouse 
                            ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12) 
                            : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2))
                        border.color: resetBtnMouse.containsMouse 
                            ? root.theme.accentPrimary 
                            : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Reset"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        MouseArea {
                            id: resetBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            onClicked: ControlCenterConfig.resetDefaults()
                        }
                    }
                }
            }
        }
    }
}
