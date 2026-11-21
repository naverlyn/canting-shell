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
    dashed: primary && primary.dashed !== undefined ? Boolean(primary.dashed) : Boolean(root.dashed),
    dynamicIsland: primary && primary.dynamicIsland !== undefined ? Boolean(primary.dynamicIsland) : Boolean(root.dynamicIsland),
    barOpacity: root.barOpacity !== undefined ? root.barOpacity : (primary ? primary.barOpacity : 1.0),
    pillRadius: primary && primary.pillRadius !== undefined ? primary.pillRadius : root.pillRadius,
    barRadius: primary && primary.barRadius !== undefined ? primary.barRadius : root.barRadius,
    barMargin: primary && primary.barMargin !== undefined ? primary.barMargin : root.barMargin,
    pillOpacity: primary && primary.pillOpacity !== undefined ? primary.pillOpacity : root.pillOpacity,
    hidePill: primary && primary.hidePill !== undefined ? Boolean(primary.hidePill) : root.hidePill,
    scaleWidgets: primary && primary.scaleWidgets !== undefined ? Boolean(primary.scaleWidgets) : root.scaleWidgets,
    activeStyle: primary && primary.activeStyle !== undefined ? primary.activeStyle : root.activeStyle,
    allMonitors: primary ? primary.allMonitors : root.allMonitors,
    displayTarget: primary && primary.displayTarget !== undefined ? primary.displayTarget : root.displayTarget,
    secondaryPosition: primary && primary.secondaryPosition !== undefined ? primary.secondaryPosition : (root.secondaryPosition || "top"),
    secondaryFloating: primary && primary.secondaryFloating !== undefined ? Boolean(primary.secondaryFloating) : Boolean(root.secondaryFloating),
    secondaryDashed: primary && primary.secondaryDashed !== undefined ? Boolean(primary.secondaryDashed) : Boolean(root.secondaryDashed),
    secondaryDynamicIsland: primary && primary.secondaryDynamicIsland !== undefined ? Boolean(primary.secondaryDynamicIsland) : Boolean(root.secondaryDynamicIsland),
    islandPosition: primary && primary.islandPosition !== undefined ? String(primary.islandPosition) : root.islandPosition,
    islandIdleMode: primary && primary.islandIdleMode !== undefined ? String(primary.islandIdleMode) : root.islandIdleMode,
    islandLiveActivity: primary && primary.islandLiveActivity !== undefined ? Boolean(primary.islandLiveActivity) : Boolean(root.islandLiveActivity),
    islandLayoutMode: primary && primary.islandLayoutMode !== undefined ? String(primary.islandLayoutMode) : root.islandLayoutMode,
    islandModules: primary && Array.isArray(primary.islandModules) ? primary.islandModules : root.islandModules,
    islandDefaultModule: primary && primary.islandDefaultModule !== undefined ? String(primary.islandDefaultModule) : root.islandDefaultModule,
    islandSplitModules: primary && Array.isArray(primary.islandSplitModules) ? primary.islandSplitModules : root.islandSplitModules,
    islandHoverDelay: primary && primary.islandHoverDelay !== undefined ? Number(primary.islandHoverDelay) : root.islandHoverDelay,
    islandCloseDelay: primary && primary.islandCloseDelay !== undefined ? Number(primary.islandCloseDelay) : root.islandCloseDelay,
    islandExpandedWidth: primary && primary.islandExpandedWidth !== undefined ? Number(primary.islandExpandedWidth) : root.islandExpandedWidth,
    islandNotificationMode: primary && primary.islandNotificationMode !== undefined ? String(primary.islandNotificationMode) : root.islandNotificationMode,
    islandOsdEnabled: primary && primary.islandOsdEnabled !== undefined ? Boolean(primary.islandOsdEnabled) : Boolean(root.islandOsdEnabled),
    islandControlTiles: primary && Array.isArray(primary.islandControlTiles) ? primary.islandControlTiles : root.islandControlTiles,
    islandAppShortcuts: primary && Array.isArray(primary.islandAppShortcuts) ? primary.islandAppShortcuts : root.islandAppShortcuts,
    barDropShadow: primary && primary.barDropShadow !== undefined ? Boolean(primary.barDropShadow) : Boolean(root.barDropShadow),
    barDropShadowTarget: primary && primary.barDropShadowTarget !== undefined ? String(primary.barDropShadowTarget) : root.barDropShadowTarget,
    barDropShadowBlur: primary && primary.barDropShadowBlur !== undefined ? Number(primary.barDropShadowBlur) : root.barDropShadowBlur,
    barDropShadowOpacity: primary && primary.barDropShadowOpacity !== undefined ? Number(primary.barDropShadowOpacity) : root.barDropShadowOpacity,
    barDropShadowOffsetY: primary && primary.barDropShadowOffsetY !== undefined ? Number(primary.barDropShadowOffsetY) : root.barDropShadowOffsetY,
    barDropShadowColorMode: primary && primary.barDropShadowColorMode !== undefined ? String(primary.barDropShadowColorMode) : root.barDropShadowColorMode,
    secondaryMode: primary && primary.secondaryMode !== undefined ? primary.secondaryMode : root.secondaryMode,
    blankOnSecondary: primary && primary.blankOnSecondary !== undefined ? Boolean(primary.blankOnSecondary) : root.blankOnSecondary,
    secondaryPanels: primary && primary.secondaryPanels ? primary.secondaryPanels : root.secondaryPanels,
    innerCorners: primary && primary.innerCorners !== undefined ? Boolean(primary.innerCorners) : root.innerCorners,
    fluidCards: primary && primary.fluidCards !== undefined ? Boolean(primary.fluidCards) : (root.fluidCards !== undefined ? Boolean(root.fluidCards) : false),
    barBorder: primary && primary.barBorder !== undefined ? Boolean(primary.barBorder) : root.barBorder,
    barBorderWidth: primary && primary.barBorderWidth !== undefined ? Number(primary.barBorderWidth) : root.barBorderWidth,
    barBorderColor: primary && primary.barBorderColor !== undefined ? String(primary.barBorderColor) : root.barBorderColor,
    screenBorder: root.screenBorder !== undefined ? Boolean(root.screenBorder) : false,
    screenBorderThickness: root.screenBorderThickness !== undefined ? Number(root.screenBorderThickness) : 4,
    screenBorderColor: root.screenBorderColor !== undefined ? String(root.screenBorderColor) : "",
    screenBorderCorners: root.screenBorderCorners !== undefined ? Boolean(root.screenBorderCorners) : true,
    screenBorderShadow: root.screenBorderShadow !== undefined ? Boolean(root.screenBorderShadow) : false,
    screenBorderShadowSize: root.screenBorderShadowSize !== undefined ? Number(root.screenBorderShadowSize) : 12,
    screenFrameOpacity: root.screenFrameOpacity !== undefined ? Number(root.screenFrameOpacity) : 1.0,
    bars: root.bars,
    panels: primaryPanels,
    leftWidgets: primaryPanels.length > 0 ? primaryPanels[0] : [],
    centerWidgets: primaryPanels.length > 1 ? primaryPanels[1] : [],
    rightWidgets: primaryPanels.length > 2 ? primaryPanels[2] : [],
    removedWidgets: root.removedWidgets,
    showAppGrid: true,
    appGridIcon: root.appGridIcon || "󰀻",
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
    taskSwitcherMode: root.taskSwitcherMode,
    taskSwitcherScope: root.taskSwitcherScope,
    taskSwitcherMaxLabelWidth: root.taskSwitcherMaxLabelWidth,
    showWeather: true,
    weatherLocation: root.weatherLocation,
    weatherUnit: root.weatherUnit,
    weatherMode: root.weatherMode,
    weatherIntervalMinutes: root.weatherIntervalMinutes,
    showTime: true,
    showSeconds: root.showSeconds,
    showDate: root.showDate,
    showYear: root.showYear,
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
    hwPollInterval: root.hwPollInterval,
    gpuShowTemp: root.gpuShowTemp,
    wifiBtMode: root.wifiBtMode,
    wifiBtShowLabels: root.wifiBtShowLabels,
    brightnessShowPercentage: root.brightnessShowPercentage,
    brightnessStep: root.brightnessStep,
    hyprLayoutShowLabel: root.hyprLayoutShowLabel,
    customScriptCommand: root.customScriptCommand,
    customScriptIcon: root.customScriptIcon,
    customScriptInterval: root.customScriptInterval,
    customScriptOnClick: root.customScriptOnClick,
    customScriptOnRightClick: root.customScriptOnRightClick,
    customScriptMaxLength: root.customScriptMaxLength,
    customScriptHideWhenEmpty: root.customScriptHideWhenEmpty,
    customScriptShowPopup: root.customScriptShowPopup,
    mediaPopupStyle: root.mediaPopupStyle,
    mediaShowAlbumArt: root.mediaShowAlbumArt,
    mediaShowSeekbar: root.mediaShowSeekbar
  };
  return data;
}

