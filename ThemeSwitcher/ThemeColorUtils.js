.pragma library

function isLightColor(hex) {
    var s = hex.toString().replace("#", "");
    var r = parseInt(s.substr(0, 2), 16);
    var g = parseInt(s.substr(2, 2), 16);
    var b = parseInt(s.substr(4, 2), 16);
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.5;
}

function hexToHsl(hex) {
    var s = String(hex || "#7aa2f7").replace("#", "");
    if (s.length !== 6) return { h: 220 / 360, s: 0.6, l: 0.65 };
    var r = parseInt(s.substr(0, 2), 16) / 255.0;
    var g = parseInt(s.substr(2, 2), 16) / 255.0;
    var b = parseInt(s.substr(4, 2), 16) / 255.0;
    var max = Math.max(r, g, b), min = Math.min(r, g, b);
    var h = 0, sat = 0, l = (max + min) / 2.0;
    if (max !== min) {
        var d = max - min;
        sat = l > 0.5 ? d / (2.0 - max - min) : d / (max + min);
        switch (max) {
        case r: h = (g - b) / d + (g < b ? 6.0 : 0.0); break;
        case g: h = (b - r) / d + 2.0; break;
        case b: h = (r - g) / d + 4.0; break;
        }
        h /= 6.0;
    }
    return { h: h, s: sat, l: l };
}

function hslToHex(h, l, s) {
    h = ((h % 1.0) + 1.0) % 1.0;
    l = Math.max(0.0, Math.min(1.0, l));
    s = Math.max(0.0, Math.min(1.0, s));
    var r, g, b;
    if (s === 0) {
        r = g = b = l;
    } else {
        var hue2rgb = function(p, q, t) {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1/6) return p + (q - p) * 6 * t;
            if (t < 1/2) return q;
            if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
            return p;
        };
        var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        var p = 2 * l - q;
        r = hue2rgb(p, q, h + 1/3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1/3);
    }
    var toHex = function(x) {
        var v = Math.max(0, Math.min(255, Math.round(x * 255))).toString(16);
        return v.length === 1 ? "0" + v : v;
    };
    return "#" + toHex(r) + toHex(g) + toHex(b);
}

function adjustAccentForMode(hex, toLight) {
    var hsl = hexToHsl(hex);
    var targetL = toLight ? Math.max(0.40, Math.min(0.48, hsl.l - 0.20)) : Math.max(0.65, Math.min(0.72, hsl.l + 0.20));
    var targetS = toLight ? Math.min(0.72, Math.max(0.55, hsl.s)) : Math.min(0.66, Math.max(0.52, hsl.s));
    return hslToHex(hsl.h, targetL, targetS);
}

function transformWallpaperPalette(pal, toDark) {
    var isLight = !toDark;
    var primHsl = hexToHsl(pal && pal.accentPrimary ? pal.accentPrimary : "#7aa2f7");
    var h = primHsl.h;
    return {
        name: (pal && pal.name) ? pal.name : "Wallpaper",
        family: (pal && pal.family) ? pal.family : "Dynamic",
        bgBase:        isLight ? hslToHex(h, 0.94, 0.18) : hslToHex(h, 0.08, 0.07),
        bgSurface:     isLight ? hslToHex(h, 0.88, 0.16) : hslToHex(h, 0.13, 0.07),
        bgHover:       isLight ? hslToHex(h, 0.83, 0.18) : hslToHex(h, 0.18, 0.08),
        bgSelected:    isLight ? hslToHex(h, 0.78, 0.20) : hslToHex(h, 0.23, 0.09),
        bgBorder:      isLight ? hslToHex(h, 0.74, 0.14) : hslToHex(h, 0.19, 0.05),
        textPrimary:   isLight ? hslToHex(h, 0.16, 0.22) : hslToHex(h, 0.92, 0.04),
        textSecondary: isLight ? hslToHex(h, 0.34, 0.18) : hslToHex(h, 0.72, 0.05),
        textMuted:     isLight ? hslToHex(h, 0.50, 0.14) : hslToHex(h, 0.48, 0.06),
        accentPrimary: adjustAccentForMode(pal.accentPrimary, isLight),
        accentCyan:    adjustAccentForMode(pal.accentCyan, isLight),
        accentGreen:   adjustAccentForMode(pal.accentGreen, isLight),
        accentOrange:  adjustAccentForMode(pal.accentOrange, isLight),
        accentRed:     adjustAccentForMode(pal.accentRed, isLight)
    };
}

