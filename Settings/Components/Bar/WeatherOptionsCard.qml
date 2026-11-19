import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: self
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: "Weather Options"
            font.family: Style.font
            font.pixelSize: Style.px(13)
            font.bold: Style.boldHeadings
            font.letterSpacing: Style.letterSpacing
            font.hintingPreference: Style.fontHintingEnum
            antialiasing: Style.fontAntialiasing
            renderType: Style.fontRenderTypeEnum
            color: Style.theme.textSecondary
            Layout.minimumWidth: implicitWidth
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }
        Item { Layout.fillWidth: true }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: innerCol.implicitHeight + 8 * 2
        radius: 12
        color: Style.theme.bgSurface
        border.color: Style.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: innerCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0
            Item {
                Layout.fillWidth: true
                height: 40

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
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 8
                        Layout.preferredWidth: 380
                        Layout.minimumWidth: 380
                        Layout.maximumWidth: 380
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        Rectangle {
                            Layout.fillWidth: true
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
                height: 40

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
                    }

                    Item { Layout.fillWidth: true }

                    AppDropdown {
                        theme: root.theme
                        font: root.font
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        menuWidth: 380
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        options: [
                            { desktop: "m", name: "Metric (°C)",   desc: "" },
                            { desktop: "u", name: "Imperial (°F)", desc: "" }
                        ]
                        currentValue: BarConfig.weatherUnit || "m"
                        onSelected: (val, opt) => {
                            BarConfig.weatherUnit = val;
                            BarConfig.saveConfig();
                            SystemInfo.refreshWeather();
                            root.showToast("Weather unit set to: " + (opt ? opt.name : val));
                        }
                    }
                }
            }

            RowDivider {}

            Item {
                Layout.fillWidth: true
                height: 40

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
                    }

                    Item { Layout.fillWidth: true }

                    AppDropdown {
                        theme: root.theme
                        font: root.font
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        menuWidth: 380
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        options: [
                            { desktop: "compact", name: "Compact (1-Day)",  desc: "" },
                            { desktop: "full",    name: "Detailed (3-Day)", desc: "" }
                        ]
                        currentValue: BarConfig.weatherMode || "compact"
                        onSelected: (val, opt) => {
                            BarConfig.weatherMode = val;
                            BarConfig.saveConfig();
                            root.showToast("Forecast format set to: " + (opt ? opt.name : val));
                        }
                    }
                }
            }

            RowDivider {}

            Item {
                Layout.fillWidth: true
                height: 40

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
                    }

                    Item { Layout.fillWidth: true }

                    AppDropdown {
                        theme: root.theme
                        font: root.font
                        Layout.preferredWidth: 380
                        implicitWidth: 380
                        menuWidth: 380
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        options: [
                            { desktop: "15", name: "15 min", desc: "" },
                            { desktop: "30", name: "30 min", desc: "" },
                            { desktop: "60", name: "1 hour", desc: "" }
                        ]
                        currentValue: String(Number(BarConfig.weatherIntervalMinutes || 15))
                        onSelected: (val, opt) => {
                            BarConfig.weatherIntervalMinutes = Number(val);
                            BarConfig.saveConfig();
                            root.showToast("Weather poll interval set to: " + (opt ? opt.name : val));
                        }
                    }
                }
            }
        }
    }
}
