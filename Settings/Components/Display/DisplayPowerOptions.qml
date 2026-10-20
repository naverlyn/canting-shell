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

                    /* Segmented VRR Mode Control */
                    Rectangle {
                        width: 260
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
                                    { val: 0, label: "Off" },
                                    { val: 1, label: "Always" },
                                    { val: 2, label: "Fullscreen" }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool isSelected: root.vrrMode === modelData.val

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: isSelected
                                        ? root.theme.accentPrimary
                                        : (vrrHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                                    border.color: isSelected ? root.theme.accentPrimary : "transparent"
                                    border.width: isSelected ? 1 : 0

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    HoverHandler { id: vrrHover }

                                    Text {
                                        id: vrrLabel
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: isSelected
                                        color: isSelected
                                            ? (root.theme.bgBase ?? "#1a1b26")
                                            : (vrrHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setVrrMode(modelData.val)
                                    }
                                }
                            }
                        }
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
