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
    property alias speedMouseRef: speedMouse
    id: mainCol
    width: parent.width
    spacing: 20

    Text {
        text: "Mouse & Touchpad"
        font.family: root.font
        font.pixelSize: 20
        font.bold: true
        color: root.theme.textPrimary
        Layout.fillWidth: true
    }

    /* Mouse Group */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "Mouse"
            font.family: root.font
            font.pixelSize: 13
            font.bold: true
            color: root.theme.textSecondary
            Layout.leftMargin: 4
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: mouseCol.implicitHeight + 16
            radius: 12
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                id: mouseCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0

                /* Primary Button Toggle Row */
                Item {
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
                                text: "Primary Button"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                            }

                            Text {
                                text: root.leftHanded ? "Right button is primary (Left-handed)" : "Left button is primary (Default)"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        /* Toggle Switch (matching media_1791696732618_a22a3e76.png) */
                        Rectangle {
                            id: leftHandedSwitch
                            width: 44
                            height: 24
                            radius: 12
                            color: root.leftHanded ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 160 } }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.leftHanded ? parent.width - width - 3 : 3
                                color: root.leftHanded ? "#ffffff" : root.theme.textPrimary

                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.leftHanded = !root.leftHanded;
                                    root.applyHyprKeyword("input:left_handed", root.leftHanded ? "true" : "false");
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

                /* Mouse Speed Row */
                Item {
                    Layout.fillWidth: true
                    height: 52

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 16

                        Text {
                            text: "Mouse Speed"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                            Layout.preferredWidth: 120
                            Layout.alignment: Qt.AlignVCenter
                        }

                        /* Slider Track */
                        Rectangle {
                            id: speedTrack
                            Layout.fillWidth: true
                            height: 7
                            radius: 3.5
                            color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14)
                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            Layout.alignment: Qt.AlignVCenter

                            /* Fill mapped from -1.0 to 1.0 (range of 2.0) */
                            Rectangle {
                                height: parent.height
                                radius: parent.radius
                                width: Math.max(0, Math.min(parent.width, parent.width * ((root.pointerSensitivity + 1.0) / 2.0)))
                                color: root.theme.accentPrimary

                                Behavior on width {
                                    enabled: !speedMouse.pressed
                                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                }
                            }

                            // Outer halo ring on hover/press
                            Rectangle {
                                anchors.centerIn: speedKnob
                                width: speedKnob.width + (speedMouse.pressed ? 8 : (speedMouse.containsMouse ? 6 : 0))
                                height: width
                                radius: width / 2
                                color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, speedMouse.pressed ? 0.35 : (speedMouse.containsMouse ? 0.2 : 0))
                                z: 1

                                Behavior on width { NumberAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            // Tactile white knob
                            Rectangle {
                                id: speedKnob
                                width: speedMouse.containsMouse || speedMouse.pressed ? 17 : 15
                                height: width
                                radius: width / 2
                                color: "#ffffff"
                                border.color: root.theme.accentPrimary
                                border.width: 3
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(speedTrack.width - width, (speedTrack.width * ((root.pointerSensitivity + 1.0) / 2.0)) - (width / 2)))
                                z: 2

                                Behavior on width { NumberAnimation { duration: 120 } }
                                Behavior on x {
                                    enabled: !speedMouse.pressed
                                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                }
                            }

                            MouseArea {
                                id: speedMouse
                                anchors.fill: parent
                                anchors.margins: -8
                                preventStealing: true
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (mouse) => {
                                    mouse.accepted = true;
                                    const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                    root.pointerSensitivity = Math.round(((frac * 2.0) - 1.0) * 100) / 100;
                                    root.applyHyprKeyword("input:sensitivity", root.pointerSensitivity);
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed) {
                                        mouse.accepted = true;
                                        const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                        root.pointerSensitivity = Math.round(((frac * 2.0) - 1.0) * 100) / 100;
                                        root.applyHyprKeyword("input:sensitivity", root.pointerSensitivity);
                                    }
                                }
                                onClicked: (mouse) => {
                                    mouse.accepted = true;
                                    const frac = Math.max(0, Math.min(1.0, mouse.x / width));
                                    root.pointerSensitivity = Math.round(((frac * 2.0) - 1.0) * 100) / 100;
                                    root.applyHyprKeyword("input:sensitivity", root.pointerSensitivity);
                                }
                            }
                        }

                        Text {
                            text: (root.pointerSensitivity > 0 ? "+" : "") + root.pointerSensitivity.toFixed(2)
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            Layout.preferredWidth: 38
                            horizontalAlignment: Text.AlignRight
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

                /* Natural Scrolling Row */
                Item {
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
                                text: "Natural Scrolling"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                            }

                            Text {
                                text: "Scrolling moves content in the opposite direction"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        /* Toggle Switch (matching media_1791696732618_a22a3e76.png) */
                        Rectangle {
                            width: 44
                            height: 24
                            radius: 12
                            color: root.naturalScroll ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 160 } }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.naturalScroll ? parent.width - width - 3 : 3
                                color: root.naturalScroll ? "#ffffff" : root.theme.textPrimary

                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.naturalScroll = !root.naturalScroll;
                                    root.applyHyprKeyword("input:natural_scroll", root.naturalScroll ? "true" : "false");
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /* Touchpad Group */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "Touchpad"
            font.family: root.font
            font.pixelSize: 13
            font.bold: true
            color: root.theme.textSecondary
            Layout.leftMargin: 4
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: touchpadCol.implicitHeight + 16
            radius: 12
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                id: touchpadCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0

                /* Row 1: Touchpad Master Enable/Disable */
                Item {
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
                                text: "Touchpad"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                            }

                            Text {
                                text: "Enable or disable touchpad gestures and input"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        /* Toggle Switch (matching media_1791696732618_a22a3e76.png) */
                        Rectangle {
                            id: touchpadMasterSwitch
                            width: 44
                            height: 24
                            radius: 12
                            color: root.touchpadEnabled ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 160 } }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.touchpadEnabled ? parent.width - width - 3 : 3
                                color: root.touchpadEnabled ? "#ffffff" : root.theme.textPrimary

                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setTouchpadState(!root.touchpadEnabled)
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

                /* Row 2: Touchpad Natural Scrolling */
                Item {
                    Layout.fillWidth: true
                    height: 52
                    opacity: root.touchpadEnabled ? 1.0 : 0.4
                    enabled: root.touchpadEnabled
                    Behavior on opacity { NumberAnimation { duration: 160 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "Natural Scrolling"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                            }

                            Text {
                                text: "Two-finger scroll moves content naturally"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        /* Toggle Switch (matching media_1791696732618_a22a3e76.png) */
                        Rectangle {
                            width: 44
                            height: 24
                            radius: 12
                            color: root.touchpadNaturalScroll ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 160 } }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.touchpadNaturalScroll ? parent.width - width - 3 : 3
                                color: root.touchpadNaturalScroll ? "#ffffff" : root.theme.textPrimary

                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.touchpadNaturalScroll = !root.touchpadNaturalScroll;
                                    root.applyHyprKeyword("input:touchpad:natural_scroll", root.touchpadNaturalScroll ? "true" : "false");
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

                /* Row 3: Tap to Click */
                Item {
                    Layout.fillWidth: true
                    height: 52
                    opacity: root.touchpadEnabled ? 1.0 : 0.4
                    enabled: root.touchpadEnabled
                    Behavior on opacity { NumberAnimation { duration: 160 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "Tap to Click"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                            }

                            Text {
                                text: "Tap touchpad to click instead of pressing down"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        /* Toggle Switch (matching media_1791696732618_a22a3e76.png) */
                        Rectangle {
                            width: 44
                            height: 24
                            radius: 12
                            color: root.tapToClick ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 160 } }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.tapToClick ? parent.width - width - 3 : 3
                                color: root.tapToClick ? "#ffffff" : root.theme.textPrimary

                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.tapToClick = !root.tapToClick;
                                    root.applyHyprKeyword("input:touchpad:tap-to-click", root.tapToClick ? "true" : "false");
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

                /* Row 4: Disable while typing */
                Item {
                    Layout.fillWidth: true
                    height: 52
                    opacity: root.touchpadEnabled ? 1.0 : 0.4
                    enabled: root.touchpadEnabled
                    Behavior on opacity { NumberAnimation { duration: 160 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "Disable While Typing"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                            }

                            Text {
                                text: "Prevent accidental palm taps when using the keyboard"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        /* Toggle Switch (matching media_1791696732618_a22a3e76.png) */
                        Rectangle {
                            width: 44
                            height: 24
                            radius: 12
                            color: root.disableWhileTyping ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 160 } }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.disableWhileTyping ? parent.width - width - 3 : 3
                                color: root.disableWhileTyping ? "#ffffff" : root.theme.textPrimary

                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.disableWhileTyping = !root.disableWhileTyping;
                                    root.applyHyprKeyword("input:touchpad:disable_while_typing", root.disableWhileTyping ? "true" : "false");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
