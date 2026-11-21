import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../../notifications"
import ".."

PanelWindow {
  id: islandWindow

  required property var hostRoot
  required property var hostWindow
  required property var hostContainer
  required property var hostScope
  required property var screenModel

  screen: screenModel
  visible: hostWindow && hostWindow.visible && !hostWindow.isBlankBar
  focusable: false
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell-dynamic-island"
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: true
    left: true
    right: true
  }

  // Reactive bar config readings
  readonly property var cfg: hostScope ? hostScope.barCfg : ({})
  readonly property var theme: hostRoot.theme
  readonly property string font: hostRoot.font
  readonly property int barThickness: hostScope ? hostScope.barThickness : 28
  readonly property int barRadius: hostScope ? hostScope.barRadius : 20
  readonly property color effectiveBarColor: hostWindow ? hostWindow.effectiveBarColor : theme.bgBase
  readonly property string islandPosition: (cfg && cfg.islandPosition) ? String(cfg.islandPosition) : BarConfig.islandPosition
  readonly property string idleMode: (cfg && cfg.islandIdleMode) ? String(cfg.islandIdleMode) : BarConfig.islandIdleMode
  readonly property bool liveActivityEnabled: (cfg && cfg.islandLiveActivity !== undefined) ? Boolean(cfg.islandLiveActivity) : BarConfig.islandLiveActivity
  readonly property string layoutMode: (cfg && cfg.islandLayoutMode) ? String(cfg.islandLayoutMode) : BarConfig.islandLayoutMode
  readonly property var enabledModules: (cfg && Array.isArray(cfg.islandModules) && cfg.islandModules.length > 0) ? cfg.islandModules : BarConfig.islandModules
  readonly property string defaultModule: (cfg && cfg.islandDefaultModule) ? String(cfg.islandDefaultModule) : BarConfig.islandDefaultModule
  readonly property var splitModules: (cfg && Array.isArray(cfg.islandSplitModules) && cfg.islandSplitModules.length >= 2) ? cfg.islandSplitModules : BarConfig.islandSplitModules
  readonly property int hoverDelayMs: (cfg && cfg.islandHoverDelay !== undefined) ? Number(cfg.islandHoverDelay) : BarConfig.islandHoverDelay
  readonly property int closeDelayMs: (cfg && cfg.islandCloseDelay !== undefined) ? Number(cfg.islandCloseDelay) : BarConfig.islandCloseDelay
  readonly property int configuredExpandedW: (cfg && cfg.islandExpandedWidth !== undefined) ? Number(cfg.islandExpandedWidth) : BarConfig.islandExpandedWidth
  readonly property string notifMode: (cfg && cfg.islandNotificationMode !== undefined) ? String(cfg.islandNotificationMode) : BarConfig.islandNotificationMode
  readonly property bool osdEnabled: (cfg && cfg.islandOsdEnabled !== undefined) ? Boolean(cfg.islandOsdEnabled) : BarConfig.islandOsdEnabled
  readonly property var controlTiles: (cfg && Array.isArray(cfg.islandControlTiles)) ? cfg.islandControlTiles : BarConfig.islandControlTiles
  readonly property var appShortcuts: (cfg && Array.isArray(cfg.islandAppShortcuts)) ? cfg.islandAppShortcuts : BarConfig.islandAppShortcuts

  // Drop Shadow Settings
  readonly property bool dropShadowEnabled: (cfg && cfg.barDropShadow !== undefined) ? Boolean(cfg.barDropShadow) : true
  readonly property int shadowBlurPx: (cfg && cfg.barDropShadowBlur !== undefined) ? Math.max(4, Math.min(36, Number(cfg.barDropShadowBlur))) : BarConfig.barDropShadowBlur
  readonly property real shadowOpacityVal: (cfg && cfg.barDropShadowOpacity !== undefined) ? Math.max(0.05, Math.min(0.85, Number(cfg.barDropShadowOpacity))) : BarConfig.barDropShadowOpacity
  readonly property int shadowOffsetY: (cfg && cfg.barDropShadowOffsetY !== undefined) ? Math.max(0, Math.min(16, Number(cfg.barDropShadowOffsetY))) : BarConfig.barDropShadowOffsetY
  readonly property string shadowColorMode: (cfg && cfg.barDropShadowColorMode !== undefined) ? String(cfg.barDropShadowColorMode) : BarConfig.barDropShadowColorMode

  readonly property color resolvedShadowColor: {
    let base = Qt.rgba(0, 0, 0, 1);
    if (shadowColorMode === "accent") {
      base = theme.accentPrimary;
    } else if (shadowColorMode === "adaptive") {
      if (hasActiveNotif && currentNotif && currentNotif.urgency === NotificationUrgency.Critical) {
        base = theme.accentRed;
      } else if (isMediaPlaying) {
        base = theme.accentPrimary;
      } else {
        base = Qt.rgba(0, 0, 0, 1);
      }
    }
    return Qt.rgba(base.r, base.g, base.b, shadowOpacityVal);
  }

  readonly property color resolvedBorderColor: {
    if (hasActiveNotif && currentNotif && currentNotif.urgency === NotificationUrgency.Critical) {
      return Qt.rgba(theme.accentRed.r, theme.accentRed.g, theme.accentRed.b, 0.72);
    }
    if (isExpandedHub || osdActive) {
      return Qt.rgba(theme.accentPrimary.r, theme.accentPrimary.g, theme.accentPrimary.b, 0.28);
    }
    return theme.bgBorder;
  }

  // Slot widgets from the assigned panel in Bar.qml
  readonly property var slotWidgets: {
    void BarConfig.panelsRevision;
    if (!hostWindow) return [];
    const idx = hostWindow.islandPanelIndex;
    const panels = hostWindow.effectivePanels || [];
    if (idx >= 0 && idx < panels.length) return panels[idx] || [];
    return [];
  }

  // Expose compact width back to Bar.qml so neighboring panels never collide
  readonly property real compactWidthOut: Math.max(110, compactView.implicitWidth)

  // Live Media state
  readonly property bool isMediaPlaying: {
    const vals = Mpris.players.values;
    if (!vals) return false;
    for (let i = 0; i < vals.length; i++) {
      if (vals[i] && vals[i].isPlaying) return true;
    }
    return false;
  }

  // Live Notifications state
  readonly property var activeNotifications: (notifMode !== "off") ? (NotificationService.notifications || []) : []
  readonly property bool hasActiveNotif: activeNotifications.length > 0
  property int notifIndex: 0
  readonly property var currentNotif: {
    if (!hasActiveNotif) return null;
    const idx = Math.max(0, Math.min(activeNotifications.length - 1, notifIndex));
    return activeNotifications[idx];
  }
  onHasActiveNotifChanged: {
    if (!hasActiveNotif) notifIndex = 0;
  }

  // Optional OSD Flash state (Volume & Brightness)
  property bool osdActive: false
  property string osdIcon: "󰕾"
  property string osdLabel: "Volume"
  property real osdValue: 0
  property string osdValueText: "0%"
  property bool osdMuted: false
  property bool _osdReady: false

  Timer {
    interval: 600
    running: true
    repeat: false
    onTriggered: islandWindow._osdReady = true
  }

  Timer {
    id: osdHideTimer
    interval: 1500
    repeat: false
    onTriggered: islandWindow.osdActive = false
  }

  Connections {
    target: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio : null
    function onVolumeChanged() { islandWindow._triggerVolumeOsd(); }
    function onVolumesChanged() { islandWindow._triggerVolumeOsd(); }
    function onMutedChanged() { islandWindow._triggerVolumeOsd(); }
  }

  Connections {
    target: islandWindow.hostRoot
    function onBrightnessValueChanged() {
      if (!islandWindow._osdReady || !islandWindow.osdEnabled) return;
      const v = Math.max(0, Math.min(1, islandWindow.hostRoot.brightnessValue));
      islandWindow.osdIcon = v < 0.33 ? "󰃞" : (v < 0.66 ? "󰃟" : "󰃠");
      islandWindow.osdLabel = "Brightness";
      islandWindow.osdValue = v;
      islandWindow.osdValueText = Math.round(v * 100) + "%";
      islandWindow.osdMuted = false;
      islandWindow.osdActive = true;
      osdHideTimer.restart();
    }
  }

  function _triggerVolumeOsd() {
    if (!islandWindow._osdReady || !islandWindow.osdEnabled) return;
    const audio = (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) ? Pipewire.defaultAudioSink.audio : null;
    if (!audio) return;
    const v = (audio.volumes && audio.volumes.length >= 2) ? Math.max(audio.volumes[0], audio.volumes[1]) : audio.volume;
    const muted = Boolean(audio.muted);
    islandWindow.osdIcon = (muted || v <= 0) ? "󰖁" : (v < 0.33 ? "󰕿" : (v < 0.66 ? "󰖀" : "󰕾"));
    islandWindow.osdLabel = "Volume";
    islandWindow.osdValue = Math.max(0, Math.min(1, isNaN(v) ? 0 : v));
    islandWindow.osdValueText = muted ? "Mute" : Math.round((isNaN(v) ? 0 : v) * 100) + "%";
    islandWindow.osdMuted = muted;
    islandWindow.osdActive = true;
    osdHideTimer.restart();
  }

  // Hover & Pin State Machine
  property bool pointerInside: islandHover.hovered
  property bool hubExpanded: false
  property bool hubPinned: false
  property string selectedHubModule: "mpris"

  function resolveInitialModule() {
    const mods = enabledModules || ["mpris", "calendar"];
    if (defaultModule === "auto") {
      if (isMediaPlaying && mods.indexOf("mpris") !== -1) return "mpris";
      if (mods.indexOf("calendar") !== -1) return "calendar";
      return mods[0] || "mpris";
    }
    if (mods.indexOf(defaultModule) !== -1) return defaultModule;
    return mods[0] || "mpris";
  }

  Timer {
    id: hoverOpenTimer
    interval: Math.max(0, islandWindow.hoverDelayMs)
    repeat: false
    onTriggered: {
      if (islandWindow.pointerInside && !islandWindow.hasActiveNotif) {
        islandWindow.selectedHubModule = islandWindow.resolveInitialModule();
        islandWindow.hubExpanded = true;
      }
    }
  }

  Timer {
    id: hoverCloseTimer
    interval: Math.max(80, islandWindow.closeDelayMs)
    repeat: false
    onTriggered: {
      if (!islandWindow.pointerInside && !islandWindow.hubPinned) {
        islandWindow.hubExpanded = false;
      }
    }
  }

  onPointerInsideChanged: {
    if (pointerInside) {
      hoverCloseTimer.stop();
      if (!hubExpanded && !hasActiveNotif) {
        if (hoverDelayMs <= 0) {
          selectedHubModule = resolveInitialModule();
          hubExpanded = true;
        } else {
          hoverOpenTimer.restart();
        }
      }
    } else {
      hoverOpenTimer.stop();
      if (hubExpanded && !hubPinned) {
        hoverCloseTimer.restart();
      }
    }
  }

  // Effective Visual Mode (priority: Notification > OSD > Expanded Hub > Compact)
  readonly property string activeMode: {
    if (hasActiveNotif) return "notif";
    if (osdActive && !hubExpanded) return "osd";
    if (hubExpanded || hubPinned) return "hub";
    return "compact";
  }
  readonly property bool isExpandedHub: activeMode === "hub"
  readonly property bool isNotifMode: activeMode === "notif"
  readonly property bool isOsdMode: activeMode === "osd"
  readonly property bool isCompactMode: activeMode === "compact"

  // Target Geometry for the Morphing Shell
  readonly property int topAnchorY: hostWindow ? hostWindow.floatTopClearance : Math.max(4, BarConfig.barMargin)
  readonly property int leftEdgePad: hostWindow ? hostWindow.floatLeftClearance : 12
  readonly property int rightEdgePad: hostWindow ? hostWindow.floatRightClearance : 12
  readonly property int screenW: (screenModel && screenModel.width > 0) ? screenModel.width : 1920

  readonly property real targetW: {
    if (isNotifMode) return pointerInside ? 390 : 350;
    if (isOsdMode) return 248;
    if (isExpandedHub) {
      const splitActive = layoutMode === "split" && (enabledModules || []).length >= 2;
      const desired = splitActive ? Math.max(560, configuredExpandedW) : configuredExpandedW;
      return Math.min(screenW - 32, desired);
    }
    return Math.min(screenW - 48, compactWidthOut);
  }

  readonly property real targetH: {
    if (isNotifMode) return Math.max(barThickness + 24, notifView.implicitHeight + 22);
    if (isOsdMode) return Math.max(barThickness + 8, 38);
    if (isExpandedHub) return Math.max(120, hubView.implicitHeight + 28);
    return barThickness;
  }

  readonly property real targetRadius: {
    if (isCompactMode) {
      return Math.min(Math.max(0, barRadius), Math.floor(Math.min(targetW, targetH) / 2));
    }
    if (isOsdMode) return Math.floor(targetH / 2);
    return Math.min(24, Math.max(16, barRadius));
  }

  readonly property real targetX: {
    const winW = islandWindow.width > 0 ? islandWindow.width : screenW;
    let rawX = Math.round((winW - targetW) / 2);
    if (islandPosition === "left") {
      rawX = leftEdgePad;
    } else if (islandPosition === "right") {
      rawX = winW - rightEdgePad - targetW;
    }
    return Math.max(8, Math.min(Math.max(8, winW - targetW - 8), rawX));
  }

  // Reserve enough vertical space in the transparent overlay window for expanded hub + shadow with zero clipping
  readonly property int shadowPad: dropShadowEnabled ? (shadowBlurPx + shadowOffsetY + 14) : 4
  implicitHeight: Math.ceil(topAnchorY + Math.max(barThickness, targetH, islandShell.height) + shadowPad)

  // Only capture pointer input inside the visible morphing island pill!
  mask: Region {
    item: islandShell
  }

  Item {
    id: islandShell
    x: islandWindow.targetX
    y: islandWindow.topAnchorY
    width: islandWindow.targetW
    height: islandWindow.targetH

    // Subtle organic spring feel when expanding (especially notifications & hover hub),
    // crisp deceleration when collapsing back to compact pill.
    Behavior on x {
      NumberAnimation {
        duration: islandWindow.isCompactMode ? 240 : 300
        easing.type: islandWindow.isCompactMode ? Easing.OutCubic : Easing.OutBack
        easing.overshoot: 0.45
      }
    }
    Behavior on width {
      NumberAnimation {
        duration: islandWindow.isCompactMode ? 240 : 310
        easing.type: islandWindow.isCompactMode ? Easing.OutCubic : Easing.OutBack
        easing.overshoot: 0.55
      }
    }
    Behavior on height {
      NumberAnimation {
        duration: islandWindow.isCompactMode ? 240 : 310
        easing.type: islandWindow.isCompactMode ? Easing.OutCubic : Easing.OutBack
        easing.overshoot: 0.50
      }
    }

    HoverHandler {
      id: islandHover
    }

    // Click compact pill to pin open, right-click notification to dismiss
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      propagateComposedEvents: true
      z: -1
      onClicked: (mouse) => {
        if (islandWindow.isNotifMode && islandWindow.currentNotif) {
          if (mouse.button === Qt.RightButton) {
            islandWindow.currentNotif.dismiss();
          } else if (mouse.button === Qt.LeftButton) {
            islandWindow.currentNotif.activate();
          }
          return;
        }
        if (mouse.button === Qt.MiddleButton) {
          islandWindow.hubPinned = !islandWindow.hubPinned;
          islandWindow.hubExpanded = islandWindow.hubPinned;
          return;
        }
        if (islandWindow.isCompactMode) {
          islandWindow.selectedHubModule = islandWindow.resolveInitialModule();
          islandWindow.hubPinned = true;
          islandWindow.hubExpanded = true;
        } else {
          mouse.accepted = false;
        }
      }
    }

    // Morphing Pill Background with Unclipped Drop Shadow
    Rectangle {
      id: islandBg
      anchors.fill: parent
      radius: islandWindow.targetRadius
      color: islandWindow.effectiveBarColor
      border.color: islandWindow.resolvedBorderColor
      border.width: 1

      Behavior on radius { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 180 } }
      Behavior on border.color { ColorAnimation { duration: 180 } }

      layer.enabled: islandWindow.dropShadowEnabled
      layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: Math.max(0.08, Math.min(1.0, islandWindow.shadowBlurPx / 32.0))
        shadowColor: islandWindow.resolvedShadowColor
        shadowVerticalOffset: islandWindow.shadowOffsetY
        shadowHorizontalOffset: 0
        autoPaddingEnabled: true
      }
    }

    // Inner Clipped Content Stage (sharp un-layered text & interactive controls)
    Item {
      id: contentClip
      anchors.fill: parent
      clip: true

      // 1. Compact Idle / Live Activity View
      DynamicIslandCompactView {
        id: compactView
        anchors.centerIn: parent
        hostRoot: islandWindow.hostRoot
        hostWindow: islandWindow.hostWindow
        hostContainer: islandWindow.hostContainer
        hostScope: islandWindow.hostScope
        theme: islandWindow.theme
        font: islandWindow.font
        slotWidgets: islandWindow.slotWidgets
        idleMode: islandWindow.idleMode
        liveActivityEnabled: islandWindow.liveActivityEnabled
        barThickness: islandWindow.barThickness

        opacity: islandWindow.isCompactMode ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
      }

      // 2. Expanded Modular Hub View (MPRIS, Calendar, Notifications, Weather, Controls, System)
      DynamicIslandHubView {
        id: hubView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        hostRoot: islandWindow.hostRoot
        theme: islandWindow.theme
        font: islandWindow.font
        enabledModules: islandWindow.enabledModules
        layoutMode: islandWindow.layoutMode
        splitModules: islandWindow.splitModules
        controlTiles: islandWindow.controlTiles
        appShortcuts: islandWindow.appShortcuts
        activeModule: islandWindow.selectedHubModule
        pinned: islandWindow.hubPinned
        onRequestTogglePin: {
          islandWindow.hubPinned = !islandWindow.hubPinned;
          if (!islandWindow.hubPinned && !islandWindow.pointerInside) {
            islandWindow.hubExpanded = false;
          }
        }
        onRequestSelectModule: (modId) => {
          islandWindow.selectedHubModule = modId;
        }
        onRequestCollapse: {
          islandWindow.hubPinned = false;
          islandWindow.hubExpanded = false;
        }

        opacity: islandWindow.isExpandedHub ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      }

      // 3. Incoming Notification View
      DynamicIslandNotifView {
        id: notifView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 11
        theme: islandWindow.theme
        font: islandWindow.font
        notification: islandWindow.currentNotif
        queueCount: islandWindow.activeNotifications.length
        currentIndex: islandWindow.notifIndex
        expanded: islandWindow.isNotifMode && islandWindow.pointerInside
        onRequestCycle: (delta) => {
          if (islandWindow.activeNotifications.length <= 1) return;
          islandWindow.notifIndex = (islandWindow.notifIndex + delta + islandWindow.activeNotifications.length) % islandWindow.activeNotifications.length;
        }

        opacity: islandWindow.isNotifMode ? 1.0 : 0.0
        scale: islandWindow.isNotifMode ? 1.0 : 0.94
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
      }

      // 4. Optional OSD Flash Pill View (Volume / Brightness)
      RowLayout {
        id: osdView
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10
        opacity: islandWindow.isOsdMode ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Text {
          text: islandWindow.osdIcon
          font.family: islandWindow.font
          font.pixelSize: 15
          color: islandWindow.osdMuted ? islandWindow.theme.accentRed : islandWindow.theme.accentPrimary
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 6
          radius: 3
          color: Qt.rgba(islandWindow.theme.textPrimary.r, islandWindow.theme.textPrimary.g, islandWindow.theme.textPrimary.b, 0.14)

          Rectangle {
            width: parent.width * islandWindow.osdValue
            height: parent.height
            radius: parent.radius
            color: islandWindow.osdMuted ? islandWindow.theme.textMuted : islandWindow.theme.accentPrimary
            Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
          }
        }

        Text {
          text: islandWindow.osdValueText
          font.family: islandWindow.font
          font.pixelSize: 11
          font.bold: true
          color: islandWindow.osdMuted ? islandWindow.theme.accentRed : islandWindow.theme.textPrimary
          Layout.preferredWidth: 36
          horizontalAlignment: Text.AlignRight
        }
      }
    }
  }
}
