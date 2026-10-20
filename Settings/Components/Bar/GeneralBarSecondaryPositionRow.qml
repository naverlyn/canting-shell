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
    visible: root.generalTab.curDisplayTarget === "all" && root.hasMultipleMonitors
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
                text: "Secondary Bar Position"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "Dock to Top, Bottom, Left, or Right edge on your secondary display"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
            }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            id: secGenPosSegmentTrack
            implicitWidth: 280
            implicitHeight: 32
            width: 280
            height: 32
            radius: 7
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1

            readonly property string activePos: BarConfig.currentBar ? (BarConfig.currentBar.secondaryPosition || BarConfig.currentBar.position || "top") : (BarConfig.secondaryPosition || BarConfig.position || "top")
            readonly property int activePosIndex: activePos === "bottom" ? 1 : (activePos === "left" ? 2 : (activePos === "right" ? 3 : 0))
            readonly property real cellWidth: (width - 6 - 12) / 4

            Rectangle {
                y: 3
                height: parent.height - 6
                width: secGenPosSegmentTrack.cellWidth
                x: 3 + secGenPosSegmentTrack.activePosIndex * (secGenPosSegmentTrack.cellWidth + 4)
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
                        id: secGenPosSegBtn
                        required property var modelData
                        readonly property bool isSel: secGenPosSegmentTrack.activePos === modelData.value

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        scale: secGenPosMouse.pressed ? 0.95 : 1.0
                        color: !isSel && secGenPosHover.hovered ? root.theme.bgHover : "transparent"
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: secGenPosHover }

                        Text {
                            anchors.centerIn: parent
                            text: secGenPosSegBtn.modelData.label
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: secGenPosSegBtn.isSel
                            color: secGenPosSegBtn.isSel ? root.theme.accentPrimary : root.theme.textSecondary
                            opacity: secGenPosSegBtn.isSel || secGenPosHover.hovered ? 1.0 : 0.75
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: secGenPosMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BarConfig.updateBarProp("secondaryPosition", secGenPosSegBtn.modelData.value)
                        }
                    }
                }
            }
        }
    }
}
