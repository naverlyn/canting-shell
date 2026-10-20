import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../../osd"
import "../.."
import "../Common"
import ".."

Item {
    required property var root
    Layout.fillWidth: true
    implicitHeight: 52
    height: 52

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 16

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Channel Test"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }

            Text {
                text: "Verify stereo speaker channel positioning"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            /* Standardized Test Left Button */
            Rectangle {
                implicitWidth: root.dualBtnWidth
                implicitHeight: root.btnHeight
                Layout.preferredWidth: root.dualBtnWidth
                Layout.preferredHeight: root.btnHeight
                width: root.dualBtnWidth
                height: root.btnHeight
                radius: root.btnRadius
                color: leftTestHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2))
                border.color: leftTestHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                border.width: 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: leftTestHover }

                Text {
                    anchors.centerIn: parent
                    text: "Test Left"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.playSound("audio-channel-front-left")
                }
            }

            /* Standardized Test Right Button */
            Rectangle {
                implicitWidth: root.dualBtnWidth
                implicitHeight: root.btnHeight
                Layout.preferredWidth: root.dualBtnWidth
                Layout.preferredHeight: root.btnHeight
                width: root.dualBtnWidth
                height: root.btnHeight
                radius: root.btnRadius
                color: rightTestHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2))
                border.color: rightTestHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                border.width: 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: rightTestHover }

                Text {
                    anchors.centerIn: parent
                    text: "Test Right"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.playSound("audio-channel-front-right")
                }
            }
        }
    }
}
