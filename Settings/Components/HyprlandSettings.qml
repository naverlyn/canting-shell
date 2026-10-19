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

    /* ---- Reusable Helper Components ---- */

    component SectionCard: ColumnLayout {
        id: secCard
        property string title: ""
        property string subtitle: ""
        property color titleColor: root.theme.textSecondary
        property color subtitleColor: root.theme.textMuted
        property int contentMargins: 12
        property int contentSpacing: 12
        default property alias content: secInnerCol.data

        Layout.fillWidth: true
        width: parent ? parent.width : 0
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: secCard.title
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: secCard.titleColor
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: secCard.subtitle !== ""
                text: secCard.subtitle
                font.family: root.font
                font.pixelSize: 11
                color: secCard.subtitleColor
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                Layout.maximumWidth: Math.max(180, secCard.width * 0.55)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: secInnerCol.implicitHeight + secCard.contentMargins * 2
            radius: 12
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder
            border.width: 1
            Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: secInnerCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: secCard.contentMargins
                }
                spacing: secCard.contentSpacing
            }
        }
    }

    component RowDivider: Rectangle {
        Layout.fillWidth: true
        height: 1
        color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
    }

    component SettingToggleRow: Item {
        id: toggleRow
        property string title: ""
        property string desc: ""
        property bool checked: false
        property bool rowEnabled: true
        signal toggled(bool val)

        Layout.fillWidth: true
        width: parent ? parent.width : 0
        height: 52
        opacity: rowEnabled ? 1.0 : 0.45

        Behavior on opacity { NumberAnimation { duration: 140 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                readonly property int colWidth: Math.max(260, Math.round(((root.width > 0 ? root.width : 889) - 48) * 0.595))
                Layout.maximumWidth: Math.max(colWidth, toggleRow.width - 80)
                Layout.fillWidth: true

                Text {
                    text: toggleRow.title
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: toggleRow.desc !== ""
                    text: toggleRow.desc
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 44
                height: 24
                radius: 12
                color: toggleRow.checked ? root.theme.accentPrimary : root.theme.bgSelected
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                Behavior on color { ColorAnimation { duration: 160 } }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: toggleRow.checked ? parent.width - width - 3 : 3
                    color: toggleRow.checked ? root.theme.bgBase : root.theme.textPrimary

                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 160 } }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: toggleRow.rowEnabled
                    cursorShape: toggleRow.rowEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        toggleRow.toggled(!toggleRow.checked);
                        root.showToast(toggleRow.title + ": " + (!toggleRow.checked ? "Enabled" : "Disabled"));
                    }
                }
            }
        }
    }

    component SettingSliderRow: Item {
        id: sliderRow
        property string title: ""
        property string desc: ""
        property real value: 0
        property real minVal: 0
        property real maxVal: 100
        property real step: 1
        property string unit: "px"
        property var presets: []
        property bool isFloat: false
        property bool customActive: false
        signal valueModified(real val)

        function formatLabel(lbl) {
            if (!lbl) return "";
            let s = String(lbl);
            let match = s.match(/\(([^)]+)\)/);
            if (match && match[1]) return match[1];
            return s;
        }

        readonly property int matchingPresetIdx: {
            if (!presets || presets.length === 0) return -1;
            for (let i = 0; i < presets.length; i++) {
                if (Math.abs(sliderRow.value - presets[i].val) < (sliderRow.isFloat ? 0.005 : 0.01)) {
                    return i;
                }
            }
            return -1;
        }

        readonly property bool isCustomEffective: customActive || (presets.length > 0 && matchingPresetIdx === -1)

        readonly property int activeIdx: {
            if (presets.length === 0) return -1;
            if (isCustomEffective) return presets.length;
            return matchingPresetIdx;
        }

        Layout.fillWidth: true
        width: parent ? parent.width : 0
        implicitHeight: (presets.length > 0 && isCustomEffective) ? 94 : 52
        height: implicitHeight

        Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 6

            /* Top Main Row */
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                spacing: 12

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: sliderRow.width > 0 ? Math.max(180, sliderRow.width - (sliderRow.presets.length > 0 ? 370 : 230)) : 320

                    Text {
                        text: sliderRow.title
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: sliderRow.desc !== ""
                        text: sliderRow.desc
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Item { Layout.fillWidth: true }

                /* Case A: Has Presets -> Segmented Track with Presets + Custom */
                Rectangle {
                    id: segmentTrack
                    visible: sliderRow.presets.length > 0
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    implicitWidth: Math.min(380, Math.max(260, (sliderRow.presets.length + 1) * 70))
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    readonly property int count: sliderRow.presets.length + 1
                    readonly property real cellWidth: (width - 6 - (count - 1) * 3) / count

                    /* Sliding Selection Pill */
                    Rectangle {
                        visible: sliderRow.activeIdx >= 0
                        y: 3
                        height: parent.height - 6
                        width: segmentTrack.cellWidth
                        x: 3 + Math.max(0, sliderRow.activeIdx) * (segmentTrack.cellWidth + 3)
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
                            model: sliderRow.presets
                            delegate: Rectangle {
                                id: segBtn
                                required property var modelData
                                required property int index
                                readonly property bool isSel: sliderRow.activeIdx === segBtn.index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                color: !isSel && segHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: segHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: sliderRow.formatLabel(segBtn.modelData.label)
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: segBtn.isSel
                                    color: segBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                    opacity: segBtn.isSel || segHover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        sliderRow.customActive = false;
                                        sliderRow.valueModified(segBtn.modelData.val);
                                        root.showToast(sliderRow.title + " set to " + sliderRow.formatLabel(segBtn.modelData.label));
                                    }
                                }
                            }
                        }

                        /* Custom Segment Button */
                        Rectangle {
                            id: customSegBtn
                            readonly property bool isSel: sliderRow.activeIdx === sliderRow.presets.length

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && cHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: cHover }

                            Text {
                                anchors.centerIn: parent
                                text: sliderRow.isCustomEffective
                                    ? (sliderRow.isFloat ? Math.round(sliderRow.value * 100) + "%" : sliderRow.value + sliderRow.unit)
                                    : "Custom"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: customSegBtn.isSel
                                color: customSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: customSegBtn.isSel || cHover.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sliderRow.customActive = !sliderRow.customActive;
                                }
                            }
                        }
                    }
                }

                /* Case B: No Presets -> Right-Aligned Slider directly in main row */
                RowLayout {
                    visible: sliderRow.presets.length === 0
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    spacing: 12
                    implicitWidth: 260

                    Rectangle {
                        id: sTrackDirect
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: root.theme.bgSelected
                        Layout.alignment: Qt.AlignVCenter

                        readonly property real frac: Math.max(0.0, Math.min(1.0, (sliderRow.value - sliderRow.minVal) / (sliderRow.maxVal - sliderRow.minVal)))
                        readonly property bool isDragging: sMouseDirect.pressed

                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            width: Math.max(0, Math.min(parent.width, parent.width * sTrackDirect.frac))
                            color: root.theme.accentPrimary

                            Behavior on width {
                                NumberAnimation {
                                    duration: sTrackDirect.isDragging ? 0 : 140
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        // Outer halo ring on hover/press
                        Rectangle {
                            anchors.centerIn: sKnobDirect
                            width: sKnobDirect.width + (sMouseDirect.pressed ? 8 : (sMouseDirect.containsMouse ? 6 : 0))
                            height: width
                            radius: width / 2
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, sMouseDirect.pressed ? 0.35 : (sMouseDirect.containsMouse ? 0.2 : 0))
                            z: 1

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Tactile white knob
                        Rectangle {
                            id: sKnobDirect
                            width: sMouseDirect.containsMouse || sMouseDirect.pressed ? 17 : 15
                            height: width
                            radius: width / 2
                            color: "#ffffff"
                            border.color: root.theme.accentPrimary
                            border.width: 3
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(sTrackDirect.width - width, (sTrackDirect.width * sTrackDirect.frac) - (width / 2)))
                            z: 2

                            Behavior on width { NumberAnimation { duration: 120 } }
                            Behavior on x {
                                NumberAnimation {
                                    duration: sTrackDirect.isDragging ? 0 : 140
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        MouseArea {
                            id: sMouseDirect
                            anchors.fill: parent
                            anchors.margins: -8
                            hoverEnabled: true
                            preventStealing: true
                            cursorShape: Qt.PointingHandCursor
                            function updateFromPos(mouse) {
                                if (sTrackDirect.width <= 0) return;
                                const trackX = mapToItem(sTrackDirect, mouse.x, 0).x;
                                const f = Math.max(0.0, Math.min(1.0, trackX / sTrackDirect.width));
                                let raw = sliderRow.minVal + f * (sliderRow.maxVal - sliderRow.minVal);
                                let val = sliderRow.isFloat ? (Math.round(raw * 100) / 100) : Math.round(raw);
                                sliderRow.valueModified(val);
                            }
                            onPressed: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                            onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateFromPos(mouse); } }
                            onClicked: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                        }
                    }

                    Text {
                        text: (sliderRow.isFloat ? Math.round(sliderRow.value * 100) + "%" : sliderRow.value + sliderRow.unit)
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.accentPrimary
                        Layout.preferredWidth: 44
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            /* Expandable Custom Slider Row */
            RowLayout {
                visible: sliderRow.presets.length > 0 && sliderRow.isCustomEffective
                opacity: (sliderRow.presets.length > 0 && sliderRow.isCustomEffective) ? 1.0 : 0.0
                Layout.fillWidth: true
                Layout.topMargin: -2
                Layout.bottomMargin: 4
                spacing: 12

                Behavior on opacity { NumberAnimation { duration: 160 } }

                Text {
                    text: "Custom " + sliderRow.title + ":"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.preferredWidth: 160
                    Layout.minimumWidth: 160
                    Layout.maximumWidth: 160
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: sTrackCustom
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: root.theme.bgSelected
                    Layout.alignment: Qt.AlignVCenter

                    readonly property real frac: Math.max(0.0, Math.min(1.0, (sliderRow.value - sliderRow.minVal) / (sliderRow.maxVal - sliderRow.minVal)))
                    readonly property bool isDragging: sMouseCustom.pressed

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        width: Math.max(0, Math.min(parent.width, parent.width * sTrackCustom.frac))
                        color: root.theme.accentPrimary

                        Behavior on width {
                            NumberAnimation {
                                duration: sTrackCustom.isDragging ? 0 : 140
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    // Outer halo ring on hover/press
                    Rectangle {
                        anchors.centerIn: sKnobCustom
                        width: sKnobCustom.width + (sMouseCustom.pressed ? 8 : (sMouseCustom.containsMouse ? 6 : 0))
                        height: width
                        radius: width / 2
                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, sMouseCustom.pressed ? 0.35 : (sMouseCustom.containsMouse ? 0.2 : 0))
                        z: 1

                        Behavior on width { NumberAnimation { duration: 120 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    // Tactile white knob
                    Rectangle {
                        id: sKnobCustom
                        width: sMouseCustom.containsMouse || sMouseCustom.pressed ? 17 : 15
                        height: width
                        radius: width / 2
                        color: "#ffffff"
                        border.color: root.theme.accentPrimary
                        border.width: 3
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(sTrackCustom.width - width, (sTrackCustom.width * sTrackCustom.frac) - (width / 2)))
                        z: 2

                        Behavior on width { NumberAnimation { duration: 120 } }
                        Behavior on x {
                            NumberAnimation {
                                duration: sTrackCustom.isDragging ? 0 : 140
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        id: sMouseCustom
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        preventStealing: true
                        cursorShape: Qt.PointingHandCursor
                        function updateFromPos(mouse) {
                            if (sTrackCustom.width <= 0) return;
                            const trackX = mapToItem(sTrackCustom, mouse.x, 0).x;
                            const f = Math.max(0.0, Math.min(1.0, trackX / sTrackCustom.width));
                            let raw = sliderRow.minVal + f * (sliderRow.maxVal - sliderRow.minVal);
                            let val = sliderRow.isFloat ? (Math.round(raw * 100) / 100) : Math.round(raw);
                            sliderRow.valueModified(val);
                        }
                        onPressed: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                        onPositionChanged: (mouse) => { if (pressed) { mouse.accepted = true; updateFromPos(mouse); } }
                        onClicked: (mouse) => { mouse.accepted = true; updateFromPos(mouse); }
                    }
                }

                Text {
                    text: (sliderRow.isFloat ? Math.round(sliderRow.value * 100) + "%" : sliderRow.value + sliderRow.unit)
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.accentPrimary
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignRight
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
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
            width: parent.width
            spacing: 18

            /* Top Page Header */
            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 3
                    Text {
                        text: "Hyprland Settings"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                    Text {
                        text: "Window management, decorations, touchpad gestures, and compositor variables"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }
            }

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

            /* Sub-Tab Navigation Bar (Underline indicator style matching BarSettings) */
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
                            { idx: 0, icon: "󰖲", label: "General & Layout" },
                            { idx: 1, icon: "󰏘", label: "Window Decoration" },
                            { idx: 2, icon: "󰌒", label: "Gestures & Touchpad" },
                            { idx: 3, icon: "󰒓", label: "Misc & Compositor" }
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

            ColumnLayout {
                id: subTabContentContainer
                Layout.fillWidth: true
                spacing: 16
                transform: Translate { id: subTabContentTranslate; y: 0 }

            /* ========================================================================= */
            /* TAB 0: GENERAL & LAYOUT                                                   */
            /* ========================================================================= */
            ColumnLayout {
                visible: root.currentSubTab === 0
                Layout.fillWidth: true
                spacing: 16

                /* Interactive Live Preview Canvas */
                SectionCard {
                    title: "Live Window Layout Preview"
                    subtitle: "Simulated layout with active gaps, borders, and rounding"

                    Rectangle {
                        Layout.fillWidth: true
                        height: 140
                        radius: 8
                        color: root.theme.bgBase
                        border.color: root.theme.bgBorder
                        border.width: 1
                        clip: true

                        // Monitor outer bezel simulation
                        Item {
                            id: previewMonitorArea
                            anchors.fill: parent

                            property real animGapsOut: Math.max(4, root.generalGapsOut * 1.2)
                            property real animGapsIn: Math.max(2, root.generalGapsIn * 1.2)
                            property real animRounding: Math.min(18, root.decorRounding)
                            property real animBorderSize: Math.max(1, root.generalBorderSize)
                            property real animInactiveOpacity: root.decorInactiveOpacity

                            Behavior on animGapsOut { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on animGapsIn { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on animRounding { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on animBorderSize { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on animInactiveOpacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            anchors.margins: animGapsOut

                            // 1. Dwindle or Master layout
                            RowLayout {
                                opacity: (root.generalLayout === "dwindle" || root.generalLayout === "master") ? 1.0 : 0.0
                                visible: opacity > 0
                                anchors.fill: parent
                                spacing: previewMonitorArea.animGapsIn

                                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                                // Primary / Master Window
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: previewMonitorArea.animRounding
                                    color: root.theme.bgSelected
                                    border.color: root.theme.accentPrimary
                                    border.width: previewMonitorArea.animBorderSize

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text {
                                            text: root.generalLayout === "master" ? "󰕰 Master Window" : "󰕮 Primary Window"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.accentPrimary
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        Text {
                                            text: root.generalLayout.toUpperCase() + " | Active"
                                            font.family: root.font
                                            font.pixelSize: 9
                                            color: root.theme.textSecondary
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                }

                                // Secondary Stack
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: previewMonitorArea.animGapsIn

                                    // Window 2
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: previewMonitorArea.animRounding
                                        color: root.theme.bgSurface
                                        border.color: root.theme.bgBorder
                                        border.width: previewMonitorArea.animBorderSize
                                        opacity: previewMonitorArea.animInactiveOpacity

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Window 2"
                                            font.family: root.font
                                            font.pixelSize: 10
                                            color: root.theme.textSecondary
                                        }
                                    }

                                    // Window 3
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: previewMonitorArea.animRounding
                                        color: root.theme.bgSurface
                                        border.color: root.theme.bgBorder
                                        border.width: previewMonitorArea.animBorderSize
                                        opacity: previewMonitorArea.animInactiveOpacity

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Window 3"
                                            font.family: root.font
                                            font.pixelSize: 10
                                            color: root.theme.textSecondary
                                        }
                                    }
                                }
                            }

                            // 2. Scrolling strip layout
                            RowLayout {
                                opacity: root.generalLayout === "scrolling" ? 1.0 : 0.0
                                visible: opacity > 0
                                anchors.fill: parent
                                spacing: previewMonitorArea.animGapsIn

                                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: previewMonitorArea.animRounding
                                    color: root.theme.bgSurface
                                    border.color: root.theme.bgBorder
                                    border.width: previewMonitorArea.animBorderSize
                                    opacity: previewMonitorArea.animInactiveOpacity

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Column 1"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textSecondary
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: previewMonitorArea.animRounding
                                    color: root.theme.bgSelected
                                    border.color: root.theme.accentPrimary
                                    border.width: previewMonitorArea.animBorderSize

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text {
                                            text: "󰍍 Active Column"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.accentPrimary
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        Text {
                                            text: "SCROLLING STRIP"
                                            font.family: root.font
                                            font.pixelSize: 9
                                            color: root.theme.textSecondary
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: previewMonitorArea.animRounding
                                    color: root.theme.bgSurface
                                    border.color: root.theme.bgBorder
                                    border.width: previewMonitorArea.animBorderSize
                                    opacity: previewMonitorArea.animInactiveOpacity

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Column 3"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textSecondary
                                    }
                                }
                            }

                            // 3. Monocle fullscreen / stacked layout
                            Rectangle {
                                opacity: root.generalLayout === "monocle" ? 1.0 : 0.0
                                visible: opacity > 0
                                anchors.fill: parent
                                radius: previewMonitorArea.animRounding
                                color: root.theme.bgSelected
                                border.color: root.theme.accentPrimary
                                border.width: previewMonitorArea.animBorderSize

                                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "󰍹 Focused Window (1 of 3)"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.accentPrimary
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "MONOCLE | Fullscreen Focused Window Stack"
                                        font.family: root.font
                                        font.pixelSize: 9
                                        color: root.theme.textSecondary
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }
                    }
                }

                /* Window Gaps Card */
                SectionCard {
                    title: "Window Spacing & Gaps"
                    subtitle: "Inner gaps between windows & outer margins to monitor edges"

                    SettingSliderRow {
                        title: "Inner Window Gaps"
                        desc: "Distance in pixels between adjacent tiled windows"
                        value: root.generalGapsIn
                        minVal: 0
                        maxVal: 24
                        unit: "px"
                        presets: [
                            { label: "0px", val: 0 },
                            { label: "2px", val: 2 },
                            { label: "5px", val: 5 },
                            { label: "10px", val: 10 }
                        ]
                        onValueModified: (v) => {
                            root.generalGapsIn = v;
                            root.setHyprVar("general", "gaps_in", v);
                        }
                    }

                    RowDivider {}

                    SettingSliderRow {
                        title: "Outer Screen Gaps"
                        desc: "Distance in pixels between windows and monitor borders"
                        value: root.generalGapsOut
                        minVal: 0
                        maxVal: 40
                        unit: "px"
                        presets: [
                            { label: "0px", val: 0 },
                            { label: "4px", val: 4 },
                            { label: "10px", val: 10 },
                            { label: "20px", val: 20 }
                        ]
                        onValueModified: (v) => {
                            root.generalGapsOut = v;
                            root.setHyprVar("general", "gaps_out", v);
                        }
                    }
                }

                /* Window Borders & Resizing Card */
                SectionCard {
                    title: "Window Borders & Sizing"
                    subtitle: "Border thickness and edge interaction"

                    SettingSliderRow {
                        title: "Border Thickness"
                        desc: "Width of window outline border"
                        value: root.generalBorderSize
                        minVal: 0
                        maxVal: 6
                        unit: "px"
                        presets: [
                            { label: "0px", val: 0 },
                            { label: "1px", val: 1 },
                            { label: "2px", val: 2 },
                            { label: "3px", val: 3 }
                        ]
                        onValueModified: (v) => {
                            root.generalBorderSize = v;
                            root.setHyprVar("general", "border_size", v);
                        }
                    }

                    RowDivider {}

                    SettingToggleRow {
                        title: "Resize On Border"
                        desc: "Enable clicking and dragging directly on window borders to resize"
                        checked: root.generalResizeOnBorder
                        onToggled: (val) => {
                            root.generalResizeOnBorder = val;
                            root.setHyprVar("general", "resize_on_border", val);
                        }
                    }

                    RowDivider {}

                    SettingToggleRow {
                        title: "Allow Screen Tearing"
                        desc: "Master switch to allow tearing for ultra-low latency gaming"
                        checked: root.generalAllowTearing
                        onToggled: (val) => {
                            root.generalAllowTearing = val;
                            root.setHyprVar("general", "allow_tearing", val);
                        }
                    }
                }

                /* Layout & Snapping Card */
                SectionCard {
                    title: "Tiling Engine & Snapping"
                    subtitle: "Compositor layout algorithm and floating window snapping"

                    Item {
                        Layout.fillWidth: true
                        width: parent ? parent.width : 0
                        height: 54

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            ColumnLayout {
                                spacing: 2
                                Layout.alignment: Qt.AlignVCenter
                                readonly property int colWidth: Math.max(260, Math.round(((root.width > 0 ? root.width : 889) - 48) * 0.595))
                                Layout.preferredWidth: colWidth
                                Layout.minimumWidth: colWidth
                                Layout.maximumWidth: colWidth

                                Text {
                                    text: "Layout Engine"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "Select default tiling layout algorithm"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textSecondary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                id: layoutSegmentTrack
                                implicitWidth: 340
                                height: 32
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                readonly property var layouts: ["dwindle", "master", "scrolling", "monocle"]
                                readonly property int activeIdx: layouts.indexOf(root.generalLayout)
                                readonly property real cellWidth: (width - 6 - 9) / 4

                                /* Sliding Selection Pill */
                                Rectangle {
                                    visible: layoutSegmentTrack.activeIdx >= 0
                                    y: 3
                                    height: parent.height - 6
                                    width: layoutSegmentTrack.cellWidth
                                    x: 3 + Math.max(0, layoutSegmentTrack.activeIdx) * (layoutSegmentTrack.cellWidth + 3)
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
                                            { id: "dwindle", label: "Dwindle" },
                                            { id: "master", label: "Master" },
                                            { id: "scrolling", label: "Scrolling" },
                                            { id: "monocle", label: "Monocle" }
                                        ]

                                        delegate: Rectangle {
                                            id: lSegBtn
                                            required property var modelData
                                            required property int index
                                            readonly property bool isSel: layoutSegmentTrack.activeIdx === lSegBtn.index

                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: !isSel && lHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                            Behavior on color { ColorAnimation { duration: 140 } }

                                            HoverHandler { id: lHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: lSegBtn.modelData.label
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: lSegBtn.isSel
                                                color: lSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                opacity: lSegBtn.isSel || lHover.hovered ? 1.0 : 0.75
                                                Behavior on color { ColorAnimation { duration: 140 } }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.generalLayout = lSegBtn.modelData.id;
                                                    root.setHyprVar("general", "layout", lSegBtn.modelData.id);
                                                    root.showToast("Layout engine set to " + lSegBtn.modelData.label);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowDivider {}

                    SettingToggleRow {
                        title: "Floating Window Snapping"
                        desc: "Snap floating windows to adjacent window edges and monitor borders"
                        checked: root.generalSnapEnabled
                        onToggled: (val) => {
                            root.generalSnapEnabled = val;
                            root.setHyprVar("general.snap", "enabled", val);
                        }
                    }
                }
            }

            /* ========================================================================= */
            /* TAB 1: WINDOW DECORATION                                                  */
            /* ========================================================================= */
            ColumnLayout {
                visible: root.currentSubTab === 1
                Layout.fillWidth: true
                spacing: 16

                /* Corner Rounding Card */
                SectionCard {
                    title: "Window Corner Rounding"
                    subtitle: "Corner radius applied to all managed application windows"

                    SettingSliderRow {
                        title: "Rounding Radius"
                        desc: "Window corner rounding radius in pixels"
                        value: root.decorRounding
                        minVal: 0
                        maxVal: 24
                        unit: "px"
                        presets: [
                            { label: "0px", val: 0 },
                            { label: "6px", val: 6 },
                            { label: "10px", val: 10 },
                            { label: "16px", val: 16 }
                        ]
                        onValueModified: (v) => {
                            root.decorRounding = v;
                            root.setHyprVar("decoration", "rounding", v);
                        }
                    }
                }

                /* Opacity & Dimming Card */
                SectionCard {
                    title: "Window Opacity & Focus Dimming"
                    subtitle: "Active vs inactive window transparency and focus contrast"

                    SettingSliderRow {
                        title: "Active Window Opacity"
                        desc: "Opacity of the currently focused application window"
                        value: root.decorActiveOpacity
                        minVal: 0.50
                        maxVal: 1.00
                        isFloat: true
                        presets: [
                            { label: "85%", val: 0.85 },
                            { label: "90%", val: 0.90 },
                            { label: "95%", val: 0.95 },
                            { label: "100%", val: 1.00 }
                        ]
                        onValueModified: (v) => {
                            root.decorActiveOpacity = v;
                            root.setHyprVar("decoration", "active_opacity", v);
                        }
                    }

                    RowDivider {}

                    SettingSliderRow {
                        title: "Inactive Window Opacity"
                        desc: "Opacity of background, unfocused application windows"
                        value: root.decorInactiveOpacity
                        minVal: 0.50
                        maxVal: 1.00
                        isFloat: true
                        presets: [
                            { label: "75%", val: 0.75 },
                            { label: "80%", val: 0.80 },
                            { label: "90%", val: 0.90 },
                            { label: "100%", val: 1.00 }
                        ]
                        onValueModified: (v) => {
                            root.decorInactiveOpacity = v;
                            root.setHyprVar("decoration", "inactive_opacity", v);
                        }
                    }

                    RowDivider {}

                    SettingToggleRow {
                        title: "Dim Inactive Windows"
                        desc: "Slightly darken unfocused windows to bring attention to active window"
                        checked: root.decorDimInactive
                        onToggled: (val) => {
                            root.decorDimInactive = val;
                            root.setHyprVar("decoration", "dim_inactive", val);
                        }
                    }

                    RowDivider { visible: root.decorDimInactive }

                    SettingSliderRow {
                        visible: root.decorDimInactive
                        title: "Dim Strength"
                        desc: "Darkening intensity applied to unfocused windows"
                        value: root.decorDimStrength
                        minVal: 0.05
                        maxVal: 0.60
                        isFloat: true
                        presets: [
                            { label: "10%", val: 0.10 },
                            { label: "20%", val: 0.20 },
                            { label: "35%", val: 0.35 }
                        ]
                        onValueModified: (v) => {
                            root.decorDimStrength = v;
                            root.setHyprVar("decoration", "dim_strength", v);
                        }
                    }
                }

                /* Background Blur Card */
                SectionCard {
                    title: "Window Background Blur"
                    subtitle: "Dual-kawase blur behind transparent windows and popups"

                    SettingToggleRow {
                        title: "Enable Window Blur"
                        desc: "Render background blur behind transparent windows and shell layers"
                        checked: root.decorBlurEnabled
                        onToggled: (val) => {
                            root.decorBlurEnabled = val;
                            root.setHyprVar("decoration.blur", "enabled", val);
                        }
                    }

                    RowDivider { visible: root.decorBlurEnabled }

                    SettingSliderRow {
                        visible: root.decorBlurEnabled
                        title: "Blur Size"
                        desc: "Radius of the blur kernel (blur spread)"
                        value: root.decorBlurSize
                        minVal: 1
                        maxVal: 12
                        unit: "px"
                        presets: [
                            { label: "3px", val: 3 },
                            { label: "6px", val: 6 },
                            { label: "9px", val: 9 }
                        ]
                        onValueModified: (v) => {
                            root.decorBlurSize = v;
                            root.setHyprVar("decoration.blur", "size", v);
                        }
                    }

                    RowDivider { visible: root.decorBlurEnabled }

                    SettingSliderRow {
                        visible: root.decorBlurEnabled
                        title: "Blur Passes"
                        desc: "Number of rendering passes (higher = smoother, more GPU usage)"
                        value: root.decorBlurPasses
                        minVal: 1
                        maxVal: 5
                        unit: ""
                        presets: [
                            { label: "2", val: 2 },
                            { label: "3", val: 3 },
                            { label: "4", val: 4 }
                        ]
                        onValueModified: (v) => {
                            root.decorBlurPasses = v;
                            root.setHyprVar("decoration.blur", "passes", v);
                        }
                    }

                    RowDivider { visible: root.decorBlurEnabled }

                    SettingToggleRow {
                        visible: root.decorBlurEnabled
                        title: "Blur Popups & Menus"
                        desc: "Apply blur behind context menus, tooltips, and overlay popups"
                        checked: root.decorBlurPopups
                        onToggled: (val) => {
                            root.decorBlurPopups = val;
                            root.setHyprVar("decoration.blur", "popups", val);
                        }
                    }

                    RowDivider { visible: root.decorBlurEnabled }

                    SettingToggleRow {
                        visible: root.decorBlurEnabled
                        title: "X-Ray Mode"
                        desc: "Floating windows blur only the desktop wallpaper instead of underlying windows"
                        checked: root.decorBlurXray
                        onToggled: (val) => {
                            root.decorBlurXray = val;
                            root.setHyprVar("decoration.blur", "xray", val);
                        }
                    }
                }

                /* Drop Shadows Card */
                SectionCard {
                    title: "Window Drop Shadows"
                    subtitle: "Compositor drop shadows around windows"

                    SettingToggleRow {
                        title: "Enable Window Shadows"
                        desc: "Render drop shadows around application windows"
                        checked: root.decorShadowEnabled
                        onToggled: (val) => {
                            root.decorShadowEnabled = val;
                            root.setHyprVar("decoration.shadow", "enabled", val);
                        }
                    }

                    RowDivider { visible: root.decorShadowEnabled }

                    SettingSliderRow {
                        visible: root.decorShadowEnabled
                        title: "Shadow Range"
                        desc: "Spread and size of the window shadow"
                        value: root.decorShadowRange
                        minVal: 1
                        maxVal: 20
                        unit: "px"
                        presets: [
                            { label: "3px", val: 3 },
                            { label: "6px", val: 6 },
                            { label: "12px", val: 12 }
                        ]
                        onValueModified: (v) => {
                            root.decorShadowRange = v;
                            root.setHyprVar("decoration.shadow", "range", v);
                        }
                    }
                }
            }

            /* ========================================================================= */
            /* TAB 2: GESTURES & TOUCHPAD                                                */
            /* ========================================================================= */
            ColumnLayout {
                visible: root.currentSubTab === 2
                Layout.fillWidth: true
                spacing: 16

                SectionCard {
                    title: "Touchpad Workspace Gestures"
                    subtitle: "Fluid multi-finger swipe navigation between virtual desktops"

                    SettingToggleRow {
                        title: "Workspace Swipe Gesture"
                        desc: "Swipe horizontally on touchpad to fluidly pan between workspaces"
                        checked: root.gesturesWorkspaceSwipe
                        onToggled: (val) => {
                            root.gesturesWorkspaceSwipe = val;
                            root.setHyprVar("gestures", "workspace_swipe", val);
                        }
                    }

                    RowDivider { visible: root.gesturesWorkspaceSwipe }

                    Item {
                        visible: root.gesturesWorkspaceSwipe
                        Layout.fillWidth: true
                        width: parent ? parent.width : 0
                        height: 52

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            ColumnLayout {
                                spacing: 2
                                Layout.alignment: Qt.AlignVCenter
                                readonly property int colWidth: Math.max(260, Math.round(((root.width > 0 ? root.width : 889) - 48) * 0.595))
                                Layout.preferredWidth: colWidth
                                Layout.minimumWidth: colWidth
                                Layout.maximumWidth: colWidth

                                Text {
                                    text: "Swipe Fingers"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "Number of fingers required for touchpad workspace swipe"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textSecondary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                id: fingerSegmentTrack
                                implicitWidth: 200
                                height: 32
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                readonly property var fingerOpts: [3, 4]
                                readonly property int activeIdx: fingerOpts.indexOf(root.gesturesWorkspaceSwipeFingers)
                                readonly property real cellWidth: (width - 6 - 3) / 2

                                /* Sliding Selection Pill */
                                Rectangle {
                                    visible: fingerSegmentTrack.activeIdx >= 0
                                    y: 3
                                    height: parent.height - 6
                                    width: fingerSegmentTrack.cellWidth
                                    x: 3 + Math.max(0, fingerSegmentTrack.activeIdx) * (fingerSegmentTrack.cellWidth + 3)
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
                                            { val: 3, label: "3 Fingers" },
                                            { val: 4, label: "4 Fingers" }
                                        ]

                                        delegate: Rectangle {
                                            id: fingerBtn
                                            required property var modelData
                                            required property int index
                                            readonly property bool isSel: fingerSegmentTrack.activeIdx === fingerBtn.index

                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: !isSel && fHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                            Behavior on color { ColorAnimation { duration: 140 } }

                                            HoverHandler { id: fHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: fingerBtn.modelData.label
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: fingerBtn.isSel
                                                color: fingerBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                opacity: fingerBtn.isSel || fHover.hovered ? 1.0 : 0.75
                                                Behavior on color { ColorAnimation { duration: 140 } }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.gesturesWorkspaceSwipeFingers = fingerBtn.modelData.val;
                                                    root.setHyprVar("gestures", "workspace_swipe_fingers", fingerBtn.modelData.val);
                                                    root.showToast("Swipe gesture set to " + fingerBtn.modelData.label);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowDivider { visible: root.gesturesWorkspaceSwipe }

                    SettingToggleRow {
                        visible: root.gesturesWorkspaceSwipe
                        title: "Invert Swipe Direction"
                        desc: "Natural swipe scrolling direction for workspace transitions"
                        checked: root.gesturesWorkspaceSwipeInvert
                        onToggled: (val) => {
                            root.gesturesWorkspaceSwipeInvert = val;
                            root.setHyprVar("gestures", "workspace_swipe_invert", val);
                        }
                    }

                    RowDivider { visible: root.gesturesWorkspaceSwipe }

                    SettingToggleRow {
                        visible: root.gesturesWorkspaceSwipe
                        title: "Seamless Workspace Looping"
                        desc: "Allow swiping past the highest workspace to cycle continuously"
                        checked: root.gesturesWorkspaceSwipeForever
                        onToggled: (val) => {
                            root.gesturesWorkspaceSwipeForever = val;
                            root.setHyprVar("gestures", "workspace_swipe_forever", val);
                        }
                    }

                    RowDivider { visible: root.gesturesWorkspaceSwipe }

                    SettingSliderRow {
                        visible: root.gesturesWorkspaceSwipe
                        title: "Swipe Distance"
                        desc: "Distance in px required to complete a full workspace transition"
                        value: root.gesturesWorkspaceSwipeDistance
                        minVal: 150
                        maxVal: 600
                        unit: "px"
                        presets: [
                            { label: "200px", val: 200 },
                            { label: "300px", val: 300 },
                            { label: "500px", val: 500 }
                        ]
                        onValueModified: (v) => {
                            root.gesturesWorkspaceSwipeDistance = v;
                            root.setHyprVar("gestures", "workspace_swipe_distance", v);
                        }
                    }
                }
            }

            /* ========================================================================= */
            /* TAB 3: MISC & COMPOSITOR                                                  */
            /* ========================================================================= */
            ColumnLayout {
                visible: root.currentSubTab === 3
                Layout.fillWidth: true
                spacing: 16

                SectionCard {
                    title: "Display Sync & Refresh"
                    subtitle: "Adaptive sync (VRR) and variable frame rate performance"

                    Item {
                        Layout.fillWidth: true
                        width: parent ? parent.width : 0
                        height: 52

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            ColumnLayout {
                                spacing: 2
                                Layout.alignment: Qt.AlignVCenter
                                readonly property int colWidth: Math.max(260, Math.round(((root.width > 0 ? root.width : 889) - 48) * 0.595))
                                Layout.preferredWidth: colWidth
                                Layout.minimumWidth: colWidth
                                Layout.maximumWidth: colWidth

                                Text {
                                    text: "Variable Refresh Rate (VRR)"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "Adaptive sync (G-Sync / FreeSync) for variable refresh rate displays"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textSecondary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                id: vrrSegmentTrack
                                implicitWidth: 320
                                height: 32
                                radius: 7
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                readonly property var vrrOpts: [0, 1, 2]
                                readonly property int activeIdx: vrrOpts.indexOf(root.miscVrr)
                                readonly property real cellWidth: (width - 6 - 6) / 3

                                /* Sliding Selection Pill */
                                Rectangle {
                                    visible: vrrSegmentTrack.activeIdx >= 0
                                    y: 3
                                    height: parent.height - 6
                                    width: vrrSegmentTrack.cellWidth
                                    x: 3 + Math.max(0, vrrSegmentTrack.activeIdx) * (vrrSegmentTrack.cellWidth + 3)
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
                                            { val: 0, label: "Off" },
                                            { val: 1, label: "Always On" },
                                            { val: 2, label: "Fullscreen" }
                                        ]

                                        delegate: Rectangle {
                                            id: vrrBtn
                                            required property var modelData
                                            required property int index
                                            readonly property bool isSel: vrrSegmentTrack.activeIdx === vrrBtn.index

                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 5
                                            color: !isSel && vHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                            Behavior on color { ColorAnimation { duration: 140 } }

                                            HoverHandler { id: vHover }

                                            Text {
                                                anchors.centerIn: parent
                                                text: vrrBtn.modelData.label
                                                font.family: root.font
                                                font.pixelSize: 11
                                                font.bold: vrrBtn.isSel
                                                color: vrrBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                opacity: vrrBtn.isSel || vHover.hovered ? 1.0 : 0.75
                                                Behavior on color { ColorAnimation { duration: 140 } }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.miscVrr = vrrBtn.modelData.val;
                                                    root.setHyprVar("misc", "vrr", vrrBtn.modelData.val);
                                                    root.showToast("VRR set to " + vrrBtn.modelData.label);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowDivider {}

                    SettingToggleRow {
                        title: "Variable Frame Rate (VFR)"
                        desc: "Drop rendering rate when screen is static to significantly reduce GPU and battery usage"
                        checked: root.miscVfr
                        onToggled: (val) => {
                            root.miscVfr = val;
                            root.setHyprVar("misc", "vfr", val);
                        }
                    }

                    RowDivider {}

                    SettingToggleRow {
                        title: "Mouse Movement Wakes Monitors"
                        desc: "Wake screens from DPMS / display standby sleep when mouse moves"
                        checked: root.miscMouseMoveDpms
                        onToggled: (val) => {
                            root.miscMouseMoveDpms = val;
                            root.setHyprVar("misc", "mouse_move_enables_dpms", val);
                        }
                    }
                }

                SectionCard {
                    title: "Interaction & System Branding"
                    subtitle: "Clipboard behavior and compositor boot elements"

                    SettingToggleRow {
                        title: "Middle-Click Paste"
                        desc: "Paste primary selection buffer when clicking middle mouse button"
                        checked: root.miscMiddleClickPaste
                        onToggled: (val) => {
                            root.miscMiddleClickPaste = val;
                            root.setHyprVar("misc", "middle_click_paste", val);
                        }
                    }

                    RowDivider {}

                    SettingToggleRow {
                        title: "Hide Hyprland Boot Logo"
                        desc: "Suppress default Hyprland anime mascot logo on compositor startup"
                        checked: root.miscDisableLogo
                        onToggled: (val) => {
                            root.miscDisableLogo = val;
                            root.setHyprVar("misc", "disable_hyprland_logo", val);
                        }
                    }

                    RowDivider {}

                    SettingToggleRow {
                        title: "Hide Splash Rendering"
                        desc: "Disable random witty splash text rendering on startup screen"
                        checked: root.miscDisableSplash
                        onToggled: (val) => {
                            root.miscDisableSplash = val;
                            root.setHyprVar("misc", "disable_splash_rendering", val);
                        }
                    }
                }
            }
        }
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
