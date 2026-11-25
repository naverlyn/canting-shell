import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../notifications"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: self
    property alias zone1Card: z1Panel
    property alias zone2Card: z2Panel
    property alias zone3Card: z3Panel
    property alias zone1Repeater: z1Panel.repeater
    property alias zone2Repeater: z2Panel.repeater
    property alias zone3Repeater: z3Panel.repeater
    property alias poolCard: availBlocksPool
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: "Card Layout"
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
        implicitHeight: innerCol.implicitHeight + 12 * 2
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
                margins: 12
            }
            spacing: 12
            // Top Quick Layout Presets & Mode Switches Bar
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 9
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "Layout Presets:"
                        font.family: root.font
                        font.pixelSize: Style.px(12)
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    RowLayout {
                        spacing: 6

                        Repeater {
                            model: [
                                { id: "standard", label: "Standard" },
                                { id: "avatar",   label: "Avatar Left" },
                                { id: "banner",   label: "Banner Media" },
                                { id: "compact",  label: "Compact" },
                                { id: "detailed", label: "Detailed" }
                            ]
                            delegate: Rectangle {
                                id: layPresetBtn
                                required property var modelData
                                implicitWidth: layPresetTxt.implicitWidth + 16
                                height: 28
                                radius: 6
                                color: layPresetHover.hovered ? root.theme.bgHover : root.theme.bgSurface
                                border.color: layPresetHover.hovered ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: 1
                                scale: layPresetMouse.pressed ? 0.95 : 1.0

                                Behavior on color { ColorAnimation { duration: 130 } }
                                Behavior on border.color { ColorAnimation { duration: 130 } }
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                HoverHandler { id: layPresetHover }

                                Text {
                                    id: layPresetTxt
                                    anchors.centerIn: parent
                                    text: layPresetBtn.modelData.label
                                    font.family: root.font
                                    font.pixelSize: Style.px(11)
                                    font.bold: true
                                    color: layPresetHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                                }

                                MouseArea {
                                    id: layPresetMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        NotificationService.applyLayoutPreset(layPresetBtn.modelData.id);
                                        root.showToast("Applied '" + layPresetBtn.modelData.label + "' notification block layout");
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }

            // 3-Column Modular Zones Grid (Header Bar, Main Content, Footer & Actions)
            GridLayout {
                columns: 3
                columnSpacing: 12
                rowSpacing: 12
                Layout.fillWidth: true

                NotificationZonePanel {
                    id: z1Panel
                    hostRoot: self.root
                    zoneIndex: 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                NotificationZonePanel {
                    id: z2Panel
                    hostRoot: self.root
                    zoneIndex: 1
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                NotificationZonePanel {
                    id: z3Panel
                    hostRoot: self.root
                    zoneIndex: 2
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            // Available Building Blocks Pool Card
            NotificationBlocksPool {
                id: availBlocksPool
                hostRoot: self.root
            }
        }
    }
}
