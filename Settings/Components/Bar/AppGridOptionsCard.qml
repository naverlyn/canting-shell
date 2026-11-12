import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

SectionCard {
    required property var root
    id: self
    title: "Applications (AppGrid) Button Options"
    contentMargins: 8
    contentSpacing: 0

    readonly property var iconPresets: [
        { icon: "󰀻", label: "Grid" },
        { icon: "󰕮", label: "Bento" },
        { icon: "󰣇", label: "Arch" },
        { icon: "", label: "Hyprland" },
        { icon: "", label: "NixOS" },
        { icon: "", label: "Linux" },
        { icon: "󱓞", label: "Rocket" },
        { icon: "󰍜", label: "Menu" },
        { icon: "󰘳", label: "Super" }
    ]

    // 1. Preset Icons Row
    Item {
        Layout.fillWidth: true
        implicitHeight: presetRowLayout.implicitHeight + 24
        height: implicitHeight

        RowLayout {
            id: presetRowLayout
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true

                Text {
                    text: "Icon Presets"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Quick-select a launcher, distro, or grid icon for the bar AppGrid button"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Flow {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                Repeater {
                    model: self.iconPresets
                    delegate: Rectangle {
                        id: presetBtn
                        required property var modelData
                        readonly property bool isSelected: (BarConfig.appGridIcon || "󰀻") === modelData.icon

                        implicitWidth: presetBtnRow.implicitWidth + 16
                        implicitHeight: 30
                        width: implicitWidth
                        height: implicitHeight
                        radius: 7
                        scale: presetMouse.pressed ? 0.94 : (presetHover.hovered ? 1.04 : 1.0)
                        color: isSelected
                            ? root.theme.bgSelected
                            : (presetHover.hovered ? root.theme.bgHover : root.theme.bgBase)
                        border.color: isSelected
                            ? root.theme.accentPrimary
                            : (presetHover.hovered ? root.withAlpha(root.theme.accentPrimary, 0.5) : root.theme.bgBorder)
                        border.width: isSelected ? 1.5 : 1

                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: presetHover }

                        RowLayout {
                            id: presetBtnRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: presetBtn.modelData.icon
                                font.family: root.font
                                font.pixelSize: 14
                                color: presetBtn.isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: presetBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: presetBtn.isSelected
                                color: presetBtn.isSelected ? root.theme.accentPrimary : root.theme.textSecondary
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: presetMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                BarConfig.appGridIcon = presetBtn.modelData.icon;
                                appGridIconInput.text = presetBtn.modelData.icon;
                                BarConfig.saveConfig();
                                root.showToast("AppGrid icon set to " + presetBtn.modelData.icon + " (" + presetBtn.modelData.label + ")");
                            }
                        }
                    }
                }
            }
        }
    }

    RowDivider {}

    // 2. Custom Icon / Glyph Input Row
    Item {
        Layout.fillWidth: true
        height: 60

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
                    text: "Custom Icon or Label"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Enter any Nerd Font glyph, symbol, or custom text for the Applications button"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                // Live Pill Preview
                Rectangle {
                    implicitWidth: Math.max(32, previewGlyphTxt.implicitWidth + 16)
                    height: 32
                    radius: 7
                    color: root.withAlpha(root.theme.accentPrimary, 0.12)
                    border.color: root.withAlpha(root.theme.accentPrimary, 0.4)
                    border.width: 1

                    Text {
                        id: previewGlyphTxt
                        anchors.centerIn: parent
                        text: appGridIconInput.text.trim() !== "" ? appGridIconInput.text.trim() : (BarConfig.appGridIcon || "󰀻")
                        font.family: root.font
                        font.pixelSize: 14
                        color: root.theme.accentPrimary
                    }
                }

                Rectangle {
                    width: 120
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: appGridIconInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1
                    clip: true

                    TextInput {
                        id: appGridIconInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 13
                        color: root.theme.textPrimary
                        selectByMouse: true
                        text: BarConfig.appGridIcon || "󰀻"

                        Connections {
                            target: BarConfig
                            function onAppGridIconChanged() {
                                if (!appGridIconInput.activeFocus) {
                                    appGridIconInput.text = BarConfig.appGridIcon || "󰀻";
                                }
                            }
                        }

                        function applyIcon() {
                            const val = text.trim() || "󰀻";
                            text = val;
                            BarConfig.appGridIcon = val;
                            BarConfig.saveConfig();
                            root.showToast("AppGrid icon updated to: " + val);
                        }

                        onAccepted: applyIcon()
                    }
                }

                ActionButton {
                    label: "Apply"
                    btnHeight: 32
                    onClicked: appGridIconInput.applyIcon()
                }

                ActionButton {
                    iconText: "󰦛"
                    label: "Reset"
                    btnHeight: 32
                    btnEnabled: (BarConfig.appGridIcon || "󰀻") !== "󰀻"
                    onClicked: {
                        BarConfig.appGridIcon = "󰀻";
                        appGridIconInput.text = "󰀻";
                        BarConfig.saveConfig();
                        root.showToast("AppGrid icon reset to default (󰀻)");
                    }
                }
            }
        }
    }
}
