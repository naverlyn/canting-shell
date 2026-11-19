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
    title: "Workspaces Options"
    contentMargins: 8
    contentSpacing: 0

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
                    font.pixelSize: 13
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
