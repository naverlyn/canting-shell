pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "SocialApps.js" as SocialApps
import "NotificationPresets.js" as Presets
import "NotificationConfigUtils.js" as ConfigUtils

Singleton {
    id: root

    readonly property string configPath: Qt.resolvedUrl("../configs/notifications_config.json").toString().replace(/^file:\/\//, "")

    property var notifications: []
    property var history: []
    readonly property int historyCount: history.length
    property bool doNotDisturb: false
    property string toastPosition: "top-right" // "top-left" | "top-center" | "top-right" | "bottom-left" | "bottom-center" | "bottom-right"
    property int toastMarginX: 10
    property int toastMarginY: 10

    // 1. MODULAR BUILDING BLOCKS CONFIGURATION (3 ZONES + POOL)
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

    // 2. CARD DIMENSIONS, TIMING & APPEARANCE
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

    // 3. PER-BUILDING-BLOCK CUSTOMIZATION PROPERTIES
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
    property bool imageShowBg: true
    property bool imageShowRing: true

    // Action Buttons Block ("buttons")
    property string buttonStyle: "pill" // "pill" | "fill" | "ghost"
    property int buttonHeight: 28
    property int buttonRadius: 14
    property string buttonAlignment: "left" // "left" | "center" | "right" | "stretch"

    // Progress Bar Block ("progressBar")
    property int progressHeight: 3
    property bool progressShowCritical: false

    // 4. INTERACTIVE COMPOSER / TEST NOTIFICATION STATE
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

    // BUILDING BLOCKS HELPER FUNCTIONS
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
        const p = Presets.LAYOUT_PRESETS[presetId];
        if (!p) return;
        for (const k in p) {
            root[k] = Array.isArray(p[k]) ? [...p[k]] : p[k];
        }
        root.blockOrderRevision++;
        root.blocksUpdated();
        root.saveConfig();
    }

    // PROPERTY SETTERS
    function setToastPosition(pos) {
        const clean = String(pos || "top-right").trim().toLowerCase();
        if (root.validPositions.indexOf(clean) !== -1 && root.toastPosition !== clean) {
            root.toastPosition = clean;
            root.saveConfig();
        }
    }

    function setToastMarginX(val) { ConfigUtils.setIntProp(root, "toastMarginX", val); }
    function setToastMarginY(val) { ConfigUtils.setIntProp(root, "toastMarginY", val); }
    function setToastWidth(val) { ConfigUtils.setIntProp(root, "toastWidth", val); }
    function setCardRadius(val) { ConfigUtils.setIntProp(root, "cardRadius", val); }
    function setCardSpacing(val) { ConfigUtils.setIntProp(root, "cardSpacing", val); }
    function setCardPadding(val) { ConfigUtils.setIntProp(root, "cardPadding", val); }

    function setCardOpacity(val) {
        const clamped = Math.max(0.5, Math.min(1.0, Math.round((Number(val) || 1.0) * 100) / 100));
        if (root.cardOpacity !== clamped) {
            root.cardOpacity = clamped;
            root.saveConfig();
        }
    }

    function setMaxVisibleToasts(val) { ConfigUtils.setIntProp(root, "maxVisibleToasts", val); }
    function setDefaultTimeout(val) { ConfigUtils.setIntProp(root, "defaultTimeout", val); }
    function setPauseOnHover(val) { ConfigUtils.setBoolProp(root, "pauseOnHover", val, false); }
    function setShowAccentStrip(val) { ConfigUtils.setBoolProp(root, "showAccentStrip", val, false); }
    function setAccentStripPosition(pos) { ConfigUtils.setEnumProp(root, "accentStripPosition", pos); }
    function setAccentStripWidth(val) { ConfigUtils.setIntProp(root, "accentStripWidth", val); }

    function setIconMode(mode) { ConfigUtils.setEnumProp(root, "iconMode", mode); }
    function setIconSize(val) { ConfigUtils.setIntProp(root, "iconSize", val); }
    function setIconRadius(val) { ConfigUtils.setIntProp(root, "iconRadius", val); }
    function setIconShowBg(val) { ConfigUtils.setBoolProp(root, "iconShowBg", val, false); }

    function setAppNameFontSize(val) { ConfigUtils.setIntProp(root, "appNameFontSize", val); }

    function setTimestampFormat(fmt) {
        const clean = String(fmt) === "time" ? "time" : "relative";
        if (root.timestampFormat !== clean) {
            root.timestampFormat = clean;
            root.blockOrderRevision++;
            root.saveConfig();
        }
    }

    function setTitleFontSize(val) { ConfigUtils.setIntProp(root, "titleFontSize", val); }
    function setTitleBold(val) { ConfigUtils.setBoolProp(root, "titleBold", val, true); }
    function setTitleMaxLines(val) { ConfigUtils.setIntProp(root, "titleMaxLines", val); }
    function setTitleAlignment(align) { ConfigUtils.setEnumProp(root, "titleAlignment", align); }

    function setBodyFontSize(val) { ConfigUtils.setIntProp(root, "bodyFontSize", val); }
    function setBodyMaxLines(val) { ConfigUtils.setIntProp(root, "bodyMaxLines", val); }
    function setBodyAlignment(align) { ConfigUtils.setEnumProp(root, "bodyAlignment", align); }

    function setImagePosition(pos) { ConfigUtils.setEnumProp(root, "imagePosition", pos); }
    function setImageSize(val) { ConfigUtils.setIntProp(root, "imageSize", val); }
    function setImageRadius(val) { ConfigUtils.setIntProp(root, "imageRadius", val); }
    function setImageShowBg(val) { ConfigUtils.setBoolProp(root, "imageShowBg", val, false); }
    function setImageShowRing(val) { ConfigUtils.setBoolProp(root, "imageShowRing", val, false); }

    function setButtonStyle(style) { ConfigUtils.setEnumProp(root, "buttonStyle", style); }
    function setButtonHeight(val) { ConfigUtils.setIntProp(root, "buttonHeight", val); }
    function setButtonRadius(val) { ConfigUtils.setIntProp(root, "buttonRadius", val); }
    function setButtonAlignment(align) { ConfigUtils.setEnumProp(root, "buttonAlignment", align); }

    function setProgressHeight(val) { ConfigUtils.setIntProp(root, "progressHeight", val); }
    function setProgressShowCritical(val) { ConfigUtils.setBoolProp(root, "progressShowCritical", val, false); }

    // COMPOSER / TEST NOTIFICATION PRESETS & LIVE DISPATCH
    function applyComposerPreset(presetId) {
        root.composerPreset = presetId;
        const p = Presets.getComposerPreset(presetId, NotificationUrgency);
        if (!p) return;
        root.composerAppName = p.appName;
        root.composerIcon = p.icon;
        root.composerTitle = p.title;
        root.composerBody = p.body;
        root.composerShowImage = p.showImage;
        root.composerUrgency = p.urgency;
        root.composerButtons = p.buttons;
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
        root.recordToHistory(data);
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
        ConfigUtils.resetDefaults(root);
    }

    function saveConfig() {
        if (!root._loaded) return;
        const jsonStr = JSON.stringify(ConfigUtils.buildConfigData(root), null, 2);
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
        ConfigUtils.applyConfig(root, cfg);
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
        keepOnReload:        true

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
            root.recordToHistory(data);

            while (root.notifications.length > root.maxVisibleToasts) {
                root.notifications[root.notifications.length - 1].dismiss();
            }
        }
    }

    function recordToHistory(notifData) {
        if (!notifData) return;
        const nId = String(notifData.notifId || ("item_" + notifData.seqId));
        const appName = String(notifData.appName || "Notification");
        const appIcon = String(notifData.appIcon || "");
        const summary = String(notifData.summary || "New Notification");
        const body = String(notifData.body || "");
        const sApp = notifData.socialApp || SocialApps.detectApp(appName, appIcon, summary, body);
        const displayAppName = String(notifData.displayAppName || SocialApps.formatAppName(appName, sApp) || appName || "Notification");
        const displayBody = String(notifData.displayBody || SocialApps.cleanBody(body, sApp) || body);
        const now = notifData.createdAt || new Date();

        const item = {
            notifId: nId,
            seqId: String(notifData.seqId || ""),
            appName: appName,
            displayAppName: displayAppName,
            appIcon: appIcon,
            customGlyph: String(notifData.customGlyph || ""),
            summary: summary,
            body: body,
            displayBody: displayBody,
            image: String(notifData.image || ""),
            urgency: notifData.urgency !== undefined ? notifData.urgency : NotificationUrgency.Normal,
            createdAt: now,
            timeStr: Qt.formatTime(now, "hh:mm"),
            socialApp: sApp,
            actions: (notifData.actions || []).filter(function(a) {
                return a && a.identifier !== "default" && (a.label || a.text);
            }).map(function(a) {
                return { label: String(a.label || a.text || ""), identifier: String(a.identifier || "") };
            })
        };

        const filtered = (root.history || []).filter(function(h) {
            return h && h.notifId !== nId;
        });
        root.history = [item, ...filtered].slice(0, 50);
    }

    function dismissHistoryItem(notifId) {
        if (!notifId) return;
        const targetId = String(notifId);
        root.history = (root.history || []).filter(function(h) {
            return h && String(h.notifId) !== targetId;
        });
        for (let i = 0; i < root.notifications.length; i++) {
            const n = root.notifications[i];
            if (n && String(n.notifId) === targetId) {
                n.dismiss();
                break;
            }
        }
    }

    function dismissHistoryByApp(appName) {
        if (!appName) return;
        const target = String(appName);
        root.history = (root.history || []).filter(function(h) {
            const name = String((h && (h.displayAppName || h.appName)) || "");
            return name !== target;
        });
    }

    function invokeHistoryAction(notifId, identifier) {
        if (!notifId || !identifier) return;
        const targetId = String(notifId);
        for (let i = 0; i < root.notifications.length; i++) {
            const n = root.notifications[i];
            if (n && String(n.notifId) === targetId) {
                n.invokeAction(identifier);
                return;
            }
        }
    }

    function clearHistory() {
        root.history = [];
        root.dismissAll();
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
        root.recordToHistory(notifData);
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
