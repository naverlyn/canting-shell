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
    title: "Battery Pill Options"
    contentMargins: 8
    contentSpacing: 0

    SettingToggleRow {
        title: "Show Battery Percentage"
        desc: "Display numerical charge percentage text alongside the battery status icon"
        checked: BarConfig.batteryShowPercentage !== false
        onToggled: (val) => {
            BarConfig.batteryShowPercentage = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Battery percentage visible" : "Battery percentage hidden");
        }
    }

    RowDivider {}

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
                    text: "Low Battery Alert Level"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Percentage at which battery icon turns red to warn about low charge"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: batThreshSegmentTrack
                implicitWidth: 260
                implicitHeight: 32
                width: 260
                height: 32
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property int activeVal: Number(BarConfig.batteryLowThreshold !== undefined ? BarConfig.batteryLowThreshold : 20)
                readonly property int activeIdx: activeVal === 15 ? 0 : (activeVal === 25 ? 2 : (activeVal === 30 ? 3 : 1))
                readonly property real cellWidth: (width - 6 - 12) / 4

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: batThreshSegmentTrack.cellWidth
                    x: 3 + batThreshSegmentTrack.activeIdx * (batThreshSegmentTrack.cellWidth + 4)
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
                            { label: "15%", value: 15 },
                            { label: "20%", value: 20 },
                            { label: "25%", value: 25 },
                            { label: "30%", value: 30 }
                        ]
                        delegate: Rectangle {
                            id: batThreshBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: batThreshSegmentTrack.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && batThreshHov.hovered ? root.theme.bgHover : "transparent"
                            scale: batThreshMouse.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            HoverHandler { id: batThreshHov }

                            Text {
                                anchors.centerIn: parent
                                text: batThreshBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: batThreshBtn.isSel
                                color: batThreshBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: batThreshBtn.isSel || batThreshHov.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: batThreshMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.batteryLowThreshold = batThreshBtn.modelData.value;
                                    BarConfig.saveConfig();
                                    root.showToast("Battery warning threshold set to: " + batThreshBtn.modelData.label);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
