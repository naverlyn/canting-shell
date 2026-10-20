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
    title: "Hardware Monitor Options (CPU / RAM / Temp / Disk)"
    contentMargins: 8
    contentSpacing: 0

    SettingToggleRow {
        title: "Show Sensor Glyphs"
        desc: "Display icons (CPU, RAM, Temp, Disk) before numerical utilization figures"
        checked: BarConfig.hwShowIcons !== false
        onToggled: (val) => {
            BarConfig.hwShowIcons = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Sensor glyphs visible" : "Sensor glyphs hidden");
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "High Load Warning Alerts"
        desc: "Highlight hardware pills in red when processor, memory, or thermal levels reach critical levels"
        checked: BarConfig.hwAlertEnabled !== false
        onToggled: (val) => {
            BarConfig.hwAlertEnabled = val;
            BarConfig.saveConfig();
            root.showToast(val ? "High load alerts enabled" : "High load alerts disabled");
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
                    text: "Critical Alert Threshold"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Percentage (%) or temperature (°C) that triggers warning highlights"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: hwThreshSegmentTrack
                implicitWidth: 260
                implicitHeight: 32
                width: 260
                height: 32
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property int activeVal: Number(BarConfig.hwAlertThreshold !== undefined ? BarConfig.hwAlertThreshold : 85)
                readonly property int activeIdx: activeVal === 75 ? 0 : (activeVal === 80 ? 1 : (activeVal === 90 ? 3 : 2))
                readonly property real cellWidth: (width - 6 - 12) / 4

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: hwThreshSegmentTrack.cellWidth
                    x: 3 + hwThreshSegmentTrack.activeIdx * (hwThreshSegmentTrack.cellWidth + 4)
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
                            { label: "75%", value: 75 },
                            { label: "80%", value: 80 },
                            { label: "85%", value: 85 },
                            { label: "90%", value: 90 }
                        ]
                        delegate: Rectangle {
                            id: hwThreshBtn
                            required property var modelData
                            readonly property bool isSel: hwThreshSegmentTrack.activeVal === modelData.value

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            scale: hwThreshMouse.pressed ? 0.95 : 1.0
                            color: !isSel && hwThreshHov.hovered ? root.theme.bgHover : "transparent"
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            Behavior on color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: hwThreshHov }

                            Text {
                                anchors.centerIn: parent
                                text: hwThreshBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: hwThreshBtn.isSel
                                color: hwThreshBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: hwThreshBtn.isSel || hwThreshHov.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: hwThreshMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.hwAlertThreshold = hwThreshBtn.modelData.value;
                                    BarConfig.saveConfig();
                                    root.showToast("Hardware alert threshold set to: " + hwThreshBtn.modelData.label);
                                }
                            }
                        }
                    }
                }
            }
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
                    text: "Hardware Polling Frequency"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Update interval for CPU, memory, network, and thermal sensors"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: pollRateSegmentTrack
                implicitWidth: 260
                implicitHeight: 32
                width: 260
                height: 32
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property int activeVal: Number(BarConfig.hwPollInterval || 2)
                readonly property int activeIdx: activeVal === 1 ? 0 : (activeVal === 5 ? 2 : 1)
                readonly property real cellWidth: (width - 6 - 8) / 3

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: pollRateSegmentTrack.cellWidth
                    x: 3 + pollRateSegmentTrack.activeIdx * (pollRateSegmentTrack.cellWidth + 4)
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
                            { label: "1s (Fast)", value: 1 },
                            { label: "2s (Norm)", value: 2 },
                            { label: "5s (Eco)", value: 5 }
                        ]
                        delegate: Rectangle {
                            id: pollRateBtn
                            required property var modelData
                            readonly property bool isSel: pollRateSegmentTrack.activeVal === modelData.value

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            scale: pollRateMouse.pressed ? 0.95 : 1.0
                            color: !isSel && pollRateHov.hovered ? root.theme.bgHover : "transparent"
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            Behavior on color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: pollRateHov }

                            Text {
                                anchors.centerIn: parent
                                text: pollRateBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: pollRateBtn.isSel
                                color: pollRateBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: pollRateBtn.isSel || pollRateHov.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: pollRateMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.hwPollInterval = pollRateBtn.modelData.value;
                                    BarConfig.saveConfig();
                                    root.showToast("Hardware polling interval set to: " + pollRateBtn.modelData.label);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
