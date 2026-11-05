pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int currentIndex: 0
    property int previewIndex: -1
    property bool wallpaperFeatureEnabled: true
    property bool wallpaperMode: false
    property var wallpaperTheme: ({})
    property string configFormat: "conf" // "conf" or "lua" - which hyprland.* is active
    property bool configFormatReady: false
    property bool themesReady: false

    function tryLoadTheme() {
        if (root.configFormatReady && root.themesReady)
            loadProc.running = true;
    }
    Timer {
        id: kittyDebounceTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (root.previewIndex >= 0 && root.previewIndex < root.themes.length) {
                root.applyKittyTheme(root.themes[root.previewIndex]);
            } else {
                root.applyKittyTheme(root.current);
            }
        }
    }

    onPreviewIndexChanged: {
        kittyDebounceTimer.restart();
    }
    readonly property var current: {
        if (previewIndex >= 0 && previewIndex < themes.length)
            return themes[previewIndex];
        if (wallpaperMode && wallpaperTheme && wallpaperTheme.bgBase)
            return wallpaperTheme;
        return themes[currentIndex];
    }
    readonly property int count: themes.length
    readonly property string currentName: current.name
    readonly property string currentFamily: current.family
    readonly property bool isDark: !isLightColor(current.bgBase)

    function isLightColor(hex) {
        hex = hex.toString().replace("#", "");
        var r = parseInt(hex.substr(0, 2), 16);
        var g = parseInt(hex.substr(2, 2), 16);
        var b = parseInt(hex.substr(4, 2), 16);
        return (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.5;
    }

    function applySystemColorScheme(dark) {
        var scheme = dark ? "prefer-dark" : "prefer-light";
        var modeStr = dark ? "Dark" : "Light";
        colorSchemeProc.command = ["sh", "-c",
            'mkdir -p "$HOME/.cache" && printf "%s\\n" "$1" > "$HOME/.cache/.theme_mode"; ' +
            'gsettings set org.gnome.desktop.interface color-scheme "$2" 2>/dev/null || true',
            "sh", modeStr, scheme
        ];
        colorSchemeProc.running = true;
    }

    property int lastDarkIndex: -1
    property int lastLightIndex: -1

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

    function findCounterpartThemeIndex(targetDark) {
        var cur = root.themes[root.currentIndex];
        var curFam = cur ? (cur.family || "") : "";
        var curName = cur ? (cur.name || "") : "";

        // 1. Direct name pair in same family (e.g., "WhatsApp Dark" <-> "WhatsApp Light", "Dark" <-> "Light")
        var swappedName = targetDark
            ? curName.replace(/Light/i, "Dark").replace(/^Latte$/i, "Mocha").replace(/^9009$/, "8008")
            : curName.replace(/Dark/i, "Light").replace(/^(Mocha|Macchiato|Frappe)$/i, "Latte").replace(/^(Night|Storm|Moon)$/i, "Light").replace(/^8008$/, "9009");

        if (swappedName !== curName) {
            for (var i = 0; i < root.themes.length; i++) {
                var t = root.themes[i];
                if (t.family === curFam && t.name.toLowerCase() === swappedName.toLowerCase() && (!root.isLightColor(t.bgBase) === targetDark)) {
                    return i;
                }
            }
        }

        // 2. Previously used theme of target darkness in the same family
        var prevIdx = targetDark ? root.lastDarkIndex : root.lastLightIndex;
        if (prevIdx >= 0 && prevIdx < root.themes.length) {
            var prevT = root.themes[prevIdx];
            if (prevT && prevT.family === curFam && (!root.isLightColor(prevT.bgBase) === targetDark)) {
                return prevIdx;
            }
        }

        // 3. Any theme in the same family matching target darkness
        for (var j = 0; j < root.themes.length; j++) {
            var famT = root.themes[j];
            if (famT.family === curFam && (!root.isLightColor(famT.bgBase) === targetDark)) {
                return j;
            }
        }

        // 4. Previously used theme of target darkness across any family
        if (prevIdx >= 0 && prevIdx < root.themes.length) {
            var anyPrevT = root.themes[prevIdx];
            if (anyPrevT && (!root.isLightColor(anyPrevT.bgBase) === targetDark)) {
                return prevIdx;
            }
        }

        // 5. Fallback to first matching theme in list
        for (var k = 0; k < root.themes.length; k++) {
            if (!root.isLightColor(root.themes[k].bgBase) === targetDark) {
                return k;
            }
        }
        return 0;
    }

    function toggleDarkLight() {
        var targetDark = !root.isDark;
        root.previewIndex = -1;
        root.previewAccent = "";

        if (root.wallpaperMode && root.wallpaperTheme && root.wallpaperTheme.bgBase) {
            var nextPal = root.transformWallpaperPalette(root.wallpaperTheme, targetDark);
            root.wallpaperTheme = nextPal;
            root.applyTheme(nextPal);
            var harmonizePy = Qt.resolvedUrl("wallpaper-theme/harmonize_palette.py").toString().replace(/^file:\/\//, "");
            var wpJson = Qt.resolvedUrl("wallpaper-theme.json").toString().replace(/^file:\/\//, "");
            var modeArg = targetDark ? "dark" : "light";
            var modeStr = targetDark ? "Dark" : "Light";
            harmonizeModeProc.command = ["sh", "-c",
                'mkdir -p "$HOME/.cache" && printf "%s\\n" "$1" > "$HOME/.cache/.theme_mode"; ' +
                'python3 "$2" "$3" --mode "$4" 2>/dev/null || true',
                "sh", modeStr, harmonizePy, wpJson, modeArg
            ];
            harmonizeModeProc.running = true;
            return;
        }

        var nextIdx = root.findCounterpartThemeIndex(targetDark);
        root.setTheme(nextIdx);
    }

    // Reactive color properties - same API as before
    readonly property color bgBase:       current.bgBase
    readonly property color bgSurface:    current.bgSurface
    readonly property color bgHover:      current.bgHover
    readonly property color bgSelected:   current.bgSelected
    readonly property color bgBorder:     current.bgBorder
    readonly property color bgOverlay:    "#88000000"

    readonly property color textPrimary:   current.textPrimary
    readonly property color textSecondary: current.textSecondary
    readonly property color textMuted:     current.textMuted

    property string previewAccent: ""
    property string customAccent: ""

    onCurrentIndexChanged: {
        customAccent = "";
        previewAccent = "";
        if (currentIndex >= 0 && currentIndex < themes.length && themes[currentIndex]) {
            if (isLightColor(themes[currentIndex].bgBase)) {
                lastLightIndex = currentIndex;
            } else {
                lastDarkIndex = currentIndex;
            }
        }
    }

    readonly property color accentPrimary: {
        if (previewAccent !== "") return previewAccent;
        if (previewIndex < 0 && customAccent !== "") return customAccent;
        return current.accentPrimary;
    }
    readonly property color accentCyan:    current.accentCyan
    readonly property color accentGreen:   current.accentGreen
    readonly property color accentOrange:  current.accentOrange
    readonly property color accentRed:     current.accentRed

    function setAccent(colorStr) {
        if (customAccent === colorStr) {
            customAccent = "";
        } else {
            customAccent = colorStr;
        }
        applyHyprlandBorders(current);
        applyHyprlockTheme(current);
    }

    // Semantic aliases
    readonly property color urgencyLow:      textMuted
    readonly property color urgencyNormal:   accentPrimary
    readonly property color urgencyCritical: accentRed
    readonly property color batteryGood:     accentGreen
    readonly property color batteryWarning:  accentOrange
    readonly property color batteryCritical: accentRed

    function hexToRgba(hex) {
        return "rgba(" + hex.toString().replace("#", "") + "ff)";
    }

    function stripHex(hex) {
        return hex.toString().replace("#", "").toLowerCase();
    }

    function applyHyprlockTheme(t) {
        if (!t || !t.bgBase) return;
        var pHex   = stripHex(root.accentPrimary);
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

        var hyprlockConf = [
            "# Dynamic Hyprlock palette generated from active Quickshell / Wallust theme",
            "$background = rgb(" + bgBase + ")",
            "$foreground = rgb(" + txtPri + ")",
            "$color0 = rgb(" + bgSurf + ")",
            "$color1 = rgb(" + rHex + ")",
            "$color2 = rgb(" + gHex + ")",
            "$color3 = rgb(" + oHex + ")",
            "$color4 = rgb(" + cHex + ")",
            "$color5 = rgb(" + pHex + ")",
            "$color6 = rgb(" + cHex + ")",
            "$color7 = rgb(" + txtSec + ")",
            "$color8 = rgb(" + txtMut + ")",
            "$color9 = rgb(" + rHex + ")",
            "$color10 = rgb(" + txtSec + ")",
            "$color11 = rgb(" + oHex + ")",
            "$color12 = rgb(" + cHex + ")",
            "$color13 = rgb(" + pHex + ")",
            "$color14 = rgb(" + gHex + ")",
            "$color15 = rgb(" + txtPri + ")",
            "$accent = rgb(" + pHex + ")",
            "$accentAlpha = " + pHex,
            "$accentPrimary = rgb(" + pHex + ")",
            "$mauve = rgb(" + pHex + ")",
            "$mauveAlpha = " + pHex,
            "$blue = rgb(" + cHex + ")",
            "$blueAlpha = " + cHex,
            "$sapphire = rgb(" + cHex + ")",
            "$sapphireAlpha = " + cHex,
            "$sky = rgb(" + cHex + ")",
            "$skyAlpha = " + cHex,
            "$teal = rgb(" + gHex + ")",
            "$tealAlpha = " + gHex,
            "$green = rgb(" + gHex + ")",
            "$greenAlpha = " + gHex,
            "$yellow = rgb(" + oHex + ")",
            "$yellowAlpha = " + oHex,
            "$peach = rgb(" + oHex + ")",
            "$peachAlpha = " + oHex,
            "$maroon = rgb(" + rHex + ")",
            "$maroonAlpha = " + rHex,
            "$red = rgb(" + rHex + ")",
            "$redAlpha = " + rHex,
            "$pink = rgb(" + pHex + ")",
            "$pinkAlpha = " + pHex,
            "$flamingo = rgb(" + rHex + ")",
            "$flamingoAlpha = " + rHex,
            "$rosewater = rgb(" + txtPri + ")",
            "$rosewaterAlpha = " + txtPri,
            "$lavender = rgb(" + cHex + ")",
            "$lavenderAlpha = " + cHex,
            "$text = rgb(" + txtPri + ")",
            "$textAlpha = " + txtPri,
            "$subtext1 = rgb(" + txtSec + ")",
            "$subtext1Alpha = " + txtSec,
            "$subtext0 = rgb(" + txtMut + ")",
            "$subtext0Alpha = " + txtMut,
            "$overlay2 = rgb(" + txtMut + ")",
            "$overlay2Alpha = " + txtMut,
            "$overlay1 = rgb(" + bgSel + ")",
            "$overlay1Alpha = " + bgSel,
            "$overlay0 = rgb(" + bgHov + ")",
            "$overlay0Alpha = " + bgHov,
            "$surface2 = rgb(" + bgSel + ")",
            "$surface2Alpha = " + bgSel,
            "$surface1 = rgb(" + bgHov + ")",
            "$surface1Alpha = " + bgHov,
            "$surface0 = rgb(" + bgSurf + ")",
            "$surface0Alpha = " + bgSurf,
            "$base = rgb(" + bgBase + ")",
            "$baseAlpha = " + bgBase,
            "$mantle = rgb(" + bgBase + ")",
            "$mantleAlpha = " + bgBase,
            "$crust = rgb(" + bgBase + ")",
            "$crustAlpha = " + bgBase
        ].join("\n");

        hyprlockThemeProc.command = ["sh", "-c",
            "mkdir -p \"$HOME/.config/hypr/wallust\" && " +
            "printf '%s\\n' '" + hyprlockConf + "' > \"$HOME/.config/quickshell/Settings/scripts/wallust-hyprlock.conf\" && " +
            "cp -f \"$HOME/.config/quickshell/Settings/scripts/wallust-hyprlock.conf\" \"$HOME/.config/hypr/wallust/wallust-hyprland.conf\" 2>/dev/null || true; " +
            "if [ -f \"$HOME/.config/hypr/hyprlock.conf\" ]; then " +
            "  sed -i 's|^source = .*mocha\\.conf|source = $HOME/.config/quickshell/Settings/scripts/wallust-hyprlock.conf|' \"$HOME/.config/hypr/hyprlock.conf\" 2>/dev/null || true; " +
            "  sed -i 's|^source = .*/wallust/wallust-hyprland\\.conf|source = $HOME/.config/quickshell/Settings/scripts/wallust-hyprlock.conf|' \"$HOME/.config/hypr/hyprlock.conf\" 2>/dev/null || true; " +
            "fi"
        ];
        hyprlockThemeProc.running = true;
    }

    function applyHyprlandBorders(t) {
        var activeColor1 = hexToRgba(root.accentPrimary);
        var activeColor2 = hexToRgba(t.accentCyan);
        var angle = 45;
        var active = activeColor1 + " " + activeColor2 + " " + angle + "deg";
        var inactive = hexToRgba(t.bgBorder);
        var checkCustom = '! grep -q "custom_border = true" "$HOME/.config/hypr/theme-borders.lua" "$HOME/.config/hypr/theme-borders.conf" 2>/dev/null';
        var writeCmd = root.configFormat === "lua"
            ? "printf '%s\\n' '-- theme_sync = true' 'hl.config({' '    general = {' '        [\"col.active_border\"] = { colors = { \"" + activeColor1 + "\", \"" + activeColor2 + "\" }, angle = " + angle + " },' '        [\"col.inactive_border\"] = \"" + inactive + "\",' '    },' '})' > \"$HOME/.config/hypr/theme-borders.lua\""
            : 'printf "%s\\n" "# theme_sync = true" "general {" "    col.active_border = ' + active + '" "    col.inactive_border = ' + inactive + '" "}" > "$HOME/.config/hypr/theme-borders.conf"';
        var applyCmd = root.configFormat === "lua"
            ? 'hyprctl eval \'dofile(os.getenv("HOME") .. "/.config/hypr/theme-borders.lua")\''
            : 'hyprctl keyword general:col.active_border "' + active + '" && hyprctl keyword general:col.inactive_border "' + inactive + '"';

        var ensureSource = root.configFormat === "lua"
            ? '[ -f "$HOME/.config/hypr/hyprland.lua" ] && ! grep -q "theme-borders" "$HOME/.config/hypr/hyprland.lua" 2>/dev/null && printf "\\npcall(require, \\"theme-borders\\")\\n" >> "$HOME/.config/hypr/hyprland.lua" || true'
            : '[ -f "$HOME/.config/hypr/hyprland.conf" ] && ! grep -q "theme-borders" "$HOME/.config/hypr/hyprland.conf" 2>/dev/null && printf "\\nsource = ~/.config/hypr/theme-borders.conf\\n" >> "$HOME/.config/hypr/hyprland.conf" || true';
        hyprlandProc.command = ["sh", "-c",
            checkCustom + ' && { ' +
            writeCmd + ' && ' +
            applyCmd + ' ; ' +
            ensureSource + ' ; } || true'
        ];
        hyprlandProc.running = true;
    }

    function applyTheme(t) {
        applyKittyTheme(t);
        applySystemColorScheme(!isLightColor(t.bgBase));
        applyHyprlandBorders(t);
        applyHyprlockTheme(t);
    }

    readonly property string themeConfPath: Qt.resolvedUrl("../theme.conf").toString().replace(/^file:\/\//, "")

    function setTheme(index) {
        if (index >= 0 && index < themes.length) {
            wallpaperMode = false;
            customAccent = "";
            previewAccent = "";
            currentIndex = index;
            saveProc.command = ["sh", "-c", 'printf "%s" "$1" > "$2"', "sh", String(index), root.themeConfPath];
            saveProc.running = true;
            applyTheme(themes[index]);
        }
    }

    function setWallpaperMode() {
        if (!wallpaperFeatureEnabled)
            return;
        wallpaperMode = true;
        customAccent = "";
        previewAccent = "";
        saveProc.command = ["sh", "-c", 'printf "%s" wallpaper > "$1"', "sh", root.themeConfPath];
        saveProc.running = true;
        if (wallpaperTheme && wallpaperTheme.bgBase)
            applyTheme(wallpaperTheme);
    }

    // Regenerate the wallpaper palette from a given image, then switch to wallpaper
    // mode. set.sh writes wallpaper-theme.json, which the FileView below live-reloads
    // and applies. Without an image this is equivalent to setWallpaperMode().
    function setWallpaperFromImage(img) {
        if (!wallpaperFeatureEnabled)
            return;
        if (img && img.length > 0) {
            generateProc.command = ["sh", Qt.resolvedUrl("wallpaper-theme/set.sh").toString().replace(/^file:\/\//, ""), img];
            generateProc.running = true;
        }
        setWallpaperMode();
    }

    function applyKittyTheme(t) {
        var accent = root.accentPrimary;
        var colorsConf = [
            "foreground " + t.textPrimary,
            "background " + t.bgBase,
            "cursor " + accent,
            "cursor_text_color " + t.bgBase,
            "selection_foreground " + t.textPrimary,
            "selection_background " + t.bgSelected,
            "active_tab_foreground " + t.textPrimary,
            "active_tab_background " + t.bgSurface,
            "inactive_tab_foreground " + t.textMuted,
            "inactive_tab_background " + t.bgBase,
            "color0 " + t.bgSurface,
            "color1 " + t.accentRed,
            "color2 " + t.accentGreen,
            "color3 " + t.accentOrange,
            "color4 " + accent,
            "color5 " + accent,
            "color6 " + t.accentCyan,
            "color7 " + t.textSecondary,
            "color8 " + t.textMuted,
            "color9 " + t.accentRed,
            "color10 " + t.accentGreen,
            "color11 " + t.accentOrange,
            "color12 " + accent,
            "color13 " + accent,
            "color14 " + t.accentCyan,
            "color15 " + t.textPrimary
        ].join("\n");
        var colorsArgs = [
            "foreground=" + t.textPrimary,
            "background=" + t.bgBase,
            "cursor=" + accent,
            "cursor_text_color=" + t.bgBase,
            "selection_foreground=" + t.textPrimary,
            "selection_background=" + t.bgSelected,
            "active_tab_foreground=" + t.textPrimary,
            "active_tab_background=" + t.bgSurface,
            "inactive_tab_foreground=" + t.textMuted,
            "inactive_tab_background=" + t.bgBase,
            "color0=" + t.bgSurface,
            "color1=" + t.accentRed,
            "color2=" + t.accentGreen,
            "color3=" + t.accentOrange,
            "color4=" + accent,
            "color5=" + accent,
            "color6=" + t.accentCyan,
            "color7=" + t.textSecondary,
            "color8=" + t.textMuted,
            "color9=" + t.accentRed,
            "color10=" + t.accentGreen,
            "color11=" + t.accentOrange,
            "color12=" + accent,
            "color13=" + accent,
            "color14=" + t.accentCyan,
            "color15=" + t.textPrimary
        ].join(" ");
        kittyProc.command = ["sh", "-c",
            "printf '%s\\n' '" + colorsConf + "' > $HOME/.config/kitty/theme-colors.conf; " +
            "for sock in /tmp/kitty-*; do " +
            "[ -S \"$sock\" ] && kitty @ --to \"unix:$sock\" set-colors --all --configured " + colorsArgs + "; " +
            "done"
        ];
        kittyProc.running = true;
    }

    Process { id: saveProc; running: false }
    Process { id: generateProc; running: false }
    Process { id: harmonizeModeProc; running: false }
    Process { id: kittyProc; running: false }
    Process { id: colorSchemeProc; running: false }
    Process { id: hyprlandProc; running: false }
    Process { id: hyprlockThemeProc; running: false }

    // Which hyprland.* is active - hyprland.lua wins exclusively if present, per
    // Hyprland's own startup precedence (see monitor-manager/MonitorService.qml for the twin check).
    Process {
        id: configFormatCheck
        command: ["sh", "-c",
            "[ -f \"$HOME/.config/hypr/hyprland.lua\" ] && echo lua || echo conf"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.configFormat = text.trim() === "lua" ? "lua" : "conf";
                root.configFormatReady = true;
                root.tryLoadTheme();
            }
        }
    }

    Process {
        id: loadProc
        command: ["sh", "-c", 'cat "$1" 2>/dev/null', "sh", root.themeConfPath]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                if (raw === "wallpaper" && root.wallpaperFeatureEnabled) {
                    root.wallpaperMode = true;
                    if (root.wallpaperTheme && root.wallpaperTheme.bgBase)
                        root.applyTheme(root.wallpaperTheme);
                    else
                        // wallpaper-theme.json missing/empty yet - show a visible
                        // default until a wallpaper hook regenerates it (the FileView
                        // re-applies once wallpaperTheme populates).
                        root.applyTheme(root.themes[0]);
                    return;
                }
                const idx = parseInt(raw);
                if (!isNaN(idx) && idx >= 0 && idx < root.themes.length) {
                    root.wallpaperMode = false;
                    root.currentIndex = idx;
                    root.applyTheme(root.themes[idx]);
                } else if (raw === "wallpaper") {
                    // Persisted wallpaper choice but the feature is disabled -
                    // fall back to the curated default.
                    root.wallpaperMode = false;
                    root.applyTheme(root.themes[root.currentIndex]);
                }
            }
        }
    }

    // Live-reloads the wallpaper-generated palette. When in wallpaper mode, a new
    // wallpaper (and a fresh wallpaper-theme.json) repaints the shell instantly.
    FileView {
        id: wallpaperThemeFile
        path: Qt.resolvedUrl("wallpaper-theme.json").toString().replace(/^file:\/\//, "")
        watchChanges: true

        // True only for live, on-disk rewrites (set.sh executed) - not the initial
        // load at startup. A fresh palette means a new wallpaper was set, so we
        // switch the switcher into wallpaper mode rather than just repainting.
        property bool liveChange: false
        onFileChanged: { liveChange = true; reload(); }

        onTextChanged: {
            const raw = wallpaperThemeFile.text();
            if (!raw) return;
            try {
                root.wallpaperTheme = JSON.parse(raw);
                if (wallpaperThemeFile.liveChange && root.wallpaperTheme.bgBase)
                    root.setWallpaperMode();
                else if (root.wallpaperMode && root.wallpaperTheme.bgBase)
                    root.applyTheme(root.wallpaperTheme);
            } catch (e) {
                console.error("Failed to parse wallpaper-theme.json:", e);
            } finally {
                wallpaperThemeFile.liveChange = false;
            }
        }
    }

    FileView {
        id: themesFile
        path: Qt.resolvedUrl("themes.json").toString().replace(/^file:\/\//, "")
        watchChanges: true
        onTextChanged: {
            const raw = themesFile.text();
            if (!raw) return;
            try {
                root.themes = JSON.parse(raw);
                root.themesReady = true;
                root.tryLoadTheme();
            } catch (e) {
                console.error("Failed to parse themes.json:", e);
            }
        }
    }

    property var themes: [
        {
            name: "Night", family: "Tokyo Night",
            bgBase: "#1a1b26", bgSurface: "#24283b", bgHover: "#1e2235",
            bgSelected: "#283457", bgBorder: "#32364a",
            textPrimary: "#c0caf5", textSecondary: "#a9b1d6", textMuted: "#565f89",
            accentPrimary: "#7aa2f7", accentCyan: "#7dcfff",
            accentGreen: "#9ece6a", accentOrange: "#ff9e64", accentRed: "#f7768e"
        }
    ]
}
