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

    implicitHeight: isExpanded ? (54 + expandedCol.implicitHeight + 14) : 54
    Layout.preferredHeight: implicitHeight
    radius: 10
    color: isExpanded
        ? Qt.rgba(deviceRow.theme.textPrimary.r, deviceRow.theme.textPrimary.g, deviceRow.theme.textPrimary.b, 0.065)
        : (itemMouse.containsMouse
            ? Qt.rgba(deviceRow.theme.textPrimary.r, deviceRow.theme.textPrimary.g, deviceRow.theme.textPrimary.b, 0.04)
            : "transparent")
    border.color: isExpanded
        ? Qt.rgba(deviceRow.theme.textPrimary.r, deviceRow.theme.textPrimary.g, deviceRow.theme.textPrimary.b, 0.12)
        : "transparent"
    border.width: 1
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 140 } }

    // Left accent pill for connected or expanded device
    Rectangle {
        width: 3
        height: deviceRow.isExpanded ? 26 : 18
        radius: 1.5
        color: deviceRow.theme.accentPrimary
        anchors.left: parent.left
        anchors.leftMargin: 4
        y: deviceRow.isExpanded ? 14 : 18
        visible: deviceRow.isConnected || deviceRow.isExpanded
        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        anchors.topMargin: 8
        anchors.bottomMargin: 10
        spacing: 10

        // Header row
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 36

            RowLayout {
                anchors.fill: parent
                spacing: 12

                Text {
                    text: deviceRow.isConnected ? "󰂱" : "󰂯"
                    font.family: deviceRow.font
                    font.pixelSize: 17
                    color: deviceRow.isConnected ? deviceRow.theme.accentPrimary : deviceRow.theme.textPrimary
                    Layout.preferredWidth: 22
                    horizontalAlignment: Text.AlignHCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: deviceRow.deviceData.name
                        font.family: deviceRow.font
                        font.pixelSize: 13
                        font.bold: deviceRow.isConnected || deviceRow.isExpanded
                        color: deviceRow.theme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: {
                            if (deviceRow.busy) return "Working...";
                            if (deviceRow.isConnected) return "Connected";
                            if (deviceRow.isPaired) return "Paired";
                            return "Available";
                        }
                        font.family: deviceRow.font
                        font.pixelSize: 11
                        color: deviceRow.isConnected ? deviceRow.theme.accentPrimary : deviceRow.theme.textSecondary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: deviceRow.deviceData.mac
                    font.family: deviceRow.font
                    font.pixelSize: 11
                    color: deviceRow.theme.textMuted
                }
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (deviceRow.isExpanded) deviceRow.collapseRequested();
                    else deviceRow.expandRequested(deviceRow.deviceData.mac);
                }
            }
        }

        // Expanded controls
        ColumnLayout {
            id: expandedCol
            Layout.fillWidth: true
            Layout.leftMargin: 34
            visible: deviceRow.isExpanded
            opacity: deviceRow.isExpanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            spacing: 10

            // Device info card for connected/paired devices
            Rectangle {
                visible: deviceRow.isConnected || deviceRow.isPaired
                Layout.fillWidth: true
                implicitHeight: btDetailsGrid.implicitHeight + 16
                radius: 8
                color: deviceRow.theme.bgBase
                border.color: deviceRow.theme.bgBorder
                border.width: 1

                GridLayout {
                    id: btDetailsGrid
                    anchors.fill: parent
                    anchors.margins: 8
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 4

                    Text {
                        text: "MAC Address"
                        color: deviceRow.theme.textMuted
                        font.family: deviceRow.font
                        font.pixelSize: 11
                    }
                    Text {
                        text: deviceRow.deviceData.mac || "—"
                        color: deviceRow.theme.textPrimary
                        font.family: deviceRow.font
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "Status"
                        color: deviceRow.theme.textMuted
                        font.family: deviceRow.font
                        font.pixelSize: 11
                    }
                    Text {
                        text: deviceRow.isConnected ? "Connected" : "Paired (Not connected)"
                        color: deviceRow.isConnected ? deviceRow.theme.accentPrimary : deviceRow.theme.textPrimary
                        font.family: deviceRow.font
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Forget button
                Rectangle {
                    visible: deviceRow.isPaired || deviceRow.isConnected
                    width: 76
                    height: 32
                    radius: 7
                    color: forgetMouse.containsMouse
                        ? Qt.rgba(deviceRow.theme.accentRed.r, deviceRow.theme.accentRed.g, deviceRow.theme.accentRed.b, 0.14)
                        : "transparent"
                    border.color: Qt.rgba(deviceRow.theme.textPrimary.r, deviceRow.theme.textPrimary.g, deviceRow.theme.textPrimary.b, 0.14)
                    border.width: 1
                    opacity: deviceRow.busy ? 0.6 : 1.0
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Forget"
                        color: forgetMouse.containsMouse ? deviceRow.theme.accentRed : deviceRow.theme.textSecondary
                        font.family: deviceRow.font
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: forgetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: deviceRow.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !deviceRow.busy
                        onClicked: deviceRow.forgetRequested(deviceRow.deviceData.mac)
                    }
                }

                Item { Layout.fillWidth: true }

                // Cancel button
                Rectangle {
                    width: 76
                    height: 32
                    radius: 7
                    color: cancelMouse.containsMouse
                        ? Qt.rgba(deviceRow.theme.textPrimary.r, deviceRow.theme.textPrimary.g, deviceRow.theme.textPrimary.b, 0.10)
                        : Qt.rgba(deviceRow.theme.textPrimary.r, deviceRow.theme.textPrimary.g, deviceRow.theme.textPrimary.b, 0.05)
                    border.color: deviceRow.theme.bgBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: deviceRow.theme.textPrimary
                        font.family: deviceRow.font
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: deviceRow.collapseRequested()
                    }
                }

                // Connect button
                Rectangle {
                    visible: !deviceRow.isConnected
                    width: deviceRow.busy ? 104 : 88
                    height: 32
                    radius: 7
                    color: connectMouse.containsMouse
                        ? Qt.lighter(deviceRow.theme.accentPrimary, 1.12)
                        : deviceRow.theme.accentPrimary
                    opacity: deviceRow.busy ? 0.6 : 1.0
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: deviceRow.busy ? "Connecting..." : "Connect"
                        color: deviceRow.theme.bgBase
                        font.family: deviceRow.font
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: connectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: deviceRow.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !deviceRow.busy
                        onClicked: deviceRow.connectRequested(deviceRow.deviceData.mac)
                    }
                }

                // Disconnect button
                Rectangle {
                    visible: deviceRow.isConnected
                    width: 96
                    height: 32
                    radius: 7
                    color: disconnectMouse.containsMouse
                        ? deviceRow.theme.accentRed
                        : Qt.rgba(deviceRow.theme.accentRed.r, deviceRow.theme.accentRed.g, deviceRow.theme.accentRed.b, 0.15)
                    border.color: deviceRow.theme.accentRed
                    border.width: 1
                    opacity: deviceRow.busy ? 0.6 : 1.0
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: deviceRow.busy ? "Working..." : "Disconnect"
                        color: disconnectMouse.containsMouse
                            ? deviceRow.theme.bgBase
                            : deviceRow.theme.accentRed
                        font.family: deviceRow.font
                        font.pixelSize: 12
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                        id: disconnectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: deviceRow.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !deviceRow.busy
                        onClicked: deviceRow.disconnectRequested(deviceRow.deviceData.mac)
                    }
                }
            }
        }
    }
}
