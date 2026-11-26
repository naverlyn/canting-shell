import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."
import "./Bluetooth"
import "../../ThemeSwitcher"
import "./Common"

Item {
    id: root
    property var theme: Theme
    property string font

    property var devices: []
    property bool btEnabled: false
    property bool btAvailable: true
    property string expandedMac: ""
    property string busyMac: ""
    property string errorMessage: ""
    property bool managePairedExpanded: false
    property bool confirmForgetAll: false

    readonly property var connectedDevices: {
        const list = [];
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected) list.push(devices[i]);
        }
        return list;
    }

    readonly property var pairedDevices: {
        const list = [];
        for (let i = 0; i < devices.length; i++) {
            if (!devices[i].connected && devices[i].paired) list.push(devices[i]);
        }
        return list;
    }

    readonly property var availableDevices: {
        const list = [];
        for (let i = 0; i < devices.length; i++) {
            const d = devices[i];
            if (!d.connected && !d.paired && !d.unnamed && d.mac !== "00:00:00:00:00:00") {
                list.push(d);
            }
        }
        return list;
    }

    readonly property var allPairedDevices: {
        const list = [];
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].paired || devices[i].connected) list.push(devices[i]);
        }
        return list;
    }

    Timer {
        id: forgetAllResetTimer
        interval: 4000
        repeat: false
        onTriggered: root.confirmForgetAll = false
    }

    function refreshAll() {
        if (!btStateProc.running) btStateProc.running = true;
        if (root.btAvailable && root.btEnabled && !btListProc.running) btListProc.running = true;
    }

    function connectDevice(mac) {
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

    function disconnectDevice(mac) {
        if (btActionProc.running) return;
        root.errorMessage = "";
        root.busyMac = mac;
        btActionProc.lastOutput = "";
        btActionProc.command = ["sh", "-c", "bluetoothctl disconnect \"$1\" 2>&1", "--", mac];
        btActionProc.running = true;
    }

    function forgetDevice(mac) {
        if (btActionProc.running) return;
        root.errorMessage = "";
        root.busyMac = mac;
        btActionProc.lastOutput = "";
        btActionProc.command = ["sh", "-c", "bluetoothctl remove \"$1\" 2>&1", "--", mac];
        btActionProc.running = true;
    }

    function forgetAllPaired() {
        if (btActionProc.running) return;
        root.errorMessage = "";
        root.busyMac = "__ALL__";
        btActionProc.lastOutput = "";
        btActionProc.command = [
            "sh", "-c",
            "bluetoothctl devices Paired 2>/dev/null | awk '{print $2}' | while read -r mac; do [ -n \"$mac\" ] && bluetoothctl remove \"$mac\" 2>&1; done"
        ];
        btActionProc.running = true;
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
                        const mac = parts[3].replace(/\x1b\[[0-9;]*m/g, "").trim();
                        const name = parts.slice(4).join("\t").replace(/\x1b\[[0-9;]*m/g, "").trim() || mac;
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
        spacing: 14

        BluetoothHeaderBar {
            theme: root.theme
            font: root.font
            btEnabled: root.btEnabled
            btAvailable: root.btAvailable
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
        }

        // Inline error banner
        Rectangle {
            visible: root.errorMessage !== ""
            Layout.fillWidth: true
            implicitHeight: errorText.implicitHeight + 16
            radius: 10
            color: Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.14)
            border.color: Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.35)
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
                    font.pixelSize: Style.px(12)
                    color: root.theme.accentRed
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: "✕"
                    font.family: root.font
                    font.pixelSize: Style.px(12)
                    color: root.theme.accentRed
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.errorMessage = ""
                    }
                }
            }
        }

        // Disabled / unavailable state card
        Rectangle {
            visible: !root.btAvailable || !root.btEnabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder
            border.width: 1

            BluetoothEmptyState {
                anchors.centerIn: parent
                theme: root.theme
                font: root.font
                btAvailable: root.btAvailable
                btEnabled: root.btEnabled
            }
        }

        // Segmented Scrollable Content (Connected / Paired / Available / Additional settings)
        Flickable {
            visible: root.btAvailable && root.btEnabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: contentCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 4
                contentItem: Rectangle {
                    implicitWidth: 3
                    radius: 1.5
                    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.2)
                }
            }

            ColumnLayout {
                id: contentCol
                width: parent.width - 8
                spacing: 14

                // 1. Connected Devices Card(s)
                Rectangle {
                    visible: root.connectedDevices.length > 0
                    Layout.fillWidth: true
                    implicitHeight: connectedCol.implicitHeight + 12
                    radius: 12
                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.10)
                    border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.35)
                    border.width: 1

                    ColumnLayout {
                        id: connectedCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6
                        spacing: 2

                        Repeater {
                            model: root.connectedDevices

                            delegate: ColumnLayout {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                spacing: 2

                                BluetoothDeviceRow {
                                    Layout.fillWidth: true
                                    theme: root.theme
                                    font: root.font
                                    deviceData: modelData
                                    isExpanded: root.expandedMac === modelData.mac
                                    busy: root.busyMac === modelData.mac
                                    onExpandRequested: mac => root.expandedMac = mac
                                    onDisconnectRequested: mac => root.disconnectDevice(mac)
                                    onForgetRequested: mac => root.forgetDevice(mac)
                                    onCollapseRequested: root.expandedMac = ""
                                }

                                Rectangle {
                                    visible: index < root.connectedDevices.length - 1
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 44
                                    Layout.rightMargin: 12
                                    height: 1
                                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.2)
                                }
                            }
                        }
                    }
                }

                // 2. Paired Devices Section
                ColumnLayout {
                    visible: root.pairedDevices.length > 0
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Paired devices"
                        font.family: root.font
                        font.pixelSize: Style.px(12)
                        font.bold: true
                        color: root.theme.textSecondary
                        Layout.leftMargin: 4
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: pairedCol.implicitHeight + 12
                        radius: 12
                        color: root.theme.bgSurface
                        border.color: root.theme.bgBorder
                        border.width: 1

                        ColumnLayout {
                            id: pairedCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 6
                            spacing: 2

                            Repeater {
                                model: root.pairedDevices

                                delegate: ColumnLayout {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 2

                                    BluetoothDeviceRow {
                                        Layout.fillWidth: true
                                        theme: root.theme
                                        font: root.font
                                        deviceData: modelData
                                        isExpanded: root.expandedMac === modelData.mac
                                        busy: root.busyMac === modelData.mac
                                        onExpandRequested: mac => root.expandedMac = mac
                                        onConnectRequested: mac => root.connectDevice(mac)
                                        onForgetRequested: mac => root.forgetDevice(mac)
                                        onCollapseRequested: root.expandedMac = ""
                                    }

                                    Rectangle {
                                        visible: index < root.pairedDevices.length - 1
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 44
                                        Layout.rightMargin: 12
                                        height: 1
                                        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
                                    }
                                }
                            }
                        }
                    }
                }

                // 3. Available Devices Section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4

                        Text {
                            text: "Available devices"
                            font.family: root.font
                            font.pixelSize: Style.px(12)
                            font.bold: true
                            color: root.theme.textSecondary
                            Layout.fillWidth: true
                        }

                        Text {
                            text: btScanProc.running ? "Scanning..." : "Scan"
                            font.family: root.font
                            font.pixelSize: Style.px(12)
                            font.bold: true
                            color: btScanProc.running ? root.theme.textMuted : root.theme.accentPrimary

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: btScanProc.running ? Qt.ArrowCursor : Qt.PointingHandCursor
                                enabled: !btScanProc.running
                                onClicked: {
                                    root.errorMessage = "";
                                    btScanProc.running = true;
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: root.availableDevices.length > 0 ? (availCol.implicitHeight + 12) : 96
                        radius: 12
                        color: root.theme.bgSurface
                        border.color: root.theme.bgBorder
                        border.width: 1

                        ColumnLayout {
                            id: availCol
                            visible: root.availableDevices.length > 0
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 6
                            spacing: 2

                            Repeater {
                                model: root.availableDevices

                                delegate: ColumnLayout {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 2

                                    BluetoothDeviceRow {
                                        Layout.fillWidth: true
                                        theme: root.theme
                                        font: root.font
                                        deviceData: modelData
                                        isExpanded: root.expandedMac === modelData.mac
                                        busy: root.busyMac === modelData.mac
                                        onExpandRequested: mac => root.expandedMac = mac
                                        onConnectRequested: mac => root.connectDevice(mac)
                                        onForgetRequested: mac => root.forgetDevice(mac)
                                        onCollapseRequested: root.expandedMac = ""
                                    }

                                    Rectangle {
                                        visible: index < root.availableDevices.length - 1
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 44
                                        Layout.rightMargin: 12
                                        height: 1
                                        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
                                    }
                                }
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            visible: root.availableDevices.length === 0

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: btScanProc.running ? "Scanning for devices..." : "No other devices nearby"
                                font.family: root.font
                                font.pixelSize: Style.px(12)
                                color: root.theme.textSecondary
                            }
                        }
                    }
                }

                // 4. Additional settings (Manage paired devices)
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    spacing: 8

                    Text {
                        text: "Additional settings"
                        font.family: root.font
                        font.pixelSize: Style.px(12)
                        font.bold: true
                        color: root.theme.textSecondary
                        Layout.leftMargin: 4
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: additionalCol.implicitHeight + 12
                        radius: 12
                        color: root.theme.bgSurface
                        border.color: root.theme.bgBorder
                        border.width: 1
                        clip: true

                        ColumnLayout {
                            id: additionalCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 6
                            spacing: 4

                            // Header row: Manage paired devices
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 50
                                Layout.preferredHeight: 50
                                radius: 10
                                color: manageRowHov.hovered
                                    ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
                                    : "transparent"

                                HoverHandler { id: manageRowHov }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.managePairedExpanded = !root.managePairedExpanded
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 10

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: "Manage paired devices"
                                            color: root.theme.textPrimary
                                            font.family: root.font
                                            font.pixelSize: Style.px(13)
                                            font.bold: true
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: root.allPairedDevices.length === 0
                                                ? "No paired Bluetooth devices"
                                                : (root.allPairedDevices.length + (root.allPairedDevices.length === 1 ? " paired device" : " paired devices"))
                                            color: root.theme.textSecondary
                                            font.family: root.font
                                            font.pixelSize: Style.px(11)
                                            Layout.fillWidth: true
                                        }
                                    }

                                    // Forget all button (2-step confirm)
                                    Rectangle {
                                        visible: root.allPairedDevices.length > 0
                                        Layout.preferredWidth: forgetAllText.implicitWidth + 18
                                        Layout.preferredHeight: 28
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 7
                                        color: root.confirmForgetAll
                                            ? root.theme.accentRed
                                            : (forgetAllHov.hovered
                                                ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.16)
                                                : Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.08))
                                        border.color: root.theme.accentRed
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                        HoverHandler { id: forgetAllHov }

                                        Text {
                                            id: forgetAllText
                                            anchors.centerIn: parent
                                            text: root.confirmForgetAll ? "Confirm forget all?" : "Forget all"
                                            color: root.confirmForgetAll ? root.theme.bgBase : root.theme.accentRed
                                            font.family: root.font
                                            font.pixelSize: Style.px(11)
                                            font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (!root.confirmForgetAll) {
                                                    root.confirmForgetAll = true;
                                                    forgetAllResetTimer.restart();
                                                } else {
                                                    root.confirmForgetAll = false;
                                                    forgetAllResetTimer.stop();
                                                    root.forgetAllPaired();
                                                    root.expandedMac = "";
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: "›"
                                        color: root.theme.textMuted
                                        font.family: root.font
                                        font.pixelSize: Style.px(16)
                                        font.bold: true
                                        Layout.preferredWidth: 16
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.alignment: Qt.AlignVCenter
                                        rotation: root.managePairedExpanded ? 90 : 0
                                        Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }

                            // Expanded list of paired devices (animated container)
                            Item {
                                id: pairedManageClip
                                Layout.fillWidth: true
                                clip: true
                                readonly property real targetHeight: Math.min(pairedManageListCol.implicitHeight, 280)
                                implicitHeight: root.managePairedExpanded ? targetHeight : 0
                                opacity: root.managePairedExpanded ? 1 : 0
                                enabled: root.managePairedExpanded

                                Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                                Flickable {
                                    anchors.fill: parent
                                    contentWidth: width
                                    contentHeight: pairedManageListCol.implicitHeight
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds

                                    ScrollBar.vertical: ScrollBar {
                                        policy: ScrollBar.AsNeeded
                                        width: 4
                                        contentItem: Rectangle {
                                            implicitWidth: 3
                                            radius: 1.5
                                            color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.2)
                                        }
                                    }

                                    ColumnLayout {
                                        id: pairedManageListCol
                                        width: parent.width - 6
                                        spacing: 2

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 12
                                            Layout.rightMargin: 12
                                            height: 1
                                            color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
                                        }

                                        Text {
                                            visible: root.allPairedDevices.length === 0
                                            Layout.fillWidth: true
                                            Layout.topMargin: 10
                                            Layout.bottomMargin: 10
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "No paired Bluetooth devices"
                                            color: root.theme.textMuted
                                            font.family: root.font
                                            font.pixelSize: Style.px(12)
                                        }

                                        Repeater {
                                            model: root.allPairedDevices

                                            delegate: ColumnLayout {
                                                required property var modelData
                                                required property int index
                                                Layout.fillWidth: true
                                                spacing: 2

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    Layout.leftMargin: 14
                                                    Layout.rightMargin: 12
                                                    Layout.topMargin: 6
                                                    Layout.bottomMargin: 6
                                                    spacing: 10

                                                    Text {
                                                        text: modelData.connected ? "󰂱" : "󰂯"
                                                        color: modelData.connected ? root.theme.accentPrimary : root.theme.textSecondary
                                                        font.family: root.font
                                                        font.pixelSize: Style.px(15)
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 1

                                                        Text {
                                                            text: modelData.name
                                                            color: root.theme.textPrimary
                                                            font.family: root.font
                                                            font.pixelSize: Style.px(12)
                                                            font.bold: modelData.connected
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                        }

                                                        Text {
                                                            text: modelData.connected ? ("Connected • " + modelData.mac) : modelData.mac
                                                            color: modelData.connected ? root.theme.accentPrimary : root.theme.textMuted
                                                            font.family: root.font
                                                            font.pixelSize: Style.px(10)
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                        }
                                                    }

                                                    Rectangle {
                                                        Layout.preferredWidth: 66
                                                        Layout.preferredHeight: 26
                                                        Layout.alignment: Qt.AlignVCenter
                                                        radius: 6
                                                        color: pairedForgetHov.hovered
                                                            ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.14)
                                                            : "transparent"
                                                        border.color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14)
                                                        border.width: 1
                                                        HoverHandler { id: pairedForgetHov }

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "Forget"
                                                            color: pairedForgetHov.hovered ? root.theme.accentRed : root.theme.textSecondary
                                                            font.family: root.font
                                                            font.pixelSize: Style.px(11)
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: root.forgetDevice(modelData.mac)
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    visible: index < root.allPairedDevices.length - 1
                                                    Layout.fillWidth: true
                                                    Layout.leftMargin: 38
                                                    Layout.rightMargin: 12
                                                    height: 1
                                                    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
