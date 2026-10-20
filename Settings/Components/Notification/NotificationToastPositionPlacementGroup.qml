import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../notifications"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    property alias miniDragAreaRef: miniDragArea
    property alias xMarginMouseRef: xMarginMouse
    property alias yMarginMouseRef: yMarginMouse
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
                            mouse.accepted = true;
                            const pt = miniDragArea.mapToItem(monitorPreview, mouse.x, mouse.y);
                            monitorPreview.dragHoverPos = root.snapPreviewPointToPosition(pt.x, pt.y, monitorPreview.width, monitorPreview.height);
                            monitorPreview.draggingToast = true;
                        }

                        onPositionChanged: (mouse) => {
                            if (!pressed) return;
                            mouse.accepted = true;
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

                        // Outer halo ring on hover/press
                        Rectangle {
                            anchors.centerIn: xMarginKnob
                            width: xMarginKnob.width + (xMarginMouse.pressed ? 8 : (xMarginMouse.containsMouse ? 6 : 0))
                            height: width
                            radius: width / 2
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, xMarginMouse.pressed ? 0.35 : (xMarginMouse.containsMouse ? 0.2 : 0))
                            z: 1

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Tactile white knob
                        Rectangle {
                            id: xMarginKnob
                            width: xMarginMouse.containsMouse || xMarginMouse.pressed ? 17 : 15
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            border.color: root.theme.accentPrimary
                            border.width: 3
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(xMarginTrack.width - width, (xMarginTrack.width * xMarginTrack.frac) - (width / 2)))
                            z: 2

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on x {
                                enabled: !xMarginMouse.pressed
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            id: xMarginMouse
                            anchors.fill: parent
                            anchors.margins: -8
                            preventStealing: true
                            enabled: !root.isCenterPos
                            hoverEnabled: true
                            cursorShape: !root.isCenterPos ? Qt.PointingHandCursor : Qt.ArrowCursor
                            function updateVal(mx) {
                                const f = Math.max(0, Math.min(1, mx / xMarginTrack.width));
                                NotificationService.setToastMarginX(Math.round(f * 200));
                            }
                            onPressed: (mouse) => { mouse.accepted = true; updateVal(mouse.x); }
                            onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateVal(mouse.x); } }
                            onClicked: (mouse) => { mouse.accepted = true; updateVal(mouse.x); }
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

                        // Outer halo ring on hover/press
                        Rectangle {
                            anchors.centerIn: yMarginKnob
                            width: yMarginKnob.width + (yMarginMouse.pressed ? 8 : (yMarginMouse.containsMouse ? 6 : 0))
                            height: width
                            radius: width / 2
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, yMarginMouse.pressed ? 0.35 : (yMarginMouse.containsMouse ? 0.2 : 0))
                            z: 1

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Tactile white knob
                        Rectangle {
                            id: yMarginKnob
                            width: yMarginMouse.containsMouse || yMarginMouse.pressed ? 17 : 15
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            border.color: root.theme.accentPrimary
                            border.width: 3
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(yMarginTrack.width - width, (yMarginTrack.width * yMarginTrack.frac) - (width / 2)))
                            z: 2

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on x {
                                enabled: !yMarginMouse.pressed
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            id: yMarginMouse
                            anchors.fill: parent
                            anchors.margins: -8
                            preventStealing: true
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            function updateVal(mx) {
                                const f = Math.max(0, Math.min(1, mx / yMarginTrack.width));
                                NotificationService.setToastMarginY(Math.round(f * 200));
                            }
                            onPressed: (mouse) => { mouse.accepted = true; updateVal(mouse.x); }
                            onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateVal(mouse.x); } }
                            onClicked: (mouse) => { mouse.accepted = true; updateVal(mouse.x); }
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
