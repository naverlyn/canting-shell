.pragma library

function getAppKey(entry) {
    return (entry && (entry.id || entry.name)) ? (entry.id || entry.name) : "";
}

function getFrecencyScore(entry, usageMap) {
    const key = getAppKey(entry);
    if (!key || !usageMap || !usageMap[key]) return 0;
    const item = usageMap[key];
    const count = item.count || 0;
    if (count <= 0) return 0;
    return (item.lastUsed || 0) + (count * 86400000);
}

function filterAndSortApps(rawEntries, searchQuery, usageMap, cfg) {
    const list = rawEntries ? [...rawEntries] : [];
    const usage = usageMap || {};
    const q = String(searchQuery || "").trim().toLowerCase();
    const matchGen = cfg ? Boolean(cfg.matchGenericName) : true;
    const matchKw = cfg ? Boolean(cfg.matchKeywords) : true;
    const matchCat = cfg ? Boolean(cfg.matchCategories) : false;
    const sortMode = (cfg && cfg.sortMode) ? String(cfg.sortMode) : "frecency";

    const visible = list.filter(d => {
        if (!d) return false;
        const key = getAppKey(d);
        return !(cfg && typeof cfg.isAppHidden === "function" && cfg.isAppHidden(key));
    });

    function compareBySortMode(a, b, aLower, bLower) {
        if (sortMode === "alphabetical") {
            return aLower.localeCompare(bLower);
        }
        if (sortMode === "recent") {
            const recA = (usage[getAppKey(a)] || {}).lastUsed || 0;
            const recB = (usage[getAppKey(b)] || {}).lastUsed || 0;
            if (recA !== recB) return recB - recA;
            return aLower.localeCompare(bLower);
        }
        const scoreA = getFrecencyScore(a, usage);
        const scoreB = getFrecencyScore(b, usage);
        if (scoreA !== scoreB) return scoreB - scoreA;
        return aLower.localeCompare(bLower);
    }

    function compareApps(a, b) {
        const favA = Boolean(cfg && typeof cfg.isAppFavorite === "function" && cfg.isAppFavorite(getAppKey(a)));
        const favB = Boolean(cfg && typeof cfg.isAppFavorite === "function" && cfg.isAppFavorite(getAppKey(b)));
        if (favA !== favB) return favA ? -1 : 1;

        const an = String(a.name || "").toLowerCase();
        const bn = String(b.name || "").toLowerCase();

        if (q !== "") {
            const aStarts = an.startsWith(q);
            const bStarts = bn.startsWith(q);
            if (aStarts !== bStarts) return aStarts ? -1 : 1;
        }

        return compareBySortMode(a, b, an, bn);
    }

    if (q === "") {
        return visible.sort(compareApps);
    }

    return visible.filter(d =>
        (d.name && d.name.toLowerCase().includes(q)) ||
        (matchGen && d.genericName && d.genericName.toLowerCase().includes(q)) ||
        (matchKw && d.keywords && d.keywords.some(k => k.toLowerCase().includes(q))) ||
        (matchCat && d.categories && d.categories.some(c => c.toLowerCase().includes(q)))
    ).sort(compareApps);
}
