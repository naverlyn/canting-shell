.pragma library

function clamp(val, min, max) {
    return Math.max(min, Math.min(max, val));
}

function parsePercent(str) {
    if (!str) return 0;
    const val = parseInt(str.toString().replace("%", "").trim());
    return isNaN(val) ? 0 : clamp(val, 0, 100);
}
