import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../notifications"
import ".."

Item {
  id: root

  required property var hostRoot
  required property var theme
  required property string font
  property color accent: theme.accentPrimary

  property var enabledModules: ["mpris", "calendar", "notifications", "weather", "quickControls", "systemStats"]
  property string layoutMode: "tabs" // "tabs" | "split"
  property var splitModules: ["mpris", "calendar"]
  property var controlTiles: []
  property var appShortcuts: []
  property string activeModule: "mpris"
  property bool pinned: false

  signal requestTogglePin()
  signal requestSelectModule(string modId)
  signal requestCollapse()

  readonly property var resolvedModules: {
    const src = Array.isArray(enabledModules) && enabledModules.length > 0
      ? enabledModules
      : ["mpris", "calendar"];
    const valid = ["mpris", "calendar", "notifications", "weather", "quickControls", "appShortcuts", "systemStats"];
    const out = [];
    for (let i = 0; i < src.length; i++) {
      if (valid.indexOf(src[i]) !== -1 && out.indexOf(src[i]) === -1) out.push(src[i]);
    }
    return out.length > 0 ? out : ["mpris", "calendar"];
  }

  readonly property var tabStripModules: {
    if (!isSplitMode) return resolvedModules;
    const out = [splitLeftId];
    for (let i = 0; i < resolvedModules.length; i++) {
      if (resolvedModules[i] !== splitLeftId) out.push(resolvedModules[i]);
    }
    return out;
  }

  readonly property bool isSplitMode: layoutMode === "split" && resolvedModules.length >= 2

  readonly property string splitLeftId: {
    const sm = Array.isArray(splitModules) ? splitModules : [];
    if (sm.length >= 1 && resolvedModules.indexOf(sm[0]) !== -1) return sm[0];
    return resolvedModules[0] || "mpris";
  }

  readonly property string splitRightId: {
    const sm = Array.isArray(splitModules) ? splitModules : [];
    if (sm.length >= 2 && resolvedModules.indexOf(sm[1]) !== -1 && sm[1] !== splitLeftId) return sm[1];
    for (let i = 0; i < resolvedModules.length; i++) {
      if (resolvedModules[i] !== splitLeftId) return resolvedModules[i];
    }
    return resolvedModules[0] || "calendar";
  }

  // Secondary module override in split mode (when user clicks a Misc tab below)
  property string splitOverrideRightId: ""
  readonly property string effectiveSplitRightId: (splitOverrideRightId !== "" && resolvedModules.indexOf(splitOverrideRightId) !== -1 && splitOverrideRightId !== splitLeftId)
    ? splitOverrideRightId
    : splitRightId

  readonly property string effectiveActiveModule: {
    if (resolvedModules.indexOf(activeModule) !== -1) return activeModule;
    return resolvedModules[0] || "mpris";
  }

  // Animated displayed module state for directional slide+fade transitions (like Calendar month switch)
  property string displayedModule: effectiveActiveModule
  property string displayedSplitRightId: effectiveSplitRightId

  onEffectiveActiveModuleChanged: {
    if (!root.visible || displayedModule === effectiveActiveModule) {
      singleTabAnim.stop();
      displayedModule = effectiveActiveModule;
      singleModWrap.opacity = 1.0;
      singleModShift.x = 0;
      return;
    }
    const oldIdx = resolvedModules.indexOf(displayedModule);
    const newIdx = resolvedModules.indexOf(effectiveActiveModule);
    const dir = (oldIdx !== -1 && newIdx !== -1 && newIdx < oldIdx) ? -1 : 1;
    if (singleTabAnim.running) singleTabAnim.complete();
    singleTabAnim.direction = dir;
    singleTabAnim.targetModule = effectiveActiveModule;
    singleTabAnim.restart();
  }

  onEffectiveSplitRightIdChanged: {
    if (!root.visible || displayedSplitRightId === effectiveSplitRightId) {
      splitRightAnim.stop();
      displayedSplitRightId = effectiveSplitRightId;
      splitRightWrap.opacity = 1.0;
      splitRightShift.x = 0;
      return;
    }
    const oldIdx = resolvedModules.indexOf(displayedSplitRightId);
    const newIdx = resolvedModules.indexOf(effectiveSplitRightId);
    const dir = (oldIdx !== -1 && newIdx !== -1 && newIdx < oldIdx) ? -1 : 1;
    if (splitRightAnim.running) splitRightAnim.complete();
    splitRightAnim.direction = dir;
    splitRightAnim.targetModule = effectiveSplitRightId;
    splitRightAnim.restart();
  }

  SequentialAnimation {
    id: singleTabAnim
    property int direction: 1
    property string targetModule: "mpris"

    ParallelAnimation {
      NumberAnimation { target: singleModWrap; property: "opacity"; to: 0.0; duration: 85; easing.type: Easing.InQuad }
      NumberAnimation { target: singleModShift; property: "x"; to: singleTabAnim.direction * -18; duration: 85; easing.type: Easing.InQuad }
    }
    ScriptAction {
      script: {
        root.displayedModule = singleTabAnim.targetModule;
        singleModShift.x = singleTabAnim.direction * 18;
      }
    }
    ParallelAnimation {
      NumberAnimation { target: singleModWrap; property: "opacity"; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
      NumberAnimation { target: singleModShift; property: "x"; to: 0; duration: 160; easing.type: Easing.OutCubic }
    }
  }

  SequentialAnimation {
    id: splitRightAnim
    property int direction: 1
    property string targetModule: "calendar"

    ParallelAnimation {
      NumberAnimation { target: splitRightWrap; property: "opacity"; to: 0.0; duration: 85; easing.type: Easing.InQuad }
      NumberAnimation { target: splitRightShift; property: "x"; to: splitRightAnim.direction * -16; duration: 85; easing.type: Easing.InQuad }
    }
    ScriptAction {
      script: {
        root.displayedSplitRightId = splitRightAnim.targetModule;
        splitRightShift.x = splitRightAnim.direction * 16;
      }
    }
    ParallelAnimation {
      NumberAnimation { target: splitRightWrap; property: "opacity"; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
      NumberAnimation { target: splitRightShift; property: "x"; to: 0; duration: 160; easing.type: Easing.OutCubic }
    }
  }

  function moduleMeta(modId) {
    switch (modId) {
      case "mpris":         return { id: "mpris",         label: "Media",    icon: "󰎆" };
      case "calendar":      return { id: "calendar",      label: "Calendar", icon: "󰃭" };
      case "notifications": return { id: "notifications", label: "Notifs",   icon: "󰂚" };
      case "weather":       return { id: "weather",       label: "Weather",  icon: "󰖐" };
      case "quickControls": return { id: "quickControls", label: "Controls", icon: "󰕰" };
      case "appShortcuts":  return { id: "appShortcuts",  label: "Apps",     icon: "󰀻" };
      case "systemStats":   return { id: "systemStats",   label: "System",   icon: "󰻠" };
      default:              return { id: modId,           label: modId,      icon: "󰄲" };
    }
  }

  function componentForModule(modId) {
    switch (modId) {
      case "mpris":         return mprisComp;
      case "calendar":      return calendarComp;
      case "notifications": return notifsComp;
      case "weather":       return weatherComp;
      case "quickControls": return controlsComp;
      case "appShortcuts":  return appsComp;
      case "systemStats":   return systemComp;
      default:              return mprisComp;
    }
  }

  function cycleModule(step) {
    const list = resolvedModules;
    if (list.length <= 1) return;
    if (isSplitMode) {
      const others = list.filter(m => m !== splitLeftId);
      if (others.length <= 1) return;
      const curIdx = others.indexOf(effectiveSplitRightId);
      const nextIdx = (curIdx + step + others.length) % others.length;
      splitOverrideRightId = others[nextIdx];
      return;
    }
    const idx = list.indexOf(effectiveActiveModule);
    const next = (idx + step + list.length) % list.length;
    root.requestSelectModule(list[next]);
  }

  implicitHeight: hubCol.implicitHeight
  height: implicitHeight

  Component {
    id: mprisComp
    DynamicIslandMediaModule {
      theme: root.theme
      font: root.font
      accent: root.accent
    }
  }
  Component {
    id: calendarComp
    DynamicIslandCalendarModule {
      theme: root.theme
      font: root.font
      accent: root.accent
    }
  }
  Component {
    id: notifsComp
    DynamicIslandNotifListModule {
      theme: root.theme
      font: root.font
      accent: root.accent
    }
  }
  Component {
    id: weatherComp
    DynamicIslandWeatherModule {
      theme: root.theme
      font: root.font
      accent: root.accent
    }
  }
  Component {
    id: controlsComp
    DynamicIslandControlsModule {
      hostRoot: root.hostRoot
      theme: root.theme
      font: root.font
      accent: root.accent
      customControlTiles: root.controlTiles
      onRequestCollapse: root.requestCollapse()
    }
  }
  Component {
    id: appsComp
    DynamicIslandAppsModule {
      theme: root.theme
      font: root.font
      accent: root.accent
      appShortcuts: root.appShortcuts
      onRequestCollapse: root.requestCollapse()
    }
  }
  Component {
    id: systemComp
    DynamicIslandSystemModule {
      theme: root.theme
      font: root.font
      accent: root.accent
    }
  }

  ColumnLayout {
    id: hubCol
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 10

    // Top Navigation Pill Strip + Pin Button
    RowLayout {
      Layout.fillWidth: true
      spacing: 6

      // Wheel scroll anywhere on tab strip cycles modules
      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 28

        WheelHandler {
          onWheel: (event) => {
            if (event.angleDelta.y > 0) root.cycleModule(-1);
            else if (event.angleDelta.y < 0) root.cycleModule(1);
          }
        }

        Row {
          id: tabStripRow
          anchors.verticalCenter: parent.verticalCenter
          spacing: 4

          Repeater {
            model: root.tabStripModules
            delegate: Rectangle {
              id: tabBtn
              required property string modelData
              readonly property var meta: root.moduleMeta(modelData)
              readonly property bool isLockedLeft: root.isSplitMode && modelData === root.splitLeftId
              readonly property bool isSelected: root.isSplitMode
                ? (modelData === root.splitLeftId || modelData === root.effectiveSplitRightId)
                : (modelData === root.effectiveActiveModule)
              readonly property int notifBadge: (modelData === "notifications" && !NotificationService.doNotDisturb) ? NotificationService.historyCount : 0

              implicitWidth: tabInnerRow.implicitWidth + (isLockedLeft ? 14 : (isSelected ? 16 : 12))
              height: 26
              radius: 13
              color: isSelected
                ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
                : (tabHover.hovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.10) : "transparent")
              border.color: isSelected ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45) : "transparent"
              border.width: 1
              scale: isLockedLeft ? 1.0 : (tabMouse.pressed ? 0.92 : (tabHover.hovered ? 1.04 : 1.0))
              Behavior on color { ColorAnimation { duration: 140 } }
              Behavior on border.color { ColorAnimation { duration: 140 } }
              Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
              Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

              HoverHandler { id: tabHover }

              Row {
                id: tabInnerRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: tabBtn.meta.icon
                  font.family: root.font
                  font.pixelSize: 12
                  color: tabBtn.isSelected ? root.accent : (tabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                }

                Text {
                  visible: !tabBtn.isLockedLeft && (tabBtn.isSelected || root.resolvedModules.length <= 4)
                  anchors.verticalCenter: parent.verticalCenter
                  text: tabBtn.meta.label
                  font.family: root.font
                  font.pixelSize: 11
                  font.bold: tabBtn.isSelected
                  color: tabBtn.isSelected ? root.theme.textPrimary : root.theme.textSecondary
                }

                Rectangle {
                  visible: tabBtn.notifBadge > 0
                  anchors.verticalCenter: parent.verticalCenter
                  width: Math.max(14, badgeTxt.implicitWidth + 5)
                  height: 14
                  radius: 7
                  color: root.theme.accentRed
                  Text {
                    id: badgeTxt
                    anchors.centerIn: parent
                    text: tabBtn.notifBadge > 99 ? "99+" : String(tabBtn.notifBadge)
                    font.family: root.font
                    font.pixelSize: 8
                    font.bold: true
                    color: root.theme.bgBase
                  }
                }
              }

              MouseArea {
                id: tabMouse
                anchors.fill: parent
                cursorShape: tabBtn.isLockedLeft ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: {
                  if (root.isSplitMode) {
                    if (!tabBtn.isLockedLeft) {
                      root.splitOverrideRightId = tabBtn.modelData;
                    }
                  } else {
                    root.requestSelectModule(tabBtn.modelData);
                  }
                }
              }
            }
          }
        }
      }

      // Pin Button (clean icon-only, no circular pill/border)
      Item {
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22
        scale: pinMouse.pressed ? 0.86 : (pinHover.hovered ? 1.12 : 1.0)
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

        HoverHandler { id: pinHover }

        Text {
          anchors.centerIn: parent
          text: root.pinned ? "󰐃" : "󰤱"
          font.family: root.font
          font.pixelSize: 13
          color: root.pinned ? root.accent : (pinHover.hovered ? root.theme.textPrimary : root.theme.textMuted)
          Behavior on color { ColorAnimation { duration: 140 } }
        }

        MouseArea {
          id: pinMouse
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.requestTogglePin()
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      height: 1
      color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08)
    }

    // Tabbed Single-Module Content (with directional slide + fade transition)
    Item {
      visible: !root.isSplitMode
      Layout.fillWidth: true
      Layout.preferredHeight: singleModLoader.item ? singleModLoader.item.implicitHeight : 100
      clip: true

      Item {
        id: singleModWrap
        anchors.left: parent.left
        anchors.right: parent.right
        height: singleModLoader.item ? singleModLoader.item.implicitHeight : 100
        transform: Translate { id: singleModShift; x: 0 }

        Loader {
          id: singleModLoader
          active: !root.isSplitMode && root.visible
          anchors.left: parent.left
          anchors.right: parent.right
          height: item ? item.implicitHeight : 100
          sourceComponent: root.componentForModule(root.displayedModule)
          onLoaded: {
            if (item) item.width = Qt.binding(() => singleModLoader.width);
          }
        }
      }
    }

    // Split Dashboard Content (2 side-by-side modules, right pane animated on switch)
    RowLayout {
      visible: root.isSplitMode
      Layout.fillWidth: true
      spacing: 14

      Loader {
        id: splitLeftLoader
        active: root.isSplitMode && root.visible
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        Layout.preferredHeight: item ? item.implicitHeight : 100
        sourceComponent: root.componentForModule(root.splitLeftId)
        onLoaded: {
          if (item) item.width = Qt.binding(() => splitLeftLoader.width);
        }
      }

      Rectangle {
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        Layout.minimumHeight: 80
        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.10)
      }

      Item {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        Layout.preferredHeight: splitRightLoader.item ? splitRightLoader.item.implicitHeight : 100
        clip: true

        Item {
          id: splitRightWrap
          anchors.left: parent.left
          anchors.right: parent.right
          height: splitRightLoader.item ? splitRightLoader.item.implicitHeight : 100
          transform: Translate { id: splitRightShift; x: 0 }

          Loader {
            id: splitRightLoader
            active: root.isSplitMode && root.visible
            anchors.left: parent.left
            anchors.right: parent.right
            height: item ? item.implicitHeight : 100
            sourceComponent: root.componentForModule(root.displayedSplitRightId)
            onLoaded: {
              if (item) item.width = Qt.binding(() => splitRightLoader.width);
            }
          }
        }
      }
    }
  }
}
