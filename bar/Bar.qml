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
import "../utils/ColorUtils.js" as ColorUtils

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"
  property bool barVisible: true
  property var activePopupData: null

  function withAlpha(col, alpha) {
    return ColorUtils.withAlpha(col, alpha);
  }

  function resolveThemeSpec(spec, fallbackColor) {
    return ColorUtils.resolveThemeSpec(root.theme, spec, fallbackColor);
  }

  function _barMatchesScreen(b, screenIdx) {
    if (!b || b.enabled === false) return null;
    const isPrim = (screenIdx === 0);
    const scr = (Quickshell.screens && Quickshell.screens.length > screenIdx) ? Quickshell.screens[screenIdx] : null;
    const scrName = (scr && scr.name) ? String(scr.name) : ("screen_" + screenIdx);
    const bTarget = b.displayTarget || (b.allMonitors ? "all" : "primary");
    if (bTarget === "primary" && !isPrim) return null;
    if (bTarget === "secondary" && isPrim) return null;
    if (bTarget !== "all" && bTarget !== "primary" && bTarget !== "secondary" && bTarget !== scrName) return null;
    const effectivePos = (!isPrim && bTarget === "all" && b.secondaryPosition) ? b.secondaryPosition : (b.position || "top");
    const effectiveFloating = (!isPrim && bTarget === "all" && b.secondaryFloating !== undefined) ? Boolean(b.secondaryFloating) : Boolean(b.floating);
    const effectiveDashed = (!isPrim && bTarget === "all" && b.secondaryDashed !== undefined) ? Boolean(b.secondaryDashed) : Boolean(b.dashed);
    return { pos: effectivePos, floating: effectiveFloating || effectiveDashed, height: b.barHeight || 32 };
  }

  function isFloatingBarActive(pos, currentBarId, screenIdx) {
    const list = BarConfig.bars || [];
    for (let i = 0; i < list.length; i++) {
      const b = list[i];
      if (!b || b.enabled === false) continue;
      const bid = (b.id !== undefined && b.id !== null) ? String(b.id) : ("bar_" + (i + 1));
      if (currentBarId && bid === currentBarId) continue;
      if (screenIdx !== undefined) {
        const info = _barMatchesScreen(b, screenIdx);
        if (info && info.pos === pos && info.floating) return true;
        continue;
      }
      if ((b.position || "top") === pos && (Boolean(b.floating) || Boolean(b.dashed))) return true;
    }
    return false;
  }

  function isDockedBarActive(pos, currentBarId, screenIdx) {
    const list = BarConfig.bars || [];
    for (let i = 0; i < list.length; i++) {
      const b = list[i];
      if (!b || b.enabled === false) continue;
      const bid = (b.id !== undefined && b.id !== null) ? String(b.id) : ("bar_" + (i + 1));
      if (currentBarId && bid === currentBarId) continue;
      if (screenIdx !== undefined) {
        const info = _barMatchesScreen(b, screenIdx);
        if (info && info.pos === pos && !info.floating) {
          return true;
        }
        continue;
      }
      if ((b.position || "top") === pos && !Boolean(b.floating) && !Boolean(b.dashed)) {
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
        const effectiveFloating = (!isPrim && bTarget === "all" && b.secondaryFloating !== undefined) ? Boolean(b.secondaryFloating) : Boolean(b.floating);
        if (effectivePos === pos && !effectiveFloating) {
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
    objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].filter(Boolean)
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
    model: BarConfig.barIds

    Scope {
      id: barInstanceScope
      required property string modelData
      readonly property string currentBarId: String(modelData || "")
      readonly property var currentBarData: {
        void BarConfig.panelsRevision;
        const bList = BarConfig.bars || [];
        for (let i = 0; i < bList.length; i++) {
          if (bList[i] && String(bList[i].id) === barInstanceScope.currentBarId) {
            return bList[i];
          }
        }
        return (bList.length > 0 && bList[0]) ? bList[0] : {};
      }
      readonly property var barCfg: currentBarData
      readonly property string barPos: barCfg.position || "top"
      readonly property bool isVert: barPos === "left" || barPos === "right"
      readonly property int barThickness: barCfg.barHeight || 32
      readonly property bool isFloating: Boolean(barCfg.floating)
      readonly property bool isDashed: Boolean(barCfg.dashed)
      readonly property real barAlpha: (barCfg.barOpacity !== undefined && barCfg.barOpacity !== null) ? Number(barCfg.barOpacity) : BarConfig.barOpacity
      readonly property int pillRadius: (barCfg.pillRadius !== undefined) ? Number(barCfg.pillRadius) : BarConfig.pillRadius
      readonly property int barRadius: (barCfg.barRadius !== undefined) ? Number(barCfg.barRadius) : BarConfig.barRadius
      readonly property int barMargin: (barCfg.barMargin !== undefined) ? Math.max(0, Number(barCfg.barMargin)) : Math.max(0, BarConfig.barMargin)
      readonly property real pillOpacity: (barCfg.pillOpacity !== undefined) ? Number(barCfg.pillOpacity) : BarConfig.pillOpacity
      readonly property bool hidePill: (barCfg.hidePill !== undefined) ? Boolean(barCfg.hidePill) : BarConfig.hidePill
      readonly property var barPanels: barCfg.panels || []
      readonly property bool hasInnerCorners: (barCfg.innerCorners !== undefined ? Boolean(barCfg.innerCorners) : Boolean(BarConfig.innerCorners)) && !barInstanceScope.isFloating
      readonly property bool fluidCards: (barCfg.fluidCards !== undefined) ? Boolean(barCfg.fluidCards) : Boolean(BarConfig.fluidCards)
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



      Variants {
        model: (Quickshell.screens || []).filter(s => s && s.name && s.name !== "")

        Loader {
          id: barWindowLoader
          required property var modelData
          readonly property var screenModel: modelData
          property bool isReloading: false
          readonly property string trackedBarPos: barInstanceScope.barPos + "|" + String(barInstanceScope.barCfg.secondaryPosition || "")

          onTrackedBarPosChanged: {
            if (!active) return;
            isReloading = true;
            Qt.callLater(() => { isReloading = false; });
          }

          active: !isReloading
          sourceComponent: Component {
        PanelWindow {
          id: barWindow
          readonly property var modelData: barWindowLoader.screenModel
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

          readonly property bool hasFloatingTop: root.isFloatingBarActive("top", undefined, screenIndex)
          readonly property bool hasFloatingBottom: root.isFloatingBarActive("bottom", undefined, screenIndex)
          readonly property bool hasFloatingLeft: root.isFloatingBarActive("left", undefined, screenIndex)
          readonly property bool hasFloatingRight: root.isFloatingBarActive("right", undefined, screenIndex)
          readonly property bool hasAnyDockedScreenBar: barWindow.hasDockedTop || barWindow.hasDockedBottom || barWindow.hasDockedLeft || barWindow.hasDockedRight
          readonly property bool hasAnyFloatingScreenBar: barWindow.hasFloatingTop || barWindow.hasFloatingBottom || barWindow.hasFloatingLeft || barWindow.hasFloatingRight
          readonly property bool ignoreOtherExclusionForDocked: !barWindow.windowIsFloating && barWindow.hasAnyFloatingScreenBar
          readonly property bool effectiveScreenBorder: Boolean(BarConfig.screenBorder)

          readonly property int effectiveDockedLeft: barWindow.hasDockedLeft
            ? barWindow.dockedLeftW
            : ((barWindow.effectiveScreenBorder && !barWindow.hasFloatingLeft) ? BarConfig.screenBorderThickness : 0)
          readonly property int effectiveDockedRight: barWindow.hasDockedRight
            ? barWindow.dockedRightW
            : ((barWindow.effectiveScreenBorder && !barWindow.hasFloatingRight) ? BarConfig.screenBorderThickness : 0)
          readonly property int effectiveDockedTop: barWindow.hasDockedTop
            ? barWindow.dockedTopH
            : ((barWindow.effectiveScreenBorder && !barWindow.hasFloatingTop) ? BarConfig.screenBorderThickness : 0)
          readonly property int effectiveDockedBottom: barWindow.hasDockedBottom
            ? barWindow.dockedBottomH
            : ((barWindow.effectiveScreenBorder && !barWindow.hasFloatingBottom) ? BarConfig.screenBorderThickness : 0)

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
          readonly property var effectivePanels: {
            void BarConfig.panelsRevision;
            if (isSecondaryScreen && target === "all") {
              if (secMode === "custom") {
                return (barInstanceScope.secondaryPanels && barInstanceScope.secondaryPanels.length > 0)
                  ? barInstanceScope.secondaryPanels
                  : BarConfig.defaultSecondaryPanels;
              } else if (secMode === "blank" || blankSec) {
                return [];
              }
              return barInstanceScope.barPanels || [];
            }
            return barInstanceScope.barPanels || [];
          }

          readonly property string windowBarPos: (isSecondaryScreen && target === "all" && barInstanceScope.barCfg.secondaryPosition)
            ? barInstanceScope.barCfg.secondaryPosition
            : barInstanceScope.barPos
          readonly property bool windowIsVert: windowBarPos === "left" || windowBarPos === "right"
          readonly property bool windowIsDashed: (isSecondaryScreen && target === "all" && barInstanceScope.barCfg.secondaryDashed !== undefined)
            ? Boolean(barInstanceScope.barCfg.secondaryDashed)
            : barInstanceScope.isDashed
          readonly property bool windowIsFloating: ((isSecondaryScreen && target === "all" && barInstanceScope.barCfg.secondaryFloating !== undefined)
            ? Boolean(barInstanceScope.barCfg.secondaryFloating)
            : barInstanceScope.isFloating) || windowIsDashed
          readonly property string windowBarColorSpec: (isSecondaryScreen && target === "all" && barInstanceScope.barCfg.secondaryBarColor !== undefined)
            ? String(barInstanceScope.barCfg.secondaryBarColor)
            : barInstanceScope.barColorSpec
          readonly property color windowResolvedBarColor: {
            const c = root.resolveThemeSpec(windowBarColorSpec, root.theme.bgBase);
            return c ? c : root.theme.bgBase;
          }
          readonly property color effectiveBarColor: Qt.rgba(barWindow.windowResolvedBarColor.r, barWindow.windowResolvedBarColor.g, barWindow.windowResolvedBarColor.b, barInstanceScope.barAlpha)

          visible: root.barVisible && Boolean(barInstanceScope.barCfg.enabled) && isScreenTargeted

          anchors {
            top: barWindow.windowBarPos === "top" || barWindow.windowIsVert
            bottom: barWindow.windowBarPos === "bottom" || barWindow.windowIsVert
            left: barWindow.windowBarPos === "left" || !barWindow.windowIsVert
            right: barWindow.windowBarPos === "right" || !barWindow.windowIsVert
          }

          readonly property int edgeGap: barInstanceScope.barMargin
          readonly property int floatSideClearance: barWindow.effectiveScreenBorder ? Math.max(12, Number(BarConfig.screenBorderThickness || 4) + edgeGap) : 12
          readonly property int floatBorderEdgeClearance: barWindow.effectiveScreenBorder ? (Number(BarConfig.screenBorderThickness || 4) + edgeGap) : edgeGap
          readonly property bool innerCornersActive: Boolean(BarConfig.innerCorners)
          readonly property int floatTopClearance: barWindow.windowIsVert
            ? ((barWindow.hasDockedTop ? barWindow.dockedTopH : 0) + ((barWindow.hasDockedTop && barWindow.innerCornersActive) ? (barInstanceScope.innerCornerRadius + 6) : 12))
            : (barWindow.windowBarPos === "top"
              ? (barWindow.hasDockedTop ? (barWindow.dockedTopH + edgeGap) : barWindow.floatBorderEdgeClearance)
              : 0)
          readonly property int floatBottomClearance: barWindow.windowIsVert
            ? ((barWindow.hasDockedBottom ? barWindow.dockedBottomH : 0) + ((barWindow.hasDockedBottom && barWindow.innerCornersActive) ? (barInstanceScope.innerCornerRadius + 6) : 12))
            : (barWindow.windowBarPos === "bottom"
              ? (barWindow.hasDockedBottom ? (barWindow.dockedBottomH + edgeGap) : barWindow.floatBorderEdgeClearance)
              : 0)
          readonly property int floatLeftClearance: !barWindow.windowIsVert
            ? ((barWindow.hasDockedLeft ? barWindow.dockedLeftW : 0) + Math.max(barWindow.floatSideClearance, (barWindow.hasDockedLeft && barWindow.innerCornersActive) ? (barInstanceScope.innerCornerRadius + 6) : 12))
            : (barWindow.windowBarPos === "left"
              ? (barWindow.hasDockedLeft ? (barWindow.dockedLeftW + edgeGap) : barWindow.floatBorderEdgeClearance)
              : 0)
          readonly property int floatRightClearance: !barWindow.windowIsVert
            ? ((barWindow.hasDockedRight ? barWindow.dockedRightW : 0) + Math.max(barWindow.floatSideClearance, (barWindow.hasDockedRight && barWindow.innerCornersActive) ? (barInstanceScope.innerCornerRadius + 6) : 12))
            : (barWindow.windowBarPos === "right"
              ? (barWindow.hasDockedRight ? (barWindow.dockedRightW + edgeGap) : barWindow.floatBorderEdgeClearance)
              : 0)

          margins {
            top: barWindow.windowIsFloating ? barWindow.floatTopClearance : 0
            bottom: barWindow.windowIsFloating ? barWindow.floatBottomClearance : 0
            left: barWindow.windowIsFloating ? barWindow.floatLeftClearance : 0
            right: barWindow.windowIsFloating ? barWindow.floatRightClearance : 0
          }

          exclusionMode: barWindow.ignoreOtherExclusionForDocked ? ExclusionMode.Ignore : ExclusionMode.Normal
          exclusiveZone: barWindow.ignoreOtherExclusionForDocked ? -1 : barInstanceScope.barThickness

          // When a floating bar is present, a docked bar uses ExclusionMode.Ignore so it
          // stays docked to the physical monitor edge without being pushed/cut out by the floating bar.
          // This invisible reserve window preserves the docked bar's exclusiveZone for tiled windows.
          Loader {
            active: barWindow.visible && barWindow.ignoreOtherExclusionForDocked
            sourceComponent: Component {
              PanelWindow {
                screen: barWindow.screen
                visible: true
                color: "transparent"
                mask: Region {}
                exclusionMode: ExclusionMode.Normal
                anchors {
                  top: barWindow.windowBarPos === "top" || barWindow.windowIsVert
                  bottom: barWindow.windowBarPos === "bottom" || barWindow.windowIsVert
                  left: barWindow.windowBarPos === "left" || !barWindow.windowIsVert
                  right: barWindow.windowBarPos === "right" || !barWindow.windowIsVert
                }
                implicitHeight: barWindow.windowIsVert ? 0 : barInstanceScope.barThickness
                implicitWidth: barWindow.windowIsVert ? barInstanceScope.barThickness : 0
                exclusiveZone: barInstanceScope.barThickness
              }
            }
          }

          implicitHeight: barWindow.windowIsVert ? 0 : barInstanceScope.barThickness
          implicitWidth: barWindow.windowIsVert ? barInstanceScope.barThickness : 0
          color: "transparent"

          property string lastPos: barWindow.windowBarPos
          onLastPosChanged: barPosSwitchAnim.restart()
          property int panelItemsRev: 0
          property int knownPanelCount: 0
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
            anchors.topMargin: barWindow.windowIsFloating
              ? 0
              : (barWindow.windowIsVert
                ? 0
                : ((barWindow.hasEffectiveInnerCorners && barWindow.windowBarPos === "bottom") ? barInstanceScope.innerCornerRadius : 0))
            anchors.bottomMargin: barWindow.windowIsFloating
              ? 0
              : (barWindow.windowIsVert
                ? 0
                : ((barWindow.hasEffectiveInnerCorners && barWindow.windowBarPos === "top") ? barInstanceScope.innerCornerRadius : 0))
            anchors.leftMargin: barWindow.windowIsFloating
              ? 0
              : (barWindow.windowIsVert
                ? ((barWindow.hasEffectiveInnerCorners && barWindow.windowBarPos === "right") ? barInstanceScope.innerCornerRadius : 0)
                : 0)
            anchors.rightMargin: barWindow.windowIsFloating
              ? 0
              : (barWindow.windowIsVert
                ? ((barWindow.hasEffectiveInnerCorners && barWindow.windowBarPos === "left") ? barInstanceScope.innerCornerRadius : 0)
                : 0)
            radius: barWindow.windowIsFloating
              ? Math.min(Math.max(0, barInstanceScope.barRadius), Math.floor(Math.min(width, height) / 2))
              : 0
            color: barWindow.windowIsDashed ? "transparent" : barWindow.effectiveBarColor
            border.color: (barWindow.windowIsFloating && !barWindow.windowIsDashed) ? root.theme.bgBorder : "transparent"
            border.width: (barWindow.windowIsFloating && !barWindow.windowIsDashed) ? 1 : 0
            transform: Translate { id: barSlideTransform; x: 0; y: 0 }

            Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on anchors.bottomMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on anchors.leftMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on anchors.rightMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }
          }

          // Split Island backgrounds for Dashed bar style (morphs smoothly to/from Floating)
          property bool dashMorphActive: false
          Timer {
            id: dashMorphTimer
            interval: 300
            onTriggered: barWindow.dashMorphActive = false
          }
          onWindowIsDashedChanged: {
            dashMorphActive = true;
            dashMorphTimer.restart();
          }

          Repeater {
            model: panelsOuterRepeater.count
            delegate: Rectangle {
              required property int index
              // itemAt() is not reactive: re-resolve whenever the panel Grids are rebuilt,
              // otherwise the island keeps a stale (destroyed) reference and disappears.
              readonly property var secGrid: { void barWindow.panelItemsRev; return panelsOuterRepeater.itemAt(index); }
              readonly property bool hasContent: secGrid && secGrid.width > 0 && secGrid.height > 0
              readonly property real targetX: barWindow.windowIsDashed
                ? (secGrid ? (barContentContainer.isVert ? barBackground.x : (barContentContainer.x + secGrid.x - 10)) : barBackground.x)
                : barBackground.x
              readonly property real targetY: barWindow.windowIsDashed
                ? (secGrid ? (barContentContainer.isVert ? (barContentContainer.y + secGrid.y - 8) : barBackground.y) : barBackground.y)
                : barBackground.y
              readonly property real targetW: barWindow.windowIsDashed
                ? (secGrid ? (barContentContainer.isVert ? barBackground.width : (secGrid.width + 20)) : 0)
                : barBackground.width
              readonly property real targetH: barWindow.windowIsDashed
                ? (secGrid ? (barContentContainer.isVert ? (secGrid.height + 16) : barBackground.height) : 0)
                : barBackground.height

              visible: hasContent && !barWindow.isBlankBar && barInstanceScope.barThickness >= 18 && (barWindow.windowIsDashed || barWindow.dashMorphActive || opacity > 0.01)
              x: targetX
              y: targetY
              width: targetW
              height: targetH
              radius: barWindow.windowIsDashed
                ? Math.min(Math.max(0, barInstanceScope.barRadius), Math.floor(Math.min(width, height) / 2))
                : barBackground.radius
              color: barWindow.effectiveBarColor
              border.color: root.theme.bgBorder
              border.width: 1
              opacity: ((barWindow.windowIsDashed || barWindow.dashMorphActive) ? barBackground.opacity : 0.0) * (secGrid ? secGrid.enter : 1.0)
              transform: Translate {
                x: barSlideTransform.x + (secGrid && !barContentContainer.isVert ? secGrid.slideOff : 0)
                y: barSlideTransform.y + (secGrid && barContentContainer.isVert ? secGrid.slideOff : 0)
              }

              Behavior on x { enabled: barWindow.dashMorphActive || barWindow.windowIsDashed; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
              Behavior on y { enabled: barWindow.dashMorphActive || barWindow.windowIsDashed; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
              Behavior on width { enabled: barWindow.dashMorphActive || barWindow.windowIsDashed; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
              Behavior on height { enabled: barWindow.dashMorphActive || barWindow.windowIsDashed; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
              Behavior on radius { enabled: barWindow.dashMorphActive; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
              // No opacity fade: islands start fully overlaying the docked bar and morph apart
              // (or together) while the bar background cross-fades, so there is no see-through dip.
              Behavior on color { ColorAnimation { duration: 180 } }
            }
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
            readonly property string barColorSpec: barWindow.windowBarColorSpec
            readonly property int barThickness: barInstanceScope.barThickness
            readonly property bool isFloating: barWindow.windowIsFloating
            readonly property int barEdgeOffset: (
              barWindow.windowBarPos === "top" ? (barWindow.windowIsFloating ? barWindow.floatTopClearance : 0)
              : (barWindow.windowBarPos === "bottom" ? (barWindow.windowIsFloating ? barWindow.floatBottomClearance : 0)
              : (barWindow.windowBarPos === "left" ? (barWindow.windowIsFloating ? barWindow.floatLeftClearance : 0)
              : (barWindow.windowIsFloating ? barWindow.floatRightClearance : 0)))
            ) + barInstanceScope.barThickness
            readonly property bool fluidCards: barInstanceScope.fluidCards
            readonly property bool hasInnerCorners: barInstanceScope.hasInnerCorners && !barWindow.windowIsFloating
            readonly property int innerCornerRadius: barInstanceScope.innerCornerRadius
            readonly property color barColor: barWindow.effectiveBarColor
            property Item activeInfoProvider: null
            property alias sharedInfoPopup: sharedInfoPopupInst

            SharedInfoPopup {
              id: sharedInfoPopupInst
              barWindow: barWindow
              barContainer: barContentContainer
              hostRoot: root
            }
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

            function resolveWidgetThemeSpec(spec) {
              _trackThemeDeps();
              if (!spec) return "";
              return ColorUtils.resolveThemeSpec(root.theme, spec, "");
            }

            function hasCustomColor(widgetId) {
              return resolveWidgetThemeSpec(wSpec(widgetId)) !== "";
            }

            function wAccent(widgetId, fallbackColor) {
              const resolved = resolveWidgetThemeSpec(wSpec(widgetId));
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
                const resolved = resolveWidgetThemeSpec(wSpec(widgetId));
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
                const resolved = resolveWidgetThemeSpec(wSpec(widgetId));
                if (resolved === "") return "transparent";
                const rgb = _toRgb(resolved);
                if (!rgb) return "transparent";
                return Qt.rgba(rgb.r, rgb.g, rgb.b, 0.45);
              } catch (e) {
                return "transparent";
              }
            }

            // Universal Pill Indicator (Supports Pill, Line, and Both active/hover styles)

            // Widget component registry
            BarWidgetRegistry {
              id: widgetRegistry
              hostRoot: root
              hostContainer: barContentContainer
              hostWindow: barWindow
              hostScope: barInstanceScope
            }

            // Dynamic Panel Section Layouts (Supports Horizontal Top/Bottom and Vertical Left/Right)
            Repeater {
              id: panelsOuterRepeater
              // Integer model keeps the Grid delegates alive when panels change,
              // so their x/y can animate (slide) instead of being rebuilt in place.
              model: barWindow.effectivePanels.length
              onItemAdded: barWindow.panelItemsRev++
              onItemRemoved: barWindow.panelItemsRev++

              Grid {
                id: panelSectionGrid
                required property var modelData
                required property int index
                readonly property var panelItems: barWindow.effectivePanels[index] || []

                // Slide-out entrance for newly added panels (existing ones stay still)
                property real enter: 1.0
                property real slideOff: 0
                opacity: enter
                transform: Translate {
                  x: barContentContainer.isVert ? 0 : panelSectionGrid.slideOff
                  y: barContentContainer.isVert ? panelSectionGrid.slideOff : 0
                }
                ParallelAnimation {
                  id: panelEnterAnim
                  NumberAnimation { target: panelSectionGrid; property: "enter"; from: 0.0; to: 1.0; duration: 300; easing.type: Easing.OutCubic }
                  NumberAnimation { target: panelSectionGrid; property: "slideOff"; from: 36; to: 0; duration: 360; easing.type: Easing.OutCubic }
                }
                Component.onCompleted: {
                  panelSectionGrid.x = targetX; panelSectionGrid.y = targetY;
                  Qt.callLater(() => { panelSectionGrid.posReady = true; });
                  if (index >= barWindow.knownPanelCount && barWindow.knownPanelCount > 0)
                    panelEnterAnim.start();
                  Qt.callLater(() => { barWindow.knownPanelCount = barWindow.effectivePanels.length; });
                }

                // Slide to new position only on big jumps (module moved / panel added);
                // tiny changes (text width jitter) snap so nothing lags or spams.
                property bool posReady: false
                NumberAnimation { id: xSlide; target: panelSectionGrid; property: "x"; duration: 300; easing.type: Easing.OutCubic }
                NumberAnimation { id: ySlide; target: panelSectionGrid; property: "y"; duration: 300; easing.type: Easing.OutCubic }
                function moveTo(anim, prop, target) {
                  const cur = panelSectionGrid[prop];
                  if (!posReady || (!anim.running && Math.abs(target - cur) < 14)) {
                    anim.stop();
                    panelSectionGrid[prop] = target;
                    return;
                  }
                  anim.stop();
                  anim.from = panelSectionGrid[prop];
                  anim.to = target;
                  anim.start();
                }
                onTargetXChanged: moveTo(xSlide, "x", targetX)
                onTargetYChanged: moveTo(ySlide, "y", targetY)
                readonly property int totalPanels: barWindow.effectivePanels.length
                columns: barContentContainer.isVert ? 1 : Math.max(1, sectionWidgetRepeater.count)
                spacing: barContentContainer.isVert ? 6 : 8
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter

                height: barContentContainer.isVert ? implicitHeight : barContentContainer.height
                width: barContentContainer.isVert ? barContentContainer.width : implicitWidth

                readonly property real targetX: {
                  if (barContentContainer.isVert) return 0;
                  if (totalPanels <= 1 || index === 0) return 0;
                  if (index === totalPanels - 1) return Math.max(0, barContentContainer.width - width);
                  const gap = 8;
                  const frac = index / (totalPanels - 1);
                  const idealX = (barContentContainer.width * frac) - (width / 2);
                  let minX = 0;
                  const prev = panelsOuterRepeater.itemAt(index - 1);
                  if (prev) {
                    minX = prev.x + prev.width + (prev.width > 0 ? gap : 0);
                  }
                  let maxX = Math.max(0, barContentContainer.width - width);
                  const last = panelsOuterRepeater.itemAt(totalPanels - 1);
                  if (last) {
                    let tailW = last.width + (last.width > 0 ? gap : 0);
                    for (let k = index + 1; k < totalPanels - 1; k++) {
                      const mid = panelsOuterRepeater.itemAt(k);
                      if (mid && mid.width > 0) tailW += mid.width + gap;
                    }
                    maxX = barContentContainer.width - tailW - width;
                  }
                  if (minX <= maxX) {
                    return Math.max(minX, Math.min(maxX, idealX));
                  }
                  return Math.max(0, Math.min(barContentContainer.width - width, minX));
                }

                readonly property real targetY: {
                  if (!barContentContainer.isVert) return 0;
                  if (totalPanels <= 1 || index === 0) return 0;
                  if (index === totalPanels - 1) return Math.max(0, barContentContainer.height - height);
                  const gap = 6;
                  const frac = index / (totalPanels - 1);
                  const idealY = (barContentContainer.height * frac) - (height / 2);
                  let minY = 0;
                  const prev = panelsOuterRepeater.itemAt(index - 1);
                  if (prev) {
                    minY = prev.y + prev.height + (prev.height > 0 ? gap : 0);
                  }
                  let maxY = Math.max(0, barContentContainer.height - height);
                  const last = panelsOuterRepeater.itemAt(totalPanels - 1);
                  if (last) {
                    let tailH = last.height + (last.height > 0 ? gap : 0);
                    for (let k = index + 1; k < totalPanels - 1; k++) {
                      const mid = panelsOuterRepeater.itemAt(k);
                      if (mid && mid.height > 0) tailH += mid.height + gap;
                    }
                    maxY = barContentContainer.height - tailH - height;
                  }
                  if (minY <= maxY) {
                    return Math.max(minY, Math.min(maxY, idealY));
                  }
                  return Math.max(0, Math.min(barContentContainer.height - height, minY));
                }

                Repeater {
                  id: sectionWidgetRepeater
                  model: panelSectionGrid.panelItems
                  delegate: Loader {
                    id: panelWidgetLoader
                    required property string modelData
                    readonly property string barId: (barInstanceScope.barCfg && barInstanceScope.barCfg.id) ? String(barInstanceScope.barCfg.id) : "bar_1"
                    active: !barWindow.isBlankBar && BarConfig.isWidgetVisible(modelData, barId)
                    sourceComponent: widgetRegistry.getWidgetComponent(modelData)
                    visible: active && sourceComponent !== null
                    width: visible ? (barContentContainer.isVert ? barContentContainer.width : (item ? (item.implicitWidth > 0 ? item.implicitWidth : item.width) : 0)) : 0
                    height: visible ? (barContentContainer.isVert ? (item ? (item.implicitHeight > 0 ? item.implicitHeight : item.height) : 28) : barContentContainer.height) : 0
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

  Variants {
    model: (Quickshell.screens || []).filter(s => s && s.name && s.name !== "")

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
