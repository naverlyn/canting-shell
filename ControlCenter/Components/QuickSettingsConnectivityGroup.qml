import QtQuick
import QtQuick.Layouts
import ".."

    Rectangle {
        id: tileGroupCard
    required property var hostGrid
        visible: ControlCenterConfig.groupTilesEnabled && ControlCenterConfig.groupedTiles.length > 0
        Layout.fillWidth: true
        implicitWidth: 300
        implicitHeight: groupGrid.implicitHeight + 16 + (groupTitle.visible ? groupTitle.height + 6 : 0)
        Layout.preferredHeight: implicitHeight
        height: implicitHeight
        radius: 12
        color: Qt.rgba(hostGrid.theme.textPrimary.r, hostGrid.theme.textPrimary.g, hostGrid.theme.textPrimary.b, 0.04)
        border.color: hostGrid.theme.bgBorder
        border.width: 1

        Text {
            id: groupTitle
            visible: ControlCenterConfig.isLiveEdit || text !== ""
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 12
            anchors.topMargin: 8
            height: 14
            text: ControlCenterConfig.isLiveEdit ? "" : ControlCenterConfig.getCardTitle("connectivity")
            font.family: hostGrid.font
            font.pixelSize: 10
            font.bold: true
            color: hostGrid.theme.textSecondary

            // Inline editor (live edit): click, type, press Enter
            TextInput {
                visible: ControlCenterConfig.isLiveEdit
                width: Math.max(80, tileGroupCard.width - 40)
                height: 14
                text: ControlCenterConfig.getCardTitle("connectivity")
                font.family: hostGrid.font
                font.pixelSize: 10
                font.bold: true
                color: hostGrid.theme.textPrimary
                selectByMouse: true
                clip: true
                maximumLength: 28
                onEditingFinished: ControlCenterConfig.setCardTitle("connectivity", text)

                Text {
                    visible: parent.text === "" && !parent.activeFocus
                    text: "Add a title…"
                    font: parent.font
                    color: hostGrid.theme.textMuted
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.bottom
                    height: 1
                    color: parent.activeFocus ? hostGrid.theme.accentPrimary : hostGrid.theme.bgBorder
                }
            }
        }

        GridLayout {
            id: groupGrid
            anchors {
                left: parent.left
                right: parent.right
                top: groupTitle.visible ? groupTitle.bottom : parent.top
                topMargin: groupTitle.visible ? 6 : 8
                leftMargin: 8
                rightMargin: 8
            }
            columns: ControlCenterConfig.groupSize
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
                    readonly property real tileCellWidth: Math.max(80, Math.floor((groupGrid.width - groupGrid.columnSpacing * (groupGrid.columns - 1)) / groupGrid.columns))
                    readonly property bool iconOnly: groupGrid.columns >= 4
                    readonly property bool showStatus: groupGrid.columns <= 2

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
                        if (isActive) {
                            return Qt.rgba(
                                hostGrid.theme.accentPrimary.r,
                                hostGrid.theme.accentPrimary.g,
                                hostGrid.theme.accentPrimary.b,
                                isHovered ? 0.42 : 0.32
                            );
                        }
                        return isHovered ? Qt.rgba(hostGrid.theme.textPrimary.r, hostGrid.theme.textPrimary.g, hostGrid.theme.textPrimary.b, 0.12) : Qt.rgba(hostGrid.theme.textPrimary.r, hostGrid.theme.textPrimary.g, hostGrid.theme.textPrimary.b, 0.06);
                    }
                    border.color: isActive
                        ? Qt.rgba(hostGrid.theme.accentPrimary.r, hostGrid.theme.accentPrimary.g, hostGrid.theme.accentPrimary.b, 0.85)
                        : (hostGrid.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 130 } }

                    HoverHandler { id: groupTileHover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: groupTileBtn.iconOnly ? 0 : 8
                        anchors.rightMargin: groupTileBtn.iconOnly ? 0 : 8
                        spacing: 8

                        Item { visible: groupTileBtn.iconOnly; Layout.fillWidth: true }

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: groupTileBtn.isActive
                                ? Qt.rgba(hostGrid.theme.accentPrimary.r, hostGrid.theme.accentPrimary.g, hostGrid.theme.accentPrimary.b, 0.38)
                                : Qt.rgba(hostGrid.theme.textPrimary.r, hostGrid.theme.textPrimary.g, hostGrid.theme.textPrimary.b, 0.10)
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                font.family: hostGrid.font
                                font.pixelSize: 14
                                color: hostGrid.theme.textPrimary
                                text: hostGrid.getTileIcon(groupTileBtn.tid)
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            visible: !groupTileBtn.iconOnly

                            Text {
                                text: groupTileBtn.modelData.label ?? ""
                                font.family: hostGrid.font
                                font.pixelSize: 11
                                font.bold: true
                                color: hostGrid.theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: groupTileBtn.showStatus && (groupTileBtn.tid === "wifi" || (groupTileBtn.tid === "bluetooth" && hostGrid.btAvailable && hostGrid.btEnabled))
                                text: {
                                    if (groupTileBtn.tid === "wifi") return hostGrid.wifiEnabled ? (hostGrid.currentSsid || "On") : "Off";
                                    if (groupTileBtn.tid === "bluetooth") return (hostGrid.btAvailable && hostGrid.btEnabled) ? "On" : "";
                                    return "";
                                }
                                font.family: hostGrid.font
                                font.pixelSize: 9
                                color: groupTileBtn.isActive ? hostGrid.theme.accentPrimary : hostGrid.theme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Item { visible: groupTileBtn.iconOnly; Layout.fillWidth: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !ControlCenterConfig.isLiveEdit
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => hostGrid.triggerTileAction(groupTileBtn.tid, mouse.button === Qt.RightButton)
                    }

                    // Remove from group (live edit): the tile returns to the Available Tiles pool
                    Rectangle {
                        visible: ControlCenterConfig.isLiveEdit
                        width: 16
                        height: 16
                        radius: 8
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 4
                        anchors.rightMargin: 4
                        z: 15
                        scale: groupRemoveArea.pressed ? 0.9 : 1.0
                        color: groupRemoveArea.containsMouse
                            ? hostGrid.theme.accentRed
                            : Qt.rgba(hostGrid.theme.accentRed.r, hostGrid.theme.accentRed.g, hostGrid.theme.accentRed.b, 0.22)
                        border.color: groupRemoveArea.containsMouse
                            ? hostGrid.theme.accentRed
                            : Qt.rgba(hostGrid.theme.accentRed.r, hostGrid.theme.accentRed.g, hostGrid.theme.accentRed.b, 0.45)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 8
                            font.bold: true
                            color: groupRemoveArea.containsMouse ? "#ffffff" : hostGrid.theme.accentRed
                        }

                        MouseArea {
                            id: groupRemoveArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            onClicked: ControlCenterConfig.removeTile(groupTileBtn.tid)
                        }
                    }
                }
            }
        }
    }
