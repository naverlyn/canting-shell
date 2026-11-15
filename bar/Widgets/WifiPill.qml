import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../Components"
import ".."

Rectangle {
  required property var hostRoot
  required property var hostContainer
  id: wifiPill

  property bool isPinned: false
  property bool wifiEnabled: true
  property string currentSsid: ""
  property int currentSignal: 0
  property string expandedSsid: ""
  property bool autoConnect: true
  property string passwordInput: ""
  property bool isConnecting: false
  property string connectingSsid: ""
  property var networkList: []
  property var savedConnections: ({})

  readonly property string wifiIcon: {
    if (!wifiEnabled) return "󰖪";
    if (SystemInfo.networkType === "ethernet" && !currentSsid) return "󰈀";
    if (!currentSsid && SystemInfo.networkType === "disconnected") return "󰤯";
    if (currentSignal >= 75) return "󰤨";
    if (currentSignal >= 50) return "󰤥";
    if (currentSignal >= 25) return "󰤢";
    return "󰖩";
  }

  implicitHeight: hostContainer.isVert ? (wifiVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (wifiContent.implicitWidth + 14)
  height: implicitHeight
  width: implicitWidth
  scale: wifiMouse.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("wifi", wifiHover.hovered || wifiMouse.containsMouse || wifiPill.isPinned)
  border.color: hostContainer.wBorder("wifi")
  border.width: hostContainer.hasCustomColor("wifi") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Wi-Fi: " + (wifiEnabled ? (currentSsid || "On") : "Off")

  HoverHandler { id: wifiHover }

  function netSignalIcon(sig, secured) {
    if (sig >= 75) return secured ? "󰤪" : "󰤨";
    if (sig >= 50) return secured ? "󰤧" : "󰤥";
    if (sig >= 25) return secured ? "󰤤" : "󰤢";
    return secured ? "󰤡" : "󰤟";
  }

  // Fast status poll for the bar icon
  Process {
    id: statusProc
    command: [
      "sh", "-c",
      "w_rad=$(nmcli radio wifi 2>/dev/null || echo 'enabled'); " +
      "w_line=$(nmcli -t -f active,ssid,signal dev wifi list --rescan no 2>/dev/null | grep '^yes:' | head -n1); " +
      "w_ssid=$(echo \"$w_line\" | cut -d: -f2); " +
      "w_sig=$(echo \"$w_line\" | cut -d: -f3); " +
      "printf '%s\\n%s\\n%s\\n' \"$w_rad\" \"$w_ssid\" \"${w_sig:-0}\""
    ]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        if (lines.length >= 1) wifiPill.wifiEnabled = (lines[0].trim() !== "disabled");
        if (lines.length >= 2) wifiPill.currentSsid = lines[1].trim();
        if (lines.length >= 3) wifiPill.currentSignal = parseInt(lines[2].trim()) || 0;
      }
    }
  }

  // Full network scan when popup is opened
  Process {
    id: scanProc
    command: [
      "sh", "-c",
      "nmcli -t -f NAME,TYPE connection show 2>/dev/null | awk -F: '$2==\"802-11-wireless\"{print \"SAVED:\"$1}'; " +
      "nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi list --rescan auto 2>/dev/null"
    ]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        const nets = [];
        const seen = {};
        const saved = {};
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i].trim();
          if (!line) continue;
          if (line.startsWith("SAVED:")) {
            saved[line.substring(6)] = true;
            continue;
          }
          const p = line.split(":");
          if (p.length >= 4) {
            const active = (p[0] === "yes");
            const ssid = p[1];
            const sig = parseInt(p[2]) || 0;
            const sec = p.slice(3).join(":").trim();
            if (!ssid || seen[ssid]) continue;
            seen[ssid] = true;
            if (active) {
              wifiPill.currentSsid = ssid;
              wifiPill.currentSignal = sig;
            }
            nets.push({
              ssid: ssid,
              active: active,
              signal: sig,
              secured: sec !== "" && sec !== "--",
              securityText: sec
            });
          }
        }
        wifiPill.savedConnections = saved;
        nets.sort((a, b) => {
          if (a.active !== b.active) return a.active ? -1 : 1;
          return b.signal - a.signal;
        });
        wifiPill.networkList = nets;
        if (!wifiPill.expandedSsid && wifiPill.currentSsid) {
          wifiPill.expandedSsid = wifiPill.currentSsid;
        }
      }
    }
  }

  Process {
    id: radioProc
    running: false
    onExited: {
      statusProc.running = true;
      if (wifiPill.wifiEnabled) scanProc.running = true;
    }
  }

  Process {
    id: connectProc
    running: false
    onExited: {
      wifiPill.isConnecting = false;
      wifiPill.connectingSsid = "";
      wifiPill.passwordInput = "";
      statusProc.running = true;
      scanProc.running = true;
    }
  }

  Process {
    id: settingsProc
    running: false
  }

  function toggleWifiRadio() {
    const next = !wifiPill.wifiEnabled;
    wifiPill.wifiEnabled = next;
    if (!next) {
      wifiPill.currentSsid = "";
      wifiPill.networkList = [];
    }
    radioProc.command = ["nmcli", "radio", "wifi", next ? "on" : "off"];
    radioProc.running = true;
  }

  function connectNetwork(ssid, secured, pwd) {
    wifiPill.isConnecting = true;
    wifiPill.connectingSsid = ssid;
    const isSaved = Boolean(wifiPill.savedConnections[ssid]);
    const autoVal = wifiPill.autoConnect ? "yes" : "no";
    if (!secured || isSaved || !pwd) {
      connectProc.command = [
        "sh", "-c",
        "nmcli dev wifi connect \"$1\" && nmcli connection modify \"$1\" connection.autoconnect \"$2\" 2>/dev/null || true",
        "--", ssid, autoVal
      ];
    } else {
      connectProc.command = [
        "sh", "-c",
        "nmcli dev wifi connect \"$1\" password \"$2\" && nmcli connection modify \"$1\" connection.autoconnect \"$3\" 2>/dev/null || true",
        "--", ssid, pwd, autoVal
      ];
    }
    connectProc.running = true;
  }

  function disconnectNetwork(ssid) {
    wifiPill.isConnecting = true;
    wifiPill.connectingSsid = ssid;
    connectProc.command = [
      "sh", "-c",
      "IFACE=$(nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | grep ':wifi:connected' | head -n1 | cut -d: -f1); " +
      "[ -n \"$IFACE\" ] && nmcli dev disconnect \"$IFACE\" 2>/dev/null; " +
      "[ -n \"$1\" ] && nmcli con down id \"$1\" 2>/dev/null || true",
      "--", ssid
    ];
    connectProc.running = true;
  }

  function openMoreWifiSettings() {
    wifiPill.isPinned = false;
    settingsProc.command = ["sh", "-c", "qs ipc call settings open wifi 2>/dev/null || quickshell ipc call settings open wifi 2>/dev/null"];
    settingsProc.running = true;
  }

  Timer {
    interval: wifiProvider.isDetailsActive ? 5000 : 12000
    running: true
    repeat: true
    onTriggered: if (!statusProc.running) statusProc.running = true
  }

  Item {
    id: wifiProvider
    visible: false
    width: 0
    height: 0
    property Item target: wifiPill
    property var barItem: hostContainer
    property var hostRoot: wifiPill.hostRoot
    property bool hovered: wifiHover.hovered || wifiMouse.containsMouse
    property bool pinned: wifiPill.isPinned
    property bool effectiveHovered: false
    readonly property bool isSharedCardHovered: Boolean(barItem && barItem.activeInfoProvider === wifiProvider && barItem.sharedInfoPopup && barItem.sharedInfoPopup.cardHovered)
    readonly property bool isDetailsActive: effectiveHovered || pinned || isSharedCardHovered
    property var theme: hostRoot.theme
    property string font: hostRoot.font
    property string title: "Wi-Fi"
    property string icon: "󰖩"
    property color accent: hostContainer.wAccent("wifi", hostRoot.theme.accentCyan)
    property bool hideHeader: true
    property int preferredWidth: 304
    property int preferredHeight: 0
    property var rows: []

    Timer {
      id: wifiCloseTimer
      interval: 150
      onTriggered: {
        if (!wifiProvider.hovered && !wifiProvider.isSharedCardHovered) {
          wifiProvider.effectiveHovered = false;
          if (hostContainer.activeInfoProvider === wifiProvider && !wifiProvider.pinned)
            hostContainer.activeInfoProvider = null;
        }
      }
    }
    onHoveredChanged: {
      if (hovered) {
        wifiCloseTimer.stop();
        effectiveHovered = true;
        hostContainer.activeInfoProvider = wifiProvider;
        if (!statusProc.running) statusProc.running = true;
        if (wifiPill.wifiEnabled && !scanProc.running) scanProc.running = true;
      } else if (!isSharedCardHovered) {
        wifiCloseTimer.restart();
      }
    }
    onIsSharedCardHoveredChanged: {
      if (isSharedCardHovered) { wifiCloseTimer.stop(); effectiveHovered = true; }
      else if (!hovered) wifiCloseTimer.restart();
    }
    onPinnedChanged: {
      if (pinned) {
        const o = hostContainer.activeInfoProvider;
        if (o && o !== wifiProvider && o.target && o.target.isPinned !== undefined) o.target.isPinned = false;
        hostContainer.activeInfoProvider = wifiProvider;
        if (wifiPill.wifiEnabled && !scanProc.running) scanProc.running = true;
      } else if (!hovered && !isSharedCardHovered && hostContainer.activeInfoProvider === wifiProvider) {
        hostContainer.activeInfoProvider = null;
      }
    }
    Component.onDestruction: {
      if (hostContainer.activeInfoProvider === wifiProvider) hostContainer.activeInfoProvider = null;
    }

    property Component contentComponent: Component {
      ColumnLayout {
        spacing: 8
        readonly property var th: wifiProvider.theme

        // Top Header: "Wi-Fi" + Refresh + Fluent Pill Toggle
        RowLayout {
          Layout.fillWidth: true
          Layout.topMargin: 2
          Layout.leftMargin: 6
          Layout.rightMargin: 6
          spacing: 8

          Text {
            text: "Wi-Fi"
            font.family: wifiProvider.font
            font.pixelSize: 13
            font.bold: true
            color: th.textPrimary
          }

          Item { Layout.fillWidth: true }

          // Refresh button
          Rectangle {
            visible: wifiPill.wifiEnabled
            width: 26; height: 26; radius: 7
            color: refHov.hovered ? Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            HoverHandler { id: refHov }
            Text {
              anchors.centerIn: parent
              text: "󰑐"
              font.family: wifiProvider.font
              font.pixelSize: 13
              color: scanProc.running ? wifiProvider.accent : (refHov.hovered ? th.textPrimary : th.textSecondary)
              RotationAnimator on rotation {
                from: 0; to: 360; duration: 900
                loops: Animation.Infinite
                running: scanProc.running
              }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: if (!scanProc.running) scanProc.running = true
            }
          }

          // Fluent Pill Toggle Switch
          Rectangle {
            width: 40
            height: 20
            radius: 10
            color: wifiPill.wifiEnabled
              ? wifiProvider.accent
              : Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.12)
            border.color: wifiPill.wifiEnabled ? "transparent" : Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.25)
            border.width: 1
            Behavior on color { ColorAnimation { duration: 160 } }

            Rectangle {
              width: 14
              height: 14
              radius: 7
              y: 3
              x: wifiPill.wifiEnabled ? (parent.width - width - 3) : 3
              color: wifiPill.wifiEnabled ? th.bgBase : th.textSecondary
              Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
              Behavior on color { ColorAnimation { duration: 160 } }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: wifiPill.toggleWifiRadio()
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
        }

        // Disabled state card
        Rectangle {
          visible: !wifiPill.wifiEnabled
          Layout.fillWidth: true
          Layout.preferredHeight: 76
          implicitHeight: 76
          radius: 8
          color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.05)
          border.color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
          border.width: 1

          Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "󰖪"
              font.family: wifiProvider.font
              font.pixelSize: 20
              color: th.textMuted
              horizontalAlignment: Text.AlignHCenter
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Wi-Fi is turned off"
              font.family: wifiProvider.font
              font.pixelSize: 12
              font.bold: true
              color: th.textPrimary
              horizontalAlignment: Text.AlignHCenter
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Turn on the switch above to browse networks"
              font.family: wifiProvider.font
              font.pixelSize: 10
              color: th.textSecondary
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }

        // Scrollable Networks List
        ListView {
          id: netListView
          visible: wifiPill.wifiEnabled
          Layout.fillWidth: true
          Layout.preferredHeight: 256
          clip: true
          spacing: 4
          model: wifiPill.networkList

          ScrollBar.vertical: ScrollBar {
            id: netScroll
            policy: ScrollBar.AsNeeded
            width: 4
            contentItem: Rectangle {
              implicitWidth: 3
              radius: 1.5
              color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.18)
            }
          }

          delegate: WifiNetworkDelegate {
            width: netListView.width - (netScroll.visible ? 6 : 0)
            theme: th
            accent: wifiProvider.accent
            font: wifiProvider.font
            isExpanded: wifiPill.expandedSsid === modelData.ssid
            isSaved: Boolean(wifiPill.savedConnections[modelData.ssid])
            isConnecting: wifiPill.isConnecting
            connectingSsid: wifiPill.connectingSsid
            autoConnect: wifiPill.autoConnect
            passwordInput: wifiPill.passwordInput
            signalIconFn: wifiPill.netSignalIcon

            onToggleExpand: ssid => {
              if (wifiPill.expandedSsid === ssid) {
                wifiPill.expandedSsid = "";
              } else {
                wifiPill.expandedSsid = ssid;
                wifiPill.passwordInput = "";
              }
            }
            onToggleAutoConnect: wifiPill.autoConnect = !wifiPill.autoConnect
            onPasswordEdited: pwd => { wifiPill.passwordInput = pwd; }
            onConnectRequested: (ssid, secured, pwd) => wifiPill.connectNetwork(ssid, secured, pwd)
            onDisconnectRequested: ssid => wifiPill.disconnectNetwork(ssid)
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
        }

        // Bottom Footer Link Row: "More Wi-Fi settings"
        Rectangle {
          Layout.fillWidth: true
          height: 28
          radius: 7
          color: moreWifiHov.hovered ? Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.06) : "transparent"
          Behavior on color { ColorAnimation { duration: 120 } }
          HoverHandler { id: moreWifiHov }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6

            Text {
              text: "More Wi-Fi settings"
              font.family: wifiProvider.font
              font.pixelSize: 11
              font.bold: true
              color: moreWifiHov.hovered ? Qt.lighter(wifiProvider.accent, 1.15) : wifiProvider.accent
            }

            Item { Layout.fillWidth: true }

            Text {
              text: "›"
              font.family: wifiProvider.font
              font.pixelSize: 14
              font.bold: true
              color: moreWifiHov.hovered ? th.textPrimary : th.textMuted
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: wifiPill.openMoreWifiSettings()
          }
        }
      }
    }
  }

  PillIndicator {
    hostRoot: wifiPill.hostRoot
    hostContainer: wifiPill.hostContainer
    active: wifiMouse.pressed || wifiPill.isPinned
    hovered: wifiHover.hovered || wifiMouse.containsMouse
    accentColor: hostContainer.wAccent("wifi", hostRoot.theme.accentCyan)
  }

  Row {
    id: wifiContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: wifiPill.wifiIcon
      color: wifiPill.wifiEnabled
        ? hostContainer.wAccent("wifi", hostRoot.theme.accentCyan)
        : hostRoot.theme.textMuted
      font.pixelSize: 14
      font.family: hostRoot.font
    }

    Text {
      visible: Boolean(BarConfig.wifiBtShowLabels) && (wifiPill.currentSsid !== "" || !wifiPill.wifiEnabled)
      anchors.verticalCenter: parent.verticalCenter
      text: wifiPill.wifiEnabled ? wifiPill.currentSsid : "Off"
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Column {
    id: wifiVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: wifiPill.wifiIcon
      color: wifiPill.wifiEnabled
        ? hostContainer.wAccent("wifi", hostRoot.theme.accentCyan)
        : hostRoot.theme.textMuted
      font.pixelSize: 13
      font.family: hostRoot.font
    }
  }

  MouseArea {
    id: wifiMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        wifiPill.toggleWifiRadio();
      } else {
        wifiPill.isPinned = !wifiPill.isPinned;
      }
    }
  }
}
