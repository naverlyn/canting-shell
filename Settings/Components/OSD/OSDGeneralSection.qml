import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../osd"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "General"
        font.family: root.font
        font.pixelSize: 13
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: generalCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: generalCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Test OSD */
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
                            text: "Test Overlay"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Trigger on-screen display overlay to verify placement, shape, and appearance"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        id: testBtn
                        width: root.actionBtnWidth
                        height: root.btnHeight
                        radius: root.btnRadius
                        color: testHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : (root.theme.bgBase ?? Qt.rgba(0,0,0,0.2))
                        border.color: testHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: testHover }

                        Text {
                            anchors.centerIn: parent
                            text: "Test OSD"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: OSDService.testOSD()
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

            /* Row 2: Reset Defaults */
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
                            text: "Reset to Defaults"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Text {
                            text: "Restore right edge placement, adaptive orientation, default margins, and 1.5s timeout"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        id: resetBtn
                        width: root.actionBtnWidth
                        height: root.btnHeight
                        radius: root.btnRadius
                        opacity: root.isCustomized ? 1.0 : 0.4
                        color: resetHover.hovered && root.isCustomized ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.12)) : (root.theme.bgBase ?? Qt.rgba(0,0,0,0.2))
                        border.color: resetHover.hovered && root.isCustomized ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1))
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: resetHover }

                        Text {
                            anchors.centerIn: parent
                            text: "Reset"
                            font.family: root.font
                            font.pixelSize: 12
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: root.isCustomized ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (root.isCustomized) {
                                    OSDService.setPosition("right");
                                    OSDService.setOrientation("auto");
                                    OSDService.setMarginX(16);
                                    OSDService.setMarginY(0);
                                    OSDService.setTimeoutMs(1500);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
