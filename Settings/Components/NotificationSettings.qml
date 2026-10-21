/*
 * NotificationSettings.qml
 *
 * Manages notification preferences, Do Not Disturb (DND) state,
 * toast popup screen position & margins, and history queue using
 * the native NotificationService singleton.
 *
 * Useful troubleshooting commands:
 *   notify-send "Test" "Sample notification"
 *   qs ipc call notifications dnd_toggle
 *   qs ipc call notifications set_position top-left
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../notifications"
import ".."
import "./Notification"
import "./Common"

Item {
    id: root
    property alias testNotifProcRef: testNotifProc
    property var theme
    property string font

    /* Reference to notification service state */
    readonly property bool isDnd: NotificationService.doNotDisturb
    readonly property int totalCount: NotificationService.count
    readonly property string toastPos: NotificationService.toastPosition || "top-right"
    readonly property int marginX: NotificationService.toastMarginX
    readonly property int marginY: NotificationService.toastMarginY
    readonly property bool isCenterPos: toastPos.indexOf("center") !== -1
    readonly property bool isPositionCustomized: toastPos !== "top-right" || marginX !== 10 || marginY !== 10

    readonly property var positionOptions: [
        { id: "top-left",      label: "Top Left",      icon: "󰁛" },
        { id: "top-center",    label: "Top Center",    icon: "󰁝" },
        { id: "top-right",     label: "Top Right",     icon: "󰁜" },
        { id: "bottom-left",   label: "Bottom Left",   icon: "󰁙" },
        { id: "bottom-center", label: "Bottom Center", icon: "󰁅" },
        { id: "bottom-right",  label: "Bottom Right",  icon: "󰁚" }
    ]

    function getPositionLabel(posId) {
        for (let i = 0; i < root.positionOptions.length; i++) {
            if (root.positionOptions[i].id === posId) return root.positionOptions[i].label;
        }
        return "Top Right";
    }

    function snapPreviewPointToPosition(px, py, w, h) {
        const isBottomHalf = py > (h * 0.5);
        const vPart = isBottomHalf ? "bottom" : "top";
        let hPart = "right";
        if (px < w * 0.34) hPart = "left";
        else if (px <= w * 0.66) hPart = "center";
        return vPart + "-" + hPart;
    }

    /* Test notification process */
    Process {
        id: testNotifProc
        command: ["notify-send", "Test Notification", "Notification toast positioned at " + root.getPositionLabel(root.toastPos) + "!"]
        running: false
    }

    /* Main Scrollable View */
    Flickable {
        id: notifFlickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !notificationToastPositionPlacementGroupInst.miniDragAreaRef.pressed && !notificationToastPositionPlacementGroupInst.xMarginMouseRef.pressed && !notificationToastPositionPlacementGroupInst.yMarginMouseRef.pressed

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15)
            }
        }

        ColumnLayout {
            id: mainCol
            width: parent.width - 10
            spacing: 20

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Notifications"
                    font.family: root.font
                    font.pixelSize: 20
                    font.bold: true
                    color: root.theme.textPrimary
                    Layout.fillWidth: true
                }

                Process {
                    id: openBackupProc
                    command: ["qs", "ipc", "call", "settings", "open", "backup"]
                    running: false
                }

                ActionButton {
                    iconText: "󰁯"
                    label: "Backup & Restore"
                    onClicked: openBackupProc.running = true
                }
            }

            /* General Settings Group */
            NotificationGeneralSettingsGroup {
                root: root
            }

            /* Toast Position & Placement Group */
            NotificationToastPositionPlacementGroup {
                id: notificationToastPositionPlacementGroupInst
                root: root
            }

            /* History Queue Group */
            NotificationHistoryQueueGroup {
                root: root
            }
        }
    }
}
