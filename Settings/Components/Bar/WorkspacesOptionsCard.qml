import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: self
    title: "Workspaces Options"
    contentMargins: 8
    contentSpacing: 0

    Item {
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
                    text: "Workspace Numbering Style"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Display numeric digits, Roman numerals, or minimal dots"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: wsStyleSegmentTrack
                implicitWidth: 260
                implicitHeight: 32
                width: 260
                height: 32
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property string activeVal: BarConfig.workspaceStyle || "index"
                readonly property int activeIdx: activeVal === "roman" ? 1 : (activeVal === "dot" ? 2 : 0)
                readonly property real cellWidth: (width - 6 - 8) / 3

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: wsStyleSegmentTrack.cellWidth
                    x: 3 + wsStyleSegmentTrack.activeIdx * (wsStyleSegmentTrack.cellWidth + 4)
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
                            { label: "1, 2, 3", value: "index" },
                            { label: "I, II, III", value: "roman" },
                            { label: "• • •", value: "dot" }
                        ]
                        delegate: Rectangle {
                            id: wsStyleBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: wsStyleSegmentTrack.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && wsHov.hovered ? root.theme.bgHover : "transparent"
                            scale: wsMouse.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            HoverHandler { id: wsHov }

                            Text {
                                anchors.centerIn: parent
                                text: wsStyleBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: wsStyleBtn.isSel
                                color: wsStyleBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: wsStyleBtn.isSel || wsHov.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.workspaceStyle = wsStyleBtn.modelData.value;
                                    BarConfig.saveConfig();
                                    root.showToast("Workspace style set to: " + wsStyleBtn.modelData.label);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Mouse Wheel Workspace Switching"
        desc: "Scroll over workspace pills to navigate between active workspaces"
        checked: BarConfig.workspaceScrollSwitch !== false
        onToggled: (val) => {
            BarConfig.workspaceScrollSwitch = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Mouse wheel workspace switching enabled" : "Mouse wheel workspace switching disabled");
        }
    }
}
