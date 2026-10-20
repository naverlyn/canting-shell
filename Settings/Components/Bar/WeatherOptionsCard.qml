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
    title: "Weather Options"
    contentMargins: 8
    contentSpacing: 0

    Item {
        Layout.fillWidth: true
        height: 60

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Weather Location (City / Region)"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Specify city name (e.g. Bekasi, Jakarta, Tokyo) or leave blank for auto-IP"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                Rectangle {
                    width: 220
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: weatherLocationInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1

                    TextInput {
                        id: weatherLocationInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textPrimary
                        selectByMouse: true
                        text: BarConfig.weatherLocation

                        function applyChange() {
                            const trimmed = text.trim();
                            BarConfig.weatherLocation = trimmed;
                            BarConfig.saveConfig();
                            SystemInfo.refreshWeather();
                            root.showToast("Weather location set to: " + (trimmed || "Auto-detect"));
                        }

                        onAccepted: applyChange()

                        Text {
                            visible: parent.text === "" && !parent.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Auto-detect (by IP)..."
                            font.family: root.font
                            font.pixelSize: 10
                            color: root.theme.textMuted
                        }
                    }
                }

                ActionButton {
                    label: "Apply"
                    btnHeight: 32
                    onClicked: weatherLocationInput.applyChange()
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
                    text: "Temperature Unit"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Choose metric (°C) or imperial (°F) units for readouts and popup"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: wUnitSegmentTrack
                implicitWidth: 220
                implicitHeight: 32
                width: 220
                height: 32
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property string activeVal: BarConfig.weatherUnit || "m"
                readonly property int activeIdx: activeVal === "u" ? 1 : 0
                readonly property real cellWidth: (width - 6 - 4) / 2

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: wUnitSegmentTrack.cellWidth
                    x: 3 + wUnitSegmentTrack.activeIdx * (wUnitSegmentTrack.cellWidth + 4)
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
                            { label: "Metric (°C)", value: "m" },
                            { label: "Imperial (°F)", value: "u" }
                        ]
                        delegate: Rectangle {
                            id: wUnitBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: wUnitSegmentTrack.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && wUnitHov.hovered ? root.theme.bgHover : "transparent"
                            scale: wUnitMouse.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            HoverHandler { id: wUnitHov }

                            Text {
                                anchors.centerIn: parent
                                text: wUnitBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: wUnitBtn.isSel
                                color: wUnitBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: wUnitBtn.isSel || wUnitHov.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: wUnitMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.weatherUnit = wUnitBtn.modelData.value;
                                    BarConfig.saveConfig();
                                    SystemInfo.refreshWeather();
                                    root.showToast("Weather unit set to: " + wUnitBtn.modelData.label);
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
                    text: "Popup Forecast Detail"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Choose between concise today-only summary or full 3-day multi-period forecast"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: wModeSegmentTrack
                implicitWidth: 240
                implicitHeight: 32
                width: 240
                height: 32
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property string activeVal: BarConfig.weatherMode || "compact"
                readonly property int activeIdx: activeVal === "full" ? 1 : 0
                readonly property real cellWidth: (width - 6 - 4) / 2

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: wModeSegmentTrack.cellWidth
                    x: 3 + wModeSegmentTrack.activeIdx * (wModeSegmentTrack.cellWidth + 4)
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
                            { label: "Compact (1-Day)", value: "compact" },
                            { label: "Detailed (3-Day)", value: "full" }
                        ]
                        delegate: Rectangle {
                            id: wModeBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: wModeSegmentTrack.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && wModeHov.hovered ? root.theme.bgHover : "transparent"
                            scale: wModeMouse.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            HoverHandler { id: wModeHov }

                            Text {
                                anchors.centerIn: parent
                                text: wModeBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: wModeBtn.isSel
                                color: wModeBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: wModeBtn.isSel || wModeHov.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: wModeMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.weatherMode = wModeBtn.modelData.value;
                                    BarConfig.saveConfig();
                                    root.showToast("Forecast format set to: " + wModeBtn.modelData.label);
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
                    text: "Auto-Refresh Interval"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Background poll frequency for weather updates"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: wIntSegmentTrack
                implicitWidth: 240
                implicitHeight: 32
                width: 240
                height: 32
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property int activeVal: Number(BarConfig.weatherIntervalMinutes || 15)
                readonly property int activeIdx: activeVal === 30 ? 1 : (activeVal === 60 ? 2 : 0)
                readonly property real cellWidth: (width - 6 - 8) / 3

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: wIntSegmentTrack.cellWidth
                    x: 3 + wIntSegmentTrack.activeIdx * (wIntSegmentTrack.cellWidth + 4)
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
                            { label: "15 min", value: 15 },
                            { label: "30 min", value: 30 },
                            { label: "1 hour", value: 60 }
                        ]
                        delegate: Rectangle {
                            id: wIntBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: wIntSegmentTrack.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && wIntHov.hovered ? root.theme.bgHover : "transparent"
                            scale: wIntMouse.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            HoverHandler { id: wIntHov }

                            Text {
                                anchors.centerIn: parent
                                text: wIntBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: wIntBtn.isSel
                                color: wIntBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: wIntBtn.isSel || wIntHov.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                id: wIntMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.weatherIntervalMinutes = wIntBtn.modelData.value;
                                    BarConfig.saveConfig();
                                    root.showToast("Weather poll interval set to: " + wIntBtn.modelData.label);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
