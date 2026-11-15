import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."
import "./Wifi"

Item {
    id: root
    property var theme: DefaultTheme {}
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

    // Scan for available Wi-Fi networks
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
                root.networks = nets.sort((a, b) => {
                    if (a.ssid === root.currentSsid) return -1;
                    if (b.ssid === root.currentSsid) return 1;
                    return b.signal - a.signal;
                });
            }
        }
    }

    Process { id: toggleProc }

    Process {
        id: connectProc
        onExited: {
            activeSsidProc.running = true;
            scanProc.running = true;
        }
    }

    Process {
        id: disconnectProc
        running: false
        onExited: {
            root.currentSsid = "";
            activeSsidProc.running = true;
            scanProc.running = true;
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

    function disconnectFromNetwork(ssid) {
        disconnectProc.command = [
            "sh", "-c",
            'IFACE=$(nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | grep ":wifi:connected" | head -n1 | cut -d: -f1); [ -n "$IFACE" ] && nmcli dev disconnect "$IFACE"; [ -n "$1" ] && nmcli con down id "$1" 2>/dev/null || true',
            "--",
            ssid || root.currentSsid
        ];
        disconnectProc.running = true;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        WifiHeaderBar {
            theme: root.theme
            font: root.font
            wifiEnabled: root.wifiEnabled
            onEnableRequested: {
                toggleProc.command = ["nmcli", "radio", "wifi", "on"];
                toggleProc.running = true;
                root.wifiEnabled = true;
                activeSsidProc.running = true;
                scanProc.running = true;
            }
            onDisableRequested: {
                toggleProc.command = ["nmcli", "radio", "wifi", "off"];
                toggleProc.running = true;
                root.wifiEnabled = false;
                root.networks = [];
                root.expandedSsid = "";
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.networks
            clip: true
            spacing: 4

            delegate: WifiNetworkRow {
                required property var modelData
                width: ListView.view.width
                theme: root.theme
                font: root.font
                networkData: modelData
                isCurrent: modelData.ssid === root.currentSsid
                isExpanded: root.expandedSsid === modelData.ssid
                disconnecting: disconnectProc.running

                onToggleExpandRequested: (ssid, isCurr, hasSecurity) => {
                    if (root.expandedSsid === ssid) {
                        root.expandedSsid = "";
                    } else {
                        root.expandedSsid = ssid;
                        if (!isCurr && !hasSecurity) {
                            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
                            connectProc.running = true;
                        }
                    }
                }

                onConnectRequested: (ssid, password, hasSecurity) => {
                    if (hasSecurity) {
                        connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
                    } else {
                        connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
                    }
                    connectProc.running = true;
                    root.expandedSsid = "";
                }

                onDisconnectRequested: ssid => {
                    root.disconnectFromNetwork(ssid);
                    root.expandedSsid = "";
                }

                onCollapseRequested: root.expandedSsid = ""
            }
        }
    }
}
