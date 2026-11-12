import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: self
    title: "Screen Brightness & Hyprland Switcher Options"
    contentMargins: 8
    contentSpacing: 0

    SettingToggleRow {
        title: "Show Brightness Percentage"
        desc: "Display numerical backlight level (%) next to the brightness icon"
        checked: BarConfig.brightnessShowPercentage !== false
        onToggled: (val) => {
            BarConfig.brightnessShowPercentage = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Brightness percentage visible" : "Brightness percentage hidden");
        }
    }

    RowDivider {}

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

                Text {
                    text: "Brightness Scroll Step"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Percentage increment per mouse wheel notch on the Brightness pill"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: brStepTrack
                implicitWidth: 220
                implicitHeight: 32
                width: 220
                height: 32
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property int activeVal: Number(BarConfig.brightnessStep || 5)
                readonly property int activeIdx: activeVal <= 2 ? 0 : (activeVal >= 10 ? 2 : 1)
                readonly property real cellWidth: (width - 6 - 8) / 3

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: brStepTrack.cellWidth
                    x: 3 + brStepTrack.activeIdx * (brStepTrack.cellWidth + 4)
                    radius: 5
                    color: root.theme.bgSelected
                    border.color: root.theme.accentPrimary
                    border.width: 1
                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "2%", value: 2 },
                            { label: "5%", value: 5 },
                            { label: "10%", value: 10 }
                        ]
                        delegate: Rectangle {
                            id: brStepBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: brStepTrack.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && brStepHov.hovered ? root.theme.bgHover : "transparent"
                            HoverHandler { id: brStepHov }

                            Text {
                                anchors.centerIn: parent
                                text: brStepBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: brStepBtn.isSel
                                color: brStepBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.brightnessStep = brStepBtn.modelData.value;
                                    BarConfig.saveConfig();
                                    root.showToast("Brightness scroll step set to: " + brStepBtn.modelData.label);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Show Hyprland Layout Name Label"
        desc: "Display active layout text (Dwindle, Master, Monocle) next to the switcher icon"
        checked: BarConfig.hyprLayoutShowLabel !== false
        onToggled: (val) => {
            BarConfig.hyprLayoutShowLabel = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Hyprland layout label visible" : "Hyprland layout icon-only mode");
        }
    }
}
