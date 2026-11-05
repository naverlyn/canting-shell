import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

ColumnLayout {
    required property var hostCard
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "Color"
            font.family: hostCard.font
            font.pixelSize: 11
            font.bold: true
            color: hostCard.theme.textSecondary
        }

        // Live Color Preview Chip
        Rectangle {
            width: 18
            height: 18
            radius: 9
            color: hostCard.resolveColor(hostCard.editColor)
            border.color: Qt.rgba(1, 1, 1, 0.25)
            border.width: 1
        }

        Text {
            text: hostCard.editColor
            font.family: hostCard.font
            font.pixelSize: 11
            font.bold: true
            color: hostCard.resolveColor(hostCard.editColor)
        }

        Item { Layout.fillWidth: true }

        // Custom Color Input Field
        Rectangle {
            width: 140
            height: 28
            radius: 6
            color: hostCard.theme.bgBase
            border.color: hostCard.theme.bgBorder
            border.width: 1

            TextInput {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                text: hostCard.editColor
                font.family: hostCard.font
                font.pixelSize: 11
                color: hostCard.theme.textPrimary
                selectByMouse: true
                onTextChanged: {
                    if (text.trim().length > 0 && hostCard.editColor !== text.trim()) {
                        hostCard.editColor = text.trim();
                    }
                }
            }
        }
    }

    // Preset Palette Chips
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: [
                { name: "Primary", val: "$accent", color: hostCard.theme.accentPrimary },
                { name: "Blue / Cyan", val: "$color12", color: hostCard.theme.accentCyan },
                { name: "Green", val: "$color14", color: hostCard.theme.accentGreen },
                { name: "Orange", val: "$color11", color: hostCard.theme.accentOrange },
                { name: "Red", val: "$color9", color: hostCard.theme.accentRed },
                { name: "Text", val: "$text", color: hostCard.theme.textPrimary },
                { name: "Secondary", val: "$color10", color: hostCard.theme.textSecondary },
                { name: "Muted", val: "$color8", color: hostCard.theme.textMuted }
            ]

            Rectangle {
                readonly property bool isSelected: hostCard.editColor === modelData.val
                implicitWidth: chipRow.implicitWidth + 14
                height: 24
                radius: 12
                color: isSelected ? Qt.rgba(hostCard.theme.accentPrimary.r, hostCard.theme.accentPrimary.g, hostCard.theme.accentPrimary.b, 0.2) : (chipHover.hovered ? hostCard.theme.bgHover : hostCard.theme.bgBase)
                border.color: isSelected ? hostCard.theme.accentPrimary : hostCard.theme.bgBorder
                border.width: isSelected ? 1.5 : 1

                HoverHandler { id: chipHover }

                RowLayout {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        color: modelData.color
                        border.color: Qt.rgba(0, 0, 0, 0.3)
                        border.width: 1
                    }

                    Text {
                        text: modelData.name
                        font.family: hostCard.font
                        font.pixelSize: 10
                        font.bold: isSelected
                        color: isSelected ? hostCard.theme.accentPrimary : hostCard.theme.textSecondary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: hostCard.editColor = modelData.val
                }
            }
        }
    }
}
