pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property string configPath: Qt.resolvedUrl("../notifications_config.json").toString().replace(/^file:\/\//, "")

    property var notifications: []
    property bool doNotDisturb: false
    property string toastPosition: "top-right" // "top-left" | "top-center" | "top-right" | "bottom-left" | "bottom-center" | "bottom-right"
    property int toastMarginX: 10
    property int toastMarginY: 10

    // =========================================================================
    // 1. MODULAR BUILDING BLOCKS CONFIGURATION (3 ZONES + POOL)
    // =========================================================================
    property var headerBlocks: ["icon", "appName", "closeBtn"]
    property var contentBlocks: ["title", "body", "image"]
    property var footerBlocks: ["buttons", "progressBar"]

    readonly property var allBlockDefs: [
        { id: "icon",        label: "App Icon",           icon: "󰂚", defaultZone: 0, desc: "Application icon badge or glyph indicator" },
        { id: "appName",     label: "App Name",           icon: "󰀻", defaultZone: 0, desc: "Source application title (e.g. notify-send, Spotify)" },
        { id: "timestamp",   label: "Timestamp",          icon: "󰥔", defaultZone: 0, desc: "Notification arrival time badge (Now / HH:mm)" },
        { id: "closeBtn",    label: "Close Button",       icon: "󰅖", defaultZone: 0, desc: "Quick dismiss (✕) button in the card header" },
        { id: "title",       label: "Title Notification", icon: "󰗴", defaultZone: 1, desc: "Bold notification summary / headline text" },
        { id: "body",        label: "Body Message",       icon: "󰦨", defaultZone: 1, desc: "Main notification message body content" },
        { id: "image",       label: "Preview Image",      icon: "󰋩", defaultZone: 1, desc: "Screenshot, album art, or inline thumbnail image" },
        { id: "buttons",     label: "Action Buttons",     icon: "󰘊", defaultZone: 2, desc: "Interactive action buttons (Open, Delete, Reply)" },
        { id: "progressBar", label: "Timeout Bar",        icon: "󰔟", defaultZone: 2, desc: "Animated auto-dismiss countdown progress bar" }
    ]

    signal blocksUpdated()
    property int blockOrderRevision: 0

    // =========================================================================
    // 2. CARD DIMENSIONS, TIMING & APPEARANCE
    // =========================================================================
    property int toastWidth: 360
    property int cardRadius: 16
    property int cardSpacing: 8
    property int cardPadding: 14
    property real cardOpacity: 1.0
    property int maxVisibleToasts: 5
    property int defaultTimeout: 5000
    property bool pauseOnHover: true

    // Accent / Urgency Strip
    property bool showAccentStrip: true
    property string accentStripPosition: "left" // "left" | "right" | "top" | "none"
    property int accentStripWidth: 3

    // =========================================================================
    // 3. PER-BUILDING-BLOCK CUSTOMIZATION PROPERTIES
    // =========================================================================
    // Icon Block ("icon")
    property string iconMode: "auto" // "auto" | "inline" | "avatar"
    property int iconSize: 24
    property int iconRadius: 8
    property bool iconShowBg: true

    // App Name & Timestamp ("appName", "timestamp")
    property int appNameFontSize: 11
    property string timestampFormat: "relative" // "relative" ("Now") | "time" ("HH:mm")

    // Title Notification Block ("title")
    property int titleFontSize: 14
    property bool titleBold: true
    property int titleMaxLines: 1
    property string titleAlignment: "left" // "left" | "center" | "right"

    // Body Message Block ("body")
    property int bodyFontSize: 12
    property int bodyMaxLines: 3
    property string bodyAlignment: "left" // "left" | "center" | "right"

    // Preview Image Block ("image")
    property string imagePosition: "right" // "right" | "left" | "banner"
    property int imageSize: 44
    property int imageRadius: 10

    // Action Buttons Block ("buttons")
    property string buttonStyle: "pill" // "pill" | "fill" | "ghost"
    property int buttonHeight: 28
    property int buttonRadius: 14
    property string buttonAlignment: "left" // "left" | "center" | "right" | "stretch"

    // Progress Bar Block ("progressBar")
    property int progressHeight: 3
    property bool progressShowCritical: false

    // =========================================================================
    // 4. INTERACTIVE COMPOSER / TEST NOTIFICATION STATE
    // =========================================================================
    property string composerPreset: "screenshot" // "screenshot" | "message" | "media" | "critical" | "custom"
    property string composerAppName: "notify-send"
    property string composerIcon: "󰂚"
    property string composerTitle: "Screenshot:"
    property string composerBody: "Captured by Swappy"
    property bool composerShowImage: true
    property string composerImagePath: ""
    property int composerUrgency: NotificationUrgency.Normal
    property var composerButtons: [
        { label: "Open", cmd: "" },
        { label: "Delete", cmd: "" }
    ]

    readonly property int count: notifications.length
    property int _seqCounter: 0
    property bool _loaded: false
    property string _lastSavedJson: ""

    readonly property var validPositions: [
        "top-left", "top-center", "top-right",
        "bottom-left", "bottom-center", "bottom-right"
    ]

    onDoNotDisturbChanged: {
        if (root._loaded) root.saveConfig();
    }

    // =========================================================================
    // BUILDING BLOCKS HELPER FUNCTIONS
    // =========================================================================
    function getBlockDef(id) {
        for (let i = 0; i < root.allBlockDefs.length; i++) {
            if (root.allBlockDefs[i].id === id) return root.allBlockDefs[i];
        }
        return null;
    }

    function getZoneIds(zIdx) {
        if (zIdx === 0) return root.headerBlocks || [];
        if (zIdx === 1) return root.contentBlocks || [];
        if (zIdx === 2) return root.footerBlocks || [];
        return [];
    }

    function setZoneIds(zIdx, list) {
        if (zIdx === 0) root.headerBlocks = list;
        else if (zIdx === 1) root.contentBlocks = list;
        else if (zIdx === 2) root.footerBlocks = list;
    }

    function getZoneBlocks(zIdx) {
        void root.blockOrderRevision;
        const ids = root.getZoneIds(zIdx);
        let res = [];
        for (let i = 0; i < ids.length; i++) {
            const def = root.getBlockDef(ids[i]);
            if (def) {
                res.push({
                    id: def.id,
                    label: def.label,
                    icon: def.icon,
                    desc: def.desc,
                    defaultZone: def.defaultZone,
                    zoneIndex: zIdx,
                    itemIndex: res.length
                });
            }
        }
        return res;
    }

    readonly property var zone1Blocks: getZoneBlocks(0)
    readonly property var zone2Blocks: getZoneBlocks(1)
    readonly property var zone3Blocks: getZoneBlocks(2)

    function getBlockZoneIndex(id) {
        void root.blockOrderRevision;
        for (let z = 0; z < 3; z++) {
            const list = root.getZoneIds(z);
            if (list.indexOf(id) !== -1) return z;
        }
        return -1;
    }

    function isBlockVisible(id) {
        return root.getBlockZoneIndex(id) !== -1;
    }

    readonly property bool isAvatarIconEffective: {
        void root.blockOrderRevision;
        if (!root.isBlockVisible("icon")) return false;
        if (root.iconMode === "avatar") return true;
        if (root.iconMode === "inline") return false;
        // "auto": avatar when placed in Content zone (zone 1)
        return root.getBlockZoneIndex("icon") === 1;
    }

    readonly property var unassignedBlocks: {
        void root.blockOrderRevision;
        let res = [];
        for (let i = 0; i < root.allBlockDefs.length; i++) {
            const def = root.allBlockDefs[i];
            if (!root.isBlockVisible(def.id)) {
                res.push(def);
            }
        }
        return res;
    }

    function getBlockBadge(blockId) {
        void root.blockOrderRevision;
        switch (blockId) {
            case "icon":
                return (root.isAvatarIconEffective ? "Avatar" : "Header") + " · " + root.iconSize + "px ↻";
            case "appName":
                return root.appNameFontSize + "px";
            case "timestamp":
                return (root.timestampFormat === "time" ? "HH:mm" : "Relative") + " ↻";
            case "closeBtn":
                return "Dismiss ✕";
            case "title":
                return root.titleFontSize + "px" + (root.titleBold ? " Bold" : "") + " ↻";
            case "body":
                return root.bodyMaxLines + (root.bodyMaxLines === 1 ? " line" : " lines") + " · " + root.bodyFontSize + "px";
            case "image":
                return (root.imagePosition === "banner" ? "Banner" : (root.imagePosition === "left" ? "Left" : "Right")) + " ↻";
            case "buttons":
                return (root.buttonStyle === "fill" ? "Full Width" : (root.buttonStyle === "ghost" ? "Ghost" : "Pill")) + " ↻";
            case "progressBar":
                return (root.defaultTimeout / 1000).toFixed(1).replace(/\.0$/, "") + "s · " + root.progressHeight + "px";
            default:
                return "";
        }
    }

    function cycleBlockQuickOption(blockId) {
        switch (blockId) {
            case "icon":
                if (root.iconMode === "auto") root.setIconMode("avatar");
                else if (root.iconMode === "avatar") root.setIconMode("inline");
                else root.setIconMode("auto");
                return "Icon layout: " + (root.isAvatarIconEffective ? "Left Avatar" : "Inline Header");
            case "timestamp":
                root.setTimestampFormat(root.timestampFormat === "relative" ? "time" : "relative");
                return "Timestamp format: " + (root.timestampFormat === "time" ? "Clock (HH:mm)" : "Relative (Now)");
            case "title":
                root.setTitleBold(!root.titleBold);
                return "Title weight: " + (root.titleBold ? "Bold" : "Regular");
            case "image":
                if (root.imagePosition === "right") root.setImagePosition("left");
                else if (root.imagePosition === "left") root.setImagePosition("banner");
                else root.setImagePosition("right");
                return "Preview Image: " + (root.imagePosition === "banner" ? "Full Banner" : (root.imagePosition === "left" ? "Left Thumbnail" : "Right Thumbnail"));
            case "buttons":
                if (root.buttonStyle === "pill") root.setButtonStyle("fill");
                else if (root.buttonStyle === "fill") root.setButtonStyle("ghost");
                else root.setButtonStyle("pill");
                return "Action Buttons style: " + (root.buttonStyle === "fill" ? "Full Width" : (root.buttonStyle === "ghost" ? "Minimal Ghost" : "Rounded Pills"));
            default:
                return "";
        }
    }

    function setBlockVisible(blockId, visible) {
        const def = root.getBlockDef(blockId);
        if (!def) return;
        if (!visible) {
            root.headerBlocks = (root.headerBlocks || []).filter(id => id !== blockId);
            root.contentBlocks = (root.contentBlocks || []).filter(id => id !== blockId);
            root.footerBlocks = (root.footerBlocks || []).filter(id => id !== blockId);
            root.blockOrderRevision++;
            root.blocksUpdated();
            root.saveConfig();
        } else if (!root.isBlockVisible(blockId)) {
            const targetZ = def.defaultZone !== undefined ? def.defaultZone : 1;
            root.moveBlockToZoneAt(blockId, targetZ, -1);
        }
    }

    function moveBlockInZone(zoneIdx, fromIdx, toIdx) {
        let list = [...root.getZoneIds(zoneIdx)];
        if (fromIdx < 0 || fromIdx >= list.length) return;
        if (toIdx < 0 || toIdx >= list.length) return;
        if (fromIdx === toIdx) return;
        const item = list.splice(fromIdx, 1)[0];
        list.splice(toIdx, 0, item);
        root.setZoneIds(zoneIdx, list);
        root.blockOrderRevision++;
        root.blocksUpdated();
        root.saveConfig();
    }

    function moveBlockLeftRight(blockId, delta) {
        const curZone = root.getBlockZoneIndex(blockId);
        if (curZone === -1) return false;
        const targetZone = curZone + delta;
        if (targetZone < 0 || targetZone > 2) return false;
        return root.moveBlockToZoneAt(blockId, targetZone, -1);
    }

    function moveBlockToZoneAt(blockId, targetZoneIdx, targetItemIdx) {
        if (!root.getBlockDef(blockId)) return false;
        let z0 = (root.headerBlocks || []).filter(id => id !== blockId);
        let z1 = (root.contentBlocks || []).filter(id => id !== blockId);
        let z2 = (root.footerBlocks || []).filter(id => id !== blockId);

        if (targetZoneIdx >= 0 && targetZoneIdx <= 2) {
            let targetList = targetZoneIdx === 0 ? z0 : (targetZoneIdx === 1 ? z1 : z2);
            const ins = (targetItemIdx >= 0 && targetItemIdx <= targetList.length)
                ? targetItemIdx
                : targetList.length;
            targetList.splice(ins, 0, blockId);
        }

        root.headerBlocks = z0;
        root.contentBlocks = z1;
        root.footerBlocks = z2;
        root.blockOrderRevision++;
        root.blocksUpdated();
        root.saveConfig();
        return true;
    }

    function applyLayoutPreset(presetId) {
        if (presetId === "standard") {
            root.headerBlocks = ["icon", "appName", "closeBtn"];
            root.contentBlocks = ["title", "body", "image"];
            root.footerBlocks = ["buttons", "progressBar"];
            root.iconMode = "auto";
            root.iconSize = 24;
            root.imagePosition = "right";
            root.imageSize = 44;
            root.buttonStyle = "pill";
            root.showAccentStrip = true;
            root.accentStripPosition = "left";
        } else if (presetId === "avatar") {
            root.headerBlocks = ["appName", "timestamp", "closeBtn"];
            root.contentBlocks = ["icon", "title", "body", "image"];
            root.footerBlocks = ["buttons", "progressBar"];
            root.iconMode = "avatar";
            root.iconSize = 36;
            root.imagePosition = "right";
            root.imageSize = 44;
            root.buttonStyle = "fill";
            root.showAccentStrip = true;
            root.accentStripPosition = "left";
        } else if (presetId === "banner") {
            root.headerBlocks = ["icon", "appName", "timestamp", "closeBtn"];
            root.contentBlocks = ["title", "body", "image"];
            root.footerBlocks = ["buttons", "progressBar"];
            root.iconMode = "inline";
            root.iconSize = 24;
            root.imagePosition = "banner";
            root.imageSize = 72;
            root.buttonStyle = "fill";
            root.showAccentStrip = true;
            root.accentStripPosition = "top";
        } else if (presetId === "compact") {
            root.headerBlocks = ["icon", "title", "closeBtn"];
            root.contentBlocks = ["body"];
            root.footerBlocks = ["buttons"];
            root.iconMode = "inline";
            root.iconSize = 20;
            root.imageSize = 44;
            root.buttonStyle = "ghost";
            root.showAccentStrip = true;
            root.accentStripPosition = "left";
        } else if (presetId === "detailed") {
            root.headerBlocks = ["icon", "appName", "timestamp", "closeBtn"];
            root.contentBlocks = ["title", "body", "image"];
            root.footerBlocks = ["buttons", "progressBar"];
            root.iconMode = "auto";
            root.iconSize = 24;
            root.imagePosition = "right";
            root.imageSize = 44;
            root.buttonStyle = "pill";
            root.showAccentStrip = true;
            root.accentStripPosition = "left";
        }
        root.blockOrderRevision++;
        root.blocksUpdated();
        root.saveConfig();
    }

    // =========================================================================
    // PROPERTY SETTERS
    // =========================================================================
    function setToastPosition(pos) {
        const clean = String(pos || "top-right").trim().toLowerCase();
        if (root.validPositions.indexOf(clean) === -1) return;
        if (root.toastPosition !== clean) {
            root.toastPosition = clean;
            root.saveConfig();
        }
    }

    function setToastMarginX(val) {
        const clamped = Math.max(0, Math.min(200, Math.round(Number(val) || 0)));
        if (root.toastMarginX !== clamped) {
            root.toastMarginX = clamped;
            root.saveConfig();
        }
    }

    function setToastMarginY(val) {
        const clamped = Math.max(0, Math.min(200, Math.round(Number(val) || 0)));
        if (root.toastMarginY !== clamped) {
            root.toastMarginY = clamped;
            root.saveConfig();
        }
    }

    function setToastWidth(val) {
        const clamped = Math.max(280, Math.min(520, Math.round(Number(val) || 360)));
        if (root.toastWidth !== clamped) {
            root.toastWidth = clamped;
            root.saveConfig();
        }
    }

    function setCardRadius(val) {
        const clamped = Math.max(0, Math.min(28, Math.round(Number(val) || 0)));
        if (root.cardRadius !== clamped) {
            root.cardRadius = clamped;
            root.saveConfig();
        }
    }

    function setCardSpacing(val) {
        const clamped = Math.max(4, Math.min(24, Math.round(Number(val) || 8)));
        if (root.cardSpacing !== clamped) {
            root.cardSpacing = clamped;
            root.saveConfig();
        }
    }

    function setCardPadding(val) {
        const clamped = Math.max(8, Math.min(24, Math.round(Number(val) || 14)));
        if (root.cardPadding !== clamped) {
            root.cardPadding = clamped;
            root.saveConfig();
        }
    }

    function setCardOpacity(val) {
        const clamped = Math.max(0.5, Math.min(1.0, Math.round((Number(val) || 1.0) * 100) / 100));
        if (root.cardOpacity !== clamped) {
            root.cardOpacity = clamped;
            root.saveConfig();
        }
    }

    function setMaxVisibleToasts(val) {
        const clamped = Math.max(1, Math.min(10, Math.round(Number(val) || 5)));
        if (root.maxVisibleToasts !== clamped) {
            root.maxVisibleToasts = clamped;
            root.saveConfig();
        }
    }

    function setDefaultTimeout(val) {
        const clamped = Math.max(1500, Math.min(20000, Math.round(Number(val) || 5000)));
        if (root.defaultTimeout !== clamped) {
            root.defaultTimeout = clamped;
            root.saveConfig();
        }
    }

    function setPauseOnHover(val) {
        const b = Boolean(val);
        if (root.pauseOnHover !== b) {
            root.pauseOnHover = b;
            root.saveConfig();
        }
    }

    function setShowAccentStrip(val) {
        const b = Boolean(val);
        if (root.showAccentStrip !== b) {
            root.showAccentStrip = b;
            root.saveConfig();
        }
    }

    function setAccentStripPosition(pos) {
        const valid = ["left", "right", "top", "none"];
        const clean = String(pos || "left").toLowerCase();
        if (valid.indexOf(clean) === -1) return;
        if (root.accentStripPosition !== clean) {
            root.accentStripPosition = clean;
            root.showAccentStrip = (clean !== "none");
            root.saveConfig();
        }
    }

    function setAccentStripWidth(val) {
        const clamped = Math.max(2, Math.min(8, Math.round(Number(val) || 3)));
        if (root.accentStripWidth !== clamped) {
            root.accentStripWidth = clamped;
            root.saveConfig();
        }
    }

    function setIconMode(mode) {
        const valid = ["auto", "inline", "avatar"];
        const clean = String(mode || "auto").toLowerCase();
        if (valid.indexOf(clean) === -1) return;
        if (root.iconMode !== clean) {
            root.iconMode = clean;
            root.blockOrderRevision++;
            root.saveConfig();
        }
    }

    function setIconSize(val) {
        const clamped = Math.max(16, Math.min(48, Math.round(Number(val) || 24)));
        if (root.iconSize !== clamped) {
            root.iconSize = clamped;
            root.blockOrderRevision++;
            root.saveConfig();
        }
    }

    function setIconRadius(val) {
        const clamped = Math.max(0, Math.min(24, Math.round(Number(val) || 8)));
        if (root.iconRadius !== clamped) {
            root.iconRadius = clamped;
            root.saveConfig();
        }
    }

    function setIconShowBg(val) {
        const b = Boolean(val);
        if (root.iconShowBg !== b) {
            root.iconShowBg = b;
            root.saveConfig();
        }
    }

    function setAppNameFontSize(val) {
        const clamped = Math.max(9, Math.min(16, Math.round(Number(val) || 11)));
        if (root.appNameFontSize !== clamped) {
            root.appNameFontSize = clamped;
            root.blockOrderRevision++;
            root.saveConfig();
        }
    }

    function setTimestampFormat(fmt) {
        const clean = String(fmt) === "time" ? "time" : "relative";
        if (root.timestampFormat !== clean) {
            root.timestampFormat = clean;
            root.blockOrderRevision++;
            root.saveConfig();
        }
    }

    function setTitleFontSize(val) {
        const clamped = Math.max(11, Math.min(22, Math.round(Number(val) || 14)));
        if (root.titleFontSize !== clamped) {
            root.titleFontSize = clamped;
            root.blockOrderRevision++;
            root.saveConfig();
        }
    }

    function setTitleBold(val) {
        const b = Boolean(val);
        if (root.titleBold !== b) {
            root.titleBold = b;
            root.blockOrderRevision++;
            root.saveConfig();
        }
    }

    function setTitleMaxLines(val) {
        const clamped = Math.max(1, Math.min(4, Math.round(Number(val) || 1)));
        if (root.titleMaxLines !== clamped) {
            root.titleMaxLines = clamped;
            root.saveConfig();
        }
    }

    function setTitleAlignment(align) {
        const valid = ["left", "center", "right"];
        const clean = String(align || "left").toLowerCase();
        if (valid.indexOf(clean) === -1) return;
        if (root.titleAlignment !== clean) {
            root.titleAlignment = clean;
            root.saveConfig();
        }
    }

    function setBodyFontSize(val) {
        const clamped = Math.max(10, Math.min(18, Math.round(Number(val) || 12)));
        if (root.bodyFontSize !== clamped) {
            root.bodyFontSize = clamped;
            root.blockOrderRevision++;
            root.saveConfig();
        }
    }

    function setBodyMaxLines(val) {
        const clamped = Math.max(1, Math.min(8, Math.round(Number(val) || 3)));
        if (root.bodyMaxLines !== clamped) {
            root.bodyMaxLines = clamped;
            root.blockOrderRevision++;
            root.saveConfig();
        }
    }

    function setBodyAlignment(align) {
        const valid = ["left", "center", "right"];
        const clean = String(align || "left").toLowerCase();
        if (valid.indexOf(clean) === -1) return;
        if (root.bodyAlignment !== clean) {
            root.bodyAlignment = clean;
            root.saveConfig();
        }
    }

    function setImagePosition(pos) {
        const valid = ["right", "left", "banner"];
        const clean = String(pos || "right").toLowerCase();
        if (valid.indexOf(clean) === -1) return;
        if (root.imagePosition !== clean) {
            root.imagePosition = clean;
            root.blockOrderRevision++;
            root.saveConfig();
        }
    }

    function setImageSize(val) {
        const clamped = Math.max(28, Math.min(110, Math.round(Number(val) || 44)));
        if (root.imageSize !== clamped) {
            root.imageSize = clamped;
            root.saveConfig();
        }
    }

    function setImageRadius(val) {
        const clamped = Math.max(0, Math.min(24, Math.round(Number(val) || 10)));
        if (root.imageRadius !== clamped) {
            root.imageRadius = clamped;
            root.saveConfig();
        }
    }

    function setButtonStyle(style) {
        const valid = ["pill", "fill", "ghost"];
        const clean = String(style || "pill").toLowerCase();
        if (valid.indexOf(clean) === -1) return;
        if (root.buttonStyle !== clean) {
            root.buttonStyle = clean;
            root.blockOrderRevision++;
            root.saveConfig();
        }
    }

    function setButtonHeight(val) {
        const clamped = Math.max(22, Math.min(40, Math.round(Number(val) || 28)));
        if (root.buttonHeight !== clamped) {
            root.buttonHeight = clamped;
            root.saveConfig();
        }
    }

    function setButtonRadius(val) {
        const clamped = Math.max(0, Math.min(20, Math.round(Number(val) || 14)));
        if (root.buttonRadius !== clamped) {
            root.buttonRadius = clamped;
            root.saveConfig();
        }
    }

    function setButtonAlignment(align) {
        const valid = ["left", "center", "right", "stretch"];
        const clean = String(align || "left").toLowerCase();
        if (valid.indexOf(clean) === -1) return;
        if (root.buttonAlignment !== clean) {
            root.buttonAlignment = clean;
            root.saveConfig();
        }
    }

    function setProgressHeight(val) {
        const clamped = Math.max(2, Math.min(8, Math.round(Number(val) || 3)));
        if (root.progressHeight !== clamped) {
            root.progressHeight = clamped;
            root.blockOrderRevision++;
            root.saveConfig();
        }
    }

    function setProgressShowCritical(val) {
        const b = Boolean(val);
        if (root.progressShowCritical !== b) {
            root.progressShowCritical = b;
            root.saveConfig();
        }
    }

    // =========================================================================
    // COMPOSER / TEST NOTIFICATION PRESETS & LIVE DISPATCH
    // =========================================================================
    function applyComposerPreset(presetId) {
        root.composerPreset = presetId;
        if (presetId === "screenshot") {
            root.composerAppName = "notify-send";
            root.composerIcon = "󰂚";
            root.composerTitle = "Screenshot:";
            root.composerBody = "Captured by Swappy";
            root.composerShowImage = true;
            root.composerUrgency = NotificationUrgency.Normal;
            root.composerButtons = [
                { label: "Open", cmd: "" },
                { label: "Delete", cmd: "" }
            ];
        } else if (presetId === "message") {
            root.composerAppName = "WhatsApp Web";
            root.composerIcon = "󰖣";
            root.composerTitle = "Alex Rivera";
            root.composerBody = "Hey! Are we still on for the design review at 10:00?";
            root.composerShowImage = false;
            root.composerUrgency = NotificationUrgency.Normal;
            root.composerButtons = [
                { label: "Reply", cmd: "" },
                { label: "Mark Read", cmd: "" }
            ];
        } else if (presetId === "media") {
            root.composerAppName = "Spotify";
            root.composerIcon = "󰓇";
            root.composerTitle = "Midnight City";
            root.composerBody = "M83 — Hurry Up, We're Dreaming";
            root.composerShowImage = true;
            root.composerUrgency = NotificationUrgency.Low;
            root.composerButtons = [
                { label: "Previous", cmd: "" },
                { label: "Pause", cmd: "" },
                { label: "Next", cmd: "" }
            ];
        } else if (presetId === "critical") {
            root.composerAppName = "System Monitor";
            root.composerIcon = "󰀦";
            root.composerTitle = "Critical Battery Alert";
            root.composerBody = "Battery level is at 7%. Connect power adapter immediately.";
            root.composerShowImage = false;
            root.composerUrgency = NotificationUrgency.Critical;
            root.composerButtons = [
                { label: "Power Saver", cmd: "" },
                { label: "Dismiss", cmd: "" }
            ];
        }
    }

    function addComposerButton(label, cmd) {
        let copy = [...(root.composerButtons || [])];
        if (copy.length >= 4) return false;
        copy.push({
            label: String(label || ("Button " + (copy.length + 1))).trim() || "Action",
            cmd: String(cmd || "").trim()
        });
        root.composerButtons = copy;
        return true;
    }

    function updateComposerButton(idx, label, cmd) {
        let copy = [...(root.composerButtons || [])];
        if (idx < 0 || idx >= copy.length) return;
        copy[idx] = {
            label: String(label !== undefined ? label : copy[idx].label),
            cmd: String(cmd !== undefined ? cmd : (copy[idx].cmd || ""))
        };
        root.composerButtons = copy;
    }

    function removeComposerButton(idx) {
        let copy = [...(root.composerButtons || [])];
        if (idx < 0 || idx >= copy.length) return;
        copy.splice(idx, 1);
        root.composerButtons = copy;
    }

    function sendCustomNotification(opts) {
        const p = opts || {};
        const appName = p.appName !== undefined ? String(p.appName) : root.composerAppName;
        const customGlyph = p.customGlyph !== undefined ? String(p.customGlyph) : root.composerIcon;
        const appIcon = p.appIcon !== undefined ? String(p.appIcon) : "";
        const summary = p.summary !== undefined ? String(p.summary) : root.composerTitle;
        const body = p.body !== undefined ? String(p.body) : root.composerBody;
        const showImg = p.showImage !== undefined ? Boolean(p.showImage) : root.composerShowImage;
        const imgPath = p.image !== undefined ? String(p.image) : (showImg ? (root.composerImagePath || "__sample__") : "");
        const urgency = p.urgency !== undefined ? Number(p.urgency) : root.composerUrgency;
        const rawBtns = p.buttons !== undefined ? p.buttons : root.composerButtons;

        let parsedActs = [];
        if (Array.isArray(rawBtns)) {
            for (let i = 0; i < rawBtns.length; i++) {
                const b = rawBtns[i];
                if (!b) continue;
                const lbl = String(b.label !== undefined ? b.label : (b.text || "")).trim();
                if (lbl === "") continue;
                parsedActs.push({
                    identifier: "custom_" + i,
                    text: lbl,
                    isReply: lbl.toLowerCase() === "reply",
                    customCmd: String(b.cmd || "")
                });
            }
        }

        const seq = String(root._seqCounter++);
        const data = notifDataComp.createObject(root, {
            notification: null,
            seqId: seq,
            notifId: "composer_" + seq,
            appName: appName,
            appIcon: appIcon,
            customGlyph: customGlyph,
            summary: summary,
            body: body,
            image: imgPath,
            urgency: urgency,
            actions: parsedActs,
            expireTimeout: root.defaultTimeout
        });

        root.notifications = [data, ...root.notifications];
        while (root.notifications.length > root.maxVisibleToasts) {
            root.notifications[root.notifications.length - 1].dismiss();
        }
    }

    function resetPositionDefaults() {
        root.toastPosition = "top-right";
        root.toastMarginX = 10;
        root.toastMarginY = 10;
        root.saveConfig();
    }

    function resetDefaults() {
        root.doNotDisturb = false;
        root.toastPosition = "top-right";
        root.toastMarginX = 10;
        root.toastMarginY = 10;

        root.headerBlocks = ["icon", "appName", "closeBtn"];
        root.contentBlocks = ["title", "body", "image"];
        root.footerBlocks = ["buttons", "progressBar"];

        root.toastWidth = 360;
        root.cardRadius = 16;
        root.cardSpacing = 8;
        root.cardPadding = 14;
        root.cardOpacity = 1.0;
        root.maxVisibleToasts = 5;
        root.defaultTimeout = 5000;
        root.pauseOnHover = true;

        root.showAccentStrip = true;
        root.accentStripPosition = "left";
        root.accentStripWidth = 3;

        root.iconMode = "auto";
        root.iconSize = 24;
        root.iconRadius = 8;
        root.iconShowBg = true;

        root.appNameFontSize = 11;
        root.timestampFormat = "relative";

        root.titleFontSize = 14;
        root.titleBold = true;
        root.titleMaxLines = 1;
        root.titleAlignment = "left";

        root.bodyFontSize = 12;
        root.bodyMaxLines = 3;
        root.bodyAlignment = "left";

        root.imagePosition = "right";
        root.imageSize = 44;
        root.imageRadius = 10;

        root.buttonStyle = "pill";
        root.buttonHeight = 28;
        root.buttonRadius = 14;
        root.buttonAlignment = "left";

        root.progressHeight = 3;
        root.progressShowCritical = false;

        root.applyComposerPreset("screenshot");
        root.blockOrderRevision++;
        root.blocksUpdated();
        root.saveConfig();
    }

    function saveConfig() {
        if (!root._loaded) return;
        const data = {
            doNotDisturb: root.doNotDisturb,
            toastPosition: root.toastPosition,
            toastMarginX: root.toastMarginX,
            toastMarginY: root.toastMarginY,
            headerBlocks: root.headerBlocks,
            contentBlocks: root.contentBlocks,
            footerBlocks: root.footerBlocks,
            toastWidth: root.toastWidth,
            cardRadius: root.cardRadius,
            cardSpacing: root.cardSpacing,
            cardPadding: root.cardPadding,
            cardOpacity: root.cardOpacity,
            maxVisibleToasts: root.maxVisibleToasts,
            defaultTimeout: root.defaultTimeout,
            pauseOnHover: root.pauseOnHover,
            showAccentStrip: root.showAccentStrip,
            accentStripPosition: root.accentStripPosition,
            accentStripWidth: root.accentStripWidth,
            iconMode: root.iconMode,
            iconSize: root.iconSize,
            iconRadius: root.iconRadius,
            iconShowBg: root.iconShowBg,
            appNameFontSize: root.appNameFontSize,
            timestampFormat: root.timestampFormat,
            titleFontSize: root.titleFontSize,
            titleBold: root.titleBold,
            titleMaxLines: root.titleMaxLines,
            titleAlignment: root.titleAlignment,
            bodyFontSize: root.bodyFontSize,
            bodyMaxLines: root.bodyMaxLines,
            bodyAlignment: root.bodyAlignment,
            imagePosition: root.imagePosition,
            imageSize: root.imageSize,
            imageRadius: root.imageRadius,
            buttonStyle: root.buttonStyle,
            buttonHeight: root.buttonHeight,
            buttonRadius: root.buttonRadius,
            buttonAlignment: root.buttonAlignment,
            progressHeight: root.progressHeight,
            progressShowCritical: root.progressShowCritical
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

    function _sanitizeBlockList(arr) {
        if (!Array.isArray(arr)) return [];
        let res = [];
        for (let i = 0; i < arr.length; i++) {
            const id = String(arr[i] || "").trim();
            if (root.getBlockDef(id) && res.indexOf(id) === -1) {
                res.push(id);
            }
        }
        return res;
    }

    function applyConfig(cfg) {
        if (!cfg) return;
        if (cfg.doNotDisturb !== undefined) root.doNotDisturb = Boolean(cfg.doNotDisturb);
        if (cfg.toastPosition !== undefined) {
            const p = String(cfg.toastPosition).trim().toLowerCase();
            if (root.validPositions.indexOf(p) !== -1) root.toastPosition = p;
        }
        if (cfg.toastMarginX !== undefined) {
            root.toastMarginX = Math.max(0, Math.min(200, Math.round(Number(cfg.toastMarginX) || 0)));
        }
        if (cfg.toastMarginY !== undefined) {
            root.toastMarginY = Math.max(0, Math.min(200, Math.round(Number(cfg.toastMarginY) || 0)));
        }

        if (Array.isArray(cfg.headerBlocks)) root.headerBlocks = root._sanitizeBlockList(cfg.headerBlocks);
        if (Array.isArray(cfg.contentBlocks)) root.contentBlocks = root._sanitizeBlockList(cfg.contentBlocks);
        if (Array.isArray(cfg.footerBlocks)) root.footerBlocks = root._sanitizeBlockList(cfg.footerBlocks);

        if (cfg.toastWidth !== undefined) root.toastWidth = Math.max(280, Math.min(520, Math.round(Number(cfg.toastWidth) || 360)));
        if (cfg.cardRadius !== undefined) root.cardRadius = Math.max(0, Math.min(28, Math.round(Number(cfg.cardRadius) || 0)));
        if (cfg.cardSpacing !== undefined) root.cardSpacing = Math.max(4, Math.min(24, Math.round(Number(cfg.cardSpacing) || 8)));
        if (cfg.cardPadding !== undefined) root.cardPadding = Math.max(8, Math.min(24, Math.round(Number(cfg.cardPadding) || 14)));
        if (cfg.cardOpacity !== undefined) root.cardOpacity = Math.max(0.5, Math.min(1.0, Number(cfg.cardOpacity) || 1.0));
        if (cfg.maxVisibleToasts !== undefined) root.maxVisibleToasts = Math.max(1, Math.min(10, Math.round(Number(cfg.maxVisibleToasts) || 5)));
        if (cfg.defaultTimeout !== undefined) root.defaultTimeout = Math.max(1500, Math.min(20000, Math.round(Number(cfg.defaultTimeout) || 5000)));
        if (cfg.pauseOnHover !== undefined) root.pauseOnHover = Boolean(cfg.pauseOnHover);

        if (cfg.showAccentStrip !== undefined) root.showAccentStrip = Boolean(cfg.showAccentStrip);
        if (cfg.accentStripPosition !== undefined) {
            const ap = String(cfg.accentStripPosition).toLowerCase();
            if (["left", "right", "top", "none"].indexOf(ap) !== -1) root.accentStripPosition = ap;
        }
        if (cfg.accentStripWidth !== undefined) root.accentStripWidth = Math.max(2, Math.min(8, Math.round(Number(cfg.accentStripWidth) || 3)));

        if (cfg.iconMode !== undefined) {
            const im = String(cfg.iconMode).toLowerCase();
            if (["auto", "inline", "avatar"].indexOf(im) !== -1) root.iconMode = im;
        }
        if (cfg.iconSize !== undefined) root.iconSize = Math.max(16, Math.min(48, Math.round(Number(cfg.iconSize) || 24)));
        if (cfg.iconRadius !== undefined) root.iconRadius = Math.max(0, Math.min(24, Math.round(Number(cfg.iconRadius) || 8)));
        if (cfg.iconShowBg !== undefined) root.iconShowBg = Boolean(cfg.iconShowBg);

        if (cfg.appNameFontSize !== undefined) root.appNameFontSize = Math.max(9, Math.min(16, Math.round(Number(cfg.appNameFontSize) || 11)));
        if (cfg.timestampFormat !== undefined) root.timestampFormat = String(cfg.timestampFormat) === "time" ? "time" : "relative";

        if (cfg.titleFontSize !== undefined) root.titleFontSize = Math.max(11, Math.min(22, Math.round(Number(cfg.titleFontSize) || 14)));
        if (cfg.titleBold !== undefined) root.titleBold = Boolean(cfg.titleBold);
        if (cfg.titleMaxLines !== undefined) root.titleMaxLines = Math.max(1, Math.min(4, Math.round(Number(cfg.titleMaxLines) || 1)));
        if (cfg.titleAlignment !== undefined) {
            const ta = String(cfg.titleAlignment).toLowerCase();
            if (["left", "center", "right"].indexOf(ta) !== -1) root.titleAlignment = ta;
        }

        if (cfg.bodyFontSize !== undefined) root.bodyFontSize = Math.max(10, Math.min(18, Math.round(Number(cfg.bodyFontSize) || 12)));
        if (cfg.bodyMaxLines !== undefined) root.bodyMaxLines = Math.max(1, Math.min(8, Math.round(Number(cfg.bodyMaxLines) || 3)));
        if (cfg.bodyAlignment !== undefined) {
            const ba = String(cfg.bodyAlignment).toLowerCase();
            if (["left", "center", "right"].indexOf(ba) !== -1) root.bodyAlignment = ba;
        }

        if (cfg.imagePosition !== undefined) {
            const ip = String(cfg.imagePosition).toLowerCase();
            if (["right", "left", "banner"].indexOf(ip) !== -1) root.imagePosition = ip;
        }
        if (cfg.imageSize !== undefined) root.imageSize = Math.max(28, Math.min(110, Math.round(Number(cfg.imageSize) || 44)));
        if (cfg.imageRadius !== undefined) root.imageRadius = Math.max(0, Math.min(24, Math.round(Number(cfg.imageRadius) || 10)));

        if (cfg.buttonStyle !== undefined) {
            const bs = String(cfg.buttonStyle).toLowerCase();
            if (["pill", "fill", "ghost"].indexOf(bs) !== -1) root.buttonStyle = bs;
        }
        if (cfg.buttonHeight !== undefined) root.buttonHeight = Math.max(22, Math.min(40, Math.round(Number(cfg.buttonHeight) || 28)));
        if (cfg.buttonRadius !== undefined) root.buttonRadius = Math.max(0, Math.min(20, Math.round(Number(cfg.buttonRadius) || 14)));
        if (cfg.buttonAlignment !== undefined) {
            const bAlign = String(cfg.buttonAlignment).toLowerCase();
            if (["left", "center", "right", "stretch"].indexOf(bAlign) !== -1) root.buttonAlignment = bAlign;
        }

        if (cfg.progressHeight !== undefined) root.progressHeight = Math.max(2, Math.min(8, Math.round(Number(cfg.progressHeight) || 3)));
        if (cfg.progressShowCritical !== undefined) root.progressShowCritical = Boolean(cfg.progressShowCritical);

        root.blockOrderRevision++;
        root.blocksUpdated();
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
                console.error("Failed to parse notifications_config.json:", e);
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

    Component {
        id: notifDataComp
        NotificationData {}
    }

    function isOsdNotification(notification) {
        if (!notification) return false;
        const app = String(notification.appName || "").toLowerCase();
        const summary = String(notification.summary || "").toLowerCase();
        const body = String(notification.body || "").toLowerCase();

        // 1. Volume level or Volume: or Microphone: notifications
        if (summary.includes("volume level") || summary.includes("volume:") || summary.includes("microphone:") || summary.includes("mic mute")) {
            return true;
        }
        if (body.includes("volume level") || body.includes("volume:")) {
            return true;
        }

        // 2. notify-send specifically sending volume or brightness
        if (app.includes("notify-send") || app === "" || app === "volume") {
            if (summary.includes("volume") || summary.includes("mute") || summary.includes("brightness") || summary.includes("microphone")) {
                return true;
            }
            if (body.includes("volume") || body.includes("brightness") || body.includes("switched on") || body.includes("switched off")) {
                return true;
            }
        }

        // 3. Brightness level notifications
        if (summary.includes("brightness level") || summary.includes("brightness:")) {
            return true;
        }

        return false;
    }

    NotificationServer {
        id: server
        actionsSupported:    true
        bodySupported:       true
        bodyMarkupSupported: true
        imageSupported:      true
        keepOnReload:        false

        onNotification: function(notification) {
            if (root.doNotDisturb) return;

            if (!notification.appName && !notification.summary
                && !notification.body && !notification.image) return;

            // Suppress volume and brightness notifications that duplicate Quickshell's OSD
            if (root.isOsdNotification(notification)) {
                try { notification.dismiss(); } catch(e) {}
                return;
            }

            notification.tracked = true;

            const idStr = String(notification.id || "");
            if (idStr !== "") {
                const existing = root.notifications.find(function(n) {
                    return n.notifId === idStr;
                });
                if (existing && !existing.closed) {
                    existing.closed = true;
                    root.notifications = root.notifications.filter(function(n) {
                        return n !== existing;
                    });
                    existing.destroy();
                }
            }

            const data = notifDataComp.createObject(root, {
                notification: notification,
                seqId: String(root._seqCounter++)
            });

            root.notifications = [data, ...root.notifications];

            while (root.notifications.length > root.maxVisibleToasts) {
                root.notifications[root.notifications.length - 1].dismiss();
            }
        }
    }

    function _remove(notifData) {
        root.notifications = root.notifications.filter(function(n) {
            return n !== notifData;
        });
    }

    function _bump(notifData) {
        if (!notifData || notifData.closed) return;
        notifData.seqId = String(root._seqCounter++);
        const rest = root.notifications.filter(function(n) {
            return n !== notifData;
        });
        root.notifications = [notifData, ...rest];
    }

    function dismiss(notifData) {
        if (notifData) notifData.dismiss();
    }

    function dismissAll() {
        const toRemove = [...root.notifications];
        root.notifications = [];
        for (const n of toRemove) {
            if (!n.closed) {
                n.closed = true;
                if (n.notification) try { n.notification.dismiss(); } catch(e) {}
                n.destroy();
            }
        }
    }
}
