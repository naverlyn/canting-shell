import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../notifications"
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    id: subTabTrack
    Layout.fillWidth: true
    height: 40
    radius: 10
    color: root.theme.bgSurface
    border.color: root.theme.bgBorder
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Repeater {
            model: [
                { idx: 0, icon: "󰕮", label: "Layout & Building Blocks" },
                { idx: 1, icon: "󰒓", label: "Placement & General" }
            ]
            delegate: Rectangle {
                id: subTabItem
                required property var modelData
                readonly property bool isCurrent: root.currentSubTab === modelData.idx

                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                border.width: 0
                scale: subTabMouse.pressed ? 0.96 : (subTabHover.hovered ? 1.02 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                HoverHandler { id: subTabHover }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 2
                    radius: 1
                    width: subTabItem.isCurrent
                        ? subTabRow.implicitWidth + 16
                        : (subTabHover.hovered ? (subTabRow.implicitWidth + 16) * 0.5 : 0)
                    opacity: subTabItem.isCurrent ? 1.0 : (subTabHover.hovered ? 0.5 : 0.0)
                    color: subTabItem.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary

                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Behavior on color { ColorAnimation { duration: 160 } }
                }

                Row {
                    id: subTabRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        width: 16
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: subTabItem.modelData.icon
                        font.family: root.font
                        font.pixelSize: 13
                        color: subTabItem.isCurrent
                            ? root.theme.accentPrimary
                            : (subTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: subTabItem.modelData.label
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: subTabItem.isCurrent
                        color: subTabItem.isCurrent
                            ? root.theme.accentPrimary
                            : (subTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }

                MouseArea {
                    id: subTabMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.currentSubTab !== subTabItem.modelData.idx) {
                            root.currentSubTab = subTabItem.modelData.idx;
                            root.subTabContentAnimation.restart();
                        }
                    }
                }
            }
        }
    }
}
