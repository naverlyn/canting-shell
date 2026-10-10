import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    property var theme
    property string font

    property var devices: []
    property bool btEnabled: false
    property bool btAvailable: true
    property string expandedMac: ""

    Process {
        id: btStateProc
        command: ["sh", "-c", "if ! command -v bluetoothctl >/dev/null 2>&1 || [ -z \"$(ls -A /sys/class/bluetooth 2>/dev/null)\" ]; then echo 'none'; elif bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then echo 'on'; else echo 'off'; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const res = text.trim();
                if (res === "none") {
                    root.btAvailable = false;
                    root.btEnabled = false;
                } else {
                    root.btAvailable = true;
                    root.btEnabled = (res === "on");
                }
            }
        }
    }

    Process {
        id: btListProc
        command: ["bluetoothctl", "devices"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const res = [];
                for (const line of lines) {
                    if (!line) continue;
                    const parts = line.split(" ");
                    if (parts.length >= 3) {
                        res.push({
                            mac: parts[1],
                            name: parts.slice(2).join(" ")
                        });
                    }
                }
                root.devices = res;
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: {
            btStateProc.running = true;
            if (root.btAvailable && root.btEnabled) btListProc.running = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Bluetooth Devices"
                font.family: root.font
                font.pixelSize: 15
                font.bold: true
                color: root.theme.accentPrimary
                Layout.fillWidth: true
            }

            // Segmented On/Off Toggle
            Rectangle {
                width: 76
                height: 26
                radius: 6
                color: root.theme.bgSelected
                border.color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                opacity: root.btAvailable ? 1.0 : 0.4
                enabled: root.btAvailable

                Row {
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 0

                    // "On" segment
                    Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        radius: 4
                        color: root.btEnabled ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.05)) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "On"
                            color: root.btEnabled ? root.theme.accentPrimary : root.theme.textMuted
                            font.pixelSize: 11
                            font.family: root.font
                            font.bold: root.btEnabled
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.btEnabled && root.btAvailable) {
                                    btToggleProc.command = ["bluetoothctl", "power", "on"];
                                    btToggleProc.running = true;
                                    root.btEnabled = true;
                                    btListProc.running = true;
                                }
                            }
                        }
                    }

                    // "Off" segment
                    Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        radius: 4
                        color: !root.btEnabled ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.05)) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Off"
                            color: !root.btEnabled ? root.theme.textPrimary : root.theme.textMuted
                            font.pixelSize: 11
                            font.family: root.font
                            font.bold: !root.btEnabled
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.btEnabled && root.btAvailable) {
                                    btToggleProc.command = ["bluetoothctl", "power", "off"];
                                    btToggleProc.running = true;
                                    root.btEnabled = false;
                                    root.devices = [];
                                    root.expandedMac = "";
                                }
                            }
                        }
                    }
                }
                Process { id: btToggleProc }
            }
        }

        // Main List or Empty / Unavailable State Card
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 1. Devices ListView
            ListView {
                anchors.fill: parent
                model: root.devices
                clip: true
                spacing: 4
                visible: root.btAvailable && root.btEnabled && root.devices.length > 0
                
                delegate: Rectangle {
                    width: ListView.view.width
                    height: root.expandedMac === modelData.mac ? 96 : 44
                    radius: 8
                    color: (root.expandedMac === modelData.mac || itemMouse.containsMouse) ? root.theme.bgSelected : "transparent"
                    clip: true
                    
                    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        // Top row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            Text {
                                text: "󰂯"
                                font.family: root.font
                                font.pixelSize: 16
                                color: root.expandedMac === modelData.mac ? root.theme.accentPrimary : root.theme.textPrimary
                            }

                            Text {
                                text: modelData.name
                                font.family: root.font
                                font.pixelSize: 14
                                font.bold: root.expandedMac === modelData.mac
                                color: root.expandedMac === modelData.mac ? root.theme.accentPrimary : root.theme.textPrimary
                                Layout.fillWidth: true
                            }
                            
                            Text {
                                text: modelData.mac
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.theme.textMuted
                            }
                        }

                        // Expanded area (Buttons)
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.expandedMac === modelData.mac

                            RowLayout {
                                anchors.fill: parent
                                spacing: 8
                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 80
                                    height: 30
                                    radius: 6
                                    color: root.theme.bgSurface
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Connect"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        color: root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            btActionProc.command = ["bluetoothctl", "connect", modelData.mac];
                                            btActionProc.running = true;
                                            root.expandedMac = "";
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 80
                                    height: 30
                                    radius: 6
                                    color: root.theme.bgSurface
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Disconnect"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        color: root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            btActionProc.command = ["bluetoothctl", "disconnect", modelData.mac];
                                            btActionProc.running = true;
                                            root.expandedMac = "";
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    width: 80
                                    height: 30
                                    radius: 6
                                    color: root.theme.bgSurface
                                    border.color: Qt.rgba(0.9, 0.3, 0.3, 0.5)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Forget"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        color: root.theme.accentRed ?? "#f7768e"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            btActionProc.command = ["bluetoothctl", "remove", modelData.mac];
                                            btActionProc.running = true;
                                            root.expandedMac = "";
                                            btListProc.running = true;
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    width: 80
                                    height: 30
                                    radius: 6
                                    color: root.theme.bgSurface
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Cancel"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        color: root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.expandedMac = ""
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
                        enabled: root.expandedMac !== modelData.mac
                        onClicked: root.expandedMac = modelData.mac
                    }
                }
            }

            // 2. Centered Placeholder / Empty State (Matching Control Center empty notification style)
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                visible: !root.btAvailable || !root.btEnabled || root.devices.length === 0

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 54
                    height: 54
                    radius: 27
                    color: root.theme.bgSelected

                    Text {
                        anchors.centerIn: parent
                        text: !root.btAvailable ? "󰂲" : (!root.btEnabled ? "󰂲" : "󰂯")
                        font.family: root.font
                        font.pixelSize: 26
                        color: root.theme.textMuted
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: !root.btAvailable 
                        ? "No Bluetooth Adapter Found" 
                        : (!root.btEnabled ? "Bluetooth is Disabled" : "No Paired Devices Found")
                    font.family: root.font
                    font.pixelSize: 14
                    font.bold: true
                    color: root.theme.textSecondary
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: !root.btAvailable 
                        ? "Plug in a Bluetooth dongle or enable your wireless card."
                        : (!root.btEnabled ? "Turn on Bluetooth to scan and connect devices." : "Click scan to search for nearby Bluetooth devices.")
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textMuted
                }
            }
        }
        Process { id: btActionProc }
    }
}
