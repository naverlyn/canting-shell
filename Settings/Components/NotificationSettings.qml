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

Item {
    id: root
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
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

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
                                        text: "Send a sample toast popup to verify delivery and placement"
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

            /* Toast Position & Placement Group */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 8

                    Text {
                        text: "Toast Position & Placement"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    Text {
                        text: "·  Click any region or drag the toast card to move"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: monitorPreview.draggingToast
                            ? ("Snap to: " + root.getPositionLabel(monitorPreview.dragHoverPos))
                            : ("Active: " + root.getPositionLabel(root.toastPos))
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentPrimary
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: posCol.implicitHeight + 24
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: posCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 12
                        }
                        spacing: 14

                        /* Interactive Screen Preview Canvas */
                        Rectangle {
                            id: monitorPreview
                            Layout.fillWidth: true
                            height: 170
                            radius: 10
                            color: root.theme.bgBase
                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1
                            clip: true

                            property bool draggingToast: false
                            property string dragHoverPos: root.toastPos

                            /* Subtle desktop frame */
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 6
                                radius: 7
                                color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.03)
                                border.color: Qt.rgba(1, 1, 1, 0.04)
                                border.width: 1
                            }

                            /* 6 Interactive Snap Zones inside Monitor Preview */
                            GridLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                columns: 3
                                rows: 2
                                columnSpacing: 10
                                rowSpacing: 10

                                Repeater {
                                    model: root.positionOptions
                                    delegate: Rectangle {
                                        id: zoneBox
                                        required property var modelData
                                        readonly property bool isSelected: root.toastPos === modelData.id
                                        readonly property bool isDragTarget: monitorPreview.draggingToast && monitorPreview.dragHoverPos === modelData.id

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 8
                                        color: isDragTarget
                                            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.18)
                                            : (zoneHover.hovered
                                                ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.08)
                                                : "transparent")
                                        border.color: isDragTarget || isSelected
                                            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, isDragTarget ? 0.85 : 0.35)
                                            : (zoneHover.hovered ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.18)) : Qt.rgba(1, 1, 1, 0.05))
                                        border.width: isDragTarget ? 1.5 : 1

                                        Behavior on color { ColorAnimation { duration: 130 } }
                                        Behavior on border.color { ColorAnimation { duration: 130 } }

                                        HoverHandler { id: zoneHover }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: !zoneBox.isSelected || monitorPreview.draggingToast
                                            text: zoneBox.modelData.label
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: zoneBox.isDragTarget || zoneHover.hovered
                                            color: zoneBox.isDragTarget
                                                ? root.theme.accentPrimary
                                                : (zoneHover.hovered ? root.theme.textPrimary : root.theme.textMuted)
                                            opacity: zoneBox.isDragTarget || zoneHover.hovered ? 0.95 : 0.45
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.setToastPosition(zoneBox.modelData.id)
                                        }
                                    }
                                }
                            }

                            /* Draggable / Animated Mini Toast Preview Card */
                            Rectangle {
                                id: miniToastCard
                                width: 126
                                height: 42
                                radius: 8
                                z: 10

                                readonly property string activeP: monitorPreview.draggingToast ? monitorPreview.dragHoverPos : root.toastPos
                                readonly property bool pTop: activeP.indexOf("top") === 0
                                readonly property bool pLeft: activeP.indexOf("left") !== -1
                                readonly property bool pRight: activeP.indexOf("right") !== -1
                                readonly property real scaledMarginX: Math.round((root.marginX / 200) * 28)
                                readonly property real scaledMarginY: Math.round((root.marginY / 200) * 24)

                                readonly property real targetX: pLeft
                                    ? (16 + scaledMarginX)
                                    : (pRight
                                        ? (monitorPreview.width - width - 16 - scaledMarginX)
                                        : Math.round((monitorPreview.width - width) / 2))
                                readonly property real targetY: pTop
                                    ? (16 + scaledMarginY)
                                    : (monitorPreview.height - height - 16 - scaledMarginY)

                                x: targetX
                                y: targetY

                                Behavior on x {
                                    enabled: !monitorPreview.draggingToast
                                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                                }
                                Behavior on y {
                                    enabled: !monitorPreview.draggingToast
                                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                                }

                                scale: monitorPreview.draggingToast ? 1.05 : (miniToastHover.hovered ? 1.02 : 1.0)
                                color: root.theme.bgSurface
                                border.color: root.theme.accentPrimary
                                border.width: 1.5

                                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                HoverHandler { id: miniToastHover }

                                Rectangle {
                                    width: 3
                                    height: parent.height - 12
                                    radius: 1.5
                                    anchors.left: parent.left
                                    anchors.leftMargin: 5
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: root.theme.accentPrimary
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 8
                                    spacing: 6

                                    Text {
                                        text: "󰂚"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        color: root.theme.accentPrimary
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    ColumnLayout {
                                        spacing: 1
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            text: "Toast Popup"
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: root.theme.textPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: root.getPositionLabel(miniToastCard.activeP)
                                            font.family: root.font
                                            font.pixelSize: 9
                                            color: root.theme.textSecondary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                MouseArea {
                                    id: miniDragArea
                                    anchors.fill: parent
                                    preventStealing: true
                                    cursorShape: monitorPreview.draggingToast ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                    onPressed: (mouse) => {
                                        const pt = miniDragArea.mapToItem(monitorPreview, mouse.x, mouse.y);
                                        monitorPreview.dragHoverPos = root.snapPreviewPointToPosition(pt.x, pt.y, monitorPreview.width, monitorPreview.height);
                                        monitorPreview.draggingToast = true;
                                    }

                                    onPositionChanged: (mouse) => {
                                        if (!pressed) return;
                                        const pt = miniDragArea.mapToItem(monitorPreview, mouse.x, mouse.y);
                                        monitorPreview.dragHoverPos = root.snapPreviewPointToPosition(pt.x, pt.y, monitorPreview.width, monitorPreview.height);
                                        miniToastCard.x = Math.max(8, Math.min(monitorPreview.width - miniToastCard.width - 8, pt.x - miniToastCard.width / 2));
                                        miniToastCard.y = Math.max(8, Math.min(monitorPreview.height - miniToastCard.height - 8, pt.y - miniToastCard.height / 2));
                                    }

                                    onReleased: (mouse) => {
                                        if (monitorPreview.draggingToast) {
                                            const targetPos = monitorPreview.dragHoverPos;
                                            monitorPreview.draggingToast = false;
                                            NotificationService.setToastPosition(targetPos);
                                            miniToastCard.x = Qt.binding(() => miniToastCard.targetX);
                                            miniToastCard.y = Qt.binding(() => miniToastCard.targetY);
                                        }
                                    }

                                    onCanceled: {
                                        monitorPreview.draggingToast = false;
                                        miniToastCard.x = Qt.binding(() => miniToastCard.targetX);
                                        miniToastCard.y = Qt.binding(() => miniToastCard.targetY);
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Horizontal Edge Margin (X Offset) */
                        Item {
                            Layout.fillWidth: true
                            height: 44
                            opacity: root.isCenterPos ? 0.45 : 1.0

                            Behavior on opacity { NumberAnimation { duration: 140 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: 175
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Horizontal Margin"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: root.isCenterPos ? "Centered horizontally on screen" : "Distance from left/right edge"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textSecondary
                                    }
                                }

                                Rectangle {
                                    id: xMarginTrack
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12)
                                    Layout.alignment: Qt.AlignVCenter

                                    readonly property real frac: Math.max(0, Math.min(1, root.marginX / 200))

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: parent.width * xMarginTrack.frac
                                        color: root.theme.accentPrimary
                                    }

                                    Rectangle {
                                        width: xMarginMouse.containsMouse || xMarginMouse.pressed ? 16 : 14
                                        height: width
                                        radius: width / 2
                                        color: root.theme.accentPrimary
                                        border.color: root.theme.bgBase
                                        border.width: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(xMarginTrack.width - width, (xMarginTrack.width * xMarginTrack.frac) - (width / 2)))
                                    }

                                    MouseArea {
                                        id: xMarginMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        enabled: !root.isCenterPos
                                        hoverEnabled: true
                                        cursorShape: !root.isCenterPos ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        function updateVal(mx) {
                                            const f = Math.max(0, Math.min(1, mx / xMarginTrack.width));
                                            NotificationService.setToastMarginX(Math.round(f * 200));
                                        }
                                        onPositionChanged: (mouse) => { if (pressed) updateVal(mouse.x); }
                                        onClicked: (mouse) => updateVal(mouse.x)
                                    }
                                }

                                Text {
                                    text: root.marginX + "px"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textSecondary
                                    Layout.preferredWidth: 42
                                    horizontalAlignment: Text.AlignRight
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }

                        /* Vertical Edge Margin (Y Offset) */
                        Item {
                            Layout.fillWidth: true
                            height: 44

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: 175
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Vertical Margin"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Distance from top/bottom edge"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textSecondary
                                    }
                                }

                                Rectangle {
                                    id: yMarginTrack
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12)
                                    Layout.alignment: Qt.AlignVCenter

                                    readonly property real frac: Math.max(0, Math.min(1, root.marginY / 200))

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: parent.width * yMarginTrack.frac
                                        color: root.theme.accentPrimary
                                    }

                                    Rectangle {
                                        width: yMarginMouse.containsMouse || yMarginMouse.pressed ? 16 : 14
                                        height: width
                                        radius: width / 2
                                        color: root.theme.accentPrimary
                                        border.color: root.theme.bgBase
                                        border.width: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(yMarginTrack.width - width, (yMarginTrack.width * yMarginTrack.frac) - (width / 2)))
                                    }

                                    MouseArea {
                                        id: yMarginMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        function updateVal(mx) {
                                            const f = Math.max(0, Math.min(1, mx / yMarginTrack.width));
                                            NotificationService.setToastMarginY(Math.round(f * 200));
                                        }
                                        onPositionChanged: (mouse) => { if (pressed) updateVal(mouse.x); }
                                        onClicked: (mouse) => updateVal(mouse.x)
                                    }
                                }

                                Text {
                                    text: root.marginY + "px"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textSecondary
                                    Layout.preferredWidth: 42
                                    horizontalAlignment: Text.AlignRight
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }

                        /* Reset Position Row */
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4

                            Text {
                                text: "Automatically respects active desktop bar clearance on all edges"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textMuted
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                id: resetPosBtn
                                width: resetPosTxt.implicitWidth + 20
                                height: 28
                                radius: 6
                                opacity: root.isPositionCustomized ? 1.0 : 0.4
                                color: resetPosHover.hovered && root.isPositionCustomized
                                    ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12))
                                    : root.theme.bgBase
                                border.color: resetPosHover.hovered && root.isPositionCustomized
                                    ? root.theme.accentPrimary
                                    : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: resetPosHover }

                                Text {
                                    id: resetPosTxt
                                    anchors.centerIn: parent
                                    text: "Reset Position"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: root.theme.textPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.isPositionCustomized
                                    cursorShape: root.isPositionCustomized ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: NotificationService.resetPositionDefaults()
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
