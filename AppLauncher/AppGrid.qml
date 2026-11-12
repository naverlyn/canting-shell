import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../bar"

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"
  property int selectedIndex: 0

  readonly property int cellSize: AppLauncherConfig.gridCellSize
  readonly property int columns: AppLauncherConfig.gridColumns
  readonly property int edgeMargin: 10

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
    gridPanel.visible = !gridPanel.visible;
    if (gridPanel.visible) {
      if (AppLauncherConfig.clearSearchOnClose) {
        searchInput.text = "";
      }
      root.selectedIndex = 0;
      loadUsageProc.running = true;
      Qt.callLater(() => searchInput.forceActiveFocus());
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
      if (!gridPanel.visible) {
        root.resolveDefaultPlacement();
      }
      root.openOrToggle();
    }

    function toggleAt(barPos: string, normX: string, normY: string, clearance: string) {
      if (!gridPanel.visible) {
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
    return (entry && (entry.id || entry.name)) ? (entry.id || entry.name) : "";
  }

  function getFrecencyScore(entry, usageMap) {
    const key = getAppKey(entry);
    if (!key || !usageMap || !usageMap[key]) return 0;
    const item = usageMap[key];
    const count = item.count || 0;
    if (count <= 0) return 0;
    return (item.lastUsed || 0) + (count * 86400000);
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
      gridPanel.visible = false;
    }
  }

  ScriptModel {
    id: filteredApps
    objectProp: "id"
    values: {
      if (!gridPanel.visible) return [];
      const usage = root.appUsage;
      const all = [...DesktopEntries.applications.values].filter(d => {
        const key = root.getAppKey(d);
        return !AppLauncherConfig.isAppHidden(key);
      });
      const q = searchInput.text.trim().toLowerCase();
      const matchGen = AppLauncherConfig.matchGenericName;
      const matchKw = AppLauncherConfig.matchKeywords;
      const matchCat = AppLauncherConfig.matchCategories;
      const sortMode = AppLauncherConfig.sortMode;

      function compareApps(a, b) {
        const favA = AppLauncherConfig.isAppFavorite(root.getAppKey(a));
        const favB = AppLauncherConfig.isAppFavorite(root.getAppKey(b));
        if (favA && !favB) return -1;
        if (!favA && favB) return 1;

        if (sortMode === "alphabetical") {
          return (a.name || "").localeCompare(b.name || "");
        } else if (sortMode === "recent") {
          const recA = (usage[root.getAppKey(a)] || {}).lastUsed || 0;
          const recB = (usage[root.getAppKey(b)] || {}).lastUsed || 0;
          if (recA !== recB) return recB - recA;
          return (a.name || "").localeCompare(b.name || "");
        } else {
          const sa = root.getFrecencyScore(a, usage);
          const sb = root.getFrecencyScore(b, usage);
          if (sa !== sb) return sb - sa;
          return (a.name || "").localeCompare(b.name || "");
        }
      }

      if (q === "") {
        return all.sort(compareApps);
      }

      return all.filter(d =>
        (d.name && d.name.toLowerCase().includes(q)) ||
        (matchGen && d.genericName && d.genericName.toLowerCase().includes(q)) ||
        (matchKw && d.keywords && d.keywords.some(k => k.toLowerCase().includes(q))) ||
        (matchCat && d.categories && d.categories.some(c => c.toLowerCase().includes(q)))
      ).sort((a, b) => {
        const favA = AppLauncherConfig.isAppFavorite(root.getAppKey(a));
        const favB = AppLauncherConfig.isAppFavorite(root.getAppKey(b));
        if (favA && !favB) return -1;
        if (!favA && favB) return 1;

        const an = (a.name || "").toLowerCase();
        const bn = (b.name || "").toLowerCase();
        const as = an.startsWith(q);
        const bs = bn.startsWith(q);
        if (as && !bs) return -1;
        if (!as && bs) return 1;

        if (sortMode === "alphabetical") {
          return an.localeCompare(bn);
        } else if (sortMode === "recent") {
          const recA = (usage[root.getAppKey(a)] || {}).lastUsed || 0;
          const recB = (usage[root.getAppKey(b)] || {}).lastUsed || 0;
          if (recA !== recB) return recB - recA;
          return an.localeCompare(bn);
        } else {
          const sa = root.getFrecencyScore(a, usage);
          const sb = root.getFrecencyScore(b, usage);
          if (sa !== sb) return sb - sa;
          return an.localeCompare(bn);
        }
      });
    }
  }

  PanelWindow {
    id: gridPanel
    visible: false
    focusable: true
    color: "transparent"

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
      onClicked: gridPanel.visible = false
    }

    Rectangle {
      id: box
      width: root.columns * root.cellSize + 32
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
                  root.selectedIndex = 0
                  grid.positionViewAtIndex(0, GridView.Beginning)
                }

                Keys.onEscapePressed: gridPanel.visible = false

                Keys.onPressed: event => {
                  const last = grid.count - 1;
                  const move = (delta) => {
                    event.accepted = true;
                    if (last < 0) return;
                    root.selectedIndex = Math.max(0, Math.min(root.selectedIndex + delta, last));
                    grid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                  };
                  if (event.key === Qt.Key_Down) { move(root.columns); return; }
                  if (event.key === Qt.Key_Up) { move(-root.columns); return; }
                  if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right) { move(1); return; }
                  if (event.key === Qt.Key_Left) { move(-1); return; }
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
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: filteredApps
          clip: true
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
      }
    }
  }
}
