import QtQuick
import QtQuick.Layouts
import "../../../osd"

Rectangle {
    id: posCard
    required property var root

    Layout.fillWidth: true
    implicitHeight: posCol.implicitHeight + 24
    radius: 12
    color: root.theme.bgSurface
    border.color: root.theme.bgBorder
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

        /* Interactive Screen Preview Canvas with Live Dragging */
        Rectangle {
            id: monitorPreview
            Layout.fillWidth: true
            height: 180
            radius: 10
            color: posCard.root.theme.bgBase
            border.color: posCard.root.theme.bgBorder
            border.width: 1
            clip: true

            /* Desktop frame container */
            Rectangle {
                id: desktopArea
                anchors.fill: parent
                anchors.margins: 6
                radius: 7
                color: Qt.rgba(posCard.root.theme.accentPrimary.r, posCard.root.theme.accentPrimary.g, posCard.root.theme.accentPrimary.b, 0.03)
                border.color: Qt.rgba(1, 1, 1, 0.04)
                border.width: 1
                clip: true

                /* Top Bar representation */
                Rectangle {
                    id: previewTopBar
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 14
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    z: 2

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        Rectangle { width: 14; height: 3; radius: 1.5; color: Qt.rgba(1, 1, 1, 0.12) }
                        Item { Layout.fillWidth: true }
                        Rectangle { width: 20; height: 3; radius: 1.5; color: Qt.rgba(1, 1, 1, 0.12) }
                    }
                }

                /* Click & Drag Area for Interactive Placement */
                MouseArea {
                    id: desktopMouse
                    anchors.fill: parent
                    preventStealing: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (mouse) => {
                        mouse.accepted = true;
                        posCard.root.handlePreviewDrag(mouse.x, mouse.y, width, height);
                    }
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            mouse.accepted = true;
                            posCard.root.handlePreviewDrag(mouse.x, mouse.y, width, height);
                        }
                    }
                }

                /* Simulated OSD Pill reflecting exact orientation and X/Y offset */
                Rectangle {
                    id: previewOsdPill
                    readonly property bool isHoriz: OSDService.isHorizontal
                    width: isHoriz ? 58 : 16
                    height: isHoriz ? 16 : 58
                    radius: 8
                    color: posCard.root.theme.accentPrimary
                    border.color: "#ffffff"
                    border.width: 1.5
                    z: 10

                    x: {
                        if (posCard.root.osdPos === "left") {
                            const frac = posCard.root.maxValX > 0 ? Math.max(0, Math.min(1, posCard.root.marginX / posCard.root.maxValX)) : 0;
                            return Math.max(8, Math.min(desktopArea.width - width - 8, 10 + Math.round(frac * (desktopArea.width / 2))));
                        } else if (posCard.root.osdPos === "right") {
                            const frac = posCard.root.maxValX > 0 ? Math.max(0, Math.min(1, posCard.root.marginX / posCard.root.maxValX)) : 0;
                            return Math.max(8, Math.min(desktopArea.width - width - 8, desktopArea.width - width - 10 - Math.round(frac * (desktopArea.width / 2))));
                        } else {
                            const frac = posCard.root.maxCenterOffsetX > 0 ? Math.max(-1, Math.min(1, posCard.root.marginX / posCard.root.maxCenterOffsetX)) : 0;
                            const maxShift = (desktopArea.width - width) / 2 - 8;
                            return Math.max(8, Math.min(desktopArea.width - width - 8, Math.round((desktopArea.width - width) / 2 + frac * maxShift)));
                        }
                    }

                    y: {
                        if (posCard.root.osdPos === "top") {
                            const frac = posCard.root.maxValY > 0 ? Math.max(0, Math.min(1, posCard.root.marginY / posCard.root.maxValY)) : 0;
                            return Math.max(18, Math.min(desktopArea.height - height - 8, 20 + Math.round(frac * (desktopArea.height / 2))));
                        } else if (posCard.root.osdPos === "bottom") {
                            const frac = posCard.root.maxValY > 0 ? Math.max(0, Math.min(1, posCard.root.marginY / posCard.root.maxValY)) : 0;
                            return Math.max(18, Math.min(desktopArea.height - height - 8, desktopArea.height - height - 10 - Math.round(frac * (desktopArea.height / 2))));
                        } else {
                            const frac = posCard.root.maxCenterOffsetY > 0 ? Math.max(-1, Math.min(1, posCard.root.marginY / posCard.root.maxCenterOffsetY)) : 0;
                            const maxShift = (desktopArea.height - height) / 2 - 12;
                            return Math.max(18, Math.min(desktopArea.height - height - 8, Math.round((desktopArea.height - height) / 2 + frac * maxShift)));
                        }
                    }

                    Behavior on x {
                        enabled: !desktopMouse.pressed
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                    Behavior on y {
                        enabled: !desktopMouse.pressed
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 3
                        visible: previewOsdPill.isHoriz

                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2.5
                            color: "#ffffff"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 3
                            radius: 1.5
                            color: Qt.rgba(0, 0, 0, 0.35)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * 0.7
                                radius: 1.5
                                color: "#ffffff"
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 4
                        anchors.bottomMargin: 4
                        spacing: 3
                        visible: !previewOsdPill.isHoriz

                        Rectangle {
                            Layout.fillHeight: true
                            width: 3
                            radius: 1.5
                            color: Qt.rgba(0, 0, 0, 0.35)
                            Layout.alignment: Qt.AlignHCenter

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: parent.height * 0.7
                                radius: 1.5
                                color: "#ffffff"
                            }
                        }

                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2.5
                            color: "#ffffff"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        /* Position Segmented Pill Track */
        Rectangle {
            id: posSegmentTrack
            Layout.fillWidth: true
            height: 34
            radius: 7
            color: posCard.root.theme.bgBase
            border.color: posCard.root.theme.bgBorder
            border.width: 1

            readonly property var posList: ["left", "center", "right", "top", "bottom"]
            readonly property int activePosIndex: {
                const idx = posList.indexOf(posCard.root.osdPos);
                return idx !== -1 ? idx : 2;
            }
            readonly property real cellWidth: (width - 6 - (4 * 4)) / 5

            Rectangle {
                y: 3
                height: parent.height - 6
                width: posSegmentTrack.cellWidth
                x: 3 + posSegmentTrack.activePosIndex * (posSegmentTrack.cellWidth + 4)
                radius: 5
                color: posCard.root.theme.bgSelected
                border.color: posCard.root.theme.accentPrimary
                border.width: 1

                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 4

                Repeater {
                    model: OSDService.positionOptions

                    delegate: Rectangle {
                        id: posSegBtn
                        required property var modelData
                        readonly property bool isSel: posCard.root.osdPos === modelData.id

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: !isSel && posSegHover.hovered ? posCard.root.theme.bgHover : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: posSegHover }

                        Text {
                            anchors.centerIn: parent
                            text: posSegBtn.modelData.label
                            font.family: posCard.root.font
                            font.pixelSize: 11
                            font.bold: posSegBtn.isSel
                            color: posSegBtn.isSel ? posCard.root.theme.accentPrimary : posCard.root.theme.textPrimary
                            opacity: posSegBtn.isSel || posSegHover.hovered ? 1.0 : 0.75
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                OSDService.setPosition(posSegBtn.modelData.id);
                                OSDService.testOSD();
                            }
                        }
                    }
                }
            }
        }
    }
}
