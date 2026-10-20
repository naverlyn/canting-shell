import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../../osd"
import "../.."
import "../Common"
import ".."

Item {
    required property var root
    property alias sinkMouseRef: sinkMouse
    Layout.fillWidth: true
    height: 52

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 16

        ColumnLayout {
            Layout.preferredWidth: root.labelColWidth
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: "Volume"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: root.isSinkMuted ? "Muted" : (root.sinkVolumePercent + "%")
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.isSinkMuted ? (root.theme.accentRed ?? "#f7768e") : (root.theme.accentPrimary ?? "#7aa2f7")
            }
        }

        /* Slider Track */
        Rectangle {
            id: sinkSliderTrack
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            implicitHeight: 6
            height: 6
            radius: 3
            color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.1)
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: Math.max(0, Math.min(parent.width, parent.width * (root.sinkVolumePercent / 100)))
                color: root.isSinkMuted ? (root.theme.textSecondary ?? "#666666") : root.theme.accentPrimary
            }

            // Outer halo ring on hover/press
            Rectangle {
                anchors.centerIn: sinkKnob
                width: sinkKnob.width + (sinkMouse.pressed ? 8 : (sinkMouse.containsMouse ? 6 : 0))
                height: width
                radius: width / 2
                color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, sinkMouse.pressed ? 0.35 : (sinkMouse.containsMouse ? 0.2 : 0))
                z: 1

                Behavior on width { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // Tactile white knob
            Rectangle {
                id: sinkKnob
                width: sinkMouse.containsMouse || sinkMouse.pressed ? 17 : 15
                height: width
                radius: width / 2
                color: "#ffffff"
                border.color: root.isSinkMuted ? (root.theme.textSecondary ?? "#666666") : root.theme.accentPrimary
                border.width: 3
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(sinkSliderTrack.width - width, (sinkSliderTrack.width * (root.sinkVolumePercent / 100)) - (width / 2)))
                z: 2

                Behavior on width { NumberAnimation { duration: 120 } }
                Behavior on x {
                    enabled: !sinkMouse.pressed
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: sinkMouse
                anchors.fill: parent
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                preventStealing: true
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: (mouse) => {
                    mouse.accepted = true;
                    root.setSinkVolumeFromMouse(mouse.x, sinkSliderTrack.width);
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        mouse.accepted = true;
                        root.setSinkVolumeFromMouse(mouse.x, sinkSliderTrack.width);
                    }
                }
            }
        }

        /* Standardized Text Mute Pill Button */
        Rectangle {
            implicitWidth: root.actionBtnWidth
            implicitHeight: root.btnHeight
            Layout.preferredWidth: root.actionBtnWidth
            Layout.preferredHeight: root.btnHeight
            width: root.actionBtnWidth
            height: root.btnHeight
            radius: root.btnRadius
            color: root.isSinkMuted 
                ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.18) 
                : (muteHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)))
            border.color: root.isSinkMuted 
                ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.4) 
                : (muteHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
            border.width: 1
            Layout.alignment: Qt.AlignVCenter

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            HoverHandler { id: muteHover }

            Text {
                anchors.centerIn: parent
                text: root.isSinkMuted ? "Muted" : "Mute"
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.isSinkMuted ? root.theme.accentRed : root.theme.textPrimary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleSinkMute()
            }
        }
    }
}
