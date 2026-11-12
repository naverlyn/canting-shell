import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../Components"
import ".."

Rectangle {
  required property var hostRoot
  required property var hostContainer
  id: brPill

  property bool isPinned: false
  property int currentPct: 75
  property bool hasBacklight: false
  property bool nightLightOn: false
  readonly property string nightLightScript: Qt.resolvedUrl("../../ControlCenter/scripts/nightlight.sh").toString().replace(/^file:\/\//, "")

  readonly property string brIcon: {
    if (nightLightOn) return "󰛨";
    if (currentPct >= 70) return "󰃠";
    if (currentPct >= 35) return "󰃟";
    return "󰃞";
  }

  implicitHeight: hostContainer.isVert ? (brVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (brContent.implicitWidth + 14)
  height: implicitHeight
  width: implicitWidth
  scale: brMouse.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("brightness", brHover.hovered || brMouse.containsMouse || brPill.isPinned)
  border.color: hostContainer.wBorder("brightness")
  border.width: hostContainer.hasCustomColor("brightness") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Brightness: " + currentPct + "%"

  HoverHandler { id: brHover }

  Process {
    id: readBrProc
    command: [
      "sh", "-c",
      "if [ -n \"$(ls -A /sys/class/backlight 2>/dev/null)\" ]; then " +
      "brightnessctl -c backlight -m 2>/dev/null | head -n1; " +
      "else echo 'none,none,0,100%,100'; fi; " +
      "bash \"" + brPill.nightLightScript + "\" status 2>/dev/null || echo 'off'"
    ]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        if (lines.length >= 1) {
          const parts = lines[0].split(",");
          if (parts.length >= 4) {
            brPill.hasBacklight = (parts[1] === "backlight");
            const pctStr = parts[3].indexOf("%") !== -1 ? parts[3] : (parts[4] || "100%");
            const val = parseInt(pctStr.replace("%", "").trim());
            if (!isNaN(val)) brPill.currentPct = Math.max(1, Math.min(100, val));
          }
        }
        if (lines.length >= 2) {
          brPill.nightLightOn = (lines[1].trim() === "on");
        }
      }
    }
  }

  Process {
    id: setBrProc
    running: false
  }

  Process {
    id: nlProc
    running: false
    onExited: readBrProc.running = true
  }

  function setBrightness(pct) {
    const clamped = Math.max(1, Math.min(100, Math.round(pct)));
    brPill.currentPct = clamped;
    if (brPill.hasBacklight) {
      setBrProc.command = ["brightnessctl", "-c", "backlight", "set", clamped + "%"];
    } else {
      setBrProc.command = ["brightnessctl", "set", clamped + "%"];
    }
    setBrProc.running = true;
  }

  function toggleNightLight() {
    nlProc.command = ["bash", brPill.nightLightScript, "toggle"];
    nlProc.running = true;
  }

  Timer {
    interval: brProvider.isDetailsActive ? 5000 : 15000
    running: brPill.hasBacklight || brProvider.isDetailsActive
    repeat: true
    onTriggered: if (!readBrProc.running) readBrProc.running = true
  }

  Item {
    id: brProvider
    visible: false
    width: 0
    height: 0
    property Item target: brPill
    property var barItem: hostContainer
    property var hostRoot: brPill.hostRoot
    property bool hovered: brHover.hovered || brMouse.containsMouse
    property bool pinned: brPill.isPinned
    property bool effectiveHovered: false
    readonly property bool isSharedCardHovered: Boolean(barItem && barItem.activeInfoProvider === brProvider && barItem.sharedInfoPopup && barItem.sharedInfoPopup.cardHovered)
    readonly property bool isDetailsActive: effectiveHovered || pinned || isSharedCardHovered
    property var theme: hostRoot.theme
    property string font: hostRoot.font
    property string title: "Brightness"
    property string icon: "󰃠"
    property color accent: hostContainer.wAccent("brightness", hostRoot.theme.accentOrange)
    property bool hideHeader: true
    property int preferredWidth: 264
    property int preferredHeight: 0
    property var rows: []

    Timer {
      id: brCloseTimer
      interval: 150
      onTriggered: {
        if (!brProvider.hovered && !brProvider.isSharedCardHovered) {
          brProvider.effectiveHovered = false;
          if (hostContainer.activeInfoProvider === brProvider && !brProvider.pinned)
            hostContainer.activeInfoProvider = null;
        }
      }
    }
    onHoveredChanged: {
      if (hovered) {
        brCloseTimer.stop();
        effectiveHovered = true;
        hostContainer.activeInfoProvider = brProvider;
        if (!readBrProc.running) readBrProc.running = true;
      } else if (!isSharedCardHovered) {
        brCloseTimer.restart();
      }
    }
    onIsSharedCardHoveredChanged: {
      if (isSharedCardHovered) { brCloseTimer.stop(); effectiveHovered = true; }
      else if (!hovered) brCloseTimer.restart();
    }
    onPinnedChanged: {
      if (pinned) {
        const o = hostContainer.activeInfoProvider;
        if (o && o !== brProvider && o.target && o.target.isPinned !== undefined) o.target.isPinned = false;
        hostContainer.activeInfoProvider = brProvider;
      } else if (!hovered && !isSharedCardHovered && hostContainer.activeInfoProvider === brProvider) {
        hostContainer.activeInfoProvider = null;
      }
    }
    Component.onDestruction: {
      if (hostContainer.activeInfoProvider === brProvider) hostContainer.activeInfoProvider = null;
    }

    property Component contentComponent: Component {
      ColumnLayout {
        spacing: 8
        readonly property var th: brProvider.theme

        // Header Row
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: "Brightness"
            font.family: brProvider.font
            font.pixelSize: 13
            font.bold: true
            color: th.textPrimary
          }

          Item { Layout.fillWidth: true }
        }

        // Inner Card for Slider + Presets
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: brCardCol.implicitHeight + 18
          radius: 8
          color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.05)
          border.color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
          border.width: 1

          ColumnLayout {
            id: brCardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 9
            spacing: 8

            Item {
              Layout.fillWidth: true
              Layout.preferredHeight: 14
              implicitHeight: 14

              Rectangle {
                id: brSliderBg
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.18)

                Rectangle {
                  id: brSliderFill
                  height: parent.height
                  radius: 3
                  width: Math.min(parent.width, parent.width * (brPill.currentPct / 100.0))
                  color: brProvider.accent
                  Behavior on width {
                    enabled: !brSliderMouse.pressed
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                  }
                }

                Rectangle {
                  width: 14; height: 14; radius: 7
                  y: (parent.height - height) / 2
                  x: Math.max(0, Math.min(brSliderBg.width - width, brSliderFill.width - (width / 2)))
                  color: th.textPrimary
                }

                MouseArea {
                  id: brSliderMouse
                  anchors.fill: parent
                  anchors.topMargin: -6
                  anchors.bottomMargin: -6
                  cursorShape: Qt.PointingHandCursor
                  onPressed: (m) => brPill.setBrightness((m.x / width) * 100)
                  onPositionChanged: (m) => { if (pressed) brPill.setBrightness((m.x / width) * 100) }
                  onWheel: (w) => brPill.setBrightness(brPill.currentPct + (w.angleDelta.y > 0 ? (BarConfig.brightnessStep || 5) : -(BarConfig.brightnessStep || 5)))
                }
              }
            }
          }
        }
      }
    }
  }

  PillIndicator {
    hostRoot: brPill.hostRoot
    hostContainer: brPill.hostContainer
    active: brMouse.pressed || brPill.isPinned
    hovered: brHover.hovered || brMouse.containsMouse
    accentColor: hostContainer.wAccent("brightness", hostRoot.theme.accentOrange)
  }

  Row {
    id: brContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: brPill.brIcon
      color: hostContainer.wAccent("brightness", hostRoot.theme.accentOrange)
      font.pixelSize: 14
      font.family: hostRoot.font
    }

    Text {
      visible: BarConfig.brightnessShowPercentage !== false
      anchors.verticalCenter: parent.verticalCenter
      text: brPill.currentPct + "%"
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Column {
    id: brVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: brPill.brIcon
      color: hostContainer.wAccent("brightness", hostRoot.theme.accentOrange)
      font.pixelSize: 13
      font.family: hostRoot.font
    }

    Text {
      visible: BarConfig.brightnessShowPercentage !== false
      anchors.horizontalCenter: parent.horizontalCenter
      text: brPill.currentPct + "%"
      color: hostRoot.theme.textPrimary
      font.pixelSize: 9
      font.family: hostRoot.font
    }
  }

  MouseArea {
    id: brMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        brPill.toggleNightLight();
      } else {
        brPill.isPinned = !brPill.isPinned;
      }
    }
    onWheel: (wheel) => {
      const step = BarConfig.brightnessStep || 5;
      brPill.setBrightness(brPill.currentPct + (wheel.angleDelta.y > 0 ? step : -step));
    }
  }
}
