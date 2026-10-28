import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: self
    title: "Desktop Bars (" + root.desktopBarTabs.length + ")"
    subtitle: root.hasMultipleMonitors
        ? (root.selectedMonitorFilter === "secondary"
            ? ("Secondary Monitor (" + root.getMonitorNameForTarget("secondary") + ") · " + root.desktopBarTabs.length + " bars configured")
            : (root.selectedMonitorFilter === "primary"
                ? ("Primary Monitor (" + root.getMonitorNameForTarget("primary") + ") · " + root.desktopBarTabs.length + " bars configured")
                : ("Dual Monitors Active (" + root.activeMonitorsSummary + ") · " + root.desktopBarTabs.length + " bars configured")))
        : ("Single Monitor Active (" + root.activeMonitorsSummary + ") · 1 display detected")
    contentMargins: 10

    // Monitor Setup Identification Banner
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 38
        radius: 8
        color: root.theme.bgBase
        border.color: root.hasMultipleMonitors
            ? root.withAlpha(root.theme.accentPrimary, 0.35)
            : root.withAlpha(root.theme.accentCyan, 0.35)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            // Setup Mode Badge
            Rectangle {
                height: 24
                implicitWidth: monSetupBadgeRow.implicitWidth + 16
                radius: 6
                color: root.hasMultipleMonitors
                    ? root.withAlpha(root.theme.accentPrimary, 0.16)
                    : root.withAlpha(root.theme.accentCyan, 0.16)
                border.color: root.hasMultipleMonitors
                    ? root.withAlpha(root.theme.accentPrimary, 0.4)
                    : root.withAlpha(root.theme.accentCyan, 0.4)
                border.width: 1

                Row {
                    id: monSetupBadgeRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.hasMultipleMonitors ? ("Dual Monitors (" + root.monitorCount + ")") : "Single Monitor"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.hasMultipleMonitors ? root.theme.accentPrimary : root.theme.accentCyan
                    }
                }
            }

            // Connected Screens Switcher Buttons
            Row {
                spacing: 6
                Repeater {
                    model: root.activeScreensList
                    delegate: Rectangle {
                        id: scrBtn
                        required property var modelData
                        required property int index
                        readonly property string targetRole: index === 0 ? "primary" : "secondary"
                        readonly property bool isSelected: root.hasMultipleMonitors
                            ? (root.selectedMonitorFilter === targetRole)
                            : true
                        readonly property bool isHovered: scrHover.hovered

                        height: 24
                        implicitWidth: scrChipRow.implicitWidth + 16
                        radius: 6
                        scale: scrMouse.pressed ? 0.94 : (isHovered && root.hasMultipleMonitors ? 1.04 : 1.0)
                        color: isSelected
                            ? (root.theme.bgSelected || root.withAlpha(root.theme.accentPrimary, 0.2))
                            : (isHovered ? root.theme.bgHover : root.theme.bgSurface)
                        border.color: isSelected
                            ? root.theme.accentPrimary
                            : (isHovered ? root.theme.textMuted : root.theme.bgBorder)
                        border.width: isSelected ? 1.5 : 1

                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: scrHover; enabled: root.hasMultipleMonitors }

                        Row {
                            id: scrChipRow
                            anchors.centerIn: parent
                            spacing: 5

                            Rectangle {
                                visible: root.hasMultipleMonitors && scrBtn.isSelected
                                width: 6
                                height: 6
                                radius: 3
                                color: root.theme.accentPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name + (root.hasMultipleMonitors ? (index === 0 ? " · Primary" : " · Secondary") : "")
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: scrBtn.isSelected
                                color: scrBtn.isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            Text {
                                visible: Boolean(modelData.model)
                                anchors.verticalCenter: parent.verticalCenter
                                text: "(" + modelData.model.split(" ")[0] + ")"
                                font.family: root.font
                                font.pixelSize: 9
                                color: scrBtn.isSelected ? root.theme.accentPrimary : root.theme.textMuted
                                opacity: scrBtn.isSelected ? 0.85 : 0.6
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }
                        }

                        MouseArea {
                            id: scrMouse
                            anchors.fill: parent
                            enabled: root.hasMultipleMonitors
                            cursorShape: root.hasMultipleMonitors ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                root.selectMonitorFilter(scrBtn.targetRole);
                            }
                        }
                    }
                }

                // All Screens View Button (shown when dual/multi-monitors)
                Rectangle {
                    id: allScreensBtn
                    visible: root.hasMultipleMonitors
                    height: 24
                    implicitWidth: allScrTxt.implicitWidth + 18
                    radius: 6
                    readonly property bool isSelected: root.selectedMonitorFilter === "all"
                    readonly property bool isHovered: allScrHov.hovered
                    scale: allScrMouse.pressed ? 0.94 : (isHovered ? 1.04 : 1.0)
                    color: isSelected
                        ? (root.theme.bgSelected || root.withAlpha(root.theme.accentPrimary, 0.2))
                        : (isHovered ? root.theme.bgHover : root.theme.bgSurface)
                    border.color: isSelected
                        ? root.theme.accentPrimary
                        : (isHovered ? root.theme.textMuted : root.theme.bgBorder)
                    border.width: isSelected ? 1.5 : 1

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: allScrHov }

                    Row {
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            visible: allScreensBtn.isSelected
                            width: 6
                            height: 6
                            radius: 3
                            color: root.theme.accentPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: allScrTxt
                            anchors.verticalCenter: parent.verticalCenter
                            text: "All Screens"
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: allScreensBtn.isSelected
                            color: allScreensBtn.isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                    }

                    MouseArea {
                        id: allScrMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectMonitorFilter("all");
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Status Note
            Text {
                text: {
                    if (!root.hasMultipleMonitors) {
                        return "Single screen mode · Secondary bar disabled";
                    }
                    if (root.selectedMonitorFilter === "primary") {
                        return "Editing " + root.getMonitorNameForTarget("primary") + " (Primary)";
                    }
                    if (root.selectedMonitorFilter === "secondary") {
                        return "Editing " + root.getMonitorNameForTarget("secondary") + " (Secondary)";
                    }
                    return "Viewing bars across all connected screens";
                }
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textMuted
                elide: Text.ElideRight
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Flow {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: root.desktopBarTabs
                delegate: Rectangle {
                    id: barTabBtn
                    required property var modelData
                    required property int index
                    readonly property bool isCurrent: BarConfig.selectedBarIndex === modelData.barIndex && BarConfig.activeEditingDisplay === modelData.display
                    readonly property string barPos: modelData.pos || "top"
                    readonly property string posLabel: modelData.posLabel
                    readonly property string tabName: modelData.name

                    implicitWidth: barTabContent.implicitWidth + 16
                    implicitHeight: 34
                    width: implicitWidth
                    height: implicitHeight
                    color: "transparent"
                    border.width: 0
                    opacity: modelData.enabled !== false ? 1.0 : 0.6
                    scale: barTabMouse.pressed ? 0.96 : (barTabHover.hovered ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    HoverHandler { id: barTabHover }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 2
                        radius: 1
                        width: barTabBtn.isCurrent ? parent.width - 8 : (barTabHover.hovered ? parent.width * 0.5 : 0)
                        opacity: barTabBtn.isCurrent ? 1.0 : (barTabHover.hovered ? 0.5 : 0.0)
                        color: barTabBtn.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary

                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }

                    Row {
                        id: barTabContent
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 16
                            height: 12
                            radius: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: "transparent"
                            border.width: 1.5
                            border.color: barTabBtn.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            Rectangle {
                                readonly property string p: barTabBtn.barPos
                                x: p === "right" ? parent.width - width - 2 : 2
                                y: p === "bottom" ? parent.height - height - 2 : 2
                                width: (p === "left" || p === "right") ? 2.5 : parent.width - 4
                                height: (p === "top" || p === "bottom") ? 2.5 : parent.height - 4
                                radius: 1
                                color: barTabBtn.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: barTabBtn.tabName
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: barTabBtn.isCurrent
                            color: barTabBtn.isCurrent
                                ? root.theme.accentPrimary
                                : (barTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        Rectangle {
                            width: monBadgeRow.implicitWidth + 10
                            height: 18
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: barTabBtn.isCurrent ? root.withAlpha(root.theme.accentPrimary, 0.12) : root.theme.bgBase
                            border.color: barTabBtn.isCurrent ? root.withAlpha(root.theme.accentPrimary, 0.35) : root.theme.bgBorder
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            Row {
                                id: monBadgeRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: barTabBtn.modelData.monitor
                                    font.family: root.font
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: barTabBtn.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }
                            }
                        }

                        Rectangle {
                            width: posBadgeTxt.implicitWidth + 10
                            height: 18
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: barTabBtn.isCurrent ? root.withAlpha(root.theme.accentPrimary, 0.16) : root.theme.bgBase
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Text {
                                id: posBadgeTxt
                                anchors.centerIn: parent
                                text: barTabBtn.posLabel + (barTabBtn.modelData.enabled === false ? " · Off" : "")
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: barTabBtn.isCurrent ? root.theme.accentPrimary : root.theme.textMuted
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }
                        }
                    }

                    MouseArea {
                        id: barTabMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            BarConfig.selectedBarIndex = barTabBtn.modelData.barIndex;
                            BarConfig.activeEditingDisplay = barTabBtn.modelData.display;
                            if (root.hasMultipleMonitors && root.selectedMonitorFilter !== "all") {
                                root.selectedMonitorFilter = barTabBtn.modelData.display === "secondary" ? "secondary" : "primary";
                            }
                        }
                    }
                }
            }

            // Empty state when filtered monitor has no bars
            Rectangle {
                visible: root.desktopBarTabs.length === 0
                height: 34
                implicitWidth: emptyMonRow.implicitWidth + 24
                radius: 6
                color: root.theme.bgSurface
                border.color: root.theme.bgBorder
                border.width: 1

                Row {
                    id: emptyMonRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "No bars on " + (root.selectedMonitorFilter === "secondary" ? (root.getMonitorNameForTarget("secondary") || "Secondary Display") : root.getMonitorNameForTarget("primary")) + " · Click Add Bar to create one"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                    }
                }
            }
        }

        ActionButton {
            visible: BarConfig.bars.length > 1
            iconText: "󰅖"
            label: "Remove Bar"
            danger: true
            btnHeight: 32
            onClicked: BarConfig.removeBarAt(BarConfig.selectedBarIndex)
        }

        ActionButton {
            iconText: "󰐕"
            label: "Add Bar"
            btnEnabled: BarConfig.bars.length < 4
            btnHeight: 32
            onClicked: {
                if (root.hasMultipleMonitors) {
                    root.openAddBarConfirm();
                } else {
                    BarConfig.addBar(undefined, "primary");
                }
            }
        }
    }
}
