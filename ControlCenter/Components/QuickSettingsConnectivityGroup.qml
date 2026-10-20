import QtQuick
import QtQuick.Layouts
import ".."

    Rectangle {
        id: tileGroupCard
    required property var hostGrid
        visible: ControlCenterConfig.groupTilesEnabled && ControlCenterConfig.groupedTiles.length > 0
        Layout.fillWidth: true
        implicitWidth: 300
        implicitHeight: groupGrid.implicitHeight + 16
        Layout.preferredHeight: implicitHeight
        height: implicitHeight
        radius: 12
        color: Qt.rgba(hostGrid.theme.textPrimary.r, hostGrid.theme.textPrimary.g, hostGrid.theme.textPrimary.b, 0.04)
        border.color: hostGrid.theme.bgBorder
        border.width: 1

        GridLayout {
            id: groupGrid
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            columns: 2
            rowSpacing: 8
            columnSpacing: 8
            uniformCellWidths: true

            Repeater {
                model: ControlCenterConfig.groupedTiles
                delegate: Rectangle {
                    id: groupTileBtn
                    required property var modelData
                    required property int index
                    readonly property string tid: modelData.id
                    readonly property bool isActive: hostGrid.isTileActive(groupTileBtn.tid)
                    readonly property bool isHovered: groupTileHover.hovered
                    readonly property real tileCellWidth: Math.max(80, Math.floor((groupGrid.width - groupGrid.columnSpacing) / 2))

                    Layout.fillWidth: true
                    Layout.preferredWidth: tileCellWidth
                    Layout.minimumWidth: tileCellWidth
                    Layout.maximumWidth: tileCellWidth
                    Layout.preferredHeight: 50
                    implicitHeight: 50
                    height: 50
                    radius: 10
                    color: {
                        if (groupTileBtn.tid === "mic" && hostGrid.micMuted) return Qt.rgba(hostGrid.theme.accentRed.r, hostGrid.theme.accentRed.g, hostGrid.theme.accentRed.b, 0.25);
                        if (groupTileBtn.tid === "mute" && hostGrid.sinkMuted) return Qt.rgba(hostGrid.theme.accentRed.r, hostGrid.theme.accentRed.g, hostGrid.theme.accentRed.b, 0.25);
                        if (isActive) return isHovered ? Qt.lighter(hostGrid.theme.accentPrimary, 1.12) : hostGrid.theme.accentPrimary;
                        return isHovered ? Qt.rgba(hostGrid.theme.textPrimary.r, hostGrid.theme.textPrimary.g, hostGrid.theme.textPrimary.b, 0.12) : Qt.rgba(hostGrid.theme.textPrimary.r, hostGrid.theme.textPrimary.g, hostGrid.theme.textPrimary.b, 0.06);
                    }
                    border.color: isActive ? "transparent" : (hostGrid.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 130 } }

                    HoverHandler { id: groupTileHover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: groupTileBtn.isActive ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(hostGrid.theme.textPrimary.r, hostGrid.theme.textPrimary.g, hostGrid.theme.textPrimary.b, 0.10)
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                font.family: hostGrid.font
                                font.pixelSize: 14
                                color: groupTileBtn.isActive ? (hostGrid.theme.bgBase ?? "#ffffff") : hostGrid.theme.textPrimary
                                text: hostGrid.getTileIcon(groupTileBtn.tid)
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: groupTileBtn.modelData.label ?? ""
                                font.family: hostGrid.font
                                font.pixelSize: 11
                                font.bold: true
                                color: groupTileBtn.isActive ? (hostGrid.theme.bgBase ?? "#ffffff") : hostGrid.theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: {
                                    if (groupTileBtn.tid === "wifi") return hostGrid.wifiEnabled ? (hostGrid.currentSsid || "On") : "Off";
                                    if (groupTileBtn.tid === "bluetooth") return (hostGrid.btAvailable && hostGrid.btEnabled) ? "On" : "Off";
                                    if (groupTileBtn.tid === "airplane") return hostGrid.airplaneEnabled ? "On" : "Off";
                                    if (groupTileBtn.tid === "dnd") return hostGrid.dndEnabled ? "On" : "Off";
                                    return groupTileBtn.isActive ? "On" : "Off";
                                }
                                font.family: hostGrid.font
                                font.pixelSize: 9
                                color: groupTileBtn.isActive ? Qt.rgba(1, 1, 1, 0.75) : hostGrid.theme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => hostGrid.triggerTileAction(groupTileBtn.tid, mouse.button === Qt.RightButton)
                    }
                }
            }
        }
    }
