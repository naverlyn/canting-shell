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

ColumnLayout {
    required property var root
    id: self
    property alias sliderMouseRef: sliderMouse
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Illumination & Brightness"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: brightGroupCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: brightGroupCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Brightness Slider (Text-only, full-width slider track) */
            Item {
                Layout.fillWidth: true
                height: 56

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        spacing: 2
                        Layout.preferredWidth: 165
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Screen Brightness"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: root.hasBacklightDevice && root.brightnessDevice !== ""
                                ? ("Backlight · " + root.brightnessDevice)
                                : "Display backlight level"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    /* Interactive Brightness Slider Track */
                    Rectangle {
                        id: sliderTrack
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            width: Math.max(0, Math.min(parent.width, parent.width * (root.brightness / 100)))
                            color: root.theme.accentPrimary

                            Behavior on width {
                                enabled: !sliderMouse.pressed
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }

                        /* Outer halo ring on hover/press */
                        Rectangle {
                            anchors.centerIn: sliderBall
                            width: sliderBall.width + (sliderMouse.pressed ? 8 : (sliderMouse.containsMouse ? 6 : 0))
                            height: width
                            radius: width / 2
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b,
                                           sliderMouse.pressed ? 0.35 : (sliderMouse.containsMouse ? 0.2 : 0))
                            z: 1

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        /* Slider Knob */
                        Rectangle {
                            id: sliderBall
                            width: sliderMouse.containsMouse || sliderMouse.pressed ? 18 : 16
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            border.color: root.theme.accentPrimary
                            border.width: 3
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(sliderTrack.width - width, (sliderTrack.width * (root.brightness / 100)) - (width / 2)))
                            z: 2

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on x { NumberAnimation { duration: sliderMouse.pressed ? 0 : 80; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: sliderMouse
                            anchors.fill: parent
                            anchors.margins: -8
                            preventStealing: true
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => {
                                mouse.accepted = true;
                                if (sliderTrack.width > 0) {
                                    const pct = Math.max(1, Math.min(100, Math.round((mouse.x / sliderTrack.width) * 100)));
                                    root.setBrightnessLevel(pct);
                                }
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed && sliderTrack.width > 0) {
                                    mouse.accepted = true;
                                    const pct = Math.max(1, Math.min(100, Math.round((mouse.x / sliderTrack.width) * 100)));
                                    root.setBrightnessLevel(pct);
                                }
                            }
                            onClicked: (mouse) => {
                                mouse.accepted = true;
                                if (sliderTrack.width > 0) {
                                    const pct = Math.max(1, Math.min(100, Math.round((mouse.x / sliderTrack.width) * 100)));
                                    root.setBrightnessLevel(pct);
                                }
                            }
                        }
                    }

                    /* Percentage Badge */
                    Rectangle {
                        width: 48
                        height: 26
                        radius: 6
                        color: root.theme.bgBase
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: root.brightness + "%"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentPrimary
                        }
                    }
                }
            }

            /* Row Divider */
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
            }

            /* Row 2: Quick Brightness Presets */
            DisplayQuickBrightnessPresets {
                root: self.root
            }
        }
    }
}
