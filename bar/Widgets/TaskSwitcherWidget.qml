import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
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
      if (n === "openwindow" || n === "closewindow" || n === "destroywindow"
          || n === "movewindow" || n === "movewindowv2"
          || n === "windowtitle" || n === "windowtitlev2")
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

  function isValidTaskToplevel(t) {
    if (!t || !t.address) return false;

    const ws = t.workspace;
    const wsId = ws ? ws.id : -1;
    const wsName = ws && ws.name ? String(ws.name) : "";
    if (!ws || (wsId <= 0 && !wsName.startsWith("special:"))) return false;

    const ipc = t.lastIpcObject;
    if (ipc) {
      if (ipc.mapped === false || ipc.hidden === true) return false;
      if (Array.isArray(ipc.size) && (ipc.size[0] <= 1 || ipc.size[1] <= 1)) return false;
      const cls = String(ipc.class || ipc.initialClass || "").toLowerCase();
      if (cls === "xsettingsd" || cls === "xwaylandvideobridge") return false;
    } else if (!t.wayland) {
      return false;
    }

    const title = String(t.title || "").trim().toLowerCase();
    if (title === "xsettingsd") return false;

    return true;
  }

  readonly property var taskList: {
    const _rev = Hyprland.toplevels.values;
    const activeWs = taskContainer.activeWsId;
    const onlyCurWs = taskContainer.scopeMode === "workspace";
    const list = [];
    for (let i = 0; i < _rev.length; i++) {
      const t = _rev[i];
      if (!taskContainer.isValidTaskToplevel(t)) continue;
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

  readonly property var groupedTaskList: {
    const list = taskContainer.taskList;
    const groups = [];
    const byKey = {};
    for (let i = 0; i < list.length; i++) {
      const t = list[i];
      const ipc = t.lastIpcObject;
      const appClass = (ipc && (ipc.class || ipc.initialClass)) ? String(ipc.class || ipc.initialClass).trim() : "";
      const key = appClass !== "" ? appClass.toLowerCase() : ("addr:" + String(t.address));
      let grp = byKey[key];
      if (!grp) {
        grp = {
          key: key,
          appClass: appClass,
          windows: [],
          primaryToplevel: t,
          isFocused: false,
          count: 0
        };
        byKey[key] = grp;
        groups.push(grp);
      }
      grp.windows.push(t);
      grp.count = grp.windows.length;
      if (Boolean(t.activated)) {
        grp.isFocused = true;
        grp.primaryToplevel = t;
      }
    }
    return groups;
  }

  function syncHoveredFromGroup(group, pill, updatePill) {
    if (!group) {
      hoveredPill = null;
      hoveredGroup = null;
      hoveredToplevel = null;
      return;
    }
    if (updatePill) hoveredPill = pill;
    hoveredGroup = group;
    if (!hoveredToplevel || !group.windows.includes(hoveredToplevel)) {
      hoveredToplevel = group.primaryToplevel;
    }
    const primary = group.primaryToplevel;
    const cls = group.appClass || "";
    const entry = cls !== "" ? DesktopEntries.heuristicLookup(cls) : null;
    const appName = (entry && entry.name && entry.name.trim() !== "")
      ? entry.name
      : (cls !== "" ? cls : "Window");
    const winTitle = (group.count === 1 && primary && primary.title && primary.title.trim() !== "")
      ? primary.title
      : appName;
    hoveredTitle = winTitle;
    hoveredIconSource = (entry && entry.icon) ? Quickshell.iconPath(entry.icon, true) : "";
    hoveredWsId = (primary && primary.workspace) ? primary.workspace.id : -1;
    const subCls = cls !== "" ? cls : "Window";
    if (group.count > 1) {
      hoveredSubtitle = subCls + " • " + group.count + " windows";
    } else {
      hoveredSubtitle = hoveredWsId > 0 ? (subCls + " • Workspace " + hoveredWsId) : subCls;
    }
  }

  onGroupedTaskListChanged: {
    if (!hoveredGroup) return;
    const wasPillHovered = hoveredPill !== null;
    if (!wasPillHovered && !taskInfoPopup.isDetailsActive) {
      syncHoveredFromGroup(null, null, true);
      return;
    }
    const idx = groupedTaskList.findIndex(g => g.key === hoveredGroup.key);
    if (idx < 0) {
      syncHoveredFromGroup(null, null, true);
    } else {
      const newPill = wasPillHovered ? taskRepeater.itemAt(idx) : null;
      syncHoveredFromGroup(groupedTaskList[idx], newPill, wasPillHovered);
    }
  }

  // Adaptive per-item label cap so many open windows don't crowd adjacent bar sections
  readonly property int adaptiveLabelWidth: {
    const count = Math.max(1, groupedTaskList.length);
    if (count <= 3) return maxLabelWidth;
    return Math.max(64, Math.min(maxLabelWidth, Math.floor(420 / count)));
  }

  property var hoveredPill: null
  property var hoveredGroup: null
  property var hoveredToplevel: null
  property string hoveredTitle: ""
  property string hoveredSubtitle: ""
  property string hoveredIconSource: ""
  property int hoveredWsId: -1

  readonly property int iconSize: hostContainer.scaled(15)
  readonly property int horizPillHeight: hostContainer.horizPillHeight

  implicitWidth: groupedTaskList.length > 0 ? taskGrid.implicitWidth : 0
  implicitHeight: groupedTaskList.length > 0
    ? (hostContainer.isVert ? taskGrid.implicitHeight : (hostContainer.hidePill ? hostContainer.height : horizPillHeight))
    : 0
  Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
  Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
  width: implicitWidth
  height: hostContainer.isVert ? implicitHeight : (groupedTaskList.length > 0 ? hostContainer.height : 0)
  visible: width > 0 || groupedTaskList.length > 0
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

  function focusGroup(group) {
    if (!group || !group.windows || group.windows.length === 0) return;
    if (group.windows.length === 1) {
      focusTask(group.windows[0]);
      return;
    }
    const curIdx = group.windows.findIndex(t => Boolean(t.activated));
    const nextIdx = curIdx >= 0 ? (curIdx + 1) % group.windows.length : 0;
    focusTask(group.windows[nextIdx]);
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
      model: taskContainer.groupedTaskList

      Rectangle {
        id: taskPill
        required property var modelData

        readonly property var groupWindows: (modelData && modelData.windows) ? modelData.windows : []
        readonly property int windowCount: (modelData && modelData.count) ? modelData.count : 0
        readonly property var primaryToplevel: (modelData && modelData.primaryToplevel) ? modelData.primaryToplevel : null
        readonly property string appClass: (modelData && modelData.appClass) ? modelData.appClass : ""
        readonly property var desktopEntry: appClass !== "" ? DesktopEntries.heuristicLookup(appClass) : null
        readonly property string appDisplayName: (desktopEntry && desktopEntry.name && desktopEntry.name.trim() !== "")
          ? desktopEntry.name
          : (appClass !== "" ? appClass : "Window")
        readonly property string windowTitle: {
          if (windowCount > 1) return appDisplayName;
          if (primaryToplevel && primaryToplevel.title && primaryToplevel.title.trim() !== "") {
            return primaryToplevel.title;
          }
          return appDisplayName;
        }
        readonly property int wsId: (primaryToplevel && primaryToplevel.workspace) ? primaryToplevel.workspace.id : -1
        readonly property bool isFocused: Boolean(modelData && modelData.isFocused)
        readonly property string iconSource: (desktopEntry && desktopEntry.icon) ? Quickshell.iconPath(desktopEntry.icon, true) : ""

        readonly property bool showIcon: taskContainer.effectiveMode === "icon" || taskContainer.effectiveMode === "icon_desc"
        readonly property bool showDesc: taskContainer.effectiveMode === "icon_desc" || taskContainer.effectiveMode === "desc"

        readonly property int badgeExtraWidth: (showDesc && windowCount > 1) ? (countBadgePill.implicitWidth + 6) : 0

        readonly property int contentWidth: {
          if (taskContainer.effectiveMode === "icon") return Math.max(hostContainer.scaled(28), taskContainer.iconSize + hostContainer.scaled(12));
          const textW = Math.min(titleMeasure.implicitWidth, taskContainer.adaptiveLabelWidth);
          if (taskContainer.effectiveMode === "icon_desc") {
            return Math.max(hostContainer.scaled(44), taskContainer.iconSize + 6 + textW + badgeExtraWidth + 16);
          }
          return Math.max(hostContainer.scaled(36), textW + badgeExtraWidth + 16);
        }

        Accessible.role: Accessible.Button
        Accessible.name: windowTitle + (windowCount > 1 ? (" (" + windowCount + " windows)") : "") + (isFocused ? ", focused" : "")

        width: hostContainer.isVert ? hostContainer.vertPillWidth : contentWidth
        implicitWidth: width
        height: hostContainer.isVert ? Math.max(hostContainer.scaled(26), taskContainer.iconSize + 10) : (hostContainer.hidePill ? hostContainer.height : taskContainer.horizPillHeight)
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
            Layout.preferredWidth: taskContainer.iconSize
            Layout.preferredHeight: taskContainer.iconSize
            Layout.alignment: Qt.AlignVCenter | (taskPill.showDesc ? Qt.AlignLeft : Qt.AlignHCenter)
            Layout.fillWidth: !taskPill.showDesc

            IconImage {
              anchors.centerIn: parent
              width: taskContainer.iconSize
              height: taskContainer.iconSize
              source: taskPill.iconSource
              visible: taskPill.iconSource !== ""
            }

            Text {
              anchors.centerIn: parent
              visible: taskPill.iconSource === ""
              text: "󰖯"
              font.family: hostRoot ? hostRoot.font : "Lato Nerd Font"
              font.pixelSize: Math.max(10, Math.round(taskContainer.iconSize * 0.87))
              color: taskPill.isFocused && hostContainer.activeStyle === "pill"
                ? hostRoot.theme.bgBase
                : (hostContainer.hasCustomColor("taskSwitcher")
                    ? hostContainer.wAccent("taskSwitcher", hostRoot.theme.textPrimary)
                    : hostRoot.theme.textPrimary)
            }

            // Compact count dot badge in icon-only mode when multiple windows are grouped
            Rectangle {
              visible: !taskPill.showDesc && taskPill.windowCount > 1
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.rightMargin: -4
              anchors.bottomMargin: -3
              implicitWidth: Math.max(13, iconCountTxt.implicitWidth + 5)
              height: 13
              radius: 6.5
              color: taskPill.isFocused && hostContainer.activeStyle === "pill"
                ? hostRoot.theme.bgBase
                : hostContainer.wAccent("taskSwitcher", hostRoot.theme.accentPrimary)
              border.width: 1
              border.color: hostRoot.theme.bgSurface

              Text {
                id: iconCountTxt
                anchors.centerIn: parent
                text: taskPill.windowCount > 9 ? "9+" : String(taskPill.windowCount)
                font.family: hostRoot ? hostRoot.font : "Lato Nerd Font"
                font.pixelSize: 8
                font.bold: true
                color: taskPill.isFocused && hostContainer.activeStyle === "pill"
                  ? hostContainer.wAccent("taskSwitcher", hostRoot.theme.accentPrimary)
                  : hostRoot.theme.bgBase
              }
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

          // Window count pill badge when multiple windows of the same app are merged
          Rectangle {
            id: countBadgePill
            visible: taskPill.showDesc && taskPill.windowCount > 1
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Math.max(16, countBadgeTxt.implicitWidth + 8)
            height: 16
            radius: 8
            color: taskPill.isFocused && hostContainer.activeStyle === "pill"
              ? Qt.rgba(hostRoot.theme.bgBase.r, hostRoot.theme.bgBase.g, hostRoot.theme.bgBase.b, 0.22)
              : Qt.rgba(hostRoot.theme.textPrimary.r, hostRoot.theme.textPrimary.g, hostRoot.theme.textPrimary.b, 0.12)
            border.width: 1
            border.color: taskPill.isFocused && hostContainer.activeStyle === "pill"
              ? Qt.rgba(hostRoot.theme.bgBase.r, hostRoot.theme.bgBase.g, hostRoot.theme.bgBase.b, 0.28)
              : Qt.rgba(hostRoot.theme.textPrimary.r, hostRoot.theme.textPrimary.g, hostRoot.theme.textPrimary.b, 0.14)

            Text {
              id: countBadgeTxt
              anchors.centerIn: parent
              text: taskPill.windowCount > 9 ? "9+" : String(taskPill.windowCount)
              font.family: hostRoot ? hostRoot.font : "Lato Nerd Font"
              font.pixelSize: 9
              font.bold: true
              color: taskPill.isFocused && hostContainer.activeStyle === "pill"
                ? hostRoot.theme.bgBase
                : (taskPill.isFocused
                    ? hostContainer.wAccent("taskSwitcher", hostRoot.theme.accentPrimary)
                    : hostRoot.theme.textSecondary)
            }
          }
        }

        MouseArea {
          id: taskMouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton
          cursorShape: Qt.PointingHandCursor
          onEntered: {
            taskContainer.hoveredToplevel = taskPill.primaryToplevel;
            taskContainer.syncHoveredFromGroup(taskPill.modelData, taskPill, true);
          }
          onExited: {
            if (taskContainer.hoveredPill === taskPill) {
              taskContainer.hoveredPill = null;
            }
          }
          onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
              taskContainer.closeTask(taskPill.primaryToplevel);
            } else {
              taskContainer.focusGroup(taskPill.modelData);
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
    id: taskInfoPopup
    target: taskContainer.hoveredPill ? taskContainer.hoveredPill : taskContainer
    barItem: taskContainer.hostContainer
    hovered: taskContainer.hoveredPill !== null
    theme: taskContainer.hostRoot ? taskContainer.hostRoot.theme : ({})
    font: taskContainer.hostRoot ? taskContainer.hostRoot.font : "Lato Nerd Font"
    title: taskContainer.hoveredTitle
    icon: "󰖯"
    summaryText: taskContainer.hoveredSubtitle
    readonly property int hoveredGroupCount: (taskContainer.hoveredGroup && taskContainer.hoveredGroup.count > 1)
      ? taskContainer.hoveredGroup.count
      : 1
    readonly property int previewCols: Math.min(4, hoveredGroupCount)
    readonly property int previewTileW: 206
    readonly property int previewTileGap: 8

    preferredWidth: hoveredGroupCount > 1
      ? (previewCols * previewTileW + (previewCols - 1) * previewTileGap)
      : 256
    accent: taskContainer.hostContainer && taskContainer.hostRoot
      ? taskContainer.hostContainer.wAccent("taskSwitcher", taskContainer.hostRoot.theme.accentPrimary)
      : "#89b4fa"
    barPosition: taskContainer.hostContainer ? taskContainer.hostContainer.barPos : "top"

    onIsDetailsActiveChanged: {
      if (!isDetailsActive && taskContainer.hoveredPill === null) {
        taskContainer.hoveredGroup = null;
        taskContainer.hoveredToplevel = null;
      }
    }

    contentComponent: Component {
      ColumnLayout {
        spacing: 8
        readonly property var th: taskInfoPopup.theme
        readonly property bool isGrouped: Boolean(taskContainer.hoveredGroup && taskContainer.hoveredGroup.count > 1)
        readonly property var groupWindows: isGrouped ? taskContainer.hoveredGroup.windows : []

        // Window / App Header: App Icon + Title + Workspace or Count Badge
        RowLayout {
          Layout.fillWidth: true
          spacing: 7

          Item {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter

            IconImage {
              anchors.fill: parent
              source: taskContainer.hoveredIconSource
              visible: taskContainer.hoveredIconSource !== ""
            }

            Text {
              anchors.centerIn: parent
              visible: taskContainer.hoveredIconSource === ""
              text: "󰖯"
              font.family: taskInfoPopup.font
              font.pixelSize: 14
              color: taskInfoPopup.accent
            }
          }

          Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: taskContainer.hoveredTitle
            elide: Text.ElideRight
            font.family: taskInfoPopup.font
            font.pixelSize: 12
            font.bold: true
            color: th.textPrimary
          }

          Rectangle {
            visible: isGrouped || taskContainer.hoveredWsId > 0
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: wsBadgeTxt.implicitWidth + 10
            implicitHeight: 18
            radius: 5
            color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)

            Text {
              id: wsBadgeTxt
              anchors.centerIn: parent
              text: isGrouped
                ? (groupWindows.length + " windows")
                : ("WS " + taskContainer.hoveredWsId)
              font.family: taskInfoPopup.font
              font.pixelSize: 10
              font.bold: true
              color: th.textSecondary
            }
          }

          // Close Button for Single-Window Popup
          Rectangle {
            id: singleCloseBtn
            visible: !isGrouped && taskContainer.hoveredToplevel !== null
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            radius: 5
            color: singleCloseHover.hovered
              ? Qt.rgba(th.accentRed.r, th.accentRed.g, th.accentRed.b, 0.22)
              : Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.06)
            scale: singleCloseMouse.pressed ? 0.84 : (singleCloseHover.hovered ? 1.10 : 1.0)
            opacity: singleCloseHover.hovered ? 1.0 : 0.78

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

            HoverHandler { id: singleCloseHover }

            Text {
              anchors.centerIn: parent
              text: "󰅖"
              font.family: taskInfoPopup.font
              font.pixelSize: 11
              color: singleCloseHover.hovered ? th.accentRed : th.textSecondary
              Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
              id: singleCloseMouse
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (taskContainer.hoveredToplevel) {
                  taskContainer.closeTask(taskContainer.hoveredToplevel);
                }
              }
            }
          }
        }

        // Side-by-Side Live Window Preview Cards (shown when multiple windows are merged)
        Flickable {
          visible: isGrouped
          Layout.fillWidth: true
          implicitHeight: visible ? Math.min(340, groupGrid.implicitHeight) : 0
          contentHeight: groupGrid.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          GridLayout {
            id: groupGrid
            width: parent.width
            columns: taskInfoPopup.previewCols
            rowSpacing: taskInfoPopup.previewTileGap
            columnSpacing: taskInfoPopup.previewTileGap

            Repeater {
              model: groupWindows

              delegate: Rectangle {
                id: winCard
                required property var modelData
                readonly property bool isWinFocused: Boolean(modelData && modelData.activated)
                readonly property int winWsId: (modelData && modelData.workspace) ? modelData.workspace.id : -1
                readonly property string winTitle: (modelData && modelData.title && modelData.title.trim() !== "")
                  ? modelData.title
                  : taskContainer.hoveredTitle

                Layout.fillWidth: true
                Layout.preferredWidth: taskInfoPopup.previewTileW
                implicitHeight: winCardCol.implicitHeight + 12
                radius: 8
                color: winCardHover.hovered
                  ? Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
                  : (isWinFocused ? Qt.rgba(taskInfoPopup.accent.r, taskInfoPopup.accent.g, taskInfoPopup.accent.b, 0.10) : th.bgBase)
                border.width: 1
                border.color: (winCardHover.hovered || isWinFocused)
                  ? taskInfoPopup.accent
                  : Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.12)

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }
                HoverHandler { id: winCardHover }

                MouseArea {
                  anchors.fill: parent
                  acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                  cursorShape: Qt.PointingHandCursor
                  onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton) {
                      taskContainer.closeTask(winCard.modelData);
                    } else {
                      taskContainer.focusTask(winCard.modelData);
                    }
                  }
                }

                ColumnLayout {
                  id: winCardCol
                  anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 6
                  }
                  spacing: 6

                  // Card Header: Focus Dot + Title + WS Badge + Close
                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Rectangle {
                      width: 6
                      height: 6
                      radius: 3
                      Layout.alignment: Qt.AlignVCenter
                      color: winCard.isWinFocused ? taskInfoPopup.accent : th.textMuted
                      opacity: winCard.isWinFocused ? 1.0 : 0.45
                    }

                    Text {
                      Layout.fillWidth: true
                      Layout.alignment: Qt.AlignVCenter
                      text: winCard.winTitle
                      elide: Text.ElideRight
                      font.family: taskInfoPopup.font
                      font.pixelSize: 11
                      font.bold: winCard.isWinFocused
                      color: winCard.isWinFocused ? taskInfoPopup.accent : th.textPrimary
                    }

                    Text {
                      visible: winCard.winWsId > 0
                      Layout.alignment: Qt.AlignVCenter
                      text: "WS " + winCard.winWsId
                      font.family: taskInfoPopup.font
                      font.pixelSize: 9
                      font.bold: true
                      color: th.textMuted
                    }

                    Rectangle {
                      id: winCloseBtn
                      Layout.preferredWidth: 18
                      Layout.preferredHeight: 18
                      Layout.alignment: Qt.AlignVCenter
                      radius: 5
                      color: closeHover.hovered
                        ? Qt.rgba(th.accentRed.r, th.accentRed.g, th.accentRed.b, 0.24)
                        : Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, winCardHover.hovered ? 0.08 : 0.0)
                      scale: closeMouse.pressed ? 0.84 : (closeHover.hovered ? 1.12 : 1.0)
                      opacity: (winCardHover.hovered || closeHover.hovered) ? 1.0 : 0.55

                      Behavior on color { ColorAnimation { duration: 140 } }
                      Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                      Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                      HoverHandler { id: closeHover }

                      Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: taskInfoPopup.font
                        font.pixelSize: 10
                        color: closeHover.hovered ? th.accentRed : th.textSecondary
                        Behavior on color { ColorAnimation { duration: 140 } }
                      }

                      MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: taskContainer.closeTask(winCard.modelData)
                      }
                    }
                  }

                  // Live Thumbnail
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 118
                    radius: 6
                    color: th.bgSurface
                    border.width: 1
                    border.color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)
                    clip: true

                    ScreencopyView {
                      id: cardPreview
                      anchors.fill: parent
                      captureSource: (taskInfoPopup.isDetailsActive && winCard.modelData && winCard.modelData.wayland)
                        ? winCard.modelData.wayland
                        : null
                      live: true
                      paintCursor: false
                      constraintSize: Qt.size(Math.max(1, width), Math.max(1, height))
                      visible: hasContent
                    }

                    Item {
                      anchors.fill: parent
                      visible: !cardPreview.hasContent

                      IconImage {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        source: taskContainer.hoveredIconSource
                        visible: taskContainer.hoveredIconSource !== ""
                        opacity: 0.75
                      }

                      Text {
                        anchors.centerIn: parent
                        visible: taskContainer.hoveredIconSource === ""
                        text: "󰖯"
                        font.family: taskInfoPopup.font
                        font.pixelSize: 22
                        color: th.textMuted
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // Single-Window Live Thumbnail Preview
        Rectangle {
          visible: !isGrouped
          Layout.fillWidth: true
          implicitHeight: 146
          radius: 8
          color: th.bgBase
          border.width: 1
          border.color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.10)
          clip: true

          ScreencopyView {
            id: previewView
            anchors.fill: parent
            captureSource: (taskInfoPopup.isDetailsActive && taskContainer.hoveredToplevel && taskContainer.hoveredToplevel.wayland)
              ? taskContainer.hoveredToplevel.wayland
              : null
            live: true
            paintCursor: false
            constraintSize: Qt.size(Math.max(1, width), Math.max(1, height))
            visible: hasContent
          }

          Item {
            anchors.fill: parent
            visible: !previewView.hasContent

            IconImage {
              anchors.centerIn: parent
              width: 36
              height: 36
              source: taskContainer.hoveredIconSource
              visible: taskContainer.hoveredIconSource !== ""
              opacity: 0.75
            }

            Text {
              anchors.centerIn: parent
              visible: taskContainer.hoveredIconSource === ""
              text: "󰖯"
              font.family: taskInfoPopup.font
              font.pixelSize: 28
              color: th.textMuted
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (taskContainer.hoveredToplevel) {
                taskContainer.focusTask(taskContainer.hoveredToplevel);
              }
            }
          }
        }
      }
    }
  }
}
