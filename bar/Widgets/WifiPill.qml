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
  readonly property bool wifiEnabled: WifiService.wifiEnabled
  readonly property string currentSsid: WifiService.currentSsid
  readonly property int currentSignal: WifiService.currentSignal
  property string expandedSsid: ""
  property bool autoConnect: true
  property string passwordInput: ""
  readonly property bool isConnecting: WifiService.isConnecting || WifiService.isDisconnecting
  readonly property string connectingSsid: WifiService.connectingSsid
  readonly property var networkList: WifiService.networkList
  readonly property var savedConnections: WifiService.savedConnections

  readonly property string wifiIcon: {
    if (!wifiEnabled) return "󰖪";
    if (SystemInfo.networkType === "ethernet" && !currentSsid) return "󰈀";
    if (!currentSsid && SystemInfo.networkType === "disconnected") return "󰤯";
    if (currentSignal >= 75) return "󰤨";
    if (currentSignal >= 50) return "󰤥";
    if (currentSignal >= 25) return "󰤢";
    return "󰖩";
  }

  implicitHeight: hostContainer.isVert ? (wifiVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : hostContainer.horizPillHeight)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (wifiContent.implicitWidth + hostContainer.scaled(14))
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
    return WifiService.signalIcon(sig, secured);
  }

  Connections {
    target: WifiService
    function onNetworkConnected(ssid) {
      wifiPill.passwordInput = "";
      wifiPill.expandedSsid = ssid;
    }
  }

  Process {
    id: settingsProc
    running: false
  }

  function toggleWifiRadio() {
    WifiService.toggleWifi();
  }

  function connectNetwork(ssid, secured, pwd) {
    WifiService.connect(ssid, secured, pwd, wifiPill.autoConnect);
  }

  function disconnectNetwork(ssid) {
    WifiService.disconnect(ssid);
  }

  function openMoreWifiSettings() {
    wifiPill.isPinned = false;
    settingsProc.command = ["sh", "-c", "qs ipc call settings open wifi 2>/dev/null || quickshell ipc call settings open wifi 2>/dev/null"];
    settingsProc.running = true;
  }

  Timer {
    interval: 5000
    running: wifiProvider.isDetailsActive
    repeat: true
    onTriggered: WifiService.refreshStatus()
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
    property color accent: hostContainer.wAccent("wifi", hostRoot.theme.accentPrimary)
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
        if (hostContainer && hostContainer.activeInfoProvider && hostContainer.activeInfoProvider !== wifiProvider && hostContainer.activeInfoProvider.pinned) return;
        wifiCloseTimer.stop();
        effectiveHovered = true;
        hostContainer.activeInfoProvider = wifiProvider;
        WifiService.refreshStatus();
        if (wifiPill.wifiEnabled) WifiService.scan(false);
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
        WifiService.refreshStatus();
        if (wifiPill.wifiEnabled) WifiService.scan(false);
      } else if (!hovered && !isSharedCardHovered && hostContainer.activeInfoProvider === wifiProvider) {
        hostContainer.activeInfoProvider = null;
      }
    }
    Component.onDestruction: {
      if (hostContainer && hostContainer.activeInfoProvider === wifiProvider) hostContainer.activeInfoProvider = null;
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
              color: WifiService.isScanning ? wifiProvider.accent : (refHov.hovered ? th.textPrimary : th.textSecondary)
              RotationAnimator on rotation {
                from: 0; to: 360; duration: 900
                loops: Animation.Infinite
                running: WifiService.isScanning
              }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: WifiService.scan(true)
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

        // Inline error banner when connection fails
        Rectangle {
          visible: WifiService.lastError !== ""
          Layout.fillWidth: true
          implicitHeight: errText.implicitHeight + 12
          radius: 7
          color: Qt.rgba(th.accentRed.r, th.accentRed.g, th.accentRed.b, 0.14)
          border.color: Qt.rgba(th.accentRed.r, th.accentRed.g, th.accentRed.b, 0.35)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6
            Text {
              id: errText
              Layout.fillWidth: true
              text: WifiService.lastError
              font.family: wifiProvider.font
              font.pixelSize: 10
              color: th.accentRed
              wrapMode: Text.WordWrap
            }
            Text {
              text: "✕"
              font.family: wifiProvider.font
              font.pixelSize: 10
              color: th.accentRed
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: WifiService.clearError()
              }
            }
          }
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
    accentColor: hostContainer.wAccent("wifi", hostRoot.theme.accentPrimary)
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
        ? hostContainer.wAccent("wifi", hostRoot.theme.accentPrimary)
        : hostRoot.theme.textMuted
      font.pixelSize: hostContainer.scaled(14)
      font.family: hostRoot.font
    }

    Text {
      visible: Boolean(BarConfig.wifiBtShowLabels) && (wifiPill.currentSsid !== "" || !wifiPill.wifiEnabled)
      anchors.verticalCenter: parent.verticalCenter
      text: wifiPill.wifiEnabled ? wifiPill.currentSsid : "Off"
      color: hostRoot.theme.textPrimary
      font.pixelSize: hostContainer.scaled(11)
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
        ? hostContainer.wAccent("wifi", hostRoot.theme.accentPrimary)
        : hostRoot.theme.textMuted
      font.pixelSize: hostContainer.scaled(13)
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