function applyConfig(root, cfg) {
  if (!cfg) return;
  if (cfg.barVisible !== undefined) root.barVisible = Boolean(cfg.barVisible);
  if (cfg.position !== undefined) root.position = String(cfg.position);
  if (cfg.barHeight !== undefined) root.barHeight = Number(cfg.barHeight);
  if (cfg.floating !== undefined) root.floating = Boolean(cfg.floating);
  if (cfg.dashed !== undefined) root.dashed = Boolean(cfg.dashed);
  if (cfg.dynamicIsland !== undefined) root.dynamicIsland = Boolean(cfg.dynamicIsland) && root.position === "top";
  if (cfg.barOpacity !== undefined) root.barOpacity = Number(cfg.barOpacity);
  if (cfg.screenFrameOpacity !== undefined) {
    root.screenFrameOpacity = Math.max(0.0, Math.min(1.0, Number(cfg.screenFrameOpacity)));
  } else if (cfg.barOpacity !== undefined) {
    root.screenFrameOpacity = Math.max(0.0, Math.min(1.0, Number(cfg.barOpacity)));
  }
  if (cfg.pillRadius !== undefined) root.pillRadius = Number(cfg.pillRadius);
  if (cfg.barRadius !== undefined) root.barRadius = Math.max(0, Math.min(24, Number(cfg.barRadius)));
  if (cfg.barMargin !== undefined) root.barMargin = Math.max(0, Math.min(24, Number(cfg.barMargin)));
  if (cfg.pillOpacity !== undefined) root.pillOpacity = Number(cfg.pillOpacity);
  if (cfg.hidePill !== undefined) root.hidePill = Boolean(cfg.hidePill);
  if (cfg.scaleWidgets !== undefined) root.scaleWidgets = Boolean(cfg.scaleWidgets);
  if (cfg.allMonitors !== undefined) root.allMonitors = Boolean(cfg.allMonitors);
  if (cfg.displayTarget !== undefined) {
    root.displayTarget = String(cfg.displayTarget);
  } else if (cfg.allMonitors !== undefined) {
    root.displayTarget = cfg.allMonitors ? "all" : "primary";
  }
  if (cfg.secondaryPosition !== undefined) root.secondaryPosition = String(cfg.secondaryPosition);
  if (cfg.secondaryFloating !== undefined) root.secondaryFloating = Boolean(cfg.secondaryFloating);
  if (cfg.secondaryDashed !== undefined) root.secondaryDashed = Boolean(cfg.secondaryDashed);
  if (cfg.secondaryDynamicIsland !== undefined) root.secondaryDynamicIsland = Boolean(cfg.secondaryDynamicIsland) && root.secondaryPosition === "top";
  if (cfg.islandPosition !== undefined) root.islandPosition = String(cfg.islandPosition);
  if (cfg.islandIdleMode !== undefined) root.islandIdleMode = String(cfg.islandIdleMode);
  if (cfg.islandLiveActivity !== undefined) root.islandLiveActivity = Boolean(cfg.islandLiveActivity);
  if (cfg.islandLayoutMode !== undefined) root.islandLayoutMode = String(cfg.islandLayoutMode);
  if (Array.isArray(cfg.islandModules) && cfg.islandModules.length > 0) root.islandModules = cfg.islandModules.slice();
  if (cfg.islandDefaultModule !== undefined) root.islandDefaultModule = String(cfg.islandDefaultModule);
  if (Array.isArray(cfg.islandSplitModules) && cfg.islandSplitModules.length >= 2) root.islandSplitModules = cfg.islandSplitModules.slice(0, 2);
  if (cfg.islandHoverDelay !== undefined) root.islandHoverDelay = Math.max(0, Math.min(500, Math.round(Number(cfg.islandHoverDelay))));
  if (cfg.islandCloseDelay !== undefined) root.islandCloseDelay = Math.max(80, Math.min(800, Math.round(Number(cfg.islandCloseDelay))));
  if (cfg.islandExpandedWidth !== undefined) root.islandExpandedWidth = Math.max(320, Math.min(680, Math.round(Number(cfg.islandExpandedWidth))));
  if (cfg.islandNotificationMode !== undefined) root.islandNotificationMode = String(cfg.islandNotificationMode);
  if (cfg.islandOsdEnabled !== undefined) root.islandOsdEnabled = Boolean(cfg.islandOsdEnabled);
  if (Array.isArray(cfg.islandControlTiles)) root.islandControlTiles = cfg.islandControlTiles.slice();
  if (Array.isArray(cfg.islandAppShortcuts)) root.islandAppShortcuts = cfg.islandAppShortcuts.slice();
  if (cfg.barDropShadow !== undefined) root.barDropShadow = Boolean(cfg.barDropShadow);
  if (cfg.barDropShadowTarget !== undefined) root.barDropShadowTarget = String(cfg.barDropShadowTarget);
  if (cfg.barDropShadowBlur !== undefined) root.barDropShadowBlur = Math.max(4, Math.min(36, Math.round(Number(cfg.barDropShadowBlur))));
  if (cfg.barDropShadowOpacity !== undefined) root.barDropShadowOpacity = Math.max(0.05, Math.min(0.85, Number(cfg.barDropShadowOpacity)));
  if (cfg.barDropShadowOffsetY !== undefined) root.barDropShadowOffsetY = Math.max(0, Math.min(16, Math.round(Number(cfg.barDropShadowOffsetY))));
  if (cfg.barDropShadowColorMode !== undefined) root.barDropShadowColorMode = String(cfg.barDropShadowColorMode);
  if (cfg.secondaryMode !== undefined) root.secondaryMode = String(cfg.secondaryMode);
  if (cfg.blankOnSecondary !== undefined) root.blankOnSecondary = Boolean(cfg.blankOnSecondary);
  if (Array.isArray(cfg.secondaryPanels) && cfg.secondaryPanels.length > 0) {
    root.secondaryPanels = cfg.secondaryPanels.map(arr => Array.isArray(arr) ? arr.slice() : []);
  }
  if (cfg.innerCorners !== undefined) root.innerCorners = Boolean(cfg.innerCorners);
  if (cfg.fluidCards !== undefined) root.fluidCards = Boolean(cfg.fluidCards);
  if (cfg.barBorder !== undefined) root.barBorder = Boolean(cfg.barBorder);
  if (cfg.barBorderWidth !== undefined) root.barBorderWidth = Number(cfg.barBorderWidth);
  if (cfg.barBorderColor !== undefined) root.barBorderColor = String(cfg.barBorderColor);
  if (cfg.screenBorder !== undefined) root.screenBorder = Boolean(cfg.screenBorder);
  if (cfg.screenBorderThickness !== undefined) root.screenBorderThickness = Math.max(1, Math.min(32, Math.round(Number(cfg.screenBorderThickness))));
  if (cfg.screenBorderColor !== undefined) root.screenBorderColor = String(cfg.screenBorderColor);
  if (cfg.screenBorderCorners !== undefined) root.screenBorderCorners = Boolean(cfg.screenBorderCorners);
  if (cfg.screenBorderShadow !== undefined) root.screenBorderShadow = Boolean(cfg.screenBorderShadow);
  if (cfg.screenBorderShadowSize !== undefined) root.screenBorderShadowSize = Math.max(1, Math.min(64, Math.round(Number(cfg.screenBorderShadowSize))));

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

  function migrateSplitWifiBt(panelArr) {
    if (!Array.isArray(panelArr)) return panelArr;
    return panelArr.map(arr => {
      if (!Array.isArray(arr)) return [];
      const out = [];
      for (let i = 0; i < arr.length; i++) {
        if (arr[i] === "wifiBluetooth") {
          if (out.indexOf("wifi") === -1) out.push("wifi");
          if (out.indexOf("bluetooth") === -1) out.push("bluetooth");
        } else {
          out.push(arr[i]);
        }
      }
      return out;
    });
  }

  pList = migrateSplitWifiBt(ensureGlobalMenu(pList));

  if (Array.isArray(cfg.bars) && cfg.bars.length > 0) {
    const globalOpacity = (cfg.barOpacity !== undefined) ? Number(cfg.barOpacity) : root.barOpacity;
    root.bars = cfg.bars.map((b, idx) => ({
      id: b.id || ("bar_" + (idx + 1)),
      name: String(b.name || (idx === 0 ? "Primary Bar" : ("Bar " + (idx + 1)))).replace(/\s*\((Top|Bottom|Left|Right)\)$/i, ""),
      enabled: b.enabled !== undefined ? Boolean(b.enabled) : true,
      position: b.position || "top",
      barHeight: b.barHeight !== undefined ? Number(b.barHeight) : 32,
      floating: b.floating !== undefined ? Boolean(b.floating) : false,
      dashed: b.dashed !== undefined ? Boolean(b.dashed) : false,
      dynamicIsland: (b.dynamicIsland !== undefined ? Boolean(b.dynamicIsland) : false) && (b.position || "top") === "top",
      barOpacity: b.barOpacity !== undefined ? Number(b.barOpacity) : globalOpacity,
      pillRadius: b.pillRadius !== undefined ? Number(b.pillRadius) : root.pillRadius,
      barRadius: b.barRadius !== undefined ? Number(b.barRadius) : root.barRadius,
      barMargin: b.barMargin !== undefined ? Number(b.barMargin) : root.barMargin,
      pillOpacity: b.pillOpacity !== undefined ? Number(b.pillOpacity) : root.pillOpacity,
      hidePill: b.hidePill !== undefined ? Boolean(b.hidePill) : root.hidePill,
      scaleWidgets: b.scaleWidgets !== undefined ? Boolean(b.scaleWidgets) : root.scaleWidgets,
      activeStyle: b.activeStyle || cfg.activeStyle || root.activeStyle,
      barColor: b.barColor !== undefined ? String(b.barColor) : "",
      secondaryBarColor: b.secondaryBarColor !== undefined ? String(b.secondaryBarColor) : (b.barColor !== undefined ? String(b.barColor) : ""),
      allMonitors: b.allMonitors !== undefined ? Boolean(b.allMonitors) : (b.displayTarget ? b.displayTarget === "all" : root.allMonitors),
      displayTarget: b.displayTarget || (b.allMonitors !== undefined ? (b.allMonitors ? "all" : "primary") : root.displayTarget),
      secondaryPosition: b.secondaryPosition || root.secondaryPosition || "top",
      secondaryFloating: b.secondaryFloating !== undefined ? Boolean(b.secondaryFloating) : (b.floating !== undefined ? Boolean(b.floating) : false),
      secondaryDashed: b.secondaryDashed !== undefined ? Boolean(b.secondaryDashed) : (b.dashed !== undefined ? Boolean(b.dashed) : false),
      secondaryDynamicIsland: (b.secondaryDynamicIsland !== undefined ? Boolean(b.secondaryDynamicIsland) : false) && (b.secondaryPosition || root.secondaryPosition || "top") === "top",
      islandPosition: b.islandPosition !== undefined ? String(b.islandPosition) : root.islandPosition,
      islandIdleMode: b.islandIdleMode !== undefined ? String(b.islandIdleMode) : root.islandIdleMode,
      islandLiveActivity: b.islandLiveActivity !== undefined ? Boolean(b.islandLiveActivity) : root.islandLiveActivity,
      islandLayoutMode: b.islandLayoutMode !== undefined ? String(b.islandLayoutMode) : root.islandLayoutMode,
      islandModules: Array.isArray(b.islandModules) && b.islandModules.length > 0 ? b.islandModules.slice() : root.islandModules.slice(),
      islandDefaultModule: b.islandDefaultModule !== undefined ? String(b.islandDefaultModule) : root.islandDefaultModule,
      islandSplitModules: Array.isArray(b.islandSplitModules) && b.islandSplitModules.length >= 2 ? b.islandSplitModules.slice(0, 2) : root.islandSplitModules.slice(),
      islandHoverDelay: b.islandHoverDelay !== undefined ? Math.max(0, Math.min(500, Math.round(Number(b.islandHoverDelay)))) : root.islandHoverDelay,
      islandCloseDelay: b.islandCloseDelay !== undefined ? Math.max(80, Math.min(800, Math.round(Number(b.islandCloseDelay)))) : root.islandCloseDelay,
      islandExpandedWidth: b.islandExpandedWidth !== undefined ? Math.max(320, Math.min(680, Math.round(Number(b.islandExpandedWidth)))) : root.islandExpandedWidth,
      islandNotificationMode: b.islandNotificationMode !== undefined ? String(b.islandNotificationMode) : root.islandNotificationMode,
      islandOsdEnabled: b.islandOsdEnabled !== undefined ? Boolean(b.islandOsdEnabled) : root.islandOsdEnabled,
      islandControlTiles: Array.isArray(b.islandControlTiles) ? b.islandControlTiles.slice() : root.islandControlTiles.slice(),
      islandAppShortcuts: Array.isArray(b.islandAppShortcuts) ? b.islandAppShortcuts.slice() : root.islandAppShortcuts.slice(),
      barDropShadow: b.barDropShadow !== undefined ? Boolean(b.barDropShadow) : root.barDropShadow,
      barDropShadowTarget: b.barDropShadowTarget !== undefined ? String(b.barDropShadowTarget) : root.barDropShadowTarget,
      barDropShadowBlur: b.barDropShadowBlur !== undefined ? Math.max(4, Math.min(36, Math.round(Number(b.barDropShadowBlur)))) : root.barDropShadowBlur,
      barDropShadowOpacity: b.barDropShadowOpacity !== undefined ? Math.max(0.05, Math.min(0.85, Number(b.barDropShadowOpacity))) : root.barDropShadowOpacity,
      barDropShadowOffsetY: b.barDropShadowOffsetY !== undefined ? Math.max(0, Math.min(16, Math.round(Number(b.barDropShadowOffsetY)))) : root.barDropShadowOffsetY,
      barDropShadowColorMode: b.barDropShadowColorMode !== undefined ? String(b.barDropShadowColorMode) : root.barDropShadowColorMode,
      secondaryMode: b.secondaryMode || root.secondaryMode,
      blankOnSecondary: b.blankOnSecondary !== undefined ? Boolean(b.blankOnSecondary) : (b.secondaryMode === "blank"),
      secondaryPanels: Array.isArray(b.secondaryPanels) && b.secondaryPanels.length > 0
        ? b.secondaryPanels.map(arr => Array.isArray(arr) ? arr.slice() : [])
        : (Array.isArray(root.secondaryPanels) && root.secondaryPanels.length > 0
          ? root.secondaryPanels.map(arr => arr.slice())
          : root.defaultSecondaryPanels.map(arr => arr.slice())),
      innerCorners: b.innerCorners !== undefined ? Boolean(b.innerCorners) : root.innerCorners,
      fluidCards: b.fluidCards !== undefined ? Boolean(b.fluidCards) : (root.fluidCards !== undefined ? Boolean(root.fluidCards) : false),
      barBorder: b.barBorder !== undefined ? Boolean(b.barBorder) : (root.barBorder !== undefined ? Boolean(root.barBorder) : true),
      barBorderWidth: b.barBorderWidth !== undefined ? Number(b.barBorderWidth) : (root.barBorderWidth !== undefined ? Number(root.barBorderWidth) : 1),
      barBorderColor: b.barBorderColor !== undefined ? String(b.barBorderColor) : (root.barBorderColor || ""),
      panels: migrateSplitWifiBt(ensureGlobalMenu(
        Array.isArray(b.panels) && b.panels.length > 0
          ? b.panels.map(arr => Array.isArray(arr) ? arr.slice() : [])
          : pList.map(arr => arr.slice())
      ))
    }));
  } else {
    root.bars = [{
      id: "bar_1",
      name: "Primary Bar",
      enabled: root.barVisible,
      position: root.position,
      barHeight: root.barHeight,
      floating: root.floating,
      dashed: Boolean(root.dashed),
      dynamicIsland: Boolean(root.dynamicIsland) && root.position === "top",
      barOpacity: root.barOpacity,
      pillRadius: root.pillRadius,
      barRadius: root.barRadius,
      barMargin: root.barMargin,
      pillOpacity: root.pillOpacity,
      hidePill: root.hidePill,
      scaleWidgets: root.scaleWidgets,
      activeStyle: root.activeStyle,
      allMonitors: root.allMonitors,
      displayTarget: root.displayTarget,
      secondaryPosition: root.secondaryPosition || "top",
      secondaryFloating: root.secondaryFloating !== undefined ? Boolean(root.secondaryFloating) : Boolean(root.floating),
      secondaryDashed: root.secondaryDashed !== undefined ? Boolean(root.secondaryDashed) : Boolean(root.dashed),
      secondaryDynamicIsland: Boolean(root.secondaryDynamicIsland) && (root.secondaryPosition || "top") === "top",
      islandPosition: root.islandPosition,
      islandIdleMode: root.islandIdleMode,
      islandLiveActivity: root.islandLiveActivity,
      islandLayoutMode: root.islandLayoutMode,
      islandModules: root.islandModules.slice(),
      islandDefaultModule: root.islandDefaultModule,
      islandSplitModules: root.islandSplitModules.slice(),
      islandHoverDelay: root.islandHoverDelay,
      islandCloseDelay: root.islandCloseDelay,
      islandExpandedWidth: root.islandExpandedWidth,
      islandNotificationMode: root.islandNotificationMode,
      islandOsdEnabled: root.islandOsdEnabled,
      islandControlTiles: root.islandControlTiles.slice(),
      islandAppShortcuts: root.islandAppShortcuts.slice(),
      barDropShadow: root.barDropShadow,
      barDropShadowTarget: root.barDropShadowTarget,
      barDropShadowBlur: root.barDropShadowBlur,
      barDropShadowOpacity: root.barDropShadowOpacity,
      barDropShadowOffsetY: root.barDropShadowOffsetY,
      barDropShadowColorMode: root.barDropShadowColorMode,
      secondaryMode: root.secondaryMode,
      blankOnSecondary: root.blankOnSecondary,
      secondaryPanels: root.secondaryPanels,
      innerCorners: root.innerCorners,
      fluidCards: root.fluidCards !== undefined ? Boolean(root.fluidCards) : false,
      barColor: "",
      secondaryBarColor: "",
      barBorder: root.barBorder,
      barBorderWidth: root.barBorderWidth,
      barBorderColor: root.barBorderColor,
      panels: pList
    }];
  }

  if (root.selectedBarIndex >= root.bars.length) {
    root.selectedBarIndex = 0;
  }

  root.removedWidgets = rem;

  if (cfg.appGridIcon !== undefined) root.appGridIcon = String(cfg.appGridIcon).trim() || "󰀻";
  if (cfg.showNetDown !== undefined) root.showNetDown = Boolean(cfg.showNetDown);
  if (cfg.showNetUp !== undefined) root.showNetUp = Boolean(cfg.showNetUp);
  if (cfg.netCompact !== undefined) root.netCompact = Boolean(cfg.netCompact);
  if (cfg.showSeconds !== undefined) root.showSeconds = Boolean(cfg.showSeconds);
  if (cfg.showDate !== undefined) root.showDate = Boolean(cfg.showDate);
  if (cfg.showYear !== undefined) root.showYear = Boolean(cfg.showYear);
  if (cfg.showGlobalMenuIcon !== undefined) root.showGlobalMenuIcon = Boolean(cfg.showGlobalMenuIcon);
  if (cfg.weatherLocation !== undefined) root.weatherLocation = String(cfg.weatherLocation);
  if (cfg.activeStyle !== undefined) root.activeStyle = String(cfg.activeStyle);
  if (cfg.workspaceStyle !== undefined) root.workspaceStyle = String(cfg.workspaceStyle);
  if (cfg.workspaceScrollSwitch !== undefined) root.workspaceScrollSwitch = Boolean(cfg.workspaceScrollSwitch);
  if (cfg.taskSwitcherMode !== undefined) root.taskSwitcherMode = String(cfg.taskSwitcherMode);
  if (cfg.taskSwitcherScope !== undefined) root.taskSwitcherScope = String(cfg.taskSwitcherScope);
  if (cfg.taskSwitcherMaxLabelWidth !== undefined) root.taskSwitcherMaxLabelWidth = Math.max(60, Math.min(280, Number(cfg.taskSwitcherMaxLabelWidth) || 140));
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
  if (cfg.gpuShowTemp !== undefined) root.gpuShowTemp = Boolean(cfg.gpuShowTemp);
  if (cfg.wifiBtMode !== undefined) root.wifiBtMode = String(cfg.wifiBtMode);
  if (cfg.wifiBtShowLabels !== undefined) root.wifiBtShowLabels = Boolean(cfg.wifiBtShowLabels);
  if (cfg.brightnessShowPercentage !== undefined) root.brightnessShowPercentage = Boolean(cfg.brightnessShowPercentage);
  if (cfg.brightnessStep !== undefined) root.brightnessStep = Math.max(1, Math.min(25, Number(cfg.brightnessStep) || 5));
  if (cfg.hyprLayoutShowLabel !== undefined) root.hyprLayoutShowLabel = Boolean(cfg.hyprLayoutShowLabel);
  if (cfg.customScriptCommand !== undefined) root.customScriptCommand = String(cfg.customScriptCommand);
  if (cfg.customScriptIcon !== undefined) root.customScriptIcon = String(cfg.customScriptIcon);
  if (cfg.customScriptInterval !== undefined) root.customScriptInterval = Math.max(1, Number(cfg.customScriptInterval) || 10);
  if (cfg.customScriptOnClick !== undefined) root.customScriptOnClick = String(cfg.customScriptOnClick);
  if (cfg.customScriptOnRightClick !== undefined) root.customScriptOnRightClick = String(cfg.customScriptOnRightClick);
  if (cfg.customScriptMaxLength !== undefined) root.customScriptMaxLength = Math.max(4, Number(cfg.customScriptMaxLength) || 28);
  if (cfg.customScriptHideWhenEmpty !== undefined) root.customScriptHideWhenEmpty = Boolean(cfg.customScriptHideWhenEmpty);
  if (cfg.customScriptShowPopup !== undefined) root.customScriptShowPopup = Boolean(cfg.customScriptShowPopup);
  if (cfg.mediaPopupStyle === "full" || cfg.mediaPopupStyle === "compact") root.mediaPopupStyle = cfg.mediaPopupStyle;
  if (cfg.mediaShowAlbumArt !== undefined) root.mediaShowAlbumArt = Boolean(cfg.mediaShowAlbumArt);
  if (cfg.mediaShowSeekbar !== undefined) root.mediaShowSeekbar = Boolean(cfg.mediaShowSeekbar);
  root.widgetVisibilityChangeCounter++;
  root.panelsRevision++;
  root.panelsUpdated();
}

