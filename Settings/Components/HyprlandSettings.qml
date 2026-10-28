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
    property string font: "Lato Nerd Font"

    /* Sub-tabs: 0: General & Layout, 1: Window Decoration, 2: Window Rules, 3: Gestures & Touchpad, 4: Misc & Compositor */
    property int currentSubTab: 0

    /* Loading & Script path */
    property bool isLoading: true
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/manage_hyprland.sh").toString().replace(/^file:\/\//, "")
    readonly property string rulesScriptPath: Qt.resolvedUrl("../scripts/lua_window_rules.py").toString().replace(/^file:\/\//, "")

    /* ---- General State ---- */
    property int generalGapsIn: 2
    property int generalGapsOut: 4
    property int generalBorderSize: 0
    property string generalLayout: "dwindle"
    property bool generalResizeOnBorder: true
    property bool generalAllowTearing: false
    property bool generalSnapEnabled: false
    property int generalSnapWindowGap: 10

    /* ---- Border Colors State ---- */
    property bool borderThemeSync: true
    property string activeBorderCol1: "#7aa2f7"
    property string activeBorderCol2: "#7dcfff"
    property int activeBorderAngle: 45
    property string inactiveBorderCol: "#32364a"

    readonly property var borderColorSwatches: [
        { name: "Theme Primary", color: root.theme ? String(root.theme.accentPrimary) : "#7aa2f7" },
        { name: "Theme Cyan",    color: root.theme ? String(root.theme.accentCyan)    : "#7dcfff" },
        { name: "Theme Green",   color: root.theme ? String(root.theme.accentGreen)   : "#9ece6a" },
        { name: "Theme Orange",  color: root.theme ? String(root.theme.accentOrange)  : "#ff9e64" },
        { name: "Theme Red",     color: root.theme ? String(root.theme.accentRed)     : "#f7768e" },
        { name: "White",         color: "#ffffff" }
    ]

    readonly property var inactiveColorSwatches: [
        { name: "Theme Border",  color: root.theme ? String(root.theme.bgBorder)      : "#32364a" },
        { name: "Theme Surface", color: root.theme ? String(root.theme.bgSurface)     : "#24283b" },
        { name: "Slate Muted",   color: "#595959" },
        { name: "Charcoal",      color: "#322f2f" },
        { name: "Deep Dark",     color: "#1a1b26" }
    ]

    function applyBorderColors() {
        if (root.isLoading) return;
        let c1 = root.borderThemeSync ? String(root.theme.accentPrimary) : root.activeBorderCol1;
        let c2 = root.borderThemeSync ? String(root.theme.accentCyan) : root.activeBorderCol2;
        let ang = root.activeBorderAngle;
        let inact = root.borderThemeSync ? String(root.theme.bgBorder) : root.inactiveBorderCol;
        setVarProc.command = [root.scriptPath, "set_borders", c1, c2, String(ang), inact, root.borderThemeSync ? "true" : "false"];
        setVarProc.running = true;
    }

    /* ---- Window Rules State ---- */
    property var windowRules: []
    property string ruleSearchQuery: ""
    property string ruleCategoryFilter: "all"
    property bool showAllRules: false

    property bool isAddingRule: false
    property string editingRuleName: ""
    property string formRuleType: "window_rule"
    property string formRuleName: ""
    property string formMatchClass: ""
    property string formMatchTitle: ""
    property string formMatchTag: ""
    property string formMatchNamespace: ""
    property bool formEffectFloat: false
    property bool formEffectCenter: false
    property bool formEffectPin: false
    property bool formEffectNoBlur: false
    property bool formEffectNoAnim: false
    property bool formEffectNoFocus: false
    property string formEffectOpacity: ""
    property string formEffectSize: ""
    property string formEffectWorkspace: ""
    property string formEffectTag: ""
    property bool formLayerBlur: true
    property string formLayerIgnoreAlpha: ""

    readonly property var filteredWindowRules: {
        if (!root.windowRules || root.windowRules.length === 0) return [];
        const q = root.ruleSearchQuery.toLowerCase().trim();
        const cat = root.ruleCategoryFilter;
        let list = root.windowRules.filter(r => {
            if (cat !== "all" && r.category !== cat) return false;
            if (!q) return true;
            const n = (r.name || "").toLowerCase();
            const m = (r.matchSummary || "").toLowerCase();
            const p = (r.effectPills || []).join(" ").toLowerCase();
            return n.includes(q) || m.includes(q) || p.includes(q);
        });
        if (!q && cat === "all" && !root.showAllRules) {
            return list.slice(0, 20);
        }
        return list;
    }

    function findRuleByName(rName) {
        if (!root.windowRules) return null;
        for (let i = 0; i < root.windowRules.length; i++) {
            if (root.windowRules[i].name === rName) return root.windowRules[i];
        }
        return null;
    }

    function toggleWindowRule(rName, enabledVal) {
        for (let i = 0; i < root.windowRules.length; i++) {
            if (root.windowRules[i].name === rName) {
                root.windowRules[i].enabled = enabledVal;
                break;
            }
        }
        root.windowRules = root.windowRules.slice();
        ruleMutationProc.command = ["python3", root.rulesScriptPath, "toggle", rName, enabledVal ? "true" : "false"];
        ruleMutationProc.running = true;
        root.showToast(rName + (enabledVal ? " enabled" : " disabled"));
    }

    function setRuleOpacity(rName, actVal, inactVal) {
        for (let i = 0; i < root.windowRules.length; i++) {
            if (root.windowRules[i].name === rName) {
                root.windowRules[i].activeOpacity = actVal;
                root.windowRules[i].inactiveOpacity = inactVal;
                break;
            }
        }
        root.windowRules = root.windowRules.slice();
        ruleMutationProc.command = ["python3", root.rulesScriptPath, "set_opacity", rName, String(actVal), String(inactVal)];
        ruleMutationProc.running = true;
        root.showToast(rName + " opacity set to " + Math.round(actVal * 100) + "% / " + Math.round(inactVal * 100) + "%");
    }

    function startAddingRule() {
        root.editingRuleName = "";
        root.formRuleType = "window_rule";
        root.formRuleName = "";
        root.formMatchClass = "";
        root.formMatchTitle = "";
        root.formMatchTag = "";
        root.formMatchNamespace = "";
        root.formEffectFloat = false;
        root.formEffectCenter = false;
        root.formEffectPin = false;
        root.formEffectNoBlur = false;
        root.formEffectNoAnim = false;
        root.formEffectNoFocus = false;
        root.formEffectOpacity = "";
        root.formEffectSize = "";
        root.formEffectWorkspace = "";
        root.formEffectTag = "";
        root.formLayerBlur = true;
        root.formLayerIgnoreAlpha = "";
        root.isAddingRule = true;
    }

    function startEditingRule(ruleItem) {
        if (!ruleItem) return;
        if (root.editingRuleName === ruleItem.name) {
            root.editingRuleName = "";
            root.isAddingRule = false;
            return;
        }
        root.isAddingRule = false;
        root.editingRuleName = ruleItem.name;
        root.formRuleType = ruleItem.ruleType || "window_rule";
        root.formRuleName = ruleItem.name || "";
        const m = ruleItem.match || {};
        root.formMatchClass = m.class !== undefined ? String(m.class) : "";
        root.formMatchTitle = m.title !== undefined ? String(m.title) : "";
        root.formMatchTag = m.tag !== undefined ? String(m.tag) : "";
        root.formMatchNamespace = m.namespace !== undefined ? String(m.namespace) : "";
        const eff = ruleItem.effects || {};
        root.formEffectFloat = Boolean(eff.float);
        root.formEffectCenter = Boolean(eff.center);
        root.formEffectPin = Boolean(eff.pin);
        root.formEffectNoBlur = Boolean(eff.no_blur);
        root.formEffectNoAnim = Boolean(eff.no_anim);
        root.formEffectNoFocus = Boolean(eff.no_focus);
        root.formEffectOpacity = eff.opacity !== undefined ? String(eff.opacity) : "";
        root.formEffectSize = eff.size !== undefined ? String(eff.size) : "";
        root.formEffectWorkspace = eff.workspace !== undefined ? String(eff.workspace) : "";
        root.formEffectTag = eff.tag !== undefined ? String(eff.tag) : "";
        root.formLayerBlur = eff.blur !== undefined ? Boolean(eff.blur) : true;
        root.formLayerIgnoreAlpha = eff.ignore_alpha !== undefined ? String(eff.ignore_alpha) : "";
    }

    function saveRuleForm() {
        const rName = root.formRuleName.trim();
        if (!rName) return;

        let matchObj = {};
        let effectsObj = {};

        if (root.formRuleType === "layer_rule") {
            matchObj.namespace = root.formMatchNamespace.trim() || "rofi";
            if (root.formLayerBlur) effectsObj.blur = true;
            if (root.formLayerIgnoreAlpha.trim() !== "") {
                effectsObj.ignore_alpha = parseFloat(root.formLayerIgnoreAlpha.trim()) || 0.5;
            }
        } else {
            if (root.formMatchClass.trim() !== "") matchObj.class = root.formMatchClass.trim();
            if (root.formMatchTitle.trim() !== "") matchObj.title = root.formMatchTitle.trim();
            if (root.formMatchTag.trim() !== "") matchObj.tag = root.formMatchTag.trim();
            if (Object.keys(matchObj).length === 0) matchObj.class = ".*";

            if (root.formEffectFloat) effectsObj.float = true;
            if (root.formEffectCenter) effectsObj.center = true;
            if (root.formEffectPin) effectsObj.pin = true;
            if (root.formEffectNoBlur) effectsObj.no_blur = true;
            if (root.formEffectNoAnim) effectsObj.no_anim = true;
            if (root.formEffectNoFocus) effectsObj.no_focus = true;
            if (root.formEffectOpacity.trim() !== "") effectsObj.opacity = root.formEffectOpacity.trim();
            if (root.formEffectSize.trim() !== "") effectsObj.size = root.formEffectSize.trim();
            if (root.formEffectWorkspace.trim() !== "") effectsObj.workspace = root.formEffectWorkspace.trim();
            if (root.formEffectTag.trim() !== "") effectsObj.tag = root.formEffectTag.trim();
        }

        const payload = {
            originalName: root.editingRuleName,
            name: rName,
            ruleType: root.formRuleType,
            enabled: true,
            match: matchObj,
            effects: effectsObj
        };

        ruleMutationProc.command = ["python3", root.rulesScriptPath, "save", JSON.stringify(payload)];
        ruleMutationProc.running = true;
        root.isAddingRule = false;
        root.editingRuleName = "";
        root.showToast("Saved Lua rule: " + rName);
    }

    function deleteWindowRule(rName) {
        if (!rName) return;
        ruleMutationProc.command = ["python3", root.rulesScriptPath, "delete", rName];
        ruleMutationProc.running = true;
        root.editingRuleName = "";
        root.isAddingRule = false;
        root.showToast("Deleted Lua rule: " + rName);
    }

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
                            if (data.general.border_theme_sync !== undefined) root.borderThemeSync = data.general.border_theme_sync;
                            if (data.general.active_border_col1 !== undefined) root.activeBorderCol1 = data.general.active_border_col1;
                            if (data.general.active_border_col2 !== undefined) root.activeBorderCol2 = data.general.active_border_col2;
                            if (data.general.active_border_angle !== undefined) root.activeBorderAngle = data.general.active_border_angle;
                            if (data.general.inactive_border_col !== undefined) root.inactiveBorderCol = data.general.inactive_border_col;
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

    Process {
        id: loadRulesProc
        command: ["python3", root.rulesScriptPath, "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text);
                    if (Array.isArray(list)) {
                        root.windowRules = list;
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: ruleMutationProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                loadRulesProc.running = false;
                loadRulesProc.running = true;
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
