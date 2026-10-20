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
        interactive: !desktopMouse.pressed && !oSDPlacementTimingInst.marginXMouseRef.pressed && !oSDPlacementTimingInst.marginYMouseRef.pressed && !oSDPlacementTimingInst.timeoutMouseRef.pressed

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15)
            }
        }

        ColumnLayout {
            id: mainCol
            width: parent.width - 10
            spacing: 20

            /* Page Title & Subtitle */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "On-Screen Display"
                    font.family: root.font
                    font.pixelSize: 20
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Text {
                    text: "Customize volume and brightness overlay positioning, adaptive orientation, live X/Y placement, and timing"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textSecondary
                }
            }

            /* ========================================================= */
            /* 1. GENERAL ACTIONS GROUP                                   */
            /* ========================================================= */
            OSDGeneralSection {
                root: root
            }

            /* ========================================================= */
            /* 2. SCREEN POSITION & PREVIEW GROUP                         */
            /* ========================================================= */
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
                        text: "· Drag preview pill or click regions to reposition in X & Y"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Active: " + OSDService.getPositionLabel(root.osdPos)
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentPrimary
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: posCol.implicitHeight + 24
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: posCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 12
                        }
                        spacing: 14

                        /* Interactive Screen Preview Canvas with Live Dragging */
                        Rectangle {
                            id: monitorPreview
                            Layout.fillWidth: true
                            height: 180
                            radius: 10
                            color: root.theme.bgBase ?? Qt.rgba(0,0,0,0.3)
                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1
                            clip: true

                            /* Desktop frame container */
                            Rectangle {
                                id: desktopArea
                                anchors.fill: parent
                                anchors.margins: 6
                                radius: 7
                                color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.03)
                                border.color: Qt.rgba(1, 1, 1, 0.04)
                                border.width: 1
                                clip: true

                                /* Top Bar representation */
                                Rectangle {
                                    id: previewTopBar
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 14
                                    color: Qt.rgba(1, 1, 1, 0.05)
                                    border.color: Qt.rgba(1, 1, 1, 0.06)
                                    border.width: 1
                                    z: 2

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8

                                        Rectangle { width: 14; height: 3; radius: 1.5; color: Qt.rgba(1, 1, 1, 0.12) }
                                        Item { Layout.fillWidth: true }
                                        Rectangle { width: 20; height: 3; radius: 1.5; color: Qt.rgba(1, 1, 1, 0.12) }
                                    }
                                }

                                /* Click & Drag Area for Interactive Placement */
                                MouseArea {
                                    id: desktopMouse
                                    anchors.fill: parent
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: (mouse) => {
                                        mouse.accepted = true;
                                        root.handlePreviewDrag(mouse.x, mouse.y, width, height);
                                    }
                                    onPositionChanged: (mouse) => {
                                        if (pressed) {
                                            mouse.accepted = true;
                                            root.handlePreviewDrag(mouse.x, mouse.y, width, height);
                                        }
                                    }
                                }

                                /* Simulated OSD Pill reflecting exact orientation and X/Y offset */
                                Rectangle {
                                    id: previewOsdPill
                                    readonly property bool isHoriz: OSDService.isHorizontal
                                    width: isHoriz ? 58 : 16
                                    height: isHoriz ? 16 : 58
                                    radius: 8
                                    color: root.theme.accentPrimary
                                    border.color: "#ffffff"
                                    border.width: 1.5
                                    z: 10

                                    // Mathematical coordinate placement responding to X & Y
                                    x: {
                                        if (root.osdPos === "left") {
                                            const frac = root.maxValX > 0 ? Math.max(0, Math.min(1, root.marginX / root.maxValX)) : 0;
                                            return Math.max(8, Math.min(desktopArea.width - width - 8, 10 + Math.round(frac * (desktopArea.width / 2))));
                                        } else if (root.osdPos === "right") {
                                            const frac = root.maxValX > 0 ? Math.max(0, Math.min(1, root.marginX / root.maxValX)) : 0;
                                            return Math.max(8, Math.min(desktopArea.width - width - 8, desktopArea.width - width - 10 - Math.round(frac * (desktopArea.width / 2))));
                                        } else {
                                            // center, top, bottom: slider goes from -maxCenterOffsetX to +maxCenterOffsetX
                                            const frac = root.maxCenterOffsetX > 0 ? Math.max(-1, Math.min(1, root.marginX / root.maxCenterOffsetX)) : 0;
                                            const maxShift = (desktopArea.width - width) / 2 - 8;
                                            return Math.max(8, Math.min(desktopArea.width - width - 8, Math.round((desktopArea.width - width) / 2 + frac * maxShift)));
                                        }
                                    }

                                    y: {
                                        if (root.osdPos === "top") {
                                            const frac = root.maxValY > 0 ? Math.max(0, Math.min(1, root.marginY / root.maxValY)) : 0;
                                            return Math.max(18, Math.min(desktopArea.height - height - 8, 20 + Math.round(frac * (desktopArea.height / 2))));
                                        } else if (root.osdPos === "bottom") {
                                            const frac = root.maxValY > 0 ? Math.max(0, Math.min(1, root.marginY / root.maxValY)) : 0;
                                            return Math.max(18, Math.min(desktopArea.height - height - 8, desktopArea.height - height - 10 - Math.round(frac * (desktopArea.height / 2))));
                                        } else {
                                            // center, left, right: slider goes from -maxCenterOffsetY to +maxCenterOffsetY
                                            const frac = root.maxCenterOffsetY > 0 ? Math.max(-1, Math.min(1, root.marginY / root.maxCenterOffsetY)) : 0;
                                            const maxShift = (desktopArea.height - height) / 2 - 12;
                                            return Math.max(18, Math.min(desktopArea.height - height - 8, Math.round((desktopArea.height - height) / 2 + frac * maxShift)));
                                        }
                                    }

                                    Behavior on x {
                                        enabled: !desktopMouse.pressed
                                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on y {
                                        enabled: !desktopMouse.pressed
                                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                    // Horizontal preview layout
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 4
                                        anchors.rightMargin: 4
                                        spacing: 3
                                        visible: previewOsdPill.isHoriz

                                        Rectangle {
                                            width: 5
                                            height: 5
                                            radius: 2.5
                                            color: "#ffffff"
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 3
                                            radius: 1.5
                                            color: Qt.rgba(0, 0, 0, 0.35)

                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                width: parent.width * 0.7
                                                radius: 1.5
                                                color: "#ffffff"
                                            }
                                        }
                                    }

                                    // Vertical preview layout
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.topMargin: 4
                                        anchors.bottomMargin: 4
                                        spacing: 3
                                        visible: !previewOsdPill.isHoriz

                                        Rectangle {
                                            Layout.fillHeight: true
                                            width: 3
                                            radius: 1.5
                                            color: Qt.rgba(0, 0, 0, 0.35)
                                            Layout.alignment: Qt.AlignHCenter

                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                height: parent.height * 0.7
                                                radius: 1.5
                                                color: "#ffffff"
                                            }
                                        }

                                        Rectangle {
                                            width: 5
                                            height: 5
                                            radius: 2.5
                                            color: "#ffffff"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }

                        /* Position Segmented Pill Track */
                        Rectangle {
                            id: posSegmentTrack
                            Layout.fillWidth: true
                            height: 34
                            radius: 7
                            color: root.theme.bgBase
                            border.color: root.theme.bgBorder
                            border.width: 1

                            readonly property var posList: ["left", "center", "right", "top", "bottom"]
                            readonly property int activePosIndex: {
                                const idx = posList.indexOf(root.osdPos);
                                return idx !== -1 ? idx : 2;
                            }
                            readonly property real cellWidth: (width - 6 - (4 * 4)) / 5

                            // Animated sliding indicator
                            Rectangle {
                                y: 3
                                height: parent.height - 6
                                width: posSegmentTrack.cellWidth
                                x: 3 + posSegmentTrack.activePosIndex * (posSegmentTrack.cellWidth + 4)
                                radius: 5
                                color: root.theme.bgSelected
                                border.color: root.theme.accentPrimary
                                border.width: 1

                                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 4

                                Repeater {
                                    model: OSDService.positionOptions

                                    delegate: Rectangle {
                                        id: posSegBtn
                                        required property var modelData
                                        readonly property bool isSel: root.osdPos === modelData.id

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 5
                                        color: !isSel && posSegHover.hovered ? root.theme.bgHover : "transparent"
                                        Behavior on color { ColorAnimation { duration: 140 } }

                                        HoverHandler { id: posSegHover }

                                        Text {
                                            anchors.centerIn: parent
                                            text: posSegBtn.modelData.label
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: posSegBtn.isSel
                                            color: posSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                            opacity: posSegBtn.isSel || posSegHover.hovered ? 1.0 : 0.75
                                            Behavior on color { ColorAnimation { duration: 140 } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                OSDService.setPosition(posSegBtn.modelData.id);
                                                OSDService.testOSD();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* ========================================================= */
            /* 3. ORIENTATION & SHAPE GROUP                               */
            /* ========================================================= */
            OSDOrientationShape {
                root: root
            }

            /* ========================================================= */
            /* 4. TACTILE X/Y PLACEMENT & TIMING GROUP                   */
            /* ========================================================= */
            OSDPlacementTiming {
                id: oSDPlacementTimingInst
                root: root
            }
        }
    }
}
