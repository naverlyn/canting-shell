import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

ColumnLayout {
    required property var hostCard
    visible: !hostCard.editIsCmd
    Layout.fillWidth: true
    spacing: 6

    Text {
        text: "Text / Variable Value"
        font.family: hostCard.font
        font.pixelSize: 12
        font.bold: true
        color: hostCard.theme.textPrimary
    }

    Rectangle {
        Layout.fillWidth: true
        height: 38
        radius: 6
        color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3)
        border.color: hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        TextInput {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }
            verticalAlignment: TextInput.AlignVCenter
            text: hostCard.editRawText
            font.family: hostCard.font
            font.pixelSize: 12
            color: hostCard.theme.textPrimary
            selectByMouse: true
            onTextChanged: hostCard.editRawText = text
        }
    }

    // Quick Insert Variable Buttons
    RowLayout {
        spacing: 6
        Text {
            text: "Quick Insert:"
            font.family: hostCard.font
            font.pixelSize: 10
            color: hostCard.theme.textMuted
        }

        Repeater {
            model: ["$USER", "$LAYOUT", "$TIME", "Locked"]
            delegate: Rectangle {
                implicitWidth: pillText.implicitWidth + 12
                height: 22
                radius: 4
                color: pillHover.hovered ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.06)
                border.color: Qt.rgba(1,1,1,0.1)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                HoverHandler { id: pillHover }

                Text {
                    id: pillText
                    anchors.centerIn: parent
                    text: modelData
                    font.family: hostCard.font
                    font.pixelSize: 10
                    color: hostCard.theme.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        hostCard.editRawText = modelData;
                    }
                }
            }
        }
    }
}
