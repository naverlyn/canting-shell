import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../../osd"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8

        Text {
            text: "On-Screen Display (OSD)"
            font.family: root.font
            font.pixelSize: 13
            font.bold: true
            color: root.theme.textSecondary
        }

        Text {
            text: "· Volume overlay position and placement"
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textMuted
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: "Active: " + OSDService.getPositionLabel(OSDService.position)
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.accentPrimary
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: osdGroupCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: osdGroupCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Position Selection */
            Item {
                Layout.fillWidth: true
                height: 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        spacing: 2
                        Layout.preferredWidth: root.labelColWidth
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Screen Position"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Overlay screen placement"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    /* Position Segmented Pill Track */
                    Rectangle {
                        id: osdPosSegmentTrack
                        implicitWidth: 400
                        width: 400
                        height: root.btnHeight
                        radius: 7
                        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        readonly property var posList: ["left", "center", "right", "top", "bottom"]
                        readonly property int activePosIndex: {
                            const idx = posList.indexOf(OSDService.position);
                            return idx !== -1 ? idx : 4;
                        }
                        readonly property real cellWidth: (width - 6 - ((OSDService.positionOptions.length - 1) * 4)) / OSDService.positionOptions.length

                        // Animated sliding indicator
                        Rectangle {
                            y: 3
                            height: parent.height - 6
                            width: osdPosSegmentTrack.cellWidth
                            x: 3 + osdPosSegmentTrack.activePosIndex * (osdPosSegmentTrack.cellWidth + 4)
                            radius: 5
                            color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)
                            border.color: root.theme.accentPrimary
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
                                    readonly property bool isSel: OSDService.position === modelData.id

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isSel && posSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: posSegHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: posSegBtn.modelData.label
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: posSegBtn.isSel
                                        color: posSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                        opacity: posSegBtn.isSel || posSegHover.hovered ? 1.0 : 0.75
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        preventStealing: true
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

            /* Row Divider */
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
            }

            /* Row 2: Test OSD */
            Item {
                Layout.fillWidth: true
                height: 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        spacing: 2
                        Layout.preferredWidth: root.labelColWidth
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Test Overlay"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Display active volume OSD"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: root.actionBtnWidth
                        implicitHeight: root.btnHeight
                        Layout.preferredWidth: root.actionBtnWidth
                        Layout.preferredHeight: root.btnHeight
                        width: root.actionBtnWidth
                        height: root.btnHeight
                        radius: root.btnRadius
                        color: testOsdHoverSound.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2))
                        border.color: testOsdHoverSound.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: testOsdHoverSound }

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
                            preventStealing: true
                            onClicked: OSDService.testOSD()
                        }
                    }
                }
            }
        }
    }
}
