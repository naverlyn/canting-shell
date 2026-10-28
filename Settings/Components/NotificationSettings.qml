/*
 * NotificationSettings.qml
 *
 * Configures modular Notification Toast building blocks (Icon, App Name, Timestamp,
 * Close Button, Title Notification, Body Message, Preview Image, Action Buttons,
 * Timeout Progress Bar, and Urgency Accent Strip), interactive live composer,
 * screen placement, and queue behavior.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../notifications"
import ".."
import "./Notification"
import "./Bar"
import "./Common"

Item {
    id: root
    property alias testNotifProcRef: testNotifProc
    property var theme
    property string font: "Lato Nerd Font"

    property int currentSubTab: 0
    property alias subTabContentAnimation: subTabContentAnim
    property string selectedInspectorBlock: "icon"

    /* Drag & Drop State for Notification Building Blocks */
    property bool isDraggingBlock: false
    property string draggedBlockId: ""
    property string draggedBlockLabel: ""
    property string draggedBlockIcon: "󰂚"
    property int dragSourceZoneIndex: -1    // -1 = pool, 0 = Zone 1 (Header), 1 = Zone 2 (Content), 2 = Zone 3 (Footer)
    property int dragSourceItemIndex: -1
    property real dragMouseX: 0
    property real dragMouseY: 0
    property int dragHoverZoneIndex: -1     // -2 = pool, -1 = none, 0..2 = Zones 1..3
    property int dragHoverItemIndex: -1

    /* Feedback Toast Notification State */
    property string toastMessage: ""
    property bool toastVisible: false
    property bool toastIsWarning: false

    Timer {
        id: toastTimer
        interval: 2800
        repeat: false
        onTriggered: root.toastVisible = false
    }

    function showToast(msg, isWarn) {
        root.toastMessage = msg;
        root.toastIsWarning = Boolean(isWarn);
        root.toastVisible = true;
        toastTimer.restart();
    }

    function withAlpha(col, alpha) {
        if (!col) return Qt.rgba(0, 0, 0, alpha);
        const c = Qt.color(col);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    function getInspectorLabel(blockId) {
        switch (blockId) {
            case "icon": return "App Icon";
            case "appName": return "Header & App Name";
            case "timestamp": return "Timestamp";
            case "closeBtn": return "Dismiss Button";
            case "title": return "Title Notification";
            case "body": return "Body Message";
            case "image": return "Preview Image";
            case "buttons": return "Action Buttons";
            case "progressBar": return "Timeout Progress Bar";
            case "card": return "Card & Accent Strip";
            default: return "App Icon";
        }
    }

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

    /* Drag & Drop Handlers */
    function startBlockDrag(blockId, blockLabel, blockIcon, srcZoneIdx, srcItemIdx, rootX, rootY) {
        root.draggedBlockId = blockId;
        root.draggedBlockLabel = blockLabel;
        root.draggedBlockIcon = blockIcon;
        root.dragSourceZoneIndex = srcZoneIdx;
        root.dragSourceItemIndex = srcItemIdx;
        root.dragMouseX = rootX;
        root.dragMouseY = rootY;
        root.dragHoverZoneIndex = srcZoneIdx;
        root.dragHoverItemIndex = srcItemIdx;
        root.isDraggingBlock = true;
        updateBlockDragHover(rootX, rootY);
    }

    function _checkZoneHit(zoneCard, blocksRep, zoneIdx, rootX, rootY) {
        if (!zoneCard || !zoneCard.visible) return false;
        const pt = zoneCard.mapFromItem(root, rootX, rootY);
        if (pt.x >= -8 && pt.x <= zoneCard.width + 8 && pt.y >= -8 && pt.y <= zoneCard.height + 8) {
            root.dragHoverZoneIndex = zoneIdx;
            if (!blocksRep || blocksRep.count === 0) {
                root.dragHoverItemIndex = 0;
                return true;
            }
            let foundIdx = blocksRep.count;
            for (let i = 0; i < blocksRep.count; i++) {
                const cItem = blocksRep.itemAt(i);
                if (!cItem) continue;
                const cPt = cItem.mapFromItem(root, rootX, rootY);
                if (cPt.y <= cItem.height * 0.5) {
                    foundIdx = i;
                    break;
                }
            }
            root.dragHoverItemIndex = foundIdx;
            return true;
        }
        return false;
    }

    function updateBlockDragHover(rootX, rootY) {
        root.dragMouseX = rootX;
        root.dragMouseY = rootY;
        if (!root.isDraggingBlock) return;

        if (_checkZoneHit(layoutCard.zone1Card, layoutCard.zone1Repeater, 0, rootX, rootY)) return;
        if (_checkZoneHit(layoutCard.zone2Card, layoutCard.zone2Repeater, 1, rootX, rootY)) return;
        if (_checkZoneHit(layoutCard.zone3Card, layoutCard.zone3Repeater, 2, rootX, rootY)) return;

        if (layoutCard.poolCard && root.dragSourceZoneIndex >= 0) {
            const poolPt = layoutCard.poolCard.mapFromItem(root, rootX, rootY);
            if (poolPt.x >= -8 && poolPt.x <= layoutCard.poolCard.width + 8 && poolPt.y >= -8 && poolPt.y <= layoutCard.poolCard.height + 8) {
                root.dragHoverZoneIndex = -2;
                root.dragHoverItemIndex = -1;
                return;
            }
        }

        root.dragHoverZoneIndex = -1;
        root.dragHoverItemIndex = -1;
    }

    function finishBlockDrag() {
        if (!root.isDraggingBlock) return;
        const bId = root.draggedBlockId;
        const bLabel = root.draggedBlockLabel;
        const targetZ = root.dragHoverZoneIndex;
        const targetI = root.dragHoverItemIndex;

        root.isDraggingBlock = false;
        root.dragHoverZoneIndex = -1;
        root.dragHoverItemIndex = -1;

        if (!bId) return;

        if (targetZ === -2) {
            NotificationService.setBlockVisible(bId, false);
            root.showToast("Removed " + bLabel + " to Available Building Blocks");
            return;
        }

        if (targetZ >= 0 && targetZ <= 2) {
            NotificationService.moveBlockToZoneAt(bId, targetZ, targetI);
            const zName = targetZ === 0 ? "Header Bar" : (targetZ === 1 ? "Main Content" : "Footer & Actions");
            root.showToast("Placed " + bLabel + " in " + zName);
        }
    }

    /* Legacy test notification process fallback */
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
        interactive: !root.isDraggingBlock
            && !notificationToastPositionPlacementGroupInst.miniDragAreaRef.pressed
            && !notificationToastPositionPlacementGroupInst.xMarginMouseRef.pressed
            && !notificationToastPositionPlacementGroupInst.yMarginMouseRef.pressed

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
            spacing: 18

            // Page Header Row (matches BarSettings.qml & ControlCenterSettings.qml)
            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 3
                    Text {
                        text: "Notification Settings"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                    Text {
                        text: "Configure modular toast building blocks, live composer, screen placement, and appearance"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                Process {
                    id: openBackupProc
                    command: ["qs", "ipc", "call", "settings", "open", "backup"]
                    running: false
                }

                ActionButton {
                    iconText: "󰂚"
                    label: "Send Test Toast"
                    onClicked: {
                        NotificationService.sendCustomNotification({});
                        root.showToast("Dispatched test toast popup (" + root.getPositionLabel(root.toastPos) + ")");
                    }
                }

                ActionButton {
                    iconText: "󰁯"
                    label: "Backup & Restore"
                    onClicked: openBackupProc.running = true
                }

                ActionButton {
                    iconText: "󰦛"
                    label: "Reset to Default"
                    onClicked: {
                        NotificationService.resetDefaults();
                        root.showToast("Restored default Notification building blocks & settings");
                    }
                }
            }

            ParallelAnimation {
                id: subTabContentAnim
                NumberAnimation {
                    target: subTabContentContainer
                    property: "opacity"
                    from: 0.3
                    to: 1.0
                    duration: 210
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: subTabContentTranslate
                    property: "y"
                    from: 6
                    to: 0
                    duration: 210
                    easing.type: Easing.OutCubic
                }
            }

            NotificationSubTabSelector {
                root: root
            }

            ColumnLayout {
                id: subTabContentContainer
                Layout.fillWidth: true
                spacing: 20
                transform: Translate { id: subTabContentTranslate; y: 0 }

                // =============================================================
                // SUB-TAB 0: MODULAR BUILDING BLOCKS, LIVE COMPOSER & INSPECTOR
                // =============================================================
                ColumnLayout {
                    visible: root.currentSubTab === 0
                    Layout.fillWidth: true
                    spacing: 20

                    NotificationLivePreviewCard {
                        root: root
                    }

                    NotificationLayoutCard {
                        id: layoutCard
                        root: root
                    }

                    NotificationBlockInspectorCard {
                        root: root
                    }
                }

                // =============================================================
                // SUB-TAB 1: PLACEMENT, GENERAL BEHAVIOR & HISTORY QUEUE
                // =============================================================
                ColumnLayout {
                    visible: root.currentSubTab === 1
                    Layout.fillWidth: true
                    spacing: 20

                    NotificationGeneralSettingsGroup {
                        root: root
                    }

                    NotificationToastPositionPlacementGroup {
                        id: notificationToastPositionPlacementGroupInst
                        root: root
                    }

                    NotificationHistoryQueueGroup {
                        root: root
                    }
                }
            }
        }
    }

    NotificationDragGhost {
        root: root
    }

    StatusToast {
        root: root
    }
}
