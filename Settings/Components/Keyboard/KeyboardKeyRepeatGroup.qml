import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    property alias delayMouseRef: delayMouse
    property alias rateMouseRef: rateMouse
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Key Repeat"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: repeatCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: repeatCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Repeat Delay Row */
            Item {
                Layout.fillWidth: true
                height: 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    Text {
                        text: "Repeat Delay"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                        Layout.preferredWidth: 120
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        id: delayTrack
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: root.theme.bgSelected
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            width: Math.max(0, Math.min(parent.width, parent.width * ((root.repeatDelay - 150) / 850)))
                            color: root.theme.accentPrimary
                        }

                        // Outer halo ring on hover/press
                        Rectangle {
                            anchors.centerIn: delayKnob
                            width: delayKnob.width + (delayMouse.pressed ? 8 : (delayMouse.containsMouse ? 6 : 0))
                            height: width
                            radius: width / 2
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, delayMouse.pressed ? 0.35 : (delayMouse.containsMouse ? 0.2 : 0))
                            z: 1

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Tactile white knob
                        Rectangle {
                            id: delayKnob
                            width: delayMouse.containsMouse || delayMouse.pressed ? 17 : 15
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            border.color: root.theme.accentPrimary
                            border.width: 3
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(delayTrack.width - width, (delayTrack.width * ((root.repeatDelay - 150) / 850)) - (width / 2)))
                            z: 2

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on x {
                                enabled: !delayMouse.pressed
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            id: delayMouse
                            anchors.fill: parent
                            anchors.margins: -8
                            preventStealing: true
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => {
                                mouse.accepted = true;
                                const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                root.repeatDelay = Math.round(150 + frac * 850);
                                root.applyHyprKeyword("input:repeat_delay", root.repeatDelay);
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    mouse.accepted = true;
                                    const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                    root.repeatDelay = Math.round(150 + frac * 850);
                                    root.applyHyprKeyword("input:repeat_delay", root.repeatDelay);
                                }
                            }
                            onClicked: (mouse) => {
                                mouse.accepted = true;
                                const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                root.repeatDelay = Math.round(150 + frac * 850);
                                root.applyHyprKeyword("input:repeat_delay", root.repeatDelay);
                            }
                        }
                    }

                    Text {
                        text: root.repeatDelay + " ms"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textSecondary
                        Layout.preferredWidth: 64
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignVCenter
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

            /* Repeat Speed / Rate Row */
            Item {
                Layout.fillWidth: true
                height: 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    Text {
                        text: "Repeat Speed"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                        Layout.preferredWidth: 120
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        id: rateTrack
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: root.theme.bgSelected
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            width: Math.max(0, Math.min(parent.width, parent.width * ((root.repeatRate - 10) / 90)))
                            color: root.theme.accentPrimary
                        }

                        // Outer halo ring on hover/press
                        Rectangle {
                            anchors.centerIn: rateKnob
                            width: rateKnob.width + (rateMouse.pressed ? 8 : (rateMouse.containsMouse ? 6 : 0))
                            height: width
                            radius: width / 2
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, rateMouse.pressed ? 0.35 : (rateMouse.containsMouse ? 0.2 : 0))
                            z: 1

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Tactile white knob
                        Rectangle {
                            id: rateKnob
                            width: rateMouse.containsMouse || rateMouse.pressed ? 17 : 15
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            border.color: root.theme.accentPrimary
                            border.width: 3
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(rateTrack.width - width, (rateTrack.width * ((root.repeatRate - 10) / 90)) - (width / 2)))
                            z: 2

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on x {
                                enabled: !rateMouse.pressed
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            id: rateMouse
                            anchors.fill: parent
                            anchors.margins: -8
                            preventStealing: true
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => {
                                mouse.accepted = true;
                                const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                root.repeatRate = Math.round(10 + frac * 90);
                                root.applyHyprKeyword("input:repeat_rate", root.repeatRate);
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    mouse.accepted = true;
                                    const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                    root.repeatRate = Math.round(10 + frac * 90);
                                    root.applyHyprKeyword("input:repeat_rate", root.repeatRate);
                                }
                            }
                            onClicked: (mouse) => {
                                mouse.accepted = true;
                                const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                root.repeatRate = Math.round(10 + frac * 90);
                                root.applyHyprKeyword("input:repeat_rate", root.repeatRate);
                            }
                        }
                    }

                    Text {
                        text: root.repeatRate + " / sec"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textSecondary
                        Layout.preferredWidth: 64
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignVCenter
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

            /* Interactive Test Field Row */
            Item {
                Layout.fillWidth: true
                height: 60

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Text {
                        text: "Test Repeat"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                        Layout.preferredWidth: 120
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 8
                        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                        border.color: testInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                        border.width: testInput.activeFocus ? 2 : 1
                        Layout.alignment: Qt.AlignVCenter

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 8

                            TextInput {
                                id: testInput
                                Layout.fillWidth: true
                                font.family: root.font
                                font.pixelSize: 13
                                color: root.theme.textPrimary
                                clip: true
                                selectByMouse: true

                                Text {
                                    text: "Type here to test key repeat speed..."
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textSecondary
                                    visible: !testInput.text && !testInput.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: "✕"
                                font.family: root.font
                                font.pixelSize: 13
                                color: clearMouse.containsMouse ? root.theme.textPrimary : root.theme.textSecondary
                                visible: testInput.text.length > 0

                                MouseArea {
                                    id: clearMouse
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: testInput.text = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
