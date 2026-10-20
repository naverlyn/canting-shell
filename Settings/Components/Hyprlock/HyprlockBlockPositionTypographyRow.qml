import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

RowLayout {
    required property var hostCard
    Layout.fillWidth: true
    spacing: 12

    // Horizontal Alignment
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
            text: "Horizontal Align"
            font.family: hostCard.font
            font.pixelSize: 11
            font.bold: true
            color: hostCard.theme.textSecondary
        }

        Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 5
            color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
            border.color: hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 2
                spacing: 2

                Repeater {
                    model: ["left", "center", "right"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 3
                        color: hostCard.editHalign === modelData ? hostCard.theme.bgSelected : "transparent"
                        border.color: hostCard.editHalign === modelData ? hostCard.theme.accentPrimary : "transparent"
                        border.width: hostCard.editHalign === modelData ? 1 : 0

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            font.family: hostCard.font
                            font.pixelSize: 10
                            font.bold: hostCard.editHalign === modelData
                            color: hostCard.editHalign === modelData ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : hostCard.theme.textSecondary

                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: hostCard.editHalign = modelData
                        }
                    }
                }
            }
        }
    }

    // Vertical Alignment
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
            text: "Vertical Align"
            font.family: hostCard.font
            font.pixelSize: 11
            font.bold: true
            color: hostCard.theme.textSecondary
        }

        Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 5
            color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
            border.color: hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 2
                spacing: 2

                Repeater {
                    model: ["top", "center", "bottom"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 3
                        color: hostCard.editValign === modelData ? hostCard.theme.bgSelected : "transparent"
                        border.color: hostCard.editValign === modelData ? hostCard.theme.accentPrimary : "transparent"
                        border.width: hostCard.editValign === modelData ? 1 : 0

                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            font.family: hostCard.font
                            font.pixelSize: 10
                            font.bold: hostCard.editValign === modelData
                            color: hostCard.editValign === modelData ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : hostCard.theme.textSecondary

                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: hostCard.editValign = modelData
                        }
                    }
                }
            }
        }
    }

    // Coordinates (X, Y)
    ColumnLayout {
        Layout.preferredWidth: 140
        spacing: 4

        Text {
            text: "Offset (X, Y)"
            font.family: hostCard.font
            font.pixelSize: 11
            font.bold: true
            color: hostCard.theme.textSecondary
        }

        RowLayout {
            spacing: 4
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 5
                color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                border.color: hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                TextInput {
                    anchors.fill: parent
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    text: String(hostCard.editPosX)
                    font.family: hostCard.font
                    font.pixelSize: 11
                    color: hostCard.theme.textPrimary
                    selectByMouse: true
                    onTextChanged: {
                        let v = parseInt(text);
                        if (!isNaN(v)) hostCard.editPosX = v;
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 5
                color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                border.color: hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                TextInput {
                    anchors.fill: parent
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    text: String(hostCard.editPosY)
                    font.family: hostCard.font
                    font.pixelSize: 11
                    color: hostCard.theme.textPrimary
                    selectByMouse: true
                    onTextChanged: {
                        let v = parseInt(text);
                        if (!isNaN(v)) hostCard.editPosY = v;
                    }
                }
            }
        }
    }

    // Font Size
    ColumnLayout {
        Layout.preferredWidth: 80
        spacing: 4

        Text {
            text: "Font Size"
            font.family: hostCard.font
            font.pixelSize: 11
            font.bold: true
            color: hostCard.theme.textSecondary
        }

        Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 5
            color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
            border.color: hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            TextInput {
                anchors.fill: parent
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                text: String(hostCard.editFontSize)
                font.family: hostCard.font
                font.pixelSize: 11
                color: hostCard.theme.textPrimary
                selectByMouse: true
                onTextChanged: {
                    let v = parseInt(text);
                    if (!isNaN(v)) hostCard.editFontSize = v;
                }
            }
        }
    }
}
