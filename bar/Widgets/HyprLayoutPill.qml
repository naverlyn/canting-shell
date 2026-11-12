import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import "../Components"
import ".."

Rectangle {
  required property var hostRoot
  required property var hostContainer
  id: hyprPill

  property bool isPinned: false
  property string currentLayout: "dwindle" // "dwindle" | "master"
  property bool isMonocle: false
  property bool isFloatingWin: false
  property bool isPseudoWin: false
  property bool isPinnedWin: false

  readonly property string manageScript: Qt.resolvedUrl("../../Settings/scripts/manage_hyprland.sh").toString().replace(/^file:\/\//, "")

  readonly property string modeIcon: {
    if (isMonocle) return "󰊓";
    if (isFloatingWin) return "󰉨";
    if (currentLayout === "master") return "󰯌";
    return "󰕰";
  }

  readonly property string modeLabel: {
    if (isMonocle) return "Monocle";
    if (currentLayout === "master") return isFloatingWin ? "Master · Float" : "Master";
    return isFloatingWin ? "Dwindle · Float" : "Dwindle";
  }

  implicitHeight: hostContainer.isVert ? (hyprVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (hyprContent.implicitWidth + 14)
  height: implicitHeight
  width: implicitWidth
  scale: hyprMouse.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("hyprLayout", hyprHover.hovered || hyprMouse.containsMouse || hyprPill.isPinned)
  border.color: hostContainer.wBorder("hyprLayout")
  border.width: hostContainer.hasCustomColor("hyprLayout") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Hyprland Layout: " + modeLabel

  HoverHandler { id: hyprHover }

  Process {
    id: statusProc
    command: [
      "sh", "-c",
      "if [ -z \"$HYPRLAND_INSTANCE_SIGNATURE\" ]; then " +
      "uid=$(id -u); inst=$(ls -td /run/user/\"$uid\"/hypr/*_*/ 2>/dev/null | head -n1); " +
      "[ -n \"$inst\" ] && export HYPRLAND_INSTANCE_SIGNATURE=$(basename \"$inst\"); fi; " +
      "lay=$(hyprctl getoption general:layout 2>/dev/null | awk '/str:/ {gsub(/\"/, \"\", $2); print $2; exit}'); " +
      "hyprctl activewindow -j 2>/dev/null | awk -v lay=\"${lay:-dwindle}\" '" +
      "BEGIN { fs=0; fl=\"false\"; ps=\"false\"; pn=\"false\" } " +
      "/\"fullscreen\":/ { gsub(/[^0-9]/, \"\", $2); if ($2 != \"\") fs=$2 } " +
      "/\"floating\":/ { if ($2 ~ /true/) fl=\"true\" } " +
      "/\"pseudo\":/ { if ($2 ~ /true/) ps=\"true\" } " +
      "/\"pinned\":/ { if ($2 ~ /true/) pn=\"true\" } " +
      "END { printf \"LAY:%s\\nFS:%s\\nFL:%s\\nPS:%s\\nPN:%s\\n\", lay, fs, fl, ps, pn }'"
    ]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        for (let i = 0; i < lines.length; i++) {
          const l = lines[i].trim();
          if (l.startsWith("LAY:")) hyprPill.currentLayout = (l.substring(4).trim() === "master") ? "master" : "dwindle";
          else if (l.startsWith("FS:")) hyprPill.isMonocle = (parseInt(l.substring(3).trim()) > 0);
          else if (l.startsWith("FL:")) hyprPill.isFloatingWin = (l.substring(3).trim() === "true");
          else if (l.startsWith("PS:")) hyprPill.isPseudoWin = (l.substring(3).trim() === "true");
          else if (l.startsWith("PN:")) hyprPill.isPinnedWin = (l.substring(3).trim() === "true");
        }
      }
    }
  }

  Process {
    id: dispatchProc
    running: false
    onExited: statusProc.running = true
  }

  function setLayout(targetLayout) {
    hyprPill.currentLayout = targetLayout;
    dispatchProc.command = [
      "sh", "-c",
      "uid=$(id -u); inst=$(ls -td /run/user/\"$uid\"/hypr/*_*/ 2>/dev/null | head -n1); " +
      "[ -n \"$inst\" ] && export HYPRLAND_INSTANCE_SIGNATURE=$(basename \"$inst\"); " +
      "hyprctl keyword general:layout " + targetLayout + " >/dev/null 2>&1; " +
      "bash \"" + hyprPill.manageScript + "\" set general layout " + targetLayout + " >/dev/null 2>&1 || true"
    ];
    dispatchProc.running = true;
  }

  function runDispatch(cmd) {
    dispatchProc.command = [
      "sh", "-c",
      "uid=$(id -u); inst=$(ls -td /run/user/\"$uid\"/hypr/*_*/ 2>/dev/null | head -n1); " +
      "[ -n \"$inst\" ] && export HYPRLAND_INSTANCE_SIGNATURE=$(basename \"$inst\"); " +
      "hyprctl dispatch " + cmd + " >/dev/null 2>&1 || true"
    ];
    dispatchProc.running = true;
  }

  function cycleLayout() {
    setLayout(hyprPill.currentLayout === "dwindle" ? "master" : "dwindle");
  }

  Timer {
    id: hyprEventDebounce
    interval: 150
    repeat: false
    onTriggered: if (!statusProc.running) statusProc.running = true
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event || !event.name) return;
      const n = event.name;
      if (n === "activewindowv2" || n === "fullscreen" ||
          n === "changefloatingmode" || n === "workspacev2" ||
          n === "configreloaded") {
        hyprEventDebounce.restart();
      }
    }
  }

  Timer {
    interval: 3000
    running: hyprProvider.isDetailsActive
    repeat: true
    onTriggered: if (!statusProc.running) statusProc.running = true
  }

  Item {
    id: hyprProvider
    visible: false
    width: 0
    height: 0
    property Item target: hyprPill
    property var barItem: hostContainer
    property var hostRoot: hyprPill.hostRoot
    property bool hovered: hyprHover.hovered || hyprMouse.containsMouse
    property bool pinned: hyprPill.isPinned
    property bool effectiveHovered: false
    readonly property bool isSharedCardHovered: Boolean(barItem && barItem.activeInfoProvider === hyprProvider && barItem.sharedInfoPopup && barItem.sharedInfoPopup.cardHovered)
    readonly property bool isDetailsActive: effectiveHovered || pinned || isSharedCardHovered
    property var theme: hostRoot.theme
    property string font: hostRoot.font
    property string title: "Hyprland Switcher"
    property string icon: "󰕰"
    property color accent: hostContainer.wAccent("hyprLayout", hostRoot.theme.accentPrimary)
    property bool hideHeader: true
    property int preferredWidth: 264
    property int preferredHeight: 0
    property var rows: []

    Timer {
      id: hyprCloseTimer
      interval: 150
      onTriggered: {
        if (!hyprProvider.hovered && !hyprProvider.isSharedCardHovered) {
          hyprProvider.effectiveHovered = false;
          if (hostContainer.activeInfoProvider === hyprProvider && !hyprProvider.pinned)
            hostContainer.activeInfoProvider = null;
        }
      }
    }
    onHoveredChanged: {
      if (hovered) {
        hyprCloseTimer.stop();
        effectiveHovered = true;
        hostContainer.activeInfoProvider = hyprProvider;
        if (!statusProc.running) statusProc.running = true;
      } else if (!isSharedCardHovered) {
        hyprCloseTimer.restart();
      }
    }
    onIsSharedCardHoveredChanged: {
      if (isSharedCardHovered) { hyprCloseTimer.stop(); effectiveHovered = true; }
      else if (!hovered) hyprCloseTimer.restart();
    }
    onPinnedChanged: {
      if (pinned) {
        const o = hostContainer.activeInfoProvider;
        if (o && o !== hyprProvider && o.target && o.target.isPinned !== undefined) o.target.isPinned = false;
        hostContainer.activeInfoProvider = hyprProvider;
      } else if (!hovered && !isSharedCardHovered && hostContainer.activeInfoProvider === hyprProvider) {
        hostContainer.activeInfoProvider = null;
      }
    }
    Component.onDestruction: {
      if (hostContainer.activeInfoProvider === hyprProvider) hostContainer.activeInfoProvider = null;
    }

    property Component contentComponent: Component {
      ColumnLayout {
        spacing: 8
        readonly property var th: hyprProvider.theme

        // Header Row
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: "Hyprland"
            font.family: hyprProvider.font
            font.pixelSize: 13
            font.bold: true
            color: th.textPrimary
          }

          Item { Layout.fillWidth: true }
        }

        // Card 1: Tiling Layout
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: layCardCol.implicitHeight + 16
          radius: 8
          color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.05)
          border.color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
          border.width: 1

          ColumnLayout {
            id: layCardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 6

            Text {
              text: "Tiling Layout"
              font.family: hyprProvider.font
              font.pixelSize: 10
              font.bold: true
              color: th.textSecondary
            }

            // Segmented Track with Sliding Selection Pill (matching Settings)
            Rectangle {
              id: laySegTrack
              Layout.fillWidth: true
              implicitHeight: 28
              height: 28
              radius: 7
              color: th.bgBase
              border.color: th.bgBorder
              border.width: 1

              readonly property int activeIdx: hyprPill.isMonocle ? 2 : (hyprPill.currentLayout === "master" ? 1 : 0)
              readonly property real cellWidth: (width - 6 - 6) / 3

              Rectangle {
                y: 3
                height: parent.height - 6
                width: laySegTrack.cellWidth
                x: 3 + laySegTrack.activeIdx * (laySegTrack.cellWidth + 3)
                radius: 5
                color: th.bgSelected
                border.color: hyprProvider.accent
                border.width: 1
                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
              }

              RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                  model: [
                    { id: "dwindle", label: "Dwindle" },
                    { id: "master",  label: "Master" },
                    { id: "monocle", label: "Monocle" }
                  ]
                  delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool isSel: laySegTrack.activeIdx === index

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 5
                    color: !isSel && lHov.hovered ? th.bgHover : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }
                    HoverHandler { id: lHov }

                    Text {
                      anchors.centerIn: parent
                      text: modelData.label
                      font.family: hyprProvider.font
                      font.pixelSize: 10
                      font.bold: isSel
                      color: isSel ? hyprProvider.accent : th.textPrimary
                      opacity: isSel || lHov.hovered ? 1.0 : 0.78
                      Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (modelData.id === "monocle") {
                          hyprPill.runDispatch("fullscreen 1");
                        } else {
                          if (hyprPill.isMonocle) hyprPill.runDispatch("fullscreen 1");
                          hyprPill.setLayout(modelData.id);
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // Card 2: Active Window Actions
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: actCardCol.implicitHeight + 16
          radius: 8
          color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.05)
          border.color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
          border.width: 1

          ColumnLayout {
            id: actCardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 6

            Text {
              text: "Active Window Actions"
              font.family: hyprProvider.font
              font.pixelSize: 10
              font.bold: true
              color: th.textSecondary
            }

            // Segmented Track for Active Window Actions
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 28
              height: 28
              radius: 7
              color: th.bgBase
              border.color: th.bgBorder
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                  model: [
                    { cmd: "togglefloating", label: "Float",  active: hyprPill.isFloatingWin },
                    { cmd: "pseudo",         label: "Pseudo", active: hyprPill.isPseudoWin },
                    { cmd: "togglesplit",    label: "Split",  active: false },
                    { cmd: "pin",            label: "Pin",    active: hyprPill.isPinnedWin }
                  ]
                  delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 5
                    color: modelData.active
                      ? th.bgSelected
                      : (wActHov.hovered ? th.bgHover : "transparent")
                    border.color: modelData.active ? hyprProvider.accent : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    HoverHandler { id: wActHov }

                    Text {
                      anchors.centerIn: parent
                      text: modelData.label
                      font.family: hyprProvider.font
                      font.pixelSize: 10
                      font.bold: modelData.active
                      color: modelData.active ? hyprProvider.accent : th.textPrimary
                      opacity: modelData.active || wActHov.hovered ? 1.0 : 0.78
                      Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: hyprPill.runDispatch(modelData.cmd)
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

  PillIndicator {
    hostRoot: hyprPill.hostRoot
    hostContainer: hyprPill.hostContainer
    active: hyprMouse.pressed || hyprPill.isPinned || hyprPill.isMonocle
    hovered: hyprHover.hovered || hyprMouse.containsMouse
    accentColor: hostContainer.wAccent("hyprLayout", hostRoot.theme.accentPrimary)
  }

  Row {
    id: hyprContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      visible: BarConfig.hyprLayoutShowLabel === false
      anchors.verticalCenter: parent.verticalCenter
      text: hyprPill.modeIcon
      color: hostContainer.wAccent("hyprLayout", hostRoot.theme.accentPrimary)
      font.pixelSize: 14
      font.family: hostRoot.font
    }

    Text {
      visible: BarConfig.hyprLayoutShowLabel !== false
      anchors.verticalCenter: parent.verticalCenter
      text: hyprPill.modeLabel
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.bold: true
      font.family: hostRoot.font
    }
  }

  Column {
    id: hyprVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: hyprPill.modeIcon
      color: hostContainer.wAccent("hyprLayout", hostRoot.theme.accentPrimary)
      font.pixelSize: 13
      font.family: hostRoot.font
    }

    Text {
      visible: BarConfig.hyprLayoutShowLabel !== false
      anchors.horizontalCenter: parent.horizontalCenter
      text: hyprPill.isMonocle ? "Mono" : (hyprPill.currentLayout === "master" ? "Mst" : "Dwn")
      color: hostRoot.theme.textPrimary
      font.pixelSize: 9
      font.family: hostRoot.font
    }
  }

  MouseArea {
    id: hyprMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        hyprPill.runDispatch("fullscreen 1");
      } else if (mouse.button === Qt.MiddleButton) {
        hyprPill.runDispatch("togglefloating");
      } else {
        hyprPill.isPinned = !hyprPill.isPinned;
      }
    }
    onWheel: (wheel) => {
      hyprPill.cycleLayout();
    }
  }
}
