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
    id: rowSelf
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
                text: (root.generalTab.curDisplayTarget === "all" && root.hasMultipleMonitors) ? "Primary Bar Position" : "Bar Position"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: (root.generalTab.curDisplayTarget === "all" && root.hasMultipleMonitors)
                    ? "Dock to Top, Bottom, Left, or Right edge on your primary display"
                    : "Dock to Top, Bottom, Left, or Right edge of the display"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
            }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            id: posSegmentTrack
            implicitWidth: 280
            implicitHeight: 32
            width: 280
            height: 32
            radius: 7
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1

            readonly property string activePos: BarConfig.currentBar ? BarConfig.currentBar.position : BarConfig.position
            readonly property int activePosIndex: activePos === "bottom" ? 1 : (activePos === "left" ? 2 : (activePos === "right" ? 3 : 0))
            readonly property real cellWidth: (width - 6 - 12) / 4

            Rectangle {
                y: 3
                height: parent.height - 6
                width: posSegmentTrack.cellWidth
                x: 3 + posSegmentTrack.activePosIndex * (posSegmentTrack.cellWidth + 4)
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
                        { label: "Top", value: "top" },
                        { label: "Bottom", value: "bottom" },
                        { label: "Left", value: "left" },
                        { label: "Right", value: "right" }
                    ]

                    delegate: Rectangle {
                        id: posSegBtn
                        required property var modelData
                        readonly property bool isSel: posSegmentTrack.activePos === modelData.value

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        scale: posSegMouse.pressed ? 0.95 : 1.0
                        color: !isSel && posSegHover.hovered ? root.theme.bgHover : "transparent"
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: posSegHover }

                        Text {
                            anchors.centerIn: parent
                            text: posSegBtn.modelData.label
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: posSegBtn.isSel
                            color: posSegBtn.isSel ? root.theme.accentPrimary : root.theme.textSecondary
                            opacity: posSegBtn.isSel || posSegHover.hovered ? 1.0 : 0.75
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: posSegMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BarConfig.updateBarProp("position", posSegBtn.modelData.value)
                        }
                    }
                }
            }
        }
    }
}
