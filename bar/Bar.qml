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

  component InnerCorner: Canvas {
    id: cornerCanvas
    property color cornerColor: "black"
    property string cornerPosition: "top-left"
    antialiasing: true

    onCornerColorChanged: requestPaint()
    onCornerPositionChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
      const ctx = getContext("2d");
      const w = width;
      const h = height;
      if (w <= 0 || h <= 0) return;
      ctx.clearRect(0, 0, w, h);

      ctx.fillStyle = cornerCanvas.cornerColor;
      ctx.beginPath();

      if (cornerPosition === "top-left") {
        ctx.moveTo(w, 0);
        ctx.arcTo(0, 0, 0, h, Math.min(w, h));
        ctx.lineTo(0, 0);
      } else if (cornerPosition === "top-right") {
        ctx.moveTo(0, 0);
        ctx.arcTo(w, 0, w, h, Math.min(w, h));
        ctx.lineTo(w, 0);
      } else if (cornerPosition === "bottom-left") {
        ctx.moveTo(w, h);
        ctx.arcTo(0, h, 0, 0, Math.min(w, h));
        ctx.lineTo(0, h);
      } else if (cornerPosition === "bottom-right") {
        ctx.moveTo(0, h);
        ctx.arcTo(w, h, w, 0, Math.min(w, h));
        ctx.lineTo(w, h);
      }

      ctx.closePath();
      ctx.fill();
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

          readonly property int effectiveDockedLeft: (barWindow.screen && barWindow.width > 0 && barWindow.width < barWindow.screen.width)
            ? 0
            : (barWindow.hasDockedLeft ? barWindow.dockedLeftW : 0)
          readonly property int effectiveDockedRight: (barWindow.screen && barWindow.width > 0 && barWindow.width < barWindow.screen.width)
            ? 0
            : (barWindow.hasDockedRight ? barWindow.dockedRightW : 0)
          readonly property int effectiveDockedTop: (barWindow.screen && barWindow.height > 0 && barWindow.height < barWindow.screen.height)
            ? 0
            : (barWindow.hasDockedTop ? barWindow.dockedTopH : 0)
          readonly property int effectiveDockedBottom: (barWindow.screen && barWindow.height > 0 && barWindow.height < barWindow.screen.height)
            ? 0
            : (barWindow.hasDockedBottom ? barWindow.dockedBottomH : 0)

          readonly property bool hasEffectiveInnerCorners: barInstanceScope.hasInnerCorners && (
            barWindow.windowIsVert
              ? (!barWindow.hasDockedTop || !barWindow.hasDockedBottom)
              : true
          )

          readonly property string target: barInstanceScope.displayTarget
          readonly property string secMode: barInstanceScope.secondaryMode
          readonly property bool blankSec: barInstanceScope.blankOnSecondary

          readonly property bool isScreenTargeted: {
            if (target === "all") {
              if (isPrimaryScreen) return true;
              return secMode !== "none";
            }
            if (target === "primary") return isPrimaryScreen;
            if (target === "secondary") return isSecondaryScreen;
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

          implicitHeight: barWindow.windowIsVert ? 0 : (barInstanceScope.barThickness + (barInstanceScope.isFloating ? 12 : (barWindow.hasEffectiveInnerCorners ? barInstanceScope.innerCornerRadius : 0)))
          implicitWidth: barWindow.windowIsVert ? (barInstanceScope.barThickness + (barInstanceScope.isFloating ? 12 : (barWindow.hasEffectiveInnerCorners ? barInstanceScope.innerCornerRadius : 0))) : 0
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

          InnerCorner {
            id: corner1
            visible: barInstanceScope.hasInnerCorners && (
              barWindow.windowIsVert ? !barWindow.hasDockedTop : true
            )
            width: barInstanceScope.hasInnerCorners ? barInstanceScope.innerCornerRadius : 0
            height: barInstanceScope.hasInnerCorners ? barInstanceScope.innerCornerRadius : 0
            cornerColor: barBackground.color
            opacity: barBackground.opacity
            transform: Translate { x: barSlideTransform.x; y: barSlideTransform.y }

            anchors.left: barWindow.windowIsVert
              ? (barWindow.windowBarPos === "left" ? barBackground.right : undefined)
              : barBackground.left
            anchors.leftMargin: barWindow.windowIsVert ? 0 : barWindow.effectiveDockedLeft
            anchors.right: barWindow.windowIsVert
              ? (barWindow.windowBarPos === "right" ? barBackground.left : undefined)
              : undefined
            anchors.top: barWindow.windowIsVert
              ? barBackground.top
              : (barWindow.windowBarPos === "top" ? barBackground.bottom : undefined)
            anchors.bottom: barWindow.windowIsVert
              ? undefined
              : (barWindow.windowBarPos === "bottom" ? barBackground.top : undefined)

            cornerPosition: barWindow.windowIsVert
              ? (barWindow.windowBarPos === "left" ? "top-left" : "top-right")
              : (barWindow.windowBarPos === "top" ? "top-left" : "bottom-left")
          }

          InnerCorner {
            id: corner2
            visible: barInstanceScope.hasInnerCorners && (
              barWindow.windowIsVert ? !barWindow.hasDockedBottom : true
            )
            width: barInstanceScope.hasInnerCorners ? barInstanceScope.innerCornerRadius : 0
            height: barInstanceScope.hasInnerCorners ? barInstanceScope.innerCornerRadius : 0
            cornerColor: barBackground.color
            opacity: barBackground.opacity
            transform: Translate { x: barSlideTransform.x; y: barSlideTransform.y }

            anchors.left: barWindow.windowIsVert
              ? (barWindow.windowBarPos === "left" ? barBackground.right : undefined)
              : undefined
            anchors.right: barWindow.windowIsVert
              ? (barWindow.windowBarPos === "right" ? barBackground.left : undefined)
              : barBackground.right
            anchors.rightMargin: barWindow.windowIsVert ? 0 : barWindow.effectiveDockedRight
            anchors.top: barWindow.windowIsVert
              ? undefined
              : (barWindow.windowBarPos === "top" ? barBackground.bottom : undefined)
            anchors.bottom: barWindow.windowIsVert
              ? barBackground.bottom
              : (barWindow.windowBarPos === "bottom" ? barBackground.top : undefined)

            cornerPosition: barWindow.windowIsVert
              ? (barWindow.windowBarPos === "left" ? "bottom-left" : "bottom-right")
              : (barWindow.windowBarPos === "top" ? "top-right" : "bottom-right")
          }

          Item {
            id: barContentContainer
            anchors.fill: barBackground
            visible: !barWindow.isBlankBar
            anchors.leftMargin: barWindow.windowIsVert
              ? 4
              : (barWindow.effectiveDockedLeft + (barInstanceScope.hasInnerCorners ? (barInstanceScope.innerCornerRadius + 6) : 10))
            anchors.rightMargin: barWindow.windowIsVert
              ? 4
              : (barWindow.effectiveDockedRight + (barInstanceScope.hasInnerCorners ? (barInstanceScope.innerCornerRadius + 6) : 10))
            anchors.topMargin: barWindow.windowIsVert
              ? (barWindow.effectiveDockedTop + (barWindow.hasDockedTop ? 6 : (barInstanceScope.hasInnerCorners ? (barInstanceScope.innerCornerRadius + 6) : 10)))
              : 0
            anchors.bottomMargin: barWindow.windowIsVert
              ? (barWindow.effectiveDockedBottom + (barWindow.hasDockedBottom ? 6 : (barInstanceScope.hasInnerCorners ? (barInstanceScope.innerCornerRadius + 6) : 10)))
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
            component PillIndicator: Item {
              id: indRoot
              anchors.fill: parent
              property bool active: false
              property bool hovered: false
              property color accentColor: root.theme.accentPrimary

              // Active indicator underline (horizontal bar)
              Rectangle {
                visible: (barContentContainer.activeStyle === "underline" || barContentContainer.activeStyle === "both") && !barContentContainer.isVert
                anchors.bottom: parent.bottom
                anchors.bottomMargin: barContentContainer.hidePill ? 2 : 1
                anchors.horizontalCenter: parent.horizontalCenter
                width: (indRoot.active || indRoot.hovered) ? Math.max(8, parent.width - 8) : 0
                height: 2
                radius: 1
                color: indRoot.active ? indRoot.accentColor : root.theme.textMuted
                opacity: indRoot.active ? 1.0 : (indRoot.hovered ? 0.9 : 0.0)
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }
              }

              // Active indicator vertical bar line (vertical bar)
              Rectangle {
                visible: (barContentContainer.activeStyle === "underline" || barContentContainer.activeStyle === "both") && barContentContainer.isVert
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: barContentContainer.barPos === "right" ? parent.left : undefined
                anchors.right: barContentContainer.barPos === "left" ? parent.right : undefined
                anchors.leftMargin: 1
                anchors.rightMargin: 1
                width: 2
                height: (indRoot.active || indRoot.hovered) ? Math.max(8, parent.height - 8) : 0
                radius: 1
                color: indRoot.active ? indRoot.accentColor : root.theme.textMuted
                opacity: indRoot.active ? 1.0 : (indRoot.hovered ? 0.9 : 0.0)
                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }
              }
            }

            // Widget building blocks

            // 1. Applications Launcher Button
            Component {
              id: appGridComp
              Rectangle {
                id: appGridButton
                implicitHeight: barContentContainer.isVert ? 28 : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : 28
                height: implicitHeight
                width: implicitWidth
                scale: appGridMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
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
                  opacity: (barContentContainer.activeStyle !== "underline" && appGridMouse.containsMouse) ? 0.15 : 0.0
                  Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                PillIndicator {
                  active: appGridMouse.pressed
                  hovered: appGridMouse.containsMouse
                  accentColor: barContentContainer.wAccent("appGrid", root.theme.accentPrimary)
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
                  anchors.topMargin: -barContentContainer.vHitPadding
                  anchors.bottomMargin: -barContentContainer.vHitPadding
                  anchors.leftMargin: -barContentContainer.hHitPadding
                  anchors.rightMargin: -barContentContainer.hHitPadding
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    const pt = appGridButton.mapToItem(null, appGridButton.width / 2, appGridButton.height / 2);
                    const winW = Math.max(1, barWindow.width);
                    const winH = Math.max(1, barWindow.height);
                    const normX = (pt.x / winW).toFixed(3);
                    const normY = (pt.y / winH).toFixed(3);
                    const clearance = barContentContainer.isVert
                      ? ((barInstanceScope.isFloating ? 6 : 0) + barInstanceScope.barThickness + 16)
                      : ((barInstanceScope.isFloating ? 6 : 0) + barInstanceScope.barThickness);
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
                property bool isPinned: false
                readonly property int cpuVal: parseInt(SystemInfo.cpuUsage) || 0
                readonly property bool isAlert: Boolean(BarConfig.hwAlertEnabled) && (cpuVal >= (BarConfig.hwAlertThreshold || 85))
                implicitHeight: barContentContainer.isVert ? (cpuVertCol.implicitHeight + 12) : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (cpuContent.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                scale: cpuMouse.pressed ? 0.93 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: isAlert ? root.withAlpha(root.theme.accentRed, 0.28) : barContentContainer.wBg("cpu", cpuHover.hovered || cpuMouse.containsMouse || cpuPill.isPinned)
                border.color: isAlert ? root.theme.accentRed : barContentContainer.wBorder("cpu")
                border.width: (isAlert || barContentContainer.hasCustomColor("cpu")) ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.Button
                Accessible.name: "CPU: " + SystemInfo.cpuUsage

                HoverHandler { id: cpuHover }

                PillIndicator {
                  active: cpuPill.isPinned || cpuMouse.pressed
                  hovered: cpuHover.hovered || cpuMouse.containsMouse
                  accentColor: isAlert ? root.theme.accentRed : barContentContainer.wAccent("cpu", root.theme.accentOrange)
                }

                MouseArea {
                  id: cpuMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: cpuPill.isPinned = !cpuPill.isPinned
                }

                InfoPopup {
                  target: cpuPill
                  barItem: barContentContainer
                  hovered: cpuHover.hovered
                  pinned: cpuPill.isPinned
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
                    visible: BarConfig.hwShowIcons !== false
                    color: isAlert ? root.theme.accentRed : barContentContainer.wAccent("cpu", root.theme.accentOrange)
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
                    visible: BarConfig.hwShowIcons !== false
                    color: isAlert ? root.theme.accentRed : barContentContainer.wAccent("cpu", root.theme.accentOrange)
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
                property bool isPinned: false
                readonly property int tempVal: parseInt(SystemInfo.temperature) || 0
                readonly property bool isAlert: Boolean(BarConfig.hwAlertEnabled) && (tempVal >= (BarConfig.hwAlertThreshold || 85))
                implicitHeight: barContentContainer.isVert ? (tempVertCol.implicitHeight + 12) : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (tempContent.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                scale: tempMouse.pressed ? 0.93 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: isAlert ? root.withAlpha(root.theme.accentRed, 0.28) : barContentContainer.wBg("temp", tempHover.hovered || tempMouse.containsMouse || tempPill.isPinned)
                border.color: isAlert ? root.theme.accentRed : barContentContainer.wBorder("temp")
                border.width: (isAlert || barContentContainer.hasCustomColor("temp")) ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.Button
                Accessible.name: "Temperature: " + SystemInfo.temperature

                HoverHandler { id: tempHover }

                PillIndicator {
                  active: tempPill.isPinned || tempMouse.pressed
                  hovered: tempHover.hovered || tempMouse.containsMouse
                  accentColor: isAlert ? root.theme.accentRed : barContentContainer.wAccent("temp", root.theme.accentRed)
                }

                MouseArea {
                  id: tempMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: tempPill.isPinned = !tempPill.isPinned
                }

                InfoPopup {
                  target: tempPill
                  barItem: barContentContainer
                  hovered: tempHover.hovered
                  pinned: tempPill.isPinned
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
                    visible: BarConfig.hwShowIcons !== false
                    color: isAlert ? root.theme.accentRed : barContentContainer.wAccent("temp", root.theme.accentRed)
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
                    visible: BarConfig.hwShowIcons !== false
                    color: isAlert ? root.theme.accentRed : barContentContainer.wAccent("temp", root.theme.accentRed)
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
                property bool isPinned: false
                readonly property int memVal: parseInt(SystemInfo.memoryUsage) || 0
                readonly property bool isAlert: Boolean(BarConfig.hwAlertEnabled) && (memVal >= (BarConfig.hwAlertThreshold || 85))
                implicitHeight: barContentContainer.isVert ? (memVertCol.implicitHeight + 12) : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (memContent.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                scale: memMouse.pressed ? 0.93 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: isAlert ? root.withAlpha(root.theme.accentRed, 0.28) : barContentContainer.wBg("memory", memHover.hovered || memMouse.containsMouse || memPill.isPinned)
                border.color: isAlert ? root.theme.accentRed : barContentContainer.wBorder("memory")
                border.width: (isAlert || barContentContainer.hasCustomColor("memory")) ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.Button
                Accessible.name: "Memory Usage: " + SystemInfo.memoryUsage

                HoverHandler { id: memHover }

                PillIndicator {
                  active: memPill.isPinned || memMouse.pressed
                  hovered: memHover.hovered || memMouse.containsMouse
                  accentColor: isAlert ? root.theme.accentRed : barContentContainer.wAccent("memory", root.theme.accentGreen ?? root.theme.accentPrimary)
                }

                MouseArea {
                  id: memMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: memPill.isPinned = !memPill.isPinned
                }

                InfoPopup {
                  target: memPill
                  barItem: barContentContainer
                  hovered: memHover.hovered
                  pinned: memPill.isPinned
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
                    visible: BarConfig.hwShowIcons !== false
                    color: isAlert ? root.theme.accentRed : barContentContainer.wAccent("memory", root.theme.accentPrimary)
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
                    visible: BarConfig.hwShowIcons !== false
                    color: isAlert ? root.theme.accentRed : barContentContainer.wAccent("memory", root.theme.accentPrimary)
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
                property bool isPinned: false
                readonly property int diskVal: parseInt(SystemInfo.diskUsage) || 0
                readonly property bool isAlert: Boolean(BarConfig.hwAlertEnabled) && (diskVal >= (BarConfig.hwAlertThreshold || 85))
                implicitHeight: barContentContainer.isVert ? (diskVertCol.implicitHeight + 12) : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (diskContent.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                scale: diskMouseArea.pressed ? 0.93 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: isAlert ? root.withAlpha(root.theme.accentRed, 0.28) : barContentContainer.wBg("disk", diskMouseArea.containsMouse || diskButton.isPinned)
                border.color: isAlert ? root.theme.accentRed : barContentContainer.wBorder("disk")
                border.width: (isAlert || barContentContainer.hasCustomColor("disk")) ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }

                Accessible.role: Accessible.Button
                Accessible.name: "/ (" + SystemInfo.diskUsage + ")"

                HoverHandler { id: diskHover }

                PillIndicator {
                  active: diskButton.isPinned || diskMouseArea.pressed
                  hovered: diskHover.hovered || diskMouseArea.containsMouse
                  accentColor: isAlert ? root.theme.accentRed : barContentContainer.wAccent("disk", root.theme.accentPrimary)
                }

                MouseArea {
                  id: diskMouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: diskButton.isPinned = !diskButton.isPinned
                }

                Rectangle {
                  anchors.fill: parent
                  radius: parent.radius
                  color: barContentContainer.wAccent("disk", root.theme.accentPrimary)
                  opacity: (barContentContainer.activeStyle !== "underline" && diskMouseArea.containsMouse) ? 0.15 : 0.0
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
                    visible: BarConfig.hwShowIcons !== false
                    color: isAlert ? root.theme.accentRed : barContentContainer.wAccent("disk", root.theme.accentPrimary)
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
                    visible: BarConfig.hwShowIcons !== false
                    color: isAlert ? root.theme.accentRed : barContentContainer.wAccent("disk", root.theme.accentPrimary)
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
                  barItem: barContentContainer
                  hovered: diskMouseArea.containsMouse
                  pinned: diskButton.isPinned
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
                implicitHeight: barContentContainer.isVert ? (titleText.text !== "" ? 28 : 0) : (barContentContainer.hidePill ? barContentContainer.height : 24)
                height: implicitHeight
                readonly property string curSec: BarConfig.getWidgetSection("windowTitle")
                readonly property real availableCenterSpace: curSec === "center"
                  ? Math.max(60, Math.min(360, barContentContainer.width / Math.max(2, barContentContainer.effectivePanels.length) - 24))
                  : 240
                implicitWidth: barContentContainer.isVert
                  ? (titleText.text !== "" ? barContentContainer.vertPillWidth : 0)
                  : (curSec === "center"
                    ? (titleText.text !== "" ? Math.max(40, Math.min(titleText.implicitWidth + 24, availableCenterSpace)) : 0)
                    : (titleText.text !== "" ? Math.max(40, Math.min(titleText.implicitWidth + 24, 240)) : 0))
                width: implicitWidth
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: barContentContainer.wBg("windowTitle", false)
                border.color: barContentContainer.wBorder("windowTitle")
                border.width: (titleText.text !== "" && barContentContainer.hasCustomColor("windowTitle")) ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                clip: true

                HoverHandler { id: titleHover }

                PillIndicator {
                  active: false
                  hovered: titleHover.hovered
                  accentColor: barContentContainer.wAccent("windowTitle", root.theme.accentPrimary)
                }

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
              Item {
                id: wsContainer
                implicitWidth: wsGrid.implicitWidth
                implicitHeight: barContentContainer.isVert ? wsGrid.implicitHeight : (barContentContainer.hidePill ? barContentContainer.height : 24)
                width: implicitWidth
                height: barContentContainer.isVert ? implicitHeight : barContentContainer.height

                function formatWsLabel(wsId, style) {
                  const s = style !== undefined ? style : BarConfig.workspaceStyle;
                  if (s === "roman") {
                    const roman = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];
                    const n = parseInt(wsId) || 0;
                    return (n > 0 && n < roman.length) ? roman[n] : String(wsId);
                  }
                  if (s === "dot") {
                    return "•";
                  }
                  return String(wsId);
                }

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
                      height: barContentContainer.isVert ? (modelData.focused ? 30 : 22) : (barContentContainer.hidePill ? barContentContainer.height : 24)
                      implicitHeight: height
                      scale: wsMouse.pressed ? 0.90 : 1.0
                      Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                      radius: barContentContainer.pillRadius
                      Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                      color: modelData.focused
                        ? (barContentContainer.activeStyle === "underline"
                            ? (barContentContainer.hidePill ? "transparent" : root.theme.bgSurface)
                            : (barContentContainer.activeStyle === "both"
                                ? (barContentContainer.hasCustomColor("workspaces")
                                    ? barContentContainer.wBg("workspaces", true)
                                    : root.theme.bgSelected)
                                : barContentContainer.wAccent("workspaces", root.theme.accentPrimary)))
                        : (modelData.urgent && urgentBlink
                          ? root.theme.accentRed
                          : (barContentContainer.activeStyle === "underline"
                              ? (barContentContainer.hidePill ? "transparent" : root.theme.bgSurface)
                              : barContentContainer.wBg("workspaces", wsMouse.containsMouse)))
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

                      PillIndicator {
                        active: wsPill.modelData.focused
                        hovered: wsMouse.containsMouse
                        accentColor: barContentContainer.wAccent("workspaces", root.theme.accentPrimary)
                      }

                      Text {
                        anchors.centerIn: parent
                        text: {
                          const s = BarConfig.workspaceStyle || "index";
                          const id = wsPill.modelData.id;
                          if (s === "roman") {
                            const roman = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];
                            const n = parseInt(id) || 0;
                            return (n > 0 && n < roman.length) ? roman[n] : String(id);
                          }
                          if (s === "dot") {
                            return "•";
                          }
                          return String(id);
                        }
                        color: wsPill.modelData.focused
                          ? (barContentContainer.activeStyle === "pill"
                              ? root.theme.bgBase
                              : barContentContainer.wAccent("workspaces", root.theme.accentPrimary))
                          : (wsMouse.containsMouse
                              ? root.theme.textPrimary
                              : (barContentContainer.hasCustomColor("workspaces")
                                  ? barContentContainer.wAccent("workspaces", root.theme.textPrimary)
                                  : root.theme.textSecondary))
                        font.pixelSize: 11
                        font.family: root.font
                        font.bold: wsPill.modelData.focused
                        Behavior on color { ColorAnimation { duration: 120 } }
                      }

                      MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wsPill.modelData.activate()
                        onWheel: wheel => {
                          if (BarConfig.workspaceScrollSwitch === false) return;
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
                property bool isPinned: false
                implicitHeight: barContentContainer.isVert ? 28 : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (weatherContent.implicitWidth + 16)
                height: implicitHeight
                width: implicitWidth
                scale: weatherMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: barContentContainer.wBg("weather", weatherHover.hovered || weatherMouse.containsMouse || weatherWidget.isPinned)
                border.color: barContentContainer.wBorder("weather")
                border.width: barContentContainer.hasCustomColor("weather") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.Button
                Accessible.name: "Weather: " + SystemInfo.weatherInfo

                HoverHandler { id: weatherHover }

                PillIndicator {
                  active: weatherWidget.isPinned || weatherMouse.pressed
                  hovered: weatherHover.hovered || weatherMouse.containsMouse
                  accentColor: barContentContainer.wAccent("weather", root.theme.accentCyan)
                }

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
                  id: weatherMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    weatherWidget.isPinned = !weatherWidget.isPinned;
                    SystemInfo.refreshWeather();
                  }
                }

                WeatherPopup {
                  id: weatherPopup
                  target: weatherWidget
                  barItem: barContentContainer
                  hovered: weatherHover.hovered
                  pinned: weatherWidget.isPinned
                  theme: root.theme
                  font: root.font
                  location: BarConfig.weatherLocation || "Bekasi"
                  accent: barContentContainer.wAccent("weather", root.theme.accentCyan)
                  barPosition: barContentContainer.barPos
                  onPinToggled: weatherWidget.isPinned = !weatherWidget.isPinned
                }
              }
            }

            // 9. Clock & Calendar Popup
            Component {
              id: clockComp
              Rectangle {
                id: timeWidget
                implicitHeight: barContentContainer.isVert ? (vertClockCol.implicitHeight + 12) : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (timeDate.implicitWidth + 16)
                height: implicitHeight
                width: implicitWidth
                scale: timeMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                property bool calPinned: false
                color: barContentContainer.wBg("clock", timeHover.hovered || timeMouse.containsMouse || timeWidget.calPinned)
                border.color: barContentContainer.wBorder("clock")
                border.width: barContentContainer.hasCustomColor("clock") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }

                HoverHandler { id: timeHover }

                PillIndicator {
                  active: timeWidget.calPinned || timeMouse.pressed
                  hovered: timeHover.hovered || timeMouse.containsMouse
                  accentColor: barContentContainer.wAccent("clock", root.theme.accentPrimary)
                }

                MouseArea {
                  id: timeMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: timeWidget.calPinned = !timeWidget.calPinned
                }

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
                  readonly property bool isCalActive: timeHover.hovered || timeMouse.containsMouse || timeWidget.calPinned
                  visible: isCalActive || calBox.opacity > 0
                  implicitWidth: 292
                  implicitHeight: 312
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
                    const bRect = win.contentItem.mapFromItem(
                      barContentContainer, 0, 0, barContentContainer.width, barContentContainer.height
                    );
                    if (barContentContainer.barPos === "top" || barContentContainer.barPos === "bottom") {
                      calendarPopup.anchor.rect = Qt.rect(widgetRect.x, bRect.y, widgetRect.width, bRect.height);
                    } else {
                      calendarPopup.anchor.rect = Qt.rect(bRect.x, widgetRect.y, bRect.width, widgetRect.height);
                    }
                  }

                  Rectangle {
                    id: calBox
                    opacity: calendarPopup.isCalActive ? 1 : 0
                    x: barContentContainer.barPos === "left"
                      ? (calendarPopup.isCalActive ? 6 : 0)
                      : (barContentContainer.barPos === "right" ? (calendarPopup.isCalActive ? 6 : 12) : 6)
                    y: barContentContainer.barPos === "top"
                      ? (calendarPopup.isCalActive ? 6 : 0)
                      : (barContentContainer.barPos === "bottom" ? (calendarPopup.isCalActive ? 6 : 12) : 6)
                    transformOrigin: {
                      if (barContentContainer.barPos === "bottom") return Item.Bottom;
                      if (barContentContainer.barPos === "left") return Item.Left;
                      if (barContentContainer.barPos === "right") return Item.Right;
                      return Item.Top;
                    }
                    scale: calendarPopup.isCalActive ? 1 : 0.96
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
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: barContentContainer.wBg("tray", trayHover.hovered)
                border.color: barContentContainer.wBorder("tray")
                border.width: barContentContainer.hasCustomColor("tray") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }

                HoverHandler { id: trayHover }

                PillIndicator {
                  active: false
                  hovered: trayHover.hovered
                  accentColor: barContentContainer.wAccent("tray", root.theme.accentPrimary)
                }

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
                      height: barContentContainer.isVert ? 24 : Math.max(24, barContentContainer.height)

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
                implicitHeight: barContentContainer.isVert ? 28 : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : 28
                height: implicitHeight
                width: implicitWidth
                scale: controlCenterArea.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: barContentContainer.wBg("controlCenter", controlCenterArea.containsMouse || (controlCenterLoader.item && controlCenterLoader.item.visible))
                border.color: barContentContainer.wBorder("controlCenter")
                border.width: barContentContainer.hasCustomColor("controlCenter") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.Button
                Accessible.name: "Control Center"

                PillIndicator {
                  active: (controlCenterLoader.item && controlCenterLoader.item.visible) || controlCenterArea.pressed
                  hovered: controlCenterArea.containsMouse
                  accentColor: barContentContainer.wAccent("controlCenter", root.theme.accentPrimary)
                }

                Text {
                  id: ccIcon
                  anchors.centerIn: parent
                  anchors.verticalCenterOffset: -1
                  text: ""
                  color: ((controlCenterLoader.item && controlCenterLoader.item.visible) || barContentContainer.hasCustomColor("controlCenter"))
                    ? barContentContainer.wAccent("controlCenter", root.theme.accentPrimary)
                    : root.theme.textPrimary
                  font.pixelSize: 12
                  font.family: root.font
                }

                Rectangle {
                  anchors.fill: parent
                  radius: parent.radius
                  color: barContentContainer.wAccent("controlCenter", root.theme.accentPrimary)
                  opacity: (barContentContainer.activeStyle !== "underline" && (controlCenterArea.containsMouse || (controlCenterLoader.item && controlCenterLoader.item.visible))) ? 0.16 : 0.0
                  Behavior on opacity {
                    NumberAnimation { duration: 150 }
                  }
                }

                MouseArea {
                  id: controlCenterArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (!controlCenterLoader.active) {
                      controlCenterLoader.active = true;
                    } else if (controlCenterLoader.item) {
                      controlCenterLoader.item.visible = !controlCenterLoader.item.visible;
                    }
                  }
                }

                Loader {
                  id: controlCenterLoader
                  active: false
                  sourceComponent: Component {
                    ControlCenter {
                      theme: root.theme
                      font: root.font
                      anchorTarget: controlCenterButton
                      barPosition: barContentContainer.barPos
                      barThickness: barInstanceScope.barThickness
                      barFloating: barInstanceScope.isFloating
                      barWindowWidth: barWindow.width
                      barWindowHeight: barWindow.height
                      Component.onCompleted: visible = true
                    }
                  }
                }
              }
            }

            // 12. Network Upload & Download Speed Pill
            Component {
              id: networkComp
              Rectangle {
                id: netPill
                property bool isPinned: false
                implicitHeight: barContentContainer.isVert ? (netVertCol.implicitHeight + 12) : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (netRow.implicitWidth + 16)
                height: implicitHeight
                width: implicitWidth
                scale: netMouse.pressed ? 0.93 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: barContentContainer.wBg("network", netHover.hovered || netMouse.containsMouse || netPill.isPinned)
                border.color: barContentContainer.wBorder("network")
                border.width: barContentContainer.hasCustomColor("network") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.Button
                Accessible.name: "Network Speed: Down " + SystemInfo.networkDownSpeed + ", Up " + SystemInfo.networkUpSpeed

                HoverHandler { id: netHover }

                PillIndicator {
                  active: netPill.isPinned || netMouse.pressed
                  hovered: netHover.hovered || netMouse.containsMouse
                  accentColor: barContentContainer.wAccent("network", root.theme.accentCyan)
                }

                MouseArea {
                  id: netMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: netPill.isPinned = !netPill.isPinned
                }

                InfoPopup {
                  target: netPill
                  barItem: barContentContainer
                  hovered: netHover.hovered
                  pinned: netPill.isPinned
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
                implicitHeight: barContentContainer.isVert ? (batVertCol.implicitHeight + 12) : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (batContent.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: barContentContainer.wBg("battery", batHover.hovered)
                border.color: barContentContainer.wBorder("battery")
                border.width: barContentContainer.hasCustomColor("battery") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.StaticText
                Accessible.name: "Battery: " + SystemInfo.batteryLevel

                HoverHandler { id: batHover }

                PillIndicator {
                  active: false
                  hovered: batHover.hovered
                  accentColor: barContentContainer.wAccent("battery", root.theme.accentGreen ?? root.theme.accentPrimary)
                }

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
                        : (SystemInfo.batteryLevelRaw <= (BarConfig.batteryLowThreshold || 20) ? root.theme.accentRed : root.theme.accentPrimary))
                    font.pixelSize: 13
                    font.family: root.font
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: BarConfig.batteryShowPercentage !== false
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
                        : (SystemInfo.batteryLevelRaw <= (BarConfig.batteryLowThreshold || 20) ? root.theme.accentRed : root.theme.accentPrimary))
                    font.pixelSize: 13
                    font.family: root.font
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: BarConfig.batteryShowPercentage !== false
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
                readonly property int volPct: {
                  if (!sinkAudio) return 0;
                  if (sinkAudio.volumes && sinkAudio.volumes.length >= 2) {
                    return Math.round(Math.max(sinkAudio.volumes[0], sinkAudio.volumes[1]) * 100);
                  }
                  return Math.round(sinkAudio.volume * 100);
                }

                implicitHeight: barContentContainer.isVert ? (volVertCol.implicitHeight + 12) : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : (volContent.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                scale: volMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: barContentContainer.wBg("volume", volMouse.containsMouse)
                border.color: barContentContainer.wBorder("volume")
                border.width: barContentContainer.hasCustomColor("volume") ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.Button
                Accessible.name: "Volume: " + volPct + "%"

                PillIndicator {
                  active: volMouse.pressed
                  hovered: volMouse.containsMouse
                  accentColor: volPill.isMuted
                    ? root.theme.accentRed
                    : barContentContainer.wAccent("volume", root.theme.accentPrimary)
                }

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
                      if (volPill.sinkAudio.volumes && volPill.sinkAudio.volumes.length >= 2) {
                        const vl = volPill.sinkAudio.volumes[0];
                        const vr = volPill.sinkAudio.volumes[1];
                        const maxV = Math.max(vl, vr);
                        const targetMax = Math.max(0.0, Math.min(1.0, (maxV > 0.001 ? maxV : volPill.sinkAudio.volume) + step));
                        if (maxV > 0.001) {
                          volPill.sinkAudio.volumes = [targetMax * (vl / maxV), targetMax * (vr / maxV)];
                        } else {
                          volPill.sinkAudio.volumes = [targetMax, targetMax];
                        }
                      } else {
                        volPill.sinkAudio.volume = Math.max(0.0, Math.min(1.0, volPill.sinkAudio.volume + step));
                      }
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

                implicitHeight: barContentContainer.isVert ? 28 : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert
                  ? barContentContainer.vertPillWidth
                  : (hasMedia ? Math.min(200, mediaContent.implicitWidth + 16) : (mediaEmptyContent.implicitWidth + 14))
                height: implicitHeight
                width: implicitWidth
                scale: mediaMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: barContentContainer.wBg("media", mediaMouse.containsMouse)
                border.color: barContentContainer.wBorder("media")
                border.width: barContentContainer.hasCustomColor("media") ? 1 : 0
                clip: true
                Behavior on color { ColorAnimation { duration: 150 } }

                PillIndicator {
                  active: mediaPill.isPlaying || mediaMouse.pressed
                  hovered: mediaMouse.containsMouse
                  accentColor: barContentContainer.wAccent("media", root.theme.accentPrimary)
                }

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

                implicitHeight: barContentContainer.isVert ? 28 : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: barContentContainer.isVert ? barContentContainer.vertPillWidth : 28
                height: implicitHeight
                width: implicitWidth
                scale: idleMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: barContentContainer.wBg("idleInhibitor", idleMouse.containsMouse || idlePill.isActive)
                border.color: barContentContainer.activeStyle === "underline"
                  ? "transparent"
                  : (idlePill.isActive
                    ? barContentContainer.wAccent("idleInhibitor", root.theme.accentOrange ?? root.theme.accentPrimary)
                    : barContentContainer.wBorder("idleInhibitor"))
                border.width: (barContentContainer.activeStyle !== "underline" && (idlePill.isActive || barContentContainer.hasCustomColor("idleInhibitor"))) ? 1 : 0
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Accessible.role: Accessible.Button
                Accessible.name: idlePill.isActive ? "Idle Inhibitor: Active" : "Idle Inhibitor: Inactive"

                Rectangle {
                  anchors.fill: parent
                  radius: parent.radius
                  color: barContentContainer.wAccent("idleInhibitor", root.theme.accentOrange ?? root.theme.accentPrimary)
                  opacity: (barContentContainer.activeStyle !== "underline") ? (idlePill.isActive ? 0.18 : (idleMouse.containsMouse ? 0.12 : 0.0)) : 0.0
                  Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                PillIndicator {
                  active: idlePill.isActive || idleMouse.pressed
                  hovered: idleMouse.containsMouse
                  accentColor: barContentContainer.wAccent("idleInhibitor", root.theme.accentOrange ?? root.theme.accentPrimary)
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

            // 17. Cava Audio Spectrum Visualizer Pill
            Component {
              id: cavaComp
              Rectangle {
                id: cavaPill
                readonly property bool hasAudio: CavaService.hasAudio
                readonly property bool autoHide: BarConfig.cavaAutoHide
                readonly property bool isVert: barContentContainer.isVert

                visible: !autoHide || hasAudio || cavaMouse.containsMouse

                implicitHeight: isVert ? Math.max(28, (cavaVertCol ? cavaVertCol.implicitHeight + 10 : 28)) : (barContentContainer.hidePill ? barContentContainer.height : 24)
                implicitWidth: isVert
                  ? barContentContainer.vertPillWidth
                  : (cavaHorizRow.implicitWidth + 14)
                height: implicitHeight
                width: implicitWidth
                scale: cavaMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                radius: barContentContainer.pillRadius
                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                color: barContentContainer.wBg("cava", cavaMouse.containsMouse || hasAudio)
                border.color: barContentContainer.wBorder("cava")
                border.width: barContentContainer.hasCustomColor("cava") ? 1 : 0
                clip: true
                Behavior on color { ColorAnimation { duration: 150 } }

                PillIndicator {
                  active: cavaPill.hasAudio || cavaMouse.pressed
                  hovered: cavaMouse.containsMouse
                  accentColor: barContentContainer.wAccent("cava", root.theme.accentPrimary)
                }

                // Horizontal layout
                Row {
                  id: cavaHorizRow
                  visible: !cavaPill.isVert
                  anchors.centerIn: parent
                  spacing: 6

                  // Bars mode (smooth rounded equalizer bars)
                  Row {
                    visible: BarConfig.cavaStyle !== "glyphs"
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    height: 16

                    Repeater {
                      model: CavaService.values
                      Rectangle {
                        required property int modelData
                        required property int index

                        width: 3
                        height: Math.max(2, Math.round((modelData / 100) * 16))
                        radius: 1.5
                        color: barContentContainer.wAccent("cava", root.theme.accentPrimary)
                        anchors.bottom: (BarConfig.cavaStyle === "line") ? undefined : parent.bottom
                        anchors.verticalCenter: (BarConfig.cavaStyle === "line") ? parent.verticalCenter : undefined

                        Behavior on height {
                          NumberAnimation {
                            duration: 50
                            easing.type: Easing.OutQuad
                          }
                        }
                      }
                    }
                  }

                  // Unicode glyphs mode
                  Text {
                    visible: BarConfig.cavaStyle === "glyphs"
                    anchors.verticalCenter: parent.verticalCenter
                    text: CavaService.glyphText
                    font.family: root.font
                    font.pixelSize: 11
                    color: barContentContainer.wAccent("cava", root.theme.accentPrimary)
                  }
                }

                // Vertical bar layout (when bar is on Left or Right)
                Column {
                  id: cavaVertCol
                  visible: cavaPill.isVert
                  anchors.centerIn: parent
                  spacing: 2

                  Repeater {
                    model: Math.min((BarConfig.cavaBars || 8), CavaService.values.length)
                    Rectangle {
                      required property int index
                      readonly property int val: (CavaService.values && CavaService.values.length > index) ? CavaService.values[index] : 0
                      height: 2
                      width: Math.max(2, Math.round((val / 100) * 18))
                      radius: 1
                      color: barContentContainer.wAccent("cava", root.theme.accentPrimary)
                      anchors.horizontalCenter: parent.horizontalCenter

                      Behavior on width {
                        NumberAnimation {
                          duration: 50
                          easing.type: Easing.OutQuad
                        }
                      }
                    }
                  }
                }

                MouseArea {
                  id: cavaMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  acceptedButtons: Qt.LeftButton | Qt.RightButton
                  onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                      const styles = ["bars", "glyphs", "line"];
                      const curIdx = styles.indexOf(BarConfig.cavaStyle || "bars");
                      const next = styles[(curIdx + 1) % styles.length];
                      BarConfig.cavaStyle = next;
                      BarConfig.saveConfig();
                    } else if (mouse.button === Qt.RightButton) {
                      const modes = ["compact", "medium", "wide"];
                      const curIdx = modes.indexOf(BarConfig.cavaMode || "compact");
                      const next = modes[(curIdx + 1) % modes.length];
                      BarConfig.setCavaMode(next);
                    }
                  }
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
}
