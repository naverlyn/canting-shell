pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property var wallpapers: []
  property string currentWallpaper: ""
  property string backend: "awww + wallust"
  property bool generatingTheme: false
  property var directories: []

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

  function loadBrowseEntries() {
    if (!browsePath || browsePath === "") {
      browsePath = normalizePath("~/Pictures");
    }
    browseLoading = true;
    browserProc.command = [
      "sh", "-c",
      'cd "$1" 2>/dev/null || exit 1\n' +
      'img_count=$(find . -maxdepth 1 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) 2>/dev/null | wc -l)\n' +
      'echo "IMAGES:$img_count"\n' +
      'for d in */; do\n' +
      '  [ -d "$d" ] || continue\n' +
      '  name="${d%/}"\n' +
      '  [ "$name" = "*" ] && continue\n' +
      '  case "$name" in .*) continue ;; esac\n' +
      '  printf "DIR:%s\\n" "$name"\n' +
      'done | sort -f\n',
      "browse", browsePath
    ];
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

  readonly property string dirsConfigPath: Qt.resolvedUrl("../wallpaper_dirs.conf").toString().replace(/^file:\/\//, "")
  readonly property string wallpaperConfPath: Qt.resolvedUrl("../wallpaper.conf").toString().replace(/^file:\/\//, "")
  readonly property string syncConfPath: Qt.resolvedUrl("../wallpaper_sync.conf").toString().replace(/^file:\/\//, "")

  property bool autoSyncPalette: false

  // Load wallpaper palette auto-sync state
  FileView {
    id: syncConfigFile
    path: root.syncConfPath
    watchChanges: true
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
    onTextChanged: root.loadDirectories()
  }

  // Load saved wallpaper path
  FileView {
    id: configFile
    path: root.wallpaperConfPath
    watchChanges: true
    onTextChanged: {
      const saved = configFile.text().trim();
      if (saved !== "") root.currentWallpaper = saved;
    }
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

  function setWallpaper(path) {
    if (!path || path === "") return;
    currentWallpaper = path;

    // 1. Change wallpaper via available daemon (awww, swww, or hyprpaper)
    setProcess.command = [
      "sh", "-c",
      'if command -v awww >/dev/null 2>&1; then ' +
        'awww img "$1" --transition-type grow --transition-pos center --transition-duration 1; ' +
      'elif command -v swww >/dev/null 2>&1; then ' +
        'swww img "$1" --transition-type grow --transition-pos center --transition-duration 1; ' +
      'elif command -v hyprpaper >/dev/null 2>&1 && command -v hyprctl >/dev/null 2>&1; then ' +
        'hyprctl hyprpaper preload "$1" 2>/dev/null || true; ' +
        'hyprctl hyprpaper wallpaper ",$1" 2>/dev/null || true; ' +
      'fi',
      "setWallpaper", path
    ];
    setProcess.running = true;

    // 2. Save current wallpaper path to config
    saveProcess.command = [
      "sh", "-c",
      'printf "%s" "$1" > "$2"',
      "sh", path, root.wallpaperConfPath
    ];
    saveProcess.running = true;

    // 3. Generate wallpaper-theme.json via set.sh only if autoSyncPalette is enabled
    if (root.autoSyncPalette) {
      root.generatingTheme = true;
      wallustProcess.command = [
        "env", "WALLPAPER_THEME_TOOL=wallust",
        "sh", Qt.resolvedUrl("../ThemeSwitcher/wallpaper-theme/set.sh").toString().replace(/^file:\/\//, ""), path
      ];
      wallustProcess.running = true;
    }
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
  }

  Process {
    id: saveProcess
    command: []
    running: false
  }

  Process {
    id: wallustProcess
    command: []
    running: false
    onExited: root.generatingTheme = false
  }

  Component.onCompleted: {
    loadDirectories();
  }
}