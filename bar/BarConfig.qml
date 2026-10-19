pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

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
  property bool innerCorners: true

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
  // Each bar object: { id, name, enabled, position ("top"|"bottom"|"left"|"right"), barHeight, floating, barOpacity, pillRadius, pillOpacity, hidePill, allMonitors, innerCorners, panels }
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
      innerCorners: true,
      panels: [
        ["appGrid", "globalMenu", "cpu", "temp", "memory", "disk", "network"],
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
      barHeight: 32, floating: false, barOpacity: 0.85, pillRadius: 10, pillOpacity: 1.0, hidePill: false, allMonitors: true,
      innerCorners: root.innerCorners,
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
  property string weatherLocation: "Bekasi"
  property bool showTime: true
  property bool showSeconds: true
  property bool showDate: true
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
      else if (propName === "pillRadius") root.pillRadius = Number(val);
      else if (propName === "pillOpacity") root.pillOpacity = Number(val);
      else if (propName === "hidePill") root.hidePill = Boolean(val);
      else if (propName === "activeStyle") root.activeStyle = String(val);
      else if (propName === "allMonitors") root.allMonitors = Boolean(val);
      else if (propName === "innerCorners") root.innerCorners = Boolean(val);
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
      pillRadius: root.pillRadius,
      pillOpacity: root.pillOpacity,
      hidePill: root.hidePill,
      allMonitors: root.allMonitors,
      innerCorners: root.innerCorners,
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
      root.innerCorners = bList[0].innerCorners !== undefined ? Boolean(bList[0].innerCorners) : root.innerCorners;
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
    root.panelsRevision++;
    root.panelsUpdated();
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

  function canAddWidgetToPanel(widgetId, targetPanelIndex) {
    const pList = root.panels || [];
    if (targetPanelIndex < 0 || targetPanelIndex >= pList.length) return false;
    const list = pList[targetPanelIndex] || [];
    if (list.indexOf(widgetId) !== -1) return true;
    return list.length < root.maxPanelWidgets;
  }

  function setWidgetPanel(widgetId, targetPanelIndex) {
    if (targetPanelIndex >= 0 && targetPanelIndex < (root.panels || []).length) {
      if (!canAddWidgetToPanel(widgetId, targetPanelIndex)) {
        root.configWarning("Already maxed out, please move somewhere else");
        return false;
      }
    }

    let pList = (root.panels || []).map(arr => (arr || []).filter(w => w !== widgetId));
    let rem = (root.removedWidgets || []).filter(w => w !== widgetId);

    if (targetPanelIndex >= 0 && targetPanelIndex < pList.length) {
      pList[targetPanelIndex].push(widgetId);
    } else {
      rem.push(widgetId);
    }

    root.removedWidgets = rem;
    _setCurrentBarPanels(pList);
    return true;
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
    let idx = (panelIndex !== undefined && panelIndex >= 0 && panelIndex < (root.panels || []).length) ? panelIndex : 0;
    if (!canAddWidgetToPanel(widgetId, idx)) {
      let found = -1;
      const pList = root.panels || [];
      for (let p = 0; p < pList.length; p++) {
        if (canAddWidgetToPanel(widgetId, p)) {
          found = p;
          break;
        }
      }
      if (found !== -1) {
        idx = found;
      } else {
        root.configWarning("Already maxed out, please move somewhere else");
        return false;
      }
    }
    setWidgetVisible(widgetId, true, undefined, true);
    return setWidgetPanel(widgetId, idx);
  }

  function addWidgetToSection(widgetId, targetSection) {
    setWidgetVisible(widgetId, true);
    let targetIdx = 0;
    const n = root.panels.length;
    if (targetSection === "left") targetIdx = 0;
    else if (targetSection === "right") targetIdx = Math.max(0, n - 1);
    else targetIdx = n > 2 ? 1 : 0;
    return addWidgetToPanel(widgetId, targetIdx);
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
      if (!canAddWidgetToPanel(widgetId, pIdx - 1)) {
        root.configWarning("Already maxed out, please move somewhere else");
        return false;
      }
      return setWidgetPanel(widgetId, pIdx - 1);
    }
    return false;
  }

  function moveWidgetSectionRight(widgetId) {
    let pIdx = getWidgetPanelIndex(widgetId);
    if (pIdx !== -1 && pIdx < root.panels.length - 1) {
      if (!canAddWidgetToPanel(widgetId, pIdx + 1)) {
        root.configWarning("Already maxed out, please move somewhere else");
        return false;
      }
      return setWidgetPanel(widgetId, pIdx + 1);
    }
    return false;
  }

  function moveWidgetToPanelAt(widgetId, targetPanelIndex, targetItemIndex) {
    if (!widgetId) return false;
    let pList = (root.panels || []).map(arr => (arr || []).slice());
    let rem = (root.removedWidgets || []).filter(w => w !== widgetId);

    // Target < 0 means drop into the unassigned pool
    if (targetPanelIndex < 0 || targetPanelIndex >= pList.length) {
      pList = pList.map(arr => arr.filter(w => w !== widgetId));
      if (rem.indexOf(widgetId) === -1) rem.push(widgetId);
      root.removedWidgets = rem;
      _setCurrentBarPanels(pList);
      return true;
    }

    let srcPanelIndex = -1;
    let srcItemIndex = -1;
    for (let p = 0; p < pList.length; p++) {
      let existingIdx = pList[p].indexOf(widgetId);
      if (existingIdx !== -1) {
        srcPanelIndex = p;
        srcItemIndex = existingIdx;
        break;
      }
    }

    // Check capacity if moving from a different panel or unassigned pool
    if (srcPanelIndex !== targetPanelIndex && pList[targetPanelIndex].length >= root.maxPanelWidgets) {
      root.configWarning("Already maxed out, please move somewhere else");
      return false;
    }

    if (srcPanelIndex !== -1) {
      pList[srcPanelIndex].splice(srcItemIndex, 1);
    }

    let destList = pList[targetPanelIndex];
    let adjustedTargetIdx = targetItemIndex;
    if (srcPanelIndex === targetPanelIndex && srcItemIndex !== -1 && targetItemIndex !== undefined && targetItemIndex > srcItemIndex) {
      adjustedTargetIdx = targetItemIndex - 1;
    }

    let insertIdx = (adjustedTargetIdx === undefined || adjustedTargetIdx < 0)
      ? destList.length
      : Math.max(0, Math.min(destList.length, adjustedTargetIdx));
    destList.splice(insertIdx, 0, widgetId);

    root.removedWidgets = rem;
    setWidgetVisible(widgetId, true, undefined, true);
    _setCurrentBarPanels(pList);
    return true;
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

  function setWidgetVisible(widgetId, val, barId, skipSave) {
    if (!widgetId) return;
    const bId = _resolveBarId(barId);
    const token = "@hidden:" + bId + ":" + widgetId;
    let rem = (root.removedWidgets || []).filter(item => String(item) !== token);
    if (!val) {
      rem.push(token);
    }
    root.removedWidgets = rem;
    root.widgetVisibilityChangeCounter++;
    if (!skipSave) {
      saveConfig();
    }
  }

  function isWidgetInAnyBar(widgetId) {
    if (!root.bars) return false;
    for (let i = 0; i < root.bars.length; i++) {
      const b = root.bars[i];
      if (b && b.enabled !== false && b.panels) {
        for (let p = 0; p < b.panels.length; p++) {
          if (b.panels[p] && b.panels[p].indexOf(widgetId) !== -1) {
            return true;
          }
        }
      }
    }
    return false;
  }

  property bool _loaded: false
  property string _lastSavedJson: ""
  property bool _savePending: false

  function saveConfig() {
    if (saveProcess.running) {
      root._savePending = true;
      return;
    }
    root._savePending = false;

    const primary = (root.bars && root.bars.length > 0) ? root.bars[0] : null;
    const primaryPanels = primary ? primary.panels : root.panels;
    const data = {
      barVisible: primary ? primary.enabled : root.barVisible,
      position: primary ? primary.position : root.position,
      barHeight: primary ? primary.barHeight : root.barHeight,
      floating: primary ? primary.floating : root.floating,
      barOpacity: primary ? primary.barOpacity : root.barOpacity,
      pillRadius: primary && primary.pillRadius !== undefined ? primary.pillRadius : root.pillRadius,
      pillOpacity: primary && primary.pillOpacity !== undefined ? primary.pillOpacity : root.pillOpacity,
      hidePill: primary && primary.hidePill !== undefined ? Boolean(primary.hidePill) : root.hidePill,
      activeStyle: primary && primary.activeStyle !== undefined ? primary.activeStyle : root.activeStyle,
      allMonitors: primary ? primary.allMonitors : root.allMonitors,
      innerCorners: primary && primary.innerCorners !== undefined ? Boolean(primary.innerCorners) : root.innerCorners,
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
      showGlobalMenu: true,
      showGlobalMenuIcon: root.showGlobalMenuIcon,
      showWorkspaces: true,
      workspaceStyle: root.workspaceStyle,
      workspaceScrollSwitch: root.workspaceScrollSwitch,
      showWeather: true,
      weatherLocation: root.weatherLocation,
      weatherUnit: root.weatherUnit,
      weatherMode: root.weatherMode,
      weatherIntervalMinutes: root.weatherIntervalMinutes,
      showTime: true,
      showSeconds: root.showSeconds,
      showDate: root.showDate,
      showTray: true,
      showControlCenter: true,
      showBattery: true,
      batteryShowPercentage: root.batteryShowPercentage,
      batteryLowThreshold: root.batteryLowThreshold,
      showVolume: true,
      showMedia: true,
      showCava: root.showCava,
      cavaMode: root.cavaMode,
      cavaBars: root.cavaBars,
      cavaFramerate: root.cavaFramerate,
      cavaStyle: root.cavaStyle,
      cavaStereo: root.cavaStereo,
      cavaAutoHide: root.cavaAutoHide,
      cavaShowIcon: root.cavaShowIcon,
      hwShowIcons: root.hwShowIcons,
      hwAlertEnabled: root.hwAlertEnabled,
      hwAlertThreshold: root.hwAlertThreshold,
      hwPollInterval: root.hwPollInterval
    };
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

  function applyConfig(cfg) {
    if (!cfg) return;
    if (cfg.barVisible !== undefined) root.barVisible = Boolean(cfg.barVisible);
    if (cfg.position !== undefined) root.position = String(cfg.position);
    if (cfg.barHeight !== undefined) root.barHeight = Number(cfg.barHeight);
    if (cfg.floating !== undefined) root.floating = Boolean(cfg.floating);
    if (cfg.barOpacity !== undefined) root.barOpacity = Number(cfg.barOpacity);
    if (cfg.pillRadius !== undefined) root.pillRadius = Number(cfg.pillRadius);
    if (cfg.pillOpacity !== undefined) root.pillOpacity = Number(cfg.pillOpacity);
    if (cfg.hidePill !== undefined) root.hidePill = Boolean(cfg.hidePill);
    if (cfg.allMonitors !== undefined) root.allMonitors = Boolean(cfg.allMonitors);
    if (cfg.innerCorners !== undefined) root.innerCorners = Boolean(cfg.innerCorners);

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

    function ensureGlobalMenu(panelArr) {
      if (!Array.isArray(panelArr) || panelArr.length === 0) return panelArr;
      if (rem.indexOf("globalMenu") !== -1) return panelArr;
      for (let i = 0; i < panelArr.length; i++) {
        if (panelArr[i].indexOf("globalMenu") !== -1) return panelArr;
      }
      let p0 = panelArr[0].slice();
      let appIdx = p0.indexOf("appGrid");
      if (appIdx !== -1) {
        p0.splice(appIdx + 1, 0, "globalMenu");
      } else {
        p0.unshift("globalMenu");
      }
      panelArr[0] = p0;
      return panelArr;
    }

    pList = ensureGlobalMenu(pList);

    if (Array.isArray(cfg.bars) && cfg.bars.length > 0) {
      root.bars = cfg.bars.map((b, idx) => ({
        id: b.id || ("bar_" + (idx + 1)),
        name: String(b.name || (idx === 0 ? "Primary Bar" : ("Bar " + (idx + 1)))).replace(/\s*\((Top|Bottom|Left|Right)\)$/i, ""),
        enabled: b.enabled !== undefined ? Boolean(b.enabled) : true,
        position: b.position || "top",
        barHeight: b.barHeight !== undefined ? Number(b.barHeight) : 32,
        floating: b.floating !== undefined ? Boolean(b.floating) : false,
        barOpacity: b.barOpacity !== undefined ? Number(b.barOpacity) : root.barOpacity,
        pillRadius: b.pillRadius !== undefined ? Number(b.pillRadius) : root.pillRadius,
        pillOpacity: b.pillOpacity !== undefined ? Number(b.pillOpacity) : root.pillOpacity,
        hidePill: b.hidePill !== undefined ? Boolean(b.hidePill) : root.hidePill,
        activeStyle: b.activeStyle || cfg.activeStyle || root.activeStyle,
        allMonitors: b.allMonitors !== undefined ? Boolean(b.allMonitors) : root.allMonitors,
        innerCorners: b.innerCorners !== undefined ? Boolean(b.innerCorners) : root.innerCorners,
        panels: ensureGlobalMenu(
          Array.isArray(b.panels) && b.panels.length > 0
            ? b.panels.map(arr => Array.isArray(arr) ? arr.slice() : [])
            : pList.map(arr => arr.slice())
        )
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
        pillRadius: root.pillRadius,
        pillOpacity: root.pillOpacity,
        hidePill: root.hidePill,
        activeStyle: root.activeStyle,
        allMonitors: root.allMonitors,
        innerCorners: root.innerCorners,
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
    if (cfg.showGlobalMenuIcon !== undefined) root.showGlobalMenuIcon = Boolean(cfg.showGlobalMenuIcon);
    if (cfg.weatherLocation !== undefined) root.weatherLocation = String(cfg.weatherLocation);
    if (cfg.activeStyle !== undefined) root.activeStyle = String(cfg.activeStyle);
    if (cfg.workspaceStyle !== undefined) root.workspaceStyle = String(cfg.workspaceStyle);
    if (cfg.workspaceScrollSwitch !== undefined) root.workspaceScrollSwitch = Boolean(cfg.workspaceScrollSwitch);
    if (cfg.weatherUnit !== undefined) root.weatherUnit = String(cfg.weatherUnit);
    if (cfg.weatherMode !== undefined) root.weatherMode = String(cfg.weatherMode);
    if (cfg.weatherIntervalMinutes !== undefined) root.weatherIntervalMinutes = Number(cfg.weatherIntervalMinutes);
    if (cfg.batteryShowPercentage !== undefined) root.batteryShowPercentage = Boolean(cfg.batteryShowPercentage);
    if (cfg.batteryLowThreshold !== undefined) root.batteryLowThreshold = Number(cfg.batteryLowThreshold);
    if (cfg.hwShowIcons !== undefined) root.hwShowIcons = Boolean(cfg.hwShowIcons);
    if (cfg.hwAlertEnabled !== undefined) root.hwAlertEnabled = Boolean(cfg.hwAlertEnabled);
    if (cfg.hwAlertThreshold !== undefined) root.hwAlertThreshold = Number(cfg.hwAlertThreshold);
    if (cfg.hwPollInterval !== undefined) root.hwPollInterval = Number(cfg.hwPollInterval);
    if (cfg.showCava !== undefined) root.showCava = Boolean(cfg.showCava);
    if (cfg.cavaMode !== undefined) {
      root.cavaMode = String(cfg.cavaMode);
    } else if (cfg.cavaBars !== undefined) {
      const b = Number(cfg.cavaBars);
      root.cavaMode = b >= 20 ? "wide" : (b >= 14 ? "medium" : "compact");
    }
    if (cfg.cavaBars !== undefined) root.cavaBars = Number(cfg.cavaBars);
    if (cfg.cavaFramerate !== undefined) root.cavaFramerate = Number(cfg.cavaFramerate);
    if (cfg.cavaStyle !== undefined) root.cavaStyle = String(cfg.cavaStyle);
    if (cfg.cavaStereo !== undefined) root.cavaStereo = Boolean(cfg.cavaStereo);
    if (cfg.cavaAutoHide !== undefined) root.cavaAutoHide = Boolean(cfg.cavaAutoHide);
    if (cfg.cavaShowIcon !== undefined) root.cavaShowIcon = Boolean(cfg.cavaShowIcon);
    root.widgetVisibilityChangeCounter++;
  }

  function resetDefaults() {
    root.barVisible = true;
    root.weatherLocation = "Bekasi";
    root.position = "top";
    root.barHeight = 32;
    root.floating = false;
    root.barOpacity = 0.85;
    root.pillRadius = 10;
    root.pillOpacity = 1.0;
    root.hidePill = false;
    root.activeStyle = "pill";
    root.workspaceStyle = "index";
    root.workspaceScrollSwitch = true;
    root.weatherUnit = "m";
    root.weatherMode = "compact";
    root.weatherIntervalMinutes = 15;
    root.batteryShowPercentage = true;
    root.batteryLowThreshold = 20;
    root.hwShowIcons = true;
    root.hwAlertEnabled = true;
    root.hwAlertThreshold = 85;
    root.hwPollInterval = 2;
    root.showCava = true;
    root.cavaMode = "compact";
    root.cavaBars = 8;
    root.cavaFramerate = 30;
    root.cavaStyle = "bars";
    root.cavaStereo = false;
    root.cavaAutoHide = false;
    root.cavaShowIcon = false;
    root.allMonitors = true;
    root.innerCorners = true;

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
        pillRadius: 10,
        pillOpacity: 1.0,
        hidePill: false,
        allMonitors: true,
        innerCorners: true,
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
    root.showGlobalMenu = true;
    root.showGlobalMenuIcon = false;
    root.widgetVisibilityChangeCounter++;
    saveConfig();
  }

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

  Process {
    id: saveProcess
    command: []
    running: false
    onExited: {
      if (root._savePending) {
        root._savePending = false;
        root.saveConfig();
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
