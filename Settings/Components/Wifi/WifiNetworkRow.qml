import QtQuick
import QtQuick.Layouts

Rectangle {
    id: netDelegate
    required property var theme
    required property string font
    required property var networkData
    required property bool isCurrent
    required property bool isExpanded
    required property bool disconnecting

    signal toggleExpandRequested(string ssid, bool isCurrent, bool hasSecurity)
    signal connectRequested(string ssid, string password, bool hasSecurity)
    signal disconnectRequested(string ssid)
    signal collapseRequested()

    height: isExpanded ? ((networkData.security && !isCurrent) ? 140 : 100) : 44
    radius: 8
    color: (isCurrent || isExpanded || hoverArea.containsMouse) ? theme.bgSelected : "transparent"
    clip: true

    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        id: activeIndicator
        width: 3
        height: 24
        radius: 2
        color: netDelegate.theme.accentPrimary
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.top: parent.top
        anchors.topMargin: 10
        visible: netDelegate.isCurrent
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: netDelegate.isExpanded ? 14 : 0
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: netDelegate.isExpanded ? -1 : 44
            spacing: 12

            Text {
                text: {
                    if (netDelegate.networkData.signal > 80) return "󰤨";
                    if (netDelegate.networkData.signal > 60) return "󰤥";
                    if (netDelegate.networkData.signal > 40) return "󰤢";
                    if (netDelegate.networkData.signal > 0) return "󰤟";
                    return "󰤨";
                }
                color: netDelegate.isCurrent ? netDelegate.theme.accentPrimary : netDelegate.theme.textPrimary
                font.pixelSize: 16
                font.family: netDelegate.font
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                text: netDelegate.networkData.ssid
                color: netDelegate.isCurrent ? netDelegate.theme.textPrimary : netDelegate.theme.textSecondary
                font.pixelSize: 13
                font.family: netDelegate.font
                font.bold: netDelegate.isCurrent || netDelegate.isExpanded
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            Text {
                text: "Connected"
                color: netDelegate.isCurrent ? netDelegate.theme.accentPrimary : netDelegate.theme.textPrimary
                font.pixelSize: 13
                font.family: netDelegate.font
                visible: netDelegate.isCurrent
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                text: ""
                visible: netDelegate.networkData.security && !netDelegate.isCurrent && !netDelegate.isExpanded
                color: netDelegate.theme.textMuted
                font.pixelSize: 12
                font.family: netDelegate.font
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: netDelegate.isExpanded
            opacity: netDelegate.isExpanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 6
                visible: netDelegate.networkData.security && !netDelegate.isCurrent
                color: netDelegate.theme.bgSurface
                border.color: pwdInput.activeFocus ? netDelegate.theme.accentPrimary : netDelegate.theme.bgBorder
                border.width: 1

                TextInput {
                    id: pwdInput
                    anchors.fill: parent
                    anchors.margins: 10
                    color: netDelegate.theme.textPrimary
                    font.pixelSize: 13
                    font.family: netDelegate.font
                    echoMode: TextInput.Password
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true

                    Keys.onEscapePressed: {
                        if (pwdInput.text !== "") {
                            pwdInput.text = "";
                        } else {
                            netDelegate.collapseRequested();
                        }
                    }

                    Keys.onReturnPressed: {
                        netDelegate.connectRequested(netDelegate.networkData.ssid, pwdInput.text, true);
                        pwdInput.text = "";
                    }
                }

                Text {
                    text: "Password"
                    color: netDelegate.theme.textMuted
                    font.pixelSize: 13
                    font.family: netDelegate.font
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    visible: pwdInput.text === ""
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item { Layout.fillWidth: true }

                Rectangle {
                    id: connectBtnRect
                    visible: !netDelegate.isCurrent
                    width: 80
                    height: 32
                    radius: 6
                    color: connectBtnMouse.containsMouse
                        ? netDelegate.theme.accentCyan
                        : netDelegate.theme.accentPrimary
                    border.color: "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Connect"
                        color: netDelegate.theme.bgBase
                        font.family: netDelegate.font
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        id: connectBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            netDelegate.connectRequested(netDelegate.networkData.ssid, pwdInput.text, netDelegate.networkData.security);
                            pwdInput.text = "";
                        }
                    }
                }

                Rectangle {
                    visible: netDelegate.isCurrent
                    width: 90
                    height: 32
                    radius: 6
                    color: disconnectMouse.containsMouse
                        ? netDelegate.theme.accentRed
                        : Qt.rgba(netDelegate.theme.accentRed.r, netDelegate.theme.accentRed.g, netDelegate.theme.accentRed.b, 0.15)
                    border.color: netDelegate.theme.accentRed
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: netDelegate.disconnecting ? "Disconnecting..." : "Disconnect"
                        color: disconnectMouse.containsMouse
                            ? netDelegate.theme.bgBase
                            : netDelegate.theme.accentRed
                        font.family: netDelegate.font
                        font.pixelSize: 12
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 150 } }
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

                Rectangle {
                    width: 80
                    height: 32
                    radius: 6
                    color: netDelegate.theme.bgHover
                    border.color: netDelegate.theme.bgBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: netDelegate.theme.textPrimary
                        font.family: netDelegate.font
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            netDelegate.collapseRequested();
                            pwdInput.text = "";
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 44
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: netDelegate.toggleExpandRequested(netDelegate.networkData.ssid, netDelegate.isCurrent, netDelegate.networkData.security)
    }
}
