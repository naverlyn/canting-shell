import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../../bar"
import "../../../MonitorManager"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: self
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8
        Text {
            text: "Workspaces Options"
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
        implicitHeight: innerCol.implicitHeight + 8 * 2
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
                margins: 8
            }
            spacing: 0
            Item {
                Layout.fillWidth: true
                height: 40

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Workspace Numbering Style"
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
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        options: [
                            { desktop: "index", name: "1, 2, 3",    desc: "" },
                            { desktop: "roman", name: "I, II, III", desc: "" },
                            { desktop: "dot",   name: "• • •",      desc: "" }
                        ]
                        currentValue: BarConfig.workspaceStyle || "index"
                        onSelected: (val, opt) => {
                            BarConfig.workspaceStyle = val;
                            BarConfig.saveConfig();
                            root.showToast("Workspace style set to: " + (opt ? opt.name : val));
                        }
                    }
                }
            }

            RowDivider {}

            SettingToggleRow {
                title: "Mouse Wheel Workspace Switching"
                checked: BarConfig.workspaceScrollSwitch !== false
                onToggled: (val) => {
                    BarConfig.workspaceScrollSwitch = val;
                    BarConfig.saveConfig();
                    root.showToast(val ? "Mouse wheel workspace switching enabled" : "Mouse wheel workspace switching disabled");
                }
            }
        }
    }
}
