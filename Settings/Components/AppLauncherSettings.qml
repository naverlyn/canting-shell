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
import "./AppLauncher"

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

                AppLauncherLayoutTab { root: root }
                AppLauncherSearchTab { root: root }
                AppLauncherAppsTab { root: root }
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
