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
            text: "Cava Visualizer Options"
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
            SettingToggleRow {
                title: "Enable Cava Visualizer"
                checked: BarConfig.showCava !== false
                onToggled: (val) => {
                    BarConfig.showCava = val;
                    BarConfig.saveConfig();
                    root.showToast(val ? "Cava visualizer enabled" : "Cava visualizer disabled");
                }
            }



            RowDivider {}

            SettingToggleRow {
                title: "Auto-Hide When Silent"
                checked: BarConfig.cavaAutoHide
                onToggled: (val) => {
                    BarConfig.cavaAutoHide = val;
                    BarConfig.saveConfig();
                    root.showToast(val ? "Auto-hide enabled" : "Auto-hide disabled");
                }
            }

            RowDivider {}

            // Visual Style Selector: Smooth Bars / Glyphs / Line Waves
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
                            text: "Visualizer Display Style"
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
                            { desktop: "bars",   name: "Bars",   desc: "" },
                            { desktop: "line",   name: "Line",   desc: "" },
                            { desktop: "glyphs", name: "Glyphs", desc: "" }
                        ]
                        currentValue: BarConfig.cavaStyle || "bars"
                        onSelected: (val, opt) => {
                            BarConfig.cavaStyle = val;
                            BarConfig.saveConfig();
                            root.showToast("Cava style set to: " + (opt ? opt.name : val));
                        }
                    }
                }
            }

            RowDivider {}

            // Cava Visualizer Mode Selector: Compact (Current) / Medium / Wide
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
                            text: "Cava Visualizer Mode"
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
                            { desktop: "compact", name: "Compact", desc: "" },
                            { desktop: "medium",  name: "Medium",  desc: "" },
                            { desktop: "wide",    name: "Wide",    desc: "" }
                        ]
                        currentValue: BarConfig.cavaMode || "compact"
                        onSelected: (val, opt) => {
                            BarConfig.setCavaMode(val);
                            root.showToast("Cava mode set to: " + (opt ? opt.name : val));
                        }
                    }
                }
            }

            RowDivider {}

            // Refresh Framerate Selector: 20, 30, 60 FPS
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
                            text: "Visualizer Framerate"
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
                            { desktop: "20", name: "20 FPS", desc: "" },
                            { desktop: "30", name: "30 FPS", desc: "" },
                            { desktop: "60", name: "60 FPS", desc: "" }
                        ]
                        currentValue: String(Number(BarConfig.cavaFramerate || 30))
                        onSelected: (val, opt) => {
                            BarConfig.cavaFramerate = Number(val);
                            BarConfig.saveConfig();
                            root.showToast("Cava framerate set to: " + (opt ? opt.name : val));
                        }
                    }
                }
            }
        }
    }
}
