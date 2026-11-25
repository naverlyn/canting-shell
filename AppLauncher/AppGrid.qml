import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../bar"
import "../utils/AppFrecencyUtils.js" as AppFrecencyUtils
import "../ThemeSwitcher"

Scope {
  id: root
  property var theme: Theme
  property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"
  property int selectedIndex: 0
  property bool panelVisible: false
  property string searchQuery: ""

  readonly property int cellSize: AppLauncherConfig.gridCellSize
  readonly property int columns: AppLauncherConfig.gridColumns
  readonly property bool isListMode: AppLauncherConfig.appMenuMode === "list"
  readonly property int edgeMargin: 8

  property string activeBarPos: "top"
  property real activeNormX: 0.05
  property real activeNormY: 0.05
  property int activeBarClearance: 0

  property var appUsage: ({})
  readonly property string usageCachePath: "$HOME/.cache/qs_app_usage.json"

  function edgeBarClearance(edgePos) {
    const list = BarConfig.bars || [];
    let maxClearance = 0;
    for (let i = 0; i < list.length; i++) {
      const b = list[i];
      if (!b || b.enabled === false || b.position !== edgePos) continue;
      const h = b.barHeight !== undefined ? b.barHeight : 38;
      const fl = b.floating !== undefined ? b.floating : false;
      const isV = (edgePos === "left" || edgePos === "right");
      const c = isV ? (h + 16 + (fl ? 6 : 0)) : (h + (fl ? 6 : 0));
      if (c > maxClearance) maxClearance = c;
    }
    return maxClearance;
  }

  function resolveDefaultPlacement() {
    const list = BarConfig.bars || [];
    let chosenBar = null;
    let chosenPanelIdx = 0;
    let chosenTotalPanels = 1;

    for (let i = 0; i < list.length; i++) {
      const b = list[i];
      if (!b || b.enabled === false) continue;
      if (!chosenBar) chosenBar = b;
      const bId = b.id ? String(b.id) : ("bar_" + (i + 1));
      if (!BarConfig.isWidgetVisible("appGrid", bId)) continue;
      const panels = Array.isArray(b.panels) ? b.panels : [];
      for (let p = 0; p < panels.length; p++) {
        if (Array.isArray(panels[p]) && panels[p].indexOf("appGrid") !== -1) {
          chosenBar = b;
          chosenPanelIdx = p;
          chosenTotalPanels = panels.length;
          break;
        }
      }
    }

    if (!chosenBar) {
      activeBarPos = BarConfig.position || "top";
      activeNormX = 0.05;
      activeNormY = 0.05;
      activeBarClearance = edgeBarClearance(activeBarPos);
      return;
    }

    const pos = chosenBar.position || "top";
    const frac = chosenTotalPanels <= 1
      ? 0.05
      : (chosenPanelIdx === 0
        ? 0.05
        : (chosenPanelIdx === chosenTotalPanels - 1 ? 0.95 : (chosenPanelIdx / (chosenTotalPanels - 1))));

    activeBarPos = pos;
    if (pos === "left" || pos === "right") {
      activeNormX = pos === "left" ? 0.05 : 0.95;
      activeNormY = frac;
    } else {
      activeNormX = frac;
      activeNormY = pos === "top" ? 0.05 : 0.95;
    }
    activeBarClearance = edgeBarClearance(pos);
  }

  function openOrToggle() {
    root.panelVisible = !root.panelVisible;
    if (root.panelVisible) {
      if (AppLauncherConfig.clearSearchOnClose) {
        root.searchQuery = "";
      }
      root.selectedIndex = 0;
      loadUsageProc.running = true;
    } else {
      Qt.callLater(() => gc());
    }
  }

  Connections {
    target: AppLauncherConfig
    function onUsageCleared() {
      root.appUsage = ({});
    }
  }

  IpcHandler {
    target: "appgrid"

    function toggle() {
      if (!root.panelVisible) {
        root.resolveDefaultPlacement();
      }
      root.openOrToggle();
    }

    function toggleAt(barPos: string, normX: string, normY: string, clearance: string) {
      if (!root.panelVisible) {
        root.activeBarPos = barPos || "top";
        const nx = parseFloat(normX);
        const ny = parseFloat(normY);
        const cl = parseInt(clearance);
        root.activeNormX = isNaN(nx) ? 0.05 : nx;
        root.activeNormY = isNaN(ny) ? 0.05 : ny;
        root.activeBarClearance = isNaN(cl) ? 0 : cl;
      }
      root.openOrToggle();
    }
  }

  Process {
    id: loadUsageProc
    command: ["sh", "-c", `cat "${root.usageCachePath}" 2>/dev/null || echo '{}'`]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const parsed = JSON.parse(text.trim() || "{}");
          if (parsed && typeof parsed === "object") root.appUsage = parsed;
        } catch (e) {
          root.appUsage = ({});
        }
      }
    }
  }

  Process {
    id: saveUsageProc
    running: false
  }

  function getAppKey(entry) {
    return AppFrecencyUtils.getAppKey(entry);
  }

  function getFrecencyScore(entry, usageMap) {
    return AppFrecencyUtils.getFrecencyScore(entry, usageMap);
  }

  function recordAppLaunch(entry) {
    const key = getAppKey(entry);
    if (!key) return;
    const next = Object.assign({}, root.appUsage);
    const prev = next[key] || { count: 0, lastUsed: 0 };
    next[key] = { count: (prev.count || 0) + 1, lastUsed: Date.now() };
    root.appUsage = next;
    saveUsageProc.command = [
      "python3", "-c",
      "import os, sys; p = os.path.expanduser('~/.cache/qs_app_usage.json'); open(p, 'w').write(sys.argv[1])",
      JSON.stringify(next)
    ];
    saveUsageProc.running = true;
  }

  function launchApp(entry) {
    if (entry) {
      recordAppLaunch(entry);
      entry.execute();
      root.panelVisible = false;
    }
  }

  ScriptModel {
    id: filteredApps
    objectProp: "id"
    values: {
      if (!root.panelVisible) return [];
      return AppFrecencyUtils.filterAndSortApps(
        DesktopEntries.applications.values,
        root.searchQuery,
        root.appUsage,
        AppLauncherConfig
      );
    }
  }

  Loader {
    active: root.panelVisible
    sourceComponent: Component {
  PanelWindow {
    id: gridPanel
    visible: true
    focusable: true
    color: "transparent"

    Component.onCompleted: {
      searchInput.text = root.searchQuery;
      openAnim.start();
      Qt.callLater(() => searchInput.forceActiveFocus());
    }

    property bool closing: false

    function requestClose() {
      if (gridPanel.closing) return;
      gridPanel.closing = true;
      openAnim.stop();
      closeAnim.start();
    }

    onVisibleChanged: {
      if (!visible) {
        root.panelVisible = false;
        Qt.callLater(() => gc());
      }
    }

    ParallelAnimation {
      id: openAnim
      NumberAnimation { target: box; property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
      NumberAnimation { target: box; property: "scale"; from: 0.96; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
      id: closeAnim
      NumberAnimation { target: box; property: "opacity"; to: 0.0; duration: 110; easing.type: Easing.InCubic }
      NumberAnimation { target: box; property: "scale"; to: 0.97; duration: 110; easing.type: Easing.InCubic }
      onFinished: gridPanel.visible = false
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-appgrid"

    exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    // Transparent click-outside-to-close area
    MouseArea {
      anchors.fill: parent
      onClicked: gridPanel.requestClose()
    }

    Rectangle {
      id: box
      width: root.isListMode ? 320 : (root.columns * root.cellSize + 32)
      height: 520

      readonly property int topClear: Math.max(
        root.edgeMargin,
        (root.activeBarPos === "top"
          ? Math.max(root.activeBarClearance, root.edgeBarClearance("top"))
          : root.edgeBarClearance("top")) + root.edgeMargin
      )
      readonly property int bottomClear: Math.max(
        root.edgeMargin,
        (root.activeBarPos === "bottom"
          ? Math.max(root.activeBarClearance, root.edgeBarClearance("bottom"))
          : root.edgeBarClearance("bottom")) + root.edgeMargin
      )
      readonly property int leftClear: Math.max(
        root.edgeMargin,
        (root.activeBarPos === "left"
          ? Math.max(root.activeBarClearance, root.edgeBarClearance("left"))
          : root.edgeBarClearance("left")) + root.edgeMargin
      )
      readonly property int rightClear: Math.max(
        root.edgeMargin,
        (root.activeBarPos === "right"
          ? Math.max(root.activeBarClearance, root.edgeBarClearance("right"))
          : root.edgeBarClearance("right")) + root.edgeMargin
      )

      x: {
        if (root.activeBarPos === "left") return leftClear;
        if (root.activeBarPos === "right") return Math.max(leftClear, gridPanel.width - width - rightClear);
        if (root.activeNormX > 0.62) return Math.max(leftClear, gridPanel.width - width - rightClear);
        if (root.activeNormX >= 0.38 && root.activeNormX <= 0.62) {
          const centered = Math.round(root.activeNormX * gridPanel.width - (width / 2));
          return Math.max(leftClear, Math.min(gridPanel.width - width - rightClear, centered));
        }
        return leftClear;
      }

      y: {
        if (root.activeBarPos === "bottom") return Math.max(topClear, gridPanel.height - height - bottomClear);
        if (root.activeBarPos === "top") return topClear;
        if (root.activeNormY > 0.62) return Math.max(topClear, gridPanel.height - height - bottomClear);
        if (root.activeNormY >= 0.38 && root.activeNormY <= 0.62) {
          const centered = Math.round(root.activeNormY * gridPanel.height - (height / 2));
          return Math.max(topClear, Math.min(gridPanel.height - height - bottomClear, centered));
        }
        return topClear;
      }

      radius: 16
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1
      opacity: 0.0
      scale: 0.96

      MouseArea { anchors.fill: parent }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Search bar
        Rectangle {
          Layout.fillWidth: true
          height: 36
          radius: 8
          color: root.theme.bgSurface
          border.color: searchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
              text: "󰍉"
              color: root.theme.textMuted
              font.pixelSize: 13
              font.family: root.font
              Layout.alignment: Qt.AlignVCenter
            }

            Item {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              implicitHeight: 20

              FocusScope {
                id: searchInput
                anchors.fill: parent
                focus: true

                property string text: ""

                onTextChanged: {
                  root.searchQuery = searchInput.text
                  root.selectedIndex = 0
                  if (root.isListMode) {
                    appList.positionViewAtIndex(0, ListView.Beginning)
                  } else {
                    grid.positionViewAtIndex(0, GridView.Beginning)
                  }
                }

                Keys.onEscapePressed: gridPanel.visible = false

                Keys.onPressed: event => {
                  const last = (root.isListMode ? appList.count : grid.count) - 1;
                  const move = (delta) => {
                    event.accepted = true;
                    if (last < 0) return;
                    root.selectedIndex = Math.max(0, Math.min(root.selectedIndex + delta, last));
                    if (root.isListMode) {
                      appList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                    } else {
                      grid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                    }
                  };
                  if (event.key === Qt.Key_Down) { move(root.isListMode ? 1 : root.columns); return; }
                  if (event.key === Qt.Key_Up) { move(root.isListMode ? -1 : -root.columns); return; }
                  if (event.key === Qt.Key_Tab) { move(1); return; }
                  if (!root.isListMode && event.key === Qt.Key_Right) { move(1); return; }
                  if (!root.isListMode && event.key === Qt.Key_Left) { move(-1); return; }
                  if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    if (root.selectedIndex >= 0 && root.selectedIndex < filteredApps.values.length)
                      root.launchApp(filteredApps.values[root.selectedIndex]);
                    return;
                  }
                  if (event.key === Qt.Key_Backspace) {
                    if (event.modifiers & Qt.ControlModifier) {
                      searchInput.text = "";
                    } else if (searchInput.text.length > 0) {
                      searchInput.text = searchInput.text.slice(0, -1);
                    }
                    event.accepted = true;
                    return;
                  }
                  if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_U) {
                    searchInput.text = "";
                    event.accepted = true;
                    return;
                  }
                  if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
                    searchInput.text += event.text;
                    event.accepted = true;
                  }
                }

                Text {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  visible: searchInput.text !== ""
                  text: searchInput.text
                  color: root.theme.textPrimary
                  font.pixelSize: 13
                  font.family: root.font
                  elide: Text.ElideLeft
                }
              }

              Text {
                text: "Search applications..."
                color: root.theme.textMuted
                font.pixelSize: 13
                font.family: root.font
                anchors.verticalCenter: parent.verticalCenter
                visible: searchInput.text === ""
              }
            }
          }
        }

        // App grid
        GridView {
          id: grid
          visible: !root.isListMode
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: filteredApps
          clip: true
          cacheBuffer: 0
          cellWidth: root.cellSize
          cellHeight: root.cellSize
          boundsBehavior: Flickable.StopAtBounds
          currentIndex: root.selectedIndex

          delegate: Item {
            id: cell
            required property var modelData
            required property int index
            width: root.cellSize
            height: root.cellSize

            Rectangle {
              anchors.fill: parent
              anchors.margins: 3
              radius: 10
              color: root.selectedIndex === cell.index ? root.theme.bgSelected
                   : (hoverArea.containsMouse ? root.theme.bgHover : "transparent")

              Behavior on color { ColorAnimation { duration: 100 } }

              Column {
                anchors.centerIn: parent
                width: parent.width - 8
                spacing: 6

                Item {
                  width: 40
                  height: 40
                  anchors.horizontalCenter: parent.horizontalCenter

                  IconImage {
                    anchors.centerIn: parent
                    implicitSize: 40
                    asynchronous: true
                    source: Quickshell.iconPath(cell.modelData.icon ?? "", true)
                    visible: (cell.modelData.icon ?? "") !== ""
                  }

                  Text {
                    anchors.centerIn: parent
                    text: "󰀻"
                    color: root.theme.accentPrimary
                    font.pixelSize: 28
                    font.family: root.font
                    visible: (cell.modelData.icon ?? "") === ""
                  }
                }

                Text {
                  width: parent.width
                  text: cell.modelData.name ?? ""
                  color: root.selectedIndex === cell.index ? root.theme.textPrimary : root.theme.textSecondary
                  font.pixelSize: 11
                  font.family: root.font
                  font.bold: root.selectedIndex === cell.index
                  horizontalAlignment: Text.AlignHCenter
                  elide: Text.ElideRight
                  maximumLineCount: 2
                  wrapMode: Text.Wrap
                }
              }

              MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.launchApp(cell.modelData)
                onEntered: root.selectedIndex = cell.index
              }
            }
          }

          Text {
            anchors.centerIn: parent
            text: "No applications found"
            color: root.theme.textMuted
            font.pixelSize: 13
            font.family: root.font
            visible: grid.count === 0 && searchInput.text !== ""
          }
        }

        // App list
        ListView {
          id: appList
          visible: root.isListMode
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: filteredApps
          clip: true
          cacheBuffer: 0
          spacing: 4
          boundsBehavior: Flickable.StopAtBounds
          currentIndex: root.selectedIndex

          delegate: Item {
            id: listRow
            required property var modelData
            required property int index
            width: appList.width
            height: 44

            Rectangle {
              anchors.fill: parent
              radius: 10
              color: root.selectedIndex === listRow.index ? root.theme.bgSelected
                   : (listHoverArea.containsMouse ? root.theme.bgHover : "transparent")

              Behavior on color { ColorAnimation { duration: 100 } }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Item {
                  Layout.preferredWidth: 26
                  Layout.preferredHeight: 26
                  Layout.alignment: Qt.AlignVCenter

                  IconImage {
                    anchors.centerIn: parent
                    implicitSize: 26
                    asynchronous: true
                    source: Quickshell.iconPath(listRow.modelData.icon ?? "", true)
                    visible: (listRow.modelData.icon ?? "") !== ""
                  }

                  Text {
                    anchors.centerIn: parent
                    text: "󰀻"
                    color: root.theme.accentPrimary
                    font.pixelSize: 20
                    font.family: root.font
                    visible: (listRow.modelData.icon ?? "") === ""
                  }
                }

                Text {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  text: listRow.modelData.name ?? ""
                  color: root.selectedIndex === listRow.index ? root.theme.textPrimary : root.theme.textSecondary
                  font.pixelSize: 13
                  font.family: root.font
                  font.bold: root.selectedIndex === listRow.index
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                id: listHoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.launchApp(listRow.modelData)
                onEntered: root.selectedIndex = listRow.index
              }
            }
          }

          Text {
            anchors.centerIn: parent
            text: "No applications found"
            color: root.theme.textMuted
            font.pixelSize: 13
            font.family: root.font
            visible: appList.count === 0 && searchInput.text !== ""
          }
        }
      }
    }
  }
    }
  }
}
