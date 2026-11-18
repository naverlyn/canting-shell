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
  property var hoveredToplevel: null
  property string hoveredTitle: ""
  property string hoveredSubtitle: ""
  property string hoveredIconSource: ""
  property int hoveredWsId: -1

  readonly property int iconSize: hostContainer.scaled(15)
  readonly property int horizPillHeight: hostContainer.horizPillHeight

  implicitWidth: taskList.length > 0 ? taskGrid.implicitWidth : 0
  implicitHeight: taskList.length > 0
    ? (hostContainer.isVert ? taskGrid.implicitHeight : (hostContainer.hidePill ? hostContainer.height : horizPillHeight))
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
          if (taskContainer.effectiveMode === "icon") return Math.max(hostContainer.scaled(28), taskContainer.iconSize + hostContainer.scaled(12));
          const textW = Math.min(titleMeasure.implicitWidth, taskContainer.adaptiveLabelWidth);
          if (taskContainer.effectiveMode === "icon_desc") {
            return Math.max(hostContainer.scaled(44), taskContainer.iconSize + 6 + textW + 16);
          }
          return Math.max(hostContainer.scaled(36), textW + 16);
        }

        Accessible.role: Accessible.Button
        Accessible.name: windowTitle + (isFocused ? ", focused" : "")

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
            taskContainer.hoveredToplevel = taskPill.modelData;
            taskContainer.hoveredTitle = taskPill.windowTitle;
            taskContainer.hoveredIconSource = taskPill.iconSource;
            taskContainer.hoveredWsId = taskPill.wsId;
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
    id: taskInfoPopup
    target: taskContainer.hoveredPill ? taskContainer.hoveredPill : taskContainer
    barItem: taskContainer.hostContainer
    hovered: taskContainer.hoveredPill !== null
    theme: taskContainer.hostRoot ? taskContainer.hostRoot.theme : ({})
    font: taskContainer.hostRoot ? taskContainer.hostRoot.font : "Lato Nerd Font"
    title: taskContainer.hoveredTitle
    icon: "󰖯"
    summaryText: taskContainer.hoveredSubtitle
    preferredWidth: 256
    accent: taskContainer.hostContainer && taskContainer.hostRoot
      ? taskContainer.hostContainer.wAccent("taskSwitcher", taskContainer.hostRoot.theme.accentPrimary)
      : "#89b4fa"
    barPosition: taskContainer.hostContainer ? taskContainer.hostContainer.barPos : "top"

    contentComponent: Component {
      ColumnLayout {
        spacing: 8
        readonly property var th: taskInfoPopup.theme

        // Window Header: App Icon + Title + Workspace Badge
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
            visible: taskContainer.hoveredWsId > 0
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: wsBadgeTxt.implicitWidth + 10
            implicitHeight: 18
            radius: 5
            color: Qt.rgba(th.textPrimary.r, th.textPrimary.g, th.textPrimary.b, 0.08)

            Text {
              id: wsBadgeTxt
              anchors.centerIn: parent
              text: "WS " + taskContainer.hoveredWsId
              font.family: taskInfoPopup.font
              font.pixelSize: 10
              font.bold: true
              color: th.textSecondary
            }
          }
        }

        // Live Window Thumbnail Preview
        Rectangle {
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
