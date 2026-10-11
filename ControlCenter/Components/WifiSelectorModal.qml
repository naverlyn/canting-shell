import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"

    property bool wifiEnabled: true
    property string currentSsid: ""
    property var networkList: []
    property string selectedSsid: ""
    property bool selectedSsidSecured: false

    // Track state and selection
    property string expandedSsid: ""
    property int selectedIndex: 0

    signal setWifiRequested(bool enabled)
    signal toggleWifiRequested()
    signal networkConnected(string ssid)
    signal networkDisconnected(string ssid)

    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-wifi-selector"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Reset state and grab keyboard focus when opened
    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0;
            expandedSsid = "";
            scanWifi();
            networkListView.forceActiveFocus();
        }
    }

    onWifiEnabledChanged: {
        if (wifiEnabled) {
            scanDelayTimer.restart();
        } else {
            root.networkList = [];
            root.expandedSsid = "";
        }
    }

    Timer {
        id: scanDelayTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (root.wifiEnabled) {
                scanWifiProc.running = true;
            }
        }
    }

    Timer {
        id: periodicScanTimer
        interval: 8000
        repeat: true
        running: root.visible && root.wifiEnabled
        onTriggered: {
            if (!scanWifiProc.running) {
                scanWifiProc.running = true;
            }
        }
    }

    // Scan for available Wi-Fi networks
    Process {
        id: scanWifiProc
        command: ["nmcli", "-t", "-f", "ssid,signal,security", "dev", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');
                const nets = [];
                const seen = new Set();
                for (const line of lines) {
                    if (!line) continue;
                    const parts = line.split(':');
                    if (parts.length >= 3) {
                        const ssid = parts[0];
                        if (!ssid || seen.has(ssid)) continue;
                        seen.add(ssid);
                        nets.push({ ssid: ssid, signal: parseInt(parts[1]), security: parts[2] !== "" });
                    }
                }
                // Sort by signal strength, but always put connected at the top
                root.networkList = nets.sort((a, b) => {
                    if (a.ssid === root.currentSsid) return -1;
                    if (b.ssid === root.currentSsid) return 1;
                    return b.signal - a.signal;
                });
            }
        }
    }

    // Fetch the currently active SSID
    Process {
        id: activeSsidProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.currentSsid = text.trim()
        }
    }

    // Connect to a selected network
    Process {
        id: connectWifiProc
        running: false
        onExited: {
            activeSsidProc.running = true;
            root.networkConnected(root.selectedSsid);
            root.visible = false;
        }
    }

    // Disconnect from network
    Process {
        id: disconnectWifiProc
        running: false
        onExited: {
            root.currentSsid = "";
            activeSsidProc.running = true;
            root.networkDisconnected(root.selectedSsid);
            scanWifi();
        }
    }

    function scanWifi() {
        if (root.wifiEnabled) {
            scanWifiProc.running = true;
        }
    }

    function connectToNetwork(password) {
        if (!selectedSsidSecured || password === "") {
            connectWifiProc.command = ["nmcli", "dev", "wifi", "connect", selectedSsid];
        } else {
            connectWifiProc.command = ["nmcli", "dev", "wifi", "connect", selectedSsid, "password", password];
        }
        connectWifiProc.running = true;
    }

    function disconnectFromNetwork(ssid) {
        root.selectedSsid = ssid || root.currentSsid;
        disconnectWifiProc.command = [
            "sh", "-c",
            'IFACE=$(nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | grep ":wifi:connected" | head -n1 | cut -d: -f1); [ -n "$IFACE" ] && nmcli dev disconnect "$IFACE"; [ -n "$1" ] && nmcli con down id "$1" 2>/dev/null || true',
            "--",
            root.selectedSsid
        ];
        disconnectWifiProc.running = true;
    }

    // Dark overlay backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false

        Rectangle {
            anchors.fill: parent
            color: root.theme.bgOverlay
        }
    }

    // Centered selection box
    Rectangle {
        id: wifiMainRect
        anchors.centerIn: parent
        width: 480
        height: 540
        radius: 16
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1

        // Keyboard navigation
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Down) {
                event.accepted = true;
                root.selectedIndex = Math.min(root.selectedIndex + 1, networkListView.count - 1);
                networkListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
            } else if (event.key === Qt.Key_Up) {
                event.accepted = true;
                root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                networkListView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true;
                if (root.selectedIndex >= 0 && root.selectedIndex < root.networkList.length) {
                    const selectedNet = root.networkList[root.selectedIndex];
                
                    if (root.expandedSsid === selectedNet.ssid) {
                        root.expandedSsid = "";
                    } else {
                        root.expandedSsid = selectedNet.ssid;
                        root.selectedSsid = selectedNet.ssid;
                        root.selectedSsidSecured = selectedNet.security;
                        if (selectedNet.ssid !== root.currentSsid && !selectedNet.security) {
                            root.connectToNetwork("");
                        }
                    }
                }
            } else if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                root.visible = false;
            }
        }

        // Slide in from right to left animation
        transform: Translate {
            x: root.visible ? 0 : 40
            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        }
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header with Title and Toggle Switch
            RowLayout {
                Layout.fillWidth: true
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Text {
                        text: "Available Networks"
                        color: root.theme.accentPrimary
                        font.pixelSize: 14
                        font.family: root.font
                        font.bold: true
                    }
                }

                Item { Layout.fillWidth: true }

                // Top Right Wi-Fi Toggle
                Rectangle {
                    width: 84
                    height: 26
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.05)
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 0

                        // "On" segment
                        Rectangle {
                            width: parent.width / 2
                            height: parent.height
                            radius: 4
                            color: root.wifiEnabled ? root.theme.bgSelected : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "On"
                                color: root.wifiEnabled 
                                    ? root.theme.accentPrimary 
                                    : root.theme.textMuted
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
                                        root.setWifiRequested(true);
                                    }
                                }
                            }
                        }

                        // "Off" segment
                        Rectangle {
                            width: parent.width / 2
                            height: parent.height
                            radius: 4
                            color: !root.wifiEnabled ? root.theme.bgSelected : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Off"
                                color: !root.wifiEnabled 
                                    ? root.theme.textPrimary 
                                    : root.theme.textMuted
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
                                        root.setWifiRequested(false);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Wi-Fi Network List
            ListView {
                id: networkListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.networkList
                clip: true
                spacing: 4
                focus: true 

                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic } }
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
                displaced: Transition { NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic } }

                delegate: Rectangle {
                    id: networkDelegate
                    required property var modelData
                    required property int index

                    width: networkListView.width
                    readonly property bool isCurrent: modelData.ssid === root.currentSsid
                    readonly property bool isExpanded: root.expandedSsid === modelData.ssid
                    readonly property bool isSelected: root.selectedIndex === index

                    height: isExpanded ? ((modelData.security && !isCurrent) ? 140 : 100) : 44
                    radius: 8
                    color: (isSelected || hoverArea.containsMouse || isExpanded) 
                        ? root.theme.bgSelected 
                        : "transparent"
                    clip: true
                    
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    onIsExpandedChanged: {
                        if (isExpanded && modelData.security && !isCurrent) {
                            pwdInput.forceActiveFocus();
                        } else if (!isExpanded) {
                            networkListView.forceActiveFocus(); 
                        }
                    }

                    Rectangle {
                        width: 3
                        height: 24
                        radius: 2
                        color: root.theme.accentPrimary
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        visible: networkDelegate.isSelected
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: isExpanded ? 14 : 0
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        // Top Row
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: isExpanded ? -1 : 44
                            spacing: 12

                            Text {
                                text: {
                                    if (modelData.signal > 80) return "󰤨";
                                    if (modelData.signal > 60) return "󰤥";
                                    if (modelData.signal > 40) return "󰤢";
                                    return "󰤟";
                                }
                                color: networkDelegate.isSelected 
                                    ? root.theme.accentPrimary 
                                    : root.theme.textPrimary
                                font.pixelSize: 16
                                font.family: root.font
                            }

                            Text {
                                text: modelData.ssid
                                color: networkDelegate.isSelected 
                                    ? root.theme.textPrimary 
                                    : root.theme.textSecondary
                                font.pixelSize: 13
                                font.family: root.font
                                font.bold: networkDelegate.isSelected
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            
                            Text {
                                text: "Connected"
                                color: root.theme.accentPrimary
                                font.pixelSize: 13
                                font.family: root.font
                                visible: networkDelegate.isCurrent
                            }

                            Text {
                                text: ""
                                visible: modelData.security && !networkDelegate.isCurrent
                                color: root.theme.textMuted
                                font.pixelSize: 12
                                font.family: root.font
                            }
                        }

                        // Expanded Dropdown Area
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: networkDelegate.isExpanded
                            opacity: networkDelegate.isExpanded ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: 6
                                visible: modelData.security && !networkDelegate.isCurrent
                                color: root.theme.bgSurface
                                border.color: pwdInput.activeFocus 
                                    ? root.theme.accentPrimary 
                                    : root.theme.bgBorder
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
                                    
                                    Keys.onEscapePressed: {
                                        if (pwdInput.text !== "") {
                                            pwdInput.text = "";
                                        } else {
                                            root.expandedSsid = "";
                                            networkListView.forceActiveFocus();
                                        }
                                    }
                                    
                                    Keys.onReturnPressed: {
                                        root.selectedSsid = modelData.ssid;
                                        root.selectedSsidSecured = modelData.security;
                                        root.connectToNetwork(pwdInput.text);
                                        root.expandedSsid = "";
                                        pwdInput.text = "";
                                        networkListView.forceActiveFocus();
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

                                // Connect button (when not connected)
                                Rectangle {
                                    id: connectBtnRect
                                    visible: !networkDelegate.isCurrent
                                    width: 80
                                    height: 32
                                    radius: 6
                                    color: connectBtnMouse.containsMouse
                                        ? root.theme.accentCyan
                                        : root.theme.accentPrimary
                                    border.color: "transparent"
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Connect"
                                        color: root.theme.bgBase
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: connectBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectedSsid = modelData.ssid;
                                            root.selectedSsidSecured = modelData.security;
                                            root.connectToNetwork(pwdInput.text);
                                            root.expandedSsid = "";
                                            pwdInput.text = "";
                                        }
                                    }
                                }

                                // Disconnect button (when connected)
                                Rectangle {
                                    visible: networkDelegate.isCurrent
                                    width: 90
                                    height: 32
                                    radius: 6
                                    color: disconnectBtnMouse.containsMouse
                                        ? root.theme.accentRed
                                        : Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.15)
                                    border.color: root.theme.accentRed
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: disconnectWifiProc.running ? "Disconnecting..." : "Disconnect"
                                        color: disconnectBtnMouse.containsMouse
                                            ? root.theme.bgBase
                                            : root.theme.accentRed
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        id: disconnectBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !disconnectWifiProc.running
                                        onClicked: {
                                            root.disconnectFromNetwork(modelData.ssid);
                                            root.expandedSsid = "";
                                        }
                                    }
                                }

                                // Cancel button
                                Rectangle {
                                    width: 80
                                    height: 32
                                    radius: 6
                                    color: root.theme.bgSurface
                                    border.color: root.theme.bgBorder
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

                    MouseArea {
                        id: hoverArea
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 44
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = networkDelegate.index
                        onClicked: {
                            networkListView.forceActiveFocus();
                            if (networkDelegate.isExpanded) {
                                root.expandedSsid = "";
                            } else {
                                root.expandedSsid = modelData.ssid;
                                root.selectedSsid = modelData.ssid;
                                root.selectedSsidSecured = modelData.security;
                                if (!networkDelegate.isCurrent && !modelData.security) {
                                    root.connectToNetwork("");
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Scanning for networks..."
                    color: root.theme.textMuted
                    font.pixelSize: 13
                    font.family: root.font
                    visible: scanWifiProc.running && root.wifiEnabled
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "Wi-Fi is turned off"
                    color: root.theme.textMuted
                    font.pixelSize: 13
                    font.family: root.font
                    visible: !root.wifiEnabled
                }
            }

            // Footer Hints
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 16

                Row {
                    spacing: 4
                    Rectangle {
                        width: hintUp.width + 8; height: 18; radius: 4
                        color: root.theme.bgSurface
                        Text { 
                            id: hintUp; anchors.centerIn: parent; text: "↑↓"
                            color: root.theme.textMuted
                            font.pixelSize: 10; font.family: root.font 
                        }
                    }
                    Text { 
                        text: "navigate"; 
                        color: root.theme.textMuted
                        font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter 
                    }
                }

                Row {
                    spacing: 4
                    Rectangle {
                        width: hintEnter.width + 8; height: 18; radius: 4
                        color: root.theme.bgSurface
                        Text { 
                            id: hintEnter; anchors.centerIn: parent; text: "⏎"
                            color: root.theme.textMuted
                            font.pixelSize: 10; font.family: root.font 
                        }
                    }
                    Text { 
                        text: "select"
                        color: root.theme.textMuted
                        font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter 
                    }
                }

                Row {
                    spacing: 4
                    Rectangle {
                        width: hintEsc.width + 8; height: 18; radius: 4
                        color: root.theme.bgSurface
                        Text { 
                            id: hintEsc; anchors.centerIn: parent; text: "esc"
                            color: root.theme.textMuted
                            font.pixelSize: 10; font.family: root.font 
                        }
                    }
                    Text { 
                        text: "close"
                        color: root.theme.textMuted
                        font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter 
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
