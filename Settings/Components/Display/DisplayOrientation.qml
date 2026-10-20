import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../MonitorManager"
import "../../../MonitorManager/Components"
import "../.."
import "../Common"
import ".."

Item {
    required property var root
    Layout.fillWidth: true
    implicitHeight: 52
    opacity: (root.selectedMonitor && root.selectedMonitor.disabled) ? 0.45 : 1.0
    enabled: !(root.selectedMonitor && root.selectedMonitor.disabled)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Orientation"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "Rotate display output clockwise"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
            }
        }

        Item { Layout.fillWidth: true }

        /* Segmented Orientation Control */
        Rectangle {
            width: 360
            height: 32
            radius: 7
            color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: [
                        { t: 0, label: "0°" },
                        { t: 1, label: "90°" },
                        { t: 2, label: "180°" },
                        { t: 3, label: "270°" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isSelected: root.selectedMonitor
                            && root.selectedMonitor.transform === modelData.t

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: isSelected
                            ? root.theme.accentPrimary
                            : (rotPillHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                        border.color: isSelected ? root.theme.accentPrimary : "transparent"
                        border.width: isSelected ? 1 : 0

                        Behavior on color { ColorAnimation { duration: 120 } }

                        HoverHandler { id: rotPillHover }

                        Text {
                            id: rotText
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: isSelected
                            color: isSelected
                                ? (root.theme.bgBase ?? "#1a1b26")
                                : (rotPillHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectTransform(modelData.t)
                        }
                    }
                }
            }
        }
    }
}
