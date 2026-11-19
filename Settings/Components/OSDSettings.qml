/*
 * OSDSettings.qml
 *
 * Configures On-Screen Display (OSD) overlay placement, screen position,
 * orientation (adaptive horizontal vs vertical), tactile seekbar X/Y positioning,
 * and live interactive monitor previews with drag-to-position.
 * Powered natively by OSDService singleton.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../osd"
import ".."
import "./OSD"
import "./Common"

Item {
    id: root
    property var theme
    property string font

    readonly property string osdPos: OSDService.position || "right"
    readonly property int marginX: OSDService.marginX
    readonly property int marginY: OSDService.marginY
    readonly property int timeoutMs: OSDService.timeoutMs
    readonly property bool isCustomized: osdPos !== "right" || OSDService.orientation !== "auto" || marginX !== 16 || marginY !== 0 || timeoutMs !== 1500

    readonly property int btnHeight: 32
    readonly property int btnRadius: 6
    readonly property int actionBtnWidth: 84

    readonly property var currentScreen: Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property int screenW: currentScreen && currentScreen.width > 0 ? currentScreen.width : 1920
    readonly property int screenH: currentScreen && currentScreen.height > 0 ? currentScreen.height : 1080

    // Full screen-span ranges:
    // When centered or top/bottom: horizontal range from center all the way to left/right edge
    readonly property int maxCenterOffsetX: Math.max(300, Math.round((screenW - 240) / 2) - 16)
    // When centered or left/right: vertical range from center all the way to top/bottom edge
    readonly property int maxCenterOffsetY: Math.max(300, Math.round((screenH - 200) / 2) - 16)
    // When left/right: edge margin range from edge inward towards screen center
    readonly property int maxEdgeMarginX: Math.max(300, Math.round(screenW / 2) - 120)
    // When top/bottom: edge margin range from edge inward towards screen center
    readonly property int maxEdgeMarginY: Math.max(250, Math.round(screenH / 2) - 60)

    readonly property bool isEdgeX: osdPos === "left" || osdPos === "right"
    readonly property int minValX: isEdgeX ? 0 : -maxCenterOffsetX
    readonly property int maxValX: isEdgeX ? maxEdgeMarginX : maxCenterOffsetX

    readonly property bool isEdgeY: osdPos === "top" || osdPos === "bottom"
    readonly property int minValY: isEdgeY ? 0 : -maxCenterOffsetY
    readonly property int maxValY: isEdgeY ? maxEdgeMarginY : maxCenterOffsetY

    // Helper to interactively place OSD from preview coordinates
    function handlePreviewDrag(px, py, w, h) {
        if (w <= 0 || h <= 0) return;
        const pos = root.osdPos;
        const isHoriz = OSDService.isHorizontal;
        const pillW = isHoriz ? 58 : 16;
        const pillH = isHoriz ? 16 : 58;

        const maxShiftX = (w - pillW) / 2 - 8;
        const maxShiftY = (h - pillH) / 2 - 12;

        if (pos === "bottom") {
            const fracX = Math.max(-1, Math.min(1, (px - (w / 2)) / (maxShiftX > 0 ? maxShiftX : (w / 2))));
            const valX = Math.round(fracX * root.maxCenterOffsetX);
            const distFromBottom = (h - pillH - 10) - py;
            const fracY = Math.max(0, Math.min(1, distFromBottom / (h / 2)));
            const valY = Math.round(fracY * root.maxValY);
            OSDService.setMarginX(valX);
            OSDService.setMarginY(valY);
        } else if (pos === "top") {
            const fracX = Math.max(-1, Math.min(1, (px - (w / 2)) / (maxShiftX > 0 ? maxShiftX : (w / 2))));
            const valX = Math.round(fracX * root.maxCenterOffsetX);
            const distFromTop = py - 20;
            const fracY = Math.max(0, Math.min(1, distFromTop / (h / 2)));
            const valY = Math.round(fracY * root.maxValY);
            OSDService.setMarginX(valX);
            OSDService.setMarginY(valY);
        } else if (pos === "left") {
            const distFromLeft = px - 10;
            const fracX = Math.max(0, Math.min(1, distFromLeft / (w / 2)));
            const valX = Math.round(fracX * root.maxValX);
            const fracY = Math.max(-1, Math.min(1, (py - (h / 2)) / (maxShiftY > 0 ? maxShiftY : (h / 2))));
            const valY = Math.round(fracY * root.maxCenterOffsetY);
            OSDService.setMarginX(valX);
            OSDService.setMarginY(valY);
        } else if (pos === "right") {
            const distFromRight = (w - pillW - 10) - px;
            const fracX = Math.max(0, Math.min(1, distFromRight / (w / 2)));
            const valX = Math.round(fracX * root.maxValX);
            const fracY = Math.max(-1, Math.min(1, (py - (h / 2)) / (maxShiftY > 0 ? maxShiftY : (h / 2))));
            const valY = Math.round(fracY * root.maxCenterOffsetY);
            OSDService.setMarginX(valX);
            OSDService.setMarginY(valY);
        } else {
            // center
            const fracX = Math.max(-1, Math.min(1, (px - (w / 2)) / (maxShiftX > 0 ? maxShiftX : (w / 2))));
            const valX = Math.round(fracX * root.maxCenterOffsetX);
            const fracY = Math.max(-1, Math.min(1, (py - (h / 2)) / (maxShiftY > 0 ? maxShiftY : (h / 2))));
            const valY = Math.round(fracY * root.maxCenterOffsetY);
            OSDService.setMarginX(valX);
            OSDService.setMarginY(valY);
        }
        OSDService.testOSD();
    }

    /* Main Scrollable View */
    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !(oSDPlacementTimingInst.marginXMouseRef && oSDPlacementTimingInst.marginXMouseRef.pressed) && !(oSDPlacementTimingInst.marginYMouseRef && oSDPlacementTimingInst.marginYMouseRef.pressed) && !(oSDPlacementTimingInst.timeoutMouseRef && oSDPlacementTimingInst.timeoutMouseRef.pressed)

        ScrollBar.vertical: ScrollBar {
            id: vertScroll
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15)
            }
        }

        ColumnLayout {
            id: mainCol
            width: mainFlickable.width - (vertScroll.visible ? 12 : 0)
            spacing: 20

            /* Page Title & Subtitle */
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                    Text {
                        text: "On-Screen Display"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                }

                Item { Layout.fillWidth: true }

                Process {
                    id: openBackupProc
                    command: ["qs", "ipc", "call", "settings", "open", "backup"]
                    running: false
                }

                ActionButton {
                    iconText: "󰁯"
                    label: "Backup & Restore"
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    onClicked: openBackupProc.running = true
                }
            }

            // 1. GENERAL ACTIONS GROUP
            OSDGeneralSection {
                root: root
            }

            // 2. SCREEN POSITION & PREVIEW GROUP
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 8

                    Text {
                        text: "Screen Position & Placement"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    Text {
                        text: "Active: " + OSDService.getPositionLabel(root.osdPos)
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentPrimary
                    }
                }

                OSDPositionPreviewCard {
                    root: root
                }
            }

            // 3. ORIENTATION & SHAPE GROUP
            OSDOrientationShape {
                root: root
            }

            // 4. TACTILE X/Y PLACEMENT & TIMING GROUP
            OSDPlacementTiming {
                id: oSDPlacementTimingInst
                root: root
            }
        }
    }
}
