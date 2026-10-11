/*
 * BarSettings.qml
 *
 * Grouped preferences for customizing the Quickshell Desktop Bar.
 * Inspired by GNOME Settings / Libadwaita (AdwPreferencesPage, AdwPreferencesGroup, AdwActionRow).
 *
 * Features:
 *   - Interactive Modular Building Blocks Builder:
 *       * Left, Center, and Right visual drop/section columns
 *       * Quick shift between sections (Left <-> Center <-> Right)
 *       * Move Up/Down within section
 *       * Quick visibility toggle on block
 *   - Comprehensive Widget Preferences:
 *       * Position segmented picker (Left | Center | Right) for each widget
 *       * Reorder arrows & master visibility switch
 *       * Contextual sub-options (e.g. Clock seconds & date)
 *   - General Bar Appearance:
 *       * Master visibility, dock position (top/bottom), height presets, floating style, opacity slider, multi-monitor
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
    property string font: "Hack Nerd Font"

    /* Reusable compact icon button */
    component MiniIconButton: Rectangle {
        id: miniBtn
        property string iconText: ""
        property string tooltipText: ""
        property bool btnEnabled: true
        signal clicked()

        width: 24
        height: 24
        radius: 6
        color: !btnEnabled ? "transparent" : (btnHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.1)) : (root.theme.bgBase ?? Qt.rgba(0,0,0,0.2)))
        border.color: !btnEnabled ? "transparent" : (btnHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.08)))
        border.width: 1
        opacity: btnEnabled ? 1.0 : 0.3

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        HoverHandler { id: btnHover; enabled: miniBtn.btnEnabled }

        Text {
            anchors.centerIn: parent
            text: miniBtn.iconText
            font.family: root.font
            font.pixelSize: 11
            color: miniBtn.btnEnabled ? (btnHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary) : root.theme.textMuted
        }

        MouseArea {
            anchors.fill: parent
            enabled: miniBtn.btnEnabled
            cursorShape: miniBtn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: miniBtn.clicked()
        }
    }

    /* Building Block Card Component */
    component BlockCard: Rectangle {
        id: blockCard
        property string widgetId: ""
        property string currentSection: ""
        property int itemIndex: 0
        property int totalInList: 1

        readonly property var meta: BarConfig.getWidgetMeta(widgetId)
        readonly property bool isVisible: BarConfig.isWidgetVisible(widgetId)

        Layout.fillWidth: true
        height: 38
        radius: 8
        color: cardHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : (root.theme.bgBase ?? Qt.rgba(0,0,0,0.2))
        border.color: isVisible ? (cardHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))) : Qt.rgba(1,1,1,0.05)
        border.width: 1
        opacity: isVisible ? 1.0 : 0.55

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
        Behavior on opacity { NumberAnimation { duration: 140 } }

        HoverHandler { id: cardHover }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            // Icon
            Text {
                text: blockCard.meta.icon
                font.family: root.font
                font.pixelSize: 13
                color: blockCard.isVisible ? root.theme.accentPrimary : root.theme.textMuted
                Layout.alignment: Qt.AlignVCenter
            }

            // Title
            Text {
                text: blockCard.meta.name
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: blockCard.isVisible ? root.theme.textPrimary : root.theme.textMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            // Action Buttons
            RowLayout {
                spacing: 3
                Layout.alignment: Qt.AlignVCenter

                // Shift Left
                MiniIconButton {
                    iconText: "◀"
                    tooltipText: "Move to previous section"
                    btnEnabled: blockCard.currentSection !== "left"
                    onClicked: BarConfig.moveWidgetSectionLeft(blockCard.widgetId)
                }

                // Move Up
                MiniIconButton {
                    iconText: "▲"
                    tooltipText: "Move earlier"
                    btnEnabled: blockCard.itemIndex > 0
                    onClicked: BarConfig.moveWidgetUp(blockCard.widgetId)
                }

                // Move Down
                MiniIconButton {
                    iconText: "▼"
                    tooltipText: "Move later"
                    btnEnabled: blockCard.itemIndex < blockCard.totalInList - 1
                    onClicked: BarConfig.moveWidgetDown(blockCard.widgetId)
                }

                // Shift Right
                MiniIconButton {
                    iconText: "▶"
                    tooltipText: "Move to next section"
                    btnEnabled: blockCard.currentSection !== "right"
                    onClicked: BarConfig.moveWidgetSectionRight(blockCard.widgetId)
                }

                // Toggle visibility
                MiniIconButton {
                    iconText: blockCard.isVisible ? "󰈈" : "󰈉"
                    tooltipText: blockCard.isVisible ? "Hide widget" : "Show widget"
                    btnEnabled: true
                    onClicked: BarConfig.setWidgetVisible(blockCard.widgetId, !blockCard.isVisible)
                }
            }
        }
    }

    /* Reusable standard switch row component */
    component SettingToggleRow: Item {
        id: toggleRow
        property string title: ""
        property string desc: ""
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

    /* Main scrollable view */
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.2)
            }
        }

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 22

            // Header
            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 3
                    Text {
                        text: "Bar Settings"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                    Text {
                        text: "Configure modular building blocks, positions, and desktop bar appearance"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    id: resetBtn
                    implicitWidth: resetText.implicitWidth + 24
                    height: 32
                    radius: 7
                    color: resetHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : (root.theme.bgSurface ?? Qt.rgba(1,1,1,0.04))
                    border.color: resetHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: resetHover }

                    Text {
                        id: resetText
                        anchors.centerIn: parent
                        text: "Reset to Default"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: resetHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BarConfig.resetDefaults()
                    }
                }
            }

            // Building blocks builder
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Text {
                        text: "Bar Layout & Building Blocks"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textSecondary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Use ◀ ▶ to move between sections, ▲ ▼ to reorder"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: blockBuilderLayout.implicitHeight + 24
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    RowLayout {
                        id: blockBuilderLayout
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 12
                        }
                        spacing: 12
                        Layout.fillWidth: true

                        // Left section column
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            implicitHeight: leftColContent.implicitHeight + 20
                            radius: 10
                            color: root.theme.bgBase ?? Qt.rgba(0,0,0,0.2)
                            border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.06)
                            border.width: 1

                            ColumnLayout {
                                id: leftColContent
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: 10
                                }
                                spacing: 8

                                // Section Header Pill
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: 6
                                    color: root.theme.bgSelected ?? Qt.rgba(1,1,1,0.08)

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text {
                                            text: "Left Section"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.accentPrimary
                                        }
                                        Text {
                                            text: "(" + BarConfig.leftWidgets.length + ")"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            color: root.theme.textMuted
                                        }
                                    }
                                }

                                // Widgets in Left Section
                                Repeater {
                                    model: BarConfig.leftWidgets
                                    delegate: BlockCard {
                                        required property string modelData
                                        required property int index
                                        widgetId: modelData
                                        currentSection: "left"
                                        itemIndex: index
                                        totalInList: BarConfig.leftWidgets.length
                                    }
                                }

                                // Empty state placeholder
                                Rectangle {
                                    visible: BarConfig.leftWidgets.length === 0
                                    Layout.fillWidth: true
                                    height: 60
                                    radius: 8
                                    color: "transparent"
                                    border.color: Qt.rgba(1,1,1,0.1)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "No widgets on Left\nMove blocks here with ◀"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textMuted
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }

                        // Center section column
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            implicitHeight: centerColContent.implicitHeight + 20
                            radius: 10
                            color: root.theme.bgBase ?? Qt.rgba(0,0,0,0.2)
                            border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.06)
                            border.width: 1

                            ColumnLayout {
                                id: centerColContent
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: 10
                                }
                                spacing: 8

                                // Section Header Pill
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: 6
                                    color: root.theme.bgSelected ?? Qt.rgba(1,1,1,0.08)

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text {
                                            text: "Center Section"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.accentPrimary
                                        }
                                        Text {
                                            text: "(" + BarConfig.centerWidgets.length + ")"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            color: root.theme.textMuted
                                        }
                                    }
                                }

                                // Widgets in Center Section
                                Repeater {
                                    model: BarConfig.centerWidgets
                                    delegate: BlockCard {
                                        required property string modelData
                                        required property int index
                                        widgetId: modelData
                                        currentSection: "center"
                                        itemIndex: index
                                        totalInList: BarConfig.centerWidgets.length
                                    }
                                }

                                // Empty state placeholder
                                Rectangle {
                                    visible: BarConfig.centerWidgets.length === 0
                                    Layout.fillWidth: true
                                    height: 60
                                    radius: 8
                                    color: "transparent"
                                    border.color: Qt.rgba(1,1,1,0.1)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "No widgets in Center\nMove blocks here with ◀ or ▶"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textMuted
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }

                        // Right section column
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            implicitHeight: rightColContent.implicitHeight + 20
                            radius: 10
                            color: root.theme.bgBase ?? Qt.rgba(0,0,0,0.2)
                            border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.06)
                            border.width: 1

                            ColumnLayout {
                                id: rightColContent
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: 10
                                }
                                spacing: 8

                                // Section Header Pill
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: 6
                                    color: root.theme.bgSelected ?? Qt.rgba(1,1,1,0.08)

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text {
                                            text: "Right Section"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.accentPrimary
                                        }
                                        Text {
                                            text: "(" + BarConfig.rightWidgets.length + ")"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            color: root.theme.textMuted
                                        }
                                    }
                                }

                                // Widgets in Right Section
                                Repeater {
                                    model: BarConfig.rightWidgets
                                    delegate: BlockCard {
                                        required property string modelData
                                        required property int index
                                        widgetId: modelData
                                        currentSection: "right"
                                        itemIndex: index
                                        totalInList: BarConfig.rightWidgets.length
                                    }
                                }

                                // Empty state placeholder
                                Rectangle {
                                    visible: BarConfig.rightWidgets.length === 0
                                    Layout.fillWidth: true
                                    height: 60
                                    radius: 8
                                    color: "transparent"
                                    border.color: Qt.rgba(1,1,1,0.1)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "No widgets on Right\nMove blocks here with ▶"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textMuted
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Widget preferences
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Widget Preferences"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: widgetsListCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: widgetsListCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        Repeater {
                            model: BarConfig.widgetDefinitions
                            delegate: ColumnLayout {
                                id: widgetItem
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                spacing: 0

                                SettingToggleRow {
                                    title: widgetItem.modelData.name
                                    desc: widgetItem.modelData.desc
                                    checked: BarConfig.isWidgetVisible(widgetItem.modelData.id)
                                    onToggled: (val) => {
                                        BarConfig.setWidgetVisible(widgetItem.modelData.id, val);
                                    }
                                }

                                // Separator between widgets
                                Rectangle {
                                    visible: widgetItem.index < BarConfig.widgetDefinitions.length - 1
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 12
                                    Layout.rightMargin: 12
                                    height: 1
                                    color: Qt.rgba(1, 1, 1, 0.05)
                                }
                            }
                        }
                    }
                }
            }

            // Clock options
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Clock Options"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: clockCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: clockCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        SettingToggleRow {
                            title: "Show Seconds in Clock"
                            desc: "Display precision seconds format (hh:mm:ss)"
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
                            desc: "Display weekday and calendar date alongside the time"
                            rowEnabled: BarConfig.showTime
                            checked: BarConfig.showDate
                            onToggled: (val) => {
                                BarConfig.showDate = val;
                                BarConfig.saveConfig();
                            }
                        }
                    }
                }
            }

            // General bar appearance
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "General Appearance"
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

                        // Master bar visibility
                        SettingToggleRow {
                            title: "Show Desktop Bar"
                            desc: "Display the top/bottom system status bar"
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

                        // Bar position selector (Top / Bottom)
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

                                    Text {
                                        text: "Bar Position"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Dock to top or bottom edge of the display"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 150
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

                                        // Top button
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: BarConfig.position === "top" ? root.theme.bgSelected : (posTopHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")
                                            border.color: BarConfig.position === "top" ? root.theme.accentPrimary : "transparent"
                                            border.width: BarConfig.position === "top" ? 1 : 0

                                            HoverHandler { id: posTopHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Top"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: BarConfig.position === "top"
                                                color: BarConfig.position === "top" ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                                                opacity: BarConfig.position === "top" ? 1.0 : (posTopHover.hovered ? 1.0 : 0.75)
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

                                        // Bottom button
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: BarConfig.position === "bottom" ? root.theme.bgSelected : (posBotHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : "transparent")
                                            border.color: BarConfig.position === "bottom" ? root.theme.accentPrimary : "transparent"
                                            border.width: BarConfig.position === "bottom" ? 1 : 0

                                            HoverHandler { id: posBotHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Bottom"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: BarConfig.position === "bottom"
                                                color: BarConfig.position === "bottom" ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                                                opacity: BarConfig.position === "bottom" ? 1.0 : (posBotHover.hovered ? 1.0 : 0.75)
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

                        // Height presets
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
                                            id: heightPresetBtn
                                            width: 52
                                            height: 28
                                            radius: 6
                                            readonly property bool isSelected: BarConfig.barHeight === modelData.value
                                            color: heightPresetBtn.isSelected ? root.theme.bgSelected : (hHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.06)) : root.theme.bgBase)
                                            border.color: heightPresetBtn.isSelected ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                            border.width: 1

                                            HoverHandler { id: hHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: heightPresetBtn.isSelected
                                                color: heightPresetBtn.isSelected ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                                                opacity: heightPresetBtn.isSelected ? 1.0 : (hHover.hovered ? 1.0 : 0.75)
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

                        // Floating style toggle
                        SettingToggleRow {
                            title: "Floating Bar"
                            desc: "Add screen margins and rounded outer corners"
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

                        // Bar opacity slider
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

                        // Multi-monitor preference
                        SettingToggleRow {
                            title: "Show on All Displays"
                            desc: "Display status bar across all connected monitors"
                            checked: BarConfig.allMonitors
                            onToggled: (val) => {
                                BarConfig.allMonitors = val;
                                BarConfig.saveConfig();
                            }
                        }
                    }
                }
            }
        }
    }
}
