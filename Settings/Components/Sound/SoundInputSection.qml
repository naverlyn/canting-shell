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

ColumnLayout {
    required property var root
    id: self
    property alias srcMouseRef: srcMouse
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Input"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: inputCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: inputCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Input Device Selector */
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
                            text: "Input Device"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: root.defaultSource ? (root.defaultSource.description || root.defaultSource.name || "Default Microphone") : "No input device available"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    /* Standardized Expand / Change Button */
                    Rectangle {
                        id: srcChangeBtn
                        implicitWidth: root.actionBtnWidth
                        implicitHeight: root.btnHeight
                        Layout.preferredWidth: root.actionBtnWidth
                        Layout.preferredHeight: root.btnHeight
                        width: root.actionBtnWidth
                        height: root.btnHeight
                        radius: root.btnRadius
                        color: root.inputDropdownOpen 
                            ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)) 
                            : (srcChangeHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)))
                        border.color: root.inputDropdownOpen 
                            ? root.theme.accentPrimary 
                            : (srcChangeHover.hovered ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: srcChangeHover }

                        Text {
                            anchors.centerIn: parent
                            text: root.inputDropdownOpen ? "Done" : "Change"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.inputDropdownOpen ? root.theme.accentPrimary : root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.inputDropdownOpen) root.outputDropdownOpen = false;
                                root.inputDropdownOpen = !root.inputDropdownOpen;
                            }
                        }
                    }
                }
            }

            /* Expandable Input Devices List */
            SoundExpandableInputDevicesList {
                root: self.root
            }

            /* Row Divider */
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
            }

            /* Row 2: Input Volume Slider & Mute Toggle */
            Item {
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
                            text: root.isSourceMuted ? "Muted" : (root.sourceVolumePercent + "%")
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.isSourceMuted ? (root.theme.accentRed ?? "#f7768e") : (root.theme.accentPrimary ?? "#7aa2f7")
                        }
                    }

                    /* Slider Track */
                    Rectangle {
                        id: srcSliderTrack
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
                            width: Math.max(0, Math.min(parent.width, parent.width * (root.sourceVolumePercent / 100)))
                            color: root.isSourceMuted ? (root.theme.textSecondary ?? "#666666") : root.theme.accentPrimary
                        }

                        // Outer halo ring
                        Rectangle {
                            anchors.centerIn: srcKnob
                            width: srcKnob.width + (srcMouse.pressed ? 8 : (srcMouse.containsMouse ? 6 : 0))
                            height: width
                            radius: width / 2
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, srcMouse.pressed ? 0.35 : (srcMouse.containsMouse ? 0.2 : 0))
                            z: 1

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Tactile white knob
                        Rectangle {
                            id: srcKnob
                            width: srcMouse.containsMouse || srcMouse.pressed ? 17 : 15
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            border.color: root.isSourceMuted ? (root.theme.textSecondary ?? "#666666") : root.theme.accentPrimary
                            border.width: 3
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(srcSliderTrack.width - width, (srcSliderTrack.width * (root.sourceVolumePercent / 100)) - (width / 2)))
                            z: 2

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on x {
                                enabled: !srcMouse.pressed
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            id: srcMouse
                            anchors.fill: parent
                            anchors.topMargin: -8
                            anchors.bottomMargin: -8
                            preventStealing: true
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => {
                                mouse.accepted = true;
                                root.setSourceVolumeFromMouse(mouse.x, srcSliderTrack.width);
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    mouse.accepted = true;
                                    root.setSourceVolumeFromMouse(mouse.x, srcSliderTrack.width);
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
                        color: root.isSourceMuted 
                            ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.18) 
                            : (srcMuteHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)))
                        border.color: root.isSourceMuted 
                            ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.4) 
                            : (srcMuteHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: srcMuteHover }

                        Text {
                            anchors.centerIn: parent
                            text: root.isSourceMuted ? "Muted" : "Mute"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.isSourceMuted ? root.theme.accentRed : root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleSourceMute()
                        }
                    }
                }
            }
        }
    }
}
