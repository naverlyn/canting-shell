import QtQuick
import QtQuick.Layouts
import "../../bar"
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Lato Nerd Font"

    width: parent ? parent.width : 300
    height: statsCol.implicitHeight + 24
    implicitHeight: statsCol.implicitHeight + 24
    implicitWidth: 300
    radius: 10
    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
    border.color: root.theme.bgBorder
    border.width: 1

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    function parsePercent(str) {
        if (!str) return 0;
        const val = parseInt(str.toString().replace("%", "").trim());
        return isNaN(val) ? 0 : Math.max(0, Math.min(100, val));
    }

    ColumnLayout {
        id: statsCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 12
        }
        spacing: 10

        Text {
            text: "System Resources"
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
            color: root.theme.textPrimary
            Layout.fillWidth: true
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            // 1. CPU Stat Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: 8
                color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
                border.color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰻠 CPU"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: SystemInfo.cpuUsage
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentPrimary
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.1)

                        Rectangle {
                            height: parent.height
                            radius: 2
                            width: Math.max(2, Math.min(parent.width, parent.width * (root.parsePercent(SystemInfo.cpuUsage) / 100)))
                            color: root.theme.accentPrimary
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // 2. Memory (RAM) Stat Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: 8
                color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
                border.color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰍛 RAM"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: SystemInfo.memoryUsage
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentPrimary
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.1)

                        Rectangle {
                            height: parent.height
                            radius: 2
                            width: Math.max(2, Math.min(parent.width, parent.width * (root.parsePercent(SystemInfo.memoryUsage) / 100)))
                            color: root.theme.accentPrimary
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // 3. Disk Usage Stat Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: 8
                color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
                border.color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰋊 Disk"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: SystemInfo.diskUsage
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentPrimary
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.1)

                        Rectangle {
                            height: parent.height
                            radius: 2
                            width: Math.max(2, Math.min(parent.width, parent.width * (root.parsePercent(SystemInfo.diskUsage) / 100)))
                            color: root.theme.accentPrimary
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // 4. Thermal Stat Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: 8
                color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
                border.color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰔏 Temp"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: SystemInfo.temperature
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentPrimary
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.1)

                        Rectangle {
                            height: parent.height
                            radius: 2
                            width: Math.max(2, Math.min(parent.width, parent.width * (Math.min(100, Math.max(0, parseInt(SystemInfo.temperature) || 40)) / 100)))
                            color: root.theme.accentPrimary
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }
}

