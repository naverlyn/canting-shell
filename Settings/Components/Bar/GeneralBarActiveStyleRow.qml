import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

Item {
    required property var root
    id: activeStyleItem
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
                text: "Active Indicator Style"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "Highlight style for active workspaces and menus"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
            }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            id: activeStyleSegmentTrack
            implicitWidth: 260
            implicitHeight: 32
            width: 260
            height: 32
            radius: 7
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1

            readonly property string activeStyleVal: root.generalTab.curActiveStyle
            readonly property int activeIdx: activeStyleVal === "underline" ? 1 : (activeStyleVal === "both" ? 2 : 0)
            readonly property real cellWidth: (width - 6 - 8) / 3

            Rectangle {
                y: 3
                height: parent.height - 6
                width: activeStyleSegmentTrack.cellWidth
                x: 3 + activeStyleSegmentTrack.activeIdx * (activeStyleSegmentTrack.cellWidth + 4)
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
                        { label: "Pill", value: "pill" },
                        { label: "Line", value: "underline" },
                        { label: "Both", value: "both" }
                    ]

                    delegate: Rectangle {
                        id: styleSegBtn
                        required property var modelData
                        readonly property bool isSel: activeStyleSegmentTrack.activeStyleVal === modelData.value

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        scale: styleSegMouse.pressed ? 0.95 : 1.0
                        color: !isSel && styleSegHover.hovered ? root.theme.bgHover : "transparent"
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: styleSegHover }

                        Text {
                            anchors.centerIn: parent
                            text: styleSegBtn.modelData.label
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: styleSegBtn.isSel
                            color: styleSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                            opacity: styleSegBtn.isSel || styleSegHover.hovered ? 1.0 : 0.75
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: styleSegMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BarConfig.updateBarProp("activeStyle", styleSegBtn.modelData.value)
                        }
                    }
                }
            }
        }
    }
}
