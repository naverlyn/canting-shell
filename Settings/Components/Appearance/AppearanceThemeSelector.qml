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
    id: self
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 8

    // Header row
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "󰔎"
            font.family: root.font
            font.pixelSize: 16
            color: root.theme.accentPrimary
        }

        Text {
            text: "Theme Selector"
            font.family: root.font
            font.pixelSize: 14
            font.bold: true
            color: root.theme.textPrimary
        }

        Text {
            text: "(" + root.filteredThemes.length + " themes)"
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textMuted
        }

        Item { Layout.fillWidth: true }

        // Open Full Theme Switcher Modal button
        Rectangle {
            height: 26
            implicitWidth: modalBtnRow.implicitWidth + 14
            radius: 6
            color: modalBtnMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.08)) : root.theme.bgSurface
            border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                id: modalBtnRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: "󰔎"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.accentPrimary
                }
                Text {
                    text: "Full View"
                    font.family: root.font
                    font.pixelSize: 10
                    color: root.theme.textPrimary
                }
            }

            MouseArea {
                id: modalBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.themeProcRef.running = true
            }
        }
    }

    // Controls row: Category pills on left, search pill on right
    AppearanceCategoryPills {
        root: self.root
    }

    // Scrollable Theme List with smooth container-level hover exit
    AppearanceThemeList {
        root: self.root
    }
}
