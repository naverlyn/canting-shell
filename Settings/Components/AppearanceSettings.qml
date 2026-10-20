import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."
import "./Appearance"

Item {
    id: root
    property alias themeProcRef: themeProc
    property alias wpProcRef: wpProc
    property var theme
    property string font

    property string searchText: ""
    property string selectedFamily: "All"
    property string hoveredAccentName: ""

    readonly property var families: ["All", "GenAI", "Tokyo Night", "Catppuccin", "MonkeyType"]

    function isColorMatch(c1, c2) {
        if (!c1 || !c2) return false;
        var s1 = String(c1).toLowerCase();
        var s2 = String(c2).toLowerCase();
        return s1.substring(0, 7) === s2.substring(0, 7);
    }

    function getThemeAccent(name, defaultColor) {
        if (!root.theme || !root.theme.current) return defaultColor;
        var t = root.theme.current;
        return t[name] ? String(t[name]) : defaultColor;
    }

    readonly property var accentSwatches: [
        { name: "Primary", color: getThemeAccent("accentPrimary", "#7aa2f7") },
        { name: "Cyan",    color: getThemeAccent("accentCyan", "#7dcfff") },
        { name: "Green",   color: getThemeAccent("accentGreen", "#9ece6a") },
        { name: "Orange",  color: getThemeAccent("accentOrange", "#ff9e64") },
        { name: "Red",     color: getThemeAccent("accentRed", "#f7768e") }
    ]

    function hasActiveCustomAccent() {
        if (!root.theme || !root.theme.customAccent) return false;
        for (var i = 0; i < root.accentSwatches.length; i++) {
            if (isColorMatch(root.theme.customAccent, root.accentSwatches[i].color))
                return true;
        }
        return false;
    }

    readonly property var filteredThemes: {
        if (!root.theme || !root.theme.themes) return [];
        var query = searchText.toLowerCase().trim();
        var fam = selectedFamily;
        var res = [];
        for (var i = 0; i < root.theme.themes.length; i++) {
            var t = root.theme.themes[i];
            if (!t) continue;
            if (fam !== "All" && t.family !== fam) continue;
            if (query !== "") {
                var nameMatch = t.name && t.name.toLowerCase().indexOf(query) !== -1;
                var famMatch = t.family && t.family.toLowerCase().indexOf(query) !== -1;
                if (!nameMatch && !famMatch) continue;
            }
            res.push({ data: t, originalIndex: i });
        }
        return res;
    }

    onVisibleChanged: {
        if (!visible && root.theme) {
            root.theme.previewIndex = -1;
            root.theme.previewAccent = "";
        }
    }

    Component.onDestruction: {
        if (root.theme) {
            root.theme.previewIndex = -1;
            root.theme.previewAccent = "";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.bottomMargin: 14
        spacing: 10

        // Page title
        Text {
            text: "Appearance"
            font.family: root.font
            font.pixelSize: 18
            font.bold: true
            color: root.theme.textPrimary
            Layout.fillWidth: true
        }

        // 1. Current Theme Preview & System Color Scheme Card
        Rectangle {
            Layout.fillWidth: true
            height: 90
            radius: 12
            color: root.theme.bgSelected

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.15)
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰏘"
                        font.family: root.font
                        font.pixelSize: 24
                        color: root.theme.accentPrimary
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8
                        Text {
                            text: "System Color Scheme"
                            font.family: root.font
                            font.pixelSize: 14
                            font.bold: true
                            color: root.theme.textPrimary
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Active theme badge
                        Rectangle {
                            height: 18
                            radius: 9
                            implicitWidth: badgeText.implicitWidth + 12
                            color: root.theme.bgSurface
                            border.color: root.theme.accentPrimary
                            border.width: 1

                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: root.theme.accentPrimary
                                text: root.theme.wallpaperMode
                                      ? "Wallpaper Palette"
                                      : ((root.theme.currentFamily || "") + " - " + (root.theme.currentName || ""))
                            }
                        }
                    }

                    Text {
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        text: root.hoveredAccentName !== ""
                              ? ("Hovering: " + root.hoveredAccentName + " accent")
                              : (root.hasActiveCustomAccent()
                                 ? "Custom accent active. Click Primary to reset."
                                 : "Hover swatches or themes to live-preview colors, click to apply")
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // Theme Accent Swatches with stable hover container
                    AppearanceThemeAccentSwatches {
                        root: root
                    }
                }
            }
        }

        // 2. Embedded Theme & Color Scheme Selector
        AppearanceThemeSelector {
            root: root
        }

        // 3. Desktop Wallpaper Switcher Card
        AppearanceWallpaperCard {
            root: root
        }
    }

    Process {
        id: themeProc
        command: ["qs", "ipc", "call", "theme", "toggle"]
        running: false
    }

    Process {
        id: wpProc
        command: ["qs", "ipc", "call", "wallpaper", "toggle"]
        running: false
    }
}
