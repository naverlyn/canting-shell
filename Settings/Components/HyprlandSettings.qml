/*
 * HyprlandSettings.qml
 *
 * Comprehensive Hyprland Compositor & Variables Configuration for Quickshell Settings.
 * Supports:
 *   - General & Layout (Inner/Outer gaps, Border width, Dwindle vs Master layout, Resize on border, Snapping)
 *   - Window Decoration (Corner rounding, Active/Inactive opacity, Dimming, Blur passes/size, Drop shadows)
 *   - Gestures & Touchpad (Workspace swipe, Fingers, Invert, Distance, Forever loop)
 *   - Misc & Compositor (VRR / Adaptive sync, VFR variable frame rate, DPMS wake, Middle-click paste, Cursors)
 *   - Real-time interactive preview canvas reflecting window gaps, borders, and rounding
 *   - Live hyprctl keyword application with persistence into ~/.config/hypr/UserConfigs/
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."
import "./Common"
import "./Hyprland"

Item {
    id: root
    property var theme
    property string font: "Hack Nerd Font"

    /* Sub-tabs: 0: General & Layout, 1: Window Decoration, 2: Gestures & Touchpad, 3: Misc & Compositor */
    property int currentSubTab: 0

    /* Loading & Script path */
    property bool isLoading: true
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/manage_hyprland.sh").toString().replace(/^file:\/\//, "")

    /* ---- General State ---- */
    property int generalGapsIn: 2
    property int generalGapsOut: 4
    property int generalBorderSize: 0
    property string generalLayout: "dwindle"
    property bool generalResizeOnBorder: true
    property bool generalAllowTearing: false
    property bool generalSnapEnabled: false
    property int generalSnapWindowGap: 10

    /* ---- Decoration State ---- */
    property int decorRounding: 10
    property real decorActiveOpacity: 1.0
    property real decorInactiveOpacity: 0.9
    property bool decorDimInactive: true
    property real decorDimStrength: 0.1
    property bool decorBlurEnabled: true
    property int decorBlurSize: 6
    property int decorBlurPasses: 3
    property bool decorBlurPopups: true
    property bool decorBlurXray: true
    property bool decorShadowEnabled: false
    property int decorShadowRange: 3
    property int decorShadowRenderPower: 1

    /* ---- Gestures State ---- */
    property bool gesturesWorkspaceSwipe: true
    property int gesturesWorkspaceSwipeFingers: 3
    property int gesturesWorkspaceSwipeDistance: 300
    property bool gesturesWorkspaceSwipeInvert: true
    property bool gesturesWorkspaceSwipeForever: true

    /* ---- Misc State ---- */
    property int miscVrr: 2
    property bool miscVfr: true
    property bool miscDisableLogo: true
    property bool miscDisableSplash: true
    property bool miscMouseMoveDpms: true
    property bool miscMiddleClickPaste: false
    property int miscNoHardwareCursors: 2

    /* Toast notification state */
    property string toastMessage: ""
    property bool toastVisible: false

    Timer {
        id: toastTimer
        interval: 2500
        repeat: false
        onTriggered: root.toastVisible = false
    }

    Connections {
        target: Style
        function onToast(msg) { root.showToast(msg); }
    }

    function showToast(msg) {
        root.toastMessage = msg;
        root.toastVisible = true;
        toastTimer.restart();
    }

    /* Helper: Set variable via manage_hyprland.sh */
    function setHyprVar(section, key, val) {
        if (root.isLoading) return;
        setVarProc.command = [root.scriptPath, "set", section, key, String(val)];
        setVarProc.running = true;
    }

    /* Query process */
    Process {
        id: loadStateProc
        command: [root.scriptPath, "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data) {
                        root.isLoading = true;
                        if (data.general) {
                            if (data.general.gaps_in !== undefined) root.generalGapsIn = data.general.gaps_in;
                            if (data.general.gaps_out !== undefined) root.generalGapsOut = data.general.gaps_out;
                            if (data.general.border_size !== undefined) root.generalBorderSize = data.general.border_size;
                            if (data.general.layout !== undefined) root.generalLayout = data.general.layout;
                            if (data.general.resize_on_border !== undefined) root.generalResizeOnBorder = data.general.resize_on_border;
                            if (data.general.allow_tearing !== undefined) root.generalAllowTearing = data.general.allow_tearing;
                            if (data.general.snap_enabled !== undefined) root.generalSnapEnabled = data.general.snap_enabled;
                            if (data.general.snap_window_gap !== undefined) root.generalSnapWindowGap = data.general.snap_window_gap;
                        }
                        if (data.decoration) {
                            if (data.decoration.rounding !== undefined) root.decorRounding = data.decoration.rounding;
                            if (data.decoration.active_opacity !== undefined) root.decorActiveOpacity = data.decoration.active_opacity;
                            if (data.decoration.inactive_opacity !== undefined) root.decorInactiveOpacity = data.decoration.inactive_opacity;
                            if (data.decoration.dim_inactive !== undefined) root.decorDimInactive = data.decoration.dim_inactive;
                            if (data.decoration.dim_strength !== undefined) root.decorDimStrength = data.decoration.dim_strength;
                            if (data.decoration.blur_enabled !== undefined) root.decorBlurEnabled = data.decoration.blur_enabled;
                            if (data.decoration.blur_size !== undefined) root.decorBlurSize = data.decoration.blur_size;
                            if (data.decoration.blur_passes !== undefined) root.decorBlurPasses = data.decoration.blur_passes;
                            if (data.decoration.blur_popups !== undefined) root.decorBlurPopups = data.decoration.blur_popups;
                            if (data.decoration.blur_xray !== undefined) root.decorBlurXray = data.decoration.blur_xray;
                            if (data.decoration.shadow_enabled !== undefined) root.decorShadowEnabled = data.decoration.shadow_enabled;
                            if (data.decoration.shadow_range !== undefined) root.decorShadowRange = data.decoration.shadow_range;
                            if (data.decoration.shadow_render_power !== undefined) root.decorShadowRenderPower = data.decoration.shadow_render_power;
                        }
                        if (data.gestures) {
                            if (data.gestures.workspace_swipe !== undefined) root.gesturesWorkspaceSwipe = data.gestures.workspace_swipe;
                            if (data.gestures.workspace_swipe_fingers !== undefined) root.gesturesWorkspaceSwipeFingers = data.gestures.workspace_swipe_fingers;
                            if (data.gestures.workspace_swipe_distance !== undefined) root.gesturesWorkspaceSwipeDistance = data.gestures.workspace_swipe_distance;
                            if (data.gestures.workspace_swipe_invert !== undefined) root.gesturesWorkspaceSwipeInvert = data.gestures.workspace_swipe_invert;
                            if (data.gestures.workspace_swipe_forever !== undefined) root.gesturesWorkspaceSwipeForever = data.gestures.workspace_swipe_forever;
                        }
                        if (data.misc) {
                            if (data.misc.vrr !== undefined) root.miscVrr = data.misc.vrr;
                            if (data.misc.vfr !== undefined) root.miscVfr = data.misc.vfr;
                            if (data.misc.disable_hyprland_logo !== undefined) root.miscDisableLogo = data.misc.disable_hyprland_logo;
                            if (data.misc.disable_splash_rendering !== undefined) root.miscDisableSplash = data.misc.disable_splash_rendering;
                            if (data.misc.mouse_move_enables_dpms !== undefined) root.miscMouseMoveDpms = data.misc.mouse_move_enables_dpms;
                            if (data.misc.middle_click_paste !== undefined) root.miscMiddleClickPaste = data.misc.middle_click_paste;
                            if (data.misc.no_hardware_cursors !== undefined) root.miscNoHardwareCursors = data.misc.no_hardware_cursors;
                        }
                        root.isLoading = false;
                    }
                } catch (e) {
                    root.isLoading = false;
                }
            }
        }
    }

    Process {
        id: setVarProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res = JSON.parse(text);
                    if (res && res.status === "ok") {
                        root.showToast(res.key + " updated");
                    }
                } catch (e) {}
            }
        }
    }

    /* ---- Main Scrollable Content ---- */
    Flickable {
        anchors.fill: parent
        contentHeight: hyprlandPageContentInst.implicitHeight + 28
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

        HyprlandPageContent {
            id: hyprlandPageContentInst
            root: root
        }
}

    // Feedback Toast (bottom floating notification matching AnimationSettings)
    Rectangle {
        id: statusToast
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 14
        implicitWidth: toastText.implicitWidth + 28
        height: 36
        radius: 18
        color: root.theme.bgSelected ?? "#283457"
        border.color: root.theme.accentPrimary ?? "#7aa2f7"
        border.width: 1
        opacity: root.toastVisible ? 1.0 : 0.0
        scale: root.toastVisible ? 1.0 : 0.92
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.centerIn: parent

            Text {
                id: toastText
                text: root.toastMessage
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textPrimary
            }
        }
    }
}
