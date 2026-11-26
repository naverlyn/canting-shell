import QtQuick
import QtQuick.Layouts
import "../Common"

Rectangle {
    id: netDelegate
    required property var theme
    required property string font
    required property var networkData
    required property bool isCurrent
    property bool isSaved: false
    property var connectionDetails: ({})
    required property bool isExpanded
    property bool connecting: false
    required property bool disconnecting

    readonly property bool hasSecurity: Boolean(networkData.secured)
    readonly property bool needsPassword: hasSecurity && !isCurrent && !isSaved
    property bool showPassword: false

    signal toggleExpandRequested(string ssid, bool isCurrent, bool needsPassword)
    signal connectRequested(string ssid, string password, bool hasSecurity)
    signal disconnectRequested(string ssid)
    signal forgetRequested(string ssid)
    signal collapseRequested()

    onIsExpandedChanged: {
        if (!isExpanded) showPassword = false;
    }

    implicitHeight: isExpanded ? (54 + expandedCol.implicitHeight + 14) : 54
    Layout.preferredHeight: implicitHeight
    radius: 10
    color: isExpanded
        ? Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.065)
        : (hoverArea.containsMouse
            ? Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.04)
            : "transparent")
    border.color: isExpanded
        ? Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.12)
        : "transparent"
    border.width: 1
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 140 } }

    // Left accent pill for active or expanded network
    Rectangle {
        id: activeIndicator
        width: 3
        height: netDelegate.isExpanded ? 26 : 18
        radius: 1.5
        color: netDelegate.theme.accentPrimary
        anchors.left: parent.left
        anchors.leftMargin: 4
        y: netDelegate.isExpanded ? 14 : 18
        visible: netDelegate.isCurrent || netDelegate.isExpanded
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
                    text: {
                        const sig = netDelegate.networkData.signal || 0;
                        const sec = netDelegate.hasSecurity;
                        if (sig >= 75) return sec ? "󰤪" : "󰤨";
                        if (sig >= 50) return sec ? "󰤧" : "󰤥";
                        if (sig >= 25) return sec ? "󰤤" : "󰤢";
                        return sec ? "󰤡" : "󰤟";
                    }
                    color: netDelegate.isCurrent ? netDelegate.theme.accentPrimary : netDelegate.theme.textPrimary
                    font.pixelSize: Style.px(17)
                    font.family: netDelegate.font
                    Layout.preferredWidth: 22
                    horizontalAlignment: Text.AlignHCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: netDelegate.networkData.ssid
                            color: netDelegate.theme.textPrimary
                            font.pixelSize: Style.px(13)
                            font.family: netDelegate.font
                            font.bold: netDelegate.isCurrent || netDelegate.isExpanded
                            Layout.fillWidth: false
                            Layout.maximumWidth: 260
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            visible: Boolean(netDelegate.networkData.band)
                            width: bandText.implicitWidth + 10
                            height: 16
                            radius: 4
                            color: "transparent"
                            border.color: netDelegate.isCurrent
                                ? Qt.rgba(netDelegate.theme.accentPrimary.r, netDelegate.theme.accentPrimary.g, netDelegate.theme.accentPrimary.b, 0.45)
                                : netDelegate.theme.bgBorder
                            border.width: 1

                            Text {
                                id: bandText
                                anchors.centerIn: parent
                                text: netDelegate.networkData.band || ""
                                color: netDelegate.isCurrent ? netDelegate.theme.accentPrimary : netDelegate.theme.textMuted
                                font.family: netDelegate.font
                                font.pixelSize: Style.px(9)
                                font.bold: true
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        text: {
                            if (netDelegate.connecting) return "Connecting...";
                            if (netDelegate.isCurrent) return netDelegate.hasSecurity ? "Connected • Secured" : "Connected • Open";
                            if (netDelegate.isSaved) return netDelegate.hasSecurity ? "Saved • Secured" : "Saved • Open";
                            return netDelegate.hasSecurity ? "Secured" : "Open";
                        }
                        color: netDelegate.isCurrent ? netDelegate.theme.accentPrimary : netDelegate.theme.textSecondary
                        font.pixelSize: Style.px(11)
                        font.family: netDelegate.font
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: (netDelegate.networkData.signal || 0) + "%"
                    color: netDelegate.theme.textMuted
                    font.pixelSize: Style.px(11)
                    font.family: netDelegate.font
                }

                Text {
                    text: ""
                    visible: netDelegate.hasSecurity && !netDelegate.isCurrent
                    color: netDelegate.theme.textMuted
                    font.pixelSize: Style.px(11)
                    font.family: netDelegate.font
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: netDelegate.toggleExpandRequested(netDelegate.networkData.ssid, netDelegate.isCurrent, netDelegate.needsPassword)
            }
        }

        // Expanded controls
        ColumnLayout {
            id: expandedCol
            Layout.fillWidth: true
            Layout.leftMargin: 34
            visible: netDelegate.isExpanded
            opacity: netDelegate.isExpanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            spacing: 10

            // Connection details (IP, Gateway, DNS, MAC) for active network
            Rectangle {
                visible: netDelegate.isCurrent
                Layout.fillWidth: true
                implicitHeight: detailsGrid.implicitHeight + 16
                radius: 8
                color: netDelegate.theme.bgBase
                border.color: netDelegate.theme.bgBorder
                border.width: 1

                GridLayout {
                    id: detailsGrid
                    anchors.fill: parent
                    anchors.margins: 8
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 4

                    Text {
                        text: "IPv4 Address"
                        color: netDelegate.theme.textMuted
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(11)
                    }
                    Text {
                        text: (netDelegate.connectionDetails && netDelegate.connectionDetails.ipv4) || "—"
                        color: netDelegate.theme.textPrimary
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(11)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "Gateway"
                        color: netDelegate.theme.textMuted
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(11)
                    }
                    Text {
                        text: (netDelegate.connectionDetails && netDelegate.connectionDetails.gateway) || "—"
                        color: netDelegate.theme.textPrimary
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(11)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "DNS"
                        color: netDelegate.theme.textMuted
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(11)
                    }
                    Text {
                        text: (netDelegate.connectionDetails && netDelegate.connectionDetails.dns) || "—"
                        color: netDelegate.theme.textPrimary
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(11)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "MAC Address"
                        color: netDelegate.theme.textMuted
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(11)
                    }
                    Text {
                        text: {
                            const mac = (netDelegate.connectionDetails && netDelegate.connectionDetails.mac) || "—";
                            const iface = (netDelegate.connectionDetails && netDelegate.connectionDetails.iface) || "";
                            return iface ? (mac + " (" + iface + ")") : mac;
                        }
                        color: netDelegate.theme.textPrimary
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(11)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            // Password field
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 8
                visible: netDelegate.needsPassword
                color: netDelegate.theme.bgBase
                border.color: pwdInput.activeFocus ? netDelegate.theme.accentPrimary : netDelegate.theme.bgBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 6

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextInput {
                            id: pwdInput
                            anchors.fill: parent
                            color: netDelegate.theme.textPrimary
                            font.pixelSize: Style.px(12)
                            font.family: netDelegate.font
                            echoMode: netDelegate.showPassword ? TextInput.Normal : TextInput.Password
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            clip: true

                            Keys.onEscapePressed: {
                                if (pwdInput.text !== "") {
                                    pwdInput.text = "";
                                } else {
                                    netDelegate.collapseRequested();
                                }
                            }

                            Keys.onReturnPressed: {
                                netDelegate.connectRequested(netDelegate.networkData.ssid, pwdInput.text, netDelegate.hasSecurity);
                                pwdInput.text = "";
                            }
                        }

                        Text {
                            text: "Enter network security key..."
                            color: netDelegate.theme.textMuted
                            font.pixelSize: Style.px(12)
                            font.family: netDelegate.font
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pwdInput.text === "" && !pwdInput.activeFocus
                        }
                    }

                    Text {
                        text: netDelegate.showPassword ? "󰈉" : "󰈈"
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(14)
                        color: eyeHov.hovered ? netDelegate.theme.textPrimary : netDelegate.theme.textMuted
                        HoverHandler { id: eyeHov }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: netDelegate.showPassword = !netDelegate.showPassword
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Forget saved network button
                Rectangle {
                    visible: netDelegate.isSaved
                    width: 76
                    height: 32
                    radius: 7
                    color: forgetMouse.containsMouse
                        ? Qt.rgba(netDelegate.theme.accentRed.r, netDelegate.theme.accentRed.g, netDelegate.theme.accentRed.b, 0.14)
                        : "transparent"
                    border.color: Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.14)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Forget"
                        color: forgetMouse.containsMouse ? netDelegate.theme.accentRed : netDelegate.theme.textSecondary
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(12)
                    }

                    MouseArea {
                        id: forgetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: netDelegate.forgetRequested(netDelegate.networkData.ssid)
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 76
                    height: 32
                    radius: 7
                    color: cancelMouse.containsMouse
                        ? Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.10)
                        : Qt.rgba(netDelegate.theme.textPrimary.r, netDelegate.theme.textPrimary.g, netDelegate.theme.textPrimary.b, 0.05)
                    border.color: netDelegate.theme.bgBorder
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: netDelegate.theme.textPrimary
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(12)
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            netDelegate.collapseRequested();
                            pwdInput.text = "";
                        }
                    }
                }

                Rectangle {
                    id: connectBtnRect
                    visible: !netDelegate.isCurrent
                    width: netDelegate.connecting ? 104 : 88
                    height: 32
                    radius: 7
                    color: connectBtnMouse.containsMouse
                        ? Qt.lighter(netDelegate.theme.accentPrimary, 1.12)
                        : netDelegate.theme.accentPrimary
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: netDelegate.connecting ? "Connecting..." : "Connect"
                        color: netDelegate.theme.bgBase
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(12)
                        font.bold: true
                    }

                    MouseArea {
                        id: connectBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !netDelegate.connecting
                        onClicked: {
                            netDelegate.connectRequested(netDelegate.networkData.ssid, pwdInput.text, netDelegate.hasSecurity);
                            pwdInput.text = "";
                        }
                    }
                }

                Rectangle {
                    visible: netDelegate.isCurrent
                    width: 96
                    height: 32
                    radius: 7
                    color: disconnectMouse.containsMouse
                        ? netDelegate.theme.accentRed
                        : Qt.rgba(netDelegate.theme.accentRed.r, netDelegate.theme.accentRed.g, netDelegate.theme.accentRed.b, 0.15)
                    border.color: netDelegate.theme.accentRed
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: netDelegate.disconnecting ? "Disconnecting..." : "Disconnect"
                        color: disconnectMouse.containsMouse
                            ? netDelegate.theme.bgBase
                            : netDelegate.theme.accentRed
                        font.family: netDelegate.font
                        font.pixelSize: Style.px(12)
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                        id: disconnectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !netDelegate.disconnecting
                        onClicked: netDelegate.disconnectRequested(netDelegate.networkData.ssid)
                    }
                }
            }
        }
    }
}
