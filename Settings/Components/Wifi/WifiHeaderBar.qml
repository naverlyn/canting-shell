import QtQuick
import QtQuick.Layouts

RowLayout {
    id: headerBar
    required property var theme
    required property string font
    required property bool wifiEnabled
    signal enableRequested()
    signal disableRequested()

    Layout.fillWidth: true

    Text {
        text: "Available Networks"
        font.family: headerBar.font
        font.pixelSize: 15
        font.bold: true
        color: headerBar.theme.accentPrimary
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
        width: 76
        height: 26
        radius: 6
        color: headerBar.theme.bgSurface
        border.color: Qt.rgba(1, 1, 1, 0.05)
        border.width: 1

        Row {
            anchors.fill: parent
            anchors.margins: 2
            spacing: 0

            Rectangle {
                width: parent.width / 2
                height: parent.height
                radius: 4
                color: headerBar.wifiEnabled ? headerBar.theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "On"
                    color: headerBar.wifiEnabled ? headerBar.theme.accentPrimary : headerBar.theme.textMuted
                    font.pixelSize: 11
                    font.family: headerBar.font
                    font.bold: headerBar.wifiEnabled
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!headerBar.wifiEnabled) headerBar.enableRequested();
                    }
                }
            }

            Rectangle {
                width: parent.width / 2
                height: parent.height
                radius: 4
                color: !headerBar.wifiEnabled ? headerBar.theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "Off"
                    color: !headerBar.wifiEnabled ? headerBar.theme.textPrimary : headerBar.theme.textMuted
                    font.pixelSize: 11
                    font.family: headerBar.font
                    font.bold: !headerBar.wifiEnabled
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (headerBar.wifiEnabled) headerBar.disableRequested();
                    }
                }
            }
        }
    }
}
