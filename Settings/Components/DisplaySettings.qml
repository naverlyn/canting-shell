/*
 * DisplaySettings.qml
 *
 * Comprehensive display management for Hyprland & Quickshell.
 * Inspired by GNOME Settings / Libadwaita (AdwPreferencesPage, AdwPreferencesGroup, AdwExpanderRow, AdwActionRow).
 *
 * Features:
 *   - Clean, text-only authentic GNOME design language
 *   - Interactive inline Monitor Arrangement Canvas powered by MonitorService & MonitorCanvas
 *   - Multi-monitor tab switcher, hotplug detection, overlap validation, and persistent save to monitors.conf
 *   - Per-display configuration: Enable/Disable, Resolution expander with aspect ratios, Refresh Rate pills,
 *     Fractional/Integer Scale pills with logical size preview, 4-way Orientation, and Mirroring
 *   - Screen Brightness group with smooth halo slider and 1-click preset pills
 *   - Compositor & Power group for Variable Refresh Rate (VRR / Adaptive Sync), Allow Tearing, and DPMS sleep
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../MonitorManager"
import "../../MonitorManager/Components"
import ".."
import "./Display"

Item {
    id: root
    property alias dispFlickableRef: dispFlickable
    property var theme
    property string font: "Lato Nerd Font"

    /* Monitor editing state synced with MonitorService */
    property var editState: []
    property int selectedIndex: 0
    property bool isApplying: false
    property string applyError: ""

    /* Inline dropdown expansion states */
    property bool resolutionDropdownOpen: false
    property bool mirrorDropdownOpen: false

    /* Brightness state */
    property int brightness: 100
    property string brightnessDevice: ""
    property bool hasBacklightDevice: false

    /* Night Light state */
    property bool nightLightEnabled: false
    property int nightLightTemp: 4500
    readonly property string nightLightScript: Qt.resolvedUrl("../../ControlCenter/scripts/nightlight.sh").toString().replace(/^file:\/\//, "")

    function getNightLightLabel(temp) {
        if (temp <= 3500) return "Very Warm · Ember glow";
        if (temp <= 4200) return "Warm · Cozy candle tone";
        if (temp <= 4800) return "Balanced · Warm sunlight";
        if (temp <= 5400) return "Mild · Soft incandescent";
        return "Cool · Subtle reduction";
    }

    Process {
        id: nlStatusProc
        command: [root.nightLightScript, "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.nightLightEnabled = (text.trim() === "on")
        }
    }

    Process {
        id: nlSetProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.nightLightEnabled = (text.trim() === "on")
        }
    }

    Timer {
        id: nlDebounceTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (root.nightLightEnabled) {
                nlSetProc.command = [root.nightLightScript, "set", String(root.nightLightTemp)];
                nlSetProc.running = true;
            }
        }
    }

    function setNightLight(enabled) {
        root.nightLightEnabled = enabled;
        nlSetProc.command = [root.nightLightScript, enabled ? "on" : "off", String(root.nightLightTemp)];
        nlSetProc.running = true;
    }

    function setNightLightTemp(temp) {
        const clamped = Math.max(3000, Math.min(6000, Math.round(Number(temp) || 4500)));
        root.nightLightTemp = clamped;
        if (root.nightLightEnabled) {
            nlDebounceTimer.restart();
        }
    }

    /* Compositor display options state */
    property int vrrMode: 0          /* 0 = Off, 1 = On, 2 = Fullscreen only */
    property bool allowTearing: false

    /* Feedback toast state */
    property string statusMessage: ""
    property bool statusVisible: false

    Timer {
        id: statusTimer
        interval: 2600
        repeat: false
        onTriggered: root.statusVisible = false
    }

    function showStatus(msg) {
        root.statusMessage = msg;
        root.statusVisible = true;
        statusTimer.restart();
    }

    function closeAllDropdowns() {
        root.resolutionDropdownOpen = false;
        root.mirrorDropdownOpen = false;
    }

    /* Currently selected monitor object in editState */
    readonly property var selectedMonitor: {
        if (root.selectedIndex >= 0 && root.selectedIndex < root.editState.length) {
            return root.editState[root.selectedIndex];
        }
        return root.editState.length > 0 ? root.editState[0] : null;
    }

    /* Count of enabled monitors */
    readonly property int activeMonitorCount: {
        let count = 0;
        for (let i = 0; i < root.editState.length; i++) {
            if (!root.editState[i].disabled) count++;
        }
        return count;
    }

    /* True when any two enabled, non-mirroring monitors overlap on the canvas */
    readonly property bool hasOverlap: {
        const enabled = root.editState.filter(m => !m.disabled && m.mirrorOf === "");
        for (let i = 0; i < enabled.length; i++) {
            for (let j = i + 1; j < enabled.length; j++) {
                const a = enabled[i], b = enabled[j];
                if (MonitorUtils.overlapsAABB(
                        a.x, a.y, MonitorUtils.logicalW(a), MonitorUtils.logicalH(a),
                        b.x, b.y, MonitorUtils.logicalW(b), MonitorUtils.logicalH(b))) {
                    return true;
                }
            }
        }
        return false;
    }

    /* True when editState differs from live MonitorService.monitors */
    readonly property bool hasUnsavedChanges: {
        const live = MonitorService.monitors;
        if (!live || live.length === 0 || root.editState.length !== live.length) return false;
        for (let i = 0; i < root.editState.length; i++) {
            const e = root.editState[i];
            const l = live.find(m => m.name === e.name);
            if (!l) return true;
            if (e.selectedMode !== l.selectedMode) return true;
            if (e.disabled !== l.disabled) return true;
            if (Math.round(e.x) !== Math.round(l.x)) return true;
            if (Math.round(e.y) !== Math.round(l.y)) return true;
            if (Math.abs(e.scale - l.scale) > 0.01) return true;
            if (e.transform !== l.transform) return true;
            if ((e.mirrorOf || "") !== (l.mirrorOf || "")) return true;
        }
        return false;
    }

    /* Aspect ratio helper (e.g. 1920x1080 -> 16:9) */
    function getAspectRatio(w, h) {
        if (!w || !h) return "";
        if ((w === 1366 && h === 768) || (w === 1360 && h === 768)) return "16:9";
        if (w === 3440 && h === 1440) return "21:9";
        function gcd(a, b) { return b === 0 ? a : gcd(b, a % b); }
        const d = gcd(w, h);
        const rw = Math.round(w / d);
        const rh = Math.round(h / d);
        if (rw === 8 && rh === 5) return "16:10";
        if (rw > 32 && Math.abs((w / h) - (16 / 9)) < 0.04) return "16:9";
        if (rw > 32 && Math.abs((w / h) - (16 / 10)) < 0.04) return "16:10";
        return rw + ":" + rh;
    }

    /* Current resolution string ("1920x1080") for selectedMonitor */
    readonly property string currentResString: {
        if (!root.selectedMonitor) return "";
        const parsed = MonitorUtils.parseMode(root.selectedMonitor.selectedMode || "");
        if (parsed) return parsed.w + "x" + parsed.h;
        return root.selectedMonitor.width + "x" + root.selectedMonitor.height;
    }

    /* Current refresh rate string ("60.00") for selectedMonitor */
    readonly property string currentRateString: {
        if (!root.selectedMonitor) return "60.00";
        const parsed = MonitorUtils.parseMode(root.selectedMonitor.selectedMode || "");
        return parsed ? parsed.rate : "60.00";
    }

    /* Unique resolutions grouped from selectedMonitor.availableModes */
    readonly property var availableResolutions: {
        const mon = root.selectedMonitor;
        if (!mon) return [];
        const modes = mon.availableModes || [];
        const map = {};
        const list = [];

        for (let i = 0; i < modes.length; i++) {
            const mStr = modes[i];
            const p = MonitorUtils.parseMode(mStr);
            if (!p) continue;
            const key = p.w + "x" + p.h;
            if (!map[key]) {
                const entry = {
                    res: key,
                    w: p.w,
                    h: p.h,
                    label: p.w + " × " + p.h,
                    aspect: root.getAspectRatio(p.w, p.h),
                    modes: []
                };
                map[key] = entry;
                list.push(entry);
            }
            map[key].modes.push({
                mode: mStr,
                rate: p.rate,
                rateNum: parseFloat(p.rate)
            });
        }

        if (list.length === 0 && mon.width > 0 && mon.height > 0) {
            const fallbackMode = mon.selectedMode || (mon.width + "x" + mon.height + "@60.00Hz");
            list.push({
                res: mon.width + "x" + mon.height,
                w: mon.width,
                h: mon.height,
                label: mon.width + " × " + mon.height,
                aspect: root.getAspectRatio(mon.width, mon.height),
                modes: [{ mode: fallbackMode, rate: "60.00", rateNum: 60.0 }]
            });
        }

        return list;
    }

    /* Available refresh rates for the currently selected resolution (sorted descending & deduplicated by label) */
    readonly property var availableRatesForCurrentRes: {
        const resKey = root.currentResString;
        const allRes = root.availableResolutions;
        const found = allRes.find(r => r.res === resKey);
        if (!found || !found.modes) return [];

        const rawList = [];
        for (let i = 0; i < found.modes.length; i++) {
            const m = found.modes[i];
            const diffFromInt = Math.abs(m.rateNum - Math.round(m.rateNum));
            const isNearInt = diffFromInt < 0.35;
            const label = isNearInt
                ? (Math.round(m.rateNum) + " Hz")
                : (m.rateNum.toFixed(1) + " Hz");
            rawList.push({
                mode: m.mode,
                rate: m.rate,
                rateNum: m.rateNum,
                label: label,
                isNearInt: isNearInt
            });
        }
        rawList.sort((a, b) => b.rateNum - a.rateNum);

        const byLabel = {};
        const result = [];
        const activeMode = root.selectedMonitor ? root.selectedMonitor.selectedMode : "";
        for (let i = 0; i < rawList.length; i++) {
            const item = rawList[i];
            if (!byLabel[item.label]) {
                byLabel[item.label] = item;
                result.push(item);
            } else if (item.mode === activeMode) {
                const idx = result.indexOf(byLabel[item.label]);
                if (idx !== -1) result[idx] = item;
                byLabel[item.label] = item;
            } else if (!byLabel[item.label].isNearInt && item.isNearInt) {
                const idx = result.indexOf(byLabel[item.label]);
                if (idx !== -1) result[idx] = item;
                byLabel[item.label] = item;
            }
        }
        return result;
    }

    /* Mirror options for the selected monitor */
    readonly property var mirrorOptions: {
        const mon = root.selectedMonitor;
        if (!mon) return [{ value: "", label: "None (Extend Desktop)" }];
        const opts = [{ value: "", label: "None (Extend Desktop)" }];
        for (let i = 0; i < root.editState.length; i++) {
            const other = root.editState[i];
            if (other.name !== mon.name) {
                opts.push({
                    value: other.name,
                    label: "Mirror " + other.name + (other.description ? (" · " + other.description) : "")
                });
            }
        }
        return opts;
    }

    /* Sync editState from MonitorService */
    function syncFromService() {
        const live = MonitorService.monitors;
        if (!live || live.length === 0) return;

        const currentName = root.selectedMonitor ? root.selectedMonitor.name : "";
        const raw = live.map(m => Object.assign({}, m));

        /* Auto-place newly appeared monitors at (0,0) that overlap others */
        const enabled = raw.filter(m => !m.disabled);
        const rightEdge = enabled.reduce((max, m) => {
            const atOrigin = m.x === 0 && m.y === 0;
            return atOrigin ? max : Math.max(max, m.x + MonitorUtils.logicalW(m));
        }, 0);

        for (let i = 0; i < raw.length; i++) {
            const m = raw[i];
            if (m.disabled || !(m.x === 0 && m.y === 0)) continue;
            const others = enabled.filter(o => o.name !== m.name);
            const overlaps = others.some(o =>
                MonitorUtils.overlapsAABB(
                    m.x, m.y, MonitorUtils.logicalW(m), MonitorUtils.logicalH(m),
                    o.x, o.y, MonitorUtils.logicalW(o), MonitorUtils.logicalH(o)
                )
            );
            if (overlaps) m.x = rightEdge;
        }

        root.editState = raw;
        if (currentName !== "") {
            const idx = raw.findIndex(m => m.name === currentName);
            root.selectedIndex = idx >= 0 ? idx : 0;
        } else if (root.selectedIndex >= raw.length) {
            root.selectedIndex = 0;
        }
    }

    /* Mutation helpers on editState[selectedIndex] */
    function selectResolution(resEntry) {
        if (!resEntry || root.selectedIndex < 0 || root.selectedIndex >= root.editState.length) return;
        const currentRateNum = parseFloat(root.currentRateString) || 60.0;
        let bestMode = resEntry.modes[0];
        let bestDiff = Infinity;
        for (let i = 0; i < resEntry.modes.length; i++) {
            const diff = Math.abs(resEntry.modes[i].rateNum - currentRateNum);
            if (diff < bestDiff) {
                bestDiff = diff;
                bestMode = resEntry.modes[i];
            }
        }
        const chosenMode = bestMode ? bestMode.mode : (resEntry.w + "x" + resEntry.h + "@60.00Hz");
        const copy = root.editState.slice();
        copy[root.selectedIndex] = Object.assign({}, root.editState[root.selectedIndex], {
            selectedMode: chosenMode,
            width: resEntry.w,
            height: resEntry.h
        });
        root.editState = copy;
    }

    function selectMode(modeStr) {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.editState.length) return;
        const parsed = MonitorUtils.parseMode(modeStr);
        if (!parsed) return;
        const copy = root.editState.slice();
        copy[root.selectedIndex] = Object.assign({}, root.editState[root.selectedIndex], {
            selectedMode: modeStr,
            width: parsed.w,
            height: parsed.h
        });
        root.editState = copy;
    }

    function selectScale(newScale) {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.editState.length) return;
        const copy = root.editState.slice();
        copy[root.selectedIndex] = Object.assign({}, root.editState[root.selectedIndex], {
            scale: newScale
        });
        root.editState = copy;
    }

    function selectTransform(newTransform) {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.editState.length) return;
        const copy = root.editState.slice();
        copy[root.selectedIndex] = Object.assign({}, root.editState[root.selectedIndex], {
            transform: newTransform
        });
        root.editState = copy;
    }

    function toggleSelectedMonitorEnabled() {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.editState.length) return;
        const current = root.editState[root.selectedIndex];
        const willBeDisabled = !current.disabled;
        if (willBeDisabled && root.activeMonitorCount <= 1) {
            root.applyError = "Cannot disable the only active display.";
            return;
        }
        root.applyError = "";
        const copy = root.editState.slice();
        copy[root.selectedIndex] = Object.assign({}, current, {
            disabled: willBeDisabled
        });
        root.editState = copy;
    }

    function selectMirror(mirrorName) {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.editState.length) return;
        const patch = { mirrorOf: mirrorName };
        if (mirrorName !== "") {
            const src = root.editState.find(m => m.name === mirrorName);
            if (src) {
                patch.x = src.x;
                patch.y = src.y;
            }
        }
        const copy = root.editState.slice();
        copy[root.selectedIndex] = Object.assign({}, root.editState[root.selectedIndex], patch);
        root.editState = copy;
    }

    function applyDisplayChanges() {
        if (root.activeMonitorCount === 0) {
            root.applyError = "At least one display must remain enabled.";
            return;
        }
        if (root.hasOverlap) {
            root.applyError = "Displays are overlapping on the canvas — drag them apart before applying.";
            return;
        }
        root.applyError = "";
        root.isApplying = true;
        MonitorService.apply(root.editState);
    }

    function revertDisplayChanges() {
        root.applyError = "";
        root.closeAllDropdowns();
        root.syncFromService();
        root.showStatus("Reverted unsaved display changes");
    }

    Connections {
        target: MonitorService

        function onMonitorsLoaded() {
            if (MonitorService._pendingVerify) return;
            if (root.editState.length === 0 || (!root.hasUnsavedChanges && !root.isApplying)) {
                root.syncFromService();
            }
        }

        function onApplyDone(hasErrors, errorText) {
            if (!root.isApplying) return;
            root.isApplying = false;
            if (hasErrors) {
                root.applyError = errorText;
            } else {
                MonitorService.persistToFile(MonitorService._lastEdits);
                root.syncFromService();
                root.showStatus("Display configuration applied & saved");
            }
        }
    }

    /* Brightness Processes (only query real backlight class to avoid reading keyboard LEDs as 0%) */
    Process {
        id: brightProc
        command: ["sh", "-c", "if [ -n \"$(ls -A /sys/class/backlight 2>/dev/null)\" ]; then brightnessctl -c backlight -m 2>/dev/null | head -n 1; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim();
                if (!line) {
                    root.hasBacklightDevice = false;
                    return;
                }
                const parts = line.split(",");
                if (parts.length >= 4) {
                    root.brightnessDevice = parts[0] || "";
                    root.hasBacklightDevice = (parts[1] === "backlight");
                    const pctStr = parts[3].indexOf("%") !== -1 ? parts[3] : (parts[4] || "");
                    const pct = parseInt(pctStr.replace("%", ""));
                    if (!isNaN(pct)) root.brightness = pct;
                }
            }
        }
    }

    Process {
        id: setBrightProc
        running: false
    }

    function setBrightnessLevel(pct) {
        const clamped = Math.max(1, Math.min(100, Math.round(pct)));
        root.brightness = clamped;
        if (root.hasBacklightDevice) {
            setBrightProc.command = ["brightnessctl", "-c", "backlight", "set", clamped + "%"];
        } else {
            setBrightProc.command = ["brightnessctl", "set", clamped + "%"];
        }
        setBrightProc.running = true;
    }

    /* Compositor Option Processes (VRR & Allow Tearing) */
    Process {
        id: queryVrrProc
        command: ["sh", "-c", "hyprctl getoption misc:vrr -j 2>/dev/null | grep -o '\"int\": *[0-9]*' | awk -F: '{print $2}' | tr -d ' '"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim());
                if (!isNaN(val) && val >= 0 && val <= 2) {
                    root.vrrMode = val;
                }
            }
        }
    }

    Process {
        id: queryTearingProc
        command: ["sh", "-c", "hyprctl getoption general:allow_tearing -j 2>/dev/null | grep -o '\"int\": *[0-9]*' | awk -F: '{print $2}' | tr -d ' '"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim());
                if (!isNaN(val)) {
                    root.allowTearing = (val === 1);
                }
            }
        }
    }

    readonly property string hyprVarScript: Qt.resolvedUrl("../scripts/manage_hyprland.sh").toString().replace(/^file:\/\//, "")

    Process {
        id: hyprKeywordProc
        running: false
    }

    function setVrrMode(mode) {
        root.vrrMode = mode;
        hyprKeywordProc.command = [root.hyprVarScript, "set", "misc", "vrr", String(mode)];
        hyprKeywordProc.running = true;
        const labels = ["Off", "Always On", "Fullscreen Only"];
        root.showStatus("Adaptive Sync (VRR) set to " + (labels[mode] || mode));
    }

    function setAllowTearing(enabled) {
        root.allowTearing = enabled;
        hyprKeywordProc.command = [root.hyprVarScript, "set", "general", "allow_tearing", enabled ? "true" : "false"];
        hyprKeywordProc.running = true;
        root.showStatus("Screen tearing " + (enabled ? "allowed for low latency" : "disabled"));
    }

    /* External Process Launchers */
    Process {
        id: openMonitorsProc
        command: ["qs", "ipc", "call", "monitors", "toggle"]
        running: false
    }

    onVisibleChanged: {
        if (visible) {
            if (MonitorService.monitors.length > 0 && root.editState.length === 0) {
                root.syncFromService();
            }
            MonitorService.refresh();
            brightProc.running = true;
            queryVrrProc.running = true;
            queryTearingProc.running = true;
        } else {
            root.closeAllDropdowns();
        }
    }

    Component.onCompleted: {
        if (MonitorService.monitors.length > 0) {
            root.syncFromService();
        }
        MonitorService.refresh();
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.visible
        onTriggered: {
            brightProc.running = true;
        }
    }

    /* Main Scrollable View */
    Flickable {
        id: dispFlickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 36
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: !displayIlluminationBrightnessInst.sliderMouseRef.pressed

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

            /* Page Header with Active Count Badge & Quick Actions */
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Displays"
                    font.family: root.font
                    font.pixelSize: 20
                    font.bold: true
                    color: root.theme.textPrimary
                    Layout.alignment: Qt.AlignVCenter
                }

                /* Connected count badge */
                Rectangle {
                    visible: root.editState.length > 0
                    height: 22
                    implicitWidth: countBadgeText.implicitWidth + 14
                    radius: 11
                    color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.14)
                    border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.35)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id: countBadgeText
                        anchors.centerIn: parent
                        text: root.editState.length === 1
                            ? "1 Display"
                            : (root.activeMonitorCount + " / " + root.editState.length + " Active")
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentPrimary
                    }
                }

                Item { Layout.fillWidth: true }

                /* Refresh Displays Button (Text-only) */
                Rectangle {
                    id: refreshHeaderBtn
                    implicitWidth: refreshHeaderText.implicitWidth + 20
                    height: 30
                    radius: 7
                    color: refreshHeaderHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgSurface
                    border.color: refreshHeaderHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: refreshHeaderHover }

                    Text {
                        id: refreshHeaderText
                        anchors.centerIn: parent
                        text: MonitorService.loading ? "Refreshing…" : "Refresh"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: refreshHeaderHover.hovered || MonitorService.loading
                            ? root.theme.accentPrimary
                            : root.theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            MonitorService.refresh();
                            brightProc.running = true;
                            root.showStatus("Refreshed display status");
                        }
                    }
                }
            }

            /* ============================================================
             * 1. Interactive Display Arrangement & Preview Group
             * ============================================================ */
            DisplayArrangementCanvas {
                root: root
            }

            /* ============================================================
             * 2. Per-Display Configuration Group
             * ============================================================ */
            DisplayConfigurationGroup {
                root: root
            }

            /* ============================================================
             * 3. Brightness & Illumination Group
             * ============================================================ */
            DisplayBrightnessGroup {
                id: displayIlluminationBrightnessInst
                root: root
            }

            /* ============================================================
             * 4. Night Light (Color Temperature) Group
             * ============================================================ */
            DisplayNightLight {
                root: root
            }

            /* ============================================================
             * 5. Compositor & Power Group
             * ============================================================ */
            DisplayPowerOptions {
                root: root
            }
        }
    }

    /* Non-intrusive bottom feedback toast */
    Rectangle {
        id: statusToast
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        implicitWidth: toastText.implicitWidth + 24
        height: 34
        radius: 17
        color: root.theme.bgSelected ?? "#283457"
        border.color: root.theme.accentPrimary ?? "#7aa2f7"
        border.width: 1
        opacity: root.statusVisible ? 1.0 : 0.0
        scale: root.statusVisible ? 1.0 : 0.92
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Text {
            id: toastText
            anchors.centerIn: parent
            text: root.statusMessage
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
            color: root.theme.textPrimary ?? "#c0caf5"
        }
    }
}
