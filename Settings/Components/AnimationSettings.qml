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

Item {
    id: root
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
        contentHeight: mainCol.implicitHeight + 36
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !canvasMouse.pressed && bezierCanvas.activeDragHandle === 0

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

        ColumnLayout {
            id: mainCol
            x: 8
            width: parent.width - 16
            spacing: 18

            // Page Header (Title on Left, Buttons pushed firmly to the Far Right)
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                    Text {
                        text: "Animations"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "Configure Hyprland window motions, workspace transitions, and curve profiles"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                RowLayout {
                    id: headerBtnRow
                    spacing: 8
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                    // Create Custom Animation Button
                    Rectangle {
                        implicitWidth: newAnimRow.implicitWidth + 22
                        height: 30
                        radius: 7
                        color: root.isCreatingCustom
                            ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                            : (newAnimMouse.containsMouse ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.06)))
                        border.color: (root.isCreatingCustom || newAnimMouse.containsMouse) ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12))
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        scale: newAnimMouse.pressed ? 0.96 : 1.0
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        RowLayout {
                            id: newAnimRow
                            anchors.centerIn: parent

                            Text {
                                text: root.isCreatingCustom ? "Close Studio" : "New Animation"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.isCreatingCustom
                                    ? root.theme.accentPrimary
                                    : (newAnimMouse.containsMouse ? "#ffffff" : root.theme.textPrimary)
                            }
                        }

                        MouseArea {
                            id: newAnimMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isCreatingCustom = !root.isCreatingCustom;
                                if (root.isCreatingCustom) root.triggerPreview();
                            }
                        }
                    }

                    // Quick Reload Button
                    Rectangle {
                        implicitWidth: refreshRow.implicitWidth + 20
                        height: 30
                        radius: 7
                        color: refreshMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.05))
                        border.color: refreshMouse.containsMouse ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12))
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        scale: refreshMouse.pressed ? 0.96 : 1.0
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        RowLayout {
                            id: refreshRow
                            anchors.centerIn: parent

                            Text {
                                text: "Reload"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: refreshMouse.containsMouse ? root.theme.accentPrimary : root.theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: queryProc.running = true
                        }
                    }
                }
            }

            // Custom Animation Studio Panel (Expandable)
            Rectangle {
                id: customStudioCard
                visible: root.isCreatingCustom
                Layout.fillWidth: true
                radius: 12
                color: root.theme.bgSurface
                border.color: root.theme.accentPrimary
                border.width: 1.5
                implicitHeight: studioCol.implicitHeight + 36
                clip: true

                ColumnLayout {
                    id: studioCol
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 16

                    // 1. Studio Header & Top Action Bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true

                            Text {
                                text: root.newAnimName ? ("Animation Studio • " + root.newAnimName) : "Animation Studio • Custom Profile"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                            }

                            Text {
                                text: "Design Bézier curves, motion physics, and Hyprland animation tree rules"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                            }
                        }

                        // Top Action Buttons (Strictly text-only, matching modern theme buttons)
                        RowLayout {
                            spacing: 8

                            // Test Live Motion
                            Rectangle {
                                height: 32
                                implicitWidth: topTestText.implicitWidth + 24
                                radius: 8
                                color: topTestHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase
                                border.color: topTestHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: topTestHover }

                                Text {
                                    id: topTestText
                                    anchors.centerIn: parent
                                    text: "Test Live Motion"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: topTestHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.testLiveMotion()
                                }
                            }

                            // Save & Apply Profile
                            Rectangle {
                                height: 32
                                implicitWidth: topSaveText.implicitWidth + 24
                                radius: 8
                                color: topSaveHover.hovered ? Qt.darker(root.theme.accentPrimary, 1.1) : root.theme.accentPrimary
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: topSaveHover }

                                Text {
                                    id: topSaveText
                                    anchors.centerIn: parent
                                    text: "Save & Apply Profile"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "#ffffff"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.saveCustomAnimation()
                                }
                            }

                            // Close Button
                            Rectangle {
                                height: 32
                                implicitWidth: topCloseText.implicitWidth + 22
                                radius: 8
                                color: topCloseHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase
                                border.color: topCloseHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: topCloseHover }

                                Text {
                                    id: topCloseText
                                    anchors.centerIn: parent
                                    text: "Close"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: topCloseHover.hovered ? root.theme.accentPrimary : root.theme.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.isCreatingCustom = false
                                }
                            }
                        }
                    }

                    // Profile Name Input Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: "Profile Name"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.textPrimary
                            Layout.preferredWidth: 100
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 34
                            radius: 7
                            color: root.theme.bgBase
                            border.color: nameInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                            border.width: 1

                            TextInput {
                                id: nameInput
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textPrimary
                                text: root.newAnimName
                                onTextChanged: root.newAnimName = text
                            }
                        }
                    }

                    // 2. Side-by-Side: Bézier Curve Manager (Left) & Motion Sandbox Preview (Right)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 330
                        spacing: 14

                        // LEFT COLUMN: Bézier Curves Manager
                        Rectangle {
                            id: bezierGraphCard
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: 55
                            radius: 8
                            color: root.theme.bgBase
                            border.color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            clip: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                // Curve Tabs & Action Header Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: "Béziers:"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    // Curve Selectors
                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Repeater {
                                            model: root.studioBeziers

                                            Rectangle {
                                                id: bTabPill
                                                property var bezierTabItem: modelData
                                                property int tabIdx: index
                                                height: 26
                                                implicitWidth: bTabText.implicitWidth + 16
                                                radius: 6
                                                color: root.selectedBezierIndex === tabIdx
                                                    ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                                                    : (bTabHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.06)) : root.theme.bgBase)
                                                border.color: root.selectedBezierIndex === tabIdx
                                                    ? root.theme.accentPrimary
                                                    : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: bTabHover }

                                                Text {
                                                    id: bTabText
                                                    anchors.centerIn: parent
                                                    text: bTabPill.bezierTabItem.name
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                    font.bold: root.selectedBezierIndex === bTabPill.tabIdx
                                                    color: root.selectedBezierIndex === bTabPill.tabIdx ? root.theme.accentPrimary : root.theme.textPrimary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.selectBezier(bTabPill.tabIdx)
                                                }
                                            }
                                        }
                                    }

                                    // Right Action Buttons (+ Add Curve, - Remove)
                                    RowLayout {
                                        spacing: 6
                                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                        // Add Curve Button
                                        Rectangle {
                                            height: 26
                                            implicitWidth: addCurveText.implicitWidth + 18
                                            radius: 6
                                            color: addCurveHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase
                                            border.color: addCurveHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12))
                                            border.width: 1

                                            Behavior on color { ColorAnimation { duration: 140 } }
                                            Behavior on border.color { ColorAnimation { duration: 140 } }

                                            HoverHandler { id: addCurveHover }

                                            Text {
                                                id: addCurveText
                                                anchors.centerIn: parent
                                                text: "+ Add Curve"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.theme.accentPrimary
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.addStudioBezier()
                                            }
                                        }

                                        // Remove Curve Button
                                        Rectangle {
                                            visible: root.studioBeziers.length > 1
                                            height: 26
                                            implicitWidth: remCurveText.implicitWidth + 16
                                            radius: 6
                                            color: remCurveHover.hovered ? Qt.rgba(0.97, 0.46, 0.56, 0.18) : root.theme.bgBase
                                            border.color: remCurveHover.hovered ? (root.theme.accentRed ?? "#f7768e") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                            border.width: 1

                                            Behavior on color { ColorAnimation { duration: 140 } }
                                            Behavior on border.color { ColorAnimation { duration: 140 } }

                                            HoverHandler { id: remCurveHover }

                                            Text {
                                                id: remCurveText
                                                anchors.centerIn: parent
                                                text: "- Remove"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: remCurveHover.hovered ? (root.theme.accentRed ?? "#f7768e") : root.theme.textMuted
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.removeSelectedBezier()
                                            }
                                        }
                                    }
                                }

                                // Selected Curve Name & Template Presets Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: "Name:"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.theme.textSecondary
                                    }

                                    Rectangle {
                                        width: 120
                                        height: 26
                                        radius: 6
                                        color: root.theme.bgBase
                                        border.color: curveNameIn.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                        border.width: 1

                                        TextInput {
                                            id: curveNameIn
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            verticalAlignment: TextInput.AlignVCenter
                                            font.family: root.font
                                            font.pixelSize: 10
                                            color: root.theme.textPrimary
                                            text: root.newCurveName
                                            onTextChanged: {
                                                if (text.trim() !== "" && text !== root.newCurveName) {
                                                    root.updateSelectedBezierName(text.trim());
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Templates:"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.theme.textSecondary
                                    }

                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Repeater {
                                            model: root.curveTemplates

                                            Rectangle {
                                                id: cTplPill
                                                property var tplData: modelData
                                                height: 24
                                                implicitWidth: cTplText.implicitWidth + 14
                                                radius: 6
                                                color: root.newCurvePreset === tplData.name
                                                    ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                                                    : (cTplHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.05)) : root.theme.bgBase)
                                                border.color: root.newCurvePreset === tplData.name
                                                    ? root.theme.accentPrimary
                                                    : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: cTplHover }

                                                Text {
                                                    id: cTplText
                                                    anchors.centerIn: parent
                                                    text: cTplPill.tplData.name
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                    font.bold: root.newCurvePreset === cTplPill.tplData.name
                                                    color: root.newCurvePreset === cTplPill.tplData.name ? root.theme.accentPrimary : root.theme.textSecondary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.selectCurveTemplate(cTplPill.tplData.name, cTplPill.tplData.points)
                                                }
                                            }
                                        }
                                    }
                                }

                                // Interactive Bezier Curve Canvas
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Canvas {
                                        id: bezierCanvas
                                        anchors.fill: parent
                                        antialiasing: true

                                        property string curvePoints: root.newCurvePoints
                                        property var coords: root.parseBezierPoints(root.newCurvePoints)
                                        property int activeDragHandle: 0 // 0: none, 1: P1, 2: P2

                                        onCurvePointsChanged: {
                                            coords = root.parseBezierPoints(root.newCurvePoints);
                                            requestPaint();
                                        }

                                        onWidthChanged: requestPaint()
                                        onHeightChanged: requestPaint()

                                        readonly property real padX: 34
                                        readonly property real padY: 16
                                        readonly property real yMin: -0.6
                                        readonly property real yMax: 1.6
                                        readonly property real ySpan: 2.2

                                        function toCanvasX(x) {
                                            const w = width - padX * 2;
                                            return padX + x * w;
                                        }

                                        function toCanvasY(y) {
                                            const h = height - padY * 2;
                                            return padY + ((yMax - y) / ySpan) * h;
                                        }

                                        function toCurveX(cx) {
                                            const w = width - padX * 2;
                                            if (w <= 0) return 0.0;
                                            const x = (cx - padX) / w;
                                            return Math.max(0.0, Math.min(1.0, x));
                                        }

                                        function toCurveY(cy) {
                                            const h = height - padY * 2;
                                            if (h <= 0) return 0.0;
                                            const norm = (cy - padY) / h;
                                            const y = yMax - norm * ySpan;
                                            return Math.max(-0.6, Math.min(1.6, y));
                                        }

                                        onPaint: {
                                            const ctx = getContext("2d");
                                            ctx.clearRect(0, 0, width, height);

                                            const x0 = coords[0];
                                            const y0 = coords[1];
                                            const x1 = coords[2];
                                            const y1 = coords[3];

                                            const cx0 = toCanvasX(0);
                                            const cy0 = toCanvasY(0);
                                            const cx1 = toCanvasX(1);
                                            const cy1 = toCanvasY(1);

                                            const p1x = toCanvasX(x0);
                                            const p1y = toCanvasY(y0);
                                            const p2x = toCanvasX(x1);
                                            const p2y = toCanvasY(y1);

                                            // Grid reference lines
                                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.10);
                                            ctx.lineWidth = 1;
                                            ctx.setLineDash([4, 4]);
                                            ctx.beginPath();
                                            ctx.moveTo(padX, cy0);
                                            ctx.lineTo(width - padX, cy0);
                                            ctx.stroke();

                                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.12);
                                            ctx.beginPath();
                                            ctx.moveTo(padX, cy1);
                                            ctx.lineTo(width - padX, cy1);
                                            ctx.stroke();

                                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.05);
                                            ctx.beginPath();
                                            ctx.moveTo(cx0, cy0);
                                            ctx.lineTo(cx1, cy1);
                                            ctx.stroke();

                                            ctx.setLineDash([]);

                                            // Axis labels
                                            ctx.font = "8px sans-serif";
                                            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.35);
                                            ctx.textAlign = "right";
                                            ctx.textBaseline = "middle";
                                            ctx.fillText("0.0", padX - 5, cy0);
                                            ctx.fillText("1.0", padX - 5, cy1);

                                            ctx.textAlign = "center";
                                            ctx.textBaseline = "top";
                                            ctx.fillText("0", cx0, cy0 + 3);
                                            ctx.fillText("1", cx1, cy0 + 3);

                                            // Tangent lines from anchors to control points
                                            ctx.strokeStyle = Qt.rgba(1, 0.42, 0.42, 0.55);
                                            ctx.lineWidth = 1.5;
                                            ctx.setLineDash([3, 3]);
                                            ctx.beginPath();
                                            ctx.moveTo(cx0, cy0);
                                            ctx.lineTo(p1x, p1y);
                                            ctx.stroke();

                                            ctx.strokeStyle = Qt.rgba(0.3, 0.67, 0.97, 0.55);
                                            ctx.beginPath();
                                            ctx.moveTo(cx1, cy1);
                                            ctx.lineTo(p2x, p2y);
                                            ctx.stroke();
                                            ctx.setLineDash([]);

                                            // Gradient fill under curve
                                            ctx.beginPath();
                                            ctx.moveTo(cx0, cy0);
                                            ctx.bezierCurveTo(p1x, p1y, p2x, p2y, cx1, cy1);
                                            ctx.lineTo(cx1, cy0);
                                            ctx.lineTo(cx0, cy0);
                                            ctx.closePath();
                                            const grad = ctx.createLinearGradient(0, cy1, 0, cy0);
                                            grad.addColorStop(0, Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.16));
                                            grad.addColorStop(1, Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.0));
                                            ctx.fillStyle = grad;
                                            ctx.fill();

                                            // Cubic Bezier curve stroke
                                            ctx.beginPath();
                                            ctx.moveTo(cx0, cy0);
                                            ctx.bezierCurveTo(p1x, p1y, p2x, p2y, cx1, cy1);
                                            ctx.strokeStyle = root.theme.accentPrimary;
                                            ctx.lineWidth = 2.5;
                                            ctx.stroke();

                                            // Anchors
                                            ctx.fillStyle = "#ffffff";
                                            ctx.beginPath();
                                            ctx.arc(cx0, cy0, 3.5, 0, Math.PI * 2);
                                            ctx.fill();
                                            ctx.beginPath();
                                            ctx.arc(cx1, cy1, 3.5, 0, Math.PI * 2);
                                            ctx.fill();

                                            // Handle P1 (red/coral)
                                            ctx.fillStyle = "#ff6b6b";
                                            ctx.beginPath();
                                            ctx.arc(p1x, p1y, 5.5, 0, Math.PI * 2);
                                            ctx.fill();
                                            ctx.strokeStyle = "#ffffff";
                                            ctx.lineWidth = 1.5;
                                            ctx.stroke();

                                            // Handle P2 (blue/cyan)
                                            ctx.fillStyle = "#4dabf7";
                                            ctx.beginPath();
                                            ctx.arc(p2x, p2y, 5.5, 0, Math.PI * 2);
                                            ctx.fill();
                                            ctx.strokeStyle = "#ffffff";
                                            ctx.lineWidth = 1.5;
                                            ctx.stroke();
                                        }

                                        MouseArea {
                                            id: canvasMouse
                                            anchors.fill: parent
                                            preventStealing: true
                                            hoverEnabled: true

                                            function checkNear(mx, my, px, py, radius) {
                                                const dx = mx - px;
                                                const dy = my - py;
                                                return (dx * dx + dy * dy) <= (radius * radius);
                                            }

                                            onPositionChanged: function(mouse) {
                                                const p1x = bezierCanvas.toCanvasX(bezierCanvas.coords[0]);
                                                const p1y = bezierCanvas.toCanvasY(bezierCanvas.coords[1]);
                                                const p2x = bezierCanvas.toCanvasX(bezierCanvas.coords[2]);
                                                const p2y = bezierCanvas.toCanvasY(bezierCanvas.coords[3]);

                                                if (bezierCanvas.activeDragHandle === 1) {
                                                    mouse.accepted = true;
                                                    const nx = bezierCanvas.toCurveX(mouse.x);
                                                    const ny = bezierCanvas.toCurveY(mouse.y);
                                                    const c = bezierCanvas.coords;
                                                    const newPts = nx.toFixed(2) + ", " + ny.toFixed(2) + ", " + c[2].toFixed(2) + ", " + c[3].toFixed(2);
                                                    root.updateSelectedBezierCurve(newPts);
                                                    root.newCurvePreset = "Custom";
                                                } else if (bezierCanvas.activeDragHandle === 2) {
                                                    mouse.accepted = true;
                                                    const nx = bezierCanvas.toCurveX(mouse.x);
                                                    const ny = bezierCanvas.toCurveY(mouse.y);
                                                    const c = bezierCanvas.coords;
                                                    const newPts = c[0].toFixed(2) + ", " + c[1].toFixed(2) + ", " + nx.toFixed(2) + ", " + ny.toFixed(2);
                                                    root.updateSelectedBezierCurve(newPts);
                                                    root.newCurvePreset = "Custom";
                                                } else {
                                                    const nearP1 = checkNear(mouse.x, mouse.y, p1x, p1y, 16);
                                                    const nearP2 = checkNear(mouse.x, mouse.y, p2x, p2y, 16);
                                                    cursorShape = (nearP1 || nearP2) ? Qt.PointingHandCursor : Qt.ArrowCursor;
                                                }
                                            }

                                            onPressed: function(mouse) {
                                                const p1x = bezierCanvas.toCanvasX(bezierCanvas.coords[0]);
                                                const p1y = bezierCanvas.toCanvasY(bezierCanvas.coords[1]);
                                                const p2x = bezierCanvas.toCanvasX(bezierCanvas.coords[2]);
                                                const p2y = bezierCanvas.toCanvasY(bezierCanvas.coords[3]);

                                                if (checkNear(mouse.x, mouse.y, p1x, p1y, 20)) {
                                                    mouse.accepted = true;
                                                    bezierCanvas.activeDragHandle = 1;
                                                    cursorShape = Qt.ClosedHandCursor;
                                                } else if (checkNear(mouse.x, mouse.y, p2x, p2y, 20)) {
                                                    mouse.accepted = true;
                                                    bezierCanvas.activeDragHandle = 2;
                                                    cursorShape = Qt.ClosedHandCursor;
                                                }
                                            }

                                            onReleased: function(mouse) {
                                                if (bezierCanvas.activeDragHandle !== 0) {
                                                    mouse.accepted = true;
                                                    bezierCanvas.activeDragHandle = 0;
                                                    cursorShape = Qt.ArrowCursor;
                                                    root.triggerPreview();
                                                }
                                            }
                                        }
                                    }
                                }

                                // Legend & Coordinates Input
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    RowLayout {
                                        spacing: 4
                                        Rectangle { width: 7; height: 7; radius: 3.5; color: "#ff6b6b" }
                                        Text {
                                            text: "P1: (" + bezierCanvas.coords[0].toFixed(2) + ", " + bezierCanvas.coords[1].toFixed(2) + ")"
                                            font.family: root.font
                                            font.pixelSize: 9
                                            color: "#ff8787"
                                        }
                                    }

                                    RowLayout {
                                        spacing: 4
                                        Rectangle { width: 7; height: 7; radius: 3.5; color: "#4dabf7" }
                                        Text {
                                            text: "P2: (" + bezierCanvas.coords[2].toFixed(2) + ", " + bezierCanvas.coords[3].toFixed(2) + ")"
                                            font.family: root.font
                                            font.pixelSize: 9
                                            color: "#74c0fc"
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: "Points:"
                                        font.family: root.font
                                        font.pixelSize: 9
                                        color: root.theme.textMuted
                                    }

                                    Rectangle {
                                        width: 140
                                        height: 22
                                        radius: 4
                                        color: root.theme.bgSurface
                                        border.color: coordIn.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                        border.width: 1

                                        TextInput {
                                            id: coordIn
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            verticalAlignment: TextInput.AlignVCenter
                                            font.family: root.font
                                            font.pixelSize: 9
                                            color: root.theme.textPrimary
                                            text: root.newCurvePoints
                                            onEditingFinished: {
                                                root.updateSelectedBezierCurve(text);
                                                root.newCurvePreset = "Custom";
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // RIGHT COLUMN: Live Motion Sandbox Preview
                        Rectangle {
                            id: studioPreviewCard
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: 45
                            radius: 8
                            color: root.theme.bgBase
                            border.color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            clip: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                // Sandbox Header with Mode Switcher & Replay
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: "Motion Sandbox"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Mode Switcher (Strictly text-only)
                                    RowLayout {
                                        spacing: 4
                                        Repeater {
                                            model: [
                                                { id: "windowsIn", label: "Window Open" },
                                                { id: "windowsOut", label: "Window Close" },
                                                { id: "layersIn", label: "Layer / Popup" },
                                                { id: "workspaces", label: "Workspace" }
                                            ]

                                            Rectangle {
                                                id: sModePill
                                                property var sModeItem: modelData
                                                height: 26
                                                implicitWidth: sModeText.implicitWidth + 16
                                                radius: 6
                                                color: root.previewMode === sModeItem.id
                                                    ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                                                    : (sModeHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.05)) : root.theme.bgBase)
                                                border.color: root.previewMode === sModeItem.id
                                                    ? root.theme.accentPrimary
                                                    : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 140 } }
                                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: sModeHover }

                                                Text {
                                                    id: sModeText
                                                    anchors.centerIn: parent
                                                    text: sModePill.sModeItem.label
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                    font.bold: root.previewMode === sModePill.sModeItem.id
                                                    color: root.previewMode === sModePill.sModeItem.id ? root.theme.accentPrimary : root.theme.textSecondary
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.previewMode = sModePill.sModeItem.id;
                                                        root.triggerPreview();
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Replay button
                                    Rectangle {
                                        height: 26
                                        implicitWidth: replayText.implicitWidth + 18
                                        radius: 6
                                        color: replayHover.hovered ? Qt.darker(root.theme.accentPrimary, 1.1) : root.theme.accentPrimary
                                        Behavior on color { ColorAnimation { duration: 140 } }

                                        HoverHandler { id: replayHover }

                                        Text {
                                            id: replayText
                                            anchors.centerIn: parent
                                            text: "Replay"
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: "#ffffff"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.triggerPreview()
                                        }
                                    }
                                }

                                // Interactive Simulated Stage
                                Rectangle {
                                    id: previewStage
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 6
                                    color: Qt.rgba(0, 0, 0, 0.22)
                                    clip: true
                                    border.color: Qt.rgba(1, 1, 1, 0.04)
                                    border.width: 1

                                    // 1. WINDOW OPEN / CLOSE SIMULATION
                                    Rectangle {
                                        id: studioMockWindow
                                        visible: root.previewMode === "windowsIn" || root.previewMode === "windowsOut"
                                        width: 150
                                        height: 72
                                        radius: 6
                                        anchors.centerIn: parent
                                        color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12)
                                        border.color: root.theme.accentPrimary
                                        border.width: 1.5

                                        readonly property real effectiveP: root.previewMode === "windowsOut" ? (1.0 - root.animProgress) : root.animProgress

                                        scale: {
                                            if (root.currentPreviewStyle.indexOf("popin 60%") !== -1) {
                                                return Math.max(0.1, 0.6 + effectiveP * 0.4);
                                            } else if (root.currentPreviewStyle.indexOf("popin") !== -1) {
                                                return Math.max(0.1, 0.8 + effectiveP * 0.2);
                                            } else if (root.currentPreviewStyle.indexOf("gnomed") !== -1) {
                                                return Math.max(0.1, 0.88 + effectiveP * 0.12);
                                            }
                                            return 1.0;
                                        }

                                        opacity: Math.max(0.0, Math.min(1.0, effectiveP * 1.5))

                                        transform: Translate {
                                            y: {
                                                if (root.currentPreviewStyle.indexOf("slide") !== -1) {
                                                    return (1.0 - studioMockWindow.effectiveP) * 50;
                                                }
                                                return 0;
                                            }
                                        }

                                        // Window Header Bar
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: 18
                                            radius: 6
                                            color: Qt.rgba(1, 1, 1, 0.06)

                                            Row {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 6
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 4
                                                Rectangle { width: 5; height: 5; radius: 2.5; color: "#f7768e" }
                                                Rectangle { width: 5; height: 5; radius: 2.5; color: "#e0af68" }
                                                Rectangle { width: 5; height: 5; radius: 2.5; color: "#9ece6a" }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.newAnimName || "Window"
                                                font.family: root.font
                                                font.pixelSize: 8
                                                color: root.theme.textSecondary
                                                elide: Text.ElideRight
                                                width: 80
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }

                                        // Window Body Text
                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            anchors.verticalCenterOffset: 6
                                            spacing: 2

                                            Text {
                                                text: root.previewMode === "windowsIn" ? "WINDOW OPENING" : "WINDOW CLOSING"
                                                font.family: root.font
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: root.theme.accentPrimary
                                                Layout.alignment: Qt.AlignHCenter
                                            }

                                            Text {
                                                text: "Curve: " + root.currentPreviewCurveName + " • " + root.currentPreviewStyle
                                                font.family: root.font
                                                font.pixelSize: 8
                                                color: root.theme.textSecondary
                                                Layout.alignment: Qt.AlignHCenter
                                            }
                                        }
                                    }

                                    // 2. LAYER / POPUP SIMULATION
                                    Item {
                                        id: layerSimulationArea
                                        visible: root.previewMode === "layersIn"
                                        anchors.fill: parent

                                        // Mock Panel Bar at Top
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: 18
                                            color: Qt.rgba(1, 1, 1, 0.05)
                                            border.color: Qt.rgba(1, 1, 1, 0.08)
                                            border.width: 1

                                            Row {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 8
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 6
                                                Text { text: "Panel / Waybar"; font.family: root.font; font.pixelSize: 8; color: root.theme.textMuted }
                                            }
                                        }

                                        // Mock Popup Card Dropping Down
                                        Rectangle {
                                            width: 140
                                            height: 60
                                            radius: 6
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)
                                            border.color: root.theme.accentPrimary
                                            border.width: 1.5

                                            y: {
                                                if (root.currentPreviewStyle.indexOf("popin") !== -1) {
                                                    return 26;
                                                }
                                                return 8 + root.animProgress * 18;
                                            }

                                            scale: root.currentPreviewStyle.indexOf("popin") !== -1
                                                ? Math.max(0.1, 0.8 + root.animProgress * 0.2)
                                                : 1.0

                                            opacity: Math.max(0.0, Math.min(1.0, root.animProgress * 1.5))

                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: 2
                                                Text {
                                                    text: "POPUP / LAUNCHER"
                                                    font.family: root.font
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: root.theme.accentPrimary
                                                    Layout.alignment: Qt.AlignHCenter
                                                }
                                                Text {
                                                    text: "layersIn • " + root.currentPreviewStyle
                                                    font.family: root.font
                                                    font.pixelSize: 8
                                                    color: root.theme.textSecondary
                                                    Layout.alignment: Qt.AlignHCenter
                                                }
                                            }
                                        }
                                    }

                                    // 3. WORKSPACE TRANSITION SIMULATION
                                    Item {
                                        id: workspaceSimulationArea
                                        visible: root.previewMode === "workspaces"
                                        anchors.fill: parent

                                        readonly property bool isVert: root.currentPreviewStyle.indexOf("vert") !== -1
                                        readonly property real p: root.animProgress

                                        // Workspace 1 (Exiting)
                                        Rectangle {
                                            width: 110
                                            height: 60
                                            radius: 6
                                            color: Qt.rgba(1, 1, 1, 0.05)
                                            border.color: Qt.rgba(1, 1, 1, 0.1)
                                            border.width: 1

                                            x: workspaceSimulationArea.isVert
                                                ? (parent.width - width) / 2
                                                : ((parent.width - width) / 2 - workspaceSimulationArea.p * (parent.width * 0.55))

                                            y: workspaceSimulationArea.isVert
                                                ? ((parent.height - height) / 2 - workspaceSimulationArea.p * (parent.height * 0.65))
                                                : ((parent.height - height) / 2)

                                            opacity: Math.max(0.0, 1.0 - workspaceSimulationArea.p)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "WS 1 (Old)"
                                                font.family: root.font
                                                font.pixelSize: 9
                                                color: root.theme.textMuted
                                            }
                                        }

                                        // Workspace 2 (Entering)
                                        Rectangle {
                                            width: 110
                                            height: 60
                                            radius: 6
                                            color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12)
                                            border.color: root.theme.accentPrimary
                                            border.width: 1.5

                                            x: workspaceSimulationArea.isVert
                                                ? (parent.width - width) / 2
                                                : ((parent.width - width) / 2 + (1.0 - workspaceSimulationArea.p) * (parent.width * 0.55))

                                            y: workspaceSimulationArea.isVert
                                                ? ((parent.height - height) / 2 + (1.0 - workspaceSimulationArea.p) * (parent.height * 0.65))
                                                : ((parent.height - height) / 2)

                                            opacity: Math.max(0.0, Math.min(1.0, workspaceSimulationArea.p * 1.5))

                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: 2
                                                Text {
                                                    text: "WS 2 (Active)"
                                                    font.family: root.font
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: root.theme.accentPrimary
                                                    Layout.alignment: Qt.AlignHCenter
                                                }
                                                Text {
                                                    text: root.currentPreviewStyle
                                                    font.family: root.font
                                                    font.pixelSize: 8
                                                    color: root.theme.textSecondary
                                                    Layout.alignment: Qt.AlignHCenter
                                                }
                                            }
                                        }
                                    }
                                }

                                // Sandbox Information Badges
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: "Target: " + root.previewMode
                                        font.family: root.font
                                        font.pixelSize: 9
                                        color: root.theme.textSecondary
                                    }

                                    Text {
                                        text: "• Curve: " + root.currentPreviewCurveName
                                        font.family: root.font
                                        font.pixelSize: 9
                                        color: root.theme.accentPrimary
                                    }

                                    Text {
                                        text: "• Speed: " + root.currentPreviewSpeed + " (" + (root.currentPreviewSpeed * 100) + "ms)"
                                        font.family: root.font
                                        font.pixelSize: 9
                                        color: root.theme.textSecondary
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: "Style: " + (root.currentPreviewStyle || "default")
                                        font.family: root.font
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }
                                }
                            }
                        }
                    }

                    // 3. Categorized Hyprland Animation Rules Tree
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        // Section Header & Global Action
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                spacing: 3
                                Layout.fillWidth: true

                                Text {
                                    text: "Compositor Animation Rules (Hyprland Tree)"
                                    font.family: root.font
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.theme.textPrimary
                                }

                                Text {
                                    text: "Configure target rules, speeds, and Bézier easing curves according to Hyprland's official animation tree"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textSecondary
                                }
                            }

                            // Expand All / Collapse All Toggle Button
                            Rectangle {
                                height: 30
                                implicitWidth: expBtnText.implicitWidth + 24
                                radius: 7
                                color: expHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgSurface
                                border.color: expHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: expHover }

                                Text {
                                    id: expBtnText
                                    anchors.centerIn: parent
                                    text: root.expandAllRules ? "Collapse All" : "Expand All"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: expHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.expandAllRules = !root.expandAllRules
                                }
                            }
                        }

                        /* Sub-Tab Navigation Bar (Matching HyprlandSettings & BarSettings) */
                        Rectangle {
                            id: subTabTrack
                            Layout.fillWidth: true
                            height: 40
                            radius: 10
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Repeater {
                                    model: [
                                        { id: "All", label: "All Rules" },
                                        { id: "Windows", label: "Windows" },
                                        { id: "Layers", label: "Layers" },
                                        { id: "Workspaces", label: "Workspaces" },
                                        { id: "Fades & Borders", label: "Fades & Borders" }
                                    ]
                                    delegate: Rectangle {
                                        id: subTabItem
                                        required property var modelData
                                        readonly property bool isCurrent: root.studioCategoryFilter === modelData.id

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
                                            spacing: 6

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
                                            onClicked: root.studioCategoryFilter = subTabItem.modelData.id
                                        }
                                    }
                                }
                            }
                        }

                        // Category Groups
                        Repeater {
                            model: root.studioCategories

                            Rectangle {
                                id: catGroupCard
                                property string catName: modelData
                                readonly property bool matchesFilter: root.studioCategoryFilter === "All" || root.studioCategoryFilter === catName
                                visible: matchesFilter
                                Layout.fillWidth: true
                                radius: 0
                                color: "transparent"
                                border.width: 0
                                implicitHeight: visible ? (catCol.implicitHeight + (root.studioCategoryFilter === "All" ? 8 : 0)) : 0

                                ColumnLayout {
                                    id: catCol
                                    anchors.fill: parent
                                    spacing: 8

                                    // Category Header (Visible when viewing All)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.topMargin: 4
                                        Layout.bottomMargin: 2
                                        spacing: 8
                                        visible: root.studioCategoryFilter === "All"

                                        Text {
                                            text: catGroupCard.catName.toUpperCase()
                                            font.family: root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: root.theme.accentPrimary
                                            Layout.leftMargin: 4
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 1
                                            color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                        }
                                    }

                                    // Rules in this category
                                    Repeater {
                                        model: root.getRulesForCategory(catGroupCard.catName)

                                        Rectangle {
                                            id: ruleRowCard
                                            property var ruleItem: modelData
                                            property bool localExpanded: false
                                            readonly property bool isExpanded: root.expandAllRules ? true : localExpanded

                                            Layout.fillWidth: true
                                            radius: 12
                                            color: ruleRowCard.ruleItem.enabled ? root.theme.bgSurface : Qt.rgba(0, 0, 0, 0.15)
                                            border.color: isExpanded && ruleRowCard.ruleItem.enabled
                                                ? root.theme.accentPrimary
                                                : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                            border.width: 1
                                            implicitHeight: ruleRowCol.implicitHeight + 24
                                            clip: true

                                            Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                            Behavior on border.color { ColorAnimation { duration: 160 } }
                                            Behavior on color { ColorAnimation { duration: 160 } }

                                            ColumnLayout {
                                                id: ruleRowCol
                                                anchors.fill: parent
                                                anchors.margins: 12
                                                spacing: 12

                                                // Top row: Title, Target tag, Description, and Actions
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 12

                                                    // Left: Clickable title/desc area that toggles expansion
                                                    Item {
                                                        Layout.fillWidth: true
                                                        implicitHeight: titleCol.implicitHeight

                                                        ColumnLayout {
                                                            id: titleCol
                                                            anchors.fill: parent
                                                            spacing: 3

                                                            RowLayout {
                                                                spacing: 8
                                                                Text {
                                                                    text: ruleRowCard.ruleItem.title || ruleRowCard.ruleItem.target
                                                                    font.family: root.font
                                                                    font.pixelSize: 13
                                                                    font.bold: true
                                                                    color: ruleRowCard.ruleItem.enabled ? root.theme.textPrimary : root.theme.textMuted
                                                                }

                                                                Rectangle {
                                                                    height: 18
                                                                    implicitWidth: targetTagText.implicitWidth + 10
                                                                    radius: 4
                                                                    color: Qt.rgba(1, 1, 1, 0.06)
                                                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                                                    border.width: 1

                                                                    Text {
                                                                        id: targetTagText
                                                                        anchors.centerIn: parent
                                                                        text: ruleRowCard.ruleItem.target
                                                                        font.family: "monospace"
                                                                        font.pixelSize: 10
                                                                        color: root.theme.textSecondary
                                                                    }
                                                                }
                                                            }

                                                            Text {
                                                                text: ruleRowCard.ruleItem.desc || ""
                                                                font.family: root.font
                                                                font.pixelSize: 11
                                                                color: root.theme.textSecondary
                                                                visible: text !== ""
                                                                elide: Text.ElideRight
                                                                Layout.fillWidth: true
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: ruleRowCard.ruleItem.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                            onClicked: {
                                                                if (ruleRowCard.ruleItem.enabled) {
                                                                    ruleRowCard.localExpanded = !ruleRowCard.isExpanded;
                                                                }
                                                            }
                                                        }
                                                    }

                                                    // Right: Summary badge, Preview, Toggle Switch, Expand Button
                                                    RowLayout {
                                                        spacing: 8
                                                        Layout.alignment: Qt.AlignVCenter

                                                        // Summary Badge (When enabled & collapsed)
                                                        Rectangle {
                                                            visible: ruleRowCard.ruleItem.enabled && !ruleRowCard.isExpanded
                                                            height: 26
                                                            implicitWidth: summaryBadgeText.implicitWidth + 16
                                                            radius: 6
                                                            color: root.theme.bgBase
                                                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                                            border.width: 1

                                                            Text {
                                                                id: summaryBadgeText
                                                                anchors.centerIn: parent
                                                                text: {
                                                                    const c = ruleRowCard.ruleItem.curve || "default";
                                                                    const sp = ruleRowCard.ruleItem.speed + " (" + (ruleRowCard.ruleItem.speed * 100) + "ms)";
                                                                    const st = (ruleRowCard.ruleItem.style && ruleRowCard.ruleItem.style !== "") ? (" • " + ruleRowCard.ruleItem.style) : "";
                                                                    return c + " • " + sp + st;
                                                                }
                                                                font.family: root.font
                                                                font.pixelSize: 10
                                                                color: root.theme.textSecondary
                                                            }
                                                        }

                                                        // Quick Preview Button (Styled matching DisplaySettings buttons)
                                                        Rectangle {
                                                            visible: ruleRowCard.ruleItem.enabled
                                                            height: 28
                                                            implicitWidth: rPrevText.implicitWidth + 20
                                                            radius: 7
                                                            color: rPrevHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase
                                                            border.color: rPrevHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                                                            border.width: 1

                                                            Behavior on color { ColorAnimation { duration: 140 } }
                                                            Behavior on border.color { ColorAnimation { duration: 140 } }

                                                            HoverHandler { id: rPrevHover }

                                                            Text {
                                                                id: rPrevText
                                                                anchors.centerIn: parent
                                                                text: "Preview"
                                                                font.family: root.font
                                                                font.pixelSize: 11
                                                                font.bold: true
                                                                color: rPrevHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    const tgt = ruleRowCard.ruleItem.target;
                                                                    if (tgt.indexOf("workspace") !== -1) root.previewMode = "workspaces";
                                                                    else if (tgt.indexOf("layer") !== -1) root.previewMode = "layersIn";
                                                                    else if (tgt === "windowsOut") root.previewMode = "windowsOut";
                                                                    else root.previewMode = "windowsIn";
                                                                    root.triggerPreview();
                                                                }
                                                            }
                                                        }

                                                        // Standard Animated Toggle Switch (Matches SettingToggleRow)
                                                        Rectangle {
                                                            id: toggleSwitch
                                                            width: 44
                                                            height: 24
                                                            radius: 12
                                                            color: ruleRowCard.ruleItem.enabled ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                                                            Layout.alignment: Qt.AlignVCenter

                                                            Behavior on color { ColorAnimation { duration: 160 } }

                                                            Rectangle {
                                                                width: 18
                                                                height: 18
                                                                radius: 9
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                x: ruleRowCard.ruleItem.enabled ? parent.width - width - 3 : 3
                                                                color: ruleRowCard.ruleItem.enabled ? "#ffffff" : root.theme.textPrimary

                                                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    root.updateRuleField(ruleRowCard.ruleItem.target, "enabled", !ruleRowCard.ruleItem.enabled);
                                                                    root.showStatus(ruleRowCard.ruleItem.title + ": " + (!ruleRowCard.ruleItem.enabled ? "Enabled" : "Disabled"));
                                                                }
                                                            }
                                                        }

                                                        // Expand / Collapse Chevron Button
                                                        Rectangle {
                                                            visible: ruleRowCard.ruleItem.enabled
                                                            height: 28
                                                            width: 28
                                                            radius: 14
                                                            color: expChevronHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"

                                                            Behavior on color { ColorAnimation { duration: 140 } }

                                                            HoverHandler { id: expChevronHover }

                                                            Text {
                                                                id: chevronGlyph
                                                                anchors.centerIn: parent
                                                                text: "▾"
                                                                font.family: root.font
                                                                font.pixelSize: 13
                                                                color: ruleRowCard.isExpanded ? root.theme.accentPrimary : root.theme.textSecondary

                                                                transform: Rotation {
                                                                    origin.x: chevronGlyph.width / 2
                                                                    origin.y: chevronGlyph.height / 2
                                                                    angle: ruleRowCard.isExpanded ? 180 : 0
                                                                    Behavior on angle { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                                                }
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: ruleRowCard.localExpanded = !ruleRowCard.isExpanded
                                                            }
                                                        }
                                                    }
                                                }

                                                // Expandable Settings Body (Matching SettingSliderRow style)
                                                ColumnLayout {
                                                    visible: ruleRowCard.ruleItem.enabled && ruleRowCard.isExpanded
                                                    Layout.fillWidth: true
                                                    spacing: 12
                                                    Layout.topMargin: 2

                                                    // Divider
                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        height: 1
                                                        color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                                    }

                                                    // 1. Easing Curve Row
                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 46
                                                        spacing: 12

                                                        ColumnLayout {
                                                            spacing: 2
                                                            Layout.alignment: Qt.AlignVCenter
                                                            Layout.preferredWidth: 150
                                                            Layout.fillWidth: false

                                                            Text {
                                                                text: "Easing Curve"
                                                                font.family: root.font
                                                                font.pixelSize: 13
                                                                font.bold: true
                                                                color: root.theme.textPrimary
                                                            }

                                                            Text {
                                                                text: "Bézier velocity profile"
                                                                font.family: root.font
                                                                font.pixelSize: 11
                                                                color: root.theme.textSecondary
                                                            }
                                                        }

                                                        Item { Layout.fillWidth: true }

                                                        // Segmented Curve Track with Sliding Pill
                                                        Rectangle {
                                                            id: curveTrack
                                                            readonly property var curveList: root.studioBeziers || []
                                                            readonly property int activeIdx: {
                                                                for (let i = 0; i < curveList.length; i++) {
                                                                    if (curveList[i].name === ruleRowCard.ruleItem.curve) return i;
                                                                }
                                                                return -1;
                                                            }
                                                            readonly property int count: curveList.length
                                                            implicitWidth: Math.min(ruleRowCol.width - 170, count * 90 + 6 + (count - 1) * 3)
                                                            width: implicitWidth
                                                            Layout.preferredWidth: implicitWidth
                                                            Layout.preferredHeight: 32
                                                            height: 32
                                                            radius: 7
                                                            color: root.theme.bgBase
                                                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                                            border.width: 1
                                                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                                            readonly property real cellWidth: count > 0 ? ((width - 6 - (count - 1) * 3) / count) : 0

                                                            /* Sliding Selection Pill */
                                                            Rectangle {
                                                                visible: curveTrack.activeIdx >= 0
                                                                y: 3
                                                                height: parent.height - 6
                                                                width: curveTrack.cellWidth
                                                                x: 3 + Math.max(0, curveTrack.activeIdx) * (curveTrack.cellWidth + 3)
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
                                                                    model: curveTrack.curveList
                                                                    delegate: Rectangle {
                                                                        id: cBtn
                                                                        required property var modelData
                                                                        required property int index
                                                                        readonly property bool isSel: curveTrack.activeIdx === cBtn.index

                                                                        Layout.preferredWidth: curveTrack.cellWidth
                                                                        Layout.minimumWidth: 0
                                                                        Layout.fillWidth: true
                                                                        Layout.fillHeight: true
                                                                        radius: 5
                                                                        color: !isSel && cHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                                                        Behavior on color { ColorAnimation { duration: 140 } }

                                                                        HoverHandler { id: cHover }

                                                                        Text {
                                                                            anchors.centerIn: parent
                                                                            text: cBtn.modelData.name
                                                                            font.family: root.font
                                                                            font.pixelSize: 10
                                                                            font.bold: cBtn.isSel
                                                                            color: cBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                                            elide: Text.ElideRight
                                                                            maximumLineCount: 1
                                                                        }

                                                                        MouseArea {
                                                                            anchors.fill: parent
                                                                            cursorShape: Qt.PointingHandCursor
                                                                            onClicked: root.updateRuleField(ruleRowCard.ruleItem.target, "curve", cBtn.modelData.name)
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    // Divider
                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        height: 1
                                                        color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                                    }

                                                    // 2. Speed Factor Row
                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 46
                                                        spacing: 12

                                                        ColumnLayout {
                                                            spacing: 2
                                                            Layout.alignment: Qt.AlignVCenter
                                                            Layout.preferredWidth: 150
                                                            Layout.fillWidth: false

                                                            Text {
                                                                text: "Speed Factor"
                                                                font.family: root.font
                                                                font.pixelSize: 13
                                                                font.bold: true
                                                                color: root.theme.textPrimary
                                                            }

                                                            Text {
                                                                text: (ruleRowCard.ruleItem.speed * 100) + "ms" + (ruleRowCard.ruleItem.speed <= 2 ? " (Snappy)" : ruleRowCard.ruleItem.speed >= 8 ? " (Cinematic)" : " (Balanced)")
                                                                font.family: root.font
                                                                font.pixelSize: 11
                                                                color: root.theme.accentPrimary
                                                            }
                                                        }

                                                        Item { Layout.fillWidth: true }

                                                        // Segmented Speed Track with Sliding Pill
                                                        Rectangle {
                                                            id: speedTrack
                                                            readonly property var speedList: ruleRowCard.ruleItem.target === "borderangle"
                                                                ? [5, 10, 20, 30, 45, 60]
                                                                : [1, 2, 3, 4, 5, 6, 8, 10]
                                                            readonly property int activeIdx: {
                                                                const val = Number(ruleRowCard.ruleItem.speed);
                                                                for (let i = 0; i < speedList.length; i++) {
                                                                    if (Number(speedList[i]) === val) return i;
                                                                }
                                                                return -1;
                                                            }
                                                            readonly property int count: speedList.length
                                                            implicitWidth: Math.min(ruleRowCol.width - 170, count * 44 + 6 + (count - 1) * 3)
                                                            width: implicitWidth
                                                            Layout.preferredWidth: implicitWidth
                                                            Layout.preferredHeight: 32
                                                            height: 32
                                                            radius: 7
                                                            color: root.theme.bgBase
                                                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                                            border.width: 1
                                                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                                            readonly property real cellWidth: count > 0 ? ((width - 6 - (count - 1) * 3) / count) : 0

                                                            /* Sliding Selection Pill */
                                                            Rectangle {
                                                                visible: speedTrack.activeIdx >= 0
                                                                y: 3
                                                                height: parent.height - 6
                                                                width: speedTrack.cellWidth
                                                                x: 3 + Math.max(0, speedTrack.activeIdx) * (speedTrack.cellWidth + 3)
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
                                                                    model: speedTrack.speedList
                                                                    delegate: Rectangle {
                                                                        id: spBtn
                                                                        required property var modelData
                                                                        required property int index
                                                                        readonly property bool isSel: speedTrack.activeIdx === spBtn.index

                                                                        Layout.preferredWidth: speedTrack.cellWidth
                                                                        Layout.minimumWidth: 0
                                                                        Layout.fillWidth: true
                                                                        Layout.fillHeight: true
                                                                        radius: 5
                                                                        color: !isSel && spHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                                                        Behavior on color { ColorAnimation { duration: 140 } }

                                                                        HoverHandler { id: spHover }

                                                                        Text {
                                                                            anchors.centerIn: parent
                                                                            text: String(spBtn.modelData)
                                                                            font.family: root.font
                                                                            font.pixelSize: 11
                                                                            font.bold: spBtn.isSel
                                                                            color: spBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                                        }

                                                                        MouseArea {
                                                                            anchors.fill: parent
                                                                            cursorShape: Qt.PointingHandCursor
                                                                            onClicked: root.updateRuleField(ruleRowCard.ruleItem.target, "speed", Number(spBtn.modelData))
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    // 3. Motion Style Row (if applicable)
                                                    ColumnLayout {
                                                        visible: Boolean(ruleRowCard.ruleItem.styles && ruleRowCard.ruleItem.styles.length > 0 && ruleRowCard.ruleItem.styles[0] !== "")
                                                        Layout.fillWidth: true
                                                        spacing: 12

                                                        // Divider
                                                        Rectangle {
                                                            Layout.fillWidth: true
                                                            height: 1
                                                            color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                                        }

                                                        RowLayout {
                                                            Layout.fillWidth: true
                                                            Layout.preferredHeight: 46
                                                            spacing: 12

                                                            ColumnLayout {
                                                                spacing: 2
                                                                Layout.alignment: Qt.AlignVCenter
                                                                Layout.preferredWidth: 150
                                                                Layout.fillWidth: false

                                                                Text {
                                                                    text: "Motion Style"
                                                                    font.family: root.font
                                                                    font.pixelSize: 13
                                                                    font.bold: true
                                                                    color: root.theme.textPrimary
                                                                }

                                                                Text {
                                                                    text: "Compositor visual effect"
                                                                    font.family: root.font
                                                                    font.pixelSize: 11
                                                                    color: root.theme.textSecondary
                                                                }
                                                            }

                                                            Item { Layout.fillWidth: true }

                                                            // Segmented Style Track with Sliding Pill
                                                            Rectangle {
                                                                id: styleTrack
                                                                readonly property var styleList: (ruleRowCard.ruleItem.styles || []).filter(s => s !== "")
                                                                readonly property int activeIdx: styleList.indexOf(ruleRowCard.ruleItem.style)
                                                                readonly property int count: styleList.length
                                                                implicitWidth: Math.min(ruleRowCol.width - 170, count * 96 + 6 + (count - 1) * 3)
                                                                width: implicitWidth
                                                                Layout.preferredWidth: implicitWidth
                                                                Layout.preferredHeight: 32
                                                                height: 32
                                                                radius: 7
                                                                color: root.theme.bgBase
                                                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                                                border.width: 1
                                                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                                                                readonly property real cellWidth: count > 0 ? ((width - 6 - (count - 1) * 3) / count) : 0

                                                                /* Sliding Selection Pill */
                                                                Rectangle {
                                                                    visible: styleTrack.activeIdx >= 0
                                                                    y: 3
                                                                    height: parent.height - 6
                                                                    width: styleTrack.cellWidth
                                                                    x: 3 + Math.max(0, styleTrack.activeIdx) * (styleTrack.cellWidth + 3)
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
                                                                        model: styleTrack.styleList
                                                                        delegate: Rectangle {
                                                                            id: stBtn
                                                                            required property var modelData
                                                                            required property int index
                                                                            readonly property bool isSel: styleTrack.activeIdx === stBtn.index

                                                                            Layout.preferredWidth: styleTrack.cellWidth
                                                                            Layout.minimumWidth: 0
                                                                            Layout.fillWidth: true
                                                                            Layout.fillHeight: true
                                                                            radius: 5
                                                                            color: !isSel && stHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                                                            Behavior on color { ColorAnimation { duration: 140 } }

                                                                            HoverHandler { id: stHover }

                                                                            Text {
                                                                                anchors.centerIn: parent
                                                                                text: String(stBtn.modelData)
                                                                                font.family: root.font
                                                                                font.pixelSize: 10
                                                                                font.bold: stBtn.isSel
                                                                                color: stBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                                                elide: Text.ElideRight
                                                                                maximumLineCount: 1
                                                                            }

                                                                            MouseArea {
                                                                                anchors.fill: parent
                                                                                cursorShape: Qt.PointingHandCursor
                                                                                onClicked: root.updateRuleField(ruleRowCard.ruleItem.target, "style", String(stBtn.modelData))
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
                            }
                        }
                    }

                    // 4. Studio Footer Action Bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // Close Studio Button
                        Rectangle {
                            height: 32
                            implicitWidth: footerCloseText.implicitWidth + 24
                            radius: 7
                            color: footerCloseMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.05))
                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1

                            Text {
                                id: footerCloseText
                                anchors.centerIn: parent
                                text: "Close Studio"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.textSecondary
                            }

                            MouseArea {
                                id: footerCloseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.isCreatingCustom = false
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Test Live Motion on Hyprland
                        Rectangle {
                            height: 32
                            implicitWidth: footerTestText.implicitWidth + 24
                            radius: 7
                            color: footerTestMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.05))
                            border.color: footerTestMouse.containsMouse ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.12))
                            border.width: 1

                            Text {
                                id: footerTestText
                                anchors.centerIn: parent
                                text: "Test Live Motion on Hyprland"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: footerTestMouse.containsMouse ? root.theme.accentPrimary : root.theme.textPrimary
                            }

                            MouseArea {
                                id: footerTestMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.testLiveMotion()
                            }
                        }

                        // Save & Apply Profile
                        Rectangle {
                            height: 32
                            implicitWidth: footerSaveText.implicitWidth + 24
                            radius: 7
                            color: footerSaveMouse.containsMouse ? Qt.darker(root.theme.accentPrimary, 1.1) : root.theme.accentPrimary

                            Text {
                                id: footerSaveText
                                anchors.centerIn: parent
                                text: "Save & Apply Profile"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: "#ffffff"
                            }

                            MouseArea {
                                id: footerSaveMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.saveCustomAnimation()
                            }
                        }
                    }
                }
            }


            // 1. Master Enable / Disable Card (Clean Text-Only AdwActionRow style)
            Rectangle {
                id: masterSwitchCard
                Layout.fillWidth: true
                height: 68
                radius: 12
                color: switchCardMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.04)) : root.theme.bgSurface
                border.color: switchCardMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: switchCardMouse
                    anchors.fill: parent
                    z: 10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setAnimationsEnabled(!root.animationsEnabled)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 18
                    spacing: 14

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        RowLayout {
                            spacing: 8
                            Text {
                                text: "Enable Compositor Animations"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                            }

                            Rectangle {
                                height: 18
                                implicitWidth: globalBadgeText.implicitWidth + 12
                                radius: 9
                                color: Qt.rgba(1, 1, 1, 0.08)
                                border.color: Qt.rgba(1, 1, 1, 0.15)
                                border.width: 1

                                Text {
                                    id: globalBadgeText
                                    anchors.centerIn: parent
                                    text: "Global Scope"
                                    font.family: root.font
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: root.theme.textSecondary
                                }
                            }

                            Rectangle {
                                height: 18
                                implicitWidth: statusBadgeText.implicitWidth + 12
                                radius: 9
                                color: root.animationsEnabled
                                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.15)
                                    : Qt.rgba(1, 1, 1, 0.06)
                                border.color: root.animationsEnabled ? root.theme.accentPrimary : Qt.rgba(1, 1, 1, 0.15)
                                border.width: 1

                                Text {
                                    id: statusBadgeText
                                    anchors.centerIn: parent
                                    text: root.animationsEnabled ? "Active" : "Disabled"
                                    font.family: root.font
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: root.animationsEnabled ? root.theme.accentPrimary : root.theme.textMuted
                                }
                            }
                        }

                        Text {
                            text: "Global Master Switch: controls whether Hyprland plays animations for windows, workspaces, and fades globally"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                        }
                    }

                    // Modern Toggle Switch
                    Rectangle {
                        width: 48
                        height: 26
                        radius: 13
                        color: root.animationsEnabled ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 160 } }

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: root.animationsEnabled ? parent.width - width - 3 : 3
                            color: root.animationsEnabled ? "#ffffff" : root.theme.textPrimary

                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // 2. Preset Selector Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                // Header & Filters
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Animation Profiles & Presets"
                        font.family: root.font
                        font.pixelSize: 14
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "(" + root.filteredPresets.length + " profiles)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                    }

                    Item { Layout.fillWidth: true }

                    // Search input
                    Rectangle {
                        width: 180
                        height: 28
                        radius: 14
                        color: root.theme.bgSurface
                        border.color: searchInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                        border.width: 1

                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textPrimary
                                clip: true
                                verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: root.searchQuery = text

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Search presets..."
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: root.theme.textMuted
                                    visible: !searchInput.text && !searchInput.activeFocus
                                }
                            }
                        }
                    }
                }

                // Family Filter Pills
                Row {
                    spacing: 6
                    Layout.fillWidth: true

                    Repeater {
                        model: root.families

                        Rectangle {
                            required property var modelData
                            height: 26
                            implicitWidth: famText.implicitWidth + 16
                            radius: 13
                            color: root.selectedFamily === modelData
                                ? root.theme.bgSelected
                                : (famMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.05)) : root.theme.bgSurface)
                            border.color: root.selectedFamily === modelData ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Text {
                                id: famText
                                anchors.centerIn: parent
                                text: parent.modelData
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: root.selectedFamily === parent.modelData
                                color: root.selectedFamily === parent.modelData ? root.theme.accentPrimary : root.theme.textSecondary
                            }

                            MouseArea {
                                id: famMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedFamily = parent.modelData
                            }
                        }
                    }
                }

                // Presets Grid Layout
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Repeater {
                        model: root.filteredPresets

                        Rectangle {
                            id: presetCard
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            height: 84
                            radius: 10
                            color: modelData.active
                                ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                                : (cardMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.06)) : root.theme.bgSurface)
                            border.color: modelData.active
                                ? root.theme.accentPrimary
                                : (cardMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.5) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
                            border.width: modelData.active ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                            scale: cardMouse.pressed ? 0.98 : 1.0

                            // Background card click area
                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: presetCard.modelData.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: {
                                    if (!presetCard.modelData.active) {
                                        root.applyPreset(presetCard.modelData.id, presetCard.modelData.displayName);
                                    }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12
                                z: 2

                                // Details column
                                ColumnLayout {
                                    spacing: 3
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    RowLayout {
                                        spacing: 6

                                        Text {
                                            text: presetCard.modelData.displayName || presetCard.modelData.name
                                            font.family: root.font
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: presetCard.modelData.active ? root.theme.accentPrimary : root.theme.textPrimary
                                            elide: Text.ElideRight
                                        }

                                        // Family tag
                                        Rectangle {
                                            height: 16
                                            implicitWidth: famTagText.implicitWidth + 8
                                            radius: 4
                                            color: Qt.rgba(1, 1, 1, 0.06)

                                            Text {
                                                id: famTagText
                                                anchors.centerIn: parent
                                                text: presetCard.modelData.family
                                                font.family: root.font
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: root.theme.textSecondary
                                            }
                                        }
                                    }

                                    Text {
                                        text: presetCard.modelData.description || ""
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    // Bezier and rule count pills
                                    Row {
                                        spacing: 6

                                        Text {
                                            text: presetCard.modelData.bezierCount + " beziers • " + presetCard.modelData.animCount + " rules"
                                            font.family: root.font
                                            font.pixelSize: 9
                                            color: root.theme.textMuted
                                        }
                                    }
                                }

                                // Action Buttons (Edit + Delete for Custom + Apply / Active)
                                RowLayout {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignVCenter

                                    // Edit button to modify custom or clone built-in presets
                                    Rectangle {
                                        height: 28
                                        implicitWidth: editBtnText.implicitWidth + 16
                                        radius: 6
                                        color: editMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : Qt.rgba(1, 1, 1, 0.05)
                                        border.color: editMouse.containsMouse ? root.theme.accentPrimary : Qt.rgba(1, 1, 1, 0.1)
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        Text {
                                            id: editBtnText
                                            anchors.centerIn: parent
                                            text: "Edit"
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: editMouse.containsMouse ? root.theme.accentPrimary : root.theme.textSecondary
                                        }

                                        MouseArea {
                                            id: editMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.editPreset(presetCard.modelData);
                                            }
                                        }
                                    }

                                    // Delete button for user custom profiles
                                    Rectangle {
                                        visible: Boolean(presetCard.modelData.isCustom)
                                        height: 28
                                        implicitWidth: delBtnText.implicitWidth + 16
                                        radius: 6
                                        color: delMouse.containsMouse ? Qt.rgba(0.97, 0.46, 0.56, 0.2) : Qt.rgba(1, 1, 1, 0.05)
                                        border.color: delMouse.containsMouse ? "#f7768e" : Qt.rgba(1, 1, 1, 0.1)
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        Text {
                                            id: delBtnText
                                            anchors.centerIn: parent
                                            text: "Delete"
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: delMouse.containsMouse ? "#f7768e" : root.theme.textMuted
                                        }

                                        MouseArea {
                                            id: delMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.deleteCustomPreset(presetCard.modelData.id);
                                            }
                                        }
                                    }

                                    // Apply / Active Button
                                    Rectangle {
                                        height: 28
                                        implicitWidth: actionBtnText.implicitWidth + 18
                                        radius: 6
                                        color: presetCard.modelData.active
                                            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.15)
                                            : (applyBtnMouse.containsMouse ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.08)))
                                        border.color: presetCard.modelData.active ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            id: actionBtnText
                                            anchors.centerIn: parent
                                            text: presetCard.modelData.active ? "Active" : "Apply"
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: presetCard.modelData.active
                                                ? root.theme.accentPrimary
                                                : (applyBtnMouse.containsMouse ? "#ffffff" : root.theme.textPrimary)
                                        }

                                        MouseArea {
                                            id: applyBtnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: presetCard.modelData.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                                            onClicked: {
                                                if (!presetCard.modelData.active) {
                                                    root.applyPreset(presetCard.modelData.id, presetCard.modelData.displayName);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Empty state when filter has no results
                    Rectangle {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        height: 90
                        radius: 10
                        visible: root.filteredPresets.length === 0
                        color: root.theme.bgSurface
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "No animation profiles match your filter"
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: true
                                color: root.theme.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: root.selectedFamily === "Custom"
                                    ? "Click 'New Animation' above to create your own profile"
                                    : "Try selecting 'All' or clearing your search query"
                                font.family: root.font
                                font.pixelSize: 10
                                color: root.theme.textSecondary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }

            // 4. Active Compositor Curves & Rules Summary
            Rectangle {
                Layout.fillWidth: true
                radius: 12
                color: root.theme.bgSurface
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                implicitHeight: summaryCol.implicitHeight + 28

                ColumnLayout {
                    id: summaryCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Active Bezier Curves & Compositor Rules"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }
                    }

                    // Bezier Chips Flow
                    Text {
                        text: "Configured Bezier Curves (" + root.activeBeziers.length + ")"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: root.activeBeziers

                            Rectangle {
                                id: chipRect
                                required property var modelData
                                height: 26
                                width: chipRow.implicitWidth + 20
                                radius: 6
                                color: root.theme.bgBase
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1

                                RowLayout {
                                    id: chipRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: chipRect.modelData.name
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.theme.accentPrimary
                                    }

                                    Text {
                                        text: "(" + chipRect.modelData.curve + ")"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textMuted
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.05)
                    }

                    // Active Animation Rules
                    Text {
                        text: "Active Animation Rules (" + root.activeRules.length + ")"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: root.activeRules

                            Rectangle {
                                id: ruleRect
                                required property var modelData
                                Layout.fillWidth: true
                                height: 30
                                radius: 6
                                color: Qt.rgba(1, 1, 1, 0.02)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10

                                    Text {
                                        text: ruleRect.modelData.target
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.theme.textPrimary
                                        Layout.preferredWidth: 140
                                    }

                                    Text {
                                        text: "Speed: " + ruleRect.modelData.speed + " • Curve: " + ruleRect.modelData.curve + (ruleRect.modelData.style ? (" • " + ruleRect.modelData.style) : "")
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textSecondary
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: ruleRect.modelData.enabled ? "#9ece6a" : "#f7768e"
                                    }
                                }
                            }
                        }
                    }
                }
            }
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
