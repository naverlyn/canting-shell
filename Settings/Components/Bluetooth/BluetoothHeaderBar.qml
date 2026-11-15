import QtQuick
import QtQuick.Layouts

RowLayout {
    id: headerBar
    required property var theme
    required property string font
    required property bool btEnabled
    required property bool btAvailable
    signal enableRequested()
    signal disableRequested()

    Layout.fillWidth: true

    Text {
        text: "Bluetooth Devices"
        font.family: headerBar.font
        font.pixelSize: 15
        font.bold: true
        color: headerBar.theme.accentPrimary
        Layout.fillWidth: true
    }

    Rectangle {
        width: 76
        height: 26
        radius: 6
        color: headerBar.theme.bgSelected
        border.color: Qt.rgba(1, 1, 1, 0.05)
        border.width: 1
        opacity: headerBar.btAvailable ? 1.0 : 0.4
        enabled: headerBar.btAvailable

        Rectangle {
            x: headerBar.btEnabled ? 2 : (parent.width / 2)
            y: 2
            width: (parent.width - 4) / 2
            height: parent.height - 4
            radius: 4
            color: headerBar.btEnabled
                ? Qt.rgba(headerBar.theme.accentPrimary.r, headerBar.theme.accentPrimary.g, headerBar.theme.accentPrimary.b, 0.2)
                : headerBar.theme.bgHover
            border.color: headerBar.btEnabled
                ? headerBar.theme.accentPrimary
                : headerBar.theme.bgBorder
            border.width: 1

            Behavior on x {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color { ColorAnimation { duration: 180 } }
            Behavior on border.color { ColorAnimation { duration: 180 } }
        }

        Row {
            anchors.fill: parent
            anchors.margins: 2
            spacing: 0

            Item {
                width: parent.width / 2
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: "On"
                    color: headerBar.btEnabled ? headerBar.theme.accentPrimary : headerBar.theme.textMuted
                    font.pixelSize: 11
                    font.family: headerBar.font
                    font.bold: headerBar.btEnabled
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!headerBar.btEnabled && headerBar.btAvailable) {
                            headerBar.enableRequested();
                        }
                    }
                }
            }

            Item {
                width: parent.width / 2
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: "Off"
                    color: !headerBar.btEnabled ? headerBar.theme.textPrimary : headerBar.theme.textMuted
                    font.pixelSize: 11
                    font.family: headerBar.font
                    font.bold: !headerBar.btEnabled
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (headerBar.btEnabled && headerBar.btAvailable) {
                            headerBar.disableRequested();
                        }
                    }
                }
            }
        }
    }
}
