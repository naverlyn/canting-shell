.pragma library

const DEFAULT_ISLAND_MODULES = ["mpris", "calendar", "notifications", "weather", "quickControls", "systemStats"];
const DEFAULT_ISLAND_SPLIT_MODULES = ["mpris", "calendar"];
const DEFAULT_LEFT_WIDGETS = ["appGrid", "globalMenu", "cpu", "temp", "memory", "disk", "network"];
const DEFAULT_CENTER_WIDGETS = ["windowTitle"];
const DEFAULT_RIGHT_WIDGETS = ["tray", "clock", "workspaces", "weather", "idleInhibitor", "controlCenter"];
const DEFAULT_SECONDARY_PANELS = [
  ["workspaces"],
  ["windowTitle"],
  ["weather", "clock"]
];

function clonePanels(panels) {
  return (panels || []).map(p => Array.isArray(p) ? p.slice() : []);
}

function createBarInstance(overrides) {
  const o = overrides || {};
  return Object.assign({
    id: "bar_1",
    name: "Primary Bar",
    enabled: true,
    position: "top",
    barHeight: 32,
    floating: false,
    dashed: false,
    dynamicIsland: false,
    barOpacity: 0.85,
    pillRadius: 10,
    barRadius: 12,
    barMargin: 6,
    pillOpacity: 1.0,
    hidePill: false,
    scaleWidgets: true,
    activeStyle: "pill",
    barColor: "",
    secondaryBarColor: "",
    allMonitors: true,
    displayTarget: "all",
    secondaryPosition: "bottom",
    secondaryFloating: false,
    secondaryDashed: false,
    secondaryDynamicIsland: false,
    islandPosition: "center",
    islandIdleMode: "widgets",
    islandLiveActivity: true,
    islandLayoutMode: "tabs",
    islandModules: DEFAULT_ISLAND_MODULES.slice(),
    islandDefaultModule: "auto",
    islandSplitModules: DEFAULT_ISLAND_SPLIT_MODULES.slice(),
    islandHoverDelay: 120,
    islandCloseDelay: 220,
    islandExpandedWidth: 400,
    islandNotificationMode: "island",
    islandOsdEnabled: false,
    islandControlTiles: [],
    islandAppShortcuts: [],
    barDropShadow: false,
    barDropShadowTarget: "all",
    barDropShadowBlur: 16,
    barDropShadowOpacity: 0.45,
    barDropShadowOffsetY: 4,
    barDropShadowColorMode: "dark",
    secondaryMode: "custom",
    blankOnSecondary: false,
    secondaryPanels: clonePanels(DEFAULT_SECONDARY_PANELS),
    innerCorners: true,
    fluidCards: false,
    barBorder: true,
    barBorderWidth: 1,
    barBorderColor: "",
    panels: [
      DEFAULT_LEFT_WIDGETS.slice(),
      DEFAULT_CENTER_WIDGETS.slice(),
      DEFAULT_RIGHT_WIDGETS.slice()
    ]
  }, o);
}

