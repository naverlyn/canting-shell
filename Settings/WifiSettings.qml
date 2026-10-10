import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    property var theme
    property string font

    property var networks: []
    property bool wifiEnabled: true
    property string currentSsid: ""
    property string expandedSsid: ""

    // Wi-Fi radio status
    Process {
        id: wifiStateProc
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    // Currently active SSID
    Process {
        id: activeSsidProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.currentSsid = text.trim();
            }
        }
    }

    // Scan for available Wi-Fi networks (matching Control Center's proven field parsing)
    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "ssid,signal,security", "dev", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const nets = [];
                const seen = new Set();
                for (const line of lines) {
                    if (!line) continue;
                    const parts = line.split(":");
                    if (parts.length >= 3) {
                        const ssid = parts[0];
                        if (!ssid || seen.has(ssid)) continue;
                        seen.add(ssid);
                        nets.push({
                            ssid: ssid,
                            signal: parseInt(parts[1]) || 0,
                            security: parts[2] !== ""
                        });
                    }
                }
                // Sort by signal strength, always prioritizing the active network at the top
                root.networks = nets.sort((a, b) => {
                    if (a.ssid === root.currentSsid) return -1;
                    if (b.ssid === root.currentSsid) return 1;
                    return b.signal - a.signal;
                });
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: {
            wifiStateProc.running = true;
            activeSsidProc.running = true;
            if (root.wifiEnabled) scanProc.running = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Available Networks"
                font.family: root.font
                font.pixelSize: 15
                font.bold: true
                color: root.theme.accentPrimary
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: Text.AlignVCenter
            }

            // Segmented On/Off Toggle
            Rectangle {
                width: 76
                height: 26
                radius: 6
                color: root.theme.bgSurface
                border.color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1

                // Smooth sliding active switch pill
                Rectangle {
                    x: root.wifiEnabled ? 2 : (parent.width / 2)
                    y: 2
                    width: (parent.width - 4) / 2
                    height: parent.height - 4
                    radius: 4
                    color: root.wifiEnabled 
                        ? (root.theme ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.2) : Qt.rgba(0.5, 0.7, 1, 0.2))
                        : (root.theme ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : Qt.rgba(1, 1, 1, 0.08))
                    border.color: root.wifiEnabled 
                        ? (root.theme ? root.theme.accentPrimary : "#7aa2f7") 
                        : (root.theme ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)) : Qt.rgba(1, 1, 1, 0.1))
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

                    // "On" segment
                    Item {
                        width: parent.width / 2
                        height: parent.height

                        Text {
                            anchors.centerIn: parent
                            text: "On"
                            color: root.wifiEnabled ? root.theme.accentPrimary : root.theme.textMuted
                            font.pixelSize: 11
                            font.family: root.font
                            font.bold: root.wifiEnabled
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.wifiEnabled) {
                                    toggleProc.command = ["nmcli", "radio", "wifi", "on"];
                                    toggleProc.running = true;
                                    root.wifiEnabled = true;
                                    activeSsidProc.running = true;
                                    scanProc.running = true;
                                }
                            }
                        }
                    }

                    // "Off" segment
                    Item {
                        width: parent.width / 2
                        height: parent.height

                        Text {
                            anchors.centerIn: parent
                            text: "Off"
                            color: !root.wifiEnabled ? root.theme.textPrimary : root.theme.textMuted
                            font.pixelSize: 11
                            font.family: root.font
                            font.bold: !root.wifiEnabled
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.wifiEnabled) {
                                    toggleProc.command = ["nmcli", "radio", "wifi", "off"];
                                    toggleProc.running = true;
                                    root.wifiEnabled = false;
                                    root.networks = [];
                                    root.expandedSsid = "";
                                }
                            }
                        }
                    }
                }
                Process { id: toggleProc }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.networks
            clip: true
            spacing: 4
            
            delegate: Rectangle {
                id: netDelegate
                required property var modelData
                required property int index

                readonly property bool isCurrent: modelData.ssid === root.currentSsid
                readonly property bool isExpanded: root.expandedSsid === modelData.ssid

                width: ListView.view.width
                height: isExpanded ? (modelData.security ? 140 : 100) : 44
                radius: 8
                color: (isCurrent || isExpanded || hoverArea.containsMouse) ? root.theme.bgSelected : "transparent"
                clip: true
                
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }

                // Active Indicator Bar matching Control Center
                Rectangle {
                    id: activeIndicator
                    width: 3
                    height: 24
                    radius: 2
                    color: root.theme.accentPrimary
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

                    // Top Row
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: netDelegate.isExpanded ? -1 : 44
                        spacing: 12

                        // Solid Signal-Strength Fan Icon matching Control Center
                        Text {
                            text: {
                                if (modelData.signal > 80) return "󰤨";
                                if (modelData.signal > 60) return "󰤥";
                                if (modelData.signal > 40) return "󰤢";
                                if (modelData.signal > 0) return "󰤟";
                                return "󰤨";
                            }
                            color: netDelegate.isCurrent ? root.theme.accentPrimary : root.theme.textPrimary
                            font.pixelSize: 16
                            font.family: root.font
                            Layout.alignment: Qt.AlignVCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: modelData.ssid
                            color: netDelegate.isCurrent ? root.theme.textPrimary : root.theme.textSecondary
                            font.pixelSize: 13
                            font.family: root.font
                            font.bold: netDelegate.isCurrent || netDelegate.isExpanded
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        
                        Text {
                            text: "Connected"
                            color: netDelegate.isCurrent ? root.theme.accentPrimary : root.theme.textPrimary
                            font.pixelSize: 13
                            font.family: root.font
                            visible: netDelegate.isCurrent
                            Layout.alignment: Qt.AlignVCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: ""
                            visible: modelData.security && !netDelegate.isCurrent && !netDelegate.isExpanded
                            color: root.theme.textMuted
                            font.pixelSize: 12
                            font.family: root.font
                            Layout.alignment: Qt.AlignVCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    // Expanded Dropdown Area
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
                            visible: modelData.security
                            color: root.theme.bgSurface
                            border.color: pwdInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                            border.width: 1

                            TextInput {
                                id: pwdInput
                                anchors.fill: parent
                                anchors.margins: 10
                                color: root.theme.textPrimary
                                font.pixelSize: 13
                                font.family: root.font
                                echoMode: TextInput.Password
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true

                                Keys.onEscapePressed: {
                                    if (pwdInput.text !== "") {
                                        pwdInput.text = "";
                                    } else {
                                        root.expandedSsid = "";
                                    }
                                }

                                Keys.onReturnPressed: {
                                    connectProc.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid, "password", pwdInput.text];
                                    connectProc.running = true;
                                    root.expandedSsid = "";
                                    pwdInput.text = "";
                                }
                            }

                            Text {
                                text: "Password"
                                color: root.theme.textMuted
                                font.pixelSize: 13
                                font.family: root.font
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

                            // Connect button
                            Rectangle {
                                width: 80
                                height: 32
                                radius: 6
                                color: root.theme.bgHover
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "Connect"
                                    color: root.theme.textPrimary
                                    font.family: root.font
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.security) {
                                            connectProc.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid, "password", pwdInput.text];
                                        } else {
                                            connectProc.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid];
                                        }
                                        connectProc.running = true;
                                        root.expandedSsid = "";
                                        pwdInput.text = "";
                                    }
                                }
                            }

                            // Cancel button
                            Rectangle {
                                width: 80
                                height: 32
                                radius: 6
                                color: root.theme.bgHover
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "Cancel"
                                    color: root.theme.textPrimary
                                    font.family: root.font
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.expandedSsid = "";
                                        pwdInput.text = "";
                                    }
                                }
                            }
                        }
                    }
                }

                // Row Click Handler (covers the top row)
                MouseArea {
                    id: hoverArea
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 44
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (netDelegate.isExpanded) {
                            root.expandedSsid = "";
                        } else if (!netDelegate.isCurrent) {
                            if (modelData.security) {
                                root.expandedSsid = modelData.ssid;
                            } else {
                                connectProc.command = ["nmcli", "dev", "wifi", "connect", modelData.ssid];
                                connectProc.running = true;
                            }
                        }
                    }
                }
            }
        }
        Process { id: connectProc }
    }
}
