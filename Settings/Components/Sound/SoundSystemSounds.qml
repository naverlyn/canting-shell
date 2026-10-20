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

    Text {
        text: "System Sounds"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: sysSoundsCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: sysSoundsCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Alert Sound Selector */
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
                            text: "Alert Sound"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Theme event sound"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    /* Sound Options Segmented Pill Track */
                    Rectangle {
                        id: soundSegmentTrack
                        implicitWidth: 440
                        width: 440
                        height: root.btnHeight
                        radius: 7
                        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        readonly property var soundOptions: [
                            { id: "bell", label: "Bell" },
                            { id: "dialog-information", label: "Information" },
                            { id: "window-attention", label: "Attention" },
                            { id: "message", label: "Message" },
                            { id: "complete", label: "Complete" }
                        ]
                        readonly property int activeIdx: {
                            for (let i = 0; i < soundOptions.length; i++) {
                                if (soundOptions[i].id === root.selectedAlertSound) return i;
                            }
                            return 0;
                        }
                        readonly property real cellWidth: (width - 6 - ((soundOptions.length - 1) * 4)) / soundOptions.length

                        // Animated sliding indicator
                        Rectangle {
                            y: 3
                            height: parent.height - 6
                            width: soundSegmentTrack.cellWidth
                            x: 3 + soundSegmentTrack.activeIdx * (soundSegmentTrack.cellWidth + 4)
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
                                model: soundSegmentTrack.soundOptions

                                delegate: Rectangle {
                                    id: soundSegBtn
                                    required property var modelData
                                    readonly property bool isSel: root.selectedAlertSound === modelData.id

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: !isSel && soundSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: soundSegHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: soundSegBtn.modelData.label
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: soundSegBtn.isSel
                                        color: soundSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                        opacity: soundSegBtn.isSel || soundSegHover.hovered ? 1.0 : 0.75
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        preventStealing: true
                                        onClicked: {
                                            root.selectedAlertSound = soundSegBtn.modelData.id;
                                            root.playSound(soundSegBtn.modelData.id);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    /* Standardized Play Alert Button */
                    Rectangle {
                        implicitWidth: root.actionBtnWidth
                        implicitHeight: root.btnHeight
                        Layout.preferredWidth: root.actionBtnWidth
                        Layout.preferredHeight: root.btnHeight
                        width: root.actionBtnWidth
                        height: root.btnHeight
                        radius: root.btnRadius
                        color: playAlertHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2))
                        border.color: playAlertHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: playAlertHover }

                        Text {
                            anchors.centerIn: parent
                            text: "Play"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            onClicked: root.playSound(root.selectedAlertSound)
                        }
                    }
                }
            }
        }
    }
}
