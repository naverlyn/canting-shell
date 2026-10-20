import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../MonitorManager"
import "../../../MonitorManager/Components"
import "../.."
import "../Common"
import ".."

Item {
    required property var root
    Layout.fillWidth: true
    height: 48

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Text {
            text: "Quick Presets"
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
            color: root.theme.textSecondary
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            id: brightPresetTrack
            implicitWidth: 280
            implicitHeight: 32
            width: 280
            height: 32
            radius: 7
            color: root.theme.bgBase
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            Layout.alignment: Qt.AlignVCenter

            readonly property var presets: [10, 25, 50, 75, 100]
            readonly property int activeIdx: {
                for (let i = 0; i < presets.length; i++) {
                    if (Math.abs(root.brightness - presets[i]) <= 2) return i;
                }
                return -1;
            }
            readonly property real cellWidth: (width - 6 - 16) / 5

            /* Sliding Selection Pill */
            Rectangle {
                visible: opacity > 0
                opacity: brightPresetTrack.activeIdx >= 0 ? 1.0 : 0.0
                y: 3
                height: parent.height - 6
                width: brightPresetTrack.cellWidth
                x: brightPresetTrack.activeIdx >= 0 ? (3 + brightPresetTrack.activeIdx * (brightPresetTrack.cellWidth + 4)) : 3
                radius: 5
                color: root.theme.bgSelected
                border.color: root.theme.accentPrimary
                border.width: 1

                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 4

                Repeater {
                    model: brightPresetTrack.presets

                    delegate: Rectangle {
                        id: bSegBtn
                        required property int modelData
                        required property int index
                        readonly property bool isSel: brightPresetTrack.activeIdx === bSegBtn.index

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: !isSel && bSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: bSegHover }

                        Text {
                            anchors.centerIn: parent
                            text: bSegBtn.modelData + "%"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: bSegBtn.isSel
                            color: bSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                            opacity: bSegBtn.isSel || bSegHover.hovered ? 1.0 : 0.75
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setBrightnessLevel(bSegBtn.modelData)
                        }
                    }
                }
            }
        }
    }
}
