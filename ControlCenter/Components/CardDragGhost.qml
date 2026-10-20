import QtQuick
import QtQuick.Layouts
import ".."

        Rectangle {
            id: cardDragGhost
    required property var hostCenter
    required property var hostMainRect
            readonly property bool active: hostCenter.isDraggingCard && hostCenter.draggedCardId !== ""
            visible: opacity > 0.01
            z: 9999
            width: 200
            height: 36
            radius: 8
            color: hostCenter.theme.bgSurface
            border.color: hostCenter.theme.accentPrimary
            border.width: 1.5
            scale: active ? 1.05 : 0.85
            opacity: active ? 0.95 : 0.0
            x: Math.max(10, Math.min(hostMainRect.width - width - 10, hostCenter.dragCardMouseX - (width / 2)))
            y: Math.max(10, Math.min(hostMainRect.height - height - 10, hostCenter.dragCardMouseY - (height / 2)))

            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    font.family: hostCenter.font
                    font.pixelSize: 14
                    color: hostCenter.theme.accentPrimary
                    text: ControlCenterConfig.getCardDef(hostCenter.draggedCardId).icon
                }

                Text {
                    font.family: hostCenter.font
                    font.pixelSize: 12
                    font.bold: true
                    color: hostCenter.theme.textPrimary
                    text: ControlCenterConfig.getCardDef(hostCenter.draggedCardId).label
                }

                Text {
                    font.family: hostCenter.font
                    font.pixelSize: 10
                    color: hostCenter.theme.accentPrimary
                    text: "󰁝 Move"
                }
            }
        }
