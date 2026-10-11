/*
 * NotificationSettings.qml
 *
 * Manages notification preferences, Do Not Disturb (DND) state,
 * and history queue using the native NotificationService singleton.
 *
 * Useful troubleshooting commands:
 *   notify-send "Test" "Sample notification"
 *   qs ipc call notifications toggle
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../notifications"
import ".."

Item {
    id: root
    property var theme
    property string font

    /* Reference to notification service state */
    readonly property bool isDnd: NotificationService.doNotDisturb
    readonly property int totalCount: NotificationService.count

    /* Test notification process */
    Process {
        id: testNotifProc
        command: ["notify-send", "Test Notification", "Your notifications are working properly!"]
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
                text: "Notifications"
                font.family: root.font
                font.pixelSize: 20
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }

            /* General Settings Group */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "General"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: generalCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: generalCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Row 1: Do Not Disturb Toggle */
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
                                        text: "Do Not Disturb"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Pause banner popups and alert notifications"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                /* Toggle Switch */
                                Rectangle {
                                    id: dndSwitch
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: root.isDnd ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 160 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.isDnd ? parent.width - width - 3 : 3
                                        color: root.isDnd ? root.theme.bgBase : root.theme.textPrimary

                                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
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

                        /* Row 2: Test Notification */
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
                                        text: "Test Notification"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Send a sample toast popup to verify delivery"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: testBtn
                                    width: 58
                                    height: 32
                                    radius: 6
                                    color: testHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : root.theme.bgBase
                                    border.color: testHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: testHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Test"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: testNotifProc.running = true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* History Queue Group */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "History"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: historyCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: historyCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

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
                                        text: root.totalCount > 0 
                                            ? "Active Notifications: " + root.totalCount 
                                            : "No Active Notifications"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Recent notifications are displayed in the Control Center"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: clearBtn
                                    width: 80
                                    height: 32
                                    radius: 6
                                    readonly property bool canClear: root.totalCount > 0
                                    opacity: canClear ? 1.0 : 0.4
                                    color: clearHover.hovered && canClear ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : root.theme.bgBase
                                    border.color: clearHover.hovered && canClear ? (root.theme.accentRed ?? "#f7768e") : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: clearHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Clear All"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: clearBtn.canClear && clearHover.hovered ? (root.theme.accentRed ?? "#f7768e") : root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: clearBtn.canClear ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (clearBtn.canClear) NotificationService.dismissAll();
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
}
