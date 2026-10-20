import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

RowLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 14

    ColumnLayout {
        spacing: 2
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

        Text {
            text: "Animations"
            font.family: root.font
            font.pixelSize: 20
            font.bold: true
            color: root.theme.textPrimary
        }

        Text {
            text: "Configure Hyprland window motions, workspace transitions, and curve profiles"
            font.family: root.font
            font.pixelSize: 12
            color: root.theme.textSecondary
        }
    }

    Item {
        Layout.fillWidth: true
    }

    RowLayout {
        id: headerBtnRow
        spacing: 8
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

        // Create Custom Animation Button
        Rectangle {
            implicitWidth: newAnimRow.implicitWidth + 22
            height: 30
            radius: 7
            color: root.isCreatingCustom
                ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                : (newAnimMouse.containsMouse ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.06)))
            border.color: (root.isCreatingCustom || newAnimMouse.containsMouse) ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12))
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
            scale: newAnimMouse.pressed ? 0.96 : 1.0
            Behavior on scale { NumberAnimation { duration: 80 } }

            RowLayout {
                id: newAnimRow
                anchors.centerIn: parent

                Text {
                    text: root.isCreatingCustom ? "Close Studio" : "New Animation"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.isCreatingCustom
                        ? root.theme.accentPrimary
                        : (newAnimMouse.containsMouse ? "#ffffff" : root.theme.textPrimary)
                }
            }

            MouseArea {
                id: newAnimMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.isCreatingCustom = !root.isCreatingCustom;
                    if (root.isCreatingCustom) root.triggerPreview();
                }
            }
        }

        // Quick Reload Button
        Rectangle {
            implicitWidth: refreshRow.implicitWidth + 20
            height: 30
            radius: 7
            color: refreshMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.05))
            border.color: refreshMouse.containsMouse ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12))
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
            scale: refreshMouse.pressed ? 0.96 : 1.0
            Behavior on scale { NumberAnimation { duration: 80 } }

            RowLayout {
                id: refreshRow
                anchors.centerIn: parent

                Text {
                    text: "Reload"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: refreshMouse.containsMouse ? root.theme.accentPrimary : root.theme.textPrimary
                }
            }

            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.queryProcRef.running = true
            }
        }
    }
}
