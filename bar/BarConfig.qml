pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  readonly property string configPath: Quickshell.env("HOME") + "/.config/quickshell/bar_config.json"

  // Master Visibility & Layout
  property bool barVisible: true
  property string position: "top" // "top" | "bottom"
  property int barHeight: 32
  property bool floating: false
  property real barOpacity: 0.85
  property bool allMonitors: true

  // Left Section Widgets
  property bool showAppGrid: true
  property bool showCpu: true
  property bool showMemory: true
  property bool showTemp: true
  property bool showDisk: true

  // Center Section Widget
  property bool showWindowTitle: true

  // Right Section Widgets
  property bool showWorkspaces: true
  property bool showWeather: true
  property bool showTime: true
  property bool showSeconds: true
  property bool showDate: true
  property bool showTray: true
  property bool showControlCenter: true

  property bool _loaded: false

  function saveConfig() {
    const data = {
      barVisible: root.barVisible,
      position: root.position,
      barHeight: root.barHeight,
      floating: root.floating,
      barOpacity: root.barOpacity,
      allMonitors: root.allMonitors,
      showAppGrid: root.showAppGrid,
      showCpu: root.showCpu,
      showMemory: root.showMemory,
      showTemp: root.showTemp,
      showDisk: root.showDisk,
      showWindowTitle: root.showWindowTitle,
      showWorkspaces: root.showWorkspaces,
      showWeather: root.showWeather,
      showTime: root.showTime,
      showSeconds: root.showSeconds,
      showDate: root.showDate,
      showTray: root.showTray,
      showControlCenter: root.showControlCenter
    };
    saveProcess.command = [
      "python3", "-c",
      "import os, sys, json; p = os.path.expanduser('~/.config/quickshell/bar_config.json'); open(p, 'w').write(sys.argv[1] + '\\n')",
      JSON.stringify(data, null, 2)
    ];
    saveProcess.running = true;
  }

  function applyConfig(cfg) {
    if (!cfg) return;
    if (cfg.barVisible !== undefined) root.barVisible = Boolean(cfg.barVisible);
    if (cfg.position !== undefined) root.position = String(cfg.position);
    if (cfg.barHeight !== undefined) root.barHeight = Number(cfg.barHeight);
    if (cfg.floating !== undefined) root.floating = Boolean(cfg.floating);
    if (cfg.barOpacity !== undefined) root.barOpacity = Number(cfg.barOpacity);
    if (cfg.allMonitors !== undefined) root.allMonitors = Boolean(cfg.allMonitors);
    if (cfg.showAppGrid !== undefined) root.showAppGrid = Boolean(cfg.showAppGrid);
    if (cfg.showCpu !== undefined) root.showCpu = Boolean(cfg.showCpu);
    if (cfg.showMemory !== undefined) root.showMemory = Boolean(cfg.showMemory);
    if (cfg.showTemp !== undefined) root.showTemp = Boolean(cfg.showTemp);
    if (cfg.showDisk !== undefined) root.showDisk = Boolean(cfg.showDisk);
    if (cfg.showWindowTitle !== undefined) root.showWindowTitle = Boolean(cfg.showWindowTitle);
    if (cfg.showWorkspaces !== undefined) root.showWorkspaces = Boolean(cfg.showWorkspaces);
    if (cfg.showWeather !== undefined) root.showWeather = Boolean(cfg.showWeather);
    if (cfg.showTime !== undefined) root.showTime = Boolean(cfg.showTime);
    if (cfg.showSeconds !== undefined) root.showSeconds = Boolean(cfg.showSeconds);
    if (cfg.showDate !== undefined) root.showDate = Boolean(cfg.showDate);
    if (cfg.showTray !== undefined) root.showTray = Boolean(cfg.showTray);
    if (cfg.showControlCenter !== undefined) root.showControlCenter = Boolean(cfg.showControlCenter);
  }

  function resetDefaults() {
    root.barVisible = true;
    root.position = "top";
    root.barHeight = 32;
    root.floating = false;
    root.barOpacity = 0.85;
    root.allMonitors = true;
    root.showAppGrid = true;
    root.showCpu = true;
    root.showMemory = true;
    root.showTemp = true;
    root.showDisk = true;
    root.showWindowTitle = true;
    root.showWorkspaces = true;
    root.showWeather = true;
    root.showTime = true;
    root.showSeconds = true;
    root.showDate = true;
    root.showTray = true;
    root.showControlCenter = true;
    saveConfig();
  }

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    onTextChanged: {
      const raw = configFile.text();
      if (!raw) {
        root._loaded = true;
        return;
      }
      try {
        const parsed = JSON.parse(raw);
        root.applyConfig(parsed);
      } catch (e) {
        console.error("Failed to parse bar_config.json:", e);
      } finally {
        root._loaded = true;
      }
    }
  }

  Process {
    id: saveProcess
    command: []
    running: false
  }

  Component.onCompleted: {
    if (!configFile.text()) {
      root._loaded = true;
    }
  }
}
