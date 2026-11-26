import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../MonitorManager"
import "../../../MonitorManager/Components"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Compositor & Display Power"
        font.family: root.font
        font.pixelSize: Style.px(13)
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: compGroupCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: compGroupCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Row 1: Variable Refresh Rate (VRR / Adaptive Sync) */
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
                            text: "Variable Refresh Rate (VRR)"
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
                        options: [
                            { desktop: "0", name: "Off",        desc: "" },
                            { desktop: "1", name: "Always",     desc: "" },
                            { desktop: "2", name: "Fullscreen", desc: "" }
                        ]
                        currentValue: String(root.vrrMode)
                        onSelected: (val) => root.setVrrMode(Number(val))
                    }
                }
            }

            RowDivider {}

            /* Row 2: Allow Screen Tearing */
            SettingToggleRow {
                title: "Allow Tearing"
                checked: root.allowTearing
                onToggled: (val) => root.setAllowTearing(val)
            }
        }
    }
}
