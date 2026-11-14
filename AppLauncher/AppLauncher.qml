import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../utils/AppFrecencyUtils.js" as AppFrecencyUtils

Scope {
  id: root
  property var theme: Theme
  property string font: (root.theme && root.theme.fontFamily) ? root.theme.fontFamily : "Lato Nerd Font"
  property bool commandMode: false
  property int selectedIndex: 0
  property bool userExpanded: false
  property bool panelVisible: false
  property string searchQuery: ""
  property string commandQuery: ""

  // Stores { "<appId>": { count: Number, lastUsed: Number } }
  property var appUsage: ({})
  readonly property string usageCachePath: "$HOME/.cache/qs_app_usage.json"

  readonly property bool isExpanded: root.commandMode
    ? (root.commandQuery.trim().length > 0)
    : (root.searchQuery.trim().length > 0 || root.userExpanded)

  IpcHandler {
    target: "launcher"

    function toggle() {
      root.panelVisible = !root.panelVisible
      if (root.panelVisible) {
        root.userExpanded = false
        root.commandMode = (AppLauncherConfig.defaultMode === "command")
        if (AppLauncherConfig.clearSearchOnClose) {
          root.searchQuery = ""
          root.commandQuery = ""
        }
        selectedIndex = 0
        loadUsageProc.running = true
      } else {
        Qt.callLater(() => gc())
      }
    }
  }

  Connections {
    target: AppLauncherConfig
    function onUsageCleared() {
      root.appUsage = ({});
    }
  }

  // Load saved app usage history on demand
  Process {
    id: loadUsageProc
    command: ["sh", "-c", `cat "${root.usageCachePath}" 2>/dev/null || echo '{}'`]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const parsed = JSON.parse(text.trim() || "{}");
          if (parsed && typeof parsed === "object") {
            root.appUsage = parsed;
          }
        } catch (e) {
          root.appUsage = ({});
        }
      }
    }
  }

  // Save updated app usage history to disk
  Process {
    id: saveUsageProc
    running: false
  }

  // Runner process for executing Linux commands
  Process {
    id: cmdRunner
  }

  function getAppKey(entry) {
    return AppFrecencyUtils.getAppKey(entry);
  }

  // Frecency score: combines recency (timestamp) + frequency (+24h weight per launch)
  function getFrecencyScore(entry, usageMap) {
    return AppFrecencyUtils.getFrecencyScore(entry, usageMap);
  }

  function recordAppLaunch(entry) {
    const key = getAppKey(entry);
    if (!key) return;

    const nextUsage = Object.assign({}, root.appUsage);
    const prev = nextUsage[key] || { count: 0, lastUsed: 0 };
    nextUsage[key] = {
      count: (prev.count || 0) + 1,
      lastUsed: Date.now()
    };

    // Reassign to trigger filteredApps re-evaluation
    root.appUsage = nextUsage;

    const jsonPayload = JSON.stringify(nextUsage);
    saveUsageProc.command = [
      "python3", "-c",
      "import os, sys; p = os.path.expanduser('~/.cache/qs_app_usage.json'); open(p, 'w').write(sys.argv[1])",
      jsonPayload
    ];
    saveUsageProc.running = true;
  }

  function runCommand(cmdText) {
    const trimmed = cmdText.trim();
    if (trimmed !== "") {
      cmdRunner.command = ["sh", "-c", trimmed];
      cmdRunner.running = true;
      root.panelVisible = false;
    }
  }

  signal modeSwitched(bool toCommandMode)

  function switchMode(toCommandMode) {
    if (root.commandMode === toCommandMode) return;
    root.commandMode = toCommandMode;
    root.modeSwitched(toCommandMode);
  }

  ScriptModel {
    id: filteredApps
    objectProp: "id"
    values: {
      if (!root.panelVisible) return [];
      const usage = root.appUsage;
      const all = [...DesktopEntries.applications.values].filter(d => {
        const key = root.getAppKey(d);
        return !AppLauncherConfig.isAppHidden(key);
      });
      const q = root.searchQuery.trim().toLowerCase();
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
          const scoreA = root.getFrecencyScore(a, usage);
          const scoreB = root.getFrecencyScore(b, usage);
          if (scoreA !== scoreB) return scoreB - scoreA;
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
        const aStarts = an.startsWith(q);
        const bStarts = bn.startsWith(q);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;

        if (sortMode === "alphabetical") {
          return an.localeCompare(bn);
        } else if (sortMode === "recent") {
          const recA = (usage[root.getAppKey(a)] || {}).lastUsed || 0;
          const recB = (usage[root.getAppKey(b)] || {}).lastUsed || 0;
          if (recA !== recB) return recB - recA;
          return an.localeCompare(bn);
        } else {
          const scoreA = root.getFrecencyScore(a, usage);
          const scoreB = root.getFrecencyScore(b, usage);
          if (scoreA !== scoreB) return scoreB - scoreA;
          return an.localeCompare(bn);
        }
      });
    }
  }

  function launchApp(entry) {
    if (entry) {
      recordAppLaunch(entry);
      entry.execute();
      root.panelVisible = false;
    }
  }

  Loader {
    active: root.panelVisible
    sourceComponent: Component {
  PanelWindow {
    id: launcherPanel
    visible: true
    focusable: true
    color: "transparent"

    Component.onCompleted: {
      searchInput.text = root.searchQuery;
      commandInput.text = root.commandQuery;
      if (root.commandMode) {
        commandInput.forceActiveFocus();
      } else {
        searchInput.forceActiveFocus();
      }
    }

    onVisibleChanged: {
      if (!visible) {
        root.panelVisible = false;
        Qt.callLater(() => gc());
      }
    }

    Connections {
      target: root
      function onModeSwitched(toCommandMode) {
        if (toCommandMode) commandInput.forceActiveFocus();
        else searchInput.forceActiveFocus();
      }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-launcher"

    exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    // Undimmed transparent backdrop (dismisses on click outside)
    MouseArea {
      anchors.fill: parent
      onClicked: launcherPanel.visible = false
    }

    // Centered Spotlight Runner Box
    Rectangle {
      id: launcherBox
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.max(80, (launcherPanel.height - height) / 2 - (root.isExpanded ? 0 : 60))
      width: AppLauncherConfig.spotlightWidth
      height: root.isExpanded ? AppLauncherConfig.spotlightHeight : 60
      radius: 16
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1
      clip: true

      Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
      Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 150 } }
      Behavior on border.color { ColorAnimation { duration: 150 } }

      // Absorb clicks inside the card so it doesn't dismiss
      MouseArea { anchors.fill: parent }

      ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ==============================================================
        // 1. TOP SPOTLIGHT SEARCH BAR (Always Visible, Height: 60px)
        // ==============================================================
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 60
          height: 60
          color: "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 16
            spacing: 14

            // Left Search / Mode Icon with smooth morph/rotation animation
            Item {
              implicitWidth: 20
              implicitHeight: 20
              Layout.alignment: Qt.AlignVCenter

              Text {
                id: searchIcon
                anchors.centerIn: parent
                text: "󰍉"
                color: root.theme.accentPrimary
                font.pixelSize: 20
                font.family: root.font
                font.bold: true
                opacity: root.commandMode ? 0.0 : 1.0
                scale: root.commandMode ? 0.6 : 1.0
                rotation: root.commandMode ? -90 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
              }

              Text {
                id: cmdPromptIcon
                anchors.centerIn: parent
                text: "$"
                color: root.theme.accentPrimary
                font.pixelSize: 20
                font.family: root.font
                font.bold: true
                opacity: root.commandMode ? 1.0 : 0.0
                scale: root.commandMode ? 1.0 : 0.6
                rotation: root.commandMode ? 0 : 90
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
              }
            }

            // Central Search Input Field
            Item {
              Layout.fillWidth: true
              Layout.fillHeight: true

              // Applications Input
              Item {
                anchors.fill: parent
                opacity: root.commandMode ? 0.0 : 1.0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 160 } }

                TextInput {
                  id: searchInput
                  anchors.fill: parent
                  verticalAlignment: Text.AlignVCenter
                  enabled: !root.commandMode
                  color: root.theme.textPrimary
                  font.pixelSize: 15
                  font.family: root.font
                  clip: true
                  selectByMouse: true
                  Accessible.role: Accessible.EditableText
                  Accessible.name: "Search applications"

                  onTextChanged: {
                    root.searchQuery = searchInput.text
                    root.selectedIndex = 0
                    if (resultsList.count > 0) {
                      resultsList.positionViewAtIndex(0, ListView.Beginning)
                    }
                  }

                  Keys.onEscapePressed: launcherPanel.visible = false

                  Keys.onPressed: event => {
                    if (event.key === Qt.Key_Right && searchInput.cursorPosition === searchInput.text.length) {
                      event.accepted = true;
                      root.switchMode(true);
                    } else if (event.key === Qt.Key_Down) {
                      event.accepted = true;
                      if (!root.userExpanded && searchInput.text === "") {
                        root.userExpanded = true;
                        root.selectedIndex = 0;
                      } else {
                        root.selectedIndex = Math.min(root.selectedIndex + 1, resultsList.count - 1);
                        resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                      }
                    } else if (event.key === Qt.Key_Up) {
                      event.accepted = true;
                      if (root.selectedIndex === 0 && searchInput.text === "") {
                        root.userExpanded = false;
                      } else {
                        root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                        resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                      }
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                      event.accepted = true;
                      if (root.selectedIndex >= 0 && root.selectedIndex < filteredApps.values.length) {
                        const entry = filteredApps.values[root.selectedIndex];
                        if (entry) root.launchApp(entry);
                      }
                    } else if (event.key === Qt.Key_Tab) {
                      event.accepted = true;
                      root.switchMode(true);
                    }
                  }
                }

                // Applications Placeholder Text
                Text {
                  anchors.fill: parent
                  verticalAlignment: Text.AlignVCenter
                  text: "Search applications, or press ↓ to browse..."
                  color: root.theme.textMuted
                  font.pixelSize: 15
                  font.family: root.font
                  visible: searchInput.text === ""
                  Behavior on color { ColorAnimation { duration: 150 } }
                }
              }

              // Commands Input
              Item {
                anchors.fill: parent
                opacity: root.commandMode ? 1.0 : 0.0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 160 } }

                TextInput {
                  id: commandInput
                  anchors.fill: parent
                  verticalAlignment: Text.AlignVCenter
                  enabled: root.commandMode
                  color: root.theme.textPrimary
                  font.pixelSize: 15
                  font.family: root.font
                  clip: true
                  selectByMouse: true
                  Accessible.role: Accessible.EditableText
                  Accessible.name: "Execute shell command"
                  onTextChanged: root.commandQuery = commandInput.text

                  Keys.onEscapePressed: launcherPanel.visible = false

                  Keys.onPressed: event => {
                    if (event.key === Qt.Key_Left && commandInput.cursorPosition === 0) {
                      event.accepted = true;
                      root.switchMode(false);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                      event.accepted = true;
                      root.runCommand(commandInput.text);
                    } else if (event.key === Qt.Key_Tab) {
                      event.accepted = true;
                      root.switchMode(false);
                    }
                  }
                }

                // Commands Placeholder Text
                Text {
                  anchors.fill: parent
                  verticalAlignment: Text.AlignVCenter
                  text: "Type shell command (e.g. btop, kitty, reboot)..."
                  color: root.theme.textMuted
                  font.pixelSize: 15
                  font.family: root.font
                  visible: commandInput.text === ""
                  Behavior on color { ColorAnimation { duration: 150 } }
                }
              }
            }

            // Right Mode Switcher Text Indicator (Clean inline text without icon, animated mode transition)
            Item {
              id: modeIndicator
              implicitWidth: modeRow.implicitWidth
              implicitHeight: 24
              Layout.alignment: Qt.AlignVCenter

              HoverHandler { id: modeHover }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.switchMode(!root.commandMode)
              }

              Row {
                id: modeRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // Animated mode label container (Apps <-> Command crossfade and slide)
                Item {
                  id: modeLabelWrap
                  implicitWidth: Math.max(appsLabel.implicitWidth, cmdLabel.implicitWidth)
                  implicitHeight: Math.max(appsLabel.implicitHeight, cmdLabel.implicitHeight)
                  anchors.verticalCenter: parent.verticalCenter
                  clip: true

                  Text {
                    id: appsLabel
                    text: "Apps"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: modeHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.commandMode ? -14 : 0
                    opacity: root.commandMode ? 0.0 : 1.0
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                  }

                  Text {
                    id: cmdLabel
                    text: "Command"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: modeHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.commandMode ? 0 : 14
                    opacity: root.commandMode ? 1.0 : 0.0
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                  }
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Tab"
                  font.family: root.font
                  font.pixelSize: 10
                  color: root.theme.textMuted
                  opacity: 0.8
                }
              }
            }
          }
        }

        // ==============================================================
        // 2. DIVIDER LINE (Visible when results expand)
        // ==============================================================
        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: root.theme.bgBorder
          opacity: root.isExpanded ? 1.0 : 0.0
          Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // ==============================================================
        // 3. EXPANDED CONTENT AREA (Applications & Commands with Slide Transition)
        // ==============================================================
        Item {
          id: contentArea
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.topMargin: 8
          Layout.bottomMargin: 4
          Layout.leftMargin: 8
          Layout.rightMargin: 8
          visible: root.isExpanded
          clip: true

          // Applications Results List View
          Item {
            anchors.fill: parent
            opacity: root.commandMode ? 0.0 : 1.0
            visible: opacity > 0.01
            x: root.commandMode ? -16 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            ListView {
              id: resultsList
              anchors.fill: parent
              model: filteredApps
              clip: true
              spacing: 2
              boundsBehavior: Flickable.StopAtBounds
              currentIndex: root.selectedIndex
              highlightMoveDuration: 150
              highlightMoveVelocity: -1

              highlight: Rectangle {
                radius: 8
                color: root.theme.bgSelected
                visible: resultsList.count > 0 && root.selectedIndex >= 0

                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                  width: 3
                  height: 24
                  radius: 2
                  color: root.theme.accentPrimary
                  anchors.left: parent.left
                  anchors.leftMargin: 2
                  anchors.verticalCenter: parent.verticalCenter
                  Behavior on color { ColorAnimation { duration: 150 } }
                }
              }

              delegate: Rectangle {
                id: delegateRoot
                required property var modelData
                required property int index
                readonly property string appKey: root.getAppKey(modelData)
                readonly property int launchCount: (appKey && root.appUsage[appKey]) ? (root.appUsage[appKey].count || 0) : 0
                readonly property bool isFav: AppLauncherConfig.isAppFavorite(appKey)
                readonly property string subTitle: delegateRoot.modelData.genericName ?? delegateRoot.modelData.comment ?? ""

                Accessible.role: Accessible.Button
                Accessible.name: (modelData.name ?? "Application") + (delegateRoot.subTitle ? " - " + delegateRoot.subTitle : "")

                width: resultsList.width
                height: 44
                radius: 8
                color: hoverArea.containsMouse && root.selectedIndex !== index ? root.theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                // App icon on left
                Item {
                  id: iconContainer
                  anchors.left: parent.left
                  anchors.leftMargin: 12
                  anchors.verticalCenter: parent.verticalCenter
                  width: 24
                  height: 24

                  IconImage {
                    anchors.centerIn: parent
                    implicitSize: 24
                    source: Quickshell.iconPath(delegateRoot.modelData.icon ?? "", true)
                    visible: (delegateRoot.modelData.icon ?? "") !== ""
                  }

                  // Fallback icon
                  Text {
                    anchors.centerIn: parent
                    text: "󰀻"
                    color: root.theme.accentPrimary
                    font.pixelSize: 16
                    font.family: root.font
                    visible: (delegateRoot.modelData.icon ?? "") === ""
                    Behavior on color { ColorAnimation { duration: 150 } }
                  }
                }

                // Right-side indicators (Recent / frequent clock)
                Row {
                  id: rightIndicators
                  anchors.right: parent.right
                  anchors.rightMargin: 14
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 6

                  Text {
                    visible: delegateRoot.launchCount > 0
                    text: "󰋚"
                    color: root.selectedIndex === delegateRoot.index ? root.theme.accentPrimary : root.theme.textMuted
                    font.pixelSize: 12
                    font.family: root.font
                    opacity: 0.75
                  }
                }

                // App info container anchored directly to icon and right indicators
                Item {
                  anchors.left: iconContainer.right
                  anchors.leftMargin: 12
                  anchors.right: rightIndicators.left
                  anchors.rightMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  height: delegateRoot.subTitle !== "" ? 34 : 20

                  Row {
                    id: titleRow
                    anchors.left: parent.left
                    anchors.top: delegateRoot.subTitle !== "" ? parent.top : undefined
                    anchors.verticalCenter: delegateRoot.subTitle === "" ? parent.verticalCenter : undefined
                    spacing: 6

                    Text {
                      text: delegateRoot.modelData.name ?? ""
                      color: root.selectedIndex === delegateRoot.index ? root.theme.textPrimary : root.theme.textSecondary
                      font.pixelSize: 13
                      font.family: root.font
                      font.bold: root.selectedIndex === delegateRoot.index
                      elide: Text.ElideRight
                      Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // Favorite indicator
                    Text {
                      visible: delegateRoot.isFav
                      text: "󰓎"
                      font.family: root.font
                      font.pixelSize: 10
                      color: "#e5c07b"
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }

                  Text {
                    visible: delegateRoot.subTitle !== ""
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    text: delegateRoot.subTitle
                    color: root.theme.textMuted
                    font.pixelSize: 11
                    font.family: root.font
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 150 } }
                  }
                }

                MouseArea {
                  id: hoverArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.launchApp(delegateRoot.modelData)
                  onEntered: root.selectedIndex = delegateRoot.index
                }
              }

              // Empty state placeholder
              Text {
                anchors.centerIn: parent
                text: "No applications found"
                color: root.theme.textMuted
                font.pixelSize: 13
                font.family: root.font
                visible: resultsList.count === 0 && searchInput.text !== ""
                Behavior on color { ColorAnimation { duration: 150 } }
              }
            }
          }

          // Command Mode Runner Preview
          Item {
            anchors.fill: parent
            opacity: root.commandMode ? 1.0 : 0.0
            visible: opacity > 0.01
            x: root.commandMode ? 0 : 16
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 8

              Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: cmdInfoRow.implicitWidth + 24
                height: 38
                radius: 8
                color: root.theme.bgSurface
                border.color: root.theme.accentPrimary
                border.width: 1

                RowLayout {
                  id: cmdInfoRow
                  anchors.centerIn: parent
                  spacing: 8

                  Text {
                    text: "⏎"
                    color: root.theme.accentPrimary
                    font.pixelSize: 14
                    font.bold: true
                    font.family: root.font
                  }

                  Text {
                    text: "Run: " + commandInput.text
                    color: root.theme.textPrimary
                    font.pixelSize: 13
                    font.bold: true
                    font.family: root.font
                  }
                }
              }

              Text {
                text: "Press Return to execute command in shell"
                color: root.theme.textMuted
                font.pixelSize: 12
                font.family: root.font
                Layout.alignment: Qt.AlignHCenter
              }
            }
          }
        }

        // ==============================================================
        // 5. FOOTER SHORTCUT HINTS (Visible when results expand)
        // ==============================================================
        Rectangle {
          Layout.fillWidth: true
          height: 32
          color: root.theme.bgSurface
          visible: root.isExpanded

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 16

            Row {
              spacing: 4
              Text { text: "↑↓"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
              Text { text: "navigate"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
              spacing: 4
              Text { text: "Tab"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
              Text { text: "switch mode"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
              spacing: 4
              Text { text: "⏎"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
              Text { text: root.commandMode ? "execute" : "launch"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
              spacing: 4
              Text { text: "esc"; color: root.theme.textMuted; font.pixelSize: 10; font.bold: true; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
              Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
            }

            Item { Layout.fillWidth: true }
          }
        }
      }
    }
  }
    }
  }
}
