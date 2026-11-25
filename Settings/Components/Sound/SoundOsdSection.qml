import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../../osd"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8

        Text {
            text: "On-Screen Display (OSD)"
            font.family: root.font
            font.pixelSize: Style.px(13)
            font.bold: true
            color: root.theme.textSecondary
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "Active: " + OSDService.getPositionLabel(OSDService.position)
            font.family: root.font
            font.pixelSize: Style.px(11)
            font.bold: true
            color: root.theme.accentPrimary
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: osdGroupCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: osdGroupCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Position Selection */
            Item {
                Layout.fillWidth: true
                height: 44

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        spacing: 2
                        Layout.preferredWidth: root.labelColWidth
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Screen Position"
                            font.family: root.font
                            font.pixelSize: Style.px(13)
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
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        options: (OSDService.positionOptions || []).map(p => ({
                            desktop: p.id,
                            name: p.label,
                            desc: ""
                        }))
                        currentValue: OSDService.position
                        onSelected: (val) => {
                            OSDService.setPosition(val);
                            OSDService.testOSD();
                        }
                    }
                }
            }

            RowDivider {}

            /* Row 2: Test OSD */
            Item {
                Layout.fillWidth: true
                height: 44

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    ColumnLayout {
                        spacing: 2
                        Layout.preferredWidth: root.labelColWidth
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
                        implicitWidth: root.actionBtnWidth
                        implicitHeight: root.btnHeight
                        Layout.preferredWidth: root.actionBtnWidth
                        Layout.preferredHeight: root.btnHeight
                        width: root.actionBtnWidth
                        height: root.btnHeight
                        radius: root.btnRadius
                        color: testOsdHoverSound.hovered ? root.theme.bgHover : root.theme.bgBase
                        border.color: testOsdHoverSound.hovered ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: testOsdHoverSound }

                        Text {
                            anchors.centerIn: parent
                            text: "Test"
                            font.family: root.font
                            font.pixelSize: Style.px(12)
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true
                            onClicked: OSDService.testOSD()
                        }
                    }
                }
            }
        }
    }
}
