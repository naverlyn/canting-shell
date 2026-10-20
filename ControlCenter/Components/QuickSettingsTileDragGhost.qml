import QtQuick
import QtQuick.Layouts
import ".."

    Rectangle {
        id: dragGhost
    required property var hostGrid
        readonly property bool active: hostGrid.isDragging && hostGrid.draggedTileId !== ""
        visible: opacity > 0.01
        z: 9999
        width: 140
        height: 40
        radius: 8
        color: hostGrid.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.22)
        border.color: hostGrid.theme.accentPrimary
        border.width: 1.5
        scale: active ? 1.05 : 0.85
        opacity: active ? 0.95 : 0.0
        x: Math.max(0, Math.min(hostGrid.width - width, hostGrid.dragMouseX - (width / 2)))
        y: Math.max(0, Math.min(hostGrid.height - height, hostGrid.dragMouseY - (height / 2)))

        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
                font.family: hostGrid.font
                font.pixelSize: 15
                color: hostGrid.theme.accentPrimary
                text: {
                    const def = ControlCenterConfig.getTileDef(hostGrid.draggedTileId);
                    return def ? def.icon : "󰒓";
                }
            }

            Text {
                font.family: hostGrid.font
                font.pixelSize: 12
                font.bold: true
                color: hostGrid.theme.textPrimary
                text: {
                    const def = ControlCenterConfig.getTileDef(hostGrid.draggedTileId);
                    return def ? def.label : "";
                }
            }
        }
    }
