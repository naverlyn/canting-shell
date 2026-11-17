import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../Components"
import ".."

Item {
  id: taskContainer
  required property var hostRoot
  required property var hostContainer

  property bool isLua: true

  Process {
    id: configFormatCheck
    command: ["sh", "-c", "[ -f \"$HOME/.config/hypr/hyprland.lua\" ] && echo lua || echo conf"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        taskContainer.isLua = (text.trim() === "lua");
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 80
    repeat: false
    onTriggered: Hyprland.refreshToplevels()
  }

  Connections {
    // NOTE: never refresh on Hyprland.toplevels.valuesChanged - refreshToplevels()
    // itself updates that list, which created an endless refresh loop that
    // rebuilt every task pill continuously and made the whole bar flicker/fade.
    target: Hyprland
    function onRawEvent(event) {
      const n = event.name;
      if (n === "openwindow" || n === "closewindow" || n === "movewindow"
          || n === "movewindowv2" || n === "windowtitle" || n === "windowtitlev2")
        refreshTimer.restart();
    }
  }

  Component.onCompleted: {
    Hyprland.refreshToplevels();
  }

  readonly property string rawMode: BarConfig.taskSwitcherMode || "icon_desc"
  readonly property string effectiveMode: hostContainer.isVert ? "icon" : rawMode
  readonly property string scopeMode: BarConfig.taskSwitcherScope || "all"
  readonly property int maxLabelWidth: Math.max(60, Math.min(280, Number(BarConfig.taskSwitcherMaxLabelWidth) || 140))

  readonly property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

  readonly property var taskList: {
    const _rev = Hyprland.toplevels.values;
    const activeWs = taskContainer.activeWsId;
    const onlyCurWs = taskContainer.scopeMode === "workspace";
    const list = [];
    for (let i = 0; i < _rev.length; i++) {
      const t = _rev[i];
      if (!t || !t.address) continue;
      const wsId = t.workspace ? t.workspace.id : -1;
      if (onlyCurWs && activeWs > 0 && wsId !== activeWs) continue;
      list.push(t);
    }
    list.sort((a, b) => {
      const wa = a.workspace ? a.workspace.id : 9999;
      const wb = b.workspace ? b.workspace.id : 9999;
      if (wa !== wb) return wa - wb;
      const ca = (a.lastIpcObject && (a.lastIpcObject.class || a.lastIpcObject.initialClass)) || "";
      const cb = (b.lastIpcObject && (b.lastIpcObject.class || b.lastIpcObject.initialClass)) || "";
      if (ca !== cb) return ca.localeCompare(cb);
      return String(a.address).localeCompare(String(b.address));
    });
    return list;
  }

  // Adaptive per-item label cap so many open windows don't crowd adjacent bar sections
  readonly property int adaptiveLabelWidth: {
    const count = Math.max(1, taskList.length);
    if (count <= 3) return maxLabelWidth;
    return Math.max(64, Math.min(maxLabelWidth, Math.floor(420 / count)));
  }

  property var hoveredPill: null
  property string hoveredTitle: ""
  property string hoveredSubtitle: ""

  implicitWidth: taskList.length > 0 ? taskGrid.implicitWidth : 0
  implicitHeight: taskList.length > 0
    ? (hostContainer.isVert ? taskGrid.implicitHeight : (hostContainer.hidePill ? hostContainer.height : 24))
    : 0
  Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
  Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
  width: implicitWidth
  height: hostContainer.isVert ? implicitHeight : (taskList.length > 0 ? hostContainer.height : 0)
  visible: width > 0 || taskList.length > 0
  clip: true

  function normalizeAddr(address) {
    if (!address) return "";
    const s = String(address);
    return s.startsWith("0x") ? s : ("0x" + s);
  }

  function focusTask(toplevel) {
    if (!toplevel) return;
    const wsObj = toplevel.workspace;
    if (wsObj && typeof wsObj.activate === "function") {
      wsObj.activate();
    }
    if (toplevel.wayland && typeof toplevel.wayland.activate === "function") {
      toplevel.wayland.activate();
    }
    const addr = normalizeAddr(toplevel.address);
    if (addr !== "") {
      if (taskContainer.isLua) {
        Hyprland.dispatch('hl.dsp.focus({ window = "address:' + addr + '" })');
      } else {
        Hyprland.dispatch("focuswindow address:" + addr);
      }
    }
  }

  function closeTask(toplevel) {
    if (!toplevel) return;
    if (toplevel.wayland && typeof toplevel.wayland.close === "function") {
      toplevel.wayland.close();
      refreshTimer.restart();
      return;
    }
    const addr = normalizeAddr(toplevel.address);
    if (addr !== "") {
      if (taskContainer.isLua) {
        Hyprland.dispatch('hl.dsp.window.close({ window = "address:' + addr + '" })');
      } else {
        Hyprland.dispatch("closewindow address:" + addr);
      }
      refreshTimer.restart();
    }
  }

  function cycleTask(deltaY) {
    const list = taskContainer.taskList;
    if (!list || list.length <= 1) return;
    let curIdx = list.findIndex(t => Boolean(t.activated));
    if (curIdx === -1) curIdx = 0;
    let targetIdx = deltaY > 0 ? curIdx - 1 : curIdx + 1;
    if (targetIdx < 0) targetIdx = list.length - 1;
    else if (targetIdx >= list.length) targetIdx = 0;
    taskContainer.focusTask(list[targetIdx]);
  }

  Grid {
    id: taskGrid
    anchors.centerIn: parent
    columns: hostContainer.isVert ? 1 : Math.max(1, taskRepeater.count)
    spacing: 4
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter

    Repeater {
      id: taskRepeater
      model: taskContainer.taskList

      Rectangle {
        id: taskPill
        required property var modelData

        readonly property string appClass: (modelData && modelData.lastIpcObject && (modelData.lastIpcObject.class || modelData.lastIpcObject.initialClass)) || ""
        readonly property string windowTitle: (modelData && modelData.title && modelData.title.trim() !== "")
          ? modelData.title
          : (appClass !== "" ? appClass : "Window")
        readonly property int wsId: (modelData && modelData.workspace) ? modelData.workspace.id : -1
        readonly property bool isFocused: Boolean(modelData && modelData.activated)
        readonly property var desktopEntry: appClass !== "" ? DesktopEntries.heuristicLookup(appClass) : null
        readonly property string iconSource: (desktopEntry && desktopEntry.icon) ? Quickshell.iconPath(desktopEntry.icon, true) : ""

        readonly property bool showIcon: taskContainer.effectiveMode === "icon" || taskContainer.effectiveMode === "icon_desc"
        readonly property bool showDesc: taskContainer.effectiveMode === "icon_desc" || taskContainer.effectiveMode === "desc"

        readonly property int contentWidth: {
          if (taskContainer.effectiveMode === "icon") return 28;
          const textW = Math.min(titleMeasure.implicitWidth, taskContainer.adaptiveLabelWidth);
          if (taskContainer.effectiveMode === "icon_desc") {
            return Math.max(44, 15 + 6 + textW + 16);
          }
          return Math.max(36, textW + 16);
        }

        Accessible.role: Accessible.Button
        Accessible.name: windowTitle + (isFocused ? ", focused" : "")

        width: hostContainer.isVert ? hostContainer.vertPillWidth : contentWidth
        implicitWidth: width
        height: hostContainer.isVert ? 26 : (hostContainer.hidePill ? hostContainer.height : 24)
        implicitHeight: height

        scale: taskMouse.pressed ? 0.94 : enterScale
        property real enterScale: 0.88
        opacity: enterOpacity
        property real enterOpacity: 0.0
        Behavior on enterScale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on enterOpacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        Component.onCompleted: {
          enterScale = 1.0;
          enterOpacity = 1.0;
        }
        radius: hostContainer.pillRadius
        Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        color: isFocused
          ? (hostContainer.activeStyle === "underline"
              ? (hostContainer.hidePill ? "transparent" : hostRoot.theme.bgSurface)
              : (hostContainer.activeStyle === "both"
                  ? (hostContainer.hasCustomColor("taskSwitcher")
                      ? hostContainer.wBg("taskSwitcher", true)
                      : hostRoot.theme.bgSelected)
                  : hostContainer.wAccent("taskSwitcher", hostRoot.theme.accentPrimary)))
          : (hostContainer.activeStyle === "underline"
              ? (hostContainer.hidePill ? "transparent" : hostRoot.theme.bgSurface)
              : hostContainer.wBg("taskSwitcher", taskMouse.containsMouse))

        border.color: !isFocused && hostContainer.hasCustomColor("taskSwitcher")
          ? hostContainer.wBorder("taskSwitcher")
          : "transparent"
        border.width: (!isFocused && hostContainer.hasCustomColor("taskSwitcher")) ? 1 : 0
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
          id: titleMeasure
          visible: false
          text: taskPill.windowTitle
          font.pixelSize: 12
          font.family: hostRoot ? hostRoot.font : "Lato Nerd Font"
          font.bold: taskPill.isFocused
        }

        PillIndicator {
          hostRoot: taskContainer.hostRoot
          hostContainer: taskContainer.hostContainer
          active: taskPill.isFocused
          hovered: taskMouse.containsMouse
          accentColor: hostContainer.wAccent("taskSwitcher", hostRoot.theme.accentPrimary)
        }

        RowLayout {
          anchors.centerIn: parent
          spacing: 6
          width: parent.width - (taskPill.showDesc ? 14 : 6)

          Item {
            visible: taskPill.showIcon
            Layout.preferredWidth: 15
            Layout.preferredHeight: 15
            Layout.alignment: Qt.AlignVCenter | (taskPill.showDesc ? Qt.AlignLeft : Qt.AlignHCenter)
            Layout.fillWidth: !taskPill.showDesc

            IconImage {
              anchors.centerIn: parent
              width: 15
              height: 15
              source: taskPill.iconSource
              visible: taskPill.iconSource !== ""
            }

            Text {
              anchors.centerIn: parent
              visible: taskPill.iconSource === ""
              text: "󰖯"
              font.family: hostRoot ? hostRoot.font : "Lato Nerd Font"
              font.pixelSize: 13
              color: taskPill.isFocused && hostContainer.activeStyle === "pill"
                ? hostRoot.theme.bgBase
                : (hostContainer.hasCustomColor("taskSwitcher")
                    ? hostContainer.wAccent("taskSwitcher", hostRoot.theme.textPrimary)
                    : hostRoot.theme.textPrimary)
            }
          }

          Text {
            visible: taskPill.showDesc
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: taskPill.windowTitle
            elide: Text.ElideRight
            horizontalAlignment: taskPill.showIcon ? Text.AlignLeft : Text.AlignHCenter
            font.pixelSize: 12
            font.family: hostRoot ? hostRoot.font : "Lato Nerd Font"
            font.bold: taskPill.isFocused
            color: taskPill.isFocused
              ? (hostContainer.activeStyle === "pill"
                  ? hostRoot.theme.bgBase
                  : hostContainer.wAccent("taskSwitcher", hostRoot.theme.accentPrimary))
              : (taskMouse.containsMouse
                  ? hostRoot.theme.textPrimary
                  : (hostContainer.hasCustomColor("taskSwitcher")
                      ? hostContainer.wAccent("taskSwitcher", hostRoot.theme.textPrimary)
                      : hostRoot.theme.textSecondary))
            Behavior on color { ColorAnimation { duration: 120 } }
          }
        }

        MouseArea {
          id: taskMouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton
          cursorShape: Qt.PointingHandCursor
          onEntered: {
            taskContainer.hoveredPill = taskPill;
            taskContainer.hoveredTitle = taskPill.windowTitle;
            const cls = taskPill.appClass !== "" ? taskPill.appClass : "Window";
            taskContainer.hoveredSubtitle = taskPill.wsId > 0
              ? (cls + " • Workspace " + taskPill.wsId)
              : cls;
          }
          onExited: {
            if (taskContainer.hoveredPill === taskPill) {
              taskContainer.hoveredPill = null;
            }
          }
          onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
              taskContainer.closeTask(taskPill.modelData);
            } else {
              taskContainer.focusTask(taskPill.modelData);
            }
          }
          onWheel: wheel => {
            taskContainer.cycleTask(wheel.angleDelta.y);
          }
        }
      }
    }
  }

  InfoPopup {
    target: taskContainer.hoveredPill ? taskContainer.hoveredPill : taskContainer
    barItem: taskContainer.hostContainer
    hovered: taskContainer.hoveredPill !== null
    theme: taskContainer.hostRoot ? taskContainer.hostRoot.theme : ({})
    font: taskContainer.hostRoot ? taskContainer.hostRoot.font : "Lato Nerd Font"
    title: taskContainer.hoveredTitle
    icon: "󰖯"
    summaryText: taskContainer.hoveredSubtitle
    accent: taskContainer.hostContainer && taskContainer.hostRoot
      ? taskContainer.hostContainer.wAccent("taskSwitcher", taskContainer.hostRoot.theme.accentPrimary)
      : "#89b4fa"
    barPosition: taskContainer.hostContainer ? taskContainer.hostContainer.barPos : "top"
  }
}
