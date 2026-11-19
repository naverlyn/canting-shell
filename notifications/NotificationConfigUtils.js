.pragma library

var INT_SPECS = {
    toastMarginX:     { min: 0,    max: 200,   def: 10,   rev: false },
    toastMarginY:     { min: 0,    max: 200,   def: 10,   rev: false },
    toastWidth:       { min: 280,  max: 520,   def: 360,  rev: false },
    cardRadius:       { min: 0,    max: 28,    def: 16,   rev: false },
    cardSpacing:      { min: 4,    max: 24,    def: 8,    rev: false },
    cardPadding:      { min: 8,    max: 24,    def: 14,   rev: false },
    maxVisibleToasts: { min: 1,    max: 10,    def: 5,    rev: false },
    defaultTimeout:   { min: 1500, max: 20000, def: 5000, rev: false },
    accentStripWidth: { min: 2,    max: 8,     def: 3,    rev: false },
    iconSize:         { min: 16,   max: 48,    def: 24,   rev: true  },
    iconRadius:       { min: 0,    max: 24,    def: 8,    rev: false },
    appNameFontSize:  { min: 9,    max: 16,    def: 11,   rev: true  },
    titleFontSize:    { min: 11,   max: 22,    def: 14,   rev: true  },
    titleMaxLines:    { min: 1,    max: 4,     def: 1,    rev: false },
    bodyFontSize:     { min: 10,   max: 18,    def: 12,   rev: true  },
    bodyMaxLines:     { min: 1,    max: 8,     def: 3,    rev: true  },
    imageSize:        { min: 28,   max: 110,   def: 44,   rev: false },
    imageRadius:      { min: 0,    max: 48,    def: 10,   rev: false, allowZero: true },
    buttonHeight:     { min: 22,   max: 40,    def: 28,   rev: false },
    buttonRadius:     { min: 0,    max: 20,    def: 14,   rev: false },
    progressHeight:   { min: 2,    max: 8,     def: 3,    rev: true  }
};

var ENUM_SPECS = {
    accentStripPosition: { valid: ["left", "right", "top", "none"],       def: "left",  rev: false },
    iconMode:            { valid: ["auto", "inline", "avatar"],           def: "auto",  rev: true  },
    titleAlignment:      { valid: ["left", "center", "right"],            def: "left",  rev: false },
    bodyAlignment:       { valid: ["left", "center", "right"],            def: "left",  rev: false },
    imagePosition:       { valid: ["right", "left", "banner"],            def: "right", rev: true  },
    buttonStyle:         { valid: ["pill", "fill", "ghost"],              def: "pill",  rev: true  },
    buttonAlignment:     { valid: ["left", "center", "right", "stretch"], def: "left",  rev: false }
};

var BOOL_DEFAULTS = {
    doNotDisturb:         false,
    pauseOnHover:         true,
    showAccentStrip:      true,
    iconShowBg:           true,
    titleBold:            true,
    imageShowBg:          true,
    imageShowRing:        true,
    progressShowCritical: false
};

var EXTRA_KEYS = [
    "toastPosition", "headerBlocks", "contentBlocks", "footerBlocks",
    "cardOpacity", "timestampFormat"
];

function clampInt(val, spec) {
    var n = Number(val);
    var num = (val === undefined || val === null || val === "" || isNaN(n)) ? spec.def : n;
    return Math.max(spec.min, Math.min(spec.max, Math.round(num)));
}

function setIntProp(root, key, val) {
    var spec = INT_SPECS[key];
    var clamped = clampInt(val, spec);
    if (root[key] !== clamped) {
        root[key] = clamped;
        if (spec.rev) root.blockOrderRevision++;
        root.saveConfig();
    }
}

function setEnumProp(root, key, val) {
    var spec = ENUM_SPECS[key];
    var clean = String(val || spec.def).toLowerCase();
    if (spec.valid.indexOf(clean) === -1) return;
    if (root[key] !== clean) {
        root[key] = clean;
        if (key === "accentStripPosition") root.showAccentStrip = (clean !== "none");
        if (spec.rev) root.blockOrderRevision++;
        root.saveConfig();
    }
}

function setBoolProp(root, key, val, bumpRev) {
    var b = Boolean(val);
    if (root[key] !== b) {
        root[key] = b;
        if (bumpRev) root.blockOrderRevision++;
        root.saveConfig();
    }
}

function sanitizeBlockList(arr, getBlockDef) {
    if (!Array.isArray(arr)) return [];
    var res = [];
    for (var i = 0; i < arr.length; i++) {
        var id = String(arr[i] || "").trim();
        if (getBlockDef(id) && res.indexOf(id) === -1) {
            res.push(id);
        }
    }
    return res;
}

function resetDefaults(root) {
    var k;
    for (k in BOOL_DEFAULTS) root[k] = BOOL_DEFAULTS[k];
    for (k in INT_SPECS) root[k] = INT_SPECS[k].def;
    for (k in ENUM_SPECS) root[k] = ENUM_SPECS[k].def;

    root.toastPosition = "top-right";
    root.headerBlocks = ["icon", "appName", "closeBtn"];
    root.contentBlocks = ["title", "body", "image"];
    root.footerBlocks = ["buttons", "progressBar"];
    root.cardOpacity = 1.0;
    root.timestampFormat = "relative";

    root.applyComposerPreset("screenshot");
    root.blockOrderRevision++;
    root.blocksUpdated();
    root.saveConfig();
}

function buildConfigData(root) {
    var data = {};
    var k, i;
    for (k in BOOL_DEFAULTS) data[k] = root[k];
    for (k in INT_SPECS) data[k] = root[k];
    for (k in ENUM_SPECS) data[k] = root[k];
    for (i = 0; i < EXTRA_KEYS.length; i++) {
        k = EXTRA_KEYS[i];
        data[k] = root[k];
    }
    return data;
}

function applyConfig(root, cfg) {
    if (!cfg) return;
    var k;

    for (k in BOOL_DEFAULTS) {
        if (cfg[k] !== undefined) root[k] = Boolean(cfg[k]);
    }
    for (k in INT_SPECS) {
        if (cfg[k] !== undefined) root[k] = clampInt(cfg[k], INT_SPECS[k]);
    }
    for (k in ENUM_SPECS) {
        if (cfg[k] !== undefined) {
            var clean = String(cfg[k]).toLowerCase();
            if (ENUM_SPECS[k].valid.indexOf(clean) !== -1) root[k] = clean;
        }
    }

    if (cfg.toastPosition !== undefined) {
        var pos = String(cfg.toastPosition).trim().toLowerCase();
        if (root.validPositions.indexOf(pos) !== -1) root.toastPosition = pos;
    }
    if (Array.isArray(cfg.headerBlocks)) root.headerBlocks = sanitizeBlockList(cfg.headerBlocks, root.getBlockDef);
    if (Array.isArray(cfg.contentBlocks)) root.contentBlocks = sanitizeBlockList(cfg.contentBlocks, root.getBlockDef);
    if (Array.isArray(cfg.footerBlocks)) root.footerBlocks = sanitizeBlockList(cfg.footerBlocks, root.getBlockDef);
    if (cfg.cardOpacity !== undefined) root.cardOpacity = Math.max(0.5, Math.min(1.0, Number(cfg.cardOpacity) || 1.0));
    if (cfg.timestampFormat !== undefined) root.timestampFormat = String(cfg.timestampFormat) === "time" ? "time" : "relative";

    root.blockOrderRevision++;
    root.blocksUpdated();
}
