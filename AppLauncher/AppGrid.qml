import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "Hack Nerd Font"
  property int selectedIndex: 0

  // Layout
  readonly property int cellSize: 96
  readonly property int columns: 5
  readonly property int barHeight: 32
  readonly property int edgeMargin: 8

  // Shares the usage history written by AppLauncher
  property var appUsage: ({})
  readonly property string usageCachePath: "$HOME/.cache/qs_app_usage.json"

  IpcHandler {
    target: "appgrid"

    function toggle(): void {
      gridPanel.visible = !gridPanel.visible
      if (gridPanel.visible) {
        searchInput.text = ""
        root.selectedIndex = 0
        loadUsageProc.running = true
        searchInput.forceActiveFocus()
      }
    }
  }

  Process {
    id: loadUsageProc
    command: ["sh", "-c", `cat "${root.usageCachePath}" 2>/dev/null || echo '{}'`]
    running: true
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
      const usage = root.appUsage;
      const all = [...DesktopEntries.applications.values];
      const q = searchInput.text.trim().toLowerCase();

      if (q === "") {
        return all.sort((a, b) => {
          const sa = root.getFrecencyScore(a, usage);
          const sb = root.getFrecencyScore(b, usage);
          if (sa !== sb) return sb - sa;
          return (a.name || "").localeCompare(b.name || "");
        });
      }

      return all.filter(d =>
        (d.name && d.name.toLowerCase().includes(q)) ||
        (d.genericName && d.genericName.toLowerCase().includes(q)) ||
        (d.keywords && d.keywords.some(k => k.toLowerCase().includes(q))) ||
        (d.categories && d.categories.some(c => c.toLowerCase().includes(q)))
      ).sort((a, b) => {
        const an = (a.name || "").toLowerCase();
        const bn = (b.name || "").toLowerCase();
        const as = an.startsWith(q);
        const bs = bn.startsWith(q);
        if (as && !bs) return -1;
        if (!as && bs) return 1;
        const sa = root.getFrecencyScore(a, usage);
        const sb = root.getFrecencyScore(b, usage);
        if (sa !== sb) return sb - sa;
        return an.localeCompare(bn);
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

    // Menu box anchored to the top-left, just below the bar
    Rectangle {
      id: box
      x: root.edgeMargin
      y: root.barHeight + root.edgeMargin
      width: root.columns * root.cellSize + 32
      height: 520
      radius: 16
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1

      // Swallow clicks so they don't close the panel
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
              text: ""
              color: root.theme.textMuted
              font.pixelSize: 13
              font.family: root.font
              Layout.alignment: Qt.AlignVCenter
            }

            Item {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              implicitHeight: searchInput.implicitHeight

              TextInput {
                id: searchInput
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: root.theme.textPrimary
                font.pixelSize: 13
                font.family: root.font
                clip: true
                selectByMouse: true

                onTextChanged: {
                  root.selectedIndex = 0
                  grid.positionViewAtIndex(0, GridView.Beginning)
                }

                Keys.onEscapePressed: gridPanel.visible = false

                Keys.onPressed: event => {
                  const last = grid.count - 1;
                  const move = (delta) => {
                    event.accepted = true;
                    root.selectedIndex = Math.max(0, Math.min(root.selectedIndex + delta, last));
                    grid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                  };
                  if (event.key === Qt.Key_Down) move(root.columns);
                  else if (event.key === Qt.Key_Up) move(-root.columns);
                  else if (event.key === Qt.Key_Tab) move(1);
                  else if (event.key === Qt.Key_Right && searchInput.cursorPosition === searchInput.text.length) move(1);
                  else if (event.key === Qt.Key_Left && searchInput.cursorPosition === 0) move(-1);
                  else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    if (root.selectedIndex >= 0 && root.selectedIndex < filteredApps.values.length)
                      root.launchApp(filteredApps.values[root.selectedIndex]);
                  }
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
                    anchors.fill: parent
                    source: Quickshell.iconPath(cell.modelData.icon ?? "", true)
                    visible: (cell.modelData.icon ?? "") !== ""
                  }

                  Text {
                    anchors.centerIn: parent
                    text: ""
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
