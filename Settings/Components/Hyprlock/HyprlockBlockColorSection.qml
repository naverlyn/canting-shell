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
                { name: "Default", val: "$color8", color: "#9FA7A8" },
                { name: "Accent", val: "$color13", color: "#D8EEF1" },
                { name: "Purple", val: "$color9", color: "#828bb8" },
                { name: "Highlight", val: "$color11", color: "#67748F" },
                { name: "Blue", val: "$color12", color: "#8F9EA7" },
                { name: "Bright", val: "$color7", color: "#E3EEF0" },
                { name: "White", val: "#ffffff", color: "#ffffff" },
                { name: "Primary", val: "$accentPrimary", color: (hostCard.theme && hostCard.theme.accentPrimary ? String(hostCard.theme.accentPrimary) : "#7aa2f7") }
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
