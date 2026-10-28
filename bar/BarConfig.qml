pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "BarConfigPanelOps.js" as PanelOps
import "BarConfigPersistence.js" as Persistence

Singleton {
  id: root

  readonly property string configPath: Qt.resolvedUrl("../bar_config.json").toString().replace(/^file:\/\//, "")

  // Master Visibility & Layout
  property bool barVisible: true
  property string position: "top" // "top" | "bottom"
  property int barHeight: 32
  property bool floating: false
  property real barOpacity: 0.85
  property int pillRadius: 10
  property real pillOpacity: 1.0
  property bool hidePill: false
  property bool allMonitors: true
  property string displayTarget: "all" // "all" | "primary" | "secondary" | monitor name
  property string secondaryPosition: "bottom" // "top" | "bottom" | "left" | "right"
  property string secondaryMode: "custom" // "blank" | "custom" | "mirror"
  property bool blankOnSecondary: false
  readonly property var defaultSecondaryPanels: [
    ["workspaces"],
    ["windowTitle"],
    ["weather", "clock"]
  ]
  property var secondaryPanels: [
    ["workspaces"],
    ["windowTitle"],
    ["weather", "clock"]
  ]
  property string activeEditingDisplay: "primary" // "primary" | "secondary"
  onActiveEditingDisplayChanged: {
    root.panelsRevision++;
    root.panelsUpdated();
  }
  property bool innerCorners: true
  property bool fluidCards: true
  property bool barBorder: true
  property int barBorderWidth: 1
  property string barBorderColor: ""
  property bool screenBorder: false
  property int screenBorderThickness: 4
  property string screenBorderColor: ""
  property bool screenBorderCorners: true
  property bool screenBorderShadow: true
  property int screenBorderShadowSize: 12
  property real screenBorderShadowOpacity: 0.35

  // Active details popups tracking across bars
  property var activePopupsList: []
  readonly property bool isHoveringBarPills: activePopupsList && activePopupsList.length > 0

  function notifyPopupActive(p) {
    if (!activePopupsList) activePopupsList = [];
    if (activePopupsList.indexOf(p) === -1) {
      const copy = activePopupsList.slice();
      copy.push(p);
      activePopupsList = copy;
    }
  }

  function notifyPopupInactive(p) {
    if (!activePopupsList) return;
    const idx = activePopupsList.indexOf(p);
    if (idx !== -1) {
      const copy = activePopupsList.slice();
      copy.splice(idx, 1);
      activePopupsList = copy;
    }
  }

  // Panel capacity limit
  readonly property int maxPanelWidgets: 10
  signal configWarning(string message)
  signal panelsUpdated()
  property int panelsRevision: 0

  // Defaults for building block sections
  readonly property var defaultLeftWidgets: ["appGrid", "globalMenu", "cpu", "temp", "memory", "disk", "network"]
  readonly property var defaultCenterWidgets: ["windowTitle"]
  readonly property var defaultRightWidgets: ["tray", "clock", "workspaces", "weather", "idleInhibitor", "controlCenter"]

  // Multi-Bar Configurations array
  // Each bar object: { id, name, enabled, position ("top"|"bottom"|"left"|"right"), barHeight, floating, barOpacity, pillRadius, pillOpacity, hidePill, allMonitors, displayTarget, secondaryMode, blankOnSecondary, secondaryPanels, innerCorners, panels }
  property var bars: [
    {
      id: "bar_1",
      name: "Primary Bar",
      enabled: true,
      position: "top",
      barHeight: 32,
      floating: false,
      barOpacity: 0.85,
      pillRadius: 10,
      pillOpacity: 1.0,
      hidePill: false,
      allMonitors: true,
      displayTarget: "all",
      secondaryPosition: "bottom",
      secondaryMode: "custom",
      blankOnSecondary: false,
      secondaryPanels: [
        ["workspaces"],
        ["windowTitle"],
        ["weather", "clock"]
      ],
      innerCorners: true,
      fluidCards: true,
      barBorder: true,
      barBorderWidth: 1,
      barBorderColor: "",
      panels: [
        ["appGrid", "globalMenu", "cpu", "temp", "memory", "disk", "network"],
        ["windowTitle"],
        ["tray", "clock", "workspaces", "weather", "idleInhibitor", "controlCenter"]
      ]
    }
  ]

  // Currently selected bar index in Bar Settings UI
  property int selectedBarIndex: 0
  onSelectedBarIndexChanged: {
    const tgt = (root.currentBar ? (root.currentBar.displayTarget || (root.currentBar.allMonitors ? "all" : "primary")) : "primary");
    if (tgt === "secondary") {
      root.activeEditingDisplay = "secondary";
    } else if (tgt === "primary") {
      root.activeEditingDisplay = "primary";
    }
  }

  readonly property var currentBar: {
    const idx = Math.max(0, Math.min((root.bars ? root.bars.length : 1) - 1, root.selectedBarIndex));
    return (root.bars && root.bars.length > 0) ? root.bars[idx] : {
      id: "bar_1", name: "Primary Bar", enabled: true, position: "top",
      barHeight: 32, floating: false, barOpacity: 0.85, pillRadius: 10, pillOpacity: 1.0, hidePill: false,
      allMonitors: true, displayTarget: "all", secondaryPosition: (root.secondaryPosition || "top"), secondaryMode: "custom", blankOnSecondary: false,
      secondaryPanels: root.defaultSecondaryPanels,
      innerCorners: root.innerCorners,
      fluidCards: root.fluidCards,
      barBorder: root.barBorder,
      barBorderWidth: root.barBorderWidth,
      barBorderColor: root.barBorderColor,
      panels: [root.defaultLeftWidgets, root.defaultCenterWidgets, root.defaultRightWidgets]
    };
  }

  // Active section widget arrays (synced with selectedBarIndex and activeEditingDisplay for BarSettings editing)
  readonly property var panels: {
    void root.panelsRevision;
    if (!currentBar) return [defaultLeftWidgets, defaultCenterWidgets, defaultRightWidgets];
    const tgt = (currentBar.displayTarget || (currentBar.allMonitors ? "all" : "primary"));
    if (tgt === "all" && root.activeEditingDisplay === "secondary") {
      return (currentBar.secondaryPanels && currentBar.secondaryPanels.length > 0)
        ? currentBar.secondaryPanels
        : root.defaultSecondaryPanels;
    }
    return currentBar.panels;
  }

  // Legacy aliases synced with panels for compatibility
  readonly property var leftWidgets: panels.length > 0 ? panels[0] : []
  readonly property var centerWidgets: panels.length > 1 ? panels[1] : []
  readonly property var rightWidgets: panels.length > 2 ? panels[2] : []

  // Explicit list of panels removed from the bar
  property var removedWidgets: ["battery", "volume", "media"]

  // Left Section Widgets
  property bool showAppGrid: true
  property bool showCpu: true
  property bool showMemory: true
  property bool showTemp: true
  property bool showDisk: true
  property bool showNetwork: true

  // Network Speed Sub-options
  property bool showNetDown: true
  property bool showNetUp: true
  property bool netCompact: false

  // Center Section Widget
  property bool showWindowTitle: true

  // Right & Extra Section Widgets
  property bool showWorkspaces: true
  property bool showWeather: true
  property string weatherLocation: "Bekasi"
  property bool showTime: true
  property bool showSeconds: true
  property bool showDate: true
  property bool showYear: true
  property bool showTray: true
  property bool showControlCenter: true
  property bool showBattery: true
  property bool showVolume: true
  property bool showMedia: true
  property bool showIdleInhibitor: true
  property bool showGlobalMenu: true
  property bool showGlobalMenuIcon: false

  // Module Customization Options
  property string activeStyle: "pill" // "pill" | "underline" | "both"
  property string workspaceStyle: "index" // "index" | "roman" | "dot"
  property bool workspaceScrollSwitch: true
  property string weatherUnit: "m" // "m" (metric °C) | "u" (imperial °F)
  property string weatherMode: "compact" // "compact" | "full"
  property int weatherIntervalMinutes: 15
  property bool batteryShowPercentage: true
  property int batteryLowThreshold: 20
  property bool hwShowIcons: true
  property bool hwAlertEnabled: true
  property int hwAlertThreshold: 85
  property int hwPollInterval: 2

  // Cava Visualizer Options
  property bool showCava: true
  property string cavaMode: "compact" // "compact" (8 bars) | "medium" (16 bars) | "wide" (24 bars)
  property int cavaBars: 8
  property int cavaFramerate: 30
  property string cavaStyle: "bars" // "bars" | "glyphs" | "line"
  property bool cavaStereo: false
  property bool cavaAutoHide: false
  property bool cavaShowIcon: false

  function setCavaMode(mode) {
    if (mode !== "compact" && mode !== "medium" && mode !== "wide") mode = "compact";
    root.cavaMode = mode;
    if (mode === "compact") {
      root.cavaBars = 8;
    } else if (mode === "medium") {
      root.cavaBars = 16;
    } else if (mode === "wide") {
      root.cavaBars = 24;
    }
    root.panelsRevision++;
    saveConfig();
  }

  // Metadata for all supported widgets
  readonly property var widgetDefinitions: [
    { id: "workspaces",    name: "Workspaces",          icon: "󰮲", desc: "Workspace switcher pills with active indicators" },
    { id: "windowTitle",   name: "Active Window Title", icon: "🗔", desc: "Title of the currently focused window" },
    { id: "globalMenu",    name: "Global Menu",         icon: "󰍜", desc: "macOS-style application menu bar (File, Edit, View, Help)" },
    { id: "clock",         name: "Clock & Calendar",    icon: "", desc: "Time pill with interactive calendar popup on hover" },
    { id: "weather",       name: "Weather Info",        icon: "󰖐", desc: "Live weather conditions and temperature readout" },
    { id: "appGrid",       name: "Applications",        icon: "󰀻", desc: "Quick access button for the app launcher grid" },
    { id: "cpu",           name: "CPU Monitor",         icon: "󰻠", desc: "Live processor usage pill with details popup" },
    { id: "temp",          name: "CPU Temperature",     icon: "󰔏", desc: "Thermal sensor status pill with details popup" },
    { id: "memory",        name: "Memory (RAM)",        icon: "", desc: "Live memory utilization pill with details popup" },
    { id: "disk",          name: "Disk Usage",          icon: "", desc: "Root partition storage utilization pill" },
    { id: "network",       name: "Network Speed",       icon: "󰓅", desc: "Live network upload & download speed monitor with details popup" },
    { id: "battery",       name: "Battery Status",      icon: "󰁹", desc: "Live battery percentage and charging indicator pill" },
    { id: "volume",        name: "Audio Volume",        icon: "󰕾", desc: "PipeWire output volume pill (scroll to adjust, click to mute)" },
    { id: "media",         name: "Media Player",        icon: "󰎆", desc: "Active MPRIS media track pill with playback controls" },
    { id: "cava",          name: "Cava Visualizer",     icon: "󰝛", desc: "Live audio spectrum equalizer visualizer pill" },
    { id: "idleInhibitor", name: "Idle Inhibitor",      icon: "", desc: "Caffeine toggle to prevent screen idle and sleep" },
    { id: "tray",          name: "System Tray",         icon: "󰖩", desc: "Status indicators and tray context menus" },
    { id: "controlCenter", name: "Control Center",      icon: "", desc: "Quick settings toggle for audio, network, and buttons" }
  ]

  // Helper to update a property on the currently selected bar (or specific barIndex)
  function updateBarProp(propName, val, barIdx) {
    const idx = barIdx !== undefined ? barIdx : Math.max(0, Math.min(root.bars.length - 1, root.selectedBarIndex));
    let bList = root.bars.map((b, i) => {
      if (i !== idx) return b;
      let copy = Object.assign({}, b);
      copy.panels = (b.panels || []).map(p => (p || []).slice());
      if (b.secondaryPanels) {
        copy.secondaryPanels = b.secondaryPanels.map(p => (p || []).slice());
      }
      copy[propName] = propName === "barOpacity" ? Number(val) : val;
      return copy;
    });
    root.bars = bList;
    if (idx === 0) {
      if (propName === "enabled") root.barVisible = Boolean(val);
      else if (propName === "position") root.position = String(val);
      else if (propName === "barHeight") root.barHeight = Number(val);
      else if (propName === "floating") root.floating = Boolean(val);
      else if (propName === "barOpacity") root.barOpacity = Number(val);
      else if (propName === "pillRadius") root.pillRadius = Number(val);
      else if (propName === "pillOpacity") root.pillOpacity = Number(val);
      else if (propName === "hidePill") root.hidePill = Boolean(val);
      else if (propName === "activeStyle") root.activeStyle = String(val);
      else if (propName === "allMonitors") root.allMonitors = Boolean(val);
      else if (propName === "displayTarget") {
        root.displayTarget = String(val);
        root.allMonitors = (String(val) === "all");
      }
      else if (propName === "secondaryPosition") {
        root.secondaryPosition = String(val);
      }
      else if (propName === "secondaryMode") {
        root.secondaryMode = String(val);
        root.blankOnSecondary = (String(val) === "blank");
      }
      else if (propName === "blankOnSecondary") {
        root.blankOnSecondary = Boolean(val);
        root.secondaryMode = val ? "blank" : "custom";
      }
      else if (propName === "secondaryPanels") {
        root.secondaryPanels = val;
      }
      else if (propName === "innerCorners") root.innerCorners = Boolean(val);
      else if (propName === "fluidCards") root.fluidCards = Boolean(val);
      else if (propName === "barBorder") root.barBorder = Boolean(val);
      else if (propName === "barBorderWidth") root.barBorderWidth = Math.max(1, Math.min(10, Number(val)));
      else if (propName === "barBorderColor") root.barBorderColor = String(val);
      else if (propName === "screenBorder") root.screenBorder = Boolean(val);
      else if (propName === "screenBorderThickness") root.screenBorderThickness = Math.max(1, Math.min(32, Math.round(Number(val))));
      else if (propName === "screenBorderColor") root.screenBorderColor = String(val);
      else if (propName === "screenBorderCorners") root.screenBorderCorners = Boolean(val);
      else if (propName === "screenBorderShadow") root.screenBorderShadow = Boolean(val);
      else if (propName === "screenBorderShadowSize") root.screenBorderShadowSize = Math.max(1, Math.min(64, Math.round(Number(val))));
    }
    root.panelsRevision++;
    saveConfig();
  }

  // Add a new Bar instance (up to 4 bars: Top, Bottom, Left, Right)
  function addBar(preferredPosition, targetDisplay) {
    if (root.bars.length >= 4) return;
    let usedPositions = root.bars.map(b => b.position);
    let order = ["bottom", "left", "right", "top"];
    let nextPos = preferredPosition || "bottom";
    if (!preferredPosition) {
      for (let i = 0; i < order.length; i++) {
        if (usedPositions.indexOf(order[i]) === -1) {
          nextPos = order[i];
          break;
        }
      }
    }
    let newIdx = root.bars.length + 1;
    let hasMulti = (Quickshell.screens && Quickshell.screens.length > 1);
    let fallbackTarget = hasMulti ? (root.bars.length === 1 ? "secondary" : "all") : "primary";
    let finalTarget = targetDisplay || fallbackTarget;
    let isAll = (finalTarget === "all");
    let newBar = {
      id: "bar_" + Date.now(),
      name: "Bar " + newIdx,
      enabled: true,
      position: nextPos,
      barHeight: 32,
      floating: false,
      barOpacity: root.barOpacity,
      pillRadius: root.pillRadius,
      pillOpacity: root.pillOpacity,
      hidePill: root.hidePill,
      allMonitors: isAll,
      displayTarget: finalTarget,
      secondaryPosition: nextPos,
      secondaryMode: "custom",
      blankOnSecondary: false,
      secondaryPanels: root.defaultSecondaryPanels.map(p => p.slice()),
      innerCorners: root.innerCorners,
      fluidCards: root.fluidCards,
      barBorder: root.barBorder,
      barBorderWidth: root.barBorderWidth,
      barBorderColor: root.barBorderColor,
      panels: [
        ["workspaces"],
        ["clock"],
        ["volume", "battery"]
      ]
    };
    let bList = root.bars.slice();
    bList.push(newBar);
    root.bars = bList;
    root.selectedBarIndex = bList.length - 1;
    if (finalTarget === "secondary") {
      root.activeEditingDisplay = "secondary";
    } else {
      root.activeEditingDisplay = "primary";
    }
    root.panelsRevision++;
    saveConfig();
  }

  // Remove a Bar instance by index (minimum 1 bar kept)
  function removeBarAt(barIdx) {
    if (root.bars.length <= 1 || barIdx < 0 || barIdx >= root.bars.length) return;
    const removedBar = root.bars[barIdx];
    const removedId = (removedBar && removedBar.id) ? String(removedBar.id) : "";
    let bList = root.bars.slice();
    bList.splice(barIdx, 1);
    root.bars = bList;
    if (removedId !== "") {
      const cPref = "@color:" + removedId + ":";
      const hPref = "@hidden:" + removedId + ":";
      root.removedWidgets = (root.removedWidgets || []).filter(item => {
        const s = String(item);
        return !s.startsWith(cPref) && !s.startsWith(hPref);
      });
    }
    root.selectedBarIndex = Math.max(0, Math.min(bList.length - 1, root.selectedBarIndex));
    root.panelsRevision++;
    root.panelsUpdated();
    if (bList.length > 0) {
      root.barVisible = Boolean(bList[0].enabled);
      root.position = String(bList[0].position);
      root.barHeight = Number(bList[0].barHeight);
      root.floating = Boolean(bList[0].floating);
      root.barOpacity = Number(bList[0].barOpacity);
      root.allMonitors = Boolean(bList[0].allMonitors);
      root.displayTarget = bList[0].displayTarget || (bList[0].allMonitors ? "all" : "primary");
      root.secondaryMode = bList[0].secondaryMode || (bList[0].blankOnSecondary !== false ? "blank" : "mirror");
      root.blankOnSecondary = bList[0].blankOnSecondary !== undefined ? Boolean(bList[0].blankOnSecondary) : (root.secondaryMode === "blank");
      root.innerCorners = bList[0].innerCorners !== undefined ? Boolean(bList[0].innerCorners) : root.innerCorners;
      root.fluidCards = bList[0].fluidCards !== undefined ? Boolean(bList[0].fluidCards) : root.fluidCards;
      root.barBorder = bList[0].barBorder !== undefined ? Boolean(bList[0].barBorder) : root.barBorder;
      root.barBorderWidth = bList[0].barBorderWidth !== undefined ? Number(bList[0].barBorderWidth) : root.barBorderWidth;
      root.barBorderColor = bList[0].barBorderColor !== undefined ? String(bList[0].barBorderColor) : root.barBorderColor;
    }
    root.panelsRevision++;
    saveConfig();
  }

  // Helper to get human-friendly panel title based on panel index, total count, and bar orientation
  function getPanelTitle(panelIndex) {
    const n = root.panels ? root.panels.length : 0;
    const pos = root.currentBar ? root.currentBar.position : root.position;
    const isVert = (pos === "left" || pos === "right");
    const startLabel = isVert ? "Top" : "Left";
    const endLabel = isVert ? "Bottom" : "Right";
    const midStartLabel = isVert ? "Upper-Mid" : "Mid-Left";
    const midEndLabel = isVert ? "Lower-Mid" : "Mid-Right";

    if (n === 1) return "Panel 1 (Full)";
    if (n === 2) return panelIndex === 0 ? ("Panel 1 (" + startLabel + ")") : ("Panel 2 (" + endLabel + ")");
    if (n === 3) {
      if (panelIndex === 0) return "Panel 1 (" + startLabel + ")";
      if (panelIndex === 1) return "Panel 2 (Center)";
      return "Panel 3 (" + endLabel + ")";
    }
    if (n === 4) {
      if (panelIndex === 0) return "Panel 1 (" + startLabel + ")";
      if (panelIndex === 1) return "Panel 2 (" + midStartLabel + ")";
      if (panelIndex === 2) return "Panel 3 (" + midEndLabel + ")";
      return "Panel 4 (" + endLabel + ")";
    }
    if (panelIndex === 0) return "Panel 1 (" + startLabel + ")";
    if (panelIndex === n - 1) return "Panel " + n + " (" + endLabel + ")";
    return "Panel " + (panelIndex + 1);
  }

  // Computed list of unassigned widgets for the currently selected bar
  readonly property var unassignedWidgets: {
    void root.panelsRevision;
    let pList = root.panels || [];
    let assigned = {};
    for (let p = 0; p < pList.length; p++) {
      let arr = pList[p] || [];
      for (let j = 0; j < arr.length; j++) {
        assigned[arr[j]] = true;
      }
    }
    let out = [];
    for (let i = 0; i < widgetDefinitions.length; i++) {
      let w = widgetDefinitions[i];
      if (!assigned[w.id]) {
        out.push(w);
      }
    }
    return out;
  }

  function getWidgetMeta(widgetId) {
    for (let i = 0; i < widgetDefinitions.length; i++) {
      if (widgetDefinitions[i].id === widgetId) return widgetDefinitions[i];
    }
    return { id: widgetId, name: widgetId, icon: "󰄲", desc: "" };
  }

  // Layout & visibility operations live in BarConfigPanelOps.js
  function getWidgetPanelIndex(widgetId) { return PanelOps.getWidgetPanelIndex(root, widgetId); }
  function getWidgetSection(widgetId) { return PanelOps.getWidgetSection(root, widgetId); }
  function _setCurrentBarPanels(newPanels) { return PanelOps._setCurrentBarPanels(root, newPanels); }
  function isSecondaryWidgetActive(widgetId) { return PanelOps.isSecondaryWidgetActive(root, widgetId); }
  function toggleSecondaryWidget(widgetId) { return PanelOps.toggleSecondaryWidget(root, widgetId); }
  function applySecondaryPreset(presetName) { return PanelOps.applySecondaryPreset(root, presetName); }
  function addBlankPanel() { return PanelOps.addBlankPanel(root); }
  function removePanelAt(panelIndex) { return PanelOps.removePanelAt(root, panelIndex); }
  function setPanelCount(targetCount) { return PanelOps.setPanelCount(root, targetCount); }
  function canAddWidgetToPanel(widgetId, targetPanelIndex) { return PanelOps.canAddWidgetToPanel(root, widgetId, targetPanelIndex); }
  function setWidgetPanel(widgetId, targetPanelIndex) { return PanelOps.setWidgetPanel(root, widgetId, targetPanelIndex); }
  function setWidgetSection(widgetId, targetSection) { return PanelOps.setWidgetSection(root, widgetId, targetSection); }
  function addWidgetToPanel(widgetId, panelIndex) { return PanelOps.addWidgetToPanel(root, widgetId, panelIndex); }
  function addWidgetToSection(widgetId, targetSection) { return PanelOps.addWidgetToSection(root, widgetId, targetSection); }
  function removeWidgetFromBar(widgetId) { return PanelOps.removeWidgetFromBar(root, widgetId); }
  function moveWidgetUp(widgetId) { return PanelOps.moveWidgetUp(root, widgetId); }
  function moveWidgetDown(widgetId) { return PanelOps.moveWidgetDown(root, widgetId); }
  function moveWidgetSectionLeft(widgetId) { return PanelOps.moveWidgetSectionLeft(root, widgetId); }
  function moveWidgetSectionRight(widgetId) { return PanelOps.moveWidgetSectionRight(root, widgetId); }
  function moveWidgetToPanelAt(widgetId, targetPanelIndex, targetItemIndex) { return PanelOps.moveWidgetToPanelAt(root, widgetId, targetPanelIndex, targetItemIndex); }
  function _resolveBarId(barId) { return PanelOps._resolveBarId(root, barId); }
  function isWidgetVisible(widgetId, barId) { return PanelOps.isWidgetVisible(root, widgetId, barId); }
  function setWidgetVisible(widgetId, val, barId, skipSave) { return PanelOps.setWidgetVisible(root, widgetId, val, barId, skipSave); }
  function isWidgetInAnyBar(widgetId) { return PanelOps.isWidgetInAnyBar(root, widgetId); }

  // Counter to guarantee real-time reactivity when widget visibility changes
  property int widgetVisibilityChangeCounter: 0

  property bool _loaded: false
  property string _lastSavedJson: ""
  property bool _savePending: false

  Timer {
    id: saveDebounceTimer
    interval: 150
    repeat: false
    onTriggered: root._flushSaveConfig()
  }

  function saveConfig() {
    saveDebounceTimer.restart();
  }

  function _flushSaveConfig() {
    if (saveProcess.running) {
      root._savePending = true;
      return;
    }
    root._savePending = false;

    const data = Persistence.buildSaveData(root);
    const jsonStr = JSON.stringify(data, null, 2);
    root._lastSavedJson = jsonStr;
    saveProcess.command = [
      "python3", "-c",
      "import os, sys; p = sys.argv[1]; tmp = p + '.tmp'; open(tmp, 'w').write(sys.argv[2] + '\\n'); os.replace(tmp, p)",
      root.configPath,
      jsonStr
    ];
    saveProcess.running = true;
  }

  function applyConfig(cfg) { Persistence.applyConfig(root, cfg); }
  function resetDefaults() { Persistence.resetDefaults(root); }

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    onFileChanged: configFile.reload()
    onTextChanged: {
      const raw = configFile.text();
      if (!raw) {
        root._loaded = true;
        return;
      }
      if (root._lastSavedJson !== "" && raw.trim() === root._lastSavedJson.trim()) {
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

  function setScreenBorder(val) {
    root.screenBorder = Boolean(val);
    root.saveConfig();
  }

  function setScreenBorderThickness(val) {
    root.screenBorderThickness = Math.max(1, Math.min(32, Math.round(Number(val))));
    root.saveConfig();
  }

  function setScreenBorderColor(val) {
    root.screenBorderColor = String(val);
    root.saveConfig();
  }

  function setScreenBorderCorners(val) {
    root.screenBorderCorners = Boolean(val);
    root.saveConfig();
  }

  function setScreenBorderShadow(val) {
    root.screenBorderShadow = Boolean(val);
    root.saveConfig();
  }

  function setScreenBorderShadowSize(val) {
    root.screenBorderShadowSize = Math.max(1, Math.min(64, Math.round(Number(val))));
    root.saveConfig();
  }

  Process {
    id: saveProcess
    command: []
    running: false
    onExited: {
      if (root._savePending) {
        root._savePending = false;
        root._flushSaveConfig();
      }
    }
  }

  Component.onCompleted: {
    if (!root._loaded) {
      const raw = configFile.text();
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          root.applyConfig(parsed);
        } catch (e) {
          console.error("Failed to parse bar_config.json on startup:", e);
        }
      }
      root._loaded = true;
    }
  }
}
