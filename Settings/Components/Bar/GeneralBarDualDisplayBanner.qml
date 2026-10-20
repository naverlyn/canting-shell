import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    id: rowSelf
    visible: root.hasMultipleMonitors && root.generalTab.curDisplayTarget === "all"
    Layout.fillWidth: true
    Layout.leftMargin: 12
    Layout.rightMargin: 12
    height: 42
    radius: 7
    color: root.theme.bgBase
    border.color: root.theme.bgBorder
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        Text {
            text: "Dual displays active (" + root.activeMonitorsSummary + "). Secondary bar layout and options can be configured in Layout & Panels."
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textSecondary
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Rectangle {
            visible: true
            height: 26
            implicitWidth: jumpPanelsTxt.implicitWidth + 24
            radius: 5
            scale: jumpPanelsMouse.pressed ? 0.94 : (jumpPanelsHover.hovered ? 1.04 : 1.0)
            color: jumpPanelsHover.hovered ? root.theme.bgHover : root.theme.bgSurface
            border.color: jumpPanelsHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder
            border.width: 1

            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            HoverHandler { id: jumpPanelsHover }

            Row {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "󰕮"
                    font.family: root.font
                    font.pixelSize: 11
                    color: jumpPanelsHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                Text {
                    id: jumpPanelsTxt
                    text: "Layout & Panels"
                    font.family: root.font
                    font.pixelSize: 10
                    font.bold: true
                    color: jumpPanelsHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 140 } }
                }
            }

            MouseArea {
                id: jumpPanelsMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    BarConfig.activeEditingDisplay = "secondary";
                    root.currentSubTab = 0;
                }
            }
        }
    }
}
