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
    opacity: root.nightLightEnabled ? 1.0 : 0.45
    Behavior on opacity { NumberAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Text {
            text: "Warmth Presets"
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
            color: root.theme.textSecondary
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            id: nlPresetTrack
            implicitWidth: 320
            implicitHeight: 32
            width: 320
            height: 32
            radius: 7
            color: root.theme.bgBase
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            Layout.alignment: Qt.AlignVCenter

            readonly property var presets: [
                { k: 3500, label: "3500K" },
                { k: 4000, label: "4000K" },
                { k: 4500, label: "4500K" },
                { k: 5000, label: "5000K" },
                { k: 5500, label: "5500K" }
            ]
            readonly property int activeIdx: {
                for (let i = 0; i < presets.length; i++) {
                    if (Math.abs(root.nightLightTemp - presets[i].k) <= 100) return i;
                }
                return -1;
            }
            readonly property real cellWidth: (width - 6 - (4 * 4)) / 5

            /* Sliding Selection Pill */
            Rectangle {
                visible: opacity > 0
                opacity: nlPresetTrack.activeIdx >= 0 && root.nightLightEnabled ? 1.0 : 0.0
                y: 3
                height: parent.height - 6
                width: nlPresetTrack.cellWidth
                x: nlPresetTrack.activeIdx >= 0 ? (3 + nlPresetTrack.activeIdx * (nlPresetTrack.cellWidth + 4)) : 3
                radius: 5
                color: root.theme.bgSelected
                border.color: root.theme.accentOrange ?? root.theme.accentPrimary
                border.width: 1

                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 4

                Repeater {
                    model: nlPresetTrack.presets

                    delegate: Rectangle {
                        id: nlSegBtn
                        required property var modelData
                        required property int index

                        readonly property bool isSel: nlPresetTrack.activeIdx === nlSegBtn.index && root.nightLightEnabled

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: !isSel && nlHover.hovered && root.nightLightEnabled ? root.theme.bgHover : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: nlHover; enabled: root.nightLightEnabled }

                        Text {
                            anchors.centerIn: parent
                            text: nlSegBtn.modelData.label
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: nlSegBtn.isSel
                            color: nlSegBtn.isSel ? (root.theme.accentOrange ?? root.theme.accentPrimary) : root.theme.textPrimary
                            opacity: !root.nightLightEnabled ? 0.45 : (nlSegBtn.isSel || nlHover.hovered ? 1.0 : 0.75)
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: root.nightLightEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: root.nightLightEnabled
                            preventStealing: true
                            onClicked: root.setNightLightTemp(nlSegBtn.modelData.k)
                        }
                    }
                }
            }
        }
    }
}
