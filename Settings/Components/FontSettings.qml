/*
 * FontSettings.qml
 *
 * Dedicated Settings page for Quickshell Global Fonts & Typography.
 * Features:
 *   - Live interactive specimen preview (Bar & UI mockup, Lock Screen & Mono mockup, Pangram & Custom text)
 *   - Active role summary cards (Primary UI Font & Monospace / Lock Screen Font)
 *   - Curated typography preset pairings with live hover preview
 *   - Installed system font browser with search, Nerd Font & Monospace filters, and live per-font specimen rows
 *   - Global font scale multiplier (85% - 125%) & letter spacing controls
 *   - Font weight, bold headings, hinting, antialiasing, and rasterizer preferences
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Common"
import "Font"

Item {
    id: root
    property var theme: Style.theme
    property string font: Style.font

    // Browser & Preview state
    property string targetRole: "ui" // "ui" | "mono" | "both"
    property string searchQuery: ""
    property string activeCategory: "all" // "all" | "nerd" | "mono" | "sans"
    property string specimenTab: "ui" // "ui" | "mono" | "charset"
    property string customSpecimenText: "The quick brown fox jumps over 0123456789"
    property bool confirmReset: false

    Timer {
        id: resetConfirmTimer
        interval: 3500
        repeat: false
        onTriggered: root.confirmReset = false
    }
    property string hoveredBrowserFont: ""

    // Installed font catalog state
    property var allFonts: []
    property var monoFontSet: ({})
    property bool fontsLoading: false

    function showToast(msg, isWarn) {
        toastBanner.show(msg, isWarn);
    }

    Connections {
        target: Style
        function onToast(msg) {
            root.showToast(msg);
        }
    }

    readonly property bool isCustomized: {
        if (!root.theme) return false;
        return root.theme.savedFontFamily !== "Lato Nerd Font"
            || root.theme.savedMonoFont !== "JetBrainsMono Nerd Font"
            || Math.abs(root.theme.fontScale - 1.0) > 0.005
            || root.theme.fontWeight !== "normal"
            || root.theme.boldHeadings !== true
            || Math.abs(root.theme.letterSpacing - 0.0) > 0.01
            || root.theme.fontHinting !== "default"
            || root.theme.fontAntialiasing !== true
            || root.theme.fontRenderType !== "qt";
    }

    function isNerdFontName(fam) {
        if (!fam) return false;
        return String(fam).toLowerCase().indexOf("nerd") !== -1;
    }

    function isMonoFontName(fam) {
        if (!fam) return false;
        if (root.monoFontSet && root.monoFontSet[fam]) return true;
        const lower = String(fam).toLowerCase();
        if (lower.indexOf("propo") !== -1) return false;
        return lower.indexOf("mono") !== -1
            || lower.indexOf("code") !== -1
            || lower.indexOf("console") !== -1
            || lower.indexOf("terminal") !== -1
            || lower.indexOf("courier") !== -1
            || lower.indexOf("typewriter") !== -1
            || lower === "hack";
    }

    function isFontInstalled(fam) {
        if (!fam || !root.allFonts) return false;
        return root.allFonts.indexOf(fam) !== -1;
    }

    function resolveAvailableFont(candidates, fallback) {
        const fams = Qt.fontFamilies();
        for (let i = 0; i < candidates.length; i++) {
            if (fams.indexOf(candidates[i]) !== -1) return candidates[i];
        }
        return fallback;
    }

    readonly property var curatedPairings: [
        {
            name: "Quickshell Default",
            badge: "Default",
            desc: "Balanced humanist sans paired with crisp developer mono",
            uiCandidates: ["Lato Nerd Font", "Lato"],
            monoCandidates: ["JetBrainsMono Nerd Font", "JetBrains Mono"],
            uiFallback: "Lato Nerd Font",
            monoFallback: "JetBrainsMono Nerd Font"
        },
        {
            name: "JetBrains Unified",
            badge: "Technical",
            desc: "Cohesive developer typography across shell UI & lock screen",
            uiCandidates: ["JetBrainsMono Nerd Font Propo", "JetBrainsMono Nerd Font", "JetBrains Mono"],
            monoCandidates: ["JetBrainsMono Nerd Font", "JetBrainsMono Nerd Font Mono", "JetBrains Mono"],
            uiFallback: "JetBrainsMono Nerd Font",
            monoFallback: "JetBrainsMono Nerd Font"
        },
        {
            name: "Modern Adwaita",
            badge: "Desktop",
            desc: "Clean contemporary GNOME desktop sans and monospace pairing",
            uiCandidates: ["Adwaita Sans", "Cantarell", "DejaVu Sans"],
            monoCandidates: ["Adwaita Mono", "Source Code Pro", "JetBrainsMono Nerd Font"],
            uiFallback: "Adwaita Sans",
            monoFallback: "Adwaita Mono"
        },
        {
            name: "Droid & Hack Nerd",
            badge: "Nerd Icons",
            desc: "High-legibility screen fonts with full Nerd Font icon coverage",
            uiCandidates: ["DroidSansM Nerd Font Propo", "DroidSansM Nerd Font", "Droid Sans"],
            monoCandidates: ["Hack Nerd Font", "Hack Nerd Font Mono", "Hack"],
            uiFallback: "DroidSansM Nerd Font Propo",
            monoFallback: "Hack Nerd Font"
        },
        {
            name: "Fantasque & Victor",
            badge: "Expressive",
            desc: "Warm humanist proportions paired with sleek coding mono",
            uiCandidates: ["FantasqueSansM Nerd Font Propo", "FantasqueSansM Nerd Font"],
            monoCandidates: ["Victor Mono", "JetBrainsMono Nerd Font"],
            uiFallback: "FantasqueSansM Nerd Font Propo",
            monoFallback: "Victor Mono"
        },
        {
            name: "Classic Code",
            badge: "Crisp",
            desc: "Neutral desktop sans paired with Fira Code programming ligatures",
            uiCandidates: ["DejaVu Sans", "FreeSans", "Lato Nerd Font"],
            monoCandidates: ["Fira Code", "Source Code Pro", "DejaVu Sans Mono"],
            uiFallback: "DejaVu Sans",
            monoFallback: "Fira Code"
        }
    ]

    readonly property var filteredFonts: {
        const list = root.allFonts || [];
        const q = root.searchQuery.toLowerCase().trim();
        const cat = root.activeCategory;
        const out = [];

        for (let i = 0; i < list.length; i++) {
            const fam = list[i];
            if (!fam) continue;
            const isNerd = root.isNerdFontName(fam);
            const isMono = root.isMonoFontName(fam);

            if (cat === "nerd" && !isNerd) continue;
            if (cat === "mono" && !isMono) continue;
            if (cat === "sans" && isMono) continue;

            if (q !== "" && fam.toLowerCase().indexOf(q) === -1) continue;

            out.push({
                family: fam,
                isNerd: isNerd,
                isMono: isMono
            });
        }
        return out;
    }

    readonly property int nerdFontCount: {
        const list = root.allFonts || [];
        let c = 0;
        for (let i = 0; i < list.length; i++) {
            if (root.isNerdFontName(list[i])) c++;
        }
        return c;
    }

    readonly property int monoFontCount: {
        const list = root.allFonts || [];
        let c = 0;
        for (let i = 0; i < list.length; i++) {
            if (root.isMonoFontName(list[i])) c++;
        }
        return c;
    }

    function loadInstalledFonts() {
        root.fontsLoading = true;
        const rawFamilies = Qt.fontFamilies();
        const cleanSet = {};
        const cleaned = [];

        for (let i = 0; i < rawFamilies.length; i++) {
            const f = String(rawFamilies[i] || "").trim();
            if (!f || f.indexOf(",") !== -1) continue;
            if (!cleanSet[f]) {
                cleanSet[f] = true;
                cleaned.push(f);
            }
        }

        // Sort with Nerd Fonts and active fonts prioritized nicely or alphabetically
        cleaned.sort((a, b) => a.localeCompare(b));
        root.allFonts = cleaned;
        monoDetectProc.running = true;
    }

    Process {
        id: monoDetectProc
        command: ["sh", "-c", "fc-list :spacing=100 family 2>/dev/null | tr ',' '\\n' | sort -u"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const map = {};
                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i].trim();
                    if (l && l.toLowerCase().indexOf("propo") === -1) {
                        map[l] = true;
                    }
                }
                root.monoFontSet = map;
                root.fontsLoading = false;
            }
        }
    }

    function applyFontForRole(fam, role) {
        if (!fam || !root.theme) return;
        const r = role || root.targetRole;
        if (r === "ui") {
            root.theme.setFontFamily(fam);
            root.showToast("Primary UI Font set to " + fam);
        } else if (r === "mono") {
            root.theme.setMonoFont(fam);
            root.showToast("Monospace / Lock Screen Font set to " + fam);
        } else {
            root.theme.setFontPairing(fam, fam);
            root.showToast("UI & Monospace Font set to " + fam);
        }
    }

    onVisibleChanged: {
        if (!visible && root.theme) {
            root.theme.previewFontFamily = "";
            root.theme.previewMonoFont = "";
            root.hoveredBrowserFont = "";
        }
    }

    Component.onDestruction: {
        if (root.theme) {
            root.theme.previewFontFamily = "";
            root.theme.previewMonoFont = "";
        }
    }

    Component.onCompleted: {
        root.loadInstalledFonts();
    }

    /* Main Scrollable Content */
    Flickable {
        id: pageFlick
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 36
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !browserList.hovered

        ScrollBar.vertical: ScrollBar {
            id: mainScroll
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15)
            }
        }

        ColumnLayout {
            id: mainCol
            width: pageFlick.width - (mainScroll.visible ? 12 : 0)
            spacing: 16

            // ---------------------------------------------------------
            // 1. Page Header Row
            // ---------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8
                        Text {
                            text: "Fonts & Typography"
                            font.family: Style.font
                            font.pixelSize: Style.px(18)
                            font.bold: Style.boldHeadings
                            font.letterSpacing: Style.letterSpacing
                            color: root.theme.textPrimary
                        }

                        Rectangle {
                            height: 20
                            radius: 10
                            implicitWidth: countBadgeText.implicitWidth + 14
                            color: Style.withAlpha(root.theme.accentPrimary, 0.14)
                            border.color: Style.withAlpha(root.theme.accentPrimary, 0.35)
                            border.width: 1

                            Text {
                                id: countBadgeText
                                anchors.centerIn: parent
                                text: root.allFonts.length + " Families • " + root.nerdFontCount + " Nerd"
                                font.family: Style.font
                                font.pixelSize: Style.px(10)
                                font.bold: true
                                color: root.theme.accentPrimary
                            }
                        }
                    }

                    Text {
                        text: "Configure global primary UI font, monospace lock screen font, scaling, and rendering"
                        font.family: Style.font
                        font.pixelSize: Style.px(11)
                        color: root.theme.textSecondary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                ActionButton {
                    iconText: "󰑐"
                    label: "Refresh"
                    btnEnabled: !root.fontsLoading
                    onClicked: {
                        root.loadInstalledFonts();
                        root.showToast("Rescanned installed system fonts");
                    }
                }

                ActionButton {
                    iconText: "󰦛"
                    label: root.confirmReset ? "Confirm Reset?" : "Reset Defaults"
                    danger: true
                    btnEnabled: root.isCustomized
                    onClicked: {
                        if (!root.confirmReset) {
                            root.confirmReset = true;
                            resetConfirmTimer.restart();
                        } else {
                            resetConfirmTimer.stop();
                            root.confirmReset = false;
                            root.theme.resetFontsToDefault();
                            root.showToast("Restored default typography (Lato Nerd + JetBrainsMono)");
                        }
                    }
                }
            }

            FontRoleCards { root: root }
            FontSpecimenPreviewCard { root: root }
            FontPairingsCard { root: root }
            FontBrowserCard { root: root }
            FontScaleRenderingCard { root: root }
        }
    }

    // Floating Bottom Toast Pill
    ToastBanner {
        id: toastBanner
        theme: root.theme
        font: Style.font
        durationMs: 2600
    }
}
