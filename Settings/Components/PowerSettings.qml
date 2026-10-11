/*
 * PowerSettings.qml
 *
 * Manages display power saving, Wayland idle inhibition (Caffeine),
 * and system power controls (suspend, reboot, poweroff).
 *
 * Useful troubleshooting commands:
 *   hyprctl dispatch dpms off
 *   systemctl suspend
 *   qs ipc call idle toggle
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

Item {
    id: root
    property var theme
    property string font

    /* Wayland idle inhibitor state */
    property bool keepAwake: false

    /* Power action processes */
    Process {
        id: turnOffDisplaysProc
        command: ["hyprctl", "dispatch", "dpms", "off"]
        running: false
    }

    Process {
        id: suspendProc
        command: ["systemctl", "suspend"]
        running: false
    }

    Process {
        id: rebootProc
        command: ["systemctl", "reboot"]
        running: false
    }

    Process {
        id: poweroffProc
        command: ["systemctl", "poweroff"]
        running: false
    }

    Process {
        id: toggleIdleProc
        command: ["qs", "ipc", "call", "idle", "toggle"]
        running: false
    }

    /* Main Scrollable View */
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 20

            Text {
                text: "Power"
                font.family: root.font
                font.pixelSize: 20
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }

            /* Screen & Idle Sleep Group */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Display & Sleep"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: sleepCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: sleepCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Row 1: Keep Awake Toggle */
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
                                        text: "Keep Awake"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Inhibit idle sleep and keep monitors from turning off"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: awakeSwitch
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: root.keepAwake ? (root.theme.accentOrange ?? root.theme.accentPrimary) : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 160 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.keepAwake ? parent.width - width - 3 : 3
                                        color: root.keepAwake ? "#ffffff" : root.theme.textPrimary

                                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.keepAwake = !root.keepAwake;
                                            toggleIdleProc.running = true;
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

                        /* Row 2: Inactivity Lock Information */
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
                                        text: "Automatic Screen Lock"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Lock session after inactivity via hypridle"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "10 minutes"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textSecondary
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

                        /* Row 3: Turn Off Displays Now */
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
                                        text: "Turn Off Displays"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Put monitors into power-saving standby immediately"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: dpmsBtn
                                    width: 80
                                    height: 32
                                    radius: 6
                                    color: dpmsHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : root.theme.bgBase
                                    border.color: dpmsHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: dpmsHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Turn Off"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: turnOffDisplaysProc.running = true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* System Power Controls Group */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "System Actions"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: powerActionsCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: powerActionsCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Suspend Row */
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
                                        text: "Suspend"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Put computer into low-power sleep state"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: suspendBtn
                                    width: 80
                                    height: 32
                                    radius: 6
                                    color: suspHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : root.theme.bgBase
                                    border.color: suspHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: suspHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Suspend"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: suspendProc.running = true
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

                        /* Restart Row */
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
                                        text: "Restart"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Reboot the operating system"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: rebootBtn
                                    width: 80
                                    height: 32
                                    radius: 6
                                    color: rebHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : root.theme.bgBase
                                    border.color: rebHover.hovered ? (root.theme.accentOrange ?? root.theme.accentPrimary) : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: rebHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Restart"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: rebootProc.running = true
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

                        /* Shut Down Row */
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
                                        text: "Power Off"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Completely turn off the computer"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: shutdownBtn
                                    width: 80
                                    height: 32
                                    radius: 6
                                    color: shutHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : root.theme.bgBase
                                    border.color: shutHover.hovered ? (root.theme.accentRed ?? "#f7768e") : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: shutHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Shut Down"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: shutHover.hovered ? (root.theme.accentRed ?? "#f7768e") : root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: poweroffProc.running = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
