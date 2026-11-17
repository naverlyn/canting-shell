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

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Compositor & Display Power"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: compGroupCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: compGroupCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Variable Refresh Rate (VRR / Adaptive Sync) */
            Item {
                Layout.fillWidth: true
                height: 54

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true

                        Text {
                            text: "Variable Refresh Rate (VRR)"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Synchronize display refresh rate with GPU frame output (Adaptive Sync)"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    AppDropdown {
                        theme: root.theme
                        font: root.font
                        width: 220
                        implicitWidth: 220
                        menuWidth: 220
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        options: [
                            { desktop: "0", name: "Off",        desc: "" },
                            { desktop: "1", name: "Always",     desc: "" },
                            { desktop: "2", name: "Fullscreen", desc: "" }
                        ]
                        currentValue: String(root.vrrMode)
                        onSelected: (val) => root.setVrrMode(Number(val))
                    }
                }
            }

            /* Row Divider */
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                height: 1
                color: Qt.rgba(1, 1, 1, 0.05)
            }

            /* Row 2: Allow Screen Tearing */
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
                        Layout.fillWidth: true

                        Text {
                            text: "Allow Tearing"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Reduce input latency in fullscreen games that request immediate page flips"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        width: 44
                        height: 24
                        radius: 12
                        color: root.allowTearing ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 160 } }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.allowTearing ? parent.width - width - 3 : 3
                            color: root.allowTearing ? "#ffffff" : root.theme.textPrimary

                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setAllowTearing(!root.allowTearing)
                        }
                    }
                }
            }
        }
    }
}
