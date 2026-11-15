import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."
import "./Bluetooth"

Item {
    id: root
    property var theme: DefaultTheme {}
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

    Process { id: btToggleProc }
    Process { id: btActionProc }

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

        BluetoothHeaderBar {
            theme: root.theme
            font: root.font
            btEnabled: root.btEnabled
            btAvailable: root.btAvailable
            onEnableRequested: {
                btToggleProc.command = ["bluetoothctl", "power", "on"];
                btToggleProc.running = true;
                root.btEnabled = true;
                btListProc.running = true;
            }
            onDisableRequested: {
                btToggleProc.command = ["bluetoothctl", "power", "off"];
                btToggleProc.running = true;
                root.btEnabled = false;
                root.devices = [];
                root.expandedMac = "";
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                anchors.fill: parent
                model: root.devices
                clip: true
                spacing: 4
                visible: root.btAvailable && root.btEnabled && root.devices.length > 0

                delegate: BluetoothDeviceRow {
                    required property var modelData
                    width: ListView.view.width
                    theme: root.theme
                    font: root.font
                    deviceData: modelData
                    isExpanded: root.expandedMac === modelData.mac
                    onExpandRequested: mac => root.expandedMac = mac
                    onConnectRequested: mac => {
                        btActionProc.command = ["bluetoothctl", "connect", mac];
                        btActionProc.running = true;
                        root.expandedMac = "";
                    }
                    onDisconnectRequested: mac => {
                        btActionProc.command = ["bluetoothctl", "disconnect", mac];
                        btActionProc.running = true;
                        root.expandedMac = "";
                    }
                    onForgetRequested: mac => {
                        btActionProc.command = ["bluetoothctl", "remove", mac];
                        btActionProc.running = true;
                        root.expandedMac = "";
                        btListProc.running = true;
                    }
                    onCollapseRequested: root.expandedMac = ""
                }
            }

            BluetoothEmptyState {
                anchors.centerIn: parent
                visible: !root.btAvailable || !root.btEnabled || root.devices.length === 0
                theme: root.theme
                font: root.font
                btAvailable: root.btAvailable
                btEnabled: root.btEnabled
            }
        }
    }
}