function normalizeHex(hex) {
    if (hex === undefined || hex === null) return "";
    var s = String(hex).trim().replace(/^#+/, "");
    if (!/^[0-9a-fA-F]{6}$/.test(s)) return "";
    return "#" + s.toLowerCase();
}

function isValidHex(hex) {
    return normalizeHex(hex) !== "";
}

function relativeLuminance(hex) {
    var norm = normalizeHex(hex);
    if (!norm) return 0;
    var s = norm.slice(1);
    var toLinear = function(c) {
        var v = parseInt(c, 16) / 255.0;
        return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    };
    return 0.2126 * toLinear(s.substr(0, 2)) +
           0.7152 * toLinear(s.substr(2, 2)) +
           0.0722 * toLinear(s.substr(4, 2));
}

function contrastRatio(hex1, hex2) {
    var l1 = relativeLuminance(hex1);
    var l2 = relativeLuminance(hex2);
    var lighter = Math.max(l1, l2);
    var darker = Math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
}

function validateThemePalette(t) {
    if (!t) {
        return { valid: false, invalidKeys: ["palette"], lowContrast: [], minContrast: 0, summary: "Missing palette" };
    }
    var keys = [
        "bgBase", "bgSurface", "bgHover", "bgSelected", "bgBorder",
        "textPrimary", "textSecondary", "textMuted",
        "accentPrimary", "accentCyan", "accentGreen", "accentOrange", "accentRed"
    ];
    var invalidKeys = [];
    for (var i = 0; i < keys.length; i++) {
        if (!isValidHex(t[keys[i]])) invalidKeys.push(keys[i]);
    }
    var pairs = [
        { fg: "textPrimary",   bg: "bgBase",    min: 4.5, label: "textPrimary / bgBase" },
        { fg: "textPrimary",   bg: "bgSurface", min: 4.5, label: "textPrimary / bgSurface" },
        { fg: "textSecondary", bg: "bgSurface", min: 3.0, label: "textSecondary / bgSurface" },
        { fg: "accentPrimary", bg: "bgSurface", min: 3.0, label: "accentPrimary / bgSurface" }
    ];
    var lowContrast = [];
    var minRatio = 21.0;
    for (var j = 0; j < pairs.length; j++) {
        var p = pairs[j];
        if (!isValidHex(t[p.fg]) || !isValidHex(t[p.bg])) continue;
        var ratio = contrastRatio(t[p.fg], t[p.bg]);
        if (ratio < minRatio) minRatio = ratio;
        if (ratio < p.min) {
            lowContrast.push({ label: p.label, ratio: Math.round(ratio * 10) / 10, required: p.min });
        }
    }
    var textRatio = (isValidHex(t.textPrimary) && isValidHex(t.bgBase))
        ? Math.round(contrastRatio(t.textPrimary, t.bgBase) * 10) / 10
        : 0;
    var valid = invalidKeys.length === 0 && lowContrast.length === 0;
    var summary = invalidKeys.length > 0
        ? ("Invalid hex: " + invalidKeys.join(", "))
        : (lowContrast.length > 0
            ? ("Low contrast: " + lowContrast[0].label + " (" + lowContrast[0].ratio + ":1)")
            : ("WCAG AA (" + textRatio + ":1)"));
    return {
        valid: valid,
        invalidKeys: invalidKeys,
        lowContrast: lowContrast,
        textContrast: textRatio,
        minContrast: Math.round(minRatio * 10) / 10,
        summary: summary
    };
}

function hexToRgba(hex) {
    var clean = stripHex(hex);
    return "rgba(" + clean + "ff)";
}

function stripHex(hex) {
    var norm = normalizeHex(hex);
    return norm ? norm.slice(1) : "000000";
}

function buildHyprlockConf(t, accentPrimary) {
    var pHex   = stripHex(accentPrimary);
    var cHex   = stripHex(t.accentCyan);
    var gHex   = stripHex(t.accentGreen);
    var oHex   = stripHex(t.accentOrange);
    var rHex   = stripHex(t.accentRed);
    var bgBase = stripHex(t.bgBase);
    var bgSurf = stripHex(t.bgSurface);
    var bgHov  = stripHex(t.bgHover);
    var bgSel  = stripHex(t.bgSelected);
    var txtPri = stripHex(t.textPrimary);
    var txtSec = stripHex(t.textSecondary);
    var txtMut = stripHex(t.textMuted);

    var tokens = [
        ["background", bgBase, false],
        ["foreground", txtPri, false],
        ["color0", bgSurf, false], ["color1", rHex, false], ["color2", gHex, false],
        ["color3", oHex, false], ["color4", cHex, false], ["color5", pHex, false],
        ["color6", cHex, false], ["color7", txtSec, false], ["color8", txtMut, false],
        ["color9", rHex, false], ["color10", txtSec, false], ["color11", oHex, false],
        ["color12", cHex, false], ["color13", pHex, false], ["color14", gHex, false],
        ["color15", txtPri, false],
        ["accent", pHex, true], ["accentPrimary", pHex, false],
        ["mauve", pHex, true], ["blue", cHex, true], ["sapphire", cHex, true],
        ["sky", cHex, true], ["teal", gHex, true], ["green", gHex, true],
        ["yellow", oHex, true], ["peach", oHex, true], ["maroon", rHex, true],
        ["red", rHex, true], ["pink", pHex, true], ["flamingo", rHex, true],
        ["rosewater", txtPri, true], ["lavender", cHex, true],
        ["text", txtPri, true], ["subtext1", txtSec, true], ["subtext0", txtMut, true],
        ["overlay2", txtMut, true], ["overlay1", bgSel, true], ["overlay0", bgHov, true],
        ["surface2", bgSel, true], ["surface1", bgHov, true], ["surface0", bgSurf, true],
        ["base", bgBase, true], ["mantle", bgBase, true], ["crust", bgBase, true]
    ];

    var lines = ["# Dynamic Hyprlock palette generated from active Quickshell / Wallust theme"];
    for (var i = 0; i < tokens.length; i++) {
        var name = tokens[i][0];
        var val = tokens[i][1];
        lines.push("$" + name + " = rgb(" + val + ")");
        if (tokens[i][2]) lines.push("$" + name + "Alpha = " + val);
    }
    return lines.join("\n");
}

function buildKittyColors(t, accentPrimary) {
    var accent = accentPrimary;
    var pairs = [
        ["foreground", t.textPrimary],
        ["background", t.bgBase],
        ["cursor", accent],
        ["cursor_text_color", t.bgBase],
        ["selection_foreground", t.textPrimary],
        ["selection_background", t.bgSelected],
        ["active_tab_foreground", t.textPrimary],
        ["active_tab_background", t.bgSurface],
        ["inactive_tab_foreground", t.textMuted],
        ["inactive_tab_background", t.bgBase],
        ["color0", t.bgSurface],
        ["color1", t.accentRed],
        ["color2", t.accentGreen],
        ["color3", t.accentOrange],
        ["color4", accent],
        ["color5", accent],
        ["color6", t.accentCyan],
        ["color7", t.textSecondary],
        ["color8", t.textMuted],
        ["color9", t.accentRed],
        ["color10", t.accentGreen],
        ["color11", t.accentOrange],
        ["color12", accent],
        ["color13", accent],
        ["color14", t.accentCyan],
        ["color15", t.textPrimary]
    ];
    return {
        conf: pairs.map(function(p) { return p[0] + " " + p[1]; }).join("\n"),
        args: pairs.map(function(p) { return p[0] + "=" + p[1]; }).join(" ")
    };
}
