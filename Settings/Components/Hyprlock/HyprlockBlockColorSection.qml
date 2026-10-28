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
            color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
            border.color: hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
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
                { name: "Primary", val: "$accent", color: String(hostCard.theme.accentPrimary ?? "#7aa2f7") },
                { name: "Blue / Cyan", val: "$color12", color: String(hostCard.theme.accentCyan ?? "#89b4fa") },
                { name: "Green", val: "$color14", color: String(hostCard.theme.accentGreen ?? "#a6e3a1") },
                { name: "Orange", val: "$color11", color: String(hostCard.theme.accentOrange ?? "#fab387") },
                { name: "Red", val: "$color9", color: String(hostCard.theme.accentRed ?? "#f38ba8") },
                { name: "Text", val: "$text", color: String(hostCard.theme.textPrimary ?? "#cdd6f4") },
                { name: "Secondary", val: "$color10", color: String(hostCard.theme.textSecondary ?? "#bac2de") },
                { name: "Muted", val: "$color8", color: String(hostCard.theme.textMuted ?? "#a6adc8") }
            ]

            Rectangle {
                readonly property bool isSelected: hostCard.editColor === modelData.val
                implicitWidth: chipRow.implicitWidth + 14
                height: 24
                radius: 12
                color: isSelected ? Qt.rgba(hostCard.theme.accentPrimary.r, hostCard.theme.accentPrimary.g, hostCard.theme.accentPrimary.b, 0.2) : (chipHover.hovered ? (hostCard.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)))
                border.color: isSelected ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : Qt.rgba(1, 1, 1, 0.1)
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
                        color: isSelected ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : (hostCard.theme.textSecondary ?? "#a6adc8")
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
