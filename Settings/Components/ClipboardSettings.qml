/*
 * ClipboardSettings.qml
 *
 * Comprehensive Clipboard History & Daemon Configuration for Quickshell Settings.
 * Supports:
 *   - Layout & Dimensions (Popup window width & height, live interactive preview)
 *   - History Capacity & Behavior (Max items, close on copy, search clearing, auto-paste)
 *   - Content Detection (Thumbnails, Hex color swatches, URLs, Code syntax recognition)
 *   - Daemon & Service Management (cliphist store watcher status, 1-click start/stop, cache wipe)
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../../Clipboard"
import "./Clipboard"
import "Common"

Item {
    id: root

    property var theme
    property string font: Style.font

    /* Sub-tabs: 0: Layout & Sizing, 1: History & Behavior, 2: Daemon & Services */
    property int currentSubTab: 0

    /* Daemon status & stats */
    property bool daemonRunning: false
    property int totalStoredItems: 0
    property string dbSizeFormatted: "0 B"
    property int thumbsCount: 0
    property bool statusLoading: false

    function showToast(msg, isWarn) {
        toastBanner.show(msg, isWarn);
    }

    readonly property string serviceScript: ClipboardConfig.serviceScript

    /* Process runner for status query */
    Process {
        id: statusProc
        command: ["python3", root.serviceScript, "status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.statusLoading = false;
                try {
                    const data = JSON.parse(text);
                    if (data.success) {
                        root.daemonRunning = Boolean(data.daemonRunning);
                        root.totalStoredItems = Number(data.totalItems) || 0;
                        root.dbSizeFormatted = data.dbSizeFormatted || "0 B";
                        root.thumbsCount = Number(data.thumbsCount) || 0;
                    }
                } catch(e) {
                    console.error("Failed to parse clip_service status:", e);
                }
            }
        }
    }

    /* Process runner for daemon actions */
    Process {
        id: daemonActionProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.queryStatus();
            }
        }
    }

    function queryStatus() {
        if (!statusProc.running) {
            root.statusLoading = true;
            statusProc.running = true;
        }
    }

    function startDaemon() {
        daemonActionProc.command = ["python3", root.serviceScript, "start_daemon"];
        daemonActionProc.running = true;
        root.showToast("Starting clipboard watcher daemon...");
    }

    function stopDaemon() {
        daemonActionProc.command = ["python3", root.serviceScript, "stop_daemon"];
        daemonActionProc.running = true;
        root.showToast("Stopping clipboard watcher daemon...");
    }

    function wipeHistory() {
        ClipboardService.wipeAll();
        root.showToast("All clipboard history wiped");
        root.queryStatus();
    }

    function testCopy() {
        const testStr = "Quickshell Clipboard Test @" + new Date().toLocaleTimeString();
        testCopyProc.command = ["wl-copy", testStr];
        testCopyProc.running = true;
        root.showToast("Copied test snippet to clipboard");
        ClipboardService.refresh();
        root.queryStatus();
    }

    Process {
        id: testCopyProc
        running: false
    }

    Component.onCompleted: {
        root.queryStatus();
    }

    Connections {
        target: ClipboardConfig
        function onHistoryWiped() {
            root.queryStatus();
        }
    }

    /* ---- Main Scrollable Content ---- */
    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 40
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: vertScroll
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.15)
            }
        }

        ColumnLayout {
            id: mainCol
            width: flickable.width - (vertScroll.visible ? 12 : 0)
            spacing: 20

            // Header Section
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                Text {
                    text: "Clipboard Manager"
                    font.family: root.font
                    font.pixelSize: 20
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Configure clipboard history capacity, content detection, window dimensions, and daemon status"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textSecondary
                }
            }

            /* Sub-Tab Switch Transition Animation (Matching HyprlandSettings) */
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
                color: (root.theme && root.theme.bgSurface) ? root.theme.bgSurface : Qt.rgba(1, 1, 1, 0.04)
                border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Repeater {
                        model: [
                            { idx: 0, icon: "󰍉", label: "Layout & Sizing" },
                            { idx: 1, icon: "󰋚", label: "History & Behavior" },
                            { idx: 2, icon: "󰒲", label: "Daemon & Services" }
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
                                color: subTabItem.isCurrent
                                    ? (root.theme.accentPrimary)
                                    : (root.theme.textSecondary)

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
                                        ? (root.theme.accentPrimary)
                                        : (subTabHover.hovered
                                            ? (root.theme.textPrimary)
                                            : (root.theme.textSecondary))
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: subTabItem.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: subTabItem.isCurrent
                                    color: subTabItem.isCurrent
                                        ? (root.theme.accentPrimary)
                                        : (subTabHover.hovered
                                            ? (root.theme.textPrimary)
                                            : (root.theme.textSecondary))
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

            ClipboardLayoutTab { root: root }
            ClipboardHistoryTab { root: root }
            ClipboardDaemonTab { root: root }
            }
        }
    }

    // =========================================================================
    // FLOATING TOAST
    // =========================================================================
    ToastBanner {
        id: toastBanner
        theme: root.theme
        font: root.font
    }
}

