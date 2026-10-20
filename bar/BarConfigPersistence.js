.pragma library

// Config (de)serialisation and defaults for BarConfig.
// Each function receives the BarConfig singleton as `root`.

function buildSaveData(root) {
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
    displayTarget: primary && primary.displayTarget !== undefined ? primary.displayTarget : root.displayTarget,
    secondaryPosition: primary && primary.secondaryPosition !== undefined ? primary.secondaryPosition : (root.secondaryPosition || "top"),
    secondaryMode: primary && primary.secondaryMode !== undefined ? primary.secondaryMode : root.secondaryMode,
    blankOnSecondary: primary && primary.blankOnSecondary !== undefined ? Boolean(primary.blankOnSecondary) : root.blankOnSecondary,
    secondaryPanels: primary && primary.secondaryPanels ? primary.secondaryPanels : root.secondaryPanels,
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
  return data;
}

function applyConfig(root, cfg) {
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
  if (cfg.displayTarget !== undefined) {
    root.displayTarget = String(cfg.displayTarget);
  } else if (cfg.allMonitors !== undefined) {
    root.displayTarget = cfg.allMonitors ? "all" : "primary";
  }
  if (cfg.secondaryPosition !== undefined) root.secondaryPosition = String(cfg.secondaryPosition);
  if (cfg.secondaryMode !== undefined) root.secondaryMode = String(cfg.secondaryMode);
  if (cfg.blankOnSecondary !== undefined) root.blankOnSecondary = Boolean(cfg.blankOnSecondary);
  if (Array.isArray(cfg.secondaryPanels) && cfg.secondaryPanels.length > 0) {
    root.secondaryPanels = cfg.secondaryPanels.map(arr => Array.isArray(arr) ? arr.slice() : []);
  }
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
      allMonitors: b.allMonitors !== undefined ? Boolean(b.allMonitors) : (b.displayTarget ? b.displayTarget === "all" : root.allMonitors),
      displayTarget: b.displayTarget || (b.allMonitors !== undefined ? (b.allMonitors ? "all" : "primary") : root.displayTarget),
      secondaryPosition: b.secondaryPosition || root.secondaryPosition || "top",
      secondaryMode: b.secondaryMode || root.secondaryMode,
      blankOnSecondary: b.blankOnSecondary !== undefined ? Boolean(b.blankOnSecondary) : (b.secondaryMode === "blank"),
      secondaryPanels: Array.isArray(b.secondaryPanels) && b.secondaryPanels.length > 0
        ? b.secondaryPanels.map(arr => Array.isArray(arr) ? arr.slice() : [])
        : (Array.isArray(root.secondaryPanels) && root.secondaryPanels.length > 0
          ? root.secondaryPanels.map(arr => arr.slice())
          : root.defaultSecondaryPanels.map(arr => arr.slice())),
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
      displayTarget: root.displayTarget,
      secondaryPosition: root.secondaryPosition || "top",
      secondaryMode: root.secondaryMode,
      blankOnSecondary: root.blankOnSecondary,
      secondaryPanels: root.secondaryPanels,
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

function resetDefaults(root) {
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
  root.displayTarget = "all";
  root.secondaryPosition = "top";
  root.secondaryMode = "custom";
  root.blankOnSecondary = false;
  root.secondaryPanels = [
    ["workspaces"],
    ["windowTitle"],
    ["weather", "clock"]
  ];
  root.activeEditingDisplay = "primary";
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
      displayTarget: "all",
      secondaryPosition: "top",
      secondaryMode: "custom",
      blankOnSecondary: false,
      secondaryPanels: [
        ["workspaces"],
        ["windowTitle"],
        ["weather", "clock"]
      ],
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
  root.saveConfig();
}
