import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    Text {
        text: "Layout & Options"
        font.family: root.font
        font.pixelSize: Style.px(13)
        font.bold: true
        color: root.theme.textSecondary
        Layout.leftMargin: 4
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: layoutCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: layoutCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 0

            /* Current Keyboard Layout Row */
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
                            text: "Keyboard Layout"
                            font.family: root.font
                            font.pixelSize: Style.px(13)
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: layoutBadgeText.implicitWidth + 18
                        height: 28
                        radius: 6
                        color: root.theme.bgSelected
                        border.color: root.theme.bgBorder
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            id: layoutBadgeText
                            anchors.centerIn: parent
                            text: root.getLayoutDisplayName(root.activeLayout)
                            font.family: root.font
                            font.pixelSize: Style.px(12)
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }
                }
            }

            RowDivider {}

            /* NumLock by Default Row */
            SettingToggleRow {
                title: "NumLock on Startup"
                checked: root.numlockByDefault
                onToggled: (val) => {
                    root.numlockByDefault = val;
                    root.applyHyprKeyword("input:numlock_by_default", val ? "true" : "false");
                }
            }

        }
    }
}
