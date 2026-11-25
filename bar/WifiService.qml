pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: true
    property string currentSsid: ""
    property int currentSignal: 0
    property var networkList: []
    property var savedConnections: ({})
    property var savedConnectionList: []
    property var connectionDetails: ({ iface: "", mac: "", ipv4: "", gateway: "", dns: "" })

    property bool isScanning: scanProc.running
    property bool isConnecting: false
    property string connectingSsid: ""
    property bool isDisconnecting: false
    property string lastError: ""
    property string errorSsid: ""

    property string _pendingSsid: ""
    property string _connectStderr: ""
    property string _connectStdout: ""

    signal networkConnected(string ssid)
    signal networkDisconnected(string ssid)
    signal connectionFailed(string ssid, string message)

    function splitNmcliTerse(line) {
        const fields = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const ch = line[i];
            if (ch === "\\" && i + 1 < line.length) {
                const next = line[i + 1];
                if (next === ":" || next === "\\") {
                    cur += next;
                    i++;
                    continue;
                }
            }
            if (ch === ":") {
                fields.push(cur);
                cur = "";
            } else {
                cur += ch;
            }
        }
        fields.push(cur);
        return fields;
    }

    function signalIcon(sig, secured) {
        if (sig >= 75) return secured ? "󰤪" : "󰤨";
        if (sig >= 50) return secured ? "󰤧" : "󰤥";
        if (sig >= 25) return secured ? "󰤤" : "󰤢";
        return secured ? "󰤡" : "󰤟";
    }

    function clearError() {
        lastError = "";
        errorSsid = "";
    }

    function refreshStatus() {
        if (!statusProc.running) statusProc.running = true;
    }

    function refreshConnectionDetails() {
        if (!currentSsid) {
            connectionDetails = { iface: "", mac: "", ipv4: "", gateway: "", dns: "" };
            return;
        }
        if (!detailsProc.running) detailsProc.running = true;
    }

    function scan(forceRescan) {
        if (!wifiEnabled) return;
        if (scanProc.running) return;
        const mode = forceRescan ? "yes" : "auto";
        scanProc.command = [
            "sh", "-c",
            "nmcli -t -f NAME,TYPE connection show 2>/dev/null | sed 's/^/SAVED:/'; " +
            "nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY,FREQ dev wifi list --rescan " + mode + " 2>/dev/null"
        ];
        scanProc.running = true;
    }

    function setWifiEnabled(enabled) {
        if (wifiEnabled === enabled && !radioProc.running) return;
        clearError();
        wifiEnabled = enabled;
        if (!enabled) {
            currentSsid = "";
            currentSignal = 0;
            networkList = [];
        }
        radioProc.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"];
        radioProc.running = true;
    }

    function toggleWifi() {
        setWifiEnabled(!wifiEnabled);
    }

    function connect(ssid, secured, password, autoConnect) {
        if (!ssid || isConnecting) return;
        clearError();
        _pendingSsid = ssid;
        _connectStderr = "";
        _connectStdout = "";
        isConnecting = true;
        connectingSsid = ssid;

        const isSaved = Boolean(savedConnections[ssid]);
        const setAuto = (autoConnect !== undefined && autoConnect !== null);
        const autoVal = autoConnect ? "yes" : "no";

        if (!secured || isSaved || !password) {
            if (setAuto) {
                connectProc.command = [
                    "sh", "-c",
                    'nmcli dev wifi connect "$1" && (nmcli connection modify "$1" connection.autoconnect "$2" 2>/dev/null || true)',
                    "--", ssid, autoVal
                ];
            } else {
                connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
            }
        } else {
            if (setAuto) {
                connectProc.command = [
                    "sh", "-c",
                    'nmcli dev wifi connect "$1" password "$2" && (nmcli connection modify "$1" connection.autoconnect "$3" 2>/dev/null || true)',
                    "--", ssid, password, autoVal
                ];
            } else {
                connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
            }
        }
        connectProc.running = true;
    }

    function disconnect(ssid) {
        const target = ssid || currentSsid;
        if (isDisconnecting) return;
        clearError();
        _pendingSsid = target;
        isDisconnecting = true;
        connectingSsid = target;
        disconnectProc.command = [
            "sh", "-c",
            'IFACE=$(nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | grep ":wifi:connected" | head -n1 | cut -d: -f1); ' +
            '[ -n "$IFACE" ] && nmcli dev disconnect "$IFACE" 2>/dev/null; ' +
            '[ -n "$1" ] && nmcli con down id "$1" 2>/dev/null || true',
            "--", target
        ];
        disconnectProc.running = true;
    }

    function forget(ssid) {
        if (!ssid || isConnecting || isDisconnecting) return;
        clearError();
        _pendingSsid = ssid;
        forgetProc.command = ["nmcli", "connection", "delete", "id", ssid];
        forgetProc.running = true;
    }

    function forgetAll() {
        if (isConnecting || isDisconnecting) return;
        clearError();
        _pendingSsid = "__ALL__";
        forgetProc.command = [
            "sh", "-c",
            'nmcli -t -f UUID,TYPE connection show 2>/dev/null | awk -F: \'$2=="802-11-wireless"{print $1}\' | while read -r u; do [ -n "$u" ] && nmcli connection delete uuid "$u" 2>/dev/null; done'
        ];
        forgetProc.running = true;
    }

    property string _lastDetailsSsid: ""

    // Fast status poll (does not trigger hardware rescan)
    Process {
        id: statusProc
        command: [
            "sh", "-c",
            "nmcli radio wifi 2>/dev/null || echo 'enabled'; " +
            "nmcli -t -f active,ssid,signal dev wifi list --rescan no 2>/dev/null | grep '^yes:' | head -n1"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                if (lines.length >= 1 && lines[0].trim() !== "") {
                    root.wifiEnabled = (lines[0].trim() !== "disabled");
                }
                const activeLine = lines.length >= 2 ? lines[1].trim() : "";
                if (activeLine) {
                    const p = root.splitNmcliTerse(activeLine);
                    const nextSsid = p.length >= 2 ? p[1] : "";
                    root.currentSsid = nextSsid;
                    root.currentSignal = p.length >= 3 ? (parseInt(p[2]) || 0) : 0;
                    if (nextSsid && (nextSsid !== root._lastDetailsSsid || !root.connectionDetails.ipv4) && !detailsProc.running) {
                        root._lastDetailsSsid = nextSsid;
                        detailsProc.running = true;
                    }
                } else {
                    root.currentSsid = "";
                    root._lastDetailsSsid = "";
                    root.currentSignal = 0;
                    root.connectionDetails = { iface: "", mac: "", ipv4: "", gateway: "", dns: "" };
                }
            }
        }
    }

    Process {
        id: detailsProc
        command: [
            "sh", "-c",
            "IFACE=$(nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | awk -F: '$2==\"wifi\" && $3==\"connected\"{print $1; exit}'); " +
            "[ -z \"$IFACE\" ] && exit 0; " +
            "printf 'IFACE:%s\\n' \"$IFACE\"; " +
            "nmcli -t -f GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS dev show \"$IFACE\" 2>/dev/null"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                let iface = "";
                let mac = "";
                let ipv4 = "";
                let gateway = "";
                let dnsList = [];
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (!line) continue;
                    const p = root.splitNmcliTerse(line);
                    if (p.length < 2) continue;
                    const key = p[0];
                    const val = p.slice(1).join(":").trim();
                    if (!val || val === "--") continue;
                    if (key === "IFACE") iface = val;
                    else if (key === "GENERAL.HWADDR") mac = val;
                    else if (key.startsWith("IP4.ADDRESS") && !ipv4) ipv4 = val;
                    else if (key === "IP4.GATEWAY") gateway = val;
                    else if (key.startsWith("IP4.DNS")) dnsList.push(val);
                }
                root.connectionDetails = {
                    iface: iface,
                    mac: mac,
                    ipv4: ipv4,
                    gateway: gateway,
                    dns: dnsList.join(", ")
                };
            }
        }
    }

    Process {
        id: scanProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const nets = [];
                const seen = {};
                const saved = {};
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (!line) continue;
                    if (line.startsWith("SAVED:")) {
                        const sp = root.splitNmcliTerse(line.substring(6));
                        if (sp.length >= 2 && sp[1] === "802-11-wireless" && sp[0]) {
                            saved[sp[0]] = true;
                        }
                        continue;
                    }
                    const p = root.splitNmcliTerse(line);
                    if (p.length >= 4) {
                        const active = (p[0] === "yes");
                        const ssid = p[1];
                        const sig = parseInt(p[2]) || 0;
                        const sec = p[3].trim();
                        const freqRaw = p.length >= 5 ? (parseInt(p[4]) || 0) : 0;
                        let band = "";
                        if (freqRaw >= 5925) band = "6G";
                        else if (freqRaw >= 4900) band = "5G";
                        else if (freqRaw >= 2400) band = "2.4G";

                        if (!ssid) continue;
                        if (seen[ssid]) {
                            const existing = seen[ssid];
                            if (band && existing._bands.indexOf(band) === -1) {
                                existing._bands.push(band);
                                existing._bands.sort();
                                existing.band = existing._bands.join("/");
                            }
                            if (active && !existing.active) {
                                existing.active = true;
                                existing.signal = sig;
                                root.currentSsid = ssid;
                                root.currentSignal = sig;
                            } else if (sig > existing.signal) {
                                existing.signal = sig;
                            }
                            continue;
                        }
                        if (active) {
                            root.currentSsid = ssid;
                            root.currentSignal = sig;
                        }
                        const entry = {
                            ssid: ssid,
                            active: active,
                            signal: sig,
                            secured: sec !== "" && sec !== "--",
                            securityText: sec === "--" ? "" : sec,
                            band: band,
                            _bands: band ? [band] : []
                        };
                        seen[ssid] = entry;
                        nets.push(entry);
                    }
                }
                root.savedConnections = saved;
                root.savedConnectionList = Object.keys(saved).sort((a, b) => a.localeCompare(b));
                nets.sort((a, b) => {
                    if (a.active !== b.active) return a.active ? -1 : 1;
                    return b.signal - a.signal;
                });
                root.networkList = nets;
            }
        }
    }

    Process {
        id: radioProc
        running: false
        onExited: {
            root.refreshStatus();
            if (root.wifiEnabled) {
                radioScanDelay.restart();
            }
        }
    }

    Timer {
        id: radioScanDelay
        interval: 800
        repeat: false
        onTriggered: {
            if (root.wifiEnabled) root.scan(false);
        }
    }

    Process {
        id: connectProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._connectStdout = text
        }
        stderr: StdioCollector {
            onStreamFinished: root._connectStderr = text
        }
        onExited: (exitCode) => {
            const ssid = root._pendingSsid;
            root.isConnecting = false;
            root.connectingSsid = "";

            if (exitCode === 0) {
                root.lastError = "";
                root.errorSsid = "";
                root.networkConnected(ssid);
                root.refreshStatus();
                root.scan(false);
            } else {
                let raw = (root._connectStderr || root._connectStdout || "").trim();
                const firstLine = raw.split("\n")[0].replace(/^Error:\s*/i, "").trim();
                const msg = firstLine || ("Failed to connect to " + ssid);
                root.lastError = msg;
                root.errorSsid = ssid;
                root.connectionFailed(ssid, msg);
                root.refreshStatus();
            }
        }
    }

    Process {
        id: disconnectProc
        running: false
        onExited: {
            const ssid = root._pendingSsid;
            root.isDisconnecting = false;
            root.connectingSsid = "";
            root.currentSsid = "";
            root.currentSignal = 0;
            root.networkDisconnected(ssid);
            root.refreshStatus();
            root.scan(false);
        }
    }

    Process {
        id: forgetProc
        running: false
        onExited: {
            const ssid = root._pendingSsid;
            if (ssid === "__ALL__") {
                root.savedConnections = ({});
                root.savedConnectionList = [];
                root.currentSsid = "";
                root.currentSignal = 0;
            } else if (ssid && root.savedConnections[ssid]) {
                const copy = Object.assign({}, root.savedConnections);
                delete copy[ssid];
                root.savedConnections = copy;
                root.savedConnectionList = Object.keys(copy).sort((a, b) => a.localeCompare(b));
            }
            if (root.currentSsid === ssid) {
                root.currentSsid = "";
                root.currentSignal = 0;
            }
            root.refreshStatus();
            root.scan(false);
        }
    }

    Timer {
        interval: 12000
        running: true
        repeat: true
        onTriggered: root.refreshStatus()
    }
}
