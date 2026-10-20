import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

Item {
    required property var root
    id: rowSelf
    visible: root.hasMultipleMonitors
    Layout.fillWidth: true
    height: 52

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Display Assignment"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "Show on all connected monitors, or only primary / secondary display"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
            }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            id: dispSegmentTrack
            Layout.preferredWidth: 320
            Layout.preferredHeight: 32
            radius: 7
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1
            clip: true

            readonly property string activeTarget: root.generalTab.curDisplayTarget
            readonly property real cellWidth: (width - 6 - 8) / 3

            Rectangle {
                id: dispSegmentThumb
                readonly property var targetIdxMap: ({ "all": 0, "primary": 1, "secondary": 2 })
                readonly property int activeIdx: targetIdxMap[dispSegmentTrack.activeTarget] !== undefined ? targetIdxMap[dispSegmentTrack.activeTarget] : 0

                x: 3 + activeIdx * (dispSegmentTrack.cellWidth + 4)
                y: 3
                width: dispSegmentTrack.cellWidth
                height: dispSegmentTrack.height - 6
                radius: 5
                color: root.theme.bgSelected
                border.color: root.theme.accentPrimary
                border.width: 1

                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 4

                Repeater {
                    model: [
                        { label: "All Displays", value: "all" },
                        { label: "Primary",      value: "primary" },
                        { label: "Secondary",    value: "secondary", disabled: !root.hasMultipleMonitors }
                    ]

                    delegate: Rectangle {
                        id: dispSegBtn
                        required property var modelData
                        readonly property bool isSel: dispSegmentTrack.activeTarget === modelData.value
                        readonly property bool isDisabled: Boolean(modelData.disabled)

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        scale: dispSegMouse.pressed && !isDisabled ? 0.95 : 1.0
                        color: !isSel && dispSegHover.hovered && !isDisabled ? root.theme.bgHover : "transparent"
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: dispSegHover }

                        Text {
                            anchors.centerIn: parent
                            text: dispSegBtn.modelData.label
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: dispSegBtn.isSel
                            color: dispSegBtn.isDisabled
                                ? root.theme.textMuted
                                : (dispSegBtn.isSel ? root.theme.accentPrimary : root.theme.textSecondary)
                            opacity: dispSegBtn.isDisabled ? 0.45 : (dispSegBtn.isSel || dispSegHover.hovered ? 1.0 : 0.75)
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: dispSegMouse
                            anchors.fill: parent
                            cursorShape: dispSegBtn.isDisabled ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (dispSegBtn.isDisabled) {
                                    root.showToast("Secondary display is not available on a single monitor setup.", true);
                                    return;
                                }
                                BarConfig.updateBarProp("displayTarget", dispSegBtn.modelData.value);
                            }
                        }
                    }
                }
            }
        }
    }
}
