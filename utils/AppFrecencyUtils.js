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
