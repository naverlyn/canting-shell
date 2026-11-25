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
        font.pixelSize: Style.px(13)
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: generalCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder
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
                height: 44

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Test Overlay"
                            font.family: root.font
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: testBtn
                        width: root.actionBtnWidth
                        height: root.btnHeight
                        radius: root.btnRadius
                        color: testHover.hovered ? root.theme.bgHover : root.theme.bgBase
                        border.color: testHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: testHover }

                        Text {
                            anchors.centerIn: parent
                            text: "Test OSD"
                            font.family: root.font
                            font.pixelSize: Style.px(12)
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

            RowDivider {}

            /* Row 2: Reset Defaults */
            Item {
                Layout.fillWidth: true
                height: 44

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Reset to Defaults"
                            font.family: root.font
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        id: resetBtn
                        width: root.actionBtnWidth
                        height: root.btnHeight
                        radius: root.btnRadius
                        opacity: root.isCustomized ? 1.0 : 0.4
                        color: resetHover.hovered && root.isCustomized ? root.theme.bgHover : root.theme.bgBase
                        border.color: resetHover.hovered && root.isCustomized ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: resetHover }

                        Text {
                            anchors.centerIn: parent
                            text: "Reset"
                            font.family: root.font
                            font.pixelSize: Style.px(12)
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
