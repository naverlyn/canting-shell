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
import "./Widgets"

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "Hack Nerd Font"
  property bool barVisible: true

  function withAlpha(col, alpha) {
    if (!col) return Qt.rgba(0, 0, 0, alpha);
    const c = Qt.color(col);
    return Qt.rgba(c.r, c.g, c.b, alpha);
  }

  function resolveThemeSpec(spec, fallbackColor) {
    if (!spec || String(spec).trim() === "") return fallbackColor !== undefined ? fallbackColor : root.theme.bgBase;
    const s = String(spec).trim();
    try {
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
    return fallbackColor !== undefined ? fallbackColor : root.theme.bgBase;
  }

  function isDockedBarActive(pos, currentBarId, screenIdx) {
    const list = BarConfig.bars || [];
    for (let i = 0; i < list.length; i++) {
      const b = list[i];
      if (!b || b.enabled === false) continue;
      const bid = (b.id !== undefined && b.id !== null) ? String(b.id) : ("bar_" + (i + 1));
      if (currentBarId && bid === currentBarId) continue;
      if (screenIdx !== undefined) {
        const isPrim = (screenIdx === 0);
        const scr = (Quickshell.screens && Quickshell.screens.length > screenIdx) ? Quickshell.screens[screenIdx] : null;
        const scrName = (scr && scr.name) ? String(scr.name) : ("screen_" + screenIdx);
        const bTarget = b.displayTarget || (b.allMonitors ? "all" : "primary");
        if (bTarget === "primary" && !isPrim) continue;
        if (bTarget === "secondary" && isPrim) continue;
        if (bTarget !== "all" && bTarget !== "primary" && bTarget !== "secondary" && bTarget !== scrName) continue;
        const effectivePos = (!isPrim && bTarget === "all" && b.secondaryPosition) ? b.secondaryPosition : (b.position || "top");
        if (effectivePos === pos && !Boolean(b.floating)) {
          return true;
        }
        continue;
      }
      if ((b.position || "top") === pos && !Boolean(b.floating)) {
        return true;
      }
    }
    return false;
  }

  function getDockedBarThickness(pos, currentBarId, screenIdx) {
    const list = BarConfig.bars || [];
    for (let i = 0; i < list.length; i++) {
      const b = list[i];
      if (!b || b.enabled === false) continue;
      const bid = (b.id !== undefined && b.id !== null) ? String(b.id) : ("bar_" + (i + 1));
      if (currentBarId && bid === currentBarId) continue;
      if (screenIdx !== undefined) {
        const isPrim = (screenIdx === 0);
        const scr = (Quickshell.screens && Quickshell.screens.length > screenIdx) ? Quickshell.screens[screenIdx] : null;
        const scrName = (scr && scr.name) ? String(scr.name) : ("screen_" + screenIdx);
        const bTarget = b.displayTarget || (b.allMonitors ? "all" : "primary");
        if (bTarget === "primary" && !isPrim) continue;
        if (bTarget === "secondary" && isPrim) continue;
        if (bTarget !== "all" && bTarget !== "primary" && bTarget !== "secondary" && bTarget !== scrName) continue;
        const effectivePos = (!isPrim && bTarget === "all" && b.secondaryPosition) ? b.secondaryPosition : (b.position || "top");
        if (effectivePos === pos && !Boolean(b.floating)) {
          return b.barHeight || 32;
        }
        continue;
      }
      if ((b.position || "top") === pos && !Boolean(b.floating)) {
        return b.barHeight || 32;
      }
    }
    return 0;
  }

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
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
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
    command: ["brightnessctl", "-c", "backlight", "get"]
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
      readonly property int pillRadius: (barCfg.pillRadius !== undefined) ? Number(barCfg.pillRadius) : BarConfig.pillRadius
      readonly property real pillOpacity: (barCfg.pillOpacity !== undefined) ? Number(barCfg.pillOpacity) : BarConfig.pillOpacity
      readonly property bool hidePill: (barCfg.hidePill !== undefined) ? Boolean(barCfg.hidePill) : BarConfig.hidePill
      readonly property var barPanels: barCfg.panels || []
      readonly property bool hasInnerCorners: (barCfg.innerCorners !== undefined ? Boolean(barCfg.innerCorners) : Boolean(BarConfig.innerCorners)) && !barInstanceScope.isFloating
      readonly property int innerCornerRadius: 16
      readonly property string activeStyle: (barCfg.activeStyle !== undefined) ? String(barCfg.activeStyle) : (BarConfig.activeStyle || "pill")
      readonly property string barColorSpec: (barCfg.barColor !== undefined) ? String(barCfg.barColor) : (BarConfig.barColor || "")
      readonly property color resolvedBarColor: {
        const c = root.resolveThemeSpec(barColorSpec, root.theme.bgBase);
        return c ? c : root.theme.bgBase;
      }

      readonly property string displayTarget: (barCfg.displayTarget !== undefined && String(barCfg.displayTarget).trim() !== "") ? String(barCfg.displayTarget).trim() : (Boolean(barCfg.allMonitors) ? "all" : "primary")
      readonly property string secondaryMode: (barCfg.secondaryMode !== undefined && String(barCfg.secondaryMode).trim() !== "") ? String(barCfg.secondaryMode).trim() : (barCfg.blankOnSecondary ? "blank" : "custom")
      readonly property bool blankOnSecondary: (barCfg.blankOnSecondary !== undefined) ? Boolean(barCfg.blankOnSecondary) : (secondaryMode === "blank")
      readonly property var secondaryPanels: (barCfg.secondaryPanels && barCfg.secondaryPanels.length > 0) ? barCfg.secondaryPanels : BarConfig.defaultSecondaryPanels

      readonly property string currentBarId: (barCfg.id !== undefined && barCfg.id !== null) ? String(barCfg.id) : ""
      readonly property bool hasDockedTop: root.isDockedBarActive("top", currentBarId)
      readonly property bool hasDockedBottom: root.isDockedBarActive("bottom", currentBarId)
      readonly property bool hasDockedLeft: root.isDockedBarActive("left", currentBarId)
      readonly property bool hasDockedRight: root.isDockedBarActive("right", currentBarId)

      readonly property int dockedTopH: root.getDockedBarThickness("top", currentBarId)
      readonly property int dockedBottomH: root.getDockedBarThickness("bottom", currentBarId)
      readonly property int dockedLeftW: root.getDockedBarThickness("left", currentBarId)
      readonly property int dockedRightW: root.getDockedBarThickness("right", currentBarId)

      Variants {
        model: Quickshell.screens

        PanelWindow {
          id: barWindow
          required property var modelData
          screen: modelData

          readonly property int screenIndex: {
            const screens = Quickshell.screens || [];
            if (!modelData) return 0;
            for (let i = 0; i < screens.length; i++) {
              if (screens[i] === modelData || (screens[i] && screens[i].name && modelData.name && screens[i].name === modelData.name)) return i;
            }
            return 0;
          }
          readonly property bool isPrimaryScreen: screenIndex === 0
          readonly property bool isSecondaryScreen: screenIndex > 0
          readonly property string screenName: (modelData && modelData.name) ? String(modelData.name) : ("Display " + (screenIndex + 1))

          readonly property bool hasDockedTop: root.isDockedBarActive("top", barInstanceScope.currentBarId, screenIndex)
          readonly property bool hasDockedBottom: root.isDockedBarActive("bottom", barInstanceScope.currentBarId, screenIndex)
          readonly property bool hasDockedLeft: root.isDockedBarActive("left", barInstanceScope.currentBarId, screenIndex)
          readonly property bool hasDockedRight: root.isDockedBarActive("right", barInstanceScope.currentBarId, screenIndex)

          readonly property int dockedTopH: root.getDockedBarThickness("top", barInstanceScope.currentBarId, screenIndex)
          readonly property int dockedBottomH: root.getDockedBarThickness("bottom", barInstanceScope.currentBarId, screenIndex)
          readonly property int dockedLeftW: root.getDockedBarThickness("left", barInstanceScope.currentBarId, screenIndex)
          readonly property int dockedRightW: root.getDockedBarThickness("right", barInstanceScope.currentBarId, screenIndex)

          readonly property int effectiveDockedLeft: barWindow.hasDockedLeft
            ? barWindow.dockedLeftW
            : (BarConfig.screenBorder ? BarConfig.screenBorderThickness : 0)
          readonly property int effectiveDockedRight: barWindow.hasDockedRight
            ? barWindow.dockedRightW
            : (BarConfig.screenBorder ? BarConfig.screenBorderThickness : 0)
          readonly property int effectiveDockedTop: barWindow.hasDockedTop
            ? barWindow.dockedTopH
            : (BarConfig.screenBorder ? BarConfig.screenBorderThickness : 0)
          readonly property int effectiveDockedBottom: barWindow.hasDockedBottom
            ? barWindow.dockedBottomH
            : (BarConfig.screenBorder ? BarConfig.screenBorderThickness : 0)

          readonly property int horizontalShrink: (barWindow.screen && barWindow.width > 0 && barWindow.width < barWindow.screen.width)
            ? Math.max(0, barWindow.screen.width - barWindow.width)
            : 0
          readonly property int verticalShrink: (barWindow.screen && barWindow.height > 0 && barWindow.height < barWindow.screen.height)
            ? Math.max(0, barWindow.screen.height - barWindow.height)
            : 0

          readonly property bool hasEffectiveInnerCorners: false

          readonly property string target: barInstanceScope.displayTarget
          readonly property string secMode: barInstanceScope.secondaryMode
          readonly property bool blankSec: barInstanceScope.blankOnSecondary

          readonly property bool isScreenTargeted: {
            if (target === "all") {
              if (isPrimaryScreen) return true;
              return secMode !== "none";
            }
            if (target === "primary") return isPrimaryScreen;
            if (target === "secondary") return (Quickshell.screens && Quickshell.screens.length > 1) ? isSecondaryScreen : isPrimaryScreen;
            if (target === screenName || target === ("screen_" + screenIndex)) return true;
            return false;
          }

          readonly property bool isBlankBar: isSecondaryScreen && (target === "all") && (secMode === "blank" || blankSec)
          readonly property var effectivePanels: (isSecondaryScreen && target === "all" && secMode === "custom")
            ? barInstanceScope.secondaryPanels
            : barInstanceScope.barPanels

          readonly property string windowBarPos: (isSecondaryScreen && target === "all" && barInstanceScope.barCfg.secondaryPosition)
            ? barInstanceScope.barCfg.secondaryPosition
            : barInstanceScope.barPos
          readonly property bool windowIsVert: windowBarPos === "left" || windowBarPos === "right"

          visible: root.barVisible && Boolean(barInstanceScope.barCfg.enabled) && isScreenTargeted

          anchors {
            top: barWindow.windowBarPos === "top" || barWindow.windowIsVert
            bottom: barWindow.windowBarPos === "bottom" || barWindow.windowIsVert
            left: barWindow.windowBarPos === "left" || !barWindow.windowIsVert
            right: barWindow.windowBarPos === "right" || !barWindow.windowIsVert
          }

          exclusiveZone: barInstanceScope.barThickness + (barInstanceScope.isFloating ? 12 : 0)

          implicitHeight: barWindow.windowIsVert ? 0 : (barInstanceScope.barThickness + (barInstanceScope.isFloating ? 12 : 0))
          implicitWidth: barWindow.windowIsVert ? (barInstanceScope.barThickness + (barInstanceScope.isFloating ? 12 : 0)) : 0
          color: "transparent"

          property string lastPos: barWindow.windowBarPos
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
              from: barWindow.windowBarPos === "left" ? -14 : (barWindow.windowBarPos === "right" ? 14 : 0)
              to: 0
              duration: 240
              easing.type: Easing.OutCubic
            }
            NumberAnimation {
              target: barSlideTransform
              property: "y"
              from: barWindow.windowBarPos === "top" ? -14 : (barWindow.windowBarPos === "bottom" ? 14 : 0)
              to: 0
              duration: 240
              easing.type: Easing.OutCubic
            }
          }

          Rectangle {
            id: barBackground
            anchors.fill: parent
            anchors.topMargin: barInstanceScope.isFloating
              ? (barWindow.windowIsVert ? 12 : (barWindow.windowBarPos === "top" ? 6 : 0))
              : (barWindow.windowIsVert
                ? 0
                : ((barWindow.hasEffectiveInnerCorners && barWindow.windowBarPos === "bottom") ? barInstanceScope.innerCornerRadius : 0))
            anchors.bottomMargin: barInstanceScope.isFloating
              ? (barWindow.windowIsVert ? 12 : (barWindow.windowBarPos === "bottom" ? 6 : 0))
              : (barWindow.windowIsVert
                ? 0
                : ((barWindow.hasEffectiveInnerCorners && barWindow.windowBarPos === "top") ? barInstanceScope.innerCornerRadius : 0))
            anchors.leftMargin: barInstanceScope.isFloating
              ? (!barWindow.windowIsVert ? 12 : (barWindow.windowBarPos === "left" ? 6 : 0))
              : (barWindow.windowIsVert
                ? ((barWindow.hasEffectiveInnerCorners && barWindow.windowBarPos === "right") ? barInstanceScope.innerCornerRadius : 0)
                : 0)
            anchors.rightMargin: barInstanceScope.isFloating
              ? (!barWindow.windowIsVert ? 12 : (barWindow.windowBarPos === "right" ? 6 : 0))
              : (barWindow.windowIsVert
                ? ((barWindow.hasEffectiveInnerCorners && barWindow.windowBarPos === "left") ? barInstanceScope.innerCornerRadius : 0)
                : 0)
            radius: barInstanceScope.isFloating ? 12 : 0
            color: Qt.rgba(barInstanceScope.resolvedBarColor.r, barInstanceScope.resolvedBarColor.g, barInstanceScope.resolvedBarColor.b, barInstanceScope.barAlpha)
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
            visible: !barWindow.isBlankBar && barInstanceScope.barThickness >= 18
            anchors.leftMargin: barWindow.windowIsVert
              ? 4
              : (Math.max(0, barWindow.effectiveDockedLeft - Math.round(barWindow.horizontalShrink / 2)) + (barInstanceScope.hasInnerCorners ? (barInstanceScope.innerCornerRadius + 6) : 10))
            anchors.rightMargin: barWindow.windowIsVert
              ? 4
              : (Math.max(0, barWindow.effectiveDockedRight - Math.round(barWindow.horizontalShrink / 2)) + (barInstanceScope.hasInnerCorners ? (barInstanceScope.innerCornerRadius + 6) : 10))
            anchors.topMargin: barWindow.windowIsVert
              ? (Math.max(0, barWindow.effectiveDockedTop - Math.round(barWindow.verticalShrink / 2)) + (barWindow.hasDockedTop ? 6 : (barInstanceScope.hasInnerCorners ? (barInstanceScope.innerCornerRadius + 6) : 10)))
              : 0
            anchors.bottomMargin: barWindow.windowIsVert
              ? (Math.max(0, barWindow.effectiveDockedBottom - Math.round(barWindow.verticalShrink / 2)) + (barWindow.hasDockedBottom ? 6 : (barInstanceScope.hasInnerCorners ? (barInstanceScope.innerCornerRadius + 6) : 10)))
              : 0
            transform: Translate { x: barSlideTransform.x; y: barSlideTransform.y }

            readonly property var effectivePanels: barWindow.effectivePanels
            readonly property bool isVert: barWindow.windowIsVert
            readonly property string barPos: barWindow.windowBarPos
            readonly property int vertPillWidth: Math.max(16, barBackground.width - 8)
            readonly property int pillRadius: barInstanceScope.pillRadius
            readonly property real pillOpacity: barInstanceScope.pillOpacity
            readonly property bool hidePill: barInstanceScope.hidePill
            readonly property string activeStyle: barInstanceScope.activeStyle
            readonly property string barColorSpec: barInstanceScope.barColorSpec
            readonly property int barThickness: barInstanceScope.barThickness
            readonly property bool isFloating: barInstanceScope.isFloating
            readonly property bool hasInnerCorners: barInstanceScope.hasInnerCorners
            readonly property int innerCornerRadius: barInstanceScope.innerCornerRadius
            readonly property color barColor: barBackground.color
            readonly property int vHitPadding: Math.max(0, Math.floor((barContentContainer.height - 24) / 2))
            readonly property int hHitPadding: barWindow.windowIsVert ? Math.max(0, Math.floor((barContentContainer.width - vertPillWidth) / 2)) : 4

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
              if (barContentContainer.activeStyle === "underline") {
                return "transparent";
              }
              if (barContentContainer.hidePill) {
                return isHovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14) : "transparent";
              }
              const base = isHovered ? root.theme.bgHover : root.theme.bgSurface;
              const alpha = isHovered
                ? Math.max(0.18, Math.min(1.0, barContentContainer.pillOpacity))
                : Math.max(0.0, Math.min(1.0, barContentContainer.pillOpacity));
              try {
                const baseRgb = _toRgb(base);
                const resolved = resolveThemeSpec(wSpec(widgetId));
                if (resolved === "") {
                  return baseRgb ? Qt.rgba(baseRgb.r, baseRgb.g, baseRgb.b, alpha) : base;
                }
                const rgb = _toRgb(resolved);
                if (!rgb || !baseRgb) return baseRgb ? Qt.rgba(baseRgb.r, baseRgb.g, baseRgb.b, alpha) : base;
                const mix = isHovered ? 0.24 : 0.15;
                return Qt.rgba(
                  baseRgb.r * (1 - mix) + rgb.r * mix,
                  baseRgb.g * (1 - mix) + rgb.g * mix,
                  baseRgb.b * (1 - mix) + rgb.b * mix,
                  alpha
                );
              } catch (e) {
                return base;
              }
            }

            function wBorder(widgetId) {
              if (barContentContainer.activeStyle === "underline" || barContentContainer.hidePill) return "transparent";
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

            // Universal Pill Indicator (Supports Pill, Line, and Both active/hover styles)

            // Widget building blocks

            // 1. Applications Launcher Button
            Component {
              id: appGridComp
              AppLauncherButton {
                hostRoot: root
                hostContainer: barContentContainer
                hostWindow: barWindow
                hostScope: barInstanceScope
              }
            }

            // 2. CPU Usage Pill
            Component {
              id: cpuComp
              CpuUsagePill {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // 3. CPU Temperature Pill
            Component {
              id: tempComp
              CpuTemperaturePill {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // 4. Memory (RAM) Pill
            Component {
              id: memoryComp
              MemoryUsagePill {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // 5. Disk Usage Pill
            Component {
              id: diskComp
              DiskUsagePill {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // 6. Active Window Title
            Component {
              id: windowTitleComp
              WindowTitleLabel {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // Global Menu (AppMenu / Menu Title)
            Component {
              id: globalMenuComp
              GlobalMenu {
                barContainer: barContentContainer
                theme: root.theme
                font: root.font
              }
            }

            Component {
              id: workspacesComp
              WorkspacesWidget {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // 8. Weather Info Pill
            Component {
              id: weatherComp
              WeatherPill {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // 9. Clock & Calendar Popup
            Component {
              id: clockComp
              ClockCalendarPill {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // 10. System Tray
            Component {
              id: trayComp
              SystemTrayWidget {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            Component {
              id: controlCenterComp
              ControlCenterButton {
                hostRoot: root
                hostContainer: barContentContainer
                hostWindow: barWindow
                hostScope: barInstanceScope
              }
            }

            // 12. Network Upload & Download Speed Pill
            Component {
              id: networkComp
              NetworkSpeedPill {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // 13. Battery Status Pill
            Component {
              id: batteryComp
              BatteryPill {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // 14. Audio Volume Pill
            Component {
              id: volumeComp
              VolumePill {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // 15. Media Player (MPRIS) Pill
            Component {
              id: mediaComp
              MediaPlayerPill {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // 16. Idle Inhibitor (Caffeine) Pill
            Component {
              id: idleInhibitorComp
              IdleInhibitorButton {
                hostRoot: root
                hostContainer: barContentContainer
              }
            }

            // 17. Cava Audio Spectrum Visualizer Pill
            Component {
              id: cavaComp
              CavaVisualizerPill {
                hostRoot: root
                hostContainer: barContentContainer
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
                case "cava": return cavaComp;
                case "idleInhibitor": return idleInhibitorComp;
                case "windowTitle": return windowTitleComp;
                case "globalMenu": return globalMenuComp;
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
              id: panelsOuterRepeater
              model: barWindow.effectivePanels

              Grid {
                id: panelSectionGrid
                required property var modelData
                required property int index

                readonly property int totalPanels: barWindow.effectivePanels.length
                columns: barContentContainer.isVert ? 1 : Math.max(1, sectionWidgetRepeater.count)
                spacing: barContentContainer.isVert ? 6 : 8
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter

                height: barContentContainer.isVert ? implicitHeight : barContentContainer.height
                width: barContentContainer.isVert ? barContentContainer.width : implicitWidth

                x: {
                  if (barContentContainer.isVert) return 0;
                  if (totalPanels <= 1) return 0;
                  if (index === 0) return 0;
                  if (index === totalPanels - 1) return Math.max(0, barContentContainer.width - width);
                  const frac = index / (totalPanels - 1);
                  return Math.max(0, Math.min(barContentContainer.width - width, (barContentContainer.width * frac) - (width / 2)));
                }

                y: {
                  if (!barContentContainer.isVert) return 0;
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
                    active: !barWindow.isBlankBar && BarConfig.isWidgetVisible(modelData, barId)
                    sourceComponent: barContentContainer.getWidgetComponent(modelData)
                    visible: active && sourceComponent !== null
                    width: visible ? (barContentContainer.isVert ? barContentContainer.width : (item ? (item.implicitWidth > 0 ? item.implicitWidth : item.width) : 0)) : 0
                    height: visible ? (barContentContainer.isVert ? (item ? (item.implicitHeight > 0 ? item.implicitHeight : item.height) : 28) : barContentContainer.height) : 0
                  }
                }
              }
            }

            Connections {
              target: BarConfig
              function onPanelsUpdated() {
                const bId = (barInstanceScope.barCfg && barInstanceScope.barCfg.id) ? String(barInstanceScope.barCfg.id) : "bar_1";
                let matchedPanels = [];
                if (BarConfig.bars) {
                  for (let i = 0; i < BarConfig.bars.length; i++) {
                    if (BarConfig.bars[i] && BarConfig.bars[i].id === bId) {
                      matchedPanels = BarConfig.bars[i].panels || [];
                      break;
                    }
                  }
                }
                panelsOuterRepeater.model = null;
                panelsOuterRepeater.model = matchedPanels;
              }
            }
          }

        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    ScreenBorder {
      required property var modelData
      screen: modelData
      screenIndex: {
        const screens = Quickshell.screens || [];
        if (!modelData) return 0;
        for (let i = 0; i < screens.length; i++) {
          if (screens[i] === modelData) return i;
        }
        return 0;
      }
      barRoot: root
    }
  }
}
