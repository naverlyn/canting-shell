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
                                radius: 6
                                color: hostWrapper.isDropTarget
                                    ? Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.22)
                                    : (cardDragMouseArea.containsMouse
                                        ? Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.12)
                                        : Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.08))
                                border.color: hostWrapper.isDropTarget ? hostCenter.theme.accentPrimary : hostCenter.theme.bgBorder
                                border.width: hostWrapper.isDropTarget ? 1.5 : 1

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 6
                                    spacing: 6

                                    // Drag handle grip icon
                                    Text {
                                        text: "󰇘"
                                        font.family: hostCenter.font
                                        font.pixelSize: 14
                                        color: hostWrapper.isDropTarget ? hostCenter.theme.accentPrimary : hostCenter.theme.textMuted
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

                                    // Media Compact/Big/Auto Mode Toggle Button
                                    Rectangle {
                                        visible: hostWrapper.cardId === "media"
                                        implicitWidth: mediaStyleTxt.implicitWidth + 12
                                        height: 22
                                        radius: 4
                                        z: 10
                                        color: mediaStyleMouse.containsMouse
                                            ? Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.24)
                                            : Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.12)
                                        border.color: hostCenter.theme.accentPrimary
                                        border.width: 1

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

                                    // Remove Card Button
                                    Rectangle {
                                        implicitWidth: removeText.implicitWidth + 14
                                        height: 22
                                        radius: 4
                                        z: 10
                                        color: cRemoveMouse.containsMouse
                                            ? (hostCenter.theme.accentRed ?? "#e05252")
                                            : Qt.rgba(1, 1, 1, 0.08)
                                        border.color: cRemoveMouse.containsMouse ? (hostCenter.theme.accentRed ?? "#e05252") : hostCenter.theme.bgBorder
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        Text {
                                            id: removeText
                                            anchors.centerIn: parent
                                            text: "Remove"
                                            font.family: hostCenter.font
                                            font.pixelSize: 10
                                            font.bold: true
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

                                // Drag MouseArea covering toolbar except right buttons
                                MouseArea {
                                    id: cardDragMouseArea
                                    anchors {
                                        top: parent.top
                                        bottom: parent.bottom
                                        left: parent.left
                                        right: parent.right
                                        rightMargin: hostWrapper.cardId === "media" ? 155 : 72
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
