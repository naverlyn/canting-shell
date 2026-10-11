import QtQuick
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"
    property bool viewNotifications: false

    width: parent ? parent.width : 300
    height: 34
    radius: 8
    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
    border.color: root.theme.bgBorder
    border.width: 1

    Row {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 0

        // Control Center Tab
        Rectangle {
            width: parent.width / 2
            height: parent.height
            radius: 6
            color: !root.viewNotifications ? root.theme.bgSelected : "transparent"
            Behavior on color { ColorAnimation { duration: 180 } }

            Text {
                anchors.centerIn: parent
                text: "Control Center"
                color: !root.viewNotifications 
                    ? root.theme.textPrimary 
                    : root.theme.textSecondary
                font.pixelSize: 11
                font.family: root.font
                font.bold: !root.viewNotifications
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.viewNotifications = false
            }
        }

        // Notifications Tab
        Rectangle {
            width: parent.width / 2
            height: parent.height
            radius: 6
            color: root.viewNotifications ? root.theme.bgSelected : "transparent"
            Behavior on color { ColorAnimation { duration: 180 } }

            Text {
                anchors.centerIn: parent
                text: "Notifications"
                color: root.viewNotifications 
                    ? root.theme.textPrimary 
                    : root.theme.textSecondary
                font.pixelSize: 11
                font.family: root.font
                font.bold: root.viewNotifications
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.viewNotifications = true
            }
        }
    }
}
