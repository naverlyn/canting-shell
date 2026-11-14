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

Item {
    id: root
    property var theme: Style.theme
    property string font: Style.font

    // Browser & Preview state
    property string targetRole: "ui" // "ui" | "mono" | "both"
    property string searchQuery: ""
    property string activeCategory: "all" // "all" | "nerd" | "mono" | "sans"
    property string specimenTab: "ui" // "ui" | "mono" | "charset"
    property string customSpecimenText: "The quick brown fox jumps over the lazy dog 0123456789"
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
                    label: "Reset Defaults"
                    danger: true
                    btnEnabled: root.isCustomized
                    onClicked: {
                        root.theme.resetFontsToDefault();
                        root.showToast("Restored default typography (Lato Nerd + JetBrainsMono)");
                    }
                }
            }

            // ---------------------------------------------------------
            // 2. Active Font Role Summary Cards (UI Font & Mono Font)
            // ---------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Primary UI Font Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    height: 88
                    radius: 12
                    color: root.targetRole === "ui"
                        ? Style.withAlpha(root.theme.accentPrimary, 0.12)
                        : root.theme.bgSurface
                    border.color: root.targetRole === "ui"
                        ? root.theme.accentPrimary
                        : root.theme.bgBorder
                    border.width: root.targetRole === "ui" ? 1.5 : 1

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 10
                            color: Style.withAlpha(root.theme.accentPrimary, 0.16)
                            border.color: Style.withAlpha(root.theme.accentPrimary, 0.4)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Aa"
                                font.family: root.theme.fontFamily
                                font.pixelSize: Style.px(18)
                                font.bold: true
                                color: root.theme.accentPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: "PRIMARY UI FONT"
                                    font.family: Style.font
                                    font.pixelSize: Style.px(9)
                                    font.bold: true
                                    font.letterSpacing: 0.8
                                    color: root.theme.accentPrimary
                                }

                                Rectangle {
                                    visible: root.targetRole === "ui" || root.targetRole === "both"
                                    height: 15
                                    radius: 4
                                    implicitWidth: uiTargetLbl.implicitWidth + 8
                                    color: root.theme.accentPrimary

                                    Text {
                                        id: uiTargetLbl
                                        anchors.centerIn: parent
                                        text: "BROWSING"
                                        font.family: Style.font
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: root.theme.bgBase
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }

                            Text {
                                text: root.theme.fontFamily
                                font.family: root.theme.fontFamily
                                font.pixelSize: Style.px(14)
                                font.bold: true
                                color: root.theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "Bar • Settings • Control Center • Notifications • OSD"
                                font.family: Style.font
                                font.pixelSize: Style.px(10)
                                color: root.theme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.targetRole = "ui"
                    }
                }

                // Monospace & Lock Screen Font Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    height: 88
                    radius: 12
                    color: root.targetRole === "mono"
                        ? Style.withAlpha(root.theme.accentCyan, 0.12)
                        : root.theme.bgSurface
                    border.color: root.targetRole === "mono"
                        ? root.theme.accentCyan
                        : root.theme.bgBorder
                    border.width: root.targetRole === "mono" ? 1.5 : 1

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 10
                            color: Style.withAlpha(root.theme.accentCyan, 0.16)
                            border.color: Style.withAlpha(root.theme.accentCyan, 0.4)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "01"
                                font.family: root.theme.monoFont
                                font.pixelSize: Style.px(16)
                                font.bold: true
                                color: root.theme.accentCyan
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: "MONOSPACE & LOCK SCREEN"
                                    font.family: Style.font
                                    font.pixelSize: Style.px(9)
                                    font.bold: true
                                    font.letterSpacing: 0.8
                                    color: root.theme.accentCyan
                                }

                                Rectangle {
                                    visible: root.targetRole === "mono" || root.targetRole === "both"
                                    height: 15
                                    radius: 4
                                    implicitWidth: monoTargetLbl.implicitWidth + 8
                                    color: root.theme.accentCyan

                                    Text {
                                        id: monoTargetLbl
                                        anchors.centerIn: parent
                                        text: "BROWSING"
                                        font.family: Style.font
                                        font.pixelSize: 8
                                        font.bold: true
                                        color: root.theme.bgBase
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }

                            Text {
                                text: root.theme.monoFont
                                font.family: root.theme.monoFont
                                font.pixelSize: Style.px(14)
                                font.bold: true
                                color: root.theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "Lock Screen ($font) • Weather Metrics • Code Blocks"
                                font.family: Style.font
                                font.pixelSize: Style.px(10)
                                color: root.theme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.targetRole = "mono"
                    }
                }
            }

            // ---------------------------------------------------------
            // 3. Live Interactive Specimen Preview Card
            // ---------------------------------------------------------
            SectionCard {
                title: "Live Specimen Preview"
                subtitle: (root.hoveredBrowserFont !== "" ? ("Previewing: " + root.hoveredBrowserFont + "  •  ") : "")
                    + "Scale " + Math.round(root.theme.fontScale * 100) + "%  •  Weight: " + root.theme.fontWeight
                subtitleColor: root.hoveredBrowserFont !== "" ? root.theme.accentPrimary : root.theme.textMuted
                subtitleBold: root.hoveredBrowserFont !== ""

                // Specimen Mode Switcher + Custom Text Input
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "ui",      label: "Shell & Bar Mockup", icon: "󰮲" },
                            { id: "mono",    label: "Lock Screen & Code", icon: "󰌾" },
                            { id: "charset", label: "Scale & Character Set", icon: "󰛖" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: root.specimenTab === modelData.id
                            height: 28
                            radius: 7
                            implicitWidth: specTabRow.implicitWidth + 18
                            color: active ? root.theme.bgSelected : (specTabMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                            border.color: active ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on border.color { ColorAnimation { duration: 130 } }

                            Row {
                                id: specTabRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    font.family: Style.font
                                    font.pixelSize: Style.px(12)
                                    color: active ? root.theme.accentPrimary : root.theme.textSecondary
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    font.family: Style.font
                                    font.pixelSize: Style.px(11)
                                    font.bold: active
                                    color: active ? root.theme.textPrimary : root.theme.textSecondary
                                }
                            }

                            MouseArea {
                                id: specTabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.specimenTab = modelData.id
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Custom specimen text input
                    Rectangle {
                        Layout.preferredWidth: 260
                        height: 28
                        radius: 7
                        color: root.theme.bgBase
                        border.color: customSpecInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: customSpecInput.activeFocus ? 1.5 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                text: "󰏫"
                                font.family: Style.font
                                font.pixelSize: 11
                                color: root.theme.textMuted
                            }

                            TextInput {
                                id: customSpecInput
                                Layout.fillWidth: true
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.customSpecimenText
                                font.family: Style.font
                                font.pixelSize: 11
                                color: root.theme.textPrimary
                                selectByMouse: true
                                clip: true
                                onTextChanged: root.customSpecimenText = text
                            }
                        }
                    }
                }

                // Specimen Stage Canvas
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: specimenStack.implicitHeight + 24
                    radius: 10
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder
                    border.width: 1

                    ColumnLayout {
                        id: specimenStack
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 12
                        }
                        spacing: 10

                        // --- Mode 1: Shell & Bar Mockup ---
                        ColumnLayout {
                            visible: root.specimenTab === "ui"
                            Layout.fillWidth: true
                            spacing: 10

                            // Simulated Bar strip
                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                radius: 8
                                color: root.theme.bgSurface
                                border.color: root.theme.bgBorder
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    // Left workspace pills
                                    Rectangle {
                                        height: 22
                                        radius: 6
                                        implicitWidth: wsRow.implicitWidth + 14
                                        color: root.theme.bgSelected

                                        Row {
                                            id: wsRow
                                            anchors.centerIn: parent
                                            spacing: 8
                                            Text {
                                                text: "󰣇"
                                                font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                                                font.pixelSize: Style.px(13)
                                                color: root.theme.accentPrimary
                                            }
                                            Text {
                                                text: "1   2   3   •   Quickshell Settings"
                                                font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                                                font.pixelSize: Style.px(11)
                                                font.weight: Style.fontWeightEnum
                                                font.bold: Style.boldHeadings
                                                font.letterSpacing: Style.letterSpacing
                                                font.hintingPreference: Style.fontHintingEnum
                                                antialiasing: Style.fontAntialiasing
                                                renderType: Style.fontRenderTypeEnum
                                                color: root.theme.textPrimary
                                            }
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Center clock pill
                                    Text {
                                        text: "Thu 12 Nov   04:20"
                                        font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                                        font.pixelSize: Style.px(12)
                                        font.bold: Style.boldHeadings
                                        font.letterSpacing: Style.letterSpacing
                                        font.hintingPreference: Style.fontHintingEnum
                                        antialiasing: Style.fontAntialiasing
                                        renderType: Style.fontRenderTypeEnum
                                        color: root.theme.textPrimary
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Right status pill
                                    Rectangle {
                                        height: 22
                                        radius: 6
                                        implicitWidth: sysRow.implicitWidth + 14
                                        color: root.theme.bgHover

                                        Row {
                                            id: sysRow
                                            anchors.centerIn: parent
                                            spacing: 8
                                            Text {
                                                text: "󰖩  5G   󰕾  78%   󰁹  96%"
                                                font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                                                font.pixelSize: Style.px(11)
                                                font.weight: Style.fontWeightEnum
                                                font.letterSpacing: Style.letterSpacing
                                                font.hintingPreference: Style.fontHintingEnum
                                                antialiasing: Style.fontAntialiasing
                                                renderType: Style.fontRenderTypeEnum
                                                color: root.theme.textSecondary
                                            }
                                        }
                                    }
                                }
                            }

                            // Simulated Notification / UI Typography Card
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: notifSampleCol.implicitHeight + 20
                                radius: 8
                                color: root.theme.bgSurface
                                border.color: Style.withAlpha(root.theme.accentPrimary, 0.3)
                                border.width: 1

                                ColumnLayout {
                                    id: notifSampleCol
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 10
                                    }
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text {
                                            text: "󰂚  Typography Preview"
                                            font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                                            font.pixelSize: Style.px(13)
                                            font.bold: Style.boldHeadings
                                            font.letterSpacing: Style.letterSpacing
                                            font.hintingPreference: Style.fontHintingEnum
                                            antialiasing: Style.fontAntialiasing
                                            renderType: Style.fontRenderTypeEnum
                                            color: root.theme.textPrimary
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: "just now"
                                            font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                                            font.pixelSize: Style.px(10)
                                            color: root.theme.textMuted
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        text: root.customSpecimenText !== ""
                                            ? root.customSpecimenText
                                            : "The quick brown fox jumps over the lazy dog 0123456789"
                                        font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "mono" ? root.hoveredBrowserFont : root.theme.fontFamily
                                        font.pixelSize: Style.px(12)
                                        font.weight: Style.fontWeightEnum
                                        font.letterSpacing: Style.letterSpacing
                                        font.hintingPreference: Style.fontHintingEnum
                                        antialiasing: Style.fontAntialiasing
                                        renderType: Style.fontRenderTypeEnum
                                        color: root.theme.textSecondary
                                    }
                                }
                            }
                        }

                        // --- Mode 2: Lock Screen & Monospace Mockup ---
                        ColumnLayout {
                            visible: root.specimenTab === "mono"
                            Layout.fillWidth: true
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Text {
                                        text: "04:20"
                                        font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "ui" ? root.hoveredBrowserFont : root.theme.monoFont
                                        font.pixelSize: Style.px(38)
                                        font.bold: true
                                        font.letterSpacing: Style.letterSpacing
                                        font.hintingPreference: Style.fontHintingEnum
                                        antialiasing: Style.fontAntialiasing
                                        renderType: Style.fontRenderTypeEnum
                                        color: root.theme.textPrimary
                                    }
                                    Text {
                                        text: "Thursday, 12 November"
                                        font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "ui" ? root.hoveredBrowserFont : root.theme.monoFont
                                        font.pixelSize: Style.px(11)
                                        font.letterSpacing: Style.letterSpacing
                                        color: root.theme.accentCyan
                                    }
                                }

                                Rectangle {
                                    width: 1
                                    Layout.fillHeight: true
                                    color: root.theme.bgBorder
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: "󰍛 CPU 14%   •   󰘚 RAM 4.2 GiB   •   󰁹 BAT 96%"
                                        font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "ui" ? root.hoveredBrowserFont : root.theme.monoFont
                                        font.pixelSize: Style.px(12)
                                        font.bold: Style.boldHeadings
                                        font.letterSpacing: Style.letterSpacing
                                        color: root.theme.accentPrimary
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: "const shell = Quickshell.lock({ font: \"" + (root.hoveredBrowserFont !== "" && root.targetRole !== "ui" ? root.hoveredBrowserFont : root.theme.monoFont) + "\" }); // !== => <= >="
                                        font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "ui" ? root.hoveredBrowserFont : root.theme.monoFont
                                        font.pixelSize: Style.px(11)
                                        font.weight: Style.fontWeightEnum
                                        font.letterSpacing: Style.letterSpacing
                                        color: root.theme.textSecondary
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: "0123456789  Il1O0  [] {} () <>  !@#$%^&*+-=~"
                                        font.family: root.hoveredBrowserFont !== "" && root.targetRole !== "ui" ? root.hoveredBrowserFont : root.theme.monoFont
                                        font.pixelSize: Style.px(11)
                                        color: root.theme.textMuted
                                    }
                                }
                            }
                        }

                        // --- Mode 3: Scale & Character Set Waterfall ---
                        ColumnLayout {
                            visible: root.specimenTab === "charset"
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [
                                    { size: 11, label: "11px" },
                                    { size: 14, label: "14px" },
                                    { size: 18, label: "18px" }
                                ]
                                delegate: RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Rectangle {
                                        width: 48
                                        height: 20
                                        radius: 5
                                        color: root.theme.bgSurface
                                        Text {
                                            anchors.centerIn: parent
                                            text: Style.px(modelData.size) + "px"
                                            font.family: root.theme.monoFont
                                            font.pixelSize: 10
                                            color: root.theme.accentPrimary
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: root.customSpecimenText !== "" ? root.customSpecimenText : "The quick brown fox jumps over the lazy dog 0123456789"
                                        font.family: root.hoveredBrowserFont !== ""
                                            ? root.hoveredBrowserFont
                                            : (root.targetRole === "mono" ? root.theme.monoFont : root.theme.fontFamily)
                                        font.pixelSize: Style.px(modelData.size)
                                        font.weight: Style.fontWeightEnum
                                        font.letterSpacing: Style.letterSpacing
                                        font.hintingPreference: Style.fontHintingEnum
                                        antialiasing: Style.fontAntialiasing
                                        renderType: Style.fontRenderTypeEnum
                                        color: root.theme.textPrimary
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: root.theme.bgBorder
                            }

                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: "Nerd Icons:  󰣇  󰖩  󰂯  󰕾  󰂚  󰐥  󰍽  󰌌  󰍹  󰏘  󰮲  󰌾    󰸉  󰕮  󰁯  󰀻  󰅌"
                                font.family: root.hoveredBrowserFont !== ""
                                    ? root.hoveredBrowserFont
                                    : (root.targetRole === "mono" ? root.theme.monoFont : root.theme.fontFamily)
                                font.pixelSize: Style.px(13)
                                color: root.theme.accentCyan
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------------
            // 4. Curated Typography Pairings
            // ---------------------------------------------------------
            SectionCard {
                title: "Curated Typography Pairings"
                subtitle: "Hover to live-preview across Quickshell, click to apply"

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 8

                    Repeater {
                        model: root.curatedPairings
                        delegate: Rectangle {
                            id: pairCard
                            required property var modelData
                            required property int index

                            readonly property string resolvedUi: root.resolveAvailableFont(modelData.uiCandidates, modelData.uiFallback)
                            readonly property string resolvedMono: root.resolveAvailableFont(modelData.monoCandidates, modelData.monoFallback)
                            readonly property bool isCurrentPair: root.theme.savedFontFamily === resolvedUi && root.theme.savedMonoFont === resolvedMono

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: pairCardCol.implicitHeight + 20
                            radius: 10
                            color: isCurrentPair
                                ? Style.withAlpha(root.theme.accentPrimary, 0.13)
                                : (pairMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                            border.color: isCurrentPair
                                ? root.theme.accentPrimary
                                : (pairMouse.containsMouse ? Style.withAlpha(root.theme.accentPrimary, 0.45) : root.theme.bgBorder)
                            border.width: isCurrentPair ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            ColumnLayout {
                                id: pairCardCol
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: 10
                                }
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: modelData.name
                                        font.family: pairCard.resolvedUi
                                        font.pixelSize: Style.px(13)
                                        font.bold: true
                                        color: root.theme.textPrimary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        height: 16
                                        radius: 4
                                        implicitWidth: pairBadgeTxt.implicitWidth + 10
                                        color: pairCard.isCurrentPair
                                            ? root.theme.accentPrimary
                                            : Style.withAlpha(root.theme.accentPrimary, 0.14)

                                        Text {
                                            id: pairBadgeTxt
                                            anchors.centerIn: parent
                                            text: pairCard.isCurrentPair ? "ACTIVE" : modelData.badge
                                            font.family: Style.font
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: pairCard.isCurrentPair ? root.theme.bgBase : root.theme.accentPrimary
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.desc
                                    font.family: Style.font
                                    font.pixelSize: Style.px(10)
                                    color: root.theme.textSecondary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        height: 20
                                        radius: 5
                                        implicitWidth: Math.min(180, uiChipTxt.implicitWidth + 10)
                                        color: root.theme.bgSurface
                                        border.color: root.theme.bgBorder
                                        border.width: 1

                                        Text {
                                            id: uiChipTxt
                                            anchors.centerIn: parent
                                            width: Math.min(168, implicitWidth)
                                            elide: Text.ElideRight
                                            text: "UI: " + pairCard.resolvedUi
                                            font.family: pairCard.resolvedUi
                                            font.pixelSize: 10
                                            color: root.theme.textPrimary
                                        }
                                    }

                                    Rectangle {
                                        height: 20
                                        radius: 5
                                        implicitWidth: Math.min(180, monoChipTxt.implicitWidth + 10)
                                        color: root.theme.bgSurface
                                        border.color: root.theme.bgBorder
                                        border.width: 1

                                        Text {
                                            id: monoChipTxt
                                            anchors.centerIn: parent
                                            width: Math.min(168, implicitWidth)
                                            elide: Text.ElideRight
                                            text: "Mono: " + pairCard.resolvedMono
                                            font.family: pairCard.resolvedMono
                                            font.pixelSize: 10
                                            color: root.theme.accentCyan
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: pairMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    root.theme.previewFontFamily = pairCard.resolvedUi;
                                    root.theme.previewMonoFont = pairCard.resolvedMono;
                                }
                                onExited: {
                                    root.theme.previewFontFamily = "";
                                    root.theme.previewMonoFont = "";
                                }
                                onClicked: {
                                    root.theme.setFontPairing(pairCard.resolvedUi, pairCard.resolvedMono);
                                    root.showToast("Applied '" + modelData.name + "' font pairing");
                                }
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------------
            // 5. Installed Font Browser (Search, Filter, Live Specimen Rows)
            // ---------------------------------------------------------
            SectionCard {
                title: "Installed Font Browser"
                subtitle: root.filteredFonts.length + " matching families"

                // Top Row: Role Target Selector
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Assign Clicked Font To:"
                        font.family: Style.font
                        font.pixelSize: Style.px(11)
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    Repeater {
                        model: [
                            { id: "ui",   label: "Primary UI Font",           icon: "󰛖" },
                            { id: "mono", label: "Monospace / Lock Screen",   icon: "󰅩" },
                            { id: "both", label: "Both UI & Mono",            icon: "󰄬" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: root.targetRole === modelData.id
                            height: 28
                            radius: 7
                            implicitWidth: roleBtnRow.implicitWidth + 16
                            color: active
                                ? Style.withAlpha(root.theme.accentPrimary, 0.16)
                                : (roleBtnMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                            border.color: active ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: active ? 1.5 : 1

                            Row {
                                id: roleBtnRow
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    font.family: Style.font
                                    font.pixelSize: 12
                                    color: active ? root.theme.accentPrimary : root.theme.textSecondary
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    font.family: Style.font
                                    font.pixelSize: Style.px(11)
                                    font.bold: active
                                    color: active ? root.theme.textPrimary : root.theme.textSecondary
                                }
                            }

                            MouseArea {
                                id: roleBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.targetRole = modelData.id
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Second Row: Search Input + Category Filter Pills
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Search Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: 8
                        color: root.theme.bgBase
                        border.color: fontSearchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: fontSearchInput.activeFocus ? 1.5 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: "󰍉"
                                font.family: Style.font
                                font.pixelSize: 13
                                color: fontSearchInput.activeFocus ? root.theme.accentPrimary : root.theme.textMuted
                            }

                            TextInput {
                                id: fontSearchInput
                                Layout.fillWidth: true
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Style.font
                                font.pixelSize: Style.px(12)
                                color: root.theme.textPrimary
                                selectByMouse: true
                                clip: true
                                onTextChanged: root.searchQuery = text

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    visible: fontSearchInput.text === ""
                                    text: "Search installed fonts (e.g. Lato, JetBrains, Nerd, Fira, Adwaita)..."
                                    font.family: Style.font
                                    font.pixelSize: Style.px(12)
                                    color: root.theme.textMuted
                                }
                            }

                            Rectangle {
                                visible: fontSearchInput.text !== ""
                                width: 18
                                height: 18
                                radius: 9
                                color: clearSearchMouse.containsMouse ? root.theme.bgHover : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    font.family: Style.font
                                    font.pixelSize: 10
                                    color: root.theme.textMuted
                                }

                                MouseArea {
                                    id: clearSearchMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        fontSearchInput.text = "";
                                        root.searchQuery = "";
                                    }
                                }
                            }
                        }
                    }

                    // Filter Pills
                    Repeater {
                        model: [
                            { id: "all",  label: "All (" + root.allFonts.length + ")" },
                            { id: "nerd", label: "Nerd Fonts (" + root.nerdFontCount + ")" },
                            { id: "mono", label: "Monospace (" + root.monoFontCount + ")" },
                            { id: "sans", label: "Proportional" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: root.activeCategory === modelData.id
                            height: 34
                            radius: 8
                            implicitWidth: catFilterTxt.implicitWidth + 20
                            color: active
                                ? root.theme.accentPrimary
                                : (catFilterMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                            border.color: active ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 130 } }

                            Text {
                                id: catFilterTxt
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Style.font
                                font.pixelSize: Style.px(11)
                                font.bold: active
                                color: active ? root.theme.bgBase : root.theme.textSecondary
                            }

                            MouseArea {
                                id: catFilterMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeCategory = modelData.id
                            }
                        }
                    }
                }

                // Virtualized Font ListView
                Rectangle {
                    Layout.fillWidth: true
                    height: 310
                    radius: 10
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder
                    border.width: 1
                    clip: true

                    ListView {
                        id: browserList
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.filteredFonts

                        property bool hovered: false

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.2)
                            }
                        }

                        delegate: Rectangle {
                            id: fontRow
                            required property var modelData
                            required property int index

                            readonly property string fam: modelData.family
                            readonly property bool isUiActive: root.theme.savedFontFamily === fam
                            readonly property bool isMonoActive: root.theme.savedMonoFont === fam
                            readonly property bool isSelected: isUiActive || isMonoActive

                            width: ListView.view.width - 8
                            height: 52
                            radius: 8
                            color: isSelected
                                ? Style.withAlpha(root.theme.accentPrimary, 0.12)
                                : (rowMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface)
                            border.color: isUiActive
                                ? root.theme.accentPrimary
                                : (isMonoActive ? root.theme.accentCyan : (rowMouse.containsMouse ? root.theme.bgBorder : "transparent"))
                            border.width: isSelected ? 1.5 : 1

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    browserList.hovered = true;
                                    root.hoveredBrowserFont = fontRow.fam;
                                }
                                onExited: {
                                    browserList.hovered = false;
                                    if (root.hoveredBrowserFont === fontRow.fam)
                                        root.hoveredBrowserFont = "";
                                }
                                onClicked: root.applyFontForRole(fontRow.fam, root.targetRole)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                // Left: Family Name + Badges
                                ColumnLayout {
                                    Layout.preferredWidth: 250
                                    Layout.maximumWidth: 270
                                    spacing: 3

                                    RowLayout {
                                        spacing: 6
                                        Layout.fillWidth: true

                                        Text {
                                            text: fontRow.fam
                                            font.family: Style.font
                                            font.pixelSize: Style.px(12)
                                            font.bold: true
                                            color: root.theme.textPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Row {
                                        spacing: 5

                                        Rectangle {
                                            visible: fontRow.modelData.isNerd
                                            height: 15
                                            radius: 4
                                            implicitWidth: nerdTag.implicitWidth + 8
                                            color: Style.withAlpha(root.theme.accentGreen, 0.15)
                                            border.color: Style.withAlpha(root.theme.accentGreen, 0.4)
                                            border.width: 1
                                            Text {
                                                id: nerdTag
                                                anchors.centerIn: parent
                                                text: "NERD FONT"
                                                font.family: Style.font
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: root.theme.accentGreen
                                            }
                                        }

                                        Rectangle {
                                            visible: fontRow.modelData.isMono
                                            height: 15
                                            radius: 4
                                            implicitWidth: monoTag.implicitWidth + 8
                                            color: Style.withAlpha(root.theme.accentCyan, 0.15)
                                            border.color: Style.withAlpha(root.theme.accentCyan, 0.4)
                                            border.width: 1
                                            Text {
                                                id: monoTag
                                                anchors.centerIn: parent
                                                text: "MONO"
                                                font.family: Style.font
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: root.theme.accentCyan
                                            }
                                        }

                                        Rectangle {
                                            visible: fontRow.isUiActive
                                            height: 15
                                            radius: 4
                                            implicitWidth: uiActTag.implicitWidth + 8
                                            color: root.theme.accentPrimary
                                            Text {
                                                id: uiActTag
                                                anchors.centerIn: parent
                                                text: "ACTIVE UI"
                                                font.family: Style.font
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: root.theme.bgBase
                                            }
                                        }

                                        Rectangle {
                                            visible: fontRow.isMonoActive
                                            height: 15
                                            radius: 4
                                            implicitWidth: monoActTag.implicitWidth + 8
                                            color: root.theme.accentCyan
                                            Text {
                                                id: monoActTag
                                                anchors.centerIn: parent
                                                text: "ACTIVE MONO"
                                                font.family: Style.font
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: root.theme.bgBase
                                            }
                                        }
                                    }
                                }

                                // Middle: Live Specimen rendered in this font family
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: root.customSpecimenText !== ""
                                        ? root.customSpecimenText
                                        : "AaBbCc 0123  󰣇 󰖩 󰕾 — The quick brown fox"
                                    font.family: fontRow.fam
                                    font.pixelSize: Style.px(14)
                                    font.weight: Style.fontWeightEnum
                                    font.letterSpacing: Style.letterSpacing
                                    color: rowMouse.containsMouse ? root.theme.textPrimary : root.theme.textSecondary
                                }

                                // Right: Quick Set UI / Set Mono Pill Buttons
                                Row {
                                    spacing: 6

                                    Rectangle {
                                        height: 26
                                        radius: 6
                                        implicitWidth: setUiTxt.implicitWidth + 14
                                        color: fontRow.isUiActive
                                            ? root.theme.accentPrimary
                                            : (setUiMouse.containsMouse ? Style.withAlpha(root.theme.accentPrimary, 0.22) : root.theme.bgBase)
                                        border.color: root.theme.accentPrimary
                                        border.width: 1

                                        Text {
                                            id: setUiTxt
                                            anchors.centerIn: parent
                                            text: fontRow.isUiActive ? "✓ UI" : "Set UI"
                                            font.family: Style.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: fontRow.isUiActive ? root.theme.bgBase : root.theme.accentPrimary
                                        }

                                        MouseArea {
                                            id: setUiMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.applyFontForRole(fontRow.fam, "ui")
                                        }
                                    }

                                    Rectangle {
                                        height: 26
                                        radius: 6
                                        implicitWidth: setMonoTxt.implicitWidth + 14
                                        color: fontRow.isMonoActive
                                            ? root.theme.accentCyan
                                            : (setMonoMouse.containsMouse ? Style.withAlpha(root.theme.accentCyan, 0.22) : root.theme.bgBase)
                                        border.color: root.theme.accentCyan
                                        border.width: 1

                                        Text {
                                            id: setMonoTxt
                                            anchors.centerIn: parent
                                            text: fontRow.isMonoActive ? "✓ Mono" : "Set Mono"
                                            font.family: Style.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: fontRow.isMonoActive ? root.theme.bgBase : root.theme.accentCyan
                                        }

                                        MouseArea {
                                            id: setMonoMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.applyFontForRole(fontRow.fam, "mono")
                                        }
                                    }
                                }
                            }
                        }

                        // Empty state when no fonts match filter
                        Text {
                            anchors.centerIn: parent
                            visible: root.filteredFonts.length === 0
                            text: root.fontsLoading ? "Scanning installed fonts..." : "No installed fonts match \"" + root.searchQuery + "\""
                            font.family: Style.font
                            font.pixelSize: Style.px(12)
                            color: root.theme.textMuted
                        }
                    }
                }
            }

            // ---------------------------------------------------------
            // 6. Global Size, Scale & Spacing Controls
            // ---------------------------------------------------------
            SectionCard {
                title: "Size, Scale & Spacing"
                subtitle: "Global typography proportions across Settings & Shell"
                contentMargins: 8
                contentSpacing: 4

                SettingSliderRow {
                    title: "Global Font Scale"
                    desc: "Proportional size multiplier applied to text across Quickshell (85% – 125%)"
                    value: Math.round(root.theme.fontScale * 100)
                    minVal: 85
                    maxVal: 125
                    step: 5
                    unit: "%"
                    announce: true
                    presets: [
                        { label: "Small (90%)",   val: 90 },
                        { label: "Default (100%)", val: 100 },
                        { label: "Medium (105%)", val: 105 },
                        { label: "Large (110%)",  val: 110 },
                        { label: "Extra (120%)",  val: 120 }
                    ]
                    onValueModified: (val) => root.theme.setFontScale(val / 100.0)
                }

                RowDivider {}

                SettingSliderRow {
                    title: "Letter Spacing (Tracking)"
                    desc: "Adjust horizontal character spacing in pixels (-0.5px to +2.0px)"
                    value: root.theme.letterSpacing
                    minVal: -0.5
                    maxVal: 2.0
                    step: 0.1
                    isFloat: true
                    unit: "px"
                    announce: true
                    presets: [
                        { label: "Tight (-0.2)",  val: -0.2 },
                        { label: "Normal (0.0)",  val: 0.0 },
                        { label: "Relaxed (0.4)", val: 0.4 },
                        { label: "Wide (0.8)",    val: 0.8 }
                    ]
                    onValueModified: (val) => root.theme.setLetterSpacing(val)
                }
            }

            // ---------------------------------------------------------
            // 7. Font Weight & Rendering Preferences
            // ---------------------------------------------------------
            SectionCard {
                title: "Weight & Rendering Preferences"
                subtitle: "Control boldness, glyph hinting, and subpixel antialiasing"
                contentMargins: 8
                contentSpacing: 4

                // Base Font Weight Segmented Row
                PreferenceRow {
                    title: "Base Font Weight"
                    subtitle: "Default stroke weight for body text, descriptions, and controls"

                    Repeater {
                        model: [
                            { id: "light",    label: "Light" },
                            { id: "normal",   label: "Normal" },
                            { id: "medium",   label: "Medium" },
                            { id: "demibold", label: "SemiBold" },
                            { id: "bold",     label: "Bold" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: root.theme.fontWeight === modelData.id
                            height: 28
                            radius: 6
                            implicitWidth: weightBtnTxt.implicitWidth + 16
                            color: active
                                ? root.theme.accentPrimary
                                : (weightBtnMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                            border.color: active ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1

                            Text {
                                id: weightBtnTxt
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Style.font
                                font.pixelSize: Style.px(11)
                                font.bold: active
                                color: active ? root.theme.bgBase : root.theme.textSecondary
                            }

                            MouseArea {
                                id: weightBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.theme.setFontWeight(modelData.id);
                                    root.showToast("Base font weight: " + modelData.label);
                                }
                            }
                        }
                    }
                }

                RowDivider {}

                SettingToggleRow {
                    title: "Bold Section Headings & Titles"
                    desc: "Emphasize page headers, card titles, and active navigation items with bold weight"
                    checked: root.theme.boldHeadings
                    announce: true
                    onToggled: (val) => root.theme.setBoldHeadings(val)
                }

                RowDivider {}

                // Font Hinting Segmented Row
                PreferenceRow {
                    title: "Glyph Hinting"
                    subtitle: "Grid-fitting alignment for sharper text stems on standard and HiDPI displays"

                    Repeater {
                        model: [
                            { id: "default",  label: "Default" },
                            { id: "none",     label: "None" },
                            { id: "vertical", label: "Vertical" },
                            { id: "full",     label: "Full" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: root.theme.fontHinting === modelData.id
                            height: 28
                            radius: 6
                            implicitWidth: hintBtnTxt.implicitWidth + 16
                            color: active
                                ? root.theme.accentPrimary
                                : (hintBtnMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                            border.color: active ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1

                            Text {
                                id: hintBtnTxt
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Style.font
                                font.pixelSize: Style.px(11)
                                font.bold: active
                                color: active ? root.theme.bgBase : root.theme.textSecondary
                            }

                            MouseArea {
                                id: hintBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.theme.setFontHinting(modelData.id);
                                    root.showToast("Font hinting: " + modelData.label);
                                }
                            }
                        }
                    }
                }

                RowDivider {}

                SettingToggleRow {
                    title: "Smooth Font Antialiasing"
                    desc: "Enable smooth edge antialiasing across shell text surfaces"
                    checked: root.theme.fontAntialiasing
                    announce: true
                    onToggled: (val) => root.theme.setFontAntialiasing(val)
                }

                RowDivider {}

                // Text Rendering Engine Row
                PreferenceRow {
                    title: "Text Rasterizer Engine"
                    subtitle: "Choose between Qt distance-field vector curves or native platform FreeType rasterization"

                    Repeater {
                        model: [
                            { id: "qt",     label: "Qt Vector (Smooth)" },
                            { id: "native", label: "Native FreeType (Crisp)" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: root.theme.fontRenderType === modelData.id
                            height: 28
                            radius: 6
                            implicitWidth: rtBtnTxt.implicitWidth + 18
                            color: active
                                ? root.theme.accentPrimary
                                : (rtBtnMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase)
                            border.color: active ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1

                            Text {
                                id: rtBtnTxt
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Style.font
                                font.pixelSize: Style.px(11)
                                font.bold: active
                                color: active ? root.theme.bgBase : root.theme.textSecondary
                            }

                            MouseArea {
                                id: rtBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.theme.setFontRenderType(modelData.id);
                                    root.showToast("Text rasterizer: " + modelData.label);
                                }
                            }
                        }
                    }
                }
            }
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
