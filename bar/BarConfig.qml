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

  // Defaults for building block sections
  readonly property var defaultLeftWidgets: ["appGrid", "cpu", "temp", "memory", "disk"]
  readonly property var defaultCenterWidgets: ["windowTitle"]
  readonly property var defaultRightWidgets: ["tray", "clock", "workspaces", "weather", "controlCenter"]

  // Active section widget arrays
  property var leftWidgets: ["appGrid", "cpu", "temp", "memory", "disk"]
  property var centerWidgets: ["windowTitle"]
  property var rightWidgets: ["tray", "clock", "workspaces", "weather", "controlCenter"]

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

  // Metadata for all supported widgets
  readonly property var widgetDefinitions: [
    { id: "workspaces",    name: "Workspaces",          icon: "󰮲", desc: "Workspace switcher pills with active indicators" },
    { id: "windowTitle",   name: "Active Window Title", icon: "🗔", desc: "Title of the currently focused window" },
    { id: "clock",         name: "Clock & Calendar",    icon: "", desc: "Time pill with interactive calendar popup on hover" },
    { id: "weather",       name: "Weather Info",        icon: "󰖐", desc: "Live weather conditions and temperature readout" },
    { id: "appGrid",       name: "Applications",        icon: "󰀻", desc: "Quick access button for the app launcher grid" },
    { id: "cpu",           name: "CPU Monitor",         icon: "󰻠", desc: "Live processor usage pill with details popup" },
    { id: "temp",          name: "CPU Temperature",     icon: "󰔏", desc: "Thermal sensor status pill with details popup" },
    { id: "memory",        name: "Memory (RAM)",        icon: "", desc: "Live memory utilization pill with details popup" },
    { id: "disk",          name: "Disk Usage",          icon: "", desc: "Root partition storage utilization pill" },
    { id: "tray",          name: "System Tray",         icon: "󰖩", desc: "Status indicators and tray context menus" },
    { id: "controlCenter", name: "Control Center",      icon: "", desc: "Quick settings toggle for audio, network, and buttons" }
  ]

  function getWidgetMeta(widgetId) {
    for (let i = 0; i < widgetDefinitions.length; i++) {
      if (widgetDefinitions[i].id === widgetId) return widgetDefinitions[i];
    }
    return { id: widgetId, name: widgetId, icon: "󰄲", desc: "" };
  }

  function getWidgetSection(widgetId) {
    if (leftWidgets && leftWidgets.indexOf(widgetId) !== -1) return "left";
    if (centerWidgets && centerWidgets.indexOf(widgetId) !== -1) return "center";
    if (rightWidgets && rightWidgets.indexOf(widgetId) !== -1) return "right";
    return "none";
  }

  function setWidgetSection(widgetId, targetSection) {
    let l = (leftWidgets || []).filter(w => w !== widgetId);
    let c = (centerWidgets || []).filter(w => w !== widgetId);
    let r = (rightWidgets || []).filter(w => w !== widgetId);

    if (targetSection === "left") l.push(widgetId);
    else if (targetSection === "center") c.push(widgetId);
    else if (targetSection === "right") r.push(widgetId);

    leftWidgets = l;
    centerWidgets = c;
    rightWidgets = r;
    saveConfig();
  }

  function moveWidgetUp(widgetId) {
    let sec = getWidgetSection(widgetId);
    let list = (sec === "left" ? leftWidgets : (sec === "center" ? centerWidgets : rightWidgets)).slice();
    let idx = list.indexOf(widgetId);
    if (idx > 0) {
      let temp = list[idx - 1];
      list[idx - 1] = list[idx];
      list[idx] = temp;
      if (sec === "left") leftWidgets = list;
      else if (sec === "center") centerWidgets = list;
      else if (sec === "right") rightWidgets = list;
      saveConfig();
    }
  }

  function moveWidgetDown(widgetId) {
    let sec = getWidgetSection(widgetId);
    let list = (sec === "left" ? leftWidgets : (sec === "center" ? centerWidgets : rightWidgets)).slice();
    let idx = list.indexOf(widgetId);
    if (idx !== -1 && idx < list.length - 1) {
      let temp = list[idx + 1];
      list[idx + 1] = list[idx];
      list[idx] = temp;
      if (sec === "left") leftWidgets = list;
      else if (sec === "center") centerWidgets = list;
      else if (sec === "right") rightWidgets = list;
      saveConfig();
    }
  }

  function moveWidgetSectionLeft(widgetId) {
    let sec = getWidgetSection(widgetId);
    if (sec === "right") setWidgetSection(widgetId, "center");
    else if (sec === "center") setWidgetSection(widgetId, "left");
  }

  function moveWidgetSectionRight(widgetId) {
    let sec = getWidgetSection(widgetId);
    if (sec === "left") setWidgetSection(widgetId, "center");
    else if (sec === "center") setWidgetSection(widgetId, "right");
  }

  // Counter to guarantee real-time reactivity when widget visibility changes
  property int widgetVisibilityChangeCounter: 0

  function isWidgetVisible(widgetId) {
    if (root.widgetVisibilityChangeCounter < 0) return false;
    switch (widgetId) {
      case "appGrid": return root.showAppGrid;
      case "cpu": return root.showCpu;
      case "temp": return root.showTemp;
      case "memory": return root.showMemory;
      case "disk": return root.showDisk;
      case "windowTitle": return root.showWindowTitle;
      case "workspaces": return root.showWorkspaces;
      case "weather": return root.showWeather;
      case "clock": return root.showTime;
      case "tray": return root.showTray;
      case "controlCenter": return root.showControlCenter;
      default: return true;
    }
  }

  function setWidgetVisible(widgetId, val) {
    switch (widgetId) {
      case "appGrid": root.showAppGrid = val; break;
      case "cpu": root.showCpu = val; break;
      case "temp": root.showTemp = val; break;
      case "memory": root.showMemory = val; break;
      case "disk": root.showDisk = val; break;
      case "windowTitle": root.showWindowTitle = val; break;
      case "workspaces": root.showWorkspaces = val; break;
      case "weather": root.showWeather = val; break;
      case "clock": root.showTime = val; break;
      case "tray": root.showTray = val; break;
      case "controlCenter": root.showControlCenter = val; break;
    }
    root.widgetVisibilityChangeCounter++;
    saveConfig();
  }

  property bool _loaded: false

  function saveConfig() {
    const data = {
      barVisible: root.barVisible,
      position: root.position,
      barHeight: root.barHeight,
      floating: root.floating,
      barOpacity: root.barOpacity,
      allMonitors: root.allMonitors,
      leftWidgets: root.leftWidgets,
      centerWidgets: root.centerWidgets,
      rightWidgets: root.rightWidgets,
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
      "import os, sys, json; p = os.path.expanduser('~/.config/quickshell/bar_config.json'); tmp = p + '.tmp'; open(tmp, 'w').write(sys.argv[1] + '\\n'); os.replace(tmp, p)",
      JSON.stringify(data, null, 2)
    ];
    saveProcess.running = true;
  }

  function ensureAllWidgetsAssigned() {
    let l = (root.leftWidgets || []).slice();
    let c = (root.centerWidgets || []).slice();
    let r = (root.rightWidgets || []).slice();
    let changed = false;

    for (let i = 0; i < widgetDefinitions.length; i++) {
      let id = widgetDefinitions[i].id;
      if (l.indexOf(id) === -1 && c.indexOf(id) === -1 && r.indexOf(id) === -1) {
        if (defaultLeftWidgets.indexOf(id) !== -1) { l.push(id); changed = true; }
        else if (defaultCenterWidgets.indexOf(id) !== -1) { c.push(id); changed = true; }
        else { r.push(id); changed = true; }
      }
    }
    if (changed) {
      root.leftWidgets = l;
      root.centerWidgets = c;
      root.rightWidgets = r;
    }
  }

  function applyConfig(cfg) {
    if (!cfg) return;
    if (cfg.barVisible !== undefined) root.barVisible = Boolean(cfg.barVisible);
    if (cfg.position !== undefined) root.position = String(cfg.position);
    if (cfg.barHeight !== undefined) root.barHeight = Number(cfg.barHeight);
    if (cfg.floating !== undefined) root.floating = Boolean(cfg.floating);
    if (cfg.barOpacity !== undefined) root.barOpacity = Number(cfg.barOpacity);
    if (cfg.allMonitors !== undefined) root.allMonitors = Boolean(cfg.allMonitors);

    if (Array.isArray(cfg.leftWidgets)) root.leftWidgets = cfg.leftWidgets.slice();
    if (Array.isArray(cfg.centerWidgets)) root.centerWidgets = cfg.centerWidgets.slice();
    if (Array.isArray(cfg.rightWidgets)) root.rightWidgets = cfg.rightWidgets.slice();

    ensureAllWidgetsAssigned();

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
    root.widgetVisibilityChangeCounter++;
  }

  function resetDefaults() {
    root.barVisible = true;
    root.position = "top";
    root.barHeight = 32;
    root.floating = false;
    root.barOpacity = 0.85;
    root.allMonitors = true;

    root.leftWidgets = root.defaultLeftWidgets.slice();
    root.centerWidgets = root.defaultCenterWidgets.slice();
    root.rightWidgets = root.defaultRightWidgets.slice();

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
    root.widgetVisibilityChangeCounter++;
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
