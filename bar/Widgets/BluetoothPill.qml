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
  id: btPill

  property bool isPinned: false
  property bool btAvailable: true
  property bool btEnabled: false
  property string connectedDeviceName: ""
  property string expandedMac: ""
  property string busyMac: ""
  property var deviceList: []

  readonly property string btIcon: {
    if (!btAvailable || !btEnabled) return "󰂲";
    if (connectedDeviceName !== "") return "󰂱";
    return "󰂯";
  }

  implicitHeight: hostContainer.isVert ? (btVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (btContent.implicitWidth + 14)
  height: implicitHeight
  width: implicitWidth
  scale: btMouse.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("bluetooth", btHover.hovered || btMouse.containsMouse || btPill.isPinned)
  border.color: hostContainer.wBorder("bluetooth")
  border.width: hostContainer.hasCustomColor("bluetooth") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Bluetooth: " + (!btAvailable ? "Unavailable" : (btEnabled ? (connectedDeviceName || "On") : "Off"))

  HoverHandler { id: btHover }

  Process {
    id: btScanProc
    command: [
      "sh", "-c",
      "if ! command -v bluetoothctl >/dev/null 2>&1 || [ -z \"$(ls -A /sys/class/bluetooth 2>/dev/null)\" ]; then " +
      "echo 'STATE:none'; exit 0; fi; " +
      "if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then echo 'STATE:on'; else echo 'STATE:off'; exit 0; fi; " +
      "conn_macs=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}'); " +
      "bluetoothctl devices 2>/dev/null | while read -r _ mac name; do " +
      "[ -z \"$mac\" ] && continue; " +
      "c='0'; for cm in $conn_macs; do [ \"$cm\" = \"$mac\" ] && c='1' && break; done; " +
      "printf 'DEV:%s:%s:%s\\n' \"$c\" \"$mac\" \"$name\"; " +
      "done"
    ]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        const devs = [];
        let firstConn = "";
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i].trim();
          if (!line) continue;
          if (line.startsWith("STATE:")) {
            const st = line.substring(6).trim();
            btPill.btAvailable = (st !== "none");
            btPill.btEnabled = (st === "on");
          } else if (line.startsWith("DEV:")) {
            const rest = line.substring(4);
            const c = rest.charAt(0) === "1";
            const rem = rest.substring(2);
            const idx = rem.indexOf(":");
            if (idx !== -1) {
              const mac = rem.substring(0, idx);
              const name = rem.substring(idx + 1).trim() || mac;
              if (c && !firstConn) firstConn = name;
              devs.push({
                mac: mac,
                name: name,
                connected: c
              });
            }
          }
        }
        devs.sort((a, b) => {
          if (a.connected !== b.connected) return a.connected ? -1 : 1;
          return a.name.localeCompare(b.name);
        });
        btPill.connectedDeviceName = firstConn;
        btPill.deviceList = devs;
        if (!btPill.expandedMac && devs.length > 0 && devs[0].connected) {
          btPill.expandedMac = devs[0].mac;
        }
      }
    }
  }

  Process {
    id: btActionProc
    running: false
    onExited: {
      btPill.busyMac = "";
      btScanProc.running = true;
    }
  }

  Process {
    id: settingsProc
    running: false
  }

  function toggleBtRadio() {
    if (!btPill.btAvailable) return;
    const next = !btPill.btEnabled;
    btPill.btEnabled = next;
    if (!next) {
      btPill.connectedDeviceName = "";
      btPill.deviceList = [];
    }
    btActionProc.command = ["bluetoothctl", "power", next ? "on" : "off"];
    btActionProc.running = true;
  }

  function toggleDeviceConnection(mac, isConnected) {
    btPill.busyMac = mac;
    btActionProc.command = ["bluetoothctl", isConnected ? "disconnect" : "connect", mac];
    btActionProc.running = true;
  }

  function openMoreBtSettings() {
    btPill.isPinned = false;
    settingsProc.command = ["sh", "-c", "qs ipc call settings open bluetooth 2>/dev/null || quickshell ipc call settings open bluetooth 2>/dev/null"];
    settingsProc.running = true;
  }

  Timer {
    interval: btProvider.isDetailsActive ? 5000 : 15000
    running: btPill.btAvailable || btProvider.isDetailsActive
    repeat: true
    onTriggered: if (!btScanProc.running) btScanProc.running = true
  }

  Item {
    id: btProvider
    visible: false
    width: 0
    height: 0
    property Item target: btPill
    property var barItem: hostContainer
    property var hostRoot: btPill.hostRoot
    property bool hovered: btHover.hovered || btMouse.containsMouse
    property bool pinned: btPill.isPinned
    property bool effectiveHovered: false
    readonly property bool isSharedCardHovered: Boolean(barItem && barItem.activeInfoProvider === btProvider && barItem.sharedInfoPopup && barItem.sharedInfoPopup.cardHovered)
    readonly property bool isDetailsActive: effectiveHovered || pinned || isSharedCardHovered
    property var theme: hostRoot.theme
    property string font: hostRoot.font
    property string title: "Bluetooth"
    property string icon: "󰂯"
    property color accent: hostContainer.wAccent("bluetooth", hostRoot.theme.accentPrimary)
    property bool hideHeader: true
    property int preferredWidth: 304
    property int preferredHeight: 0
    property var rows: []

    Timer {
      id: btCloseTimer
      interval: 150
      onTriggered: {
        if (!btProvider.hovered && !btProvider.isSharedCardHovered) {
          btProvider.effectiveHovered = false;
          if (hostContainer.activeInfoProvider === btProvider && !btProvider.pinned)
            hostContainer.activeInfoProvider = null;
        }
      }
    }
    onHoveredChanged: {
      if (hovered) {
        btCloseTimer.stop();
        effectiveHovered = true;
        hostContainer.activeInfoProvider = btProvider;
        if (!btScanProc.running) btScanProc.running = true;
      } else if (!isSharedCardHovered) {
        btCloseTimer.restart();
      }
    }
    onIsSharedCardHoveredChanged: {
      if (isSharedCardHovered) { btCloseTimer.stop(); effectiveHovered = true; }
      else if (!hovered) btCloseTimer.restart();
    }
    onPinnedChanged: {
      if (pinned) {
        const o = hostContainer.activeInfoProvider;
        if (o && o !== btProvider && o.target && o.target.isPinned !== undefined) o.target.isPinned = false;
        hostContainer.activeInfoProvider = btProvider;
        if (!btScanProc.running) btScanProc.running = true;
      } else if (!hovered && !isSharedCardHovered && hostContainer.activeInfoProvider === btProvider) {
        hostContainer.activeInfoProvider = null;
      }
    }
    Component.onDestruction: {
      if (hostContainer.activeInfoProvider === btProvider) hostContainer.activeInfoProvider = null;
    }

    property Component contentComponent: Component {
      ColumnLayout {
        spacing: 8
        readonly property var th: btProvider.theme

        // Top Header: "Bluetooth" + Refresh + Fluent Pill Toggle
        RowLayout {
          Layout.fillWidth: true
          Layout.topMargin: 2
          Layout.leftMargin: 6
          Layout.rightMargin: 6
          spacing: 8

          Text {
            text: "Bluetooth"
            font.family: btProvider.font
            font.pixelSize: 13
            font.bold: true
            color: th.textPrimary
          }

          Item { Layout.fillWidth: true }

          // Refresh button
          Rectangle {
            visible: btPill.btAvailable && btPill.btEnabled
            width: 26; height: 26; radius: 7
            color: btRefHov.hovered ? Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            HoverHandler { id: btRefHov }
            Text {
              anchors.centerIn: parent
              text: "󰑐"
              font.family: btProvider.font
              font.pixelSize: 13
              color: btScanProc.running ? btProvider.accent : (btRefHov.hovered ? th.textPrimary : th.textSecondary)
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: if (!btScanProc.running) btScanProc.running = true
            }
          }

          // Fluent Pill Toggle Switch
          Rectangle {
            width: 40
            height: 20
            radius: 10
            opacity: btPill.btAvailable ? 1.0 : 0.45
            color: (btPill.btAvailable && btPill.btEnabled)
              ? btProvider.accent
              : Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.12)
            border.color: (btPill.btAvailable && btPill.btEnabled) ? "transparent" : Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.25)
            border.width: 1
            Behavior on color { ColorAnimation { duration: 160 } }

            Rectangle {
              width: 14
              height: 14
              radius: 7
              y: 3
              x: (btPill.btAvailable && btPill.btEnabled) ? (parent.width - width - 3) : 3
              color: (btPill.btAvailable && btPill.btEnabled) ? th.bgBase : th.textSecondary
              Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
              Behavior on color { ColorAnimation { duration: 160 } }
            }

            MouseArea {
              anchors.fill: parent
              enabled: btPill.btAvailable
              cursorShape: btPill.btAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: btPill.toggleBtRadio()
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
        }

        // Unavailable or Off state card
        Rectangle {
          visible: !btPill.btAvailable || !btPill.btEnabled
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
              text: "󰂲"
              font.family: btProvider.font
              font.pixelSize: 20
              color: th.textMuted
              horizontalAlignment: Text.AlignHCenter
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: !btPill.btAvailable ? "Bluetooth Unavailable" : "Bluetooth is turned off"
              font.family: btProvider.font
              font.pixelSize: 12
              font.bold: true
              color: th.textPrimary
              horizontalAlignment: Text.AlignHCenter
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: !btPill.btAvailable ? "No Bluetooth adapter detected" : "Turn on the switch above to connect"
              font.family: btProvider.font
              font.pixelSize: 10
              color: th.textSecondary
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }

        // Empty devices state when enabled
        Item {
          visible: btPill.btAvailable && btPill.btEnabled && btPill.deviceList.length === 0
          Layout.fillWidth: true
          Layout.preferredHeight: 192

          Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "󰂯"
              font.family: btProvider.font
              font.pixelSize: 20
              color: th.textMuted
              horizontalAlignment: Text.AlignHCenter
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "No paired devices found"
              font.family: btProvider.font
              font.pixelSize: 12
              font.bold: true
              color: th.textPrimary
              horizontalAlignment: Text.AlignHCenter
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Open Bluetooth settings to pair a new device"
              font.family: btProvider.font
              font.pixelSize: 10
              color: th.textSecondary
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }

        // Scrollable Devices List
        ListView {
          id: btListView
          visible: btPill.btAvailable && btPill.btEnabled && btPill.deviceList.length > 0
          Layout.fillWidth: true
          Layout.preferredHeight: 192
          clip: true
          spacing: 4
          model: btPill.deviceList

          ScrollBar.vertical: ScrollBar {
            id: btScroll
            policy: ScrollBar.AsNeeded
            width: 4
            contentItem: Rectangle {
              implicitWidth: 3
              radius: 1.5
              color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.18)
            }
          }

          delegate: Rectangle {
            id: btDelegate
            required property var modelData
            readonly property bool isExpanded: btPill.expandedMac === modelData.mac

            width: btListView.width - (btScroll.visible ? 6 : 0)
            height: isExpanded ? 88 : 44
            radius: 10
            color: isExpanded
              ? Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.07)
              : (btRowHov.hovered ? Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.045) : "transparent")
            border.color: isExpanded
              ? Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.10)
              : "transparent"
            border.width: 1
            clip: true
            Behavior on height { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 130 } }

            HoverHandler { id: btRowHov }

            Rectangle {
              visible: btDelegate.isExpanded || btDelegate.modelData.connected
              width: 3
              height: btDelegate.isExpanded ? 24 : 16
              y: btDelegate.isExpanded ? 12 : 14
              anchors.left: parent.left
              anchors.leftMargin: 3
              radius: 1.5
              color: btProvider.accent
              Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }

            ColumnLayout {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 12
              anchors.topMargin: 8
              anchors.bottomMargin: 10
              spacing: 8

              Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 28

                RowLayout {
                  anchors.fill: parent
                  spacing: 12

                  Text {
                    text: btDelegate.modelData.connected ? "󰂱" : "󰂯"
                    font.family: btProvider.font
                    font.pixelSize: 16
                    color: btDelegate.modelData.connected ? btProvider.accent : th.textPrimary
                    Layout.preferredWidth: 20
                    horizontalAlignment: Text.AlignHCenter
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                      text: btDelegate.modelData.name
                      font.family: btProvider.font
                      font.pixelSize: 12
                      font.bold: btDelegate.modelData.connected || btDelegate.isExpanded
                      color: th.textPrimary
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }

                    Text {
                      visible: btDelegate.isExpanded || btDelegate.modelData.connected
                      text: btPill.busyMac === btDelegate.modelData.mac
                        ? "Working..."
                        : (btDelegate.modelData.connected ? "Connected" : "Paired")
                      font.family: btProvider.font
                      font.pixelSize: 10
                      color: btDelegate.modelData.connected ? btProvider.accent : th.textSecondary
                    }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    btPill.expandedMac = (btPill.expandedMac === btDelegate.modelData.mac) ? "" : btDelegate.modelData.mac;
                  }
                }
              }

              // Expanded Connect / Disconnect Button Row
              RowLayout {
                visible: btDelegate.isExpanded
                Layout.fillWidth: true
                Layout.leftMargin: 32
                Item { Layout.fillWidth: true }

                Rectangle {
                  width: 124
                  height: 28
                  radius: 6
                  color: btDelegate.modelData.connected
                    ? (btActHov.hovered ? Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.16) : Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.10))
                    : (btActHov.hovered ? Qt.lighter(btProvider.accent, 1.1) : btProvider.accent)
                  border.color: btDelegate.modelData.connected
                    ? Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.14)
                    : "transparent"
                  border.width: 1
                  scale: btActMouse.pressed ? 0.96 : 1.0
                  Behavior on scale { NumberAnimation { duration: 100 } }
                  Behavior on color { ColorAnimation { duration: 120 } }
                  HoverHandler { id: btActHov }

                  Text {
                    anchors.centerIn: parent
                    text: btPill.busyMac === btDelegate.modelData.mac
                      ? "Working..."
                      : (btDelegate.modelData.connected ? "Disconnect" : "Connect")
                    font.family: btProvider.font
                    font.pixelSize: 11
                    font.bold: true
                    color: btDelegate.modelData.connected ? th.textPrimary : th.bgBase
                  }

                  MouseArea {
                    id: btActMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: btPill.toggleDeviceConnection(btDelegate.modelData.mac, btDelegate.modelData.connected)
                  }
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
        }

        // Bottom Footer Link Row: "More Bluetooth settings"
        Rectangle {
          Layout.fillWidth: true
          height: 28
          radius: 7
          color: moreBtHov.hovered ? Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.06) : "transparent"
          Behavior on color { ColorAnimation { duration: 120 } }
          HoverHandler { id: moreBtHov }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6

            Text {
              text: "More Bluetooth settings"
              font.family: btProvider.font
              font.pixelSize: 11
              font.bold: true
              color: moreBtHov.hovered ? Qt.lighter(btProvider.accent, 1.15) : btProvider.accent
            }

            Item { Layout.fillWidth: true }

            Text {
              text: "›"
              font.family: btProvider.font
              font.pixelSize: 14
              font.bold: true
              color: moreBtHov.hovered ? th.textPrimary : th.textMuted
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: btPill.openMoreBtSettings()
          }
        }
      }
    }
  }

  PillIndicator {
    hostRoot: btPill.hostRoot
    hostContainer: btPill.hostContainer
    active: btMouse.pressed || btPill.isPinned
    hovered: btHover.hovered || btMouse.containsMouse
    accentColor: hostContainer.wAccent("bluetooth", hostRoot.theme.accentPrimary)
  }

  Row {
    id: btContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: btPill.btIcon
      color: btPill.btEnabled
        ? hostContainer.wAccent("bluetooth", hostRoot.theme.accentPrimary)
        : hostRoot.theme.textMuted
      font.pixelSize: 13
      font.family: hostRoot.font
    }

    Text {
      visible: Boolean(BarConfig.wifiBtShowLabels) && btPill.connectedDeviceName !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: btPill.connectedDeviceName
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Column {
    id: btVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: btPill.btIcon
      color: btPill.btEnabled
        ? hostContainer.wAccent("bluetooth", hostRoot.theme.accentPrimary)
        : hostRoot.theme.textMuted
      font.pixelSize: 13
      font.family: hostRoot.font
    }
  }

  MouseArea {
    id: btMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        btPill.toggleBtRadio();
      } else {
        btPill.isPinned = !btPill.isPinned;
      }
    }
  }
}
