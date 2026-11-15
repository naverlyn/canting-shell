pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "ThemeColorUtils.js" as ThemeColorUtils

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

    function isLightColor(hex) { return ThemeColorUtils.isLightColor(hex); }

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

    function hexToHsl(hex) { return ThemeColorUtils.hexToHsl(hex); }
    function hslToHex(h, l, s) { return ThemeColorUtils.hslToHex(h, l, s); }
    function adjustAccentForMode(hex, toLight) { return ThemeColorUtils.adjustAccentForMode(hex, toLight); }
    function transformWallpaperPalette(pal, toDark) { return ThemeColorUtils.transformWallpaperPalette(pal, toDark); }

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

    // --- Global Typography & Font Configuration ---
    readonly property string fontsConfigPath: Qt.resolvedUrl("../configs/fonts_config.json").toString().replace(/^file:\/\//, "")
    property bool _fontsLoaded: false

    property string savedFontFamily: "Lato Nerd Font"
    property string savedMonoFont: "JetBrainsMono Nerd Font"
    property string savedLockscreenFont: "JetBrainsMono Nerd Font"
    property string previewFontFamily: ""
    property string previewMonoFont: ""
    property string previewLockscreenFont: ""

    readonly property string fontFamily: previewFontFamily !== "" ? previewFontFamily : (savedFontFamily || "Lato Nerd Font")
    readonly property string monoFont: previewMonoFont !== "" ? previewMonoFont : (savedMonoFont || "JetBrainsMono Nerd Font")
    readonly property string lockscreenFont: previewLockscreenFont !== "" ? previewLockscreenFont : (savedLockscreenFont || monoFont || "JetBrainsMono Nerd Font")

    property real fontScale: 1.0
    property string fontWeight: "normal" // "light", "normal", "medium", "demibold", "bold"
    property bool boldHeadings: true
    property real letterSpacing: 0.0
    property string fontHinting: "default" // "default", "none", "vertical", "full"
    property bool fontAntialiasing: true
    property string fontRenderType: "qt" // "qt" or "native"

    readonly property int fontWeightEnum: {
        switch (root.fontWeight) {
            case "light": return Font.Light;
            case "medium": return Font.Medium;
            case "demibold": return Font.DemiBold;
            case "bold": return Font.Bold;
            default: return Font.Normal;
        }
    }

    readonly property int fontHintingEnum: {
        switch (root.fontHinting) {
            case "none": return Font.PreferNoHinting;
            case "vertical": return Font.PreferVerticalHinting;
            case "full": return Font.PreferFullHinting;
            default: return Font.PreferDefaultHinting;
        }
    }

    readonly property int fontRenderTypeEnum: root.fontRenderType === "native" ? Text.NativeRendering : Text.QtRendering

    function scaledPx(basePx) {
        return Math.max(8, Math.round((Number(basePx) || 12) * root.fontScale));
    }

    function syncApplicationFont() {
        try {
            if (Qt.application && Qt.application.font) {
                Qt.application.font.family = root.fontFamily;
                Qt.application.font.weight = root.fontWeightEnum;
                Qt.application.font.letterSpacing = root.letterSpacing;
                Qt.application.font.hintingPreference = root.fontHintingEnum;
            }
        } catch (e) {}
    }

    onFontFamilyChanged: root.syncApplicationFont()
    onFontWeightEnumChanged: root.syncApplicationFont()
    onLetterSpacingChanged: root.syncApplicationFont()
    onFontHintingEnumChanged: root.syncApplicationFont()

    function setFontFamily(fam) {
        const clean = String(fam || "").trim();
        if (!clean) return;
        root.previewFontFamily = "";
        if (root.savedFontFamily !== clean) {
            root.savedFontFamily = clean;
            root.saveFontsConfig();
        }
    }

    function setMonoFont(fam) {
        const clean = String(fam || "").trim();
        if (!clean) return;
        root.previewMonoFont = "";
        if (root.savedMonoFont !== clean) {
            root.savedMonoFont = clean;
            root.saveFontsConfig();
        }
    }

    function setLockscreenFont(fam) {
        const clean = String(fam || "").trim();
        if (!clean) return;
        root.previewLockscreenFont = "";
        if (root.savedLockscreenFont !== clean) {
            root.savedLockscreenFont = clean;
            root.saveFontsConfig();
        }
    }

    function setFontPairing(primaryFam, monoFam, lockFam) {
        const pClean = String(primaryFam || "").trim();
        const mClean = String(monoFam || "").trim();
        const lClean = String(lockFam !== undefined ? lockFam : (monoFam || "")).trim();
        root.previewFontFamily = "";
        root.previewMonoFont = "";
        root.previewLockscreenFont = "";
        let changed = false;
        if (pClean && root.savedFontFamily !== pClean) {
            root.savedFontFamily = pClean;
            changed = true;
        }
        if (mClean && root.savedMonoFont !== mClean) {
            root.savedMonoFont = mClean;
            changed = true;
        }
        if (lClean && root.savedLockscreenFont !== lClean) {
            root.savedLockscreenFont = lClean;
            changed = true;
        }
        if (changed) root.saveFontsConfig();
    }

    function setFontScale(val) {
        const clamped = Math.round(Math.max(0.85, Math.min(1.25, Number(val) || 1.0)) * 100) / 100;
        if (Math.abs(root.fontScale - clamped) > 0.001) {
            root.fontScale = clamped;
            fontsSaveDebounce.restart();
        }
    }

    function setFontWeight(w) {
        const clean = String(w || "normal").toLowerCase();
        if (["light", "normal", "medium", "demibold", "bold"].indexOf(clean) !== -1) {
            if (root.fontWeight !== clean) {
                root.fontWeight = clean;
                root.saveFontsConfig();
            }
        }
    }

    function setBoldHeadings(val) {
        const b = Boolean(val);
        if (root.boldHeadings !== b) {
            root.boldHeadings = b;
            root.saveFontsConfig();
        }
    }

    function setLetterSpacing(val) {
        const clamped = Math.round(Math.max(-0.5, Math.min(2.0, Number(val) || 0.0)) * 10) / 10;
        if (Math.abs(root.letterSpacing - clamped) > 0.01) {
            root.letterSpacing = clamped;
            fontsSaveDebounce.restart();
        }
    }

    function setFontHinting(h) {
        const clean = String(h || "default").toLowerCase();
        if (["default", "none", "vertical", "full"].indexOf(clean) !== -1) {
            if (root.fontHinting !== clean) {
                root.fontHinting = clean;
                root.saveFontsConfig();
            }
        }
    }

    function setFontAntialiasing(val) {
        const b = Boolean(val);
        if (root.fontAntialiasing !== b) {
            root.fontAntialiasing = b;
            root.saveFontsConfig();
        }
    }

    function setFontRenderType(rt) {
        const clean = String(rt || "qt").toLowerCase() === "native" ? "native" : "qt";
        if (root.fontRenderType !== clean) {
            root.fontRenderType = clean;
            root.saveFontsConfig();
        }
    }

    function resetFontsToDefault() {
        root.previewFontFamily = "";
        root.previewMonoFont = "";
        root.previewLockscreenFont = "";
        root.savedFontFamily = "Lato Nerd Font";
        root.savedMonoFont = "JetBrainsMono Nerd Font";
        root.savedLockscreenFont = "JetBrainsMono Nerd Font";
        root.fontScale = 1.0;
        root.fontWeight = "normal";
        root.boldHeadings = true;
        root.letterSpacing = 0.0;
        root.fontHinting = "default";
        root.fontAntialiasing = true;
        root.fontRenderType = "qt";
        root.saveFontsConfig();
    }

    function applyFontsConfig(cfg) {
        if (!cfg) return;
        if (cfg.fontFamily && String(cfg.fontFamily).trim() !== "")
            root.savedFontFamily = String(cfg.fontFamily).trim();
        if (cfg.monoFont && String(cfg.monoFont).trim() !== "")
            root.savedMonoFont = String(cfg.monoFont).trim();
        if (cfg.lockscreenFont && String(cfg.lockscreenFont).trim() !== "")
            root.savedLockscreenFont = String(cfg.lockscreenFont).trim();
        else if (cfg.monoFont && String(cfg.monoFont).trim() !== "" && root.savedLockscreenFont === "JetBrainsMono Nerd Font")
            root.savedLockscreenFont = String(cfg.monoFont).trim();
        if (cfg.fontScale !== undefined)
            root.fontScale = Math.round(Math.max(0.85, Math.min(1.25, Number(cfg.fontScale) || 1.0)) * 100) / 100;
        if (cfg.fontWeight !== undefined && ["light", "normal", "medium", "demibold", "bold"].indexOf(String(cfg.fontWeight)) !== -1)
            root.fontWeight = String(cfg.fontWeight);
        if (cfg.boldHeadings !== undefined)
            root.boldHeadings = Boolean(cfg.boldHeadings);
        if (cfg.letterSpacing !== undefined)
            root.letterSpacing = Math.round(Math.max(-0.5, Math.min(2.0, Number(cfg.letterSpacing) || 0.0)) * 10) / 10;
        if (cfg.fontHinting !== undefined && ["default", "none", "vertical", "full"].indexOf(String(cfg.fontHinting)) !== -1)
            root.fontHinting = String(cfg.fontHinting);
        if (cfg.fontAntialiasing !== undefined)
            root.fontAntialiasing = Boolean(cfg.fontAntialiasing);
        if (cfg.fontRenderType !== undefined)
            root.fontRenderType = String(cfg.fontRenderType) === "native" ? "native" : "qt";
    }

    Timer {
        id: fontsSaveDebounce
        interval: 250
        repeat: false
        onTriggered: root.saveFontsConfig()
    }

    function saveFontsConfig() {
        if (!root._fontsLoaded) return;
        const data = {
            fontFamily: root.savedFontFamily,
            monoFont: root.savedMonoFont,
            lockscreenFont: root.savedLockscreenFont,
            fontScale: root.fontScale,
            fontWeight: root.fontWeight,
            boldHeadings: root.boldHeadings,
            letterSpacing: root.letterSpacing,
            fontHinting: root.fontHinting,
            fontAntialiasing: root.fontAntialiasing,
            fontRenderType: root.fontRenderType
        };
        const jsonStr = JSON.stringify(data, null, 2);
        saveFontsProc.command = [
            "python3", "-c",
            "import os, sys; p = sys.argv[1]; tmp = p + '.tmp'; open(tmp, 'w', encoding='utf-8').write(sys.argv[2] + '\\n'); os.replace(tmp, p)",
            root.fontsConfigPath,
            jsonStr
        ];
        saveFontsProc.running = true;
    }

    Process { id: saveFontsProc; running: false }

    FileView {
        id: fontsConfigFile
        path: root.fontsConfigPath
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            const raw = fontsConfigFile.text();
            if (!raw) {
                root._fontsLoaded = true;
                return;
            }
            try {
                root.applyFontsConfig(JSON.parse(raw));
            } catch (e) {
                console.error("Failed to parse fonts_config.json:", e);
            } finally {
                root._fontsLoaded = true;
            }
        }
    }

    Component.onCompleted: {
        try {
            const raw = fontsConfigFile.text();
            if (raw && raw.trim().length > 0) {
                root.applyFontsConfig(JSON.parse(raw));
            }
        } catch (e) {}
        root._fontsLoaded = true;
        root.syncApplicationFont();
    }

    function hexToRgba(hex) { return ThemeColorUtils.hexToRgba(hex); }
    function stripHex(hex) { return ThemeColorUtils.stripHex(hex); }

    function applyHyprlockTheme(t) {
        if (!t || !t.bgBase) return;
        var hyprlockConf = ThemeColorUtils.buildHyprlockConf(t, root.accentPrimary);
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

    readonly property string themeConfPath: Qt.resolvedUrl("../configs/theme.conf").toString().replace(/^file:\/\//, "")

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
        var kitty = ThemeColorUtils.buildKittyColors(t, root.accentPrimary);
        kittyProc.command = ["sh", "-c",
            "printf '%s\\n' '" + kitty.conf + "' > $HOME/.config/kitty/theme-colors.conf; " +
            "for sock in /tmp/kitty-*; do " +
            "[ -S \"$sock\" ] && kitty @ --to \"unix:$sock\" set-colors --all --configured " + kitty.args + "; " +
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
