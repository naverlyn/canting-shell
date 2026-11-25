.pragma library

.import "SocialApps.js" as SocialApps

var _desktopIconCache = {};
var _desktopCacheSize = -1;

function resolveDesktopIconByAppName(app, qsObj, desktopEntriesObj) {
    const lower = String(app || "").toLowerCase().trim();
    if (lower === "" || lower === "notify-send" || lower === "notification") return "";

    const entries = (desktopEntriesObj && desktopEntriesObj.applications && desktopEntriesObj.applications.values)
        ? desktopEntriesObj.applications.values
        : [];

    if (entries.length !== _desktopCacheSize) {
        _desktopIconCache = {};
        _desktopCacheSize = entries.length;
    }
    if (_desktopIconCache[lower] !== undefined) {
        return _desktopIconCache[lower];
    }

    let resolved = "";
    for (let i = 0; i < entries.length; i++) {
        const e = entries[i];
        if (!e || !e.icon) continue;
        const eName = String(e.name || "").toLowerCase();
        const eId = String(e.id || "").toLowerCase();
        const eCls = String(e.startupClass || "").toLowerCase();
        if (eName === lower || eId === lower || eCls === lower || (lower.length >= 3 && (eName.indexOf(lower) !== -1 || eId.indexOf(lower) !== -1))) {
            const ep = qsObj ? qsObj.iconPath(e.icon, true) : "";
            if (ep) {
                resolved = ep;
                break;
            }
        }
    }
    if (!resolved && lower.indexOf("brave") !== -1 && qsObj) {
        resolved = qsObj.iconPath("brave-desktop", true) || qsObj.iconPath("brave-browser", true) || "";
    }
    if (!resolved && qsObj) {
        resolved = qsObj.iconPath(lower.replace(/\s+/g, "-"), true) || qsObj.iconPath(lower, true) || "";
    }

    _desktopIconCache[lower] = resolved;
    return resolved;
}

function resolveIconInfo(item, accentColor, qsObj, desktopEntriesObj) {
    if (!item) return { themeSrc: "", fileSrc: "", fallbackThemeSrc: "", glyph: "", color: accentColor };
    const rawIcon = String(item.appIcon || "").trim();
    const app = String(item.displayAppName || item.appName || "").trim();
    const sum = String(item.summary || "");
    const body = String(item.displayBody || item.body || "");

    const sApp = item.socialApp || SocialApps.detectApp(item.appName || app, rawIcon, sum, body);
    if (sApp) {
        const sPath = (sApp.appIcon && qsObj) ? (qsObj.iconPath(sApp.appIcon, true) || "") : "";
        const isFile = sPath.startsWith("file://") || sPath.startsWith("/");
        return {
            themeSrc: (!isFile && sPath !== "") ? sPath : "",
            fileSrc: isFile ? (sPath.startsWith("/") ? ("file://" + sPath) : sPath) : "",
            fallbackThemeSrc: "",
            glyph: sApp.icon || "",
            color: sApp.color || accentColor
        };
    }

    const desktopFallback = resolveDesktopIconByAppName(item.appName || app, qsObj, desktopEntriesObj);
    const fbIsFile = desktopFallback.startsWith("file://") || desktopFallback.startsWith("/");
    const fbTheme = (!fbIsFile && desktopFallback !== "") ? desktopFallback : "";
    const fbFile = fbIsFile ? (desktopFallback.startsWith("/") ? ("file://" + desktopFallback) : desktopFallback) : "";

    if (rawIcon !== "") {
        const isVolatileTmp = rawIcon.indexOf("/tmp/") !== -1 || rawIcon.indexOf("scoped_dir") !== -1;
        if (isVolatileTmp && desktopFallback !== "") {
            return { themeSrc: fbTheme, fileSrc: fbFile, fallbackThemeSrc: "", glyph: "", color: accentColor };
        }
        if (rawIcon.startsWith("image://icon//")) {
            return { themeSrc: "", fileSrc: "file://" + rawIcon.slice(13), fallbackThemeSrc: fbTheme, glyph: "", color: accentColor };
        }
        if (rawIcon.startsWith("image://icon/")) {
            const validated = qsObj ? (qsObj.iconPath(rawIcon.slice(13), true) || "") : "";
            if (validated !== "") {
                const vFile = validated.startsWith("file://") || validated.startsWith("/");
                return {
                    themeSrc: !vFile ? validated : "",
                    fileSrc: vFile ? (validated.startsWith("/") ? ("file://" + validated) : validated) : "",
                    fallbackThemeSrc: fbTheme,
                    glyph: "",
                    color: accentColor
                };
            }
        } else if (rawIcon.startsWith("file://")) {
            return { themeSrc: "", fileSrc: rawIcon, fallbackThemeSrc: fbTheme, glyph: "", color: accentColor };
        } else if (rawIcon.startsWith("/")) {
            return { themeSrc: "", fileSrc: "file://" + rawIcon, fallbackThemeSrc: fbTheme, glyph: "", color: accentColor };
        } else if (!rawIcon.startsWith("image://")) {
            const validated = qsObj ? (qsObj.iconPath(rawIcon, true) || "") : "";
            if (validated !== "") {
                const vFile = validated.startsWith("file://") || validated.startsWith("/");
                return {
                    themeSrc: !vFile ? validated : "",
                    fileSrc: vFile ? (validated.startsWith("/") ? ("file://" + validated) : validated) : "",
                    fallbackThemeSrc: fbTheme,
                    glyph: "",
                    color: accentColor
                };
            }
        }
    }

    if (desktopFallback !== "") {
        return { themeSrc: fbTheme, fileSrc: fbFile, fallbackThemeSrc: "", glyph: "", color: accentColor };
    }

    return { themeSrc: "", fileSrc: "", fallbackThemeSrc: "", glyph: "", color: accentColor };
}

function buildHistoryButtons(item) {
    if (!item) return [];
    const out = [];
    const rawActs = item.actions;
    const count = (rawActs && rawActs.length !== undefined) ? rawActs.length : 0;
    for (let i = 0; i < count && out.length < 3; i++) {
        const a = rawActs[i];
        if (!a) continue;
        const lbl = String(a.label !== undefined ? a.label : (a.text !== undefined ? a.text : "")).trim();
        if (!lbl) continue;
        out.push({
            kind: "action",
            label: lbl,
            identifier: String(a.identifier || ""),
            customCmd: String(a.customCmd || ""),
            danger: lbl.toLowerCase() === "delete"
        });
    }
    if (out.length === 0) {
        out.push({ kind: "dismiss", label: "Dismiss", identifier: "dismiss", customCmd: "", danger: true });
    }
    return out;
}

function groupHistoryByApp(historyList, maxItems) {
    const raw = (historyList || []).slice(0, maxItems || 20);
    const order = [];
    const map = {};
    for (let i = 0; i < raw.length; i++) {
        const h = raw[i];
        if (!h) continue;
        const appKey = SocialApps.formatAppName(h.displayAppName || h.appName || "", h.socialApp);
        if (!map[appKey]) {
            map[appKey] = { appName: appKey, items: [] };
            order.push(appKey);
        }
        map[appKey].items.push(h);
    }
    return order.map(k => map[k]);
}
