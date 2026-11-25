import QtQuick
import ".."
import "../../ThemeSwitcher"

Rectangle {
    id: root

    property var theme: Theme
    property string font: "Lato Nerd Font"

    width: parent ? parent.width : 300
    height: innerNotificationsView.implicitHeight + 24
    implicitHeight: innerNotificationsView.implicitHeight + 24
    implicitWidth: 300
    radius: 10
    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
    border.color: root.theme.bgBorder
    border.width: 1
    clip: true

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    NotificationsView {
        id: innerNotificationsView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        theme: root.theme
        font: root.font
    }
}
