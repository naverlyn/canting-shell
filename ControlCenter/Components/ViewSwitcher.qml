import QtQuick
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Lato Nerd Font"
    property bool viewNotifications: false

    width: parent ? parent.width : 300
    height: 34
    implicitHeight: 34
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
            color: !root.viewNotifications 
                ? root.theme.bgSelected 
                : (ccTabMouse.containsMouse ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08) : "transparent")
            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }

            Text {
                anchors.centerIn: parent
                text: "Control Center"
                color: !root.viewNotifications 
                    ? root.theme.textPrimary 
                    : (ccTabMouse.containsMouse ? root.theme.textPrimary : root.theme.textSecondary)
                font.pixelSize: 11
                font.family: root.font
                font.bold: !root.viewNotifications
            }
            
            MouseArea {
                id: ccTabMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.viewNotifications = false
            }
        }

        // Notifications Tab
        Rectangle {
            width: parent.width / 2
            height: parent.height
            radius: 6
            color: root.viewNotifications 
                ? root.theme.bgSelected 
                : (notifTabMouse.containsMouse ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08) : "transparent")
            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }

            Text {
                anchors.centerIn: parent
                text: "Notifications"
                color: root.viewNotifications 
                    ? root.theme.textPrimary 
                    : (notifTabMouse.containsMouse ? root.theme.textPrimary : root.theme.textSecondary)
                font.pixelSize: 11
                font.family: root.font
                font.bold: root.viewNotifications
            }

            MouseArea {
                id: notifTabMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.viewNotifications = true
            }
        }
    }
}