function syncPrimaryBarToRoot(root, b0) {
  if (!root || !b0) return;
  root.barVisible = Boolean(b0.enabled !== false);
  root.position = String(b0.position || "top");
  root.barHeight = Number(b0.barHeight || 32);
  root.floating = Boolean(b0.floating);
  root.dashed = Boolean(b0.dashed);
  root.dynamicIsland = Boolean(b0.dynamicIsland) && root.position === "top";
  root.barOpacity = b0.barOpacity !== undefined ? Number(b0.barOpacity) : root.barOpacity;
  root.pillRadius = b0.pillRadius !== undefined ? Number(b0.pillRadius) : root.pillRadius;
  root.barRadius = b0.barRadius !== undefined ? Number(b0.barRadius) : root.barRadius;
  root.barMargin = b0.barMargin !== undefined ? Number(b0.barMargin) : root.barMargin;
  root.pillOpacity = b0.pillOpacity !== undefined ? Number(b0.pillOpacity) : root.pillOpacity;
  root.hidePill = Boolean(b0.hidePill);
  root.scaleWidgets = b0.scaleWidgets !== undefined ? Boolean(b0.scaleWidgets) : true;
  if (b0.activeStyle) root.activeStyle = String(b0.activeStyle);
  root.displayTarget = b0.displayTarget || (b0.allMonitors ? "all" : "primary");
  root.allMonitors = (root.displayTarget === "all");
  root.secondaryPosition = String(b0.secondaryPosition || "bottom");
  root.secondaryFloating = Boolean(b0.secondaryFloating);
  root.secondaryDashed = Boolean(b0.secondaryDashed);
  root.secondaryDynamicIsland = Boolean(b0.secondaryDynamicIsland) && root.secondaryPosition === "top";
  if (b0.islandPosition !== undefined) root.islandPosition = String(b0.islandPosition);
  if (b0.islandIdleMode !== undefined) root.islandIdleMode = String(b0.islandIdleMode);
  if (b0.islandLiveActivity !== undefined) root.islandLiveActivity = Boolean(b0.islandLiveActivity);
  if (b0.islandLayoutMode !== undefined) root.islandLayoutMode = String(b0.islandLayoutMode);
  if (Array.isArray(b0.islandModules)) root.islandModules = b0.islandModules.slice();
  if (b0.islandDefaultModule !== undefined) root.islandDefaultModule = String(b0.islandDefaultModule);
  if (Array.isArray(b0.islandSplitModules)) root.islandSplitModules = b0.islandSplitModules.slice();
  if (b0.islandHoverDelay !== undefined) root.islandHoverDelay = Math.max(0, Math.min(500, Math.round(Number(b0.islandHoverDelay))));
  if (b0.islandCloseDelay !== undefined) root.islandCloseDelay = Math.max(80, Math.min(800, Math.round(Number(b0.islandCloseDelay))));
  if (b0.islandExpandedWidth !== undefined) root.islandExpandedWidth = Math.max(320, Math.min(680, Math.round(Number(b0.islandExpandedWidth))));
  if (b0.islandNotificationMode !== undefined) root.islandNotificationMode = String(b0.islandNotificationMode);
  if (b0.islandOsdEnabled !== undefined) root.islandOsdEnabled = Boolean(b0.islandOsdEnabled);
  if (Array.isArray(b0.islandControlTiles)) root.islandControlTiles = b0.islandControlTiles.slice();
  if (Array.isArray(b0.islandAppShortcuts)) root.islandAppShortcuts = b0.islandAppShortcuts.slice();
  if (b0.barDropShadow !== undefined) root.barDropShadow = Boolean(b0.barDropShadow);
  if (b0.barDropShadowTarget !== undefined) root.barDropShadowTarget = String(b0.barDropShadowTarget);
  if (b0.barDropShadowBlur !== undefined) root.barDropShadowBlur = Math.max(4, Math.min(36, Math.round(Number(b0.barDropShadowBlur))));
  if (b0.barDropShadowOpacity !== undefined) root.barDropShadowOpacity = Math.max(0.05, Math.min(0.85, Number(b0.barDropShadowOpacity)));
  if (b0.barDropShadowOffsetY !== undefined) root.barDropShadowOffsetY = Math.max(0, Math.min(16, Math.round(Number(b0.barDropShadowOffsetY))));
  if (b0.barDropShadowColorMode !== undefined) root.barDropShadowColorMode = String(b0.barDropShadowColorMode);
  root.secondaryMode = b0.secondaryMode || (b0.blankOnSecondary ? "blank" : "custom");
  root.blankOnSecondary = b0.blankOnSecondary !== undefined ? Boolean(b0.blankOnSecondary) : (root.secondaryMode === "blank");
  if (Array.isArray(b0.secondaryPanels)) root.secondaryPanels = clonePanels(b0.secondaryPanels);
  if (b0.innerCorners !== undefined) root.innerCorners = Boolean(b0.innerCorners);
  if (b0.fluidCards !== undefined) root.fluidCards = Boolean(b0.fluidCards);
  if (b0.barBorder !== undefined) root.barBorder = Boolean(b0.barBorder);
  if (b0.barBorderWidth !== undefined) root.barBorderWidth = Math.max(1, Math.min(10, Number(b0.barBorderWidth)));
  if (b0.barBorderColor !== undefined) root.barBorderColor = String(b0.barBorderColor);
}
