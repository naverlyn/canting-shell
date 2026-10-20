import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

Rectangle {
    required property var root
    Layout.fillWidth: true
    radius: 12
    color: root.theme.bgSurface
    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
    border.width: 1
    implicitHeight: summaryCol.implicitHeight + 28

    ColumnLayout {
        id: summaryCol
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Active Bezier Curves & Compositor Rules"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }
        }

        // Bezier Chips Flow
        Text {
            text: "Configured Bezier Curves (" + root.activeBeziers.length + ")"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.textSecondary
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.activeBeziers

                Rectangle {
                    id: chipRect
                    required property var modelData
                    height: 26
                    width: chipRow.implicitWidth + 20
                    radius: 6
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: chipRect.modelData.name
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentPrimary
                        }

                        Text {
                            text: "(" + chipRect.modelData.curve + ")"
                            font.family: root.font
                            font.pixelSize: 10
                            color: root.theme.textMuted
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.05)
        }

        // Active Animation Rules
        Text {
            text: "Active Animation Rules (" + root.activeRules.length + ")"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.textSecondary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: root.activeRules

                Rectangle {
                    id: ruleRect
                    required property var modelData
                    Layout.fillWidth: true
                    height: 30
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.02)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text {
                            text: ruleRect.modelData.target
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textPrimary
                            Layout.preferredWidth: 140
                        }

                        Text {
                            text: "Speed: " + ruleRect.modelData.speed + " • Curve: " + ruleRect.modelData.curve + (ruleRect.modelData.style ? (" • " + ruleRect.modelData.style) : "")
                            font.family: root.font
                            font.pixelSize: 10
                            color: root.theme.textSecondary
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: ruleRect.modelData.enabled ? "#9ece6a" : "#f7768e"
                        }
                    }
                }
            }
        }
    }
}
