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
    property string busyMac: ""
    property string errorMessage: ""

    function refreshAll() {
        if (!btStateProc.running) btStateProc.running = true;
        if (root.btAvailable && root.btEnabled && !btListProc.running) btListProc.running = true;
    }

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
                    if (root.btEnabled && !btListProc.running) {
                        btListProc.running = true;
                    }
                }
            }
        }
    }

    Process {
        id: btListProc
        command: [
            "sh", "-c",
            "conn_macs=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}'); " +
            "pair_macs=$(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}'); " +
            "bluetoothctl devices 2>/dev/null | while read -r _ mac name; do " +
            "[ -z \"$mac\" ] && continue; " +
            "c='0'; for cm in $conn_macs; do [ \"$cm\" = \"$mac\" ] && c='1' && break; done; " +
            "p='0'; for pm in $pair_macs; do [ \"$pm\" = \"$mac\" ] && p='1' && break; done; " +
            "printf 'DEV\\t%s\\t%s\\t%s\\t%s\\n' \"$c\" \"$p\" \"$mac\" \"$name\"; " +
            "done"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const res = [];
                for (const line of lines) {
                    if (!line.startsWith("DEV\t")) continue;
                    const parts = line.split("\t");
                    if (parts.length >= 4) {
                        const c = parts[1] === "1";
                        const p = parts[2] === "1";
                        const mac = parts[3].trim();
                        const name = parts.slice(4).join("\t").trim() || mac;
                        const macDashed = mac.replace(/:/g, "-").toLowerCase();
                        const isUnnamed = !name || name.toLowerCase() === macDashed || name.toLowerCase() === mac.toLowerCase();
                        res.push({
                            mac: mac,
                            name: isUnnamed ? "Unknown Device" : name,
                            connected: c,
                            paired: p,
                            unnamed: isUnnamed
                        });
                    }
                }
                res.sort((a, b) => {
                    if (a.connected !== b.connected) return a.connected ? -1 : 1;
                    if (a.paired !== b.paired) return a.paired ? -1 : 1;
                    if (a.unnamed !== b.unnamed) return a.unnamed ? 1 : -1;
                    return a.name.localeCompare(b.name);
                });
                root.devices = res;
            }
        }
    }

    Process {
        id: btToggleProc
        property string lastOutput: ""
        stdout: StdioCollector {
            onStreamFinished: btToggleProc.lastOutput = text.trim()
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.errorMessage = btToggleProc.lastOutput || "Failed to toggle Bluetooth power.";
            } else {
                root.errorMessage = "";
            }
            btStateProc.running = true;
        }
    }

    Process {
        id: btScanProc
        command: ["sh", "-c", "rfkill unblock bluetooth 2>/dev/null || true; bluetoothctl --timeout 8 scan on >/dev/null 2>&1"]
        running: false
        onExited: {
            if (root.btAvailable && root.btEnabled && !btListProc.running) {
                btListProc.running = true;
            }
        }
    }

    Process {
        id: btActionProc
        property string lastOutput: ""
        stdout: StdioCollector {
            onStreamFinished: btActionProc.lastOutput = text.trim()
        }
        onExited: (exitCode) => {
            root.busyMac = "";
            if (exitCode !== 0) {
                const lines = btActionProc.lastOutput.split("\n").filter(l => l.trim() !== "");
                root.errorMessage = lines.length > 0 ? lines[lines.length - 1].trim() : "Bluetooth action failed.";
            } else {
                root.errorMessage = "";
                root.expandedMac = "";
            }
            root.refreshAll();
        }
    }

    Timer {
        interval: btScanProc.running ? 2000 : 5000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: root.refreshAll()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        BluetoothHeaderBar {
            theme: root.theme
            font: root.font
            btEnabled: root.btEnabled
            btAvailable: root.btAvailable
            scanning: btScanProc.running
            onEnableRequested: {
                if (btToggleProc.running) return;
                root.errorMessage = "";
                btToggleProc.lastOutput = "";
                btToggleProc.command = ["sh", "-c", "rfkill unblock bluetooth 2>/dev/null || true; bluetoothctl power on 2>&1"];
                btToggleProc.running = true;
            }
            onDisableRequested: {
                if (btToggleProc.running) return;
                root.errorMessage = "";
                btToggleProc.lastOutput = "";
                btToggleProc.command = ["bluetoothctl", "power", "off"];
                btToggleProc.running = true;
                root.btEnabled = false;
                root.devices = [];
                root.expandedMac = "";
            }
            onScanRequested: {
                if (!btScanProc.running && root.btAvailable && root.btEnabled) {
                    root.errorMessage = "";
                    btScanProc.running = true;
                }
            }
        }

        Rectangle {
            visible: root.errorMessage !== ""
            Layout.fillWidth: true
            height: errorText.implicitHeight + 16
            radius: 8
            color: Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.12)
            border.color: Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.45)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Text {
                    id: errorText
                    Layout.fillWidth: true
                    text: root.errorMessage
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.accentRed
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: "✕"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.accentRed
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.errorMessage = ""
                    }
                }
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
                    busy: root.busyMac === modelData.mac
                    onExpandRequested: mac => root.expandedMac = mac
                    onConnectRequested: mac => {
                        if (btActionProc.running) return;
                        root.errorMessage = "";
                        root.busyMac = mac;
                        btActionProc.lastOutput = "";
                        btActionProc.command = [
                            "python3",
                            Qt.resolvedUrl("../scripts/bt_connect.py").toString().replace("file://", ""),
                            mac
                        ];
                        btActionProc.running = true;
                    }
                    onDisconnectRequested: mac => {
                        if (btActionProc.running) return;
                        root.errorMessage = "";
                        root.busyMac = mac;
                        btActionProc.lastOutput = "";
                        btActionProc.command = ["sh", "-c", "bluetoothctl disconnect \"$1\" 2>&1", "--", mac];
                        btActionProc.running = true;
                    }
                    onForgetRequested: mac => {
                        if (btActionProc.running) return;
                        root.errorMessage = "";
                        root.busyMac = mac;
                        btActionProc.lastOutput = "";
                        btActionProc.command = ["sh", "-c", "bluetoothctl remove \"$1\" 2>&1", "--", mac];
                        btActionProc.running = true;
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
