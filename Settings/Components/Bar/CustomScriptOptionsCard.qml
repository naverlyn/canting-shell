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
    title: "Custom Script Module Options"
    contentMargins: 8
    contentSpacing: 0

    // 1. Command to Execute
    Item {
        Layout.fillWidth: true
        height: 62

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
                    text: "Script / Shell Command"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Supports plain text (line 1 = pill, line 2+ = tooltip) or Waybar JSON {\"text\", \"tooltip\", \"icon\"}"
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

                Rectangle {
                    width: 240
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: csCmdInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1
                    clip: true

                    TextInput {
                        id: csCmdInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textPrimary
                        selectByMouse: true
                        text: BarConfig.customScriptCommand

                        function applyChange() {
                            BarConfig.customScriptCommand = text.trim();
                            BarConfig.customScriptRevision++;
                            BarConfig.saveConfig();
                            root.showToast("Custom script command updated");
                        }

                        onAccepted: applyChange()
                    }
                }

                ActionButton {
                    label: "Apply"
                    btnHeight: 32
                    onClicked: csCmdInput.applyChange()
                }
            }
        }
    }

    RowDivider {}

    // 2. Icon & Left-Click Action
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

                Text {
                    text: "Icon & Left-Click Command"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Nerd Font glyph and optional command triggered when clicking the pill"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                Rectangle {
                    width: 54
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: csIconInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1

                    TextInput {
                        id: csIconInput
                        anchors.fill: parent
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 13
                        color: root.theme.accentPrimary
                        selectByMouse: true
                        text: BarConfig.customScriptIcon
                        onAccepted: csClickInput.applyBoth()
                    }
                }

                Rectangle {
                    width: 180
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: csClickInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1
                    clip: true

                    TextInput {
                        id: csClickInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textPrimary
                        selectByMouse: true
                        text: BarConfig.customScriptOnClick

                        function applyBoth() {
                            BarConfig.customScriptIcon = csIconInput.text.trim();
                            BarConfig.customScriptOnClick = csClickInput.text.trim();
                            BarConfig.customScriptRevision++;
                            BarConfig.saveConfig();
                            root.showToast("Custom script icon & click command saved");
                        }

                        onAccepted: applyBoth()

                        Text {
                            visible: parent.text === "" && !parent.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            text: "On-click cmd (optional)..."
                            font.family: root.font
                            font.pixelSize: 10
                            color: root.theme.textMuted
                        }
                    }
                }

                ActionButton {
                    label: "Save"
                    btnHeight: 32
                    onClicked: csClickInput.applyBoth()
                }
            }
        }
    }

    RowDivider {}

    // 3. Poll Interval
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
                    text: "Execution Poll Interval"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "How often the custom script is executed in the background"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                id: csIntTrack
                implicitWidth: 260
                implicitHeight: 32
                width: 260
                height: 32
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1

                readonly property int activeVal: Number(BarConfig.customScriptInterval || 10)
                readonly property int activeIdx: activeVal <= 5 ? 0 : (activeVal <= 10 ? 1 : (activeVal <= 30 ? 2 : 3))
                readonly property real cellWidth: (width - 6 - 12) / 4

                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: csIntTrack.cellWidth
                    x: 3 + csIntTrack.activeIdx * (csIntTrack.cellWidth + 4)
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
                            { label: "5s", value: 5 },
                            { label: "10s", value: 10 },
                            { label: "30s", value: 30 },
                            { label: "60s", value: 60 }
                        ]
                        delegate: Rectangle {
                            id: csIntBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: csIntTrack.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && csIntHov.hovered ? root.theme.bgHover : "transparent"
                            HoverHandler { id: csIntHov }

                            Text {
                                anchors.centerIn: parent
                                text: csIntBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: csIntBtn.isSel
                                color: csIntBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.customScriptInterval = csIntBtn.modelData.value;
                                    BarConfig.customScriptRevision++;
                                    BarConfig.saveConfig();
                                    root.showToast("Custom script poll interval set to: " + csIntBtn.modelData.label);
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
        title: "Show Hover Popup Card"
        desc: "Display a popup card with full script/tooltip output when hovering or clicking the pill"
        checked: Boolean(BarConfig.customScriptShowPopup)
        onToggled: (val) => {
            BarConfig.customScriptShowPopup = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Custom script popup card enabled" : "Custom script popup card disabled");
        }
    }

    RowDivider {}

    SettingToggleRow {
        title: "Auto-Hide When Output is Empty"
        desc: "Collapse the Custom Script pill automatically if the command produces no output"
        checked: Boolean(BarConfig.customScriptHideWhenEmpty)
        onToggled: (val) => {
            BarConfig.customScriptHideWhenEmpty = val;
            BarConfig.saveConfig();
            root.showToast(val ? "Custom script will hide when empty" : "Custom script always visible");
        }
    }
}
