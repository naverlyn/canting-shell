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
        colorSchemeProc.command = ["gsettings", "set",
            "org.gnome.desktop.interface", "color-scheme",
            dark ? "prefer-dark" : "prefer-light"];
        colorSchemeProc.running = true;
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

    function applyHyprlandBorders(t) {
        var activeColor1 = hexToRgba(root.accentPrimary);
        var activeColor2 = hexToRgba(t.accentCyan);
        var angle = 45;
        var active = activeColor1 + " " + activeColor2 + " " + angle + "deg";
        var inactive = hexToRgba(t.bgBorder);
        var writeCmd = root.configFormat === "lua"
            ? "printf 'hl.config({\\n    general = {\\n        [\"col.active_border\"] = { colors = { \"" + activeColor1 + "\", \"" + activeColor2 + "\" }, angle = " + angle + " },\\n        [\"col.inactive_border\"] = \"" + inactive + "\",\\n    },\\n})\\n' > \"$HOME/.config/hypr/theme-borders.lua\""
            : 'printf "general {\\n    col.active_border = ' + active + '\\n    col.inactive_border = ' + inactive + '\\n}\\n" > "$HOME/.config/hypr/theme-borders.conf"';
        var applyCmd = root.configFormat === "lua"
            ? "hyprctl -r eval \"$(/bin/cat $HOME/.config/hypr/theme-borders.lua)\""
            : 'hyprctl keyword general:col.active_border "' + active + '" && hyprctl keyword general:col.inactive_border "' + inactive + '"';

        var ensureSource = '[ -f "$HOME/.config/hypr/hyprland.conf" ] && ! grep -q "theme-borders" "$HOME/.config/hypr/hyprland.conf" 2>/dev/null && echo -e "\\nsource = ~/.config/hypr/theme-borders.' + (root.configFormat === "lua" ? "lua" : "conf") + '" >> "$HOME/.config/hypr/hyprland.conf" || true';
        hyprlandProc.command = ["sh", "-c",
            writeCmd + ' && ' +
            applyCmd + ' ; ' +
            ensureSource
        ];
        hyprlandProc.running = true;
    }

    function applyTheme(t) {
        applyKittyTheme(t);
        applySystemColorScheme(!isLightColor(t.bgBase));
        applyHyprlandBorders(t);
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
    Process { id: kittyProc; running: false }
    Process { id: colorSchemeProc; running: false }
    Process { id: hyprlandProc; running: false }

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
