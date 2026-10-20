import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
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
            text: "Orientation & Shape"
            font.family: root.font
            font.pixelSize: 13
            font.bold: true
            color: root.theme.textSecondary
        }

        Text {
            text: "· Adaptive: vertical on edges, horizontal in center"
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textMuted
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: OSDService.isHorizontal ? "Current: Horizontal" : "Current: Vertical"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.accentPrimary
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: orientCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: orientCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 8

            /* Orientation Segmented Pill Track */
            Rectangle {
                id: orientSegmentTrack
                Layout.fillWidth: true
                height: 34
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property var orientList: ["auto", "horizontal", "vertical"]
                readonly property int activeOrientIndex: {
                    const idx = orientList.indexOf(OSDService.orientation);
                    return idx !== -1 ? idx : 0;
                }
                readonly property real cellWidth: (width - 6 - (2 * 4)) / 3

                // Animated sliding indicator
                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: orientSegmentTrack.cellWidth
                    x: 3 + orientSegmentTrack.activeOrientIndex * (orientSegmentTrack.cellWidth + 4)
                    radius: 5
                    color: root.theme.bgSelected
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
                        model: OSDService.orientationOptions

                        delegate: Rectangle {
                            id: orientSegBtn
                            required property var modelData
                            readonly property bool isSel: OSDService.orientation === modelData.id

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && orientSegHover.hovered ? root.theme.bgHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: orientSegHover }

                            Text {
                                anchors.centerIn: parent
                                text: orientSegBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: orientSegBtn.isSel
                                color: orientSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: orientSegBtn.isSel || orientSegHover.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    OSDService.setOrientation(orientSegBtn.modelData.id);
                                    OSDService.testOSD();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
