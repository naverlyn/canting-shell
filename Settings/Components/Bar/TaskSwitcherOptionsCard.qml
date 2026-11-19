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
    title: "Task Switcher Options"
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
                    text: "Display Mode"
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
                    { desktop: "icon",      name: "Icon Only",             desc: "" },
                    { desktop: "icon_desc", name: "Icon with Description", desc: "" },
                    { desktop: "desc",      name: "Description Only",      desc: "" }
                ]
                currentValue: BarConfig.taskSwitcherMode || "icon_desc"
                onSelected: (val, opt) => {
                    BarConfig.taskSwitcherMode = val;
                    BarConfig.saveConfig();
                    root.showToast("Task switcher mode: " + (opt ? opt.name : val));
                }
            }
        }
    }

    RowDivider {}

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
                    text: "Window Scope"
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
                    { desktop: "all",       name: "All Workspaces",    desc: "" },
                    { desktop: "workspace", name: "Current Workspace", desc: "" }
                ]
                currentValue: BarConfig.taskSwitcherScope || "all"
                onSelected: (val, opt) => {
                    BarConfig.taskSwitcherScope = val;
                    BarConfig.saveConfig();
                    root.showToast("Task switcher scope: " + (opt ? opt.name : val));
                }
            }
        }
    }

    RowDivider {
        visible: (BarConfig.taskSwitcherMode || "icon_desc") !== "icon"
    }

    Item {
        visible: (BarConfig.taskSwitcherMode || "icon_desc") !== "icon"
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
                    text: "Max Label Width"
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
                    { desktop: "100", name: "Compact (100 px)", desc: "" },
                    { desktop: "140", name: "Balanced (140 px)", desc: "" },
                    { desktop: "180", name: "Wide (180 px)", desc: "" },
                    { desktop: "240", name: "Extra Wide (240 px)", desc: "" }
                ]
                currentValue: String(BarConfig.taskSwitcherMaxLabelWidth || 140)
                onSelected: (val, opt) => {
                    BarConfig.taskSwitcherMaxLabelWidth = Number(val) || 140;
                    BarConfig.saveConfig();
                    root.showToast("Task label width: " + (opt ? opt.name : val));
                }
            }
        }
    }
}
