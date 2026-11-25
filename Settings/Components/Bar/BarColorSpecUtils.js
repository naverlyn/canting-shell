.pragma library

function getBlockColorSpec(barId, widgetId, removedWidgets) {
    if (!widgetId) return "";
    const prefix = "@color:" + barId + ":" + widgetId + "=";
    const rem = removedWidgets || [];
    for (let i = 0; i < rem.length; i++) {
        const s = String(rem[i]);
        if (s.startsWith(prefix)) return s.substring(prefix.length).trim();
    }
    return "";
}

function buildUpdatedWidgetColorSpec(barId, widgetId, spec, removedWidgets) {
    const prefix = "@color:" + barId + ":" + widgetId + "=";
    const rem = (removedWidgets || []).filter(item => !String(item).startsWith(prefix));
    const clean = spec ? String(spec).trim() : "";
    if (clean !== "") rem.push(prefix + clean);
    return rem;
}

function buildUpdatedPanelColorSpecs(barId, widgets, spec, removedWidgets) {
    const prefixes = (widgets || []).map(w => "@color:" + barId + ":" + w + "=");
    const clean = spec ? String(spec).trim() : "";
    const rem = (removedWidgets || []).filter(item => {
        const s = String(item);
        return !prefixes.some(p => s.startsWith(p));
    });
    if (clean !== "") {
        for (let i = 0; i < prefixes.length; i++) {
            rem.push(prefixes[i] + clean);
        }
    }
    return rem;
}

function getPanelUniformColorSpec(barId, widgets, removedWidgets) {
    if (!widgets || widgets.length === 0) return "";
    const firstSpec = getBlockColorSpec(barId, widgets[0], removedWidgets);
    for (let i = 1; i < widgets.length; i++) {
        if (getBlockColorSpec(barId, widgets[i], removedWidgets) !== firstSpec) return "";
    }
    return firstSpec;
}

function getSpecLabel(spec, themeRoles) {
    if (!spec || String(spec).trim() === "") return "Auto";
    const s = String(spec).trim();
    if (s.indexOf("theme:") === 0) {
        const parts = s.split(":");
        if (parts.length >= 3) {
            const tName = parts.slice(1, parts.length - 1).join(":");
            const roleKey = parts[parts.length - 1];
            return tName + " · " + roleKey.replace("accent", "").replace("text", "");
        }
    }
    const roles = themeRoles || [];
    for (let i = 0; i < roles.length; i++) {
        if (roles[i].key === s) return roles[i].label;
    }
    return s;
}
