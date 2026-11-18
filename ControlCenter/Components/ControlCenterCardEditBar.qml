import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: cardEditBar
    required property var hostCenter
    required property var hostMainRect
    required property var hostWrapper

    visible: ControlCenterConfig.isLiveEdit && hostWrapper.isCardEnabled
    width: parent.width
    height: 30
    radius: 7
    color: hostWrapper.isDropTarget
        ? Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.22)
        : (cardDragMouseArea.containsMouse
            ? Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.11)
            : Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.06))
    border.color: hostWrapper.isDropTarget
        ? hostCenter.theme.accentPrimary
        : (cardDragMouseArea.containsMouse
            ? Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.45)
            : hostCenter.theme.bgBorder)
    border.width: hostWrapper.isDropTarget ? 1.5 : 1

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 5
        spacing: 6

        // Drag handle grip icon
        Text {
            text: "󰇘"
            font.family: hostCenter.font
            font.pixelSize: 13
            color: (hostWrapper.isDropTarget || cardDragMouseArea.containsMouse)
                ? hostCenter.theme.accentPrimary
                : hostCenter.theme.textMuted
        }

        Text {
            readonly property var cardDefObj: ControlCenterConfig.getCardDef(hostWrapper.cardId)
            visible: (cardDefObj ? cardDefObj.icon : "") !== ""
            text: cardDefObj ? cardDefObj.icon : ""
            font.family: hostCenter.font
            font.pixelSize: 12
            color: hostCenter.theme.accentPrimary
        }

        Text {
            text: ControlCenterConfig.getCardDef(hostWrapper.cardId).label
            font.family: hostCenter.font
            font.pixelSize: 11
            font.bold: true
            color: hostCenter.theme.textPrimary
        }

        Text {
            text: hostWrapper.isDropTarget ? "Drop here" : (cardDragMouseArea.containsMouse ? "· Drag" : "")
            font.family: hostCenter.font
            font.pixelSize: 10
            color: hostWrapper.isDropTarget ? hostCenter.theme.accentPrimary : hostCenter.theme.textMuted
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Row {
            id: rightButtonsRow
            spacing: 5
            z: 10

            // Media Compact/Big/Auto Mode Toggle Button
            Rectangle {
                visible: hostWrapper.cardId === "media"
                implicitWidth: mediaStyleTxt.implicitWidth + 12
                height: 20
                radius: 5
                color: mediaStyleMouse.containsMouse
                    ? Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.24)
                    : Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.12)
                border.color: Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, mediaStyleMouse.containsMouse ? 0.9 : 0.5)
                border.width: 1
                scale: mediaStyleMouse.pressed ? 0.95 : 1.0
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                    id: mediaStyleTxt
                    anchors.centerIn: parent
                    text: ControlCenterConfig.mediaEffectiveBadge
                    font.family: hostCenter.font
                    font.pixelSize: 9
                    font.bold: true
                    color: hostCenter.theme.accentPrimary
                }

                MouseArea {
                    id: mediaStyleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true
                    onClicked: ControlCenterConfig.cycleMediaWidgetStyle()
                }
            }

            // Connectivity grid size (2x2 .. 6x6)
            Rectangle {
                visible: hostWrapper.cardId === "connectivity"
                implicitWidth: sizeTxt.implicitWidth + 12
                height: 20
                radius: 5
                color: sizeMouse.containsMouse
                    ? Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.24)
                    : Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.12)
                border.color: Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, sizeMouse.containsMouse ? 0.9 : 0.5)
                border.width: 1
                scale: sizeMouse.pressed ? 0.95 : 1.0
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                    id: sizeTxt
                    anchors.centerIn: parent
                    text: ControlCenterConfig.groupSize + "x" + ControlCenterConfig.groupSize
                    font.family: hostCenter.font
                    font.pixelSize: 9
                    font.bold: true
                    color: hostCenter.theme.accentPrimary
                }

                MouseArea {
                    id: sizeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true
                    onClicked: ControlCenterConfig.cycleGroupSize()
                }
            }

            // Remove Card Button
            Rectangle {
                implicitWidth: removeText.implicitWidth + 14
                height: 20
                radius: 5
                color: cRemoveMouse.containsMouse
                    ? (hostCenter.theme.accentRed ?? "#e05252")
                    : Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.06)
                border.color: cRemoveMouse.containsMouse
                    ? (hostCenter.theme.accentRed ?? "#e05252")
                    : hostCenter.theme.bgBorder
                border.width: 1
                scale: cRemoveMouse.pressed ? 0.95 : 1.0

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                    id: removeText
                    anchors.centerIn: parent
                    text: "Remove"
                    font.family: hostCenter.font
                    font.pixelSize: 10
                    font.bold: cRemoveMouse.containsMouse
                    color: cRemoveMouse.containsMouse ? "#ffffff" : hostCenter.theme.textSecondary
                }

                MouseArea {
                    id: cRemoveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true
                    onClicked: ControlCenterConfig.setCardVisible(hostWrapper.cardId, false)
                }
            }
        }
    }

    // Drag MouseArea covering toolbar except right buttons
    MouseArea {
        id: cardDragMouseArea
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            rightMargin: rightButtonsRow.width + 10
        }
        hoverEnabled: true
        cursorShape: hostCenter.isDraggingCard ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        preventStealing: true

        property real pressX: 0
        property real pressY: 0
        property bool dragStarted: false

        onPressed: (mouse) => {
            pressX = mouse.x;
            pressY = mouse.y;
            dragStarted = false;
        }

        onPositionChanged: (mouse) => {
            if (!pressed) return;
            const pt = cardDragMouseArea.mapToItem(hostMainRect, mouse.x, mouse.y);
            if (!dragStarted && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 5) {
                dragStarted = true;
                hostCenter.startCardDrag(hostWrapper.cardId, hostWrapper.enabledIdx, pt.x, pt.y);
            } else if (dragStarted) {
                hostCenter.updateCardDrag(pt.x, pt.y);
            }
        }

        onReleased: (mouse) => {
            if (dragStarted) {
                const pt = cardDragMouseArea.mapToItem(hostMainRect, mouse.x, mouse.y);
                hostCenter.updateCardDrag(pt.x, pt.y);
                hostCenter.finishCardDrag();
                dragStarted = false;
            }
        }

        onCanceled: {
            if (dragStarted) {
                hostCenter.finishCardDrag();
                dragStarted = false;
            }
        }
    }
}
