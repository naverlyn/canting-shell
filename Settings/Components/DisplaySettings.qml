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

Item {
    id: root
    property var theme
    property string font: "Hack Nerd Font"

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

    Process {
        id: hyprKeywordProc
        running: false
    }

    function setVrrMode(mode) {
        root.vrrMode = mode;
        hyprKeywordProc.command = ["hyprctl", "keyword", "misc:vrr", String(mode)];
        hyprKeywordProc.running = true;
        const labels = ["Off", "Always On", "Fullscreen Only"];
        root.showStatus("Adaptive Sync (VRR) set to " + (labels[mode] || mode));
    }

    function setAllowTearing(enabled) {
        root.allowTearing = enabled;
        hyprKeywordProc.command = ["hyprctl", "keyword", "general:allow_tearing", enabled ? "true" : "false"];
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
        interactive: !sliderMouse.pressed

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
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 8

                    Text {
                        text: "Display Arrangement"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    Text {
                        text: root.editState.length > 1
                            ? "·  Drag displays to arrange layout or click to configure"
                            : "·  Live preview of active display geometry and orientation"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.selectedMonitor !== null
                        text: root.selectedMonitor
                            ? ("Selected: " + root.selectedMonitor.name)
                            : ""
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentPrimary
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: arrangementCol.implicitHeight + 24
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.hasUnsavedChanges
                        ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.45)
                        : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    ColumnLayout {
                        id: arrangementCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 12
                        }
                        spacing: 12

                        /* Embedded Interactive MonitorCanvas */
                        Rectangle {
                            Layout.fillWidth: true
                            height: 195
                            radius: 10
                            color: root.theme.bgBase
                            border.color: root.hasOverlap
                                ? (root.theme.accentOrange ?? "#ff9e64")
                                : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                            border.width: root.hasOverlap ? 1.5 : 1
                            clip: true

                            MonitorCanvas {
                                id: inlineCanvas
                                anchors.fill: parent
                                anchors.margins: 2
                                monitors: root.editState
                                selectedIndex: root.selectedIndex
                                theme: root.theme
                                font: root.font

                                onMonitorSelected: idx => {
                                    root.selectedIndex = idx;
                                    root.closeAllDropdowns();
                                }
                                onMonitorMoved: (idx, nx, ny) => {
                                    const copy = root.editState.slice();
                                    copy[idx] = Object.assign({}, root.editState[idx], { x: nx, y: ny });
                                    root.editState = copy;
                                }
                            }

                            /* Top-left subtle coordinate badge for selected monitor */
                            Rectangle {
                                visible: root.selectedMonitor !== null && !root.selectedMonitor.disabled
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.margins: 10
                                height: 22
                                implicitWidth: coordText.implicitWidth + 14
                                radius: 6
                                color: Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.88)
                                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                                border.width: 1

                                Text {
                                    id: coordText
                                    anchors.centerIn: parent
                                    text: root.selectedMonitor
                                        ? (Math.round(MonitorUtils.logicalW(root.selectedMonitor)) + " × " +
                                           Math.round(MonitorUtils.logicalH(root.selectedMonitor)) + " logical  ·  (" +
                                           Math.round(root.selectedMonitor.x) + ", " + Math.round(root.selectedMonitor.y) + ")")
                                        : ""
                                    font.family: root.font
                                    font.pixelSize: 10
                                    color: root.theme.textSecondary
                                }
                            }
                        }

                        /* Monitor Selector Pills */
                        Flow {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: root.editState.length > 0

                            Repeater {
                                model: root.editState
                                delegate: Rectangle {
                                    id: monTabPill
                                    required property var modelData
                                    required property int index
                                    readonly property bool isCurrent: root.selectedIndex === index

                                    height: 34
                                    implicitWidth: monPillRow.implicitWidth + 22
                                    radius: 8
                                    color: isCurrent
                                        ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.16)
                                        : (monPillHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase)
                                    border.color: isCurrent
                                        ? root.theme.accentPrimary
                                        : (monPillHover.hovered ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.18)) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
                                    border.width: isCurrent ? 1.5 : 1

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: monPillHover }

                                    RowLayout {
                                        id: monPillRow
                                        anchors.centerIn: parent
                                        spacing: 8

                                        /* Active status dot */
                                        Rectangle {
                                            width: 7
                                            height: 7
                                            radius: 3.5
                                            color: monTabPill.modelData.disabled
                                                ? root.theme.textMuted
                                                : (root.theme.accentGreen ?? root.theme.accentPrimary)
                                        }

                                        Text {
                                            text: monTabPill.modelData.name
                                            font.family: root.font
                                            font.pixelSize: 12
                                            font.bold: monTabPill.isCurrent
                                            color: monTabPill.isCurrent ? root.theme.accentPrimary : root.theme.textPrimary
                                        }

                                        Text {
                                            text: monTabPill.modelData.disabled
                                                ? "Disabled"
                                                : (monTabPill.modelData.selectedMode || "").replace("Hz", " Hz")
                                            font.family: root.font
                                            font.pixelSize: 11
                                            color: root.theme.textSecondary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectedIndex = monTabPill.index;
                                            root.closeAllDropdowns();
                                        }
                                    }
                                }
                            }
                        }

                        /* Error / Overlap Warning Banner (Text-only) */
                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.applyError !== "" || root.hasOverlap
                            height: 38
                            radius: 8
                            color: Qt.rgba((root.theme.accentRed ?? "#f7768e").r, (root.theme.accentRed ?? "#f7768e").g, (root.theme.accentRed ?? "#f7768e").b, 0.14)
                            border.color: root.theme.accentRed ?? "#f7768e"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text {
                                    Layout.fillWidth: true
                                    text: root.applyError !== ""
                                        ? root.applyError
                                        : "Displays are overlapping — drag them apart before applying."
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: root.theme.accentRed ?? "#f7768e"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: root.applyError !== ""
                                    text: "Dismiss"
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: root.theme.accentRed ?? "#f7768e"

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.applyError = ""
                                    }
                                }
                            }
                        }

                        /* Unsaved Changes Action Bar (Text-only) */
                        Rectangle {
                            Layout.fillWidth: true
                            visible: root.hasUnsavedChanges || root.isApplying
                            height: 46
                            radius: 8
                            color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.1)
                            border.color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.35)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                spacing: 10

                                ColumnLayout {
                                    spacing: 1
                                    Layout.fillWidth: true

                                    Text {
                                        text: root.isApplying ? "Applying display changes…" : "Unsaved Display Changes"
                                        font.family: root.font
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: MonitorService.persistenceAvailable
                                            ? ("Will apply live and save to ~/.config/hypr/monitors." + MonitorService.configFormat)
                                            : "Will apply live to current Hyprland session"
                                        font.family: root.font
                                        font.pixelSize: 10
                                        color: root.theme.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                /* Revert Button */
                                Rectangle {
                                    width: 68
                                    height: 30
                                    radius: 6
                                    color: revertHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.1)) : root.theme.bgBase
                                    border.color: revertHover.hovered ? root.theme.textSecondary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                                    border.width: 1
                                    enabled: !root.isApplying

                                    HoverHandler { id: revertHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Revert"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.revertDisplayChanges()
                                    }
                                }

                                /* Apply & Save Button */
                                Rectangle {
                                    width: 108
                                    height: 30
                                    radius: 6
                                    readonly property bool canApply: !root.isApplying && !MonitorService.loading && !root.hasOverlap
                                    color: !canApply
                                        ? root.theme.bgSelected
                                        : (applyBtnHover.hovered ? Qt.lighter(root.theme.accentPrimary, 1.1) : root.theme.accentPrimary)
                                    opacity: canApply ? 1.0 : 0.5

                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: applyBtnHover }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.isApplying ? "Applying…" : "Apply & Save"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: parent.canApply ? root.theme.bgBase : root.theme.textMuted
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: parent.canApply
                                        cursorShape: parent.canApply ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.applyDisplayChanges()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* ============================================================
             * 2. Per-Display Configuration Group
             * ============================================================ */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.selectedMonitor !== null

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 8

                    Text {
                        text: root.selectedMonitor
                            ? ("Display Configuration  —  " + root.selectedMonitor.name)
                            : "Display Configuration"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    Text {
                        visible: root.selectedMonitor !== null && (root.selectedMonitor.description || "") !== ""
                        text: root.selectedMonitor ? ("·  " + root.selectedMonitor.description) : ""
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: configCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: configCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Row 1: Display Identity & Enable Switch (Text-only, no icon badge) */
                        Item {
                            Layout.fillWidth: true
                            height: 54

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true

                                    RowLayout {
                                        spacing: 8

                                        Text {
                                            text: root.selectedMonitor ? root.selectedMonitor.name : ""
                                            font.family: root.font
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: root.theme.textPrimary
                                        }

                                        Rectangle {
                                            height: 18
                                            implicitWidth: statusTag.implicitWidth + 10
                                            radius: 5
                                            color: (root.selectedMonitor && !root.selectedMonitor.disabled)
                                                ? Qt.rgba((root.theme.accentGreen ?? root.theme.accentPrimary).r,
                                                          (root.theme.accentGreen ?? root.theme.accentPrimary).g,
                                                          (root.theme.accentGreen ?? root.theme.accentPrimary).b, 0.15)
                                                : Qt.rgba(1, 1, 1, 0.06)

                                            Text {
                                                id: statusTag
                                                anchors.centerIn: parent
                                                text: (root.selectedMonitor && !root.selectedMonitor.disabled)
                                                    ? (root.editState.length === 1 ? "Primary Output" : "Enabled")
                                                    : "Disabled"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: (root.selectedMonitor && !root.selectedMonitor.disabled)
                                                    ? (root.theme.accentGreen ?? root.theme.accentPrimary)
                                                    : root.theme.textMuted
                                            }
                                        }
                                    }

                                    Text {
                                        text: {
                                            if (!root.selectedMonitor) return "";
                                            const desc = root.selectedMonitor.description || "Connected Display Output";
                                            const lw = Math.round(MonitorUtils.logicalW(root.selectedMonitor));
                                            const lh = Math.round(MonitorUtils.logicalH(root.selectedMonitor));
                                            return desc + "  ·  Logical " + lw + " × " + lh;
                                        }
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                /* Enable/Disable Switch (shown when >1 monitor or when monitor is disabled) */
                                Rectangle {
                                    visible: root.editState.length > 1 || (root.selectedMonitor && root.selectedMonitor.disabled)
                                    width: 44
                                    height: 24
                                    radius: 12
                                    readonly property bool isMonEnabled: root.selectedMonitor ? !root.selectedMonitor.disabled : true
                                    color: isMonEnabled ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 160 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: parent.isMonEnabled ? parent.width - width - 3 : 3
                                        color: parent.isMonEnabled ? "#ffffff" : root.theme.textPrimary

                                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleSelectedMonitorEnabled()
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 2: Resolution Expander Row */
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            opacity: (root.selectedMonitor && root.selectedMonitor.disabled) ? 0.45 : 1.0
                            enabled: !(root.selectedMonitor && root.selectedMonitor.disabled)

                            Item {
                                Layout.fillWidth: true
                                height: 52

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    ColumnLayout {
                                        spacing: 2
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            text: "Resolution"
                                            font.family: root.font
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: root.theme.textPrimary
                                        }

                                        Text {
                                            text: "Native pixel dimensions and aspect ratio"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            color: root.theme.textSecondary
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    /* Resolution Dropdown Pill */
                                    Rectangle {
                                        width: 220
                                        height: 32
                                        radius: 6
                                        color: root.resolutionDropdownOpen
                                            ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                                            : (resPillHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.04)))
                                        border.color: root.resolutionDropdownOpen
                                            ? root.theme.accentPrimary
                                            : (resPillHover.hovered
                                                ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4)
                                                : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                                        border.width: root.resolutionDropdownOpen ? 1.5 : 1
                                        Layout.alignment: Qt.AlignVCenter

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                        HoverHandler { id: resPillHover }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 8

                                            Text {
                                                text: {
                                                    if (!root.selectedMonitor) return "";
                                                    const parts = root.currentResString.split("x");
                                                    if (parts.length === 2) {
                                                        const ar = root.getAspectRatio(parseInt(parts[0]), parseInt(parts[1]));
                                                        return parts[0] + " × " + parts[1] + (ar ? ("  (" + ar + ")") : "");
                                                    }
                                                    return root.currentResString;
                                                }
                                                font.family: root.font
                                                font.pixelSize: 12
                                                color: root.theme.textPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: root.resolutionDropdownOpen ? "Close" : "Change"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.resolutionDropdownOpen ? root.theme.accentPrimary : root.theme.textSecondary
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.mirrorDropdownOpen = false;
                                                root.resolutionDropdownOpen = !root.resolutionDropdownOpen;
                                            }
                                        }
                                    }
                                }
                            }

                            /* Expandable Resolution Options Sub-Container */
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 8
                                Layout.rightMargin: 8
                                Layout.bottomMargin: root.resolutionDropdownOpen ? 8 : 0
                                Layout.preferredHeight: root.resolutionDropdownOpen ? Math.min(220, resListCol.implicitHeight + 8) : 0
                                opacity: root.resolutionDropdownOpen ? 1.0 : 0.0
                                clip: true
                                radius: 8
                                color: Qt.rgba(0, 0, 0, 0.18)
                                border.color: root.resolutionDropdownOpen ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                border.width: 1

                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                                Behavior on Layout.bottomMargin { NumberAnimation { duration: 200 } }

                                Flickable {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    contentHeight: resListCol.implicitHeight
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds

                                    ColumnLayout {
                                        id: resListCol
                                        width: parent.width
                                        spacing: 2

                                        Repeater {
                                            model: root.availableResolutions
                                            delegate: Rectangle {
                                                required property var modelData
                                                Layout.fillWidth: true
                                                height: 34
                                                radius: 6
                                                readonly property bool isSelected: root.currentResString === modelData.res

                                                color: isSelected
                                                    ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                                                    : (resOptHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.06)) : "transparent")
                                                border.color: isSelected
                                                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.3)
                                                    : "transparent"
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 120 } }

                                                HoverHandler { id: resOptHover }

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 12
                                                    anchors.rightMargin: 12
                                                    spacing: 8

                                                    Text {
                                                        text: modelData.label
                                                        font.family: root.font
                                                        font.pixelSize: 12
                                                        font.bold: isSelected
                                                        color: isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                                                    }

                                                    Rectangle {
                                                        visible: modelData.aspect !== ""
                                                        height: 18
                                                        implicitWidth: aspectLabel.implicitWidth + 10
                                                        radius: 4
                                                        color: Qt.rgba(1, 1, 1, 0.06)

                                                        Text {
                                                            id: aspectLabel
                                                            anchors.centerIn: parent
                                                            text: modelData.aspect
                                                            font.family: root.font
                                                            font.pixelSize: 10
                                                            color: root.theme.textSecondary
                                                        }
                                                    }

                                                    Item { Layout.fillWidth: true }

                                                    Text {
                                                        visible: isSelected
                                                        text: "Active"
                                                        font.family: root.font
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                        color: root.theme.accentPrimary
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.selectResolution(modelData);
                                                        root.resolutionDropdownOpen = false;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 3: Refresh Rate Selector */
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 52
                            opacity: (root.selectedMonitor && root.selectedMonitor.disabled) ? 0.45 : 1.0
                            enabled: !(root.selectedMonitor && root.selectedMonitor.disabled)

                            RowLayout {
                                id: rateRowLayout
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Refresh Rate"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Frame update frequency at " + root.currentResString.replace("x", "×")
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                /* Segmented Refresh Rate Control */
                                Rectangle {
                                    visible: root.availableRatesForCurrentRes.length > 0
                                    width: 360
                                    height: 32
                                    radius: 7
                                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 3

                                        Repeater {
                                            model: root.availableRatesForCurrentRes
                                            delegate: Rectangle {
                                                required property var modelData
                                                readonly property bool isSelected: {
                                                    if (!root.selectedMonitor) return false;
                                                    if (root.selectedMonitor.selectedMode === modelData.mode) return true;
                                                    const curRate = parseFloat(root.currentRateString);
                                                    return Math.abs(curRate - modelData.rateNum) < 0.35;
                                                }

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSelected
                                                    ? root.theme.accentPrimary
                                                    : (rateHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                                                border.color: isSelected ? root.theme.accentPrimary : "transparent"
                                                border.width: isSelected ? 1 : 0

                                                Behavior on color { ColorAnimation { duration: 120 } }

                                                HoverHandler { id: rateHover }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: isSelected
                                                    color: isSelected
                                                        ? (root.theme.bgBase ?? "#1a1b26")
                                                        : (rateHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.selectMode(modelData.mode)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 4: Scale Selector */
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 52
                            opacity: (root.selectedMonitor && root.selectedMonitor.disabled) ? 0.45 : 1.0
                            enabled: !(root.selectedMonitor && root.selectedMonitor.disabled)

                            RowLayout {
                                id: scaleRowLayout
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Scale"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "UI and text scaling factor (" + Math.round((root.selectedMonitor ? root.selectedMonitor.scale : 1.0) * 100) + "%)"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                /* Segmented Scale Control */
                                Rectangle {
                                    width: 360
                                    height: 32
                                    radius: 7
                                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 3

                                        Repeater {
                                            model: [
                                                { val: 0.75, label: "75%" },
                                                { val: 1.0,  label: "100%" },
                                                { val: 1.25, label: "125%" },
                                                { val: 1.5,  label: "150%" },
                                                { val: 1.75, label: "175%" },
                                                { val: 2.0,  label: "200%" }
                                            ]
                                            delegate: Rectangle {
                                                required property var modelData
                                                readonly property bool isSelected: root.selectedMonitor
                                                    && Math.abs(root.selectedMonitor.scale - modelData.val) < 0.02

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSelected
                                                    ? root.theme.accentPrimary
                                                    : (scalePillHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                                                border.color: isSelected ? root.theme.accentPrimary : "transparent"
                                                border.width: isSelected ? 1 : 0

                                                Behavior on color { ColorAnimation { duration: 120 } }

                                                HoverHandler { id: scalePillHover }

                                                Text {
                                                    id: scaleText
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: isSelected
                                                    color: isSelected
                                                        ? (root.theme.bgBase ?? "#1a1b26")
                                                        : (scalePillHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.selectScale(modelData.val)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 5: Orientation / Rotation (Segmented control) */
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 52
                            opacity: (root.selectedMonitor && root.selectedMonitor.disabled) ? 0.45 : 1.0
                            enabled: !(root.selectedMonitor && root.selectedMonitor.disabled)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Orientation"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Rotate display output clockwise"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                /* Segmented Orientation Control */
                                Rectangle {
                                    width: 360
                                    height: 32
                                    radius: 7
                                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 3

                                        Repeater {
                                            model: [
                                                { t: 0, label: "0°" },
                                                { t: 1, label: "90°" },
                                                { t: 2, label: "180°" },
                                                { t: 3, label: "270°" }
                                            ]
                                            delegate: Rectangle {
                                                required property var modelData
                                                readonly property bool isSelected: root.selectedMonitor
                                                    && root.selectedMonitor.transform === modelData.t

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSelected
                                                    ? root.theme.accentPrimary
                                                    : (rotPillHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                                                border.color: isSelected ? root.theme.accentPrimary : "transparent"
                                                border.width: isSelected ? 1 : 0

                                                Behavior on color { ColorAnimation { duration: 120 } }

                                                HoverHandler { id: rotPillHover }

                                                Text {
                                                    id: rotText
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: isSelected
                                                    color: isSelected
                                                        ? (root.theme.bgBase ?? "#1a1b26")
                                                        : (rotPillHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.selectTransform(modelData.t)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        /* Row Divider (only when multiple monitors exist) */
                        Rectangle {
                            visible: root.editState.length > 1
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 6: Mirror Display Expander (visible when >1 monitor connected) */
                        ColumnLayout {
                            visible: root.editState.length > 1
                            Layout.fillWidth: true
                            spacing: 0
                            opacity: (root.selectedMonitor && root.selectedMonitor.disabled) ? 0.45 : 1.0
                            enabled: !(root.selectedMonitor && root.selectedMonitor.disabled)

                            Item {
                                Layout.fillWidth: true
                                height: 52

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    ColumnLayout {
                                        spacing: 2
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            text: "Mirror Display"
                                            font.family: root.font
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: root.theme.textPrimary
                                        }

                                        Text {
                                            text: "Clone content from another active monitor"
                                            font.family: root.font
                                            font.pixelSize: 11
                                            color: root.theme.textSecondary
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        width: 220
                                        height: 32
                                        radius: 6
                                        color: root.mirrorDropdownOpen
                                            ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                                            : (mirPillHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.04)))
                                        border.color: root.mirrorDropdownOpen
                                            ? root.theme.accentPrimary
                                            : (mirPillHover.hovered
                                                ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4)
                                                : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)))
                                        border.width: root.mirrorDropdownOpen ? 1.5 : 1
                                        Layout.alignment: Qt.AlignVCenter

                                        HoverHandler { id: mirPillHover }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 8

                                            Text {
                                                text: (root.selectedMonitor && root.selectedMonitor.mirrorOf)
                                                    ? ("Mirroring " + root.selectedMonitor.mirrorOf)
                                                    : "None (Extend Desktop)"
                                                font.family: root.font
                                                font.pixelSize: 12
                                                color: root.theme.textPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: root.mirrorDropdownOpen ? "Close" : "Change"
                                                font.family: root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: root.mirrorDropdownOpen ? root.theme.accentPrimary : root.theme.textSecondary
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.resolutionDropdownOpen = false;
                                                root.mirrorDropdownOpen = !root.mirrorDropdownOpen;
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 8
                                Layout.rightMargin: 8
                                Layout.bottomMargin: root.mirrorDropdownOpen ? 8 : 0
                                Layout.preferredHeight: root.mirrorDropdownOpen ? (mirrorOptCol.implicitHeight + 8) : 0
                                opacity: root.mirrorDropdownOpen ? 1.0 : 0.0
                                clip: true
                                radius: 8
                                color: Qt.rgba(0, 0, 0, 0.18)
                                border.color: root.mirrorDropdownOpen ? (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                border.width: 1

                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

                                ColumnLayout {
                                    id: mirrorOptCol
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                        margins: 4
                                    }
                                    spacing: 2

                                    Repeater {
                                        model: root.mirrorOptions
                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            height: 34
                                            radius: 6
                                            readonly property bool isSelected: (root.selectedMonitor ? (root.selectedMonitor.mirrorOf || "") : "") === modelData.value

                                            color: isSelected
                                                ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12))
                                                : (mirOptHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.06)) : "transparent")
                                            border.color: isSelected
                                                ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.3)
                                                : "transparent"
                                            border.width: 1

                                            HoverHandler { id: mirOptHover }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 12
                                                spacing: 8

                                                Text {
                                                    text: modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 12
                                                    font.bold: isSelected
                                                    color: isSelected ? root.theme.accentPrimary : root.theme.textPrimary
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    visible: isSelected
                                                    text: "Active"
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: root.theme.accentPrimary
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.selectMirror(modelData.value);
                                                    root.mirrorDropdownOpen = false;
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

            /* ============================================================
             * 3. Brightness & Illumination Group
             * ============================================================ */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Illumination & Brightness"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: brightGroupCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: brightGroupCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Row 1: Brightness Slider (Text-only, full-width slider track) */
                        Item {
                            Layout.fillWidth: true
                            height: 56

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: 165
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Screen Brightness"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: root.hasBacklightDevice && root.brightnessDevice !== ""
                                            ? ("Backlight · " + root.brightnessDevice)
                                            : "Display backlight level"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                /* Interactive Brightness Slider Track */
                                Rectangle {
                                    id: sliderTrack
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: Math.max(0, Math.min(parent.width, parent.width * (root.brightness / 100)))
                                        color: root.theme.accentPrimary

                                        Behavior on width {
                                            enabled: !sliderMouse.pressed
                                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    /* Outer halo ring on hover/press */
                                    Rectangle {
                                        anchors.centerIn: sliderBall
                                        width: sliderBall.width + (sliderMouse.pressed ? 8 : (sliderMouse.containsMouse ? 6 : 0))
                                        height: width
                                        radius: width / 2
                                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b,
                                                       sliderMouse.pressed ? 0.35 : (sliderMouse.containsMouse ? 0.2 : 0))
                                        z: 1

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    /* Slider Knob */
                                    Rectangle {
                                        id: sliderBall
                                        width: sliderMouse.containsMouse || sliderMouse.pressed ? 18 : 16
                                        height: width
                                        radius: width / 2
                                        color: "#ffffff"
                                        border.color: root.theme.accentPrimary
                                        border.width: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(sliderTrack.width - width, (sliderTrack.width * (root.brightness / 100)) - (width / 2)))
                                        z: 2

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on x { NumberAnimation { duration: sliderMouse.pressed ? 0 : 80; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        id: sliderMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        preventStealing: true
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: (mouse) => {
                                            mouse.accepted = true;
                                            if (sliderTrack.width > 0) {
                                                const pct = Math.max(1, Math.min(100, Math.round((mouse.x / sliderTrack.width) * 100)));
                                                root.setBrightnessLevel(pct);
                                            }
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (pressed && sliderTrack.width > 0) {
                                                mouse.accepted = true;
                                                const pct = Math.max(1, Math.min(100, Math.round((mouse.x / sliderTrack.width) * 100)));
                                                root.setBrightnessLevel(pct);
                                            }
                                        }
                                        onClicked: (mouse) => {
                                            mouse.accepted = true;
                                            if (sliderTrack.width > 0) {
                                                const pct = Math.max(1, Math.min(100, Math.round((mouse.x / sliderTrack.width) * 100)));
                                                root.setBrightnessLevel(pct);
                                            }
                                        }
                                    }
                                }

                                /* Percentage Badge */
                                Rectangle {
                                    width: 48
                                    height: 26
                                    radius: 6
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.brightness + "%"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.theme.accentPrimary
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 2: Quick Brightness Presets */
                        Item {
                            Layout.fillWidth: true
                            height: 48

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    text: "Quick Presets"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textSecondary
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: brightPresetTrack
                                    implicitWidth: 280
                                    implicitHeight: 32
                                    width: 280
                                    height: 32
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    readonly property var presets: [10, 25, 50, 75, 100]
                                    readonly property int activeIdx: {
                                        for (let i = 0; i < presets.length; i++) {
                                            if (Math.abs(root.brightness - presets[i]) <= 2) return i;
                                        }
                                        return -1;
                                    }
                                    readonly property real cellWidth: (width - 6 - 16) / 5

                                    /* Sliding Selection Pill */
                                    Rectangle {
                                        visible: opacity > 0
                                        opacity: brightPresetTrack.activeIdx >= 0 ? 1.0 : 0.0
                                        y: 3
                                        height: parent.height - 6
                                        width: brightPresetTrack.cellWidth
                                        x: brightPresetTrack.activeIdx >= 0 ? (3 + brightPresetTrack.activeIdx * (brightPresetTrack.cellWidth + 4)) : 3
                                        radius: 5
                                        color: root.theme.bgSelected
                                        border.color: root.theme.accentPrimary
                                        border.width: 1

                                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: brightPresetTrack.presets

                                            delegate: Rectangle {
                                                id: bSegBtn
                                                required property int modelData
                                                required property int index
                                                readonly property bool isSel: brightPresetTrack.activeIdx === bSegBtn.index

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: !isSel && bSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                                                Behavior on color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: bSegHover }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: bSegBtn.modelData + "%"
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: bSegBtn.isSel
                                                    color: bSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                    opacity: bSegBtn.isSel || bSegHover.hovered ? 1.0 : 0.75
                                                    Behavior on color { ColorAnimation { duration: 140 } }
                                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.setBrightnessLevel(bSegBtn.modelData)
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

            /* ============================================================
             * 4. Night Light (Color Temperature) Group
             * ============================================================ */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 8

                    Text {
                        text: "Night Light"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    Text {
                        text: "· Warm blue-light filter to reduce eye strain"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.nightLightEnabled ? (root.nightLightTemp + " K · Active") : "Disabled"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.nightLightEnabled ? (root.theme.accentOrange ?? root.theme.accentPrimary) : root.theme.textMuted
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: nlGroupCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: nlGroupCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Row 1: Enable Night Light Switch */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Night Light"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Apply warm color temperature filter to all connected displays"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                /* Libadwaita Toggle Switch */
                                Rectangle {
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: root.nightLightEnabled
                                        ? root.theme.accentPrimary
                                        : (root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3))
                                    border.color: root.nightLightEnabled
                                        ? root.theme.accentPrimary
                                        : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.15))
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.nightLightEnabled ? (parent.width - width - 3) : 3
                                        color: root.nightLightEnabled
                                            ? (root.theme.bgBase ?? "#ffffff")
                                            : root.theme.textPrimary

                                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        preventStealing: true
                                        onClicked: root.setNightLight(!root.nightLightEnabled)
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 2: Color Temperature Slider */
                        Item {
                            Layout.fillWidth: true
                            height: 56
                            opacity: root.nightLightEnabled ? 1.0 : 0.45
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Layout.preferredWidth: 165
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "Color Temperature"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: root.getNightLightLabel(root.nightLightTemp)
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                    }
                                }

                                /* Interactive Temperature Slider Track */
                                Rectangle {
                                    id: nlSliderTrack
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    readonly property real minK: 3000.0
                                    readonly property real maxK: 6000.0
                                    readonly property real frac: Math.max(0.0, Math.min(1.0, (root.nightLightTemp - minK) / (maxK - minK)))

                                    Rectangle {
                                        height: parent.height
                                        radius: parent.radius
                                        width: Math.max(0, Math.min(parent.width, parent.width * nlSliderTrack.frac))
                                        color: root.theme.accentOrange ?? root.theme.accentPrimary

                                        Behavior on width {
                                            enabled: !nlSliderMouse.pressed
                                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    /* Outer halo ring */
                                    Rectangle {
                                        anchors.centerIn: nlSliderBall
                                        width: nlSliderBall.width + (nlSliderMouse.pressed ? 8 : (nlSliderMouse.containsMouse ? 6 : 0))
                                        height: width
                                        radius: width / 2
                                        color: Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b,
                                                       nlSliderMouse.pressed ? 0.35 : (nlSliderMouse.containsMouse ? 0.2 : 0))
                                        z: 1

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    /* Slider Knob */
                                    Rectangle {
                                        id: nlSliderBall
                                        width: nlSliderMouse.containsMouse || nlSliderMouse.pressed ? 18 : 16
                                        height: width
                                        radius: width / 2
                                        color: "#ffffff"
                                        border.color: root.theme.accentOrange ?? root.theme.accentPrimary
                                        border.width: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(nlSliderTrack.width - width, (nlSliderTrack.width * nlSliderTrack.frac) - (width / 2)))
                                        z: 2

                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on x { NumberAnimation { duration: nlSliderMouse.pressed ? 0 : 80; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        id: nlSliderMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        preventStealing: true
                                        hoverEnabled: true
                                        cursorShape: root.nightLightEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        enabled: root.nightLightEnabled

                                        function updateTemp(mouseX) {
                                            if (nlSliderTrack.width > 0) {
                                                const ratio = Math.max(0.0, Math.min(1.0, mouseX / nlSliderTrack.width));
                                                const k = Math.round(nlSliderTrack.minK + ratio * (nlSliderTrack.maxK - nlSliderTrack.minK));
                                                root.setNightLightTemp(k);
                                            }
                                        }

                                        onPressed: (mouse) => {
                                            mouse.accepted = true;
                                            dispFlickable.interactive = false;
                                            updateTemp(mouse.x);
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (pressed) {
                                                mouse.accepted = true;
                                                updateTemp(mouse.x);
                                            }
                                        }
                                        onReleased: dispFlickable.interactive = true
                                        onCanceled: dispFlickable.interactive = true
                                    }
                                }

                                /* Kelvin Badge */
                                Rectangle {
                                    width: 64
                                    height: 26
                                    radius: 6
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.nightLightTemp + " K"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.nightLightEnabled ? (root.theme.accentOrange ?? root.theme.accentPrimary) : root.theme.textMuted
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 3: Temperature Presets */
                        Item {
                            Layout.fillWidth: true
                            height: 48
                            opacity: root.nightLightEnabled ? 1.0 : 0.45
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    text: "Warmth Presets"
                                    font.family: root.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: root.theme.textSecondary
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: nlPresetTrack
                                    implicitWidth: 320
                                    implicitHeight: 32
                                    width: 320
                                    height: 32
                                    radius: 7
                                    color: root.theme.bgBase
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    readonly property var presets: [
                                        { k: 3500, label: "3500K" },
                                        { k: 4000, label: "4000K" },
                                        { k: 4500, label: "4500K" },
                                        { k: 5000, label: "5000K" },
                                        { k: 5500, label: "5500K" }
                                    ]
                                    readonly property int activeIdx: {
                                        for (let i = 0; i < presets.length; i++) {
                                            if (Math.abs(root.nightLightTemp - presets[i].k) <= 100) return i;
                                        }
                                        return -1;
                                    }
                                    readonly property real cellWidth: (width - 6 - (4 * 4)) / 5

                                    /* Sliding Selection Pill */
                                    Rectangle {
                                        visible: opacity > 0
                                        opacity: nlPresetTrack.activeIdx >= 0 && root.nightLightEnabled ? 1.0 : 0.0
                                        y: 3
                                        height: parent.height - 6
                                        width: nlPresetTrack.cellWidth
                                        x: nlPresetTrack.activeIdx >= 0 ? (3 + nlPresetTrack.activeIdx * (nlPresetTrack.cellWidth + 4)) : 3
                                        radius: 5
                                        color: root.theme.bgSelected
                                        border.color: root.theme.accentOrange ?? root.theme.accentPrimary
                                        border.width: 1

                                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 4

                                        Repeater {
                                            model: nlPresetTrack.presets

                                            delegate: Rectangle {
                                                id: nlSegBtn
                                                required property var modelData
                                                required property int index

                                                readonly property bool isSel: nlPresetTrack.activeIdx === nlSegBtn.index && root.nightLightEnabled

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: !isSel && nlHover.hovered && root.nightLightEnabled ? root.theme.bgHover : "transparent"
                                                Behavior on color { ColorAnimation { duration: 140 } }

                                                HoverHandler { id: nlHover; enabled: root.nightLightEnabled }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: nlSegBtn.modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: nlSegBtn.isSel
                                                    color: nlSegBtn.isSel ? (root.theme.accentOrange ?? root.theme.accentPrimary) : root.theme.textPrimary
                                                    opacity: !root.nightLightEnabled ? 0.45 : (nlSegBtn.isSel || nlHover.hovered ? 1.0 : 0.75)
                                                    Behavior on color { ColorAnimation { duration: 140 } }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: root.nightLightEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                    enabled: root.nightLightEnabled
                                                    preventStealing: true
                                                    onClicked: root.setNightLightTemp(nlSegBtn.modelData.k)
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

            /* ============================================================
             * 5. Compositor & Power Group
             * ============================================================ */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Compositor & Display Power"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.leftMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: compGroupCol.implicitHeight + 16
                    radius: 12
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    ColumnLayout {
                        id: compGroupCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 0

                        /* Row 1: Variable Refresh Rate (VRR / Adaptive Sync) */
                        Item {
                            Layout.fillWidth: true
                            height: 54

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true

                                    Text {
                                        text: "Variable Refresh Rate (VRR)"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Synchronize display refresh rate with GPU frame output (Adaptive Sync)"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                /* Segmented VRR Mode Control */
                                Rectangle {
                                    width: 260
                                    height: 32
                                    radius: 7
                                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        spacing: 3

                                        Repeater {
                                            model: [
                                                { val: 0, label: "Off" },
                                                { val: 1, label: "Always" },
                                                { val: 2, label: "Fullscreen" }
                                            ]
                                            delegate: Rectangle {
                                                required property var modelData
                                                readonly property bool isSelected: root.vrrMode === modelData.val

                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                radius: 5
                                                color: isSelected
                                                    ? root.theme.accentPrimary
                                                    : (vrrHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                                                border.color: isSelected ? root.theme.accentPrimary : "transparent"
                                                border.width: isSelected ? 1 : 0

                                                Behavior on color { ColorAnimation { duration: 120 } }

                                                HoverHandler { id: vrrHover }

                                                Text {
                                                    id: vrrLabel
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    font.family: root.font
                                                    font.pixelSize: 11
                                                    font.bold: isSelected
                                                    color: isSelected
                                                        ? (root.theme.bgBase ?? "#1a1b26")
                                                        : (vrrHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.setVrrMode(modelData.val)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        /* Row Divider */
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        /* Row 2: Allow Screen Tearing */
                        Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.fillWidth: true

                                    Text {
                                        text: "Allow Tearing"
                                        font.family: root.font
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.theme.textPrimary
                                    }

                                    Text {
                                        text: "Reduce input latency in fullscreen games that request immediate page flips"
                                        font.family: root.font
                                        font.pixelSize: 11
                                        color: root.theme.textSecondary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle {
                                    width: 44
                                    height: 24
                                    radius: 12
                                    color: root.allowTearing ? root.theme.accentPrimary : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                                    Layout.alignment: Qt.AlignVCenter

                                    Behavior on color { ColorAnimation { duration: 160 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: root.allowTearing ? parent.width - width - 3 : 3
                                        color: root.allowTearing ? "#ffffff" : root.theme.textPrimary

                                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setAllowTearing(!root.allowTearing)
                                    }
                                }
                            }
                        }
                    }
                }
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
