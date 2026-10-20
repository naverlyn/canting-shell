import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

ColumnLayout {
    required property var hostCard
    visible: hostCard.editIsCmd
    Layout.fillWidth: true
    spacing: 8

    // Update Interval Selector
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Text {
            text: "Update Interval"
            font.family: hostCard.font
            font.pixelSize: 12
            font.bold: true
            color: hostCard.theme.textPrimary
            Layout.preferredWidth: 140
        }

        // Interval Presets
        RowLayout {
            spacing: 6
            Layout.fillWidth: true

            Repeater {
                model: [
                    { label: "1s (1000ms)", val: 1000 },
                    { label: "5s (5000ms)", val: 5000 },
                    { label: "1m (60000ms)", val: 60000 },
                    { label: "1h (3600000ms)", val: 3600000 }
                ]
                delegate: Rectangle {
                    implicitWidth: intLabel.implicitWidth + 14
                    height: 28
                    radius: 5
                    color: hostCard.editCmdInterval === modelData.val ? hostCard.theme.bgSelected : Qt.rgba(1, 1, 1, 0.04)
                    border.color: hostCard.editCmdInterval === modelData.val ? hostCard.theme.accentPrimary : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    Text {
                        id: intLabel
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: hostCard.font
                        font.pixelSize: 10
                        font.bold: hostCard.editCmdInterval === modelData.val
                        color: hostCard.editCmdInterval === modelData.val ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : (hostCard.theme.textPrimary ?? "#ffffff")

                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: hostCard.editCmdInterval = modelData.val
                    }
                }
            }
        }
    }

    // Command / Script Input
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
            text: "Shell Script Command"
            font.family: hostCard.font
            font.pixelSize: 12
            font.bold: true
            color: hostCard.theme.textPrimary
        }

        Text {
            text: "Executed in bash. Can run system binaries, scripts ($HOME/.config/hypr/scripts), or pipe output."
            font.family: hostCard.font
            font.pixelSize: 11
            color: hostCard.theme.textSecondary
        }

        Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: 6
            color: hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3)
            border.color: hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
            border.width: 1

            TextInput {
                id: cmdInput
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                verticalAlignment: TextInput.AlignVCenter
                text: hostCard.editCmdBody
                font.family: hostCard.font
                font.pixelSize: 12
                color: hostCard.theme.textPrimary
                selectByMouse: true
                onTextChanged: hostCard.editCmdBody = text
            }
        }
    }

    // Live Run / Test Command Box
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            id: runBtn
            implicitWidth: runBtnText.implicitWidth + 24
            height: 32
            radius: 7
            color: runBtnHover.hovered ? (hostCard.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (hostCard.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25))
            border.color: runBtnHover.hovered ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : (hostCard.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
            border.width: 1
            scale: runBtnMouse.pressed ? 0.96 : 1.0

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 80 } }

            HoverHandler { id: runBtnHover }

            Text {
                id: runBtnText
                anchors.centerIn: parent
                text: hostCard.isEvaluating ? "Executing..." : "Execute & Test Output"
                font.family: hostCard.font
                font.pixelSize: 11
                font.bold: true
                color: runBtnHover.hovered ? (hostCard.theme.accentPrimary ?? "#7aa2f7") : (hostCard.theme.textPrimary ?? "#ffffff")
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: runBtnMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !hostCard.isEvaluating
                onClicked: hostCard.runTest()
            }
        }

        Text {
            text: hostCard.isEvaluating ? "Running in bash..." : (hostCard.testOutput !== "" ? "Command finished" : "Click to test output live")
            font.family: hostCard.font
            font.pixelSize: 11
            color: hostCard.theme.textMuted ?? "#888888"
        }
    }

    // Live Execution Output Box
    Rectangle {
        visible: hostCard.testOutput !== ""
        Layout.fillWidth: true
        implicitHeight: Math.max(38, evalOutputText.implicitHeight + 16)
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.45)
        border.color: hostCard.theme.accentPrimary ?? "#7aa2f7"
        border.width: 1

        Text {
            id: evalOutputText
            anchors {
                fill: parent
                margins: 10
            }
            text: hostCard.testOutput
            font.family: hostCard.font
            font.pixelSize: 11
            color: hostCard.theme.textPrimary ?? "#ffffff"
            wrapMode: Text.WrapAnywhere
        }
    }
}
