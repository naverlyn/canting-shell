pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
  id: root

  property var wallpapers: []
  property string currentWallpaper: ""
  property string wallpaperA: ""
  property string wallpaperB: ""
  property string resizeMode: "crop" // "crop" (Scale), "fit", "stretch", "no" (Center)
  property string filterMode: "Lanczos3" // "Lanczos3", "Mitchell", "CatmullRom", "Bilinear", "Nearest"
  property string effectMode: "none" // "none", "negate", "bw", "blurred", "sepia", etc.
  property bool generatingEffect: false
  property string targetDisplay: "all" // "all", "primary", "secondary"
  property string backend: "awww + wallust"
  property bool generatingTheme: false
  property var directories: []

  readonly property var effectModes: [
    { id: "none",            label: "No Effects",         desc: "Original unaltered wallpaper" },
    { id: "negate",          label: "Negate (Invert)",    desc: "Inverted color negative" },
    { id: "bw",              label: "Black & White",      desc: "Monochrome with boosted contrast" },
    { id: "blurred",         label: "Blurred",            desc: "Smooth background blur" },
    { id: "charcoal",        label: "Charcoal",           desc: "Pencil & charcoal sketch" },
    { id: "edge",            label: "Edge Detect",        desc: "Contour line outlines" },
    { id: "emboss",          label: "Emboss",             desc: "3D textured relief" },
    { id: "oil",             label: "Oil Paint",          desc: "Painterly brush strokes" },
    { id: "posterize",       label: "Posterize",          desc: "Retro reduced color palette" },
    { id: "sepia",           label: "Sepia Tone",         desc: "Warm vintage antique tone" },
    { id: "solarize",        label: "Solarize",           desc: "Partial tone inversion glow" },
    { id: "sharpen",         label: "Sharpen",            desc: "High clarity detail boost" },
    { id: "vignette",        label: "Vignette",           desc: "Soft peripheral edge fade" },
    { id: "vignette_black",  label: "Vignette (Black)",   desc: "Dark cinematic border shadow" },
    { id: "zoomed",          label: "Zoomed (1:1)",       desc: "Centered 1:1 aspect crop" }
  ]

  // Active connected displays detection
  readonly property var activeScreens: {
    if (Quickshell.screens) void Quickshell.screens.length;
    const qs = Quickshell.screens || [];
    const list = [];
    for (let i = 0; i < qs.length; i++) {
      const s = qs[i];
      if (s && s.name) {
        list.push({
          name: String(s.name),
          model: String(s.model || s.description || "").trim(),
          width: s.width || 0,
          height: s.height || 0
        });
      }
    }
    if (list.length > 0) return list;

    if (typeof MonitorService !== "undefined" && MonitorService.monitors && MonitorService.monitors.length > 0) {
      const ms = MonitorService.monitors.filter(m => !m.disabled);
      if (ms.length > 0) {
        return ms.map((m, idx) => ({
          name: String(m.name || ("Display " + (idx + 1))),
          model: String(m.description || m.model || "").trim(),
          width: m.width || 0,
          height: m.height || 0
        }));
      }
    }

    return [{ name: "HDMI-A-1", model: "", width: 1920, height: 1080 }];
  }

  readonly property int monitorCount: activeScreens.length
  readonly property bool hasMultipleMonitors: monitorCount >= 2

  readonly property string displayAName: (activeScreens.length > 0 && activeScreens[0] && activeScreens[0].name)
    ? activeScreens[0].name
    : "HDMI-A-1"

  readonly property string displayBName: (activeScreens.length > 1 && activeScreens[1] && activeScreens[1].name)
    ? activeScreens[1].name
    : ""

  readonly property var resizeModes: [
    { id: "crop",    label: "Fill" },
    { id: "fit",     label: "Fit" },
    { id: "stretch", label: "Stretch" },
    { id: "no",      label: "Center" }
  ]

  readonly property var filterModes: [
    { id: "Lanczos3",   label: "Lanczos3",    desc: "Lanczos3 (High Quality)" },
    { id: "Mitchell",   label: "Mitchell",    desc: "Mitchell (Smooth)" },
    { id: "CatmullRom", label: "Catmull-Rom", desc: "Catmull-Rom (Sharp)" },
    { id: "Bilinear",   label: "Bilinear",    desc: "Bilinear (Fast)" },
    { id: "Nearest",    label: "Nearest",     desc: "Nearest (Pixel Art)" }
  ]

  readonly property var displayOptions: {
    if (!hasMultipleMonitors) return [];
    const list = [
      { id: "all", label: "All Displays", target: "all" }
    ];
    for (let i = 0; i < activeScreens.length; i++) {
      const role = i === 0 ? "Primary" : (i === 1 ? "Secondary" : ("Display " + (i + 1)));
      list.push({
        id: (i === 0 ? "primary" : (i === 1 ? "secondary" : activeScreens[i].name)),
        target: (i === 0 ? "primary" : (i === 1 ? "secondary" : activeScreens[i].name)),
        outputName: activeScreens[i].name,
        label: role + " (" + activeScreens[i].name + ")"
      });
    }
    return list;
  }

  function extractFilename(p) {
    if (!p || p === "") return "None selected";
    const parts = p.split("/");
    return parts[parts.length - 1];
  }

  // Folder browser state
  property string browsePath: Quickshell.env("HOME") + "/Pictures"
  property var browseEntries: []
  property int browseImageCount: 0
  property bool browseLoading: false

  function normalizePath(p) {
    if (!p) return "";
    let clean = p.trim();
    if (clean.startsWith("~/")) {
      clean = Quickshell.env("HOME") + clean.slice(1);
    } else if (clean === "~") {
      clean = Quickshell.env("HOME");
    }
    if (clean.length > 1 && clean.endsWith("/")) {
      clean = clean.slice(0, -1);
    }
    return clean;
  }

  function displayPath(p) {
    if (!p) return "";
    const home = Quickshell.env("HOME");
    if (p === home) return "~";
    if (p.startsWith(home + "/")) return "~" + p.slice(home.length);
    return p;
  }

  function getBreadcrumbs(fullPath) {
    const home = Quickshell.env("HOME");
    let crumbs = [];
    if (!fullPath || fullPath === "") return crumbs;

    const norm = normalizePath(fullPath);
    if (norm.startsWith(home)) {
      crumbs.push({ label: "~", path: home });
      const rel = norm.substring(home.length).replace(/^\/+/, "");
      if (rel.length > 0) {
        const parts = rel.split("/");
        let current = home;
        for (let i = 0; i < parts.length; i++) {
          current += "/" + parts[i];
          crumbs.push({ label: parts[i], path: current });
        }
      }
    } else {
      crumbs.push({ label: "/", path: "/" });
      const parts = norm.split("/").filter(p => p.length > 0);
      let current = "";
      for (let i = 0; i < parts.length; i++) {
        current += "/" + parts[i];
        crumbs.push({ label: parts[i], path: current });
      }
    }
    return crumbs;
  }

  // Scan wallpaper directories on demand
  Process {
    id: scanner
    command: []
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n").filter(p => p.length > 0);
        root.wallpapers = lines;
      }
    }
  }

  // Browse process to list subdirectories and image count
  Process {
    id: browserProc
    command: []
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        let imgCount = 0;
        let dirs = [];
        const lines = text.trim().split("\n");
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i];
          if (line.startsWith("IMAGES:")) {
            imgCount = parseInt(line.substring(7)) || 0;
          } else if (line.startsWith("DIR:")) {
            const dirName = line.substring(4).trim();
            if (dirName.length > 0) dirs.push(dirName);
          }
        }
        root.browseImageCount = imgCount;
        root.browseEntries = dirs;
        root.browseLoading = false;
      }
    }
  }

  readonly property string wallpaperScript: Qt.resolvedUrl("scripts/wallpaper.sh").toString().replace(/^file:\/\//, "")

  function loadBrowseEntries() {
    if (!browsePath || browsePath === "") {
      browsePath = normalizePath("~/Pictures");
    }
    browseLoading = true;
    browserProc.command = ["bash", root.wallpaperScript, "browse", browsePath];
    browserProc.running = true;
  }

  function navigateTo(newPath) {
    const norm = normalizePath(newPath);
    if (norm && norm !== "") {
      browsePath = norm;
      loadBrowseEntries();
    }
  }

  function navigateUp() {
    if (browsePath === "/" || browsePath === "") return;
    const parts = browsePath.split("/").filter(p => p.length > 0);
    if (parts.length <= 1) {
      navigateTo("/");
    } else {
      parts.pop();
      navigateTo("/" + parts.join("/"));
    }
  }

  function isConfigured(dirPath) {
    const norm = normalizePath(dirPath);
    return (directories || []).includes(norm);
  }

  readonly property string dirsConfigPath: Qt.resolvedUrl("../configs/wallpaper_dirs.conf").toString().replace(/^file:\/\//, "")
  readonly property string wallpaperConfPath: Qt.resolvedUrl("../configs/wallpaper.conf").toString().replace(/^file:\/\//, "")
  readonly property string syncConfPath: Qt.resolvedUrl("../configs/wallpaper_sync.conf").toString().replace(/^file:\/\//, "")
  readonly property string modeConfPath: Qt.resolvedUrl("../configs/wallpaper_mode.conf").toString().replace(/^file:\/\//, "")
  readonly property string configJsonPath: Qt.resolvedUrl("../configs/wallpaper_config.json").toString().replace(/^file:\/\//, "")
  readonly property string configPath: configJsonPath
  readonly property string legacyDisplaysJsonPath: Qt.resolvedUrl("../configs/wallpaper_displays.json").toString().replace(/^file:\/\//, "")

  property bool autoSyncPalette: false

  // Load wallpaper palette auto-sync state
  FileView {
    id: syncConfigFile
    path: root.syncConfPath
    watchChanges: true
    printErrors: false
    onTextChanged: {
      const saved = syncConfigFile.text().trim();
      root.autoSyncPalette = (saved === "true");
    }
  }

  // Load configured wallpaper directories
  FileView {
    id: dirsConfigFile
    path: root.dirsConfigPath
    watchChanges: true
    printErrors: false
    onTextChanged: root.loadDirectories()
  }

  // Load saved wallpaper paths
  FileView {
    id: configFile
    path: root.wallpaperConfPath
    watchChanges: true
    printErrors: false
    onTextChanged: {
      const saved = configFile.text().trim();
      if (saved !== "") {
        const lines = saved.split("\n").map(l => l.trim()).filter(l => l.length > 0);
        if (lines.length > 0) {
          if (!root.currentWallpaper) root.currentWallpaper = lines[0];
          if (!root.wallpaperA) root.wallpaperA = lines[0];
          if (lines.length > 1 && !root.wallpaperB) root.wallpaperB = lines[1];
        }
      }
    }
  }

  // Load saved wallpaper resize mode
  FileView {
    id: modeConfigFile
    path: root.modeConfPath
    watchChanges: true
    printErrors: false
    onTextChanged: {
      const saved = modeConfigFile.text().trim().toLowerCase();
      if (saved === "crop" || saved === "scale" || saved === "fill") root.resizeMode = "crop";
      else if (saved === "fit") root.resizeMode = "fit";
      else if (saved === "stretch") root.resizeMode = "stretch";
      else if (saved === "no" || saved === "center") root.resizeMode = "no";
    }
  }

  function parseConfigJson(raw) {
    if (!raw) return;
    try {
      const data = JSON.parse(raw);
      const sc = String(data.scaling || data.mode || "").toLowerCase();
      if (sc === "scale" || sc === "crop" || sc === "fill") root.resizeMode = "crop";
      else if (sc === "center" || sc === "no") root.resizeMode = "no";
      else if (sc === "fit" || sc === "stretch") root.resizeMode = sc;

      if (data.filter) root.filterMode = String(data.filter);
      if (data.effect) root.effectMode = String(data.effect);

      if (data.target) root.targetDisplay = data.target;
      const wallA = data.primaryWallpaper || data.displayA || data.current;
      const wallB = data.secondaryWallpaper || data.displayB;
      if (wallA) {
        root.wallpaperA = wallA;
        root.currentWallpaper = wallA;
      }
      if (wallB) root.wallpaperB = wallB;
    } catch (e) {
      // Ignore parse error
    }
  }

  // Load modern wallpaper_config.json
  FileView {
    id: configJsonFile
    path: root.configJsonPath
    watchChanges: true
    printErrors: false
    onTextChanged: root.parseConfigJson(configJsonFile.text().trim())
  }

  // Fallback for legacy wallpaper_displays.json if exists
  FileView {
    id: legacyDisplaysConfigFile
    path: root.legacyDisplaysJsonPath
    watchChanges: true
    printErrors: false
    onTextChanged: root.parseConfigJson(legacyDisplaysConfigFile.text().trim())
  }

  function setAutoSync(enabled) {
    root.autoSyncPalette = enabled;
    saveSyncProcess.command = [
      "sh", "-c",
      'printf "%s" "$1" > "$2"',
      "saveSync", enabled ? "true" : "false", root.syncConfPath
    ];
    saveSyncProcess.running = true;
    if (enabled && root.currentWallpaper) {
      root.generatingTheme = true;
      wallustProcess.command = [
        "env", "WALLPAPER_THEME_TOOL=wallust",
        "sh", Qt.resolvedUrl("../ThemeSwitcher/wallpaper-theme/set.sh").toString().replace(/^file:\/\//, ""), root.currentWallpaper
      ];
      wallustProcess.running = true;
    }
  }

  function loadDirectories() {
    const raw = dirsConfigFile.text().trim();
    let dirs = [];
    if (raw !== "") {
      const lines = raw.split("\n");
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (line.length > 0 && !line.startsWith("#")) {
          const norm = normalizePath(line);
          if (norm && !dirs.includes(norm)) {
            dirs.push(norm);
          }
        }
      }
    }

    if (dirs.length === 0) {
      dirs = [normalizePath("~/Pictures/wallpapers")];
    }

    const currentStr = (root.directories || []).join("|");
    const nextStr = dirs.join("|");
    if (currentStr !== nextStr) {
      root.directories = dirs;
      if (root.wallpapers.length > 0) {
        rescan();
      }
    }
  }

  function saveDirectories() {
    const content = (root.directories || []).map(d => displayPath(d)).join("\n");
    saveDirsProcess.command = [
      "sh", "-c",
      'if [ -z "$1" ]; then : > "$2"; else printf "%s\\n" "$1" > "$2"; fi',
      "saveDirs", content, root.dirsConfigPath
    ];
    saveDirsProcess.running = true;
  }

  function addDirectory(rawPath) {
    if (!rawPath) return false;
    const norm = normalizePath(rawPath);
    if (!norm) return false;

    let current = [...(root.directories || [])];
    if (current.includes(norm)) return false;

    current.push(norm);
    root.directories = current;
    saveDirectories();
    rescan();
    return true;
  }

  function removeDirectory(rawPath) {
    if (!rawPath) return false;
    const norm = normalizePath(rawPath);
    let current = [...(root.directories || [])];
    const idx = current.indexOf(norm);
    if (idx === -1) return false;

    current.splice(idx, 1);
    root.directories = current;
    saveDirectories();
    rescan();
    return true;
  }

  function resetDefaultDirectories() {
    root.directories = [normalizePath("~/Pictures/wallpapers")];
    saveDirectories();
    rescan();
  }

  function rescan() {
    wallpapers = [];
    if (!directories || directories.length === 0) return;

    scanner.command = [
      "sh", "-c",
      'find "$@" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) 2>/dev/null | sort -u',
      "find",
      ...directories.map(d => normalizePath(d))
    ];
    scanner.running = true;
  }

  function setWallpaper(path, target, mode) {
    if (!path || path === "") return;

    let chosenTarget = target || root.targetDisplay || "all";
    let chosenMode = mode || root.resizeMode || "crop";
    if (chosenMode === "scale") chosenMode = "crop";
    if (chosenMode === "center") chosenMode = "no";

    root.resizeMode = chosenMode;

    if (chosenTarget === "all") {
      root.currentWallpaper = path;
      root.wallpaperA = path;
      root.wallpaperB = path;
    } else if (chosenTarget === "primary" || chosenTarget === "displayA" || chosenTarget === root.displayAName) {
      root.wallpaperA = path;
      root.currentWallpaper = path;
    } else if (chosenTarget === "secondary" || chosenTarget === "displayB" || chosenTarget === root.displayBName) {
      root.wallpaperB = path;
      if (!root.wallpaperA) root.wallpaperA = root.currentWallpaper || path;
    }

    let outputArg = "";
    if (chosenTarget === "primary" || chosenTarget === "displayA" || chosenTarget === root.displayAName) {
      outputArg = root.displayAName;
    } else if (chosenTarget === "secondary" || chosenTarget === "displayB" || chosenTarget === root.displayBName) {
      outputArg = root.displayBName;
    }

    // 1. Change wallpaper via available daemon (awww, swww, or hyprpaper)
    const activeFilter = root.filterMode || "Lanczos3";
    const activeEffect = root.effectMode || "none";
    const syncThemeFlag = root.autoSyncPalette ? "syncTheme" : "noSync";
    const setShScript = Qt.resolvedUrl("../ThemeSwitcher/wallpaper-theme/set.sh").toString().replace(/^file:\/\//, "");

    root.generatingEffect = (activeEffect !== "none");
    if (root.autoSyncPalette) root.generatingTheme = true;

    setProcess.command = [
      "bash", root.wallpaperScript, "set",
      path, outputArg, chosenMode, activeFilter, activeEffect, syncThemeFlag, setShScript
    ];
    setProcess.running = true;

    // 2. Persist state to configurations
    saveState();
  }

  function setWallpaperType(mode) {
    let chosenMode = mode || "crop";
    if (chosenMode === "scale") chosenMode = "crop";
    if (chosenMode === "center") chosenMode = "no";
    if (chosenMode === root.resizeMode) return;

    root.resizeMode = chosenMode;
    saveState();

    const currentImg = root.currentWallpaper || root.wallpaperA;
    if (currentImg && currentImg !== "") {
      root.setWallpaper(currentImg, root.targetDisplay, chosenMode);
    } else {
      reapplyWallpapers();
    }
  }

  function setFilterMode(filter) {
    if (!filter || filter === root.filterMode) return;
    root.filterMode = filter;
    saveState();

    const currentImg = root.currentWallpaper || root.wallpaperA;
    if (currentImg && currentImg !== "") {
      root.setWallpaper(currentImg, root.targetDisplay, root.resizeMode);
    } else {
      reapplyWallpapers();
    }
  }

  function setEffectMode(eff) {
    let chosenEffect = eff || "none";
    if (chosenEffect === root.effectMode) return;
    root.effectMode = chosenEffect;
    saveState();

    const currentImg = root.currentWallpaper || root.wallpaperA;
    if (currentImg && currentImg !== "") {
      root.setWallpaper(currentImg, root.targetDisplay, root.resizeMode);
    } else {
      reapplyWallpapers();
    }
  }

  function reapplyWallpapers() {
    if (reapplyProcess.running) {
      screenReconnectTimer.restart();
      return;
    }

    const mode = root.resizeMode || "crop";
    const activeFilter = root.filterMode || "Lanczos3";
    const activeEffect = root.effectMode || "none";
    const wallA = root.wallpaperA || root.currentWallpaper;
    const wallB = root.wallpaperB;
    const outA = root.displayAName;
    const outB = root.displayBName;

    reapplyProcess.command = [
      "bash", root.wallpaperScript, "reapply",
      mode, wallA, wallB, outA, outB, activeFilter, activeEffect
    ];
    reapplyProcess.running = true;
  }

  function saveState() {
    const prim = root.wallpaperA || root.currentWallpaper || "";
    const sec = root.wallpaperB || "";
    const mode = root.resizeMode || "crop";
    const filter = root.filterMode || "Lanczos3";
    const effect = root.effectMode || "none";
    const target = root.targetDisplay || "all";

    const confLines = [prim];
    if (sec && sec !== prim) confLines.push(sec);
    const confContent = confLines.join("\n");

    const stateObj = {
      scaling: mode === "crop" ? "fill" : (mode === "no" ? "center" : mode),
      filter: filter,
      effect: effect,
      target: target,
      primaryWallpaper: prim,
      secondaryWallpaper: sec,
      primaryDisplay: root.displayAName,
      secondaryDisplay: root.displayBName
    };
    const jsonContent = JSON.stringify(stateObj, null, 2);

    saveAllProcess.command = [
      "sh", "-c",
      'printf "%s\\n" "$1" > "$2"; ' +
      'printf "%s\\n" "$3" > "$4"; ' +
      'printf "%s\\n" "$5" > "$6"; ',
      "saveAll",
      confContent, root.wallpaperConfPath,
      mode, root.modeConfPath,
      jsonContent, root.configJsonPath
    ];
    saveAllProcess.running = true;
  }

  Process {
    id: saveSyncProcess
    command: []
    running: false
  }

  Process {
    id: saveDirsProcess
    command: []
    running: false
  }

  Process {
    id: setProcess
    command: []
    running: false
    onExited: {
      root.generatingEffect = false;
      root.generatingTheme = false;
    }
  }

  Process {
    id: saveAllProcess
    command: []
    running: false
  }

  Process {
    id: reapplyProcess
    command: []
    running: false
  }

  Process {
    id: wallustProcess
    command: []
    running: false
    onExited: root.generatingTheme = false
  }

  property bool _initialStartupDone: false

  // Re-apply saved wallpaper at startup ONLY if the wallpaper daemon is empty
  Timer {
    id: startupApplyTimer
    interval: 250
    repeat: false
    onTriggered: {
      root._initialStartupDone = true;
      if (root.wallpaperA || root.currentWallpaper) {
        const wA = root.wallpaperA || root.currentWallpaper;
        startupCheckProc.command = ["bash", root.wallpaperScript, "check-startup", wA];
        startupCheckProc.running = true;
      }
    }
  }

  Process {
    id: startupCheckProc
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim() === "NEED_APPLY") {
          root.reapplyWallpapers();
        }
      }
    }
  }

  // Auto-restore wallpaper when a monitor is connected or powered on after startup
  onActiveScreensChanged: {
    if (root._initialStartupDone && activeScreens && activeScreens.length > 0) {
      screenReconnectTimer.restart();
    }
  }

  // Listen for Hyprland events: monitor hotplug, DPMS changes, and config reloads
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event || !event.name) return;
      const triggers = ["monitoradded", "monitoraddedv2", "dpms", "configreloaded"];
      if (triggers.includes(event.name)) {
        screenReconnectTimer.restart();
      }
    }
  }

  Timer {
    id: screenReconnectTimer
    interval: 350
    repeat: false
    onTriggered: {
      if (root.wallpaperA || root.currentWallpaper) {
        root.reapplyWallpapers();
      }
    }
  }

  Component.onCompleted: {
    loadDirectories();
    startupApplyTimer.start();
  }
}
