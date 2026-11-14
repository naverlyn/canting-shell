.pragma library

const _TOKEN_MAP = {
    "$accent": "accentPrimary",
    "$accentPrimary": "accentPrimary",
    "$mauve": "accentPrimary",
    "$pink": "accentPrimary",
    "$color5": "accentPrimary",
    "$color13": "accentPrimary",

    "$blue": "accentCyan",
    "$cyan": "accentCyan",
    "$sapphire": "accentCyan",
    "$sky": "accentCyan",
    "$lavender": "accentCyan",
    "$color4": "accentCyan",
    "$color6": "accentCyan",
    "$color12": "accentCyan",

    "$green": "accentGreen",
    "$teal": "accentGreen",
    "$color2": "accentGreen",
    "$color14": "accentGreen",

    "$yellow": "accentOrange",
    "$orange": "accentOrange",
    "$peach": "accentOrange",
    "$color3": "accentOrange",
    "$color11": "accentOrange",

    "$red": "accentRed",
    "$maroon": "accentRed",
    "$flamingo": "accentRed",
    "$color1": "accentRed",
    "$color9": "accentRed",

    "$text": "textPrimary",
    "$rosewater": "textPrimary",
    "$color15": "textPrimary",
    "$foreground": "textPrimary",

    "$secondary": "textSecondary",
    "$subtext1": "textSecondary",
    "$color10": "textSecondary",
    "$color7": "textSecondary",

    "$muted": "textMuted",
    "$subtext0": "textMuted",
    "$overlay2": "textMuted",
    "$color8": "textMuted",

    "$surface2": "bgSelected",
    "$overlay1": "bgSelected",
    "$surface1": "bgHover",
    "$overlay0": "bgHover",
    "$surface0": "bgSurface",
    "$color0": "bgSurface",
    "$base": "bgBase",
    "$mantle": "bgBase",
    "$crust": "bgBase",
    "$background": "bgBase"
};

function withAlpha(col, alpha) {
    if (!col) return Qt.rgba(0, 0, 0, alpha);
    const c = Qt.color(col);
    return Qt.rgba(c.r, c.g, c.b, alpha);
}

function resolveColorToken(theme, colStr, fallbackColor) {
    const fb = fallbackColor !== undefined ? fallbackColor : (theme ? theme.accentPrimary : "#ffffff");
    if (!colStr) return fb;
    const str = String(colStr).trim();
    if (!str) return fb;
    if (str.charAt(0) === "#") return str;
    if (str.indexOf("rgb(") === 0 || str.indexOf("rgba(") === 0) {
        const hexMatch = str.match(/rgba?\(\s*([0-9a-fA-F]{6})\s*\)/);
        if (hexMatch) return "#" + hexMatch[1];
        const rgbMatch = str.match(/rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/);
        if (rgbMatch) {
            return Qt.rgba(parseInt(rgbMatch[1]) / 255, parseInt(rgbMatch[2]) / 255, parseInt(rgbMatch[3]) / 255, 1);
        }
    }
    const prop = _TOKEN_MAP[str];
    if (prop && theme && theme[prop] !== undefined) {
        return theme[prop];
    }
    return fb;
}

function resolveThemeSpec(theme, spec, fallbackColor) {
    const defaultFallback = fallbackColor !== undefined ? fallbackColor : (theme ? theme.bgBase : "#000000");
    if (!spec || String(spec).trim() === "") return defaultFallback;
    const s = String(spec).trim();
    try {
        if (s.indexOf("theme:") === 0) {
            const parts = s.split(":");
            if (parts.length >= 3) {
                const tName = parts.slice(1, parts.length - 1).join(":");
                const roleKey = parts[parts.length - 1];
                const tList = (theme && theme.themes) ? theme.themes : [];
                for (let i = 0; i < tList.length; i++) {
                    if (tList[i] && tList[i].name === tName && tList[i][roleKey]) {
                        return Qt.color(String(tList[i][roleKey]));
                    }
                }
            }
        }
        if (theme && theme[s] !== undefined && typeof theme[s] !== "function") {
            return theme[s];
        }
        if (theme && theme.current && theme.current[s]) {
            return Qt.color(String(theme.current[s]));
        }
        if (s.charAt(0) === "#") return Qt.color(s);
    } catch (e) {}
    return defaultFallback;
}
