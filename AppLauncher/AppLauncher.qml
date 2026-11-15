import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "../utils/AppFrecencyUtils.js" as AppFrecencyUtils
import "LauncherModes.js" as LauncherModes
import "Components"

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
  property string copyFeedbackText: ""

  // Stores { "<appId>": { count: Number, lastUsed: Number } }
  property var appUsage: ({})
  readonly property string usageCachePath: "$HOME/.cache/qs_app_usage.json"

  // Stores most-recent shell commands (newest first)
  property var commandHistory: []
  readonly property string cmdHistoryPath: "$HOME/.cache/qs_cmd_history.json"

  readonly property string prefixMode: root.commandMode
    ? "command"
    : LauncherModes.detectPrefixMode(root.searchQuery)

  readonly property var smartResults: {
    if (!root.panelVisible || root.commandMode) return [];
    if (root.prefixMode === "calc") {
      const expr = LauncherModes.stripPrefix(root.searchQuery);
      const res = LauncherModes.evalMath(expr);
      return [{
        kind: "calc",
        ok: res.ok,
        title: res.ok ? ("= " + res.result) : "Calculator",
        subtitle: res.hint,
        value: res.result,
        glyph: "󰃬"
      }];
    }
    if (root.prefixMode === "window") {
      const q = LauncherModes.stripPrefix(root.searchQuery).toLowerCase();
      return [...Hyprland.toplevels.values]
        .filter(t => {
          if (!t || !t.address) return false;
          if (q === "") return true;
          const title = (t.title || "").toLowerCase();
          const cls = ((t.lastIpcObject && (t.lastIpcObject.class || t.lastIpcObject.initialClass)) || "").toLowerCase();
          return title.indexOf(q) !== -1 || cls.indexOf(q) !== -1;
        })
        .sort((a, b) => {
          const wsA = a.workspace ? a.workspace.id : 999;
          const wsB = b.workspace ? b.workspace.id : 999;
          if (wsA !== wsB) return wsA - wsB;
          return (a.title || "").localeCompare(b.title || "");
        })
        .map(t => {
          const cls = (t.lastIpcObject && (t.lastIpcObject.class || t.lastIpcObject.initialClass)) || "";
          const de = cls !== "" ? DesktopEntries.heuristicLookup(cls) : null;
          return {
            kind: "window",
            title: t.title || cls || "Window",
            subtitle: cls !== "" ? cls : "Window",
            wsId: t.workspace ? t.workspace.id : -1,
            iconName: (de && de.icon) ? de.icon : "",
            toplevel: t,
            glyph: "󰖯"
          };
        });
    }
    return [];
  }

  readonly property bool isExpanded: !root.commandMode
    && (root.searchQuery.trim().length > 0 || root.userExpanded)

  function resetSearchIfNeeded() {
    copyFeedbackTimer.stop();
    root.copyFeedbackText = "";
    if (AppLauncherConfig.clearSearchOnClose) {
      root.searchQuery = "";
      root.commandQuery = "";
    }
    root.userExpanded = false;
    root.selectedIndex = 0;
  }

  IpcHandler {
    target: "launcher"

    function toggle() {
      if (!root.panelVisible) {
        root.commandMode = (AppLauncherConfig.defaultMode === "command");
        root.resetSearchIfNeeded();
        loadUsageProc.running = true;
        loadCmdHistoryProc.running = true;
        root.panelVisible = true;
      } else {
        root.panelVisible = false;
        root.resetSearchIfNeeded();
        Qt.callLater(() => gc());
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

  // Load saved shell command history on demand
  Process {
    id: loadCmdHistoryProc
    command: ["sh", "-c", `cat "${root.cmdHistoryPath}" 2>/dev/null || echo '[]'`]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const parsed = JSON.parse(text.trim() || "[]");
          if (Array.isArray(parsed)) {
            root.commandHistory = parsed;
          }
        } catch (e) {
          root.commandHistory = [];
        }
      }
    }
  }

  // Save updated shell command history to disk
  Process {
    id: saveCmdHistoryProc
    running: false
  }

  Timer {
    id: copyFeedbackTimer
    interval: 420
    repeat: false
    onTriggered: {
      root.copyFeedbackText = "";
      root.panelVisible = false;
      root.resetSearchIfNeeded();
    }
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

  function recordCommand(cmdText) {
    const next = [cmdText].concat(root.commandHistory.filter(c => c !== cmdText)).slice(0, 50);
    root.commandHistory = next;
    const jsonPayload = JSON.stringify(next);
    saveCmdHistoryProc.command = [
      "python3", "-c",
      "import os, sys; p = os.path.expanduser('~/.cache/qs_cmd_history.json'); open(p, 'w').write(sys.argv[1])",
      jsonPayload
    ];
    saveCmdHistoryProc.running = true;
  }

  function runCommand(cmdText) {
    const trimmed = cmdText.trim();
    if (trimmed !== "") {
      recordCommand(trimmed);
      cmdRunner.command = ["sh", "-c", trimmed];
      cmdRunner.running = true;
      root.panelVisible = false;
      root.resetSearchIfNeeded();
    }
  }

  signal modeSwitched(bool toCommandMode)

  function switchMode(toCommandMode) {
    if (root.commandMode === toCommandMode) return;
    root.commandMode = toCommandMode;
    root.modeSwitched(toCommandMode);
    if (overlayLoader.item) overlayLoader.item.focusActiveInput();
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
      root.resetSearchIfNeeded();
    }
  }

  function copyToClipboard(textVal) {
    if (!textVal) return;
    Quickshell.execDetached(["wl-copy", String(textVal)]);
    root.copyFeedbackText = "Copied!";
    copyFeedbackTimer.restart();
  }

  function focusWindow(toplevel) {
    if (!toplevel) return;
    const wsObj = toplevel.workspace;
    const addr = toplevel.address
      ? (String(toplevel.address).startsWith("0x") ? toplevel.address : ("0x" + toplevel.address))
      : "";
    root.panelVisible = false;
    root.resetSearchIfNeeded();
    if (wsObj && typeof wsObj.activate === "function") {
      wsObj.activate();
    }
    if (toplevel.wayland && typeof toplevel.wayland.activate === "function") {
      toplevel.wayland.activate();
    }
    if (addr !== "") {
      try {
        Hyprland.dispatch('hl.dsp.focus({ window = "address:' + addr + '" })');
      } catch (e) {
        Hyprland.dispatch("focuswindow address:" + addr);
      }
    }
  }

  function activateSmartItem(item) {
    if (!item) return;
    if (item.kind === "calc" && item.ok) {
      copyToClipboard(item.value);
    } else if (item.kind === "window" && item.toplevel) {
      focusWindow(item.toplevel);
    }
  }

  Loader {
    id: overlayLoader
    active: root.panelVisible
    sourceComponent: Component {
      SpotlightOverlay {
        theme: root.theme
        font: root.font
        commandMode: root.commandMode
        prefixMode: root.prefixMode
        searchQuery: root.searchQuery
        commandQuery: root.commandQuery
        selectedIndex: root.selectedIndex
        userExpanded: root.userExpanded
        isExpanded: root.isExpanded
        appsModel: filteredApps
        appUsage: root.appUsage
        smartResults: root.smartResults
        commandHistory: root.commandHistory
        copyFeedbackText: root.copyFeedbackText

        onOverlayClosed: {
          root.panelVisible = false;
          root.resetSearchIfNeeded();
          Qt.callLater(() => gc());
        }
        onSearchQueryUpdated: text => {
          root.searchQuery = text;
          root.selectedIndex = 0;
        }
        onCommandQueryUpdated: text => root.commandQuery = text
        onModeSwitchRequested: toCommandMode => root.switchMode(toCommandMode)
        onExpandRequested: {
          root.userExpanded = true;
          root.selectedIndex = 0;
        }
        onCollapseRequested: root.userExpanded = false
        onSelectionRequested: index => root.selectedIndex = index
        onAppLaunched: entry => root.launchApp(entry)
        onSmartItemActivated: item => root.activateSmartItem(item)
        onCommandExecuteRequested: cmd => root.runCommand(cmd)
      }
    }
  }
}
