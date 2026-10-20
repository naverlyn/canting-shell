/*
 * AnimationSettings.qml
 *
 * Comprehensive animation management for Hyprland & Quickshell.
 * Supports:
 *   - Global animations master switch (hyprctl keyword animations:enabled & UserAnimations.conf)
 *   - Preset switcher with 17+ bundled animation profiles (HYDE, ML4W, Mahaveer, END, Standard)
 *   - Real-time animated preview playground demonstrating active curves and easing
 *   - Inspector for active Bezier curves and compositor animation rules
 *   - Smooth transitions and feedback toasts
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."
import "./Animation"

Item {
    id: root
    property alias queryProcRef: queryProc
    property var theme
    property string font: "Hack Nerd Font"

    /* Animation State */
    property bool animationsEnabled: true
    property string currentPreset: "00-default"
    property var presets: []
    property var activeBeziers: []
    property var activeRules: []

    /* Filter & Search State */
    property string selectedFamily: "All"
    property string searchQuery: ""
    readonly property var families: ["All", "Custom", "Standard", "HYDE", "ML4W", "Mahaveer", "END"]

    /* Custom Animation Studio State */
    property bool isCreatingCustom: false
    property string newAnimName: "My Custom Flow"
    property string newCurvePreset: "Overshot"
    property string newCurveName: "customEase"
    property string newCurvePoints: "0.05, 0.9, 0.1, 1.05"

    property var studioBeziers: [
        { name: "wind", curve: "0.05, 0.9, 0.1, 1.05" },
        { name: "winIn", curve: "0.1, 1.1, 0.1, 1.1" },
        { name: "winOut", curve: "0.3, -0.3, 0, 1" },
        { name: "smoothOut", curve: "0.5, 0, 0.99, 0.99" },
        { name: "liner", curve: "1, 1, 1, 1" }
    ]
    property int selectedBezierIndex: 0

    property var studioRules: [
        { category: "Windows", target: "windowsIn", title: "Window Open", desc: "Animation played when an application window opens", enabled: true, speed: 5.0, curve: "winIn", style: "popin 80%", styles: ["popin 80%", "popin 60%", "slide", "gnomed", "fade"] },
        { category: "Windows", target: "windowsOut", title: "Window Close", desc: "Animation played when an application window closes", enabled: true, speed: 3.0, curve: "winOut", style: "popin 80%", styles: ["popin 80%", "popin 60%", "slide", "fade"] },
        { category: "Windows", target: "windowsMove", title: "Window Move & Resize", desc: "Animation played when dragging or resizing windows", enabled: true, speed: 4.0, curve: "wind", style: "slide", styles: ["slide", "none"] },
        { category: "Layers", target: "layersIn", title: "Layer / Popup Open", desc: "QuickShell panels, launcher, and popups opening", enabled: true, speed: 4.0, curve: "winIn", style: "popin", styles: ["popin", "slide", "fade"] },
        { category: "Layers", target: "layersOut", title: "Layer / Popup Close", desc: "QuickShell panels, launcher, and popups closing", enabled: true, speed: 3.0, curve: "winOut", style: "fade", styles: ["fade", "popin", "slide"] },
        { category: "Workspaces", target: "workspaces", title: "Workspace Switch", desc: "Virtual workspace switching transition", enabled: true, speed: 5.0, curve: "wind", style: "slide", styles: ["slide", "slidevert", "fade", "slidefade", "slidefadevert 15%"] },
        { category: "Workspaces", target: "specialWorkspace", title: "Special Workspace", desc: "Scratchpad dropdown toggle transition", enabled: true, speed: 4.0, curve: "wind", style: "slidefadevert 15%", styles: ["slidefadevert 15%", "slidevert", "slide", "fade"] },
        { category: "Fades & Borders", target: "fade", title: "Window Opacity Fade", desc: "Window dimming and opacity transitions", enabled: true, speed: 3.0, curve: "wind", style: "", styles: [""] },
        { category: "Fades & Borders", target: "border", title: "Border Color Transition", desc: "Color transition on focus change", enabled: true, speed: 1.0, curve: "liner", style: "", styles: [""] },
        { category: "Fades & Borders", target: "borderangle", title: "Border Gradient Rotation", desc: "Rotating gradient angle for active borders", enabled: true, speed: 30.0, curve: "liner", style: "once", styles: ["once", "loop"] }
    ]

    readonly property var curveTemplates: [
        { name: "Overshot", points: "0.05, 0.9, 0.1, 1.05" },
        { name: "Ease-Out", points: "0.25, 1.0, 0.5, 1.0" },
        { name: "Snappy", points: "0.1, 1.0, 0.1, 1.0" },
        { name: "Bounce", points: "0.68, -0.55, 0.265, 1.55" },
        { name: "Gentle", points: "0.0, 0.0, 0.2, 1.0" },
        { name: "Linear", points: "0.0, 0.0, 1.0, 1.0" }
    ]

    function selectCurveTemplate(name, points) {
        root.newCurvePreset = name;
        root.updateSelectedBezierCurve(points);
    }

    function parseBezierPoints(str) {
        if (!str) return [0.05, 0.9, 0.1, 1.05];
        const parts = str.split(",");
        if (parts.length < 4) return [0.05, 0.9, 0.1, 1.05];
        const p0 = parseFloat(parts[0].trim());
        const p1 = parseFloat(parts[1].trim());
        const p2 = parseFloat(parts[2].trim());
        const p3 = parseFloat(parts[3].trim());
        return [
            isNaN(p0) ? 0.05 : p0,
            isNaN(p1) ? 0.90 : p1,
            isNaN(p2) ? 0.10 : p2,
            isNaN(p3) ? 1.05 : p3
        ];
    }

    /* Interactive Preview State */
    property string previewMode: "windowsIn" /* windowsIn, windowsOut, layersIn, workspaces */
    property real animProgress: 1.0
    property bool isPlayingPreview: false

    function findStudioRule(target) {
        if (root.isCreatingCustom && root.studioRules) {
            for (let i = 0; i < root.studioRules.length; i++) {
                if (root.studioRules[i].target === target) return root.studioRules[i];
            }
        } else if (root.activeRules) {
            for (let i = 0; i < root.activeRules.length; i++) {
                if (root.activeRules[i].target === target) return root.activeRules[i];
            }
        }
        return null;
    }

    function findStudioBezierCurve(curveName) {
        if (root.isCreatingCustom && root.studioBeziers) {
            for (let i = 0; i < root.studioBeziers.length; i++) {
                if (root.studioBeziers[i].name === curveName) return root.studioBeziers[i].curve;
            }
        } else if (root.activeBeziers) {
            for (let i = 0; i < root.activeBeziers.length; i++) {
                if (root.activeBeziers[i].name === curveName) return root.activeBeziers[i].curve;
            }
        }
        return root.newCurvePoints || "0.05, 0.9, 0.1, 1.05";
    }

    readonly property real currentPreviewSpeed: {
        const rule = root.findStudioRule(root.previewMode);
        return rule && rule.speed ? Number(rule.speed) : 4.0;
    }

    readonly property string currentPreviewStyle: {
        const rule = root.findStudioRule(root.previewMode);
        return rule && rule.style ? String(rule.style) : "popin 80%";
    }

    readonly property string currentPreviewCurveName: {
        const rule = root.findStudioRule(root.previewMode);
        return rule && rule.curve ? String(rule.curve) : (root.studioBeziers.length > 0 ? root.studioBeziers[0].name : "wind");
    }

    readonly property var currentPreviewBezierPoints: {
        const curveStr = root.findStudioBezierCurve(root.currentPreviewCurveName);
        return root.parseBezierPoints(curveStr);
    }

    readonly property var currentPreviewBezierList: {
        const pts = root.currentPreviewBezierPoints;
        const x1 = Math.max(0.0, Math.min(1.0, pts[0]));
        const y1 = pts[1];
        const x2 = Math.max(0.0, Math.min(1.0, pts[2]));
        const y2 = pts[3];
        return [x1, y1, x2, y2, 1.0, 1.0];
    }

    function selectBezier(idx) {
        if (idx >= 0 && idx < root.studioBeziers.length) {
            root.selectedBezierIndex = idx;
            root.newCurveName = root.studioBeziers[idx].name;
            root.newCurvePoints = root.studioBeziers[idx].curve;
            root.newCurvePreset = "Custom";
            root.triggerPreview();
        }
    }

    function updateSelectedBezierCurve(pointsStr) {
        root.newCurvePoints = pointsStr;
        if (root.selectedBezierIndex >= 0 && root.selectedBezierIndex < root.studioBeziers.length) {
            let list = JSON.parse(JSON.stringify(root.studioBeziers));
            list[root.selectedBezierIndex].curve = pointsStr;
            root.studioBeziers = list;
        }
        root.triggerPreview();
    }

    function updateSelectedBezierName(nameStr) {
        root.newCurveName = nameStr;
        if (root.selectedBezierIndex >= 0 && root.selectedBezierIndex < root.studioBeziers.length) {
            let list = JSON.parse(JSON.stringify(root.studioBeziers));
            const oldName = list[root.selectedBezierIndex].name;
            list[root.selectedBezierIndex].name = nameStr;
            root.studioBeziers = list;
            let rules = JSON.parse(JSON.stringify(root.studioRules));
            for (let i = 0; i < rules.length; i++) {
                if (rules[i].curve === oldName) {
                    rules[i].curve = nameStr;
                }
            }
            root.studioRules = rules;
        }
    }

    function addStudioBezier() {
        let list = JSON.parse(JSON.stringify(root.studioBeziers));
        const idx = list.length + 1;
        const newCrv = { name: "curve" + idx, curve: "0.05, 0.9, 0.1, 1.05" };
        list.push(newCrv);
        root.studioBeziers = list;
        root.selectBezier(list.length - 1);
        root.showStatus("Added curve: " + newCrv.name);
    }

    function removeSelectedBezier() {
        if (root.studioBeziers.length <= 1) {
            root.showStatus("Profile must have at least one curve");
            return;
        }
        let list = JSON.parse(JSON.stringify(root.studioBeziers));
        const remName = list[root.selectedBezierIndex].name;
        list.splice(root.selectedBezierIndex, 1);
        root.studioBeziers = list;
        root.selectBezier(Math.max(0, root.selectedBezierIndex - 1));
        root.showStatus("Removed curve: " + remName);
    }

    function updateRuleField(target, field, val) {
        let rules = JSON.parse(JSON.stringify(root.studioRules));
        for (let i = 0; i < rules.length; i++) {
            if (rules[i].target === target) {
                rules[i][field] = val;
                break;
            }
        }
        root.studioRules = rules;
        root.triggerPreview();
    }

    readonly property var studioCategories: {
        let cats = ["Windows", "Layers", "Workspaces", "Fades & Borders"];
        if (root.studioRules) {
            for (let i = 0; i < root.studioRules.length; i++) {
                const c = root.studioRules[i].category;
                if (c && cats.indexOf(c) === -1) {
                    cats.push(c);
                }
            }
        }
        return cats;
    }

    function getRulesForCategory(cat) {
        if (!root.studioRules) return [];
        let list = [];
        for (let i = 0; i < root.studioRules.length; i++) {
            if (root.studioRules[i].category === cat) {
                list.push(root.studioRules[i]);
            }
        }
        return list;
    }

    /* Studio Animation Rules Filter & Accordion State */
    property string studioCategoryFilter: "All"
    property bool expandAllRules: false

    readonly property var studioCategoryTabs: [
        { id: "All", label: "All Rules", count: root.studioRules ? root.studioRules.length : 0 },
        { id: "Windows", label: "Windows", count: root.getRulesForCategory("Windows").length },
        { id: "Layers", label: "Layers", count: root.getRulesForCategory("Layers").length },
        { id: "Workspaces", label: "Workspaces", count: root.getRulesForCategory("Workspaces").length },
        { id: "Fades & Borders", label: "Fades & Borders", count: root.getRulesForCategory("Fades & Borders").length }
    ]

    /* Status Toast State */
    property string statusMessage: ""
    property bool statusVisible: false

    readonly property string scriptPath: Qt.resolvedUrl("../scripts/manage_animations.sh").toString().replace(/^file:\/\//, "")

    Timer {
        id: statusTimer
        interval: 2500
        repeat: false
        onTriggered: root.statusVisible = false
    }

    function showStatus(msg) {
        root.statusMessage = msg;
        root.statusVisible = true;
        statusTimer.restart();
    }

    /* Query Animation Status */
    Process {
        id: queryProc
        command: [root.scriptPath, "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text.trim());
                    root.animationsEnabled = Boolean(data.enabled);
                    root.currentPreset = data.currentPreset || "Custom";
                    root.presets = data.presets || [];
                    root.activeBeziers = data.activeBeziers || [];
                    root.activeRules = data.activeRules || [];
                } catch (e) {
                    console.log("[AnimationSettings] Error parsing status:", e);
                }
            }
        }
    }

    Component.onCompleted: {
        queryProc.running = true;
    }

    /* Master Toggle Process */
    Process {
        id: toggleProc
        running: false
        onRunningChanged: {
            if (!running) queryProc.running = true;
        }
    }

    function setAnimationsEnabled(enabled) {
        root.animationsEnabled = enabled;
        toggleProc.command = [root.scriptPath, "set_enabled", enabled ? "true" : "false"];
        toggleProc.running = true;
        root.showStatus(enabled ? "Compositor animations enabled" : "Compositor animations disabled");
    }

    /* Apply Preset Process */
    Process {
        id: applyProc
        running: false
        onRunningChanged: {
            if (!running) {
                queryProc.running = true;
                root.triggerPreview();
            }
        }
    }

    function applyPreset(presetId, displayName) {
        applyProc.command = [root.scriptPath, "apply_preset", String(presetId)];
        applyProc.running = true;
        root.showStatus("Applied animation profile: " + (displayName || presetId));
    }

    /* Test Notification Process */
    Process {
        id: testProc
        command: [root.scriptPath, "test"]
        running: false
    }

    /* Save Custom Preset Process */
    Process {
        id: saveCustomProc
        running: false
        onRunningChanged: {
            if (!running) {
                root.selectedFamily = "Custom";
                queryProc.running = true;
                root.triggerPreview();
                root.isCreatingCustom = false;
            }
        }
    }

    function saveCustomAnimation() {
        const payload = {
            name: root.newAnimName.trim() || "My Custom Flow",
            beziers: root.studioBeziers,
            rules: root.studioRules
        };
        root.selectedFamily = "Custom";
        saveCustomProc.command = [root.scriptPath, "save_custom", JSON.stringify(payload)];
        saveCustomProc.running = true;
        root.showStatus("Saved and applied profile: " + payload.name);
    }

    /* Delete Custom Preset Process */
    Process {
        id: deleteCustomProc
        running: false
        onRunningChanged: {
            if (!running) {
                queryProc.running = true;
            }
        }
    }

    function deleteCustomPreset(presetId) {
        deleteCustomProc.command = [root.scriptPath, "delete_custom", String(presetId)];
        deleteCustomProc.running = true;
        root.showStatus("Removed custom profile: " + presetId);
    }

    function editPreset(preset) {
        if (!preset) return;
        root.newAnimName = preset.displayName || preset.name || "My Animation";

        // 1. Populate Beziers
        if (preset.beziers && preset.beziers.length > 0) {
            root.studioBeziers = JSON.parse(JSON.stringify(preset.beziers));
        } else {
            root.studioBeziers = [
                { name: "wind", curve: "0.05, 0.9, 0.1, 1.05" },
                { name: "winIn", curve: "0.1, 1.1, 0.1, 1.1" },
                { name: "winOut", curve: "0.3, -0.3, 0, 1" },
                { name: "smoothOut", curve: "0.5, 0, 0.99, 0.99" },
                { name: "liner", curve: "1, 1, 1, 1" }
            ];
        }
        root.selectedBezierIndex = 0;
        root.newCurveName = root.studioBeziers[0].name;
        root.newCurvePoints = root.studioBeziers[0].curve;
        root.newCurvePreset = "Custom";

        // 2. Populate Rules
        let defaultRules = [
            { category: "Windows", target: "windowsIn", title: "Window Open", desc: "Animation played when an application window opens", enabled: true, speed: 5.0, curve: "winIn", style: "popin 80%", styles: ["popin 80%", "popin 60%", "slide", "gnomed", "fade"] },
            { category: "Windows", target: "windowsOut", title: "Window Close", desc: "Animation played when an application window closes", enabled: true, speed: 3.0, curve: "winOut", style: "popin 80%", styles: ["popin 80%", "popin 60%", "slide", "fade"] },
            { category: "Windows", target: "windowsMove", title: "Window Move & Resize", desc: "Animation played when dragging or resizing windows", enabled: true, speed: 4.0, curve: "wind", style: "slide", styles: ["slide", "none"] },
            { category: "Layers", target: "layersIn", title: "Layer / Popup Open", desc: "QuickShell panels, launcher, and popups opening", enabled: true, speed: 4.0, curve: "winIn", style: "popin", styles: ["popin", "slide", "fade"] },
            { category: "Layers", target: "layersOut", title: "Layer / Popup Close", desc: "QuickShell panels, launcher, and popups closing", enabled: true, speed: 3.0, curve: "winOut", style: "fade", styles: ["fade", "popin", "slide"] },
            { category: "Workspaces", target: "workspaces", title: "Workspace Switch", desc: "Virtual workspace switching transition", enabled: true, speed: 5.0, curve: "wind", style: "slide", styles: ["slide", "slidevert", "fade", "slidefade", "slidefadevert 15%"] },
            { category: "Workspaces", target: "specialWorkspace", title: "Special Workspace", desc: "Scratchpad dropdown toggle transition", enabled: true, speed: 4.0, curve: "wind", style: "slidefadevert 15%", styles: ["slidefadevert 15%", "slidevert", "slide", "fade"] },
            { category: "Fades & Borders", target: "fade", title: "Window Opacity Fade", desc: "Window dimming and opacity transitions", enabled: true, speed: 3.0, curve: "wind", style: "", styles: [""] },
            { category: "Fades & Borders", target: "border", title: "Border Color Transition", desc: "Color transition on focus change", enabled: true, speed: 1.0, curve: "liner", style: "", styles: [""] },
            { category: "Fades & Borders", target: "borderangle", title: "Border Gradient Rotation", desc: "Rotating gradient angle for active borders", enabled: true, speed: 30.0, curve: "liner", style: "once", styles: ["once", "loop"] }
        ];

        const firstCurve = root.studioBeziers[0].name;
        for (let j = 0; j < defaultRules.length; j++) {
            let foundCurve = false;
            for (let k = 0; k < root.studioBeziers.length; k++) {
                if (root.studioBeziers[k].name === defaultRules[j].curve) {
                    foundCurve = true;
                    break;
                }
            }
            if (!foundCurve) defaultRules[j].curve = firstCurve;
        }

        if (preset.animations && preset.animations.length > 0) {
            for (let i = 0; i < preset.animations.length; i++) {
                const a = preset.animations[i];
                if (!a) continue;
                let matched = false;
                for (let j = 0; j < defaultRules.length; j++) {
                    if (defaultRules[j].target === a.target) {
                        defaultRules[j].enabled = a.enabled !== undefined ? Boolean(a.enabled) : true;
                        if (a.speed) defaultRules[j].speed = Number(a.speed);
                        if (a.curve) defaultRules[j].curve = String(a.curve);
                        if (a.style !== undefined) defaultRules[j].style = String(a.style);
                        matched = true;
                        break;
                    }
                }
                if (!matched && a.target) {
                    defaultRules.push({
                        category: "Custom Rules",
                        target: a.target,
                        title: a.target,
                        desc: "Custom compositor animation rule",
                        enabled: a.enabled !== undefined ? Boolean(a.enabled) : true,
                        speed: a.speed ? Number(a.speed) : 4.0,
                        curve: a.curve ? String(a.curve) : firstCurve,
                        style: a.style ? String(a.style) : "",
                        styles: [a.style || "slide", "popin", "fade", "none"]
                    });
                }
            }
        }

        root.studioRules = defaultRules;
        root.isCreatingCustom = true;
        mainFlickable.contentY = 0;
        root.triggerPreview();
        root.showStatus("Loaded animation profile: " + root.newAnimName);
    }

    function testLiveMotion() {
        const payload = {
            name: root.newAnimName.trim() || "Test Flow",
            beziers: root.studioBeziers,
            rules: root.studioRules
        };
        testProc.command = [root.scriptPath, "test", JSON.stringify(payload)];
        testProc.running = true;
        root.triggerPreview();
        root.showStatus("Testing motion on Hyprland — observe popup and transitions");
    }

    /* Filtered Presets List */
    readonly property var filteredPresets: {
        const query = root.searchQuery.toLowerCase().trim();
        const fam = root.selectedFamily;
        let list = [];
        for (let i = 0; i < root.presets.length; i++) {
            const p = root.presets[i];
            if (!p) continue;
            if (fam !== "All" && p.family !== fam) continue;
            if (query !== "") {
                const nameMatch = p.displayName && p.displayName.toLowerCase().indexOf(query) !== -1;
                const famMatch = p.family && p.family.toLowerCase().indexOf(query) !== -1;
                const descMatch = p.description && p.description.toLowerCase().indexOf(query) !== -1;
                if (!nameMatch && !famMatch && !descMatch) continue;
            }
            list.push(p);
        }
        return list;
    }

    /* Preview Animation Trigger */
    function triggerPreview() {
        previewAnim.restart();
    }

    SequentialAnimation {
        id: previewAnim
        running: false
        PropertyAction { target: root; property: "isPlayingPreview"; value: true }
        NumberAnimation {
            id: animProgressNumberAnim
            target: root
            property: "animProgress"
            from: 0.0
            to: 1.0
            duration: {
                if (!root.animationsEnabled) return 50;
                const spd = root.currentPreviewSpeed;
                return Math.max(120, Math.min(2500, spd * 100));
            }
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.currentPreviewBezierList
        }
        PropertyAction { target: root; property: "isPlayingPreview"; value: false }
    }

    /* Main Scrollable Content */
    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: animationPageContentInst.implicitHeight + 36
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !animationPageContentInst.animationStudioPanelInstRef.animationCurveEditorRowInstRef.canvasMouseRef.pressed && animationPageContentInst.animationStudioPanelInstRef.animationCurveEditorRowInstRef.bezierCanvasRef.activeDragHandle === 0

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 8
            background: Item {}
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15)
            }
        }

        AnimationPageContent {
            id: animationPageContentInst
            root: root
        }
    }

    // Feedback Toast (bottom floating notification)
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
        opacity: root.statusVisible ? 1.0 : 0.0
        scale: root.statusVisible ? 1.0 : 0.92
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.centerIn: parent

            Text {
                id: toastText
                text: root.statusMessage
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textPrimary
            }
        }
    }
}
