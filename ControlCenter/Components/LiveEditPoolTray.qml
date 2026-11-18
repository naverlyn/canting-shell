import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: poolTray
    required property var hostCenter

    visible: ControlCenterConfig.isLiveEdit && (ControlCenterConfig.unassignedCards.length > 0 || ControlCenterConfig.unassignedTiles.length > 0)
    width: parent.width
    implicitHeight: poolCol.implicitHeight + 20
    radius: 10
    color: Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.04)
    border.color: hostCenter.theme.bgBorder
    border.width: 1

    ColumnLayout {
        id: poolCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 10

        // Available Sections (Unassigned Cards)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: ControlCenterConfig.unassignedCards.length > 0

            Text {
                text: "Available Sections"
                font.family: hostCenter.font
                font.pixelSize: 11
                font.bold: true
                color: hostCenter.theme.textSecondary
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: ControlCenterConfig.unassignedCards

                    delegate: Rectangle {
                        required property var modelData
                        height: 26
                        implicitWidth: cChipRow.implicitWidth + 16
                        radius: 13
                        color: cChipMouse.containsMouse
                            ? Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.16)
                            : Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.06)
                        border.color: cChipMouse.containsMouse
                            ? hostCenter.theme.accentPrimary
                            : Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.45)
                        border.width: 1
                        scale: cChipMouse.pressed ? 0.96 : 1.0
                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                        RowLayout {
                            id: cChipRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: modelData.icon || ""
                                font.family: hostCenter.font
                                font.pixelSize: 11
                                color: hostCenter.theme.accentPrimary
                            }

                            Text {
                                text: modelData.label || ""
                                font.family: hostCenter.font
                                font.pixelSize: 11
                                font.bold: true
                                color: hostCenter.theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: cChipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            onClicked: ControlCenterConfig.setCardVisible(modelData.id, true)
                        }
                    }
                }
            }
        }

        // Available Quick Settings Tiles (Unassigned Tiles)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: ControlCenterConfig.unassignedTiles.length > 0

            Text {
                text: "Available Tiles (click to add to a panel)"
                font.family: hostCenter.font
                font.pixelSize: 11
                font.bold: true
                color: hostCenter.theme.textSecondary
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: ControlCenterConfig.unassignedTiles

                    delegate: Rectangle {
                        required property var modelData
                        height: 26
                        implicitWidth: tChipRow.implicitWidth + 16
                        radius: 13
                        color: tChipMouse.containsMouse
                            ? Qt.rgba(hostCenter.theme.accentPrimary.r, hostCenter.theme.accentPrimary.g, hostCenter.theme.accentPrimary.b, 0.16)
                            : Qt.rgba(hostCenter.theme.textPrimary.r, hostCenter.theme.textPrimary.g, hostCenter.theme.textPrimary.b, 0.06)
                        border.color: tChipMouse.containsMouse ? hostCenter.theme.accentPrimary : hostCenter.theme.bgBorder
                        border.width: 1
                        scale: tChipMouse.pressed ? 0.96 : 1.0
                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                        RowLayout {
                            id: tChipRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: (modelData.icon || "󰒓")
                                font.family: hostCenter.font
                                font.pixelSize: 11
                                color: hostCenter.theme.accentPrimary
                            }

                            Text {
                                text: modelData.label || ""
                                font.family: hostCenter.font
                                font.pixelSize: 11
                                color: hostCenter.theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: tChipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            // Place the tile as its own module in the emptiest panel; drag it to rearrange
                            onClicked: ControlCenterConfig.setCardVisible("tile:" + modelData.id, true)
                        }
                    }
                }
            }
        }
    }
}
