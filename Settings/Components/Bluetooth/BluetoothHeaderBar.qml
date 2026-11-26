import QtQuick
import QtQuick.Layouts
import "../Common"

RowLayout {
    id: headerBar
    required property var theme
    required property string font
    required property bool btEnabled
    required property bool btAvailable

    signal enableRequested()
    signal disableRequested()

    Layout.fillWidth: true
    spacing: 10

    Text {
        text: "Bluetooth"
        font.family: headerBar.font
        font.pixelSize: Style.px(20)
        font.bold: true
        color: headerBar.theme.textPrimary
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        visible: !headerBar.btAvailable
        text: "Unavailable"
        font.family: headerBar.font
        font.pixelSize: Style.px(12)
        color: headerBar.theme.textMuted
        Layout.alignment: Qt.AlignVCenter
    }

    // Pill Toggle Switch
    Rectangle {
        visible: headerBar.btAvailable
        width: 44
        height: 24
        radius: 12
        color: headerBar.btEnabled
            ? headerBar.theme.accentPrimary
            : Qt.rgba(headerBar.theme.textPrimary.r, headerBar.theme.textPrimary.g, headerBar.theme.textPrimary.b, 0.12)
        border.color: headerBar.btEnabled
            ? "transparent"
            : Qt.rgba(headerBar.theme.textPrimary.r, headerBar.theme.textPrimary.g, headerBar.theme.textPrimary.b, 0.25)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 160 } }

        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 3
            x: headerBar.btEnabled ? (parent.width - width - 3) : 3
            color: headerBar.btEnabled ? headerBar.theme.bgBase : headerBar.theme.textSecondary
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 160 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (headerBar.btEnabled) headerBar.disableRequested();
                else headerBar.enableRequested();
            }
        }
    }
}