function resetDefaults(root) {
  root.barVisible = true;
  root.weatherLocation = "";
  root.position = "top";
  root.barHeight = 32;
  root.floating = false;
  root.dashed = false;
  root.dynamicIsland = false;
  root.secondaryFloating = false;
  root.secondaryDashed = false;
  root.secondaryDynamicIsland = false;
  root.islandPosition = "center";
  root.islandIdleMode = "widgets";
  root.islandLiveActivity = true;
  root.islandLayoutMode = "tabs";
  root.islandModules = ["mpris", "calendar", "notifications", "weather", "quickControls", "systemStats"];
  root.islandDefaultModule = "auto";
  root.islandSplitModules = ["mpris", "calendar"];
  root.islandHoverDelay = 120;
  root.islandCloseDelay = 220;
  root.islandExpandedWidth = 400;
  root.islandNotificationMode = "island";
  root.islandOsdEnabled = false;
  root.islandControlTiles = [];
  root.islandAppShortcuts = [];
  root.barDropShadow = false;
  root.barDropShadowTarget = "all";
  root.barDropShadowBlur = 16;
  root.barDropShadowOpacity = 0.45;
  root.barDropShadowOffsetY = 4;
  root.barDropShadowColorMode = "dark";
  root.barOpacity = 0.85;
  root.screenFrameOpacity = 1.0;
  root.pillRadius = 10;
  root.barRadius = 12;
  root.barMargin = 6;
  root.pillOpacity = 1.0;
  root.hidePill = false;
  root.scaleWidgets = true;
  root.activeStyle = "pill";
  root.workspaceStyle = "index";
  root.workspaceScrollSwitch = true;
  root.taskSwitcherMode = "icon_desc";
  root.taskSwitcherScope = "all";
  root.taskSwitcherMaxLabelWidth = 140;
  root.weatherUnit = "m";
  root.weatherMode = "compact";
  root.weatherIntervalMinutes = 15;
  root.batteryShowPercentage = true;
  root.batteryLowThreshold = 20;
  root.hwShowIcons = true;
  root.hwAlertEnabled = true;
  root.hwAlertThreshold = 85;
  root.hwPollInterval = 2;
  root.gpuShowTemp = false;
  root.wifiBtMode = "both";
  root.wifiBtShowLabels = false;
  root.brightnessShowPercentage = true;
  root.brightnessStep = 5;
  root.hyprLayoutShowLabel = true;
  root.customScriptCommand = "echo '{\"text\": \"Ready\", \"tooltip\": \"Custom Script Module\"}'";
  root.customScriptIcon = "󰆍";
  root.customScriptInterval = 10;
  root.customScriptOnClick = "";
  root.customScriptOnRightClick = "";
  root.customScriptMaxLength = 28;
  root.customScriptHideWhenEmpty = false;
  root.customScriptShowPopup = true;
  root.mediaPopupStyle = "full";
  root.mediaShowAlbumArt = true;
  root.mediaShowSeekbar = true;
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
  root.fluidCards = false;
  root.screenBorder = false;
  root.screenBorderThickness = 4;
  root.screenBorderColor = "";
  root.screenBorderCorners = true;
  root.screenBorderShadow = false;
  root.screenBorderShadowSize = 12;

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
      scaleWidgets: true,
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
      barColor: "",
      secondaryBarColor: "",
      innerCorners: true,
      fluidCards: false,
      panels: [
        root.defaultLeftWidgets.slice(),
        root.defaultCenterWidgets.slice(),
        root.defaultRightWidgets.slice()
      ]
    }
  ];
  root.removedWidgets = ["battery", "volume", "media"];

  root.showAppGrid = true;
  root.appGridIcon = "󰀻";
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
  root.showYear = true;
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
