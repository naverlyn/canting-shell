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
  readonly property var defaultLeftWidgets: ["appGrid", "cpu", "temp", "memory", "disk", "network"]
  readonly property var defaultCenterWidgets: ["windowTitle"]
  readonly property var defaultRightWidgets: ["tray", "clock", "workspaces", "weather", "idleInhibitor", "controlCenter"]

  // Multi-Bar Configurations array
  // Each bar object: { id, name, enabled, position ("top"|"bottom"|"left"|"right"), barHeight, floating, barOpacity, allMonitors, panels }
  property var bars: [
    {
      id: "bar_1",
      name: "Primary Bar",
      enabled: true,
      position: "top",
      barHeight: 32,
      floating: false,
      barOpacity: 0.85,
      allMonitors: true,
      panels: [
        ["appGrid", "cpu", "temp", "memory", "disk", "network"],
        ["windowTitle"],
        ["tray", "clock", "workspaces", "weather", "idleInhibitor", "controlCenter"]
      ]
    }
  ]

  // Currently selected bar index in Bar Settings UI
  property int selectedBarIndex: 0

  readonly property var currentBar: {
    const idx = Math.max(0, Math.min((root.bars ? root.bars.length : 1) - 1, root.selectedBarIndex));
    return (root.bars && root.bars.length > 0) ? root.bars[idx] : {
      id: "bar_1", name: "Primary Bar", enabled: true, position: "top",
      barHeight: 32, floating: false, barOpacity: 0.85, allMonitors: true,
      panels: [root.defaultLeftWidgets, root.defaultCenterWidgets, root.defaultRightWidgets]
    };
  }

  // Active section widget arrays (synced with selectedBarIndex for BarSettings editing)
  readonly property var panels: currentBar ? currentBar.panels : [defaultLeftWidgets, defaultCenterWidgets, defaultRightWidgets]

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
  property bool showTime: true
  property bool showSeconds: true
  property bool showDate: true
  property bool showTray: true
  property bool showControlCenter: true
  property bool showBattery: true
  property bool showVolume: true
  property bool showMedia: true
  property bool showIdleInhibitor: true

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
    { id: "network",       name: "Network Speed",       icon: "󰓅", desc: "Live network upload & download speed monitor with details popup" },
    { id: "battery",       name: "Battery Status",      icon: "󰁹", desc: "Live battery percentage and charging indicator pill" },
    { id: "volume",        name: "Audio Volume",        icon: "󰕾", desc: "PipeWire output volume pill (scroll to adjust, click to mute)" },
    { id: "media",         name: "Media Player",        icon: "󰎆", desc: "Active MPRIS media track pill with playback controls" },
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
      copy[propName] = val;
      return copy;
    });
    root.bars = bList;
    if (idx === 0) {
      if (propName === "enabled") root.barVisible = Boolean(val);
      else if (propName === "position") root.position = String(val);
      else if (propName === "barHeight") root.barHeight = Number(val);
      else if (propName === "floating") root.floating = Boolean(val);
      else if (propName === "barOpacity") root.barOpacity = Number(val);
      else if (propName === "allMonitors") root.allMonitors = Boolean(val);
    }
    saveConfig();
  }

  // Add a new Bar instance (up to 4 bars: Top, Bottom, Left, Right)
  function addBar(preferredPosition) {
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
    let newBar = {
      id: "bar_" + Date.now(),
      name: "Bar " + newIdx,
      enabled: true,
      position: nextPos,
      barHeight: 32,
      floating: false,
      barOpacity: root.barOpacity,
      allMonitors: root.allMonitors,
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
    saveConfig();
  }

  // Remove a Bar instance by index (minimum 1 bar kept)
  function removeBarAt(barIdx) {
    if (root.bars.length <= 1 || barIdx < 0 || barIdx >= root.bars.length) return;
    let bList = root.bars.slice();
    bList.splice(barIdx, 1);
    if (root.selectedBarIndex >= bList.length) {
      root.selectedBarIndex = Math.max(0, bList.length - 1);
    }
    root.bars = bList;
    if (bList.length > 0) {
      root.barVisible = Boolean(bList[0].enabled);
      root.position = String(bList[0].position);
      root.barHeight = Number(bList[0].barHeight);
      root.floating = Boolean(bList[0].floating);
      root.barOpacity = Number(bList[0].barOpacity);
      root.allMonitors = Boolean(bList[0].allMonitors);
    }
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

  function getWidgetPanelIndex(widgetId) {
    let pList = root.panels || [];
    for (let i = 0; i < pList.length; i++) {
      if ((pList[i] || []).indexOf(widgetId) !== -1) return i;
    }
    return -1;
  }

  function getWidgetSection(widgetId) {
    let idx = getWidgetPanelIndex(widgetId);
    if (idx === -1) return "none";
    const n = root.panels.length;
    if (idx === 0) return "left";
    if (idx === n - 1 && n > 1) return "right";
    return "center";
  }

  function _setCurrentBarPanels(newPanels) {
    updateBarProp("panels", newPanels, root.selectedBarIndex);
  }

  // Add a new blank panel section to the selected Bar (up to 6 panels)
  function addBlankPanel() {
    let pList = (root.panels || []).map(arr => (arr || []).slice());
    if (pList.length >= 6) return;
    pList.push([]);
    _setCurrentBarPanels(pList);
  }

  // Remove a specific panel section by index; any widgets inside return to the Available Pool
  function removePanelAt(panelIndex) {
    let pList = (root.panels || []).map(arr => (arr || []).slice());
    if (pList.length <= 1 || panelIndex < 0 || panelIndex >= pList.length) return;
    let removedItems = pList[panelIndex] || [];
    pList.splice(panelIndex, 1);
    let rem = (root.removedWidgets || []).slice();
    for (let i = 0; i < removedItems.length; i++) {
      if (rem.indexOf(removedItems[i]) === -1) rem.push(removedItems[i]);
    }
    root.removedWidgets = rem;
    _setCurrentBarPanels(pList);
  }

  // Set exact number of panels (e.g. 2, 3, 4, 5) - adds blank panels or removes trailing panels
  function setPanelCount(targetCount) {
    targetCount = Math.max(1, Math.min(6, Number(targetCount) || 3));
    let pList = (root.panels || []).map(arr => (arr || []).slice());
    let rem = (root.removedWidgets || []).slice();

    while (pList.length < targetCount) {
      pList.push([]);
    }
    while (pList.length > targetCount) {
      let popped = pList.pop() || [];
      for (let i = 0; i < popped.length; i++) {
        if (rem.indexOf(popped[i]) === -1) rem.push(popped[i]);
      }
    }
    root.removedWidgets = rem;
    _setCurrentBarPanels(pList);
  }

  function setWidgetPanel(widgetId, targetPanelIndex) {
    let pList = (root.panels || []).map(arr => (arr || []).filter(w => w !== widgetId));
    let rem = (root.removedWidgets || []).filter(w => w !== widgetId);

    if (targetPanelIndex >= 0 && targetPanelIndex < pList.length) {
      pList[targetPanelIndex].push(widgetId);
    } else {
      rem.push(widgetId);
    }

    root.removedWidgets = rem;
    _setCurrentBarPanels(pList);
  }

  function setWidgetSection(widgetId, targetSection) {
    if (targetSection === "none") {
      setWidgetPanel(widgetId, -1);
      return;
    }
    if (typeof targetSection === "number") {
      setWidgetPanel(widgetId, targetSection);
      return;
    }
    const n = root.panels.length;
    if (targetSection === "left") setWidgetPanel(widgetId, 0);
    else if (targetSection === "right") setWidgetPanel(widgetId, Math.max(0, n - 1));
    else setWidgetPanel(widgetId, n > 2 ? 1 : 0);
  }

  function addWidgetToPanel(widgetId, panelIndex) {
    setWidgetVisible(widgetId, true);
    let idx = (panelIndex !== undefined && panelIndex >= 0 && panelIndex < root.panels.length) ? panelIndex : 0;
    setWidgetPanel(widgetId, idx);
  }

  function addWidgetToSection(widgetId, targetSection) {
    setWidgetVisible(widgetId, true);
    setWidgetSection(widgetId, targetSection !== undefined ? targetSection : 0);
  }

  function removeWidgetFromBar(widgetId) {
    setWidgetPanel(widgetId, -1);
  }

  function moveWidgetUp(widgetId) {
    let pIdx = getWidgetPanelIndex(widgetId);
    if (pIdx === -1) return;
    let pList = (root.panels || []).map(arr => (arr || []).slice());
    let list = pList[pIdx];
    let idx = list.indexOf(widgetId);
    if (idx > 0) {
      let temp = list[idx - 1];
      list[idx - 1] = list[idx];
      list[idx] = temp;
      _setCurrentBarPanels(pList);
    }
  }

  function moveWidgetDown(widgetId) {
    let pIdx = getWidgetPanelIndex(widgetId);
    if (pIdx === -1) return;
    let pList = (root.panels || []).map(arr => (arr || []).slice());
    let list = pList[pIdx];
    let idx = list.indexOf(widgetId);
    if (idx !== -1 && idx < list.length - 1) {
      let temp = list[idx + 1];
      list[idx + 1] = list[idx];
      list[idx] = temp;
      _setCurrentBarPanels(pList);
    }
  }

  function moveWidgetSectionLeft(widgetId) {
    let pIdx = getWidgetPanelIndex(widgetId);
    if (pIdx > 0) {
      setWidgetPanel(widgetId, pIdx - 1);
    }
  }

  function moveWidgetSectionRight(widgetId) {
    let pIdx = getWidgetPanelIndex(widgetId);
    if (pIdx !== -1 && pIdx < root.panels.length - 1) {
      setWidgetPanel(widgetId, pIdx + 1);
    }
  }

  function moveWidgetToPanelAt(widgetId, targetPanelIndex, targetItemIndex) {
    if (!widgetId) return;
    let pList = (root.panels || []).map(arr => (arr || []).slice());
    let rem = (root.removedWidgets || []).filter(w => w !== widgetId);

    // Target < 0 means drop into the unassigned pool
    if (targetPanelIndex < 0 || targetPanelIndex >= pList.length) {
      pList = pList.map(arr => arr.filter(w => w !== widgetId));
      if (rem.indexOf(widgetId) === -1) rem.push(widgetId);
      root.removedWidgets = rem;
      _setCurrentBarPanels(pList);
      return;
    }

    // Remove from current panel if present
    for (let p = 0; p < pList.length; p++) {
      let existingIdx = pList[p].indexOf(widgetId);
      if (existingIdx !== -1) {
        pList[p].splice(existingIdx, 1);
      }
    }

    let destList = pList[targetPanelIndex];
    let insertIdx = (targetItemIndex === undefined || targetItemIndex < 0)
      ? destList.length
      : Math.max(0, Math.min(destList.length, targetItemIndex));
    destList.splice(insertIdx, 0, widgetId);

    root.removedWidgets = rem;
    setWidgetVisible(widgetId, true);
    _setCurrentBarPanels(pList);
  }

  // Counter to guarantee real-time reactivity when widget visibility changes
  property int widgetVisibilityChangeCounter: 0

  function _resolveBarId(barId) {
    if (barId && String(barId).trim() !== "") return String(barId).trim();
    return (root.currentBar && root.currentBar.id) ? String(root.currentBar.id) : "bar_1";
  }

  function isWidgetVisible(widgetId, barId) {
    if (root.widgetVisibilityChangeCounter < 0) return false;
    void root.selectedBarIndex;
    const bId = _resolveBarId(barId);
    const token = "@hidden:" + bId + ":" + widgetId;
    const rem = root.removedWidgets || [];
    for (let i = 0; i < rem.length; i++) {
      if (String(rem[i]) === token) return false;
    }
    return true;
  }

  function setWidgetVisible(widgetId, val, barId) {
    if (!widgetId) return;
    const bId = _resolveBarId(barId);
    const token = "@hidden:" + bId + ":" + widgetId;
    let rem = (root.removedWidgets || []).filter(item => String(item) !== token);
    if (!val) {
      rem.push(token);
    }
    root.removedWidgets = rem;
    root.widgetVisibilityChangeCounter++;
    saveConfig();
  }

  property bool _loaded: false
  property string _lastSavedJson: ""

  function saveConfig() {
    const primary = (root.bars && root.bars.length > 0) ? root.bars[0] : null;
    const primaryPanels = primary ? primary.panels : root.panels;
    const data = {
      barVisible: primary ? primary.enabled : root.barVisible,
      position: primary ? primary.position : root.position,
      barHeight: primary ? primary.barHeight : root.barHeight,
      floating: primary ? primary.floating : root.floating,
      barOpacity: primary ? primary.barOpacity : root.barOpacity,
      allMonitors: primary ? primary.allMonitors : root.allMonitors,
      bars: root.bars,
      panels: primaryPanels,
      leftWidgets: primaryPanels.length > 0 ? primaryPanels[0] : [],
      centerWidgets: primaryPanels.length > 1 ? primaryPanels[1] : [],
      rightWidgets: primaryPanels.length > 2 ? primaryPanels[2] : [],
      removedWidgets: root.removedWidgets,
      showAppGrid: true,
      showCpu: true,
      showMemory: true,
      showTemp: true,
      showDisk: true,
      showNetwork: true,
      showNetDown: root.showNetDown,
      showNetUp: root.showNetUp,
      netCompact: root.netCompact,
      showWindowTitle: true,
      showWorkspaces: true,
      showWeather: true,
      showTime: true,
      showSeconds: root.showSeconds,
      showDate: root.showDate,
      showTray: true,
      showControlCenter: true,
      showBattery: true,
      showVolume: true,
      showMedia: true
    };
    const jsonStr = JSON.stringify(data, null, 2);
    root._lastSavedJson = jsonStr;
    saveProcess.command = [
      "python3", "-c",
      "import os, sys; p = os.path.expanduser('~/.config/quickshell/bar_config.json'); tmp = p + '.tmp'; open(tmp, 'w').write(sys.argv[1] + '\\n'); os.replace(tmp, p)",
      jsonStr
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

    let pList = [];
    if (Array.isArray(cfg.panels) && cfg.panels.length > 0) {
      pList = cfg.panels.map(arr => Array.isArray(arr) ? arr.slice() : []);
    } else {
      let l = Array.isArray(cfg.leftWidgets) ? cfg.leftWidgets.slice() : root.defaultLeftWidgets.slice();
      let c = Array.isArray(cfg.centerWidgets) ? cfg.centerWidgets.slice() : root.defaultCenterWidgets.slice();
      let r = Array.isArray(cfg.rightWidgets) ? cfg.rightWidgets.slice() : root.defaultRightWidgets.slice();
      pList = [l, c, r];
    }

    let rem = Array.isArray(cfg.removedWidgets) ? cfg.removedWidgets.slice() : ["battery", "volume", "media"];

    let hasNet = rem.indexOf("network") !== -1;
    for (let i = 0; i < pList.length; i++) {
      if (pList[i].indexOf("network") !== -1) hasNet = true;
    }
    if (!hasNet && pList.length > 0) {
      pList[0].push("network");
    }

    if (Array.isArray(cfg.bars) && cfg.bars.length > 0) {
      root.bars = cfg.bars.map((b, idx) => ({
        id: b.id || ("bar_" + (idx + 1)),
        name: String(b.name || (idx === 0 ? "Primary Bar" : ("Bar " + (idx + 1)))).replace(/\s*\((Top|Bottom|Left|Right)\)$/i, ""),
        enabled: b.enabled !== undefined ? Boolean(b.enabled) : true,
        position: b.position || "top",
        barHeight: b.barHeight !== undefined ? Number(b.barHeight) : 32,
        floating: b.floating !== undefined ? Boolean(b.floating) : false,
        barOpacity: b.barOpacity !== undefined ? Number(b.barOpacity) : root.barOpacity,
        allMonitors: b.allMonitors !== undefined ? Boolean(b.allMonitors) : root.allMonitors,
        panels: Array.isArray(b.panels) && b.panels.length > 0
          ? b.panels.map(arr => Array.isArray(arr) ? arr.slice() : [])
          : pList.map(arr => arr.slice())
      }));
    } else {
      root.bars = [{
        id: "bar_1",
        name: "Primary Bar",
        enabled: root.barVisible,
        position: root.position,
        barHeight: root.barHeight,
        floating: root.floating,
        barOpacity: root.barOpacity,
        allMonitors: root.allMonitors,
        panels: pList
      }];
    }

    if (root.selectedBarIndex >= root.bars.length) {
      root.selectedBarIndex = 0;
    }

    root.removedWidgets = rem;

    if (cfg.showNetDown !== undefined) root.showNetDown = Boolean(cfg.showNetDown);
    if (cfg.showNetUp !== undefined) root.showNetUp = Boolean(cfg.showNetUp);
    if (cfg.netCompact !== undefined) root.netCompact = Boolean(cfg.netCompact);
    if (cfg.showSeconds !== undefined) root.showSeconds = Boolean(cfg.showSeconds);
    if (cfg.showDate !== undefined) root.showDate = Boolean(cfg.showDate);
    root.widgetVisibilityChangeCounter++;
  }

  function resetDefaults() {
    root.barVisible = true;
    root.position = "top";
    root.barHeight = 32;
    root.floating = false;
    root.barOpacity = 0.85;
    root.allMonitors = true;

    root.selectedBarIndex = 0;
    root.bars = [
      {
        id: "bar_1",
        name: "Primary Bar",
        enabled: true,
        position: "top",
        barHeight: 32,
        floating: false,
        barOpacity: 0.85,
        allMonitors: true,
        panels: [
          root.defaultLeftWidgets.slice(),
          root.defaultCenterWidgets.slice(),
          root.defaultRightWidgets.slice()
        ]
      }
    ];
    root.removedWidgets = ["battery", "volume", "media"];

    root.showAppGrid = true;
    root.showCpu = true;
    root.showMemory = true;
    root.showTemp = true;
    root.showDisk = true;
    root.showNetwork = true;
    root.showNetDown = true;
    root.showNetUp = true;
    root.netCompact = false;
    root.showWindowTitle = true;
    root.showWorkspaces = true;
    root.showWeather = true;
    root.showTime = true;
    root.showSeconds = true;
    root.showDate = true;
    root.showTray = true;
    root.showControlCenter = true;
    root.showBattery = true;
    root.showVolume = true;
    root.showMedia = true;
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
