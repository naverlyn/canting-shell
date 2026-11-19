import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../osd"
import "../.."
import "../Common"
import ".."

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8

        Text {
            text: "Orientation & Shape"
            font.family: root.font
            font.pixelSize: 13
            font.bold: true
            color: root.theme.textSecondary
        }

        Item { Layout.fillWidth: true }

        Text {
            text: OSDService.isHorizontal ? "Current: Horizontal" : "Current: Vertical"
            font.family: root.font
            font.pixelSize: 11
            font.bold: true
            color: root.theme.accentPrimary
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: orientCol.implicitHeight + 16
        radius: 12
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: orientCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            spacing: 8

            /* Orientation Dropdown */
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 12

                Text {
                    text: "Orientation"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Item { Layout.fillWidth: true }

                AppDropdown {
                    theme: root.theme
                    font: root.font
                    Layout.preferredWidth: 380
                    implicitWidth: 380
                    menuWidth: 380
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    options: (OSDService.orientationOptions || []).map(o => ({
                        desktop: o.id,
                        name: o.label,
                        desc: ""
                    }))
                    currentValue: OSDService.orientation
                    onSelected: (val) => {
                        OSDService.setOrientation(val);
                        OSDService.testOSD();
                    }
                }
            }
        }
    }
}
