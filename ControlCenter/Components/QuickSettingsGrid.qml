import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

GridLayout {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"

    // Toggle states
    property bool wifiEnabled: true
    property string currentSsid: ""
    property bool btEnabled: false
    property bool btAvailable: false
    property bool dndEnabled: false
    property bool airplaneEnabled: false

    signal openWifiRequested()

    width: parent ? parent.width : 300
    columns: 2
    rowSpacing: 8
    columnSpacing: 8

    // Processes
    Process {
        id: wifiProc
        running: false
        onExited: {
            wifiStatusProc.running = true;
            activeSsidProc.running = true;
        }
    }
    Process { id: airplaneProc; running: false }

    Process {
        id: wifiStatusProc
        command: ["nmcli", "radio", "wifi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = (text.trim() === "enabled");
            }
        }
    }

    Process {
        id: activeSsidProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.currentSsid = text.trim()
        }
    }

    Process {
        id: btProc
        running: false
        onExited: btStatusProc.running = true
    }

    Process {
        id: btStatusProc
        command: [
            "sh", "-c",
            "if [ -z \"$(ls -A /sys/class/bluetooth 2>/dev/null)\" ]; then echo 'none'; elif bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then echo 'on'; else echo 'off'; fi"
        ]
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
        id: dndProc
        command: ["swaync-client", "-d"]
        running: false
    }

    Process {
        id: dndStatusProc
        command: ["swaync-client", "-D"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.dndEnabled = (text.trim() === "true");
            }
        }
    }

    Process {
        id: airplaneStatusProc
        command: ["sh", "-c", "rfkill list wifi | grep -o 'Soft blocked: yes'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const blocked = text.trim() !== "";
                root.airplaneEnabled = blocked;
                if (blocked) root.wifiEnabled = false;
            }
        }
    }

    function setWifi(enabled) {
        if (root.wifiEnabled === enabled) return;
        root.wifiEnabled = enabled;
        if (root.wifiEnabled) {
            root.airplaneEnabled = false;
            activeSsidProc.running = true;
        } else {
            root.currentSsid = "";
        }
        wifiProc.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "on" : "off"];
        wifiProc.running = true;
    }

    function toggleWifi() {
        setWifi(!root.wifiEnabled);
    }

    function toggleBt() {
        if (!root.btAvailable) {
            btStatusProc.running = true;
            return;
        }
        const targetState = !root.btEnabled;
        btProc.command = ["bluetoothctl", "power", targetState ? "on" : "off"];
        btProc.running = true;
    }

    function togglednd() {
        root.dndEnabled = !root.dndEnabled;
        dndProc.running = true;
    }

    function toggleAirplane() {
        const notifIcon = "$HOME/.config/swaync/images/ja.png";
        if (root.airplaneEnabled) {
            root.airplaneEnabled = false;
            root.wifiEnabled = true;
            airplaneProc.command = [
                "sh", "-c",
                `rfkill unblock wifi && notify-send -u low -i "${notifIcon}" " Airplane" " mode: OFF"`
            ];
        } else {
            root.airplaneEnabled = true;
            root.wifiEnabled = false;
            root.currentSsid = "";
            airplaneProc.command = [
                "sh", "-c",
                `rfkill block wifi && notify-send -u low -i "${notifIcon}" " Airplane" " mode: ON"`
            ];
        }
        airplaneProc.running = true;
    }

    function refresh() {
        wifiStatusProc.running = true;
        activeSsidProc.running = true;
        btStatusProc.running = true;
        dndStatusProc.running = true;
        airplaneStatusProc.running = true;
    }

    // Wi-Fi
    Rectangle {
        Layout.fillWidth: true
        height: 40
        radius: 8
        color: root.wifiEnabled 
            ? root.theme.accentPrimary 
            : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
        border.color: root.wifiEnabled ? "transparent" : root.theme.bgBorder
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: root.wifiEnabled ? "󰖩" : "󰖪"
                font.family: root.font
                font.pixelSize: 16
                color: root.wifiEnabled ? root.theme.bgBase : root.theme.textPrimary
            }
            Text {
                text: (root.wifiEnabled && root.currentSsid !== "") ? root.currentSsid : "Wi-Fi"
                font.family: root.font
                font.pixelSize: 12
                color: root.wifiEnabled ? root.theme.bgBase : root.theme.textPrimary
                elide: Text.ElideRight
                Layout.maximumWidth: 100
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    root.toggleWifi();
                } else if (mouse.button === Qt.LeftButton) {
                    root.openWifiRequested();
                }
            }
        }
    }

    // Bluetooth
    Rectangle {
        Layout.fillWidth: true
        height: 40
        radius: 8
        opacity: root.btAvailable ? 1.0 : 0.55
        color: (root.btAvailable && root.btEnabled) 
            ? root.theme.accentPrimary 
            : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
        border.color: (root.btAvailable && root.btEnabled) ? "transparent" : root.theme.bgBorder
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: (root.btAvailable && root.btEnabled) ? "󰂯" : "󰂲"
                font.family: root.font
                font.pixelSize: 16
                color: (root.btAvailable && root.btEnabled) ? root.theme.bgBase : root.theme.textPrimary
            }
            Text {
                text: root.btAvailable ? "Bluetooth" : "No Bluetooth"
                font.family: root.font
                font.pixelSize: 12
                color: (root.btAvailable && root.btEnabled) ? root.theme.bgBase : root.theme.textPrimary
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: root.btAvailable ? Qt.PointingHandCursor : Qt.ForbiddenCursor
            onClicked: root.toggleBt()
        }
    }

    // Airplane Mode
    Rectangle {
        Layout.fillWidth: true
        height: 40
        radius: 8
        color: root.airplaneEnabled 
            ? root.theme.accentPrimary 
            : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
        border.color: root.airplaneEnabled ? "transparent" : root.theme.bgBorder
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: root.airplaneEnabled ? "󰀝" : "󰀞"
                font.family: root.font
                font.pixelSize: 16
                color: root.airplaneEnabled ? root.theme.bgBase : root.theme.textPrimary
            }
            Text {
                text: "Airplane"
                font.family: root.font
                font.pixelSize: 12
                color: root.airplaneEnabled ? root.theme.bgBase : root.theme.textPrimary
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleAirplane()
        }
    }

    // Do Not Disturb (DND)
    Rectangle {
        Layout.fillWidth: true
        height: 40
        radius: 8
        color: root.dndEnabled 
            ? root.theme.accentPrimary 
            : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
        border.color: root.dndEnabled ? "transparent" : root.theme.bgBorder
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: root.dndEnabled ? "󰂛" : "󰂚"
                font.family: root.font
                font.pixelSize: 16
                color: root.dndEnabled ? root.theme.bgBase : root.theme.textPrimary
            }
            Text {
                text: "DND"
                font.family: root.font
                font.pixelSize: 12
                color: root.dndEnabled ? root.theme.bgBase : root.theme.textPrimary
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.togglednd()
        }
    }
}
