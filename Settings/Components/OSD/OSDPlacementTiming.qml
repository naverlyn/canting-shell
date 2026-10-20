import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../osd"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    property alias marginXMouseRef: marginXMouse
    property alias marginYMouseRef: marginYMouse
    property alias timeoutMouseRef: timeoutMouse
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Placement & Timing"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: slidersCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: slidersCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Horizontal Placement (X) Slider */
            Item {
                Layout.fillWidth: true
                height: 56

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        Layout.preferredWidth: 160
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: root.isEdgeX ? (root.osdPos === "left" ? "Left Edge Margin (X)" : "Right Edge Margin (X)") : "Horizontal Offset (X)"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: {
                                if (root.isEdgeX) return root.marginX + " px";
                                if (root.marginX === 0) return "Centered (0 px)";
                                if (root.marginX > 0) return "+" + root.marginX + " px (Right)";
                                return root.marginX + " px (Left)";
                            }
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentPrimary
                        }
                    }

                    /* Libadwaita Tactile Seekbar Track */
                    Rectangle {
                        id: marginXTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        height: 6
                        radius: 3
                        color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.1)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        readonly property real fraction: {
                            const range = root.maxValX - root.minValX;
                            if (range <= 0) return 0;
                            return Math.max(0, Math.min(1, (root.marginX - root.minValX) / range));
                        }

                        // Progress fill
                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            width: Math.max(0, Math.min(parent.width, parent.width * marginXTrack.fraction))
                            color: root.theme.accentPrimary
                        }

                        // Halo ring on hover/press
                        Rectangle {
                            anchors.centerIn: marginXKnob
                            width: marginXKnob.width + (marginXMouse.pressed ? 8 : (marginXMouse.containsMouse ? 6 : 0))
                            height: width
                            radius: width / 2
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, marginXMouse.pressed ? 0.35 : (marginXMouse.containsMouse ? 0.2 : 0))
                            z: 1

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Tactile white knob
                        Rectangle {
                            id: marginXKnob
                            width: marginXMouse.containsMouse || marginXMouse.pressed ? 17 : 15
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            border.color: root.theme.accentPrimary
                            border.width: 3
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(marginXTrack.width - width, (marginXTrack.width * marginXTrack.fraction) - (width / 2)))
                            z: 2

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on x {
                                enabled: !marginXMouse.pressed
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            id: marginXMouse
                            anchors.fill: parent
                            anchors.topMargin: -12
                            anchors.bottomMargin: -12
                            preventStealing: true
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => {
                                mouse.accepted = true;
                                const frac = Math.max(0, Math.min(1, mouse.x / marginXTrack.width));
                                const val = Math.round(root.minValX + frac * (root.maxValX - root.minValX));
                                OSDService.setMarginX(val);
                                OSDService.testOSD();
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    mouse.accepted = true;
                                    const frac = Math.max(0, Math.min(1, mouse.x / marginXTrack.width));
                                    const val = Math.round(root.minValX + frac * (root.maxValX - root.minValX));
                                    OSDService.setMarginX(val);
                                    OSDService.testOSD();
                                }
                            }
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

            /* Row 2: Vertical Placement (Y) Slider */
            Item {
                Layout.fillWidth: true
                height: 56

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        Layout.preferredWidth: 160
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: root.isEdgeY ? (root.osdPos === "top" ? "Top Edge Margin (Y)" : "Bottom Edge Margin (Y)") : "Vertical Offset (Y)"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: {
                                if (root.isEdgeY) return root.marginY + " px";
                                if (root.marginY === 0) return "Centered (0 px)";
                                if (root.marginY > 0) return "+" + root.marginY + " px (Down)";
                                return root.marginY + " px (Up)";
                            }
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentPrimary
                        }
                    }

                    /* Libadwaita Tactile Seekbar Track */
                    Rectangle {
                        id: marginYTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        height: 6
                        radius: 3
                        color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.1)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        readonly property real fraction: {
                            const range = root.maxValY - root.minValY;
                            if (range <= 0) return 0;
                            return Math.max(0, Math.min(1, (root.marginY - root.minValY) / range));
                        }

                        // Progress fill
                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            width: Math.max(0, Math.min(parent.width, parent.width * marginYTrack.fraction))
                            color: root.theme.accentPrimary
                        }

                        // Halo ring on hover/press
                        Rectangle {
                            anchors.centerIn: marginYKnob
                            width: marginYKnob.width + (marginYMouse.pressed ? 8 : (marginYMouse.containsMouse ? 6 : 0))
                            height: width
                            radius: width / 2
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, marginYMouse.pressed ? 0.35 : (marginYMouse.containsMouse ? 0.2 : 0))
                            z: 1

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Tactile white knob
                        Rectangle {
                            id: marginYKnob
                            width: marginYMouse.containsMouse || marginYMouse.pressed ? 17 : 15
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            border.color: root.theme.accentPrimary
                            border.width: 3
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(marginYTrack.width - width, (marginYTrack.width * marginYTrack.fraction) - (width / 2)))
                            z: 2

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on x {
                                enabled: !marginYMouse.pressed
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            id: marginYMouse
                            anchors.fill: parent
                            anchors.topMargin: -12
                            anchors.bottomMargin: -12
                            preventStealing: true
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => {
                                mouse.accepted = true;
                                const frac = Math.max(0, Math.min(1, mouse.x / marginYTrack.width));
                                const val = Math.round(root.minValY + frac * (root.maxValY - root.minValY));
                                OSDService.setMarginY(val);
                                OSDService.testOSD();
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    mouse.accepted = true;
                                    const frac = Math.max(0, Math.min(1, mouse.x / marginYTrack.width));
                                    const val = Math.round(root.minValY + frac * (root.maxValY - root.minValY));
                                    OSDService.setMarginY(val);
                                    OSDService.testOSD();
                                }
                            }
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

            /* Row 3: Display Timeout Slider */
            Item {
                Layout.fillWidth: true
                height: 56

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        Layout.preferredWidth: 160
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: "Display Duration"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: (root.timeoutMs / 1000).toFixed(1) + " s"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentPrimary
                        }
                    }

                    /* Libadwaita Tactile Seekbar Track */
                    Rectangle {
                        id: timeoutTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        height: 6
                        radius: 3
                        color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.1)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        // Range: 800ms to 4000ms
                        readonly property real fraction: Math.max(0, Math.min(1, (root.timeoutMs - 800) / 3200))

                        // Progress fill
                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            width: Math.max(0, Math.min(parent.width, parent.width * timeoutTrack.fraction))
                            color: root.theme.accentPrimary
                        }

                        // Halo ring on hover/press
                        Rectangle {
                            anchors.centerIn: timeoutKnob
                            width: timeoutKnob.width + (timeoutMouse.pressed ? 8 : (timeoutMouse.containsMouse ? 6 : 0))
                            height: width
                            radius: width / 2
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, timeoutMouse.pressed ? 0.35 : (timeoutMouse.containsMouse ? 0.2 : 0))
                            z: 1

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Tactile white knob
                        Rectangle {
                            id: timeoutKnob
                            width: timeoutMouse.containsMouse || timeoutMouse.pressed ? 17 : 15
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            border.color: root.theme.accentPrimary
                            border.width: 3
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(timeoutTrack.width - width, (timeoutTrack.width * timeoutTrack.fraction) - (width / 2)))
                            z: 2

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on x {
                                enabled: !timeoutMouse.pressed
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            id: timeoutMouse
                            anchors.fill: parent
                            anchors.topMargin: -12
                            anchors.bottomMargin: -12
                            preventStealing: true
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => {
                                mouse.accepted = true;
                                const frac = Math.max(0, Math.min(1, mouse.x / timeoutTrack.width));
                                OSDService.setTimeoutMs(Math.round(800 + frac * 3200));
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    mouse.accepted = true;
                                    const frac = Math.max(0, Math.min(1, mouse.x / timeoutTrack.width));
                                    OSDService.setTimeoutMs(Math.round(800 + frac * 3200));
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
