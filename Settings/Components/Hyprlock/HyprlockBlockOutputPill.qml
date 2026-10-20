import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    required property var hostCard
    visible: !hostCard.isExpanded && hostCard.testOutput !== ""
    Layout.fillWidth: true
    implicitHeight: testOutRow.implicitHeight + 8
    radius: 6
    color: Qt.rgba(0, 0, 0, 0.45)
    border.color: hostCard.theme.accentPrimary ?? "#7aa2f7"
    border.width: 1

    RowLayout {
        id: testOutRow
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: 8
        }
        spacing: 8

        Text {
            text: "Output:"
            font.family: hostCard.font
            font.pixelSize: 11
            font.bold: true
            color: hostCard.theme.accentPrimary ?? "#7aa2f7"
        }

        Text {
            text: hostCard.testOutput
            font.family: hostCard.font
            font.pixelSize: 11
            color: hostCard.theme.textPrimary ?? "#ffffff"
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Rectangle {
            width: 20
            height: 20
            radius: 4
            color: closeOutHover.hovered ? Qt.rgba(1,1,1,0.2) : "transparent"
            HoverHandler { id: closeOutHover }
            Text {
                anchors.centerIn: parent
                text: "x"
                font.family: hostCard.font
                font.pixelSize: 11
                color: hostCard.theme.textMuted ?? "#888888"
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: hostCard.testOutput = ""
            }
        }
    }
}
