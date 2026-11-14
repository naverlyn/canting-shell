/*
 * AppLauncherSettings.qml
 *
 * Comprehensive configuration for Quickshell Spotlight Launcher and AppGrid menu.
 * Designed to strictly match the layout, typography, and sub-tab indicator styling
 * of HyprlandSettings and BarSettings.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../utils/AppFrecencyUtils.js" as AppFrecencyUtils
import Quickshell.Io
import Quickshell.Widgets
import "../../AppLauncher"
import ".."
import "./Common"

Item {
    id: root
    property var theme
    property string font: "Lato Nerd Font"

    // Sub-tab: 0: Layout & Sizing, 1: Search & Ranking, 2: Applications
    property int currentSubTab: 0

    // Preview mode: "spotlight" or "grid"
    property string previewMode: "spotlight"

    Connections {
        target: Style
        function onToast(msg) { root.showToast(msg); }
    }

    function showToast(msg, isWarn) {
        toastBanner.show(msg, isWarn);
    }

    Connections {
        target: AppLauncherConfig
        function onUsageCleared() {
            root.showToast("Launch history and frecency cache cleared!");
        }
    }

    // App Manager search & filtering state
    property string appSearchQuery: ""
    property string appFilterMode: "all" // "all", "favorites", "hidden"
    property bool showAllApps: false

    readonly property var allApps: {
        try {
            const list = [...DesktopEntries.applications.values];
            return list.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        } catch(e) {
            return [];
        }
    }

    readonly property int totalAppCount: allApps.length
    readonly property int favoriteCount: (AppLauncherConfig.favoriteApps || []).length
    readonly property int hiddenCount: (AppLauncherConfig.hiddenApps || []).length

    function getAppKey(app) {
        return AppFrecencyUtils.getAppKey(app);
    }

    readonly property var filteredAppsList: {
        const q = root.appSearchQuery.toLowerCase().trim();
        const mode = root.appFilterMode;
        return root.allApps.filter(app => {
            const key = root.getAppKey(app);
            const isFav = AppLauncherConfig.isAppFavorite(key);
            const isHid = AppLauncherConfig.isAppHidden(key);

            if (mode === "favorites" && !isFav) return false;
            if (mode === "hidden" && !isHid) return false;

            if (!q) return true;
            const n = (app.name || "").toLowerCase();
            const g = (app.genericName || "").toLowerCase();
            const k = key.toLowerCase();
            return n.includes(q) || g.includes(q) || k.includes(q);
        });
    }

    /* ---- Main Scrollable Content ---- */
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 28
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder
            }
        }

        ColumnLayout {
            id: mainCol
            width: parent.width - 12
            spacing: 18

            /* Top Page Header (Matching HyprlandSettings) */
            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 3
                    Text {
                        text: "App Launcher"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                    Text {
                        text: "Configure spotlight runner, app grid dimensions, search behavior, and application visibility"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }
            }

            /* Sub-Tab Switch Transition Animation */
            ParallelAnimation {
                id: subTabContentAnim
                NumberAnimation {
                    target: subTabContentContainer
                    property: "opacity"
                    from: 0.35
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: subTabContentTranslate
                    property: "y"
                    from: 8
                    to: 0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            /* Sub-Tab Navigation Bar (Underline indicator matching HyprlandSettings & BarSettings) */
            Rectangle {
                id: subTabTrack
                Layout.fillWidth: true
                height: 40
                radius: 10
                color: root.theme.bgSurface
                border.color: root.theme.bgBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Repeater {
                        model: [
                            { idx: 0, icon: "󰕮", label: "Layout & Sizing" },
                            { idx: 1, icon: "󰍉", label: "Search & Ranking" },
                            { idx: 2, icon: "󰀻", label: "Applications (" + root.totalAppCount + ")" }
                        ]
                        delegate: Rectangle {
                            id: subTabItem
                            required property var modelData
                            readonly property bool isCurrent: root.currentSubTab === modelData.idx

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                            border.width: 0

                            HoverHandler { id: subTabHover }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 2
                                radius: 1
                                width: subTabItem.isCurrent
                                    ? subTabRow.implicitWidth + 16
                                    : (subTabHover.hovered ? (subTabRow.implicitWidth + 16) * 0.5 : 0)
                                opacity: subTabItem.isCurrent ? 1.0 : (subTabHover.hovered ? 0.5 : 0.0)
                                color: subTabItem.isCurrent ? root.theme.accentPrimary : root.theme.textSecondary

                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 160 } }
                                Behavior on color { ColorAnimation { duration: 160 } }
                            }

                            Row {
                                id: subTabRow
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    width: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: subTabItem.modelData.icon
                                    font.family: root.font
                                    font.pixelSize: 13
                                    color: subTabItem.isCurrent
                                        ? root.theme.accentPrimary
                                        : (subTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: subTabItem.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: subTabItem.isCurrent
                                    color: subTabItem.isCurrent
                                        ? root.theme.accentPrimary
                                        : (subTabHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.currentSubTab !== subTabItem.modelData.idx) {
                                        root.currentSubTab = subTabItem.modelData.idx;
                                        subTabContentAnim.restart();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* Sub-Tab Dynamic Animated Container */
            ColumnLayout {
                id: subTabContentContainer
                Layout.fillWidth: true
                spacing: 16
                transform: Translate { id: subTabContentTranslate; y: 0 }

                // =====================================================================
                // SUB-TAB 0: LAYOUT & SIZING
                // =====================================================================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    visible: root.currentSubTab === 0

                    // Live Interactive Proportions Preview Card
                    SectionCard {
                        title: "Live Proportions Preview"
                        subtitle: root.previewMode === "spotlight"
                            ? (AppLauncherConfig.spotlightWidth + " × " + AppLauncherConfig.spotlightHeight + " px • Spotlight Runner")
                            : (AppLauncherConfig.gridColumns + " Columns • " + AppLauncherConfig.gridCellSize + " px Cell • App Grid")
                        contentMargins: 14
                        contentSpacing: 12

                        // Toggle Preview Switcher Track
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                implicitHeight: 28
                                implicitWidth: previewTrackRow.implicitWidth + 8
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder
                                border.width: 1

                                RowLayout {
                                    id: previewTrackRow
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Rectangle {
                                        implicitWidth: 124
                                        implicitHeight: 22
                                        radius: 5
                                        color: root.previewMode === "spotlight" ? root.theme.accentPrimary : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text {
                                                text: "󰍉"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                color: root.previewMode === "spotlight" ? root.theme.bgBase : root.theme.textMuted
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                text: "Spotlight Runner"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: root.previewMode === "spotlight"
                                                color: root.previewMode === "spotlight" ? root.theme.bgBase : root.theme.textSecondary
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.previewMode = "spotlight"
                                        }
                                    }

                                    Rectangle {
                                        implicitWidth: 116
                                        implicitHeight: 22
                                        radius: 5
                                        color: root.previewMode === "grid" ? root.theme.accentPrimary : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text {
                                                text: "󰕮"
                                                font.family: root.font
                                                font.pixelSize: 11
                                                color: root.previewMode === "grid" ? root.theme.bgBase : root.theme.textMuted
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                text: "App Grid Menu"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: root.previewMode === "grid"
                                                color: root.previewMode === "grid" ? root.theme.bgBase : root.theme.textSecondary
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.previewMode = "grid"
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 180
                            radius: 12
                            color: root.theme.bgBase
                            border.color: root.theme.bgBorder
                            border.width: 1
                            clip: true

                            // Screen canvas simulation
                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.round(parent.width * 0.90)
                                height: 154
                                radius: 8
                                color: Qt.darker(root.theme.bgBase, 1.25)
                                border.color: Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1

                                // -------------------------------------------------------------
                                // A. SPOTLIGHT RUNNER PREVIEW
                                // -------------------------------------------------------------
                                Rectangle {
                                    id: mockSpotlightBox
                                    visible: root.previewMode === "spotlight"
                                    readonly property real scaleRatio: 120 / 620
                                    width: Math.max(180, Math.min(parent.width - 24, Math.round(AppLauncherConfig.spotlightWidth * scaleRatio)))
                                    height: Math.max(86, Math.min(136, Math.round(AppLauncherConfig.spotlightHeight * scaleRatio)))
                                    anchors.centerIn: parent
                                    radius: 10
                                    color: root.theme.bgSurface
                                    border.color: root.theme.accentPrimary
                                    border.width: 1.5

                                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 7
                                        spacing: 5

                                        // Mock Spotlight Top Search Bar
                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 18
                                            radius: 5
                                            color: root.theme.bgBase
                                            border.color: root.theme.bgBorder
                                            border.width: 1

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 6
                                                anchors.rightMargin: 6
                                                spacing: 4

                                                Text {
                                                    text: AppLauncherConfig.defaultMode === "command" ? "$" : "󰍉"
                                                    font.family: root.font
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: root.theme.accentPrimary
                                                }

                                                Text {
                                                    text: AppLauncherConfig.defaultMode === "command" ? "run shell command..." : "search applications..."
                                                    font.family: root.font
                                                    font.pixelSize: 8
                                                    color: root.theme.textMuted
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: AppLauncherConfig.defaultMode === "command" ? "Command  Tab" : "Apps  Tab"
                                                    font.family: root.font
                                                    font.pixelSize: 7
                                                    font.bold: true
                                                    color: root.theme.textSecondary
                                                }
                                            }
                                        }

                                        // Mock Spotlight List Rows (Vertical results list)
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            spacing: 3

                                            // Row 1: Selected
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 4
                                                color: root.theme.bgSelected

                                                Rectangle {
                                                    width: 2
                                                    height: parent.height - 4
                                                    radius: 1
                                                    color: root.theme.accentPrimary
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: 2
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 7
                                                    anchors.rightMargin: 6
                                                    spacing: 5

                                                    Rectangle {
                                                        width: 10; height: 10; radius: 2; color: root.theme.accentPrimary; opacity: 0.9
                                                        Text { anchors.centerIn: parent; text: "󰨞"; font.pixelSize: 7; color: root.theme.bgBase; font.family: root.font }
                                                    }
                                                    Column {
                                                        Layout.fillWidth: true
                                                        Text { text: "VSCodium"; font.pixelSize: 7; font.bold: true; color: root.theme.textPrimary; font.family: root.font }
                                                        Text { text: "Text Editor"; font.pixelSize: 6; color: root.theme.textMuted; font.family: root.font }
                                                    }
                                                    Text { text: "󰋚"; font.pixelSize: 7; color: root.theme.accentPrimary; font.family: root.font }
                                                }
                                            }

                                            // Row 2: Unselected
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 4
                                                color: "transparent"

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 7
                                                    anchors.rightMargin: 6
                                                    spacing: 5

                                                    Rectangle {
                                                        width: 10; height: 10; radius: 2; color: Qt.rgba(1, 1, 1, 0.12)
                                                        Text { anchors.centerIn: parent; text: "󰈹"; font.pixelSize: 7; color: root.theme.textPrimary; font.family: root.font }
                                                    }
                                                    Column {
                                                        Layout.fillWidth: true
                                                        Text { text: "Brave"; font.pixelSize: 7; color: root.theme.textSecondary; font.family: root.font }
                                                        Text { text: "Web Browser"; font.pixelSize: 6; color: root.theme.textMuted; font.family: root.font }
                                                    }
                                                }
                                            }

                                            // Row 3: Unselected
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 4
                                                color: "transparent"

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 7
                                                    anchors.rightMargin: 6
                                                    spacing: 5

                                                    Rectangle {
                                                        width: 10; height: 10; radius: 2; color: Qt.rgba(1, 1, 1, 0.12)
                                                        Text { anchors.centerIn: parent; text: "󰓓"; font.pixelSize: 7; color: root.theme.textPrimary; font.family: root.font }
                                                    }
                                                    Column {
                                                        Layout.fillWidth: true
                                                        Text { text: "Steam"; font.pixelSize: 7; color: root.theme.textSecondary; font.family: root.font }
                                                        Text { text: "Game Launcher"; font.pixelSize: 6; color: root.theme.textMuted; font.family: root.font }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // -------------------------------------------------------------
                                // B. APP GRID MENU PREVIEW
                                // -------------------------------------------------------------
                                Rectangle {
                                    id: mockGridBox
                                    visible: root.previewMode === "grid"
                                    width: Math.min(parent.width - 24, Math.max(170, AppLauncherConfig.gridColumns * (AppLauncherConfig.gridCellSize > 72 ? 30 : 25) + 32))
                                    height: Math.min(136, 116)
                                    anchors.centerIn: parent
                                    radius: 10
                                    color: root.theme.bgSurface
                                    border.color: root.theme.accentPrimary
                                    border.width: 1.5

                                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 7
                                        spacing: 6

                                        // Mock Search Bar
                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 18
                                            radius: 5
                                            color: root.theme.bgBase
                                            border.color: root.theme.bgBorder
                                            border.width: 1

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 6
                                                anchors.rightMargin: 6
                                                spacing: 4

                                                Text {
                                                    text: "󰍉"
                                                    font.family: root.font
                                                    font.pixelSize: 9
                                                    color: root.theme.accentPrimary
                                                }

                                                Text {
                                                    text: "Search apps..."
                                                    font.family: root.font
                                                    font.pixelSize: 8
                                                    color: root.theme.textMuted
                                                    Layout.fillWidth: true
                                                }
                                            }
                                        }

                                        // Mock App Grid cells
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            spacing: 4

                                            Repeater {
                                                model: Math.min(8, AppLauncherConfig.gridColumns)
                                                delegate: Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    radius: 4
                                                    color: index === 0 ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03)

                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 2
                                                        Rectangle {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            width: AppLauncherConfig.gridCellSize > 72 ? 14 : 11
                                                            height: AppLauncherConfig.gridCellSize > 72 ? 14 : 11
                                                            radius: 3
                                                            color: index === 0 ? root.theme.accentPrimary : root.theme.textMuted
                                                            opacity: 0.8
                                                        }
                                                        Rectangle {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            width: 16
                                                            height: 2
                                                            radius: 1
                                                            color: root.theme.textMuted
                                                            opacity: 0.5
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Spotlight Window Sizing Section
                    SectionCard {
                        title: "Spotlight Runner Dimensions (Center Popup)"
                        subtitle: "Adjust the popup box size when opened via shortcut or runner"
                        contentMargins: 8
                        contentSpacing: 0

                        SettingSliderRow {
                            title: "Spotlight Width"
                            desc: "Width of the center spotlight application launcher"
                            value: AppLauncherConfig.spotlightWidth
                            minVal: 480
                            maxVal: 840
                            step: 10
                            unit: "px"
                            presets: [
                                { label: "540px", val: 540 },
                                { label: "620px (Default)", val: 620 },
                                { label: "720px", val: 720 },
                                { label: "800px", val: 800 }
                            ]
                            onValueModified: (val) => AppLauncherConfig.setSpotlightWidth(val)
                        }

                        RowDivider {}

                        SettingSliderRow {
                            title: "Spotlight Height"
                            desc: "Maximum vertical height of the spotlight launcher window"
                            value: AppLauncherConfig.spotlightHeight
                            minVal: 360
                            maxVal: 680
                            step: 10
                            unit: "px"
                            presets: [
                                { label: "420px", val: 420 },
                                { label: "480px (Default)", val: 480 },
                                { label: "540px", val: 540 },
                                { label: "600px", val: 600 }
                            ]
                            onValueModified: (val) => AppLauncherConfig.setSpotlightHeight(val)
                        }

                        RowDivider {}

                        // Default Mode Selector
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Default Opening Mode"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Initial tab active when spotlight launcher opens"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                /* Segmented Track matching SettingSliderRow style */
                                Rectangle {
                                    id: modeSegmentTrack
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                    implicitWidth: 260
                                    height: 32
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1

                                    readonly property int activeIdx: AppLauncherConfig.defaultMode === "command" ? 1 : 0
                                    readonly property real cellWidth: (width - 6 - 3) / 2

                                    /* Sliding Selection Pill */
                                    Rectangle {
                                        y: 3
                                        height: parent.height - 6
                                        width: modeSegmentTrack.cellWidth
                                        x: 3 + modeSegmentTrack.activeIdx * (modeSegmentTrack.cellWidth + 3)
                                        radius: 5
                                        color: root.theme.bgSelected
                                        border.color: root.theme.accentPrimary
                                        border.width: 1

                                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 3

                                        Repeater {
                                            model: [
                                                { id: "apps",    label: "Applications" },
                                                { id: "command", label: "Execute Command" }
                                            ]
                                            delegate: Rectangle {
                                                id: modeSegBtn
                                                required property var modelData
                                                required property int index
                                                readonly property bool isSel: modeSegmentTrack.activeIdx === modeSegBtn.index

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: !isSel && modeSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                                Behavior on color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: modeSegHover }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modeSegBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: modeSegBtn.isSel
                                                    color: modeSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                    opacity: modeSegBtn.isSel || modeSegHover.hovered ? 1.0 : 0.75
                                                    Behavior on color { ColorAnimation { duration: 140 } }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        AppLauncherConfig.setDefaultMode(modeSegBtn.modelData.id);
                                                        root.showToast("Default mode set to " + modeSegBtn.modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // AppGrid Menu Sizing Section
                    SectionCard {
                        title: "App Grid Menu Dimensions (Bar Popup)"
                        subtitle: "Configure the grid menu launched from the bar launcher button"
                        contentMargins: 8
                        contentSpacing: 0

                        SettingSliderRow {
                            title: "Grid Columns"
                            desc: "Number of horizontal app columns per row in AppGrid"
                            value: AppLauncherConfig.gridColumns
                            minVal: 3
                            maxVal: 8
                            step: 1
                            unit: ""
                            presets: [
                                { label: "4", val: 4 },
                                { label: "5 (Default)", val: 5 },
                                { label: "6", val: 6 },
                                { label: "7", val: 7 }
                            ]
                            onValueModified: (val) => AppLauncherConfig.setGridColumns(val)
                        }

                        RowDivider {}

                        SettingSliderRow {
                            title: "Cell Size"
                            desc: "Square dimensions of each application icon cell"
                            value: AppLauncherConfig.gridCellSize
                            minVal: 72
                            maxVal: 128
                            step: 4
                            unit: "px"
                            presets: [
                                { label: "80px (Compact)", val: 80 },
                                { label: "96px (Default)", val: 96 },
                                { label: "112px (Large)", val: 112 }
                            ]
                            onValueModified: (val) => AppLauncherConfig.setGridCellSize(val)
                        }
                    }
                }

                // =====================================================================
                // SUB-TAB 1: SEARCH & RANKING
                // =====================================================================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    visible: root.currentSubTab === 1

                    // Sorting Algorithm Section
                    SectionCard {
                        title: "Application Ranking & Sorting"
                        subtitle: "Determines how applications are ordered before entering a search term"
                        contentMargins: 10
                        contentSpacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: AppLauncherConfig.sortOptions
                                delegate: Rectangle {
                                    id: sortCard
                                    required property var modelData
                                    readonly property bool isSelected: AppLauncherConfig.sortMode === modelData.id

                                    Layout.fillWidth: true
                                    height: 52
                                    radius: 8
                                    color: isSelected
                                        ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.08))
                                        : (sortHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.04)) : root.theme.bgBase)
                                    border.color: isSelected ? root.theme.accentPrimary : root.theme.bgBorder
                                    border.width: isSelected ? 1.5 : 1

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    HoverHandler { id: sortHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            AppLauncherConfig.setSortMode(sortCard.modelData.id);
                                            root.showToast("Sorting set to " + sortCard.modelData.label);
                                        }
                                    }

                                    // Radio indicator circle anchored left
                                    Rectangle {
                                        id: radioCircle
                                        anchors.left: parent.left
                                        anchors.leftMargin: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "transparent"
                                        border.color: sortCard.isSelected ? root.theme.accentPrimary : root.theme.textMuted
                                        border.width: 1.5

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 10
                                            height: 10
                                            radius: 5
                                            color: root.theme.accentPrimary
                                            visible: sortCard.isSelected
                                        }
                                    }

                                    // Content Column explicitly anchored to radio circle
                                    Column {
                                        anchors.left: radioCircle.right
                                        anchors.leftMargin: 14
                                        anchors.right: parent.right
                                        anchors.rightMargin: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Text {
                                            width: parent.width
                                            text: sortCard.modelData.label
                                            font.family: root.font
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: sortCard.isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                                            horizontalAlignment: Text.AlignLeft
                                        }

                                        Text {
                                            width: parent.width
                                            text: sortCard.modelData.desc
                                            font.family: root.font
                                            font.pixelSize: 11
                                            color: root.theme.textMuted
                                            horizontalAlignment: Text.AlignLeft
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Search Match Scope Section
                    SectionCard {
                        title: "Search Matching Scope"
                        subtitle: "Control which metadata fields are evaluated during fuzzy search"
                        contentMargins: 8
                        contentSpacing: 0

                        SettingToggleRow {
                            title: "Match Generic App Names"
                            desc: "Allow searches like 'Browser', 'Terminal', 'Text Editor', or 'File Manager'"
                            checked: AppLauncherConfig.matchGenericName
                            onToggled: (val) => AppLauncherConfig.setMatchGenericName(val)
                        }

                        RowDivider {}

                        SettingToggleRow {
                            title: "Match Keywords"
                            desc: "Match developer tags and search keywords embedded in .desktop entries"
                            checked: AppLauncherConfig.matchKeywords
                            onToggled: (val) => AppLauncherConfig.setMatchKeywords(val)
                        }

                        RowDivider {}

                        SettingToggleRow {
                            title: "Match Categories"
                            desc: "Allow filtering by categories such as 'Development', 'Graphics', or 'AudioVideo'"
                            checked: AppLauncherConfig.matchCategories
                            onToggled: (val) => AppLauncherConfig.setMatchCategories(val)
                        }

                        RowDivider {}

                        SettingToggleRow {
                            title: "Clear Search Query on Close"
                            desc: "Reset search bar and return to default state when the launcher is closed"
                            checked: AppLauncherConfig.clearSearchOnClose
                            onToggled: (val) => AppLauncherConfig.setClearSearchOnClose(val)
                        }
                    }

                    // Actions & Cache Section
                    SectionCard {
                        title: "Actions & Cache Management"
                        subtitle: "Manage launch history and restore default launcher configurations"
                        contentMargins: 8
                        contentSpacing: 0

                        Item {
                            Layout.fillWidth: true
                            height: 52

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: clearHistBtn.left
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: "Clear App Launch History"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: "Wipe all recorded application launch counts and timestamps in ~/.cache/qs_app_usage.json"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textMuted
                                    elide: Text.ElideRight
                                }
                            }

                            ActionButton {
                                id: clearHistBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                label: "Clear History"
                                danger: true
                                btnHeight: 30
                                onClicked: AppLauncherConfig.clearAppUsage()
                            }
                        }

                        RowDivider {}

                        Item {
                            Layout.fillWidth: true
                            height: 52

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: resetDefaultsBtn.left
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: "Reset All Launcher Settings"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: "Revert dimensions, sorting, search scopes, and exclusions to default values"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textMuted
                                    elide: Text.ElideRight
                                }
                            }

                            ActionButton {
                                id: resetDefaultsBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                label: "Reset Defaults"
                                btnHeight: 30
                                onClicked: {
                                    AppLauncherConfig.resetDefaults();
                                    root.showToast("App Launcher reset to default settings");
                                }
                            }
                        }
                    }
                }

                // =====================================================================
                // SUB-TAB 2: APPLICATIONS & VISIBILITY
                // =====================================================================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    visible: root.currentSubTab === 2

                    SectionCard {
                        title: "Manage Installed Applications"
                        subtitle: root.totalAppCount + " total apps • " + root.favoriteCount + " favorites • " + root.hiddenCount + " hidden"
                        contentMargins: 12
                        contentSpacing: 10

                        // Search & Filter Bar
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // Search Input Box
                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: 7
                                color: root.theme.bgBase
                                border.color: appSearchInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: "󰍉"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        color: appSearchInput.activeFocus ? root.theme.accentPrimary : root.theme.textMuted
                                    }

                                    TextInput {
                                        id: appSearchInput
                                        Layout.fillWidth: true
                                        font.family: root.font
                                        font.pixelSize: 12
                                        color: root.theme.textPrimary
                                        clip: true
                                        selectByMouse: true
                                        text: root.appSearchQuery
                                        onTextChanged: root.appSearchQuery = text

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: !parent.text && !parent.activeFocus
                                            text: "Filter applications by name, class, or generic tag..."
                                            font.family: root.font
                                            font.pixelSize: 12
                                            color: root.theme.textMuted
                                        }
                                    }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: clearSearchHover.hovered ? root.theme.bgHover : "transparent"
                                        visible: appSearchInput.text.length > 0

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            color: root.theme.textSecondary
                                        }

                                        HoverHandler { id: clearSearchHover }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: appSearchInput.text = ""
                                        }
                                    }
                                }
                            }

                            // Filter Segmented Track: All / Favorites / Hidden
                            Rectangle {
                                id: appFilterSegmentTrack
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: 290
                                height: 36
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1

                                readonly property var filterModes: ["all", "favorites", "hidden"]
                                readonly property int activeIdx: Math.max(0, filterModes.indexOf(root.appFilterMode))
                                readonly property real cellWidth: (width - 6 - 2 * 3) / 3

                                /* Sliding Selection Pill */
                                Rectangle {
                                    y: 3
                                    height: parent.height - 6
                                    width: appFilterSegmentTrack.cellWidth
                                    x: 3 + appFilterSegmentTrack.activeIdx * (appFilterSegmentTrack.cellWidth + 3)
                                    radius: 5
                                    color: root.theme.bgSelected
                                    border.color: root.theme.accentPrimary
                                    border.width: 1

                                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    spacing: 3

                                    Repeater {
                                        model: [
                                            { id: "all",       label: "All (" + root.totalAppCount + ")" },
                                            { id: "favorites", label: "Favorites (" + root.favoriteCount + ")" },
                                            { id: "hidden",    label: "Hidden (" + root.hiddenCount + ")" }
                                        ]
                                        delegate: Rectangle {
                                            id: filterSegBtn
                                            required property var modelData
                                            required property int index
                                            readonly property bool isSel: appFilterSegmentTrack.activeIdx === filterSegBtn.index

                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: !isSel && filterSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                            Behavior on color { ColorAnimation { duration: 140 } }

                                            HoverHandler { id: filterSegHover }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.appFilterMode = filterSegBtn.modelData.id
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: filterSegBtn.modelData.label
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: filterSegBtn.isSel
                                                color: filterSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                opacity: filterSegBtn.isSel || filterSegHover.hovered ? 1.0 : 0.75
                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                Behavior on opacity { NumberAnimation { duration: 140 } }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // App List View Box
                        Rectangle {
                            Layout.fillWidth: true
                            height: 440
                            radius: 8
                            color: root.theme.bgBase
                            border.color: root.theme.bgBorder
                            border.width: 1
                            clip: true

                            ListView {
                                id: appListView
                                anchors.fill: parent
                                anchors.margins: 4
                                model: root.filteredAppsList
                                spacing: 2
                                boundsBehavior: Flickable.StopAtBounds

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    contentItem: Rectangle {
                                        implicitWidth: 4
                                        radius: 2
                                        color: root.theme.bgBorder
                                    }
                                }

                                // Empty state placeholder
                                Item {
                                    anchors.centerIn: parent
                                    visible: appListView.count === 0
                                    width: 260
                                    height: 100

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: "󰀻"
                                            font.family: root.font
                                            font.pixelSize: 32
                                            color: root.theme.textMuted
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: root.appSearchQuery ? "No applications found" : "No applications in this category"
                                            font.family: root.font
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: root.theme.textSecondary
                                        }
                                    }
                                }

                                delegate: Rectangle {
                                    id: appRowItem
                                    required property var modelData
                                    readonly property string appKey: root.getAppKey(modelData)
                                    readonly property bool isFav: AppLauncherConfig.isAppFavorite(appKey)
                                    readonly property bool isHid: AppLauncherConfig.isAppHidden(appKey)

                                    width: appListView.width - 8
                                    height: 48
                                    radius: 6
                                    color: appRowHover.hovered ? root.theme.bgHover : "transparent"
                                    opacity: isHid ? 0.55 : 1.0

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on opacity { NumberAnimation { duration: 140 } }

                                    HoverHandler { id: appRowHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        // App Icon
                                        Rectangle {
                                            id: appIconBox
                                            width: 32
                                            height: 32
                                            radius: 6
                                            color: root.theme.bgSurface
                                            border.color: root.theme.bgBorder
                                            border.width: 1
                                            Layout.alignment: Qt.AlignVCenter

                                            readonly property string resolvedIcon: {
                                                const raw = (appRowItem.modelData && appRowItem.modelData.icon) ? appRowItem.modelData.icon : "";
                                                if (raw) {
                                                    const p = Quickshell.iconPath(raw, true);
                                                    if (p) return p;
                                                }
                                                return Quickshell.iconPath("application-x-executable", true);
                                            }

                                            IconImage {
                                                anchors.centerIn: parent
                                                implicitSize: 22
                                                source: appIconBox.resolvedIcon
                                                visible: appIconBox.resolvedIcon !== ""
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰀻"
                                                font.family: root.font
                                                font.pixelSize: 16
                                                color: root.theme.accentPrimary
                                                visible: appIconBox.resolvedIcon === ""
                                            }
                                        }

                                        // App Titles
                                        ColumnLayout {
                                            spacing: 1
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter

                                            RowLayout {
                                                Layout.alignment: Qt.AlignLeft
                                                spacing: 6
                                                Text {
                                                    text: (appRowItem.modelData && appRowItem.modelData.name) ? appRowItem.modelData.name : "Unknown Application"
                                                    font.family: root.font
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    color: isHid ? root.theme.textMuted : root.theme.textPrimary
                                                }

                                                // Favorite Badge
                                                Rectangle {
                                                    visible: appRowItem.isFav
                                                    implicitWidth: 16
                                                    implicitHeight: 16
                                                    radius: 8
                                                    color: Qt.rgba(1, 0.8, 0.2, 0.15)
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "󰓎"
                                                        font.family: root.font
                                                        font.pixelSize: 10
                                                        color: root.theme.accentOrange
                                                    }
                                                }

                                                // Hidden Badge
                                                Rectangle {
                                                    visible: appRowItem.isHid
                                                    implicitWidth: hiddenBadgeText.implicitWidth + 8
                                                    implicitHeight: 16
                                                    radius: 4
                                                    color: Qt.rgba(0.9, 0.3, 0.3, 0.15)
                                                    Text {
                                                        id: hiddenBadgeText
                                                        anchors.centerIn: parent
                                                        text: "Hidden"
                                                        font.family: root.font
                                                        font.pixelSize: 9
                                                        font.bold: true
                                                        color: root.theme.accentRed
                                                    }
                                                }
                                            }

                                            Text {
                                                text: {
                                                    let sub = (appRowItem.modelData && appRowItem.modelData.genericName) ? appRowItem.modelData.genericName : "";
                                                    if (!sub && appRowItem.appKey) sub = appRowItem.appKey;
                                                    return sub;
                                                }
                                                font.family: root.font
                                                font.pixelSize: 11
                                                color: root.theme.textMuted
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        // Action Buttons: Favorite Star & Hide Eye
                                        RowLayout {
                                            spacing: 6
                                            Layout.alignment: Qt.AlignVCenter

                                            // Toggle Favorite Button
                                            Rectangle {
                                                width: 30
                                                height: 30
                                                radius: 6
                                                color: appRowItem.isFav
                                                    ? Qt.rgba(1, 0.8, 0.2, 0.2)
                                                    : (favHover.hovered ? root.theme.bgSurface : "transparent")
                                                border.color: appRowItem.isFav ? root.theme.accentOrange : (favHover.hovered ? root.theme.bgBorder : "transparent")
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 120 } }

                                                HoverHandler { id: favHover }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        AppLauncherConfig.toggleFavoriteApp(appRowItem.appKey);
                                                        const isNowFav = AppLauncherConfig.isAppFavorite(appRowItem.appKey);
                                                        const appName = (appRowItem.modelData && appRowItem.modelData.name) ? appRowItem.modelData.name : "Application";
                                                        root.showToast(isNowFav ? (appName + " pinned to favorites") : (appName + " unpinned from favorites"));
                                                    }
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: appRowItem.isFav ? "󰓎" : "󰤱"
                                                    font.family: root.font
                                                    font.pixelSize: 14
                                                    color: appRowItem.isFav ? root.theme.accentOrange : (favHover.hovered ? root.theme.textPrimary : root.theme.textMuted)
                                                }
                                            }

                                            // Toggle Hide/Unhide Button
                                            Rectangle {
                                                width: 30
                                                height: 30
                                                radius: 6
                                                color: appRowItem.isHid
                                                    ? Qt.rgba(0.9, 0.3, 0.3, 0.15)
                                                    : (hidHover.hovered ? root.theme.bgSurface : "transparent")
                                                border.color: appRowItem.isHid ? root.theme.accentRed : (hidHover.hovered ? root.theme.bgBorder : "transparent")
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 120 } }

                                                HoverHandler { id: hidHover }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        AppLauncherConfig.toggleHiddenApp(appRowItem.appKey);
                                                        const isNowHidden = AppLauncherConfig.isAppHidden(appRowItem.appKey);
                                                        const appName = (appRowItem.modelData && appRowItem.modelData.name) ? appRowItem.modelData.name : "Application";
                                                        root.showToast(isNowHidden ? (appName + " hidden from launcher") : (appName + " restored to launcher"));
                                                    }
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: appRowItem.isHid ? "󰈈" : "󰈉"
                                                    font.family: root.font
                                                    font.pixelSize: 14
                                                    color: appRowItem.isHid ? root.theme.accentRed : (hidHover.hovered ? root.theme.textPrimary : root.theme.textMuted)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /* Feedback Toast (Bottom floating notification strictly matching HyprlandSettings) */
    ToastBanner {
        id: toastBanner
        theme: root.theme
        font: root.font
    }
}
