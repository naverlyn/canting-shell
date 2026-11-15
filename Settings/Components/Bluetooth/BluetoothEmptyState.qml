import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: emptyState
    required property var theme
    required property string font
    required property bool btAvailable
    required property bool btEnabled

    spacing: 12

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 54
        height: 54
        radius: 27
        color: emptyState.theme.bgSelected

        Text {
            anchors.centerIn: parent
            text: !emptyState.btAvailable ? "󰂲" : (!emptyState.btEnabled ? "󰂲" : "󰂯")
            font.family: emptyState.font
            font.pixelSize: 26
            color: emptyState.theme.textMuted
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: !emptyState.btAvailable
            ? "No Bluetooth Adapter Found"
            : (!emptyState.btEnabled ? "Bluetooth is Disabled" : "No Paired Devices Found")
        font.family: emptyState.font
        font.pixelSize: 14
        font.bold: true
        color: emptyState.theme.textSecondary
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: !emptyState.btAvailable
            ? "Plug in a Bluetooth dongle or enable your wireless card."
            : (!emptyState.btEnabled ? "Turn on Bluetooth to scan and connect devices." : "Click scan to search for nearby Bluetooth devices.")
        font.family: emptyState.font
        font.pixelSize: 12
        color: emptyState.theme.textMuted
    }
}
