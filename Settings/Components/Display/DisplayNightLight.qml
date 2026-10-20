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
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8

        Text {
            text: "Night Light"
            font.family: root.font
            font.pixelSize: 13
            font.bold: true
            color: root.theme.textSecondary
        }

        Text {
            text: "· Warm blue-light filter to reduce eye strain"
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textMuted
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: root.nightLightEnabled ? (root.nightLightTemp + " K · Active") : "Disabled"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.nightLightEnabled ? (root.theme.accentOrange ?? root.theme.accentPrimary) : root.theme.textMuted
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: nlGroupCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: nlGroupCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Enable Night Light Switch */
            Item {
                Layout.fillWidth: true
                height: 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Night Light"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Apply warm color temperature filter to all connected displays"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    /* Libadwaita Toggle Switch */
                    Rectangle {
                        width: 44
                        height: 24
                        radius: 12
                        color: root.nightLightEnabled
                            ? root.theme.accentPrimary
                            : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3))
                        border.color: root.nightLightEnabled
                            ? root.theme.accentPrimary
                            : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15))
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.nightLightEnabled ? (parent.width - width - 3) : 3
                            color: root.nightLightEnabled
                                ? "#ffffff"
                                : root.theme.textPrimary

                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            onClicked: root.setNightLight(!root.nightLightEnabled)
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

            /* Row 2: Color Temperature Slider */
            Item {
                Layout.fillWidth: true
                height: 56
                opacity: root.nightLightEnabled ? 1.0 : 0.45
                Behavior on opacity { NumberAnimation { duration: 150 } }

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
                            text: "Color Temperature"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: root.getNightLightLabel(root.nightLightTemp)
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    /* Interactive Temperature Slider Track */
                    Rectangle {
                        id: nlSliderTrack
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        readonly property real minK: 3000.0
                        readonly property real maxK: 6000.0
                        readonly property real frac: Math.max(0.0, Math.min(1.0, (root.nightLightTemp - minK) / (maxK - minK)))

                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            width: Math.max(0, Math.min(parent.width, parent.width * nlSliderTrack.frac))
                            color: root.theme.accentOrange ?? root.theme.accentPrimary

                            Behavior on width {
                                enabled: !nlSliderMouse.pressed
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }

                        /* Outer halo ring */
                        Rectangle {
                            anchors.centerIn: nlSliderBall
                            width: nlSliderBall.width + (nlSliderMouse.pressed ? 8 : (nlSliderMouse.containsMouse ? 6 : 0))
                            height: width
                            radius: width / 2
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b,
                                           nlSliderMouse.pressed ? 0.35 : (nlSliderMouse.containsMouse ? 0.2 : 0))
                            z: 1

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        /* Slider Knob */
                        Rectangle {
                            id: nlSliderBall
                            width: nlSliderMouse.containsMouse || nlSliderMouse.pressed ? 18 : 16
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            border.color: root.theme.accentOrange ?? root.theme.accentPrimary
                            border.width: 3
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(nlSliderTrack.width - width, (nlSliderTrack.width * nlSliderTrack.frac) - (width / 2)))
                            z: 2

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on x { NumberAnimation { duration: nlSliderMouse.pressed ? 0 : 80; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: nlSliderMouse
                            anchors.fill: parent
                            anchors.margins: -8
                            preventStealing: true
                            hoverEnabled: true
                            cursorShape: root.nightLightEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: root.nightLightEnabled

                            function updateTemp(mouseX) {
                                if (nlSliderTrack.width > 0) {
                                    const ratio = Math.max(0.0, Math.min(1.0, mouseX / nlSliderTrack.width));
                                    const k = Math.round(nlSliderTrack.minK + ratio * (nlSliderTrack.maxK - nlSliderTrack.minK));
                                    root.setNightLightTemp(k);
                                }
                            }

                            onPressed: (mouse) => {
                                mouse.accepted = true;
                                root.dispFlickableRef.interactive = false;
                                updateTemp(mouse.x);
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    mouse.accepted = true;
                                    updateTemp(mouse.x);
                                }
                            }
                            onReleased: root.dispFlickableRef.interactive = true
                            onCanceled: root.dispFlickableRef.interactive = true
                        }
                    }

                    /* Kelvin Badge */
                    Rectangle {
                        width: 64
                        height: 26
                        radius: 6
                        color: root.theme.bgBase
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: root.nightLightTemp + " K"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.nightLightEnabled ? (root.theme.accentOrange ?? root.theme.accentPrimary) : root.theme.textMuted
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

            /* Row 3: Temperature Presets */
            DisplayWarmthPresets {
                root: self.root
            }
        }
    }
}
