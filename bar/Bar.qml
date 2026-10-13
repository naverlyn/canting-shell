import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Services.SystemTray
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick.Effects
import "../ControlCenter"
import "./Components"

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "Hack Nerd Font"
  property bool barVisible: true

  // MPRIS active player
  property var activePlayer: {
    const players = Mpris.players.values;
    if (!players || players.length === 0) return null;
    for (const p of players) {
      if (p.playbackState === MprisPlaybackState.Playing) return p;
    }
    return players[0];
  }

  IpcHandler {
    target: "bar"
    function toggle() { root.barVisible = !root.barVisible; }
  }

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  // Brightness state
  property real brightnessValue: 0
  property real brightnessMax: 1

  FileView {
    id: brightnessFile
    path: ""
    watchChanges: true
    onFileChanged: brightnessReadProc.running = true
  }

  Process {
    id: brightnessReadProc
    command: ["brightnessctl", "get"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const val = parseInt(text.trim());
        if (!isNaN(val) && root.brightnessMax > 0)
          root.brightnessValue = val / root.brightnessMax;
      }
    }
  }

  Process {
    id: brightnessSetProc
    running: false
  }

  Process {
    id: backlightDiscovery
    command: ["sh", "-c", "p=$(ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -1); [ -n \"$p\" ] && echo \"$p\" && cat \"${p%brightness}max_brightness\""]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        if (lines.length >= 2) {
          const max = parseInt(lines[1]);
          if (!isNaN(max) && max > 0) root.brightnessMax = max;
          brightnessFile.path = lines[0];
          brightnessReadProc.running = true;
        }
      }
    }
  }

  Process {
    id: weatherProcess
    running: false
    onRunningChanged: {
      if (running) {
        SystemInfo.refreshWeather();
        running = false;
      }
    }
  }

  Variants {
    model: BarConfig.bars

    Scope {
      id: barInstanceScope
      required property var modelData
      readonly property var barCfg: modelData
      readonly property string barPos: barCfg.position || "top"
      readonly property bool isVert: barPos === "left" || barPos === "right"
      readonly property int barThickness: barCfg.barHeight || 32
      readonly property bool isFloating: Boolean(barCfg.floating)
      readonly property real barAlpha: barCfg.barOpacity !== undefined ? barCfg.barOpacity : 0.85
      readonly property var barPanels: barCfg.panels || []

      Variants {
        model: Quickshell.screens

        PanelWindow {
          id: barWindow
          required property var modelData
          screen: modelData
          visible: root.barVisible && Boolean(barInstanceScope.barCfg.enabled) && (Boolean(barInstanceScope.barCfg.allMonitors) || modelData === Quickshell.screens[0])

          anchors {
            top: barInstanceScope.barPos === "top" || barInstanceScope.isVert
            bottom: barInstanceScope.barPos === "bottom" || barInstanceScope.isVert
            left: barInstanceScope.barPos === "left" || !barInstanceScope.isVert
            right: barInstanceScope.barPos === "right" || !barInstanceScope.isVert
          }

          implicitHeight: barInstanceScope.isVert ? 0 : (barInstanceScope.barThickness + (barInstanceScope.isFloating ? 12 : 0))
          implicitWidth: barInstanceScope.isVert ? (barInstanceScope.barThickness + 16 + (barInstanceScope.isFloating ? 12 : 0)) : 0
          color: "transparent"

          property string lastPos: barInstanceScope.barPos
          onLastPosChanged: barPosSwitchAnim.restart()
          Component.onCompleted: barPosSwitchAnim.restart()

          ParallelAnimation {
            id: barPosSwitchAnim
            NumberAnimation {
              target: barBackground
              property: "opacity"
              from: 0.0
              to: 1.0
              duration: 240
              easing.type: Easing.OutCubic
            }
            NumberAnimation {
              target: barContentContainer
              property: "opacity"
              from: 0.0
              to: 1.0
              duration: 240
              easing.type: Easing.OutCubic
            }
            NumberAnimation {
              target: barSlideTransform
              property: "x"
              from: barInstanceScope.barPos === "left" ? -14 : (barInstanceScope.barPos === "right" ? 14 : 0)
              to: 0
              duration: 240
              easing.type: Easing.OutCubic
            }
            NumberAnimation {
              target: barSlideTransform
              property: "y"
              from: barInstanceScope.barPos === "top" ? -14 : (barInstanceScope.barPos === "bottom" ? 14 : 0)
              to: 0
              duration: 240
              easing.type: Easing.OutCubic
            }
          }

          Rectangle {
            id: barBackground
            anchors.fill: parent
            anchors.topMargin: barInstanceScope.isFloating ? (barInstanceScope.isVert ? 12 : (barInstanceScope.barPos === "top" ? 6 : 0)) : 0
            anchors.bottomMargin: barInstanceScope.isFloating ? (barInstanceScope.isVert ? 12 : (barInstanceScope.barPos === "bottom" ? 6 : 0)) : 0
            anchors.leftMargin: barInstanceScope.isFloating ? (!barInstanceScope.isVert ? 12 : (barInstanceScope.barPos === "left" ? 6 : 0)) : 0
            anchors.rightMargin: barInstanceScope.isFloating ? (!barInstanceScope.isVert ? 12 : (barInstanceScope.barPos === "right" ? 6 : 0)) : 0
            radius: barInstanceScope.isFloating ? 12 : 0
            color: Qt.rgba(root.theme.bgBase.r, root.theme.bgBase.g, root.theme.bgBase.b, barInstanceScope.barAlpha)
            border.color: barInstanceScope.isFloating ? root.theme.bgBorder : "transparent"
            border.width: barInstanceScope.isFloating ? 1 : 0
            transform: Translate { id: barSlideTransform; x: 0; y: 0 }

            Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on anchors.bottomMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on anchors.leftMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on anchors.rightMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 180 } }
          }

          Item {
            id: barContentContainer
            anchors.fill: barBackground
            anchors.leftMargin: barInstanceScope.isVert ? 4 : 10
            anchors.rightMargin: barInstanceScope.isVert ? 4 : 10
            anchors.topMargin: barInstanceScope.isVert ? 10 : 0
            anchors.bottomMargin: barInstanceScope.isVert ? 10 : 0
            transform: Translate { x: barSlideTransform.x; y: barSlideTransform.y }

            readonly property bool isVert: barInstanceScope.isVert
            readonly property string barPos: barInstanceScope.barPos
            readonly property int vertPillWidth: Math.max(28, barBackground.width - 8)

            function _trackThemeDeps() {
              if (root.theme) {
                void root.theme.currentName;
                void root.theme.customAccent;
                void root.theme.previewAccent;
                void root.theme.wallpaperMode;
                void root.theme.accentPrimary;
                void root.theme.accentCyan;
                void root.theme.accentGreen;
                void root.theme.accentOrange;
                void root.theme.accentRed;
                void root.theme.textPrimary;
                void root.theme.textSecondary;
                void root.theme.textMuted;
                void root.theme.bgBase;
                void root.theme.bgSurface;
                void root.theme.bgHover;
                void root.theme.themes;
              }
              void BarConfig.removedWidgets;
            }

            function _toRgb(val) {
              if (!val) return null;
              if (typeof val === "object" && val.r !== undefined) {
                return { r: Number(val.r), g: Number(val.g), b: Number(val.b) };
              }
              let s = String(val).replace("#", "").trim();
              if (s.length === 8) s = s.substring(2);
              if (s.length !== 6) return null;
              let r = parseInt(s.substring(0, 2), 16) / 255.0;
              let g = parseInt(s.substring(2, 4), 16) / 255.0;
              let b = parseInt(s.substring(4, 6), 16) / 255.0;
              if (isNaN(r) || isNaN(g) || isNaN(b)) return null;
              return { r: r, g: g, b: b };
            }

            function wSpec(widgetId) {
              _trackThemeDeps();
              try {
                const bId = (barInstanceScope.barCfg && barInstanceScope.barCfg.id) ? String(barInstanceScope.barCfg.id) : "bar_1";
                const prefix = "@color:" + bId + ":" + widgetId + "=";
                const rem = BarConfig.removedWidgets || [];
                for (let i = 0; i < rem.length; i++) {
                  const item = String(rem[i]);
                  if (item.indexOf(prefix) === 0) {
                    return item.substring(prefix.length).trim();
                  }
                }
                if (barInstanceScope.barCfg && barInstanceScope.barCfg.widgetColors && barInstanceScope.barCfg.widgetColors[widgetId]) {
                  return String(barInstanceScope.barCfg.widgetColors[widgetId]).trim();
                }
              } catch (e) {}
              return "";
            }

            function resolveThemeSpec(spec) {
              _trackThemeDeps();
              if (!spec) return "";
              try {
                const s = String(spec).trim();
                if (s === "") return "";
                if (s.indexOf("theme:") === 0) {
                  const parts = s.split(":");
                  if (parts.length >= 3) {
                    const tName = parts.slice(1, parts.length - 1).join(":");
                    const roleKey = parts[parts.length - 1];
                    const tList = (root.theme && root.theme.themes) ? root.theme.themes : [];
                    for (let i = 0; i < tList.length; i++) {
                      if (tList[i] && tList[i].name === tName && tList[i][roleKey]) {
                        return Qt.color(String(tList[i][roleKey]));
                      }
                    }
                  }
                }
                if (root.theme && root.theme[s] !== undefined && typeof root.theme[s] !== "function") {
                  return root.theme[s];
                }
                if (root.theme && root.theme.current && root.theme.current[s]) {
                  return Qt.color(String(root.theme.current[s]));
                }
                if (s.charAt(0) === "#") return Qt.color(s);
              } catch (e) {}
              return "";
            }

            function hasCustomColor(widgetId) {
              return resolveThemeSpec(wSpec(widgetId)) !== "";
            }

            function wAccent(widgetId, fallbackColor) {
              const resolved = resolveThemeSpec(wSpec(widgetId));
              return resolved !== "" ? resolved : fallbackColor;
            }

            function wBg(widgetId, isHovered) {
              const base = isHovered ? root.theme.bgHover : root.theme.bgSurface;
              try {
                const resolved = resolveThemeSpec(wSpec(widgetId));
                if (resolved === "") return base;
                const rgb = _toRgb(resolved);
                const baseRgb = _toRgb(base);
                if (!rgb || !baseRgb) return base;
                const mix = isHovered ? 0.24 : 0.15;
                return Qt.rgba(
                  baseRgb.r * (1 - mix) + rgb.r * mix,
                  baseRgb.g * (1 - mix) + rgb.g * mix,
                  baseRgb.b * (1 - mix) + rgb.b * mix,
                  1.0
                );
              } catch (e) {
                return base;
              }
            }

            function wBorder(widgetId) {
              try {
                const resolved = resolveThemeSpec(wSpec(widgetId));
                if (resolved === "") return "transparent";
                const rgb = _toRgb(resolved);
                if (!rgb) return "transparent";
                return Qt.rgba(rgb.r, rgb.g, rgb.b, 0.45);
              } catch (e) {
                return "transparent";
              }
            }

            // Widget building blocks

            // 1. Applications Launcher Button
            Component {
              id: appGridComp
              Rectangle {
                id: appGridButton
                implicitHeight: barContentContainer.isVert ? 28 : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : 28
                height: implicitHeight
                width: implicitWidth
                radius: 12
                color: barContentContainer.wBg("appGrid", appGridMouse.containsMouse)
                border.color: barContentContainer.wBorder("appGrid")
                border.width: barContentContainer.hasCustomColor("appGrid") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.Button
                Accessible.name: "Applications"

                Rectangle {
                  anchors.fill: parent
                  radius: parent.radius
                  color: barContentContainer.wAccent("appGrid", root.theme.accentPrimary)
                  opacity: appGridMouse.containsMouse ? 0.15 : 0.0
                  Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Text {
                  anchors.centerIn: parent
                  text: "󰀻"
                  color: barContentContainer.wAccent("appGrid", root.theme.accentPrimary)
                  font.pixelSize: 14
                  font.family: root.font
                }

                MouseArea {
                  id: appGridMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    const pt = appGridButton.mapToItem(null, appGridButton.width / 2, appGridButton.height / 2);
                    const winW = Math.max(1, barWindow.width);
                    const winH = Math.max(1, barWindow.height);
                    const normX = (pt.x / winW).toFixed(3);
                    const normY = (pt.y / winH).toFixed(3);
                    const clearance = barContentContainer.isVert
                      ? Math.max(barWindow.width, barInstanceScope.barThickness + 16 + (barInstanceScope.isFloating ? 12 : 0))
                      : Math.max(barWindow.height, barInstanceScope.barThickness + (barInstanceScope.isFloating ? 12 : 6));
                    appGridProc.command = [
                      "qs", "ipc", "call", "appgrid", "toggleAt",
                      barContentContainer.barPos, String(normX), String(normY), String(clearance)
                    ];
                    appGridProc.running = true;
                  }
                }

                Process {
                  id: appGridProc
                  command: ["qs", "ipc", "call", "appgrid", "toggle"]
                  running: false
                }
              }
            }

            // 2. CPU Usage Pill
            Component {
              id: cpuComp
              Rectangle {
                id: cpuPill
                implicitHeight: barContentContainer.isVert ? (cpuVertCol.implicitHeight + 12) : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (cpuContent.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("cpu", cpuHover.hovered)
                border.color: barContentContainer.wBorder("cpu")
                border.width: barContentContainer.hasCustomColor("cpu") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.StaticText
                Accessible.name: "CPU: " + SystemInfo.cpuUsage

                HoverHandler { id: cpuHover }

                InfoPopup {
                  target: cpuPill
                  hovered: cpuHover.hovered
                  theme: root.theme
                  font: root.font
                  title: "CPU"
                  icon: "󰻠"
                  accent: barContentContainer.wAccent("cpu", root.theme.accentOrange)
                  script: "cpu"
                  barPosition: barContentContainer.barPos
                }

                Row {
                  id: cpuContent
                  visible: !barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 6

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰻠"
                    color: barContentContainer.wAccent("cpu", root.theme.accentOrange)
                    font.pixelSize: 14
                    font.family: root.font
                  }
                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: SystemInfo.cpuUsage
                    color: root.theme.textPrimary
                    font.pixelSize: 11
                    font.family: root.font
                  }
                }

                Column {
                  id: cpuVertCol
                  visible: barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 2

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰻠"
                    color: barContentContainer.wAccent("cpu", root.theme.accentOrange)
                    font.pixelSize: 13
                    font.family: root.font
                  }
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SystemInfo.cpuUsage
                    color: root.theme.textPrimary
                    font.pixelSize: 9
                    font.family: root.font
                  }
                }
              }
            }

            // 3. CPU Temperature Pill
            Component {
              id: tempComp
              Rectangle {
                id: tempPill
                implicitHeight: barContentContainer.isVert ? (tempVertCol.implicitHeight + 12) : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (tempContent.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("temp", tempHover.hovered)
                border.color: barContentContainer.wBorder("temp")
                border.width: barContentContainer.hasCustomColor("temp") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.StaticText
                Accessible.name: "Temperature: " + SystemInfo.temperature

                HoverHandler { id: tempHover }

                InfoPopup {
                  target: tempPill
                  hovered: tempHover.hovered
                  theme: root.theme
                  font: root.font
                  title: "Temperature"
                  icon: "󰔏"
                  accent: barContentContainer.wAccent("temp", root.theme.accentRed)
                  script: "temp"
                  barPosition: barContentContainer.barPos
                }

                Row {
                  id: tempContent
                  visible: !barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 6

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰔏"
                    color: barContentContainer.wAccent("temp", root.theme.accentRed)
                    font.pixelSize: 14
                    font.family: root.font
                  }
                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: SystemInfo.temperature
                    color: root.theme.textPrimary
                    font.pixelSize: 11
                    font.family: root.font
                  }
                }

                Column {
                  id: tempVertCol
                  visible: barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 2

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰔏"
                    color: barContentContainer.wAccent("temp", root.theme.accentRed)
                    font.pixelSize: 13
                    font.family: root.font
                  }
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SystemInfo.temperature
                    color: root.theme.textPrimary
                    font.pixelSize: 9
                    font.family: root.font
                  }
                }
              }
            }

            // 4. Memory (RAM) Pill
            Component {
              id: memoryComp
              Rectangle {
                id: memPill
                implicitHeight: barContentContainer.isVert ? (memVertCol.implicitHeight + 12) : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (memContent.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("memory", memHover.hovered)
                border.color: barContentContainer.wBorder("memory")
                border.width: barContentContainer.hasCustomColor("memory") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.StaticText
                Accessible.name: "Memory Usage: " + SystemInfo.memoryUsage

                HoverHandler { id: memHover }

                InfoPopup {
                  target: memPill
                  hovered: memHover.hovered
                  theme: root.theme
                  font: root.font
                  title: "Memory"
                  icon: "\uf2db"
                  accent: barContentContainer.wAccent("memory", root.theme.accentPrimary)
                  script: "mem"
                  barPosition: barContentContainer.barPos
                }

                Row {
                  id: memContent
                  visible: !barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 6

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: barContentContainer.wAccent("memory", root.theme.accentPrimary)
                    font.pixelSize: 14
                    font.family: root.font
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: SystemInfo.memoryUsage
                    color: root.theme.textPrimary
                    font.pixelSize: 11
                    font.family: root.font
                  }
                }

                Column {
                  id: memVertCol
                  visible: barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 2

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ""
                    color: barContentContainer.wAccent("memory", root.theme.accentPrimary)
                    font.pixelSize: 13
                    font.family: root.font
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SystemInfo.memoryUsage
                    color: root.theme.textPrimary
                    font.pixelSize: 9
                    font.family: root.font
                  }
                }
              }
            }

            // 5. Disk Usage Pill
            Component {
              id: diskComp
              Rectangle {
                id: diskButton
                implicitHeight: barContentContainer.isVert ? (diskVertCol.implicitHeight + 12) : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (diskContent.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("disk", diskMouseArea.containsMouse)
                border.color: barContentContainer.wBorder("disk")
                border.width: barContentContainer.hasCustomColor("disk") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }

                Accessible.role: Accessible.StaticText
                Accessible.name: "/ (" + SystemInfo.diskUsage + ")"

                MouseArea {
                  id: diskMouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                }

                Rectangle {
                  anchors.fill: parent
                  radius: parent.radius
                  color: barContentContainer.wAccent("disk", root.theme.accentPrimary)
                  opacity: diskMouseArea.containsMouse ? 0.15 : 0.0
                  Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Row {
                  id: diskContent
                  visible: !barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 6

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: barContentContainer.wAccent("disk", root.theme.accentPrimary)
                    font.pixelSize: 14
                    font.family: root.font
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "" + SystemInfo.diskUsage + ""
                    color: root.theme.textPrimary
                    font.pixelSize: 11
                    font.family: root.font
                  }
                }

                Column {
                  id: diskVertCol
                  visible: barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 2

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ""
                    color: barContentContainer.wAccent("disk", root.theme.accentPrimary)
                    font.pixelSize: 13
                    font.family: root.font
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SystemInfo.diskUsage
                    color: root.theme.textPrimary
                    font.pixelSize: 9
                    font.family: root.font
                  }
                }

                InfoPopup {
                  target: diskButton
                  hovered: diskMouseArea.containsMouse
                  theme: root.theme
                  font: root.font
                  title: "Disk"
                  icon: "\uf0a0"
                  accent: barContentContainer.wAccent("disk", root.theme.accentPrimary)
                  script: "disk"
                  barPosition: barContentContainer.barPos
                }
              }
            }

            // 6. Active Window Title
            Component {
              id: windowTitleComp
              Rectangle {
                id: winTitleWidget
                implicitHeight: barContentContainer.isVert ? (titleText.text !== "" ? 28 : 0) : 24
                height: implicitHeight
                readonly property string curSec: BarConfig.getWidgetSection("windowTitle")
                readonly property real availableCenterSpace: curSec === "center"
                  ? Math.max(60, Math.min(360, barContentContainer.width / Math.max(2, barInstanceScope.barPanels.length) - 24))
                  : 240
                implicitWidth: barContentContainer.isVert
                  ? (titleText.text !== "" ? barContentContainer.vertPillWidth : 0)
                  : (curSec === "center"
                    ? (titleText.text !== "" ? Math.max(40, Math.min(titleText.implicitWidth + 24, availableCenterSpace)) : 0)
                    : (titleText.text !== "" ? Math.max(40, Math.min(titleText.implicitWidth + 24, 240)) : 0))
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("windowTitle", false)
                border.color: barContentContainer.wBorder("windowTitle")
                border.width: (titleText.text !== "" && barContentContainer.hasCustomColor("windowTitle")) ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                clip: true

                Text {
                  id: titleText
                  visible: !barContentContainer.isVert
                  Accessible.role: Accessible.StaticText
                  Accessible.name: "Active window: " + text
                  text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
                  color: barContentContainer.hasCustomColor("windowTitle")
                    ? barContentContainer.wAccent("windowTitle", root.theme.textPrimary)
                    : root.theme.textPrimary
                  font.pixelSize: 13
                  font.family: root.font
                  elide: Text.ElideRight
                  width: Math.min(implicitWidth, parent.width - 16)
                  anchors.centerIn: parent
                }

                Text {
                  visible: barContentContainer.isVert
                  anchors.centerIn: parent
                  text: "🗔"
                  color: barContentContainer.wAccent("windowTitle", root.theme.accentPrimary)
                  font.pixelSize: 13
                  font.family: root.font
                }
              }
            }

            Component {
              id: workspacesComp
              Item {
                id: wsContainer
                implicitWidth: wsGrid.implicitWidth
                implicitHeight: wsGrid.implicitHeight
                width: implicitWidth
                height: implicitHeight

                Grid {
                  id: wsGrid
                  anchors.centerIn: parent
                  columns: barContentContainer.isVert ? 1 : Math.max(1, wsRepeater.count)
                  spacing: 4
                  horizontalItemAlignment: Grid.AlignHCenter
                  verticalItemAlignment: Grid.AlignVCenter

                  Repeater {
                    id: wsRepeater
                    model: Hyprland.workspaces

                    Rectangle {
                      id: wsPill
                      required property var modelData
                      property bool urgentBlink: false

                      Accessible.role: Accessible.Button
                      Accessible.name: "Workspace " + modelData.id + (modelData.focused ? ", active" : "") + (modelData.urgent ? ", urgent" : "")

                      width: barContentContainer.isVert ? barContentContainer.vertPillWidth : (modelData.focused ? 32 : 24)
                      implicitWidth: width
                      height: barContentContainer.isVert ? (modelData.focused ? 30 : 22) : 24
                      implicitHeight: height
                      radius: 10
                      color: modelData.focused
                        ? barContentContainer.wAccent("workspaces", root.theme.accentPrimary)
                        : (modelData.urgent && urgentBlink
                          ? root.theme.accentRed
                          : barContentContainer.wBg("workspaces", wsMouse.containsMouse))
                      border.color: !modelData.focused && barContentContainer.hasCustomColor("workspaces")
                        ? barContentContainer.wBorder("workspaces")
                        : "transparent"
                      border.width: (!modelData.focused && barContentContainer.hasCustomColor("workspaces")) ? 1 : 0

                      Behavior on color { ColorAnimation { duration: 150 } }
                      Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                      Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                      SequentialAnimation {
                        loops: Animation.Infinite
                        running: wsPill.modelData.urgent && !wsPill.modelData.focused

                        PropertyAction { target: wsPill; property: "urgentBlink"; value: true }
                        PauseAnimation { duration: 500 }
                        PropertyAction { target: wsPill; property: "urgentBlink"; value: false }
                        PauseAnimation { duration: 500 }

                        onStopped: wsPill.urgentBlink = false
                      }

                      Text {
                        anchors.centerIn: parent
                        text: wsPill.modelData.id
                        color: wsPill.modelData.focused ? root.theme.bgBase : root.theme.textPrimary
                        font.pixelSize: 11
                        font.family: root.font
                        font.bold: wsPill.modelData.focused
                      }

                      MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wsPill.modelData.activate()
                        onWheel: wheel => {
                          if (wheel.angleDelta.y > 0) {
                            Hyprland.dispatch("workspace e-1");
                          } else if (wheel.angleDelta.y < 0) {
                            Hyprland.dispatch("workspace e+1");
                          }
                        }
                      }
                    }
                  }
                }
              }
            }

            // 8. Weather Info Pill
            Component {
              id: weatherComp
              Rectangle {
                id: weatherWidget
                implicitHeight: barContentContainer.isVert ? 28 : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (weatherContent.implicitWidth + 16)
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("weather", false)
                border.color: barContentContainer.wBorder("weather")
                border.width: barContentContainer.hasCustomColor("weather") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                clip: true
                Accessible.role: Accessible.Button
                Accessible.name: "Weather: " + SystemInfo.weatherInfo

                Row {
                  id: weatherContent
                  visible: !barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 6

                  Text {
                    id: weatherText
                    anchors.verticalCenter: parent.verticalCenter
                    text: SystemInfo.weatherInfo
                    color: barContentContainer.hasCustomColor("weather")
                      ? barContentContainer.wAccent("weather", root.theme.textPrimary)
                      : root.theme.textPrimary
                    font.pixelSize: 11
                    font.family: root.font
                  }
                }

                Text {
                  visible: barContentContainer.isVert
                  anchors.centerIn: parent
                  text: "󰖐"
                  color: barContentContainer.wAccent("weather", root.theme.accentCyan)
                  font.pixelSize: 14
                  font.family: root.font
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: SystemInfo.refreshWeather()
                }
              }
            }

            // 9. Clock & Calendar Popup
            Component {
              id: clockComp
              Rectangle {
                id: timeWidget
                implicitHeight: barContentContainer.isVert ? (vertClockCol.implicitHeight + 12) : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (timeDate.implicitWidth + 16)
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("clock", timeHover.hovered)
                border.color: barContentContainer.wBorder("clock")
                border.width: barContentContainer.hasCustomColor("clock") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }

                HoverHandler { id: timeHover }

                Row {
                  id: timeDate
                  visible: !barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 8

                  Text {
                    id: clockTimeText
                    anchors.verticalCenter: parent.verticalCenter
                    text: Time.timeString
                    color: barContentContainer.hasCustomColor("clock")
                      ? barContentContainer.wAccent("clock", root.theme.textPrimary)
                      : root.theme.textPrimary
                    font.pixelSize: 12
                    font.family: root.font
                  }

                  Text {
                    id: clockDateText
                    anchors.verticalCenter: parent.verticalCenter
                    text: Time.dateString
                    visible: BarConfig.showDate
                    color: root.theme.textSecondary
                    font.pixelSize: 12
                    font.family: root.font
                  }
                }

                Column {
                  id: vertClockCol
                  visible: barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 1

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.timeString.split(":")[0] || "00"
                    color: root.theme.textPrimary
                    font.pixelSize: 11
                    font.bold: true
                    font.family: root.font
                  }
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.timeString.split(":")[1] || "00"
                    color: barContentContainer.wAccent("clock", root.theme.accentPrimary)
                    font.pixelSize: 11
                    font.bold: true
                    font.family: root.font
                  }
                }

                PopupWindow {
                  id: calendarPopup
                  visible: timeHover.hovered || calBox.opacity > 0
                  implicitWidth: 288
                  implicitHeight: 308
                  color: "transparent"

                  anchor.window: timeWidget.QsWindow.window
                  anchor.edges: {
                    if (barContentContainer.barPos === "bottom") return Edges.Top;
                    if (barContentContainer.barPos === "left") return Edges.Right;
                    if (barContentContainer.barPos === "right") return Edges.Left;
                    return Edges.Bottom;
                  }
                  anchor.gravity: {
                    if (barContentContainer.barPos === "bottom") return Edges.Top;
                    if (barContentContainer.barPos === "left") return Edges.Right;
                    if (barContentContainer.barPos === "right") return Edges.Left;
                    return Edges.Bottom;
                  }
                  anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
                  anchor.onAnchoring: {
                    const win = timeWidget.QsWindow.window;
                    if (!win) return;
                    const widgetRect = win.contentItem.mapFromItem(
                      timeWidget, 0, 0, timeWidget.width, timeWidget.height
                    );
                    calendarPopup.anchor.rect = widgetRect;
                  }

                  Rectangle {
                    id: calBox
                    opacity: timeHover.hovered ? 1 : 0
                    x: timeHover.hovered ? (barContentContainer.barPos === "left" ? 8 : (barContentContainer.barPos === "right" ? -8 : 0)) : 0
                    y: timeHover.hovered ? (barContentContainer.barPos === "bottom" ? -8 : (barContentContainer.barPos === "top" ? 8 : 0)) : 0
                    transformOrigin: {
                      if (barContentContainer.barPos === "bottom") return Item.Bottom;
                      if (barContentContainer.barPos === "left") return Item.Left;
                      if (barContentContainer.barPos === "right") return Item.Right;
                      return Item.Top;
                    }
                    scale: timeHover.hovered ? 1 : 0.96
                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    width: 280
                    height: 300
                    color: root.theme.bgSurface
                    radius: 12
                    border.color: root.theme.bgBase
                    border.width: 2

                    ColumnLayout {
                      anchors.fill: parent
                      anchors.margins: 16
                      spacing: 12

                      Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(new Date(), "MMMM yyyy")
                        color: barContentContainer.wAccent("clock", root.theme.accentPrimary)
                        font.pixelSize: 14
                        font.bold: true
                        font.family: root.font
                      }

                      DayOfWeekRow {
                        locale: Qt.locale("en_US")
                        Layout.fillWidth: true
                        delegate: Text {
                          text: model.shortName
                          color: root.theme.textSecondary
                          font.pixelSize: 12
                          font.family: root.font
                          horizontalAlignment: Text.AlignHCenter
                        }
                      }

                      MonthGrid {
                        locale: Qt.locale("en_US")
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        delegate: Item {
                          implicitWidth: 24
                          implicitHeight: 24

                          Rectangle {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            radius: 12
                            color: barContentContainer.wAccent("clock", root.theme.accentPrimary)
                            visible: model.today
                          }

                          Text {
                            anchors.centerIn: parent
                            text: model.day
                            color: model.today ? root.theme.bgBase : root.theme.textPrimary
                            font.pixelSize: 12
                            font.family: root.font
                          }
                        }
                      }
                    }
                  }
                }
              }
            }

            // 10. System Tray
            Component {
              id: trayComp
              Rectangle {
                id: trayWidget
                implicitHeight: barContentContainer.isVert ? Math.max(28, trayGrid.implicitHeight + 10) : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : Math.max(24, trayGrid.implicitWidth + 8)
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("tray", false)
                border.color: barContentContainer.wBorder("tray")
                border.width: barContentContainer.hasCustomColor("tray") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }

                Grid {
                  id: trayGrid
                  anchors.centerIn: parent
                  columns: barContentContainer.isVert ? 1 : Math.max(1, trayRepeater.count)
                  spacing: 2

                  Repeater {
                    id: trayRepeater
                    model: SystemTray.items

                    MouseArea {
                      id: trayDelegate
                      required property SystemTrayItem modelData

                      Accessible.role: Accessible.Button
                      Accessible.name: modelData.tooltipTitle || modelData.title || "System tray item"

                      width: 24
                      height: 24

                      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                      onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                          modelData.activate()
                        } else if (mouse.button === Qt.RightButton) {
                          if (modelData.hasMenu) {
                            menuAnchor.open()
                          }
                        } else if (mouse.button === Qt.MiddleButton) {
                          modelData.secondaryActivate()
                        }
                      }

                      IconImage {
                        anchors.centerIn: parent
                        source: trayDelegate.modelData.icon
                        implicitSize: 16
                      }

                      QsMenuAnchor {
                        id: menuAnchor
                        menu: trayDelegate.modelData.menu

                        anchor.window: trayDelegate.QsWindow.window
                        anchor.adjustment: PopupAdjustment.Flip
                        anchor.onAnchoring: {
                          const window = trayDelegate.QsWindow.window;
                          if (!window) return;
                          const widgetRect = window.contentItem.mapFromItem(
                            trayDelegate, 0, trayDelegate.height,
                            trayDelegate.width, trayDelegate.height);
                          menuAnchor.anchor.rect = widgetRect;
                        }
                      }
                    }
                  }
                }
              }
            }

            Component {
              id: controlCenterComp
              Rectangle {
                id: controlCenterButton
                implicitHeight: barContentContainer.isVert ? 28 : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : 28
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("controlCenter", controlCenterArea.containsMouse || controlCenter.visible)
                border.color: barContentContainer.wBorder("controlCenter")
                border.width: barContentContainer.hasCustomColor("controlCenter") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.Button
                Accessible.name: "Control Center"

                Text {
                  id: ccIcon
                  anchors.centerIn: parent
                  text: ""
                  color: (controlCenter.visible || barContentContainer.hasCustomColor("controlCenter"))
                    ? barContentContainer.wAccent("controlCenter", root.theme.accentPrimary)
                    : root.theme.textPrimary
                  font.pixelSize: 12
                  font.family: root.font
                }

                MouseArea {
                  id: controlCenterArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: controlCenter.visible = !controlCenter.visible
                }

                Rectangle {
                  anchors.fill: parent
                  radius: parent.radius
                  color: barContentContainer.wAccent("controlCenter", root.theme.accentPrimary)
                  opacity: (controlCenterArea.containsMouse || controlCenter.visible) ? 0.16 : 0.0
                  Behavior on opacity {
                    NumberAnimation { duration: 150 }
                  }
                }

                ControlCenter {
                  id: controlCenter
                  theme: root.theme
                  font: root.font
                  anchorTarget: controlCenterButton
                  barPosition: barContentContainer.barPos
                  barThickness: barInstanceScope.barThickness
                  barFloating: barInstanceScope.isFloating
                  barWindowWidth: barWindow.width
                  barWindowHeight: barWindow.height
                }
              }
            }

            // 12. Network Upload & Download Speed Pill
            Component {
              id: networkComp
              Rectangle {
                id: netPill
                implicitHeight: barContentContainer.isVert ? (netVertCol.implicitHeight + 12) : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (netRow.implicitWidth + 16)
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("network", netHover.hovered)
                border.color: barContentContainer.wBorder("network")
                border.width: barContentContainer.hasCustomColor("network") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.StaticText
                Accessible.name: "Network Speed: Down " + SystemInfo.networkDownSpeed + ", Up " + SystemInfo.networkUpSpeed

                HoverHandler { id: netHover }

                InfoPopup {
                  target: netPill
                  hovered: netHover.hovered
                  theme: root.theme
                  font: root.font
                  title: "Network (" + SystemInfo.networkInfo + ")"
                  icon: "󰓅"
                  accent: barContentContainer.wAccent("network", root.theme.accentCyan)
                  script: "net"
                  barPosition: barContentContainer.barPos
                }

                Row {
                  id: netRow
                  visible: !barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 8

                  // Download Indicator
                  Row {
                    spacing: 4
                    visible: BarConfig.showNetDown || !BarConfig.showNetUp
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: "󰇚"
                      color: barContentContainer.wAccent("network", root.theme.accentCyan ?? root.theme.accentGreen)
                      font.pixelSize: 13
                      font.family: root.font
                    }

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: BarConfig.netCompact ? SystemInfo.networkDownCompact : SystemInfo.networkDownSpeed
                      color: root.theme.textPrimary
                      font.pixelSize: 11
                      font.family: root.font
                    }
                  }

                  // Upload Indicator
                  Row {
                    spacing: 4
                    visible: BarConfig.showNetUp
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: "󰕒"
                      color: barContentContainer.wAccent("network", root.theme.accentOrange ?? root.theme.accentPrimary)
                      font.pixelSize: 13
                      font.family: root.font
                    }

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      text: BarConfig.netCompact ? SystemInfo.networkUpCompact : SystemInfo.networkUpSpeed
                      color: root.theme.textPrimary
                      font.pixelSize: 11
                      font.family: root.font
                    }
                  }
                }

                Column {
                  id: netVertCol
                  visible: barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 2

                  Text {
                    visible: BarConfig.showNetDown || !BarConfig.showNetUp
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "↓" + SystemInfo.networkDownCompact
                    color: barContentContainer.wAccent("network", root.theme.accentCyan ?? root.theme.accentGreen)
                    font.pixelSize: 9
                    font.family: root.font
                  }
                  Text {
                    visible: BarConfig.showNetUp
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "↑" + SystemInfo.networkUpCompact
                    color: barContentContainer.wAccent("network", root.theme.accentOrange ?? root.theme.accentPrimary)
                    font.pixelSize: 9
                    font.family: root.font
                  }
                }
              }
            }

            // 13. Battery Status Pill
            Component {
              id: batteryComp
              Rectangle {
                id: batPill
                implicitHeight: barContentContainer.isVert ? (batVertCol.implicitHeight + 12) : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (batContent.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("battery", false)
                border.color: barContentContainer.wBorder("battery")
                border.width: barContentContainer.hasCustomColor("battery") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.StaticText
                Accessible.name: "Battery: " + SystemInfo.batteryLevel

                Row {
                  id: batContent
                  visible: !barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 6

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: SystemInfo.batteryIcon
                    color: barContentContainer.hasCustomColor("battery")
                      ? barContentContainer.wAccent("battery", root.theme.accentPrimary)
                      : (SystemInfo.batteryCharging
                        ? root.theme.accentGreen
                        : (SystemInfo.batteryLevelRaw <= 20 ? root.theme.accentRed : root.theme.accentPrimary))
                    font.pixelSize: 13
                    font.family: root.font
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: SystemInfo.batteryLevel
                    color: root.theme.textPrimary
                    font.pixelSize: 11
                    font.family: root.font
                  }
                }

                Column {
                  id: batVertCol
                  visible: barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 2

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SystemInfo.batteryIcon
                    color: barContentContainer.hasCustomColor("battery")
                      ? barContentContainer.wAccent("battery", root.theme.accentPrimary)
                      : (SystemInfo.batteryCharging
                        ? root.theme.accentGreen
                        : (SystemInfo.batteryLevelRaw <= 20 ? root.theme.accentRed : root.theme.accentPrimary))
                    font.pixelSize: 13
                    font.family: root.font
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: SystemInfo.batteryLevel
                    color: root.theme.textPrimary
                    font.pixelSize: 9
                    font.family: root.font
                  }
                }
              }
            }

            // 14. Audio Volume Pill
            Component {
              id: volumeComp
              Rectangle {
                id: volPill
                readonly property var sinkAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
                readonly property bool isMuted: sinkAudio ? sinkAudio.muted : false
                readonly property int volPct: sinkAudio ? Math.round(sinkAudio.volume * 100) : 0

                implicitHeight: barContentContainer.isVert ? (volVertCol.implicitHeight + 12) : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (volContent.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("volume", volMouse.containsMouse)
                border.color: barContentContainer.wBorder("volume")
                border.width: barContentContainer.hasCustomColor("volume") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.Button
                Accessible.name: "Volume: " + volPct + "%"

                Row {
                  id: volContent
                  visible: !barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 6

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: volPill.isMuted ? "󰝟" : (volPill.volPct >= 60 ? "󰕾" : (volPill.volPct > 0 ? "󰖀" : "󰕿"))
                    color: volPill.isMuted
                      ? root.theme.accentRed
                      : barContentContainer.wAccent("volume", root.theme.accentPrimary)
                    font.pixelSize: 14
                    font.family: root.font
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: volPill.isMuted ? "Muted" : (volPill.volPct + "%")
                    color: root.theme.textPrimary
                    font.pixelSize: 11
                    font.family: root.font
                  }
                }

                Column {
                  id: volVertCol
                  visible: barContentContainer.isVert
                  anchors.centerIn: parent
                  spacing: 2

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: volPill.isMuted ? "󰝟" : (volPill.volPct >= 60 ? "󰕾" : (volPill.volPct > 0 ? "󰖀" : "󰕿"))
                    color: volPill.isMuted
                      ? root.theme.accentRed
                      : barContentContainer.wAccent("volume", root.theme.accentPrimary)
                    font.pixelSize: 13
                    font.family: root.font
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: volPill.isMuted ? "Mute" : (volPill.volPct + "%")
                    color: root.theme.textPrimary
                    font.pixelSize: 9
                    font.family: root.font
                  }
                }

                MouseArea {
                  id: volMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  acceptedButtons: Qt.LeftButton | Qt.RightButton
                  onClicked: (mouse) => {
                    if (volPill.sinkAudio) {
                      volPill.sinkAudio.muted = !volPill.sinkAudio.muted;
                    }
                  }
                  onWheel: (wheel) => {
                    if (volPill.sinkAudio) {
                      let step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                      volPill.sinkAudio.volume = Math.max(0.0, Math.min(1.0, volPill.sinkAudio.volume + step));
                    }
                  }
                }
              }
            }

            // 15. Media Player (MPRIS) Pill
            Component {
              id: mediaComp
              Rectangle {
                id: mediaPill
                readonly property var player: root.activePlayer
                readonly property bool hasMedia: player !== null && (player.trackTitle || player.identity)
                readonly property bool isPlaying: player !== null && player.playbackState === MprisPlaybackState.Playing

                implicitHeight: barContentContainer.isVert ? 28 : 24
                implicitWidth: barContentContainer.isVert
                  ? barContentContainer.vertPillWidth
                  : (hasMedia ? Math.min(200, mediaContent.implicitWidth + 16) : (mediaEmptyContent.implicitWidth + 14))
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("media", mediaMouse.containsMouse)
                border.color: barContentContainer.wBorder("media")
                border.width: barContentContainer.hasCustomColor("media") ? 1 : 0
                clip: true
                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                  id: mediaContent
                  visible: !barContentContainer.isVert && mediaPill.hasMedia
                  anchors.centerIn: parent
                  spacing: 6

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: mediaPill.isPlaying ? "󰏤" : "󰐊"
                    color: barContentContainer.wAccent("media", root.theme.accentPrimary)
                    font.pixelSize: 13
                    font.family: root.font
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: mediaPill.player ? (mediaPill.player.trackTitle || mediaPill.player.identity || "Media") : ""
                    color: root.theme.textPrimary
                    font.pixelSize: 11
                    font.family: root.font
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, 160)
                  }
                }

                Row {
                  id: mediaEmptyContent
                  visible: !barContentContainer.isVert && !mediaPill.hasMedia
                  anchors.centerIn: parent
                  spacing: 6

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰎆"
                    color: barContentContainer.hasCustomColor("media")
                      ? barContentContainer.wAccent("media", root.theme.textMuted)
                      : root.theme.textMuted
                    font.pixelSize: 13
                    font.family: root.font
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "No Media"
                    color: root.theme.textMuted
                    font.pixelSize: 11
                    font.family: root.font
                  }
                }

                Text {
                  visible: barContentContainer.isVert
                  anchors.centerIn: parent
                  text: mediaPill.hasMedia ? (mediaPill.isPlaying ? "󰏤" : "󰐊") : "󰎆"
                  color: (mediaPill.hasMedia || barContentContainer.hasCustomColor("media"))
                    ? barContentContainer.wAccent("media", root.theme.accentPrimary)
                    : root.theme.textMuted
                  font.pixelSize: 13
                  font.family: root.font
                }

                MouseArea {
                  id: mediaMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                  onClicked: (mouse) => {
                    if (!mediaPill.player) return;
                    if (mouse.button === Qt.LeftButton) mediaPill.player.togglePlaying();
                    else if (mouse.button === Qt.RightButton) mediaPill.player.next();
                    else if (mouse.button === Qt.MiddleButton) mediaPill.player.previous();
                  }
                }
              }
            }

            // 16. Idle Inhibitor (Caffeine) Pill
            Component {
              id: idleInhibitorComp
              Rectangle {
                id: idlePill
                readonly property bool isActive: SystemInfo.idleInhibited

                implicitHeight: barContentContainer.isVert ? 28 : 24
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : 28
                height: implicitHeight
                width: implicitWidth
                radius: 10
                color: barContentContainer.wBg("idleInhibitor", idleMouse.containsMouse || idlePill.isActive)
                border.color: idlePill.isActive
                  ? barContentContainer.wAccent("idleInhibitor", root.theme.accentOrange ?? root.theme.accentPrimary)
                  : barContentContainer.wBorder("idleInhibitor")
                border.width: (idlePill.isActive || barContentContainer.hasCustomColor("idleInhibitor")) ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.Button
                Accessible.name: idlePill.isActive ? "Idle Inhibitor: Active" : "Idle Inhibitor: Inactive"

                Rectangle {
                  anchors.fill: parent
                  radius: parent.radius
                  color: barContentContainer.wAccent("idleInhibitor", root.theme.accentOrange ?? root.theme.accentPrimary)
                  opacity: idlePill.isActive ? 0.18 : (idleMouse.containsMouse ? 0.12 : 0.0)
                  Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Text {
                  anchors.centerIn: parent
                  text: idlePill.isActive ? "" : ""
                  color: idlePill.isActive
                    ? barContentContainer.wAccent("idleInhibitor", root.theme.accentOrange ?? root.theme.accentPrimary)
                    : (barContentContainer.hasCustomColor("idleInhibitor")
                      ? barContentContainer.wAccent("idleInhibitor", root.theme.textPrimary)
                      : root.theme.textPrimary)
                  font.pixelSize: 13
                  font.family: root.font
                }

                MouseArea {
                  id: idleMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: SystemInfo.toggleIdleInhibitor()
                }
              }
            }

            // Widget component resolver
            function getWidgetComponent(widgetId) {
              switch (widgetId) {
                case "appGrid": return appGridComp;
                case "cpu": return cpuComp;
                case "temp": return tempComp;
                case "memory": return memoryComp;
                case "disk": return diskComp;
                case "network": return networkComp;
                case "battery": return batteryComp;
                case "volume": return volumeComp;
                case "media": return mediaComp;
                case "idleInhibitor": return idleInhibitorComp;
                case "windowTitle": return windowTitleComp;
                case "workspaces": return workspacesComp;
                case "weather": return weatherComp;
                case "clock": return clockComp;
                case "tray": return trayComp;
                case "controlCenter": return controlCenterComp;
                default: return null;
              }
            }

            // Dynamic Panel Section Layouts (Supports Horizontal Top/Bottom and Vertical Left/Right)
            Repeater {
              model: barInstanceScope.barPanels

              Grid {
                id: panelSectionGrid
                required property var modelData
                required property int index

                readonly property int totalPanels: barInstanceScope.barPanels.length
                columns: barContentContainer.isVert ? 1 : Math.max(1, sectionWidgetRepeater.count)
                spacing: barContentContainer.isVert ? 6 : 8
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter

                x: {
                  if (barContentContainer.isVert) {
                    return Math.max(0, (barContentContainer.width - width) / 2);
                  }
                  if (totalPanels <= 1) return 0;
                  if (index === 0) return 0;
                  if (index === totalPanels - 1) return Math.max(0, barContentContainer.width - width);
                  const frac = index / (totalPanels - 1);
                  return Math.max(0, Math.min(barContentContainer.width - width, (barContentContainer.width * frac) - (width / 2)));
                }

                y: {
                  if (!barContentContainer.isVert) {
                    return Math.max(0, (barContentContainer.height - height) / 2);
                  }
                  if (totalPanels <= 1) return 0;
                  if (index === 0) return 0;
                  if (index === totalPanels - 1) return Math.max(0, barContentContainer.height - height);
                  const frac = index / (totalPanels - 1);
                  return Math.max(0, Math.min(barContentContainer.height - height, (barContentContainer.height * frac) - (height / 2)));
                }

                Repeater {
                  id: sectionWidgetRepeater
                  model: panelSectionGrid.modelData
                  delegate: Loader {
                    id: panelWidgetLoader
                    required property string modelData
                    readonly property string barId: (barInstanceScope.barCfg && barInstanceScope.barCfg.id) ? String(barInstanceScope.barCfg.id) : "bar_1"
                    active: BarConfig.isWidgetVisible(modelData, barId)
                    sourceComponent: barContentContainer.getWidgetComponent(modelData)
                    visible: active && sourceComponent !== null
                    width: visible ? (item ? (item.implicitWidth > 0 ? item.implicitWidth : item.width) : 0) : 0
                    height: visible ? (item ? (item.implicitHeight > 0 ? item.implicitHeight : item.height) : 24) : 0
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
