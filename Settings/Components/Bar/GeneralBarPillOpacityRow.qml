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
    id: pillOpacityItem
    Layout.fillWidth: true
    height: 52
    readonly property real activePillOpacity: root.generalTab.curPillOpacity
    opacity: root.generalTab.curHidePill ? 0.45 : 1.0
    enabled: !root.generalTab.curHidePill
    Behavior on opacity { NumberAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.preferredWidth: 160
            Layout.minimumWidth: 160
            Layout.maximumWidth: 160
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Pill Background Opacity"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: "Transparency of widget cards"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: pillOpacityTrack
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: root.theme.bgSelected
            Layout.alignment: Qt.AlignVCenter

            readonly property real val: pillOpacityItem.activePillOpacity
            readonly property bool isDragging: pillOpMouse.pressed

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: Math.max(0, Math.min(parent.width, parent.width * pillOpacityTrack.val))
                color: root.theme.accentPrimary

                Behavior on width {
                    NumberAnimation {
                        duration: pillOpacityTrack.isDragging ? 0 : 140
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Outer halo ring on hover/press
            Rectangle {
                anchors.centerIn: pillOpKnob
                width: pillOpKnob.width + (pillOpMouse.pressed ? 8 : (pillOpMouse.containsMouse ? 6 : 0))
                height: width
                radius: width / 2
                color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, pillOpMouse.pressed ? 0.35 : (pillOpMouse.containsMouse ? 0.2 : 0))
                z: 1

                Behavior on width { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // Tactile white knob
            Rectangle {
                id: pillOpKnob
                width: pillOpMouse.containsMouse || pillOpMouse.pressed ? 17 : 15
                height: width
                radius: width / 2
                color: "#ffffff"
                border.color: root.theme.accentPrimary
                border.width: 3
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(pillOpacityTrack.width - width, (pillOpacityTrack.width * pillOpacityTrack.val) - (width / 2)))
                z: 2

                Behavior on width { NumberAnimation { duration: 120 } }
                Behavior on x {
                    NumberAnimation {
                        duration: pillOpacityTrack.isDragging ? 0 : 140
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: pillOpMouse
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                function updateFromPos(mouse) {
                    if (pillOpacityTrack.width <= 0) return;
                    const trackX = mapToItem(pillOpacityTrack, mouse.x, 0).x;
                    const frac = Math.max(0.0, Math.min(1.0, trackX / pillOpacityTrack.width));
                    BarConfig.updateBarProp("pillOpacity", Math.round(frac * 100) / 100);
                }
                onPressed: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateFromPos(mouse); } }
                onClicked: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
            }
        }

        Text {
            text: Math.round(pillOpacityTrack.val * 100) + "%"
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
