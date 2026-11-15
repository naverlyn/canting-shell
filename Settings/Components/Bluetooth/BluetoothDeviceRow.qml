import QtQuick
import QtQuick.Layouts

Rectangle {
    id: deviceRow
    required property var theme
    required property string font
    required property var deviceData
    required property bool isExpanded
    property bool busy: false

    readonly property bool isConnected: Boolean(deviceData && deviceData.connected)
    readonly property bool isPaired: Boolean(deviceData && deviceData.paired)

    signal expandRequested(string mac)
    signal connectRequested(string mac)
    signal disconnectRequested(string mac)
    signal forgetRequested(string mac)
    signal collapseRequested()

    height: isExpanded ? 96 : 44
    radius: 8
    color: (isExpanded || itemMouse.containsMouse) ? theme.bgSelected : "transparent"
    clip: true

    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 150 } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Text {
                text: deviceRow.isConnected ? "󰂱" : "󰂯"
                font.family: deviceRow.font
                font.pixelSize: 16
                color: deviceRow.isConnected
                    ? deviceRow.theme.accentGreen
                    : (deviceRow.isExpanded ? deviceRow.theme.accentPrimary : deviceRow.theme.textPrimary)
            }

            Text {
                text: deviceRow.deviceData.name
                font.family: deviceRow.font
                font.pixelSize: 14
                font.bold: deviceRow.isExpanded || deviceRow.isConnected
                color: deviceRow.isConnected
                    ? deviceRow.theme.accentGreen
                    : (deviceRow.isExpanded ? deviceRow.theme.accentPrimary : deviceRow.theme.textPrimary)
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: deviceRow.busy || deviceRow.isConnected || deviceRow.isPaired
                text: deviceRow.busy
                    ? "Working..."
                    : (deviceRow.isConnected ? "Connected" : "Paired")
                font.family: deviceRow.font
                font.pixelSize: 11
                font.bold: deviceRow.isConnected
                color: deviceRow.busy
                    ? deviceRow.theme.accentPrimary
                    : (deviceRow.isConnected ? deviceRow.theme.accentGreen : deviceRow.theme.textMuted)
            }

            Text {
                text: deviceRow.deviceData.mac
                font.family: deviceRow.font
                font.pixelSize: 12
                color: deviceRow.theme.textMuted
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: deviceRow.isExpanded

            RowLayout {
                anchors.fill: parent
                spacing: 8
                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: !deviceRow.isConnected
                    width: deviceRow.busy ? 96 : 80
                    height: 30
                    radius: 6
                    color: deviceRow.theme.bgSurface
                    border.color: deviceRow.theme.accentPrimary
                    border.width: 1
                    opacity: deviceRow.busy ? 0.6 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: deviceRow.busy ? "Connecting..." : "Connect"
                        font.family: deviceRow.font
                        font.pixelSize: 12
                        color: deviceRow.theme.accentPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: deviceRow.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !deviceRow.busy
                        onClicked: deviceRow.connectRequested(deviceRow.deviceData.mac)
                    }
                }

                Rectangle {
                    visible: deviceRow.isConnected
                    width: 84
                    height: 30
                    radius: 6
                    color: deviceRow.theme.bgSurface
                    border.color: deviceRow.theme.bgBorder
                    border.width: 1
                    opacity: deviceRow.busy ? 0.6 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: deviceRow.busy ? "Working..." : "Disconnect"
                        font.family: deviceRow.font
                        font.pixelSize: 12
                        color: deviceRow.theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: deviceRow.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !deviceRow.busy
                        onClicked: deviceRow.disconnectRequested(deviceRow.deviceData.mac)
                    }
                }

                Rectangle {
                    width: 80
                    height: 30
                    radius: 6
                    color: deviceRow.theme.bgSurface
                    border.color: Qt.rgba(deviceRow.theme.accentRed.r, deviceRow.theme.accentRed.g, deviceRow.theme.accentRed.b, 0.5)
                    border.width: 1
                    opacity: deviceRow.busy ? 0.6 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: "Forget"
                        font.family: deviceRow.font
                        font.pixelSize: 12
                        color: deviceRow.theme.accentRed
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: deviceRow.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !deviceRow.busy
                        onClicked: deviceRow.forgetRequested(deviceRow.deviceData.mac)
                    }
                }

                Rectangle {
                    width: 80
                    height: 30
                    radius: 6
                    color: deviceRow.theme.bgSurface
                    border.color: deviceRow.theme.bgBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: deviceRow.font
                        font.pixelSize: 12
                        color: deviceRow.theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: deviceRow.collapseRequested()
                    }
                }
            }
        }
    }

    MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !deviceRow.isExpanded
        onClicked: deviceRow.expandRequested(deviceRow.deviceData.mac)
    }
}
