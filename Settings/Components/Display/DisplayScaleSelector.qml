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
        id: scaleRowLayout
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Scale"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "UI and text scaling factor (" + Math.round((root.selectedMonitor ? root.selectedMonitor.scale : 1.0) * 100) + "%)"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
            }
        }

        Item { Layout.fillWidth: true }

        /* Segmented Scale Control */
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
                        { val: 0.75, label: "75%" },
                        { val: 1.0,  label: "100%" },
                        { val: 1.25, label: "125%" },
                        { val: 1.5,  label: "150%" },
                        { val: 1.75, label: "175%" },
                        { val: 2.0,  label: "200%" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isSelected: root.selectedMonitor
                            && Math.abs(root.selectedMonitor.scale - modelData.val) < 0.02

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: isSelected
                            ? root.theme.accentPrimary
                            : (scalePillHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                        border.color: isSelected ? root.theme.accentPrimary : "transparent"
                        border.width: isSelected ? 1 : 0

                        Behavior on color { ColorAnimation { duration: 120 } }

                        HoverHandler { id: scalePillHover }

                        Text {
                            id: scaleText
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: isSelected
                            color: isSelected
                                ? (root.theme.bgBase ?? "#1a1b26")
                                : (scalePillHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectScale(modelData.val)
                        }
                    }
                }
            }
        }
    }
}
