import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../bar"
import "../../MonitorManager"
import ".."
import "./Common"
import "./Bar"

Item {
    id: root
    property var theme
    property string font: "Hack Nerd Font"

    property int currentSubTab: 0
    property string selectedColorTargetType: "block"
    property string selectedColorWidgetId: "launcher"
    property int selectedColorPanelIndex: 0
    property string themeSearchQuery: ""

    property bool isDraggingBlock: false
    property string draggedWidgetId: ""
    property int dragSourcePanelIndex: -1
    property int dragSourceItemIndex: -1
    property real dragMouseX: 0
    property real dragMouseY: 0
    property int dragHoverPanelIndex: -1
    property int dragHoverItemIndex: -1

    /* Feedback Toast Notification State */
    property string toastMessage: ""
    property bool toastVisible: false
    property bool toastIsWarning: false

    Timer {
        id: toastTimer
        interval: 2800
        repeat: false
        onTriggered: root.toastVisible = false
    }

    function showToast(msg, isWarn) {
        root.toastMessage = msg;
        root.toastIsWarning = Boolean(isWarn);
        root.toastVisible = true;
        toastTimer.restart();
    }

    Connections {
        target: BarConfig
        function onConfigWarning(msg) {
            root.showToast(msg, true);
        }
        function onPanelsUpdated() {
            const p = BarConfig.panels;
            layoutCard.panelRepeater.model = null;
            layoutCard.panelRepeater.model = p;
        }
    }

    property int _monitorRevision: 0
    property alias subTabContentAnimation: subTabContentAnim
    property alias generalTab: generalTabCol

    Component.onCompleted: {
        if (typeof MonitorService !== "undefined") {
            MonitorService.refresh();
        }
        if (root.isSingleMonitor && BarConfig.activeEditingDisplay === "secondary") {
            BarConfig.activeEditingDisplay = "primary";
        }
    }

    Connections {
        target: (typeof MonitorService !== "undefined") ? MonitorService : null
        function onMonitorsLoaded() {
            root._monitorRevision++;
            if (root.isSingleMonitor && BarConfig.activeEditingDisplay === "secondary") {
                BarConfig.activeEditingDisplay = "primary";
            }
        }
    }

    readonly property var themeRoles: [
        { key: "",              label: "Auto (Default)" },
        { key: "accentPrimary", label: "Primary" },
        { key: "accentCyan",    label: "Cyan" },
        { key: "accentGreen",   label: "Green" },
        { key: "accentOrange",  label: "Orange" },
        { key: "accentRed",     label: "Red" },
        { key: "textPrimary",   label: "Text" },
        { key: "textSecondary", label: "Subtext" },
        { key: "textMuted",     label: "Muted" }
    ]

    readonly property var themeAccentKeys: [
        { key: "accentPrimary", label: "Primary" },
        { key: "accentCyan",    label: "Cyan" },
        { key: "accentGreen",   label: "Green" },
        { key: "accentOrange",  label: "Orange" },
        { key: "accentRed",     label: "Red" },
        { key: "textPrimary",   label: "Text" }
    ]

    readonly property var filteredThemesList: {
        const all = (root.theme && root.theme.themes) ? root.theme.themes : [];
        const q = root.themeSearchQuery.toLowerCase().trim();
        let res = [];
        for (let i = 0; i < all.length; i++) {
            const t = all[i];
            if (!t || !t.name) continue;
            if (q === ""
                || String(t.name).toLowerCase().indexOf(q) !== -1
                || (t.family && String(t.family).toLowerCase().indexOf(q) !== -1)) {
                res.push(t);
            }
        }
        return res;
    }

    function cleanBarName(raw, fallback) {
        const s = String(raw || fallback || "Primary Bar")
            .replace(/[\uE000-\uF8FF]/g, "")
            .replace(/\s*\((Top|Bottom|Left|Right)\)$/i, "")
            .replace(/\s*\([^)]+\)$/i, "")
            .trim();
        return s || (fallback || "Primary Bar");
    }

    // Live active monitor detection
    readonly property var activeScreensList: {
        void root._monitorRevision;
        if (Quickshell.screens) void Quickshell.screens.length;
        if (typeof MonitorService !== "undefined" && MonitorService.monitors) void MonitorService.monitors.length;

        const qscreens = Quickshell.screens || [];
        const validQS = [];
        for (let i = 0; i < qscreens.length; i++) {
            const s = qscreens[i];
            if (s && s.name) {
                validQS.push({
                    name: String(s.name),
                    model: String(s.model || s.description || "").trim(),
                    width: s.width || 0,
                    height: s.height || 0
                });
            }
        }
        if (validQS.length > 0) return validQS;

        if (typeof MonitorService !== "undefined" && MonitorService.monitors && MonitorService.monitors.length > 0) {
            const activeMS = MonitorService.monitors.filter(m => !m.disabled);
            if (activeMS.length > 0) {
                return activeMS.map((m, idx) => ({
                    name: String(m.name || ("Display " + (idx + 1))),
                    model: String(m.description || m.model || "").trim(),
                    width: m.width || 0,
                    height: m.height || 0
                }));
            }
        }

        return [{ name: "HDMI-A-1", model: "", width: 1920, height: 1080 }];
    }

    readonly property int monitorCount: root.activeScreensList.length
    readonly property bool hasMultipleMonitors: root.monitorCount >= 2
    readonly property bool isSingleMonitor: root.monitorCount <= 1

    function getMonitorNameForTarget(target) {
        const screens = root.activeScreensList;
        if (target === "primary") {
            return (screens.length > 0 && screens[0] && screens[0].name) ? screens[0].name : "HDMI-A-1";
        }
        if (target === "secondary") {
            if (screens.length > 1 && screens[1] && screens[1].name) {
                return screens[1].name;
            }
            return "";
        }
        for (let i = 0; i < screens.length; i++) {
            if (screens[i] && screens[i].name === target) return screens[i].name;
        }
        return target || (screens.length > 0 ? screens[0].name : "Display");
    }

    readonly property string activeMonitorsSummary: {
        const screens = root.activeScreensList;
        return screens.map(s => s.name || "Display").join(", ");
    }

    /* Add Bar Confirmation Dialog State */
    property bool addBarModalVisible: false
    property string addBarChosenTarget: "primary"
    property string addBarChosenPosition: "bottom"

    readonly property var addBarTargetOptions: {
        const screens = root.activeScreensList;
        const primMon = root.getMonitorNameForTarget("primary");
        const secMon = root.getMonitorNameForTarget("secondary");

        const opts = [
            {
                id: "primary",
                title: "Primary Display (" + primMon + ")",
                desc: root.hasMultipleMonitors
                    ? "Show this bar only on your main screen"
                    : "Show this bar on your active display (" + primMon + ")"
            }
        ];

        if (root.hasMultipleMonitors && secMon) {
            opts.push({
                id: "secondary",
                title: "Secondary Display (" + secMon + ")",
                desc: "Show this bar only on your secondary screen"
            });
            opts.push({
                id: "all",
                title: "All Displays",
                desc: "Show synchronized bar across all screens (" + root.activeMonitorsSummary + ")"
            });
        } else {
            opts.push({
                id: "all",
                title: "All Displays (Single Screen)",
                desc: "Show on current display (" + primMon + ")"
            });
        }

        if (screens.length > 2) {
            for (let i = 2; i < screens.length; i++) {
                const sName = screens[i] ? screens[i].name : ("Display " + (i + 1));
                opts.push({
                    id: sName,
                    title: "Display " + (i + 1) + " (" + sName + ")",
                    desc: "Show this bar only on " + sName
                });
            }
        }
        return opts;
    }

    function openAddBarConfirm() {
        if (BarConfig.bars && BarConfig.bars.length >= 4) {
            root.showToast("Maximum of 4 bars reached", true);
            return;
        }
        const usedPos = (BarConfig.bars || []).map(b => b.position);
        const order = ["bottom", "left", "right", "top"];
        let defaultPos = "bottom";
        for (let i = 0; i < order.length; i++) {
            if (usedPos.indexOf(order[i]) === -1) {
                defaultPos = order[i];
                break;
            }
        }
        root.addBarChosenPosition = defaultPos;
        root.addBarChosenTarget = (root.hasMultipleMonitors && root.selectedMonitorFilter === "secondary") ? "secondary" : "primary";
        root.addBarModalVisible = true;
    }

    function confirmAddBar() {
        if (BarConfig.bars && BarConfig.bars.length >= 4) {
            root.showToast("Maximum of 4 bars reached", true);
            root.addBarModalVisible = false;
            return;
        }
        BarConfig.addBar(root.addBarChosenPosition, root.addBarChosenTarget);
        root.addBarModalVisible = false;
        const targetLabel = (root.addBarChosenTarget === "all")
            ? "All Displays"
            : root.getMonitorNameForTarget(root.addBarChosenTarget);
        const posLabel = root.addBarChosenPosition.charAt(0).toUpperCase() + root.addBarChosenPosition.slice(1);
        root.showToast("Added Bar " + BarConfig.bars.length + " on " + targetLabel + " (" + posLabel + ")", false);
    }

    property string selectedMonitorFilter: "primary"

    onHasMultipleMonitorsChanged: {
        if (!hasMultipleMonitors) {
            selectedMonitorFilter = "primary";
            BarConfig.activeEditingDisplay = "primary";
        }
    }

    function selectMonitorFilter(target) {
        root.selectedMonitorFilter = target;
        if (target === "secondary") {
            BarConfig.activeEditingDisplay = "secondary";
            const secTabs = root.allDesktopBarTabs.filter(t => t.monitorTarget === "secondary");
            if (secTabs.length > 0) {
                const hasCurrent = secTabs.some(t => t.barIndex === BarConfig.selectedBarIndex);
                if (!hasCurrent) {
                    BarConfig.selectedBarIndex = secTabs[0].barIndex;
                }
            }
        } else if (target === "primary") {
            BarConfig.activeEditingDisplay = "primary";
            const primTabs = root.allDesktopBarTabs.filter(t => t.monitorTarget === "primary");
            if (primTabs.length > 0) {
                const hasCurrent = primTabs.some(t => t.barIndex === BarConfig.selectedBarIndex);
                if (!hasCurrent) {
                    BarConfig.selectedBarIndex = primTabs[0].barIndex;
                }
            }
        }
        subTabContentAnim.restart();
    }

    readonly property var allDesktopBarTabs: {
        void BarConfig.bars;
        void BarConfig.selectedBarIndex;
        void BarConfig.position;
        void BarConfig.secondaryPosition;
        void BarConfig.displayTarget;
        void BarConfig.panelsRevision;
        void root.activeScreensList;

        const primMon = root.getMonitorNameForTarget("primary");
        const secMon = root.getMonitorNameForTarget("secondary");

        const list = [];
        const rawBars = BarConfig.bars || [];
        for (let i = 0; i < rawBars.length; ++i) {
            const bar = rawBars[i];
            if (!bar) continue;
            const dispTarget = bar.displayTarget || (bar.allMonitors ? "all" : "primary");
            const primPos = bar.position || "top";
            const secPos = (dispTarget === "all") ? (bar.secondaryPosition || bar.position || "top") : (bar.position || "bottom");
            const baseName = root.cleanBarName(bar.name, i === 0 ? "Primary Bar" : ("Bar " + (i + 1)));

            if (dispTarget === "all") {
                list.push({
                    barIndex: i,
                    display: "primary",
                    name: (rawBars.length === 1 && i === 0) ? "Primary Bar" : baseName,
                    pos: primPos,
                    posLabel: primPos.charAt(0).toUpperCase() + primPos.slice(1),
                    monitor: primMon,
                    monitorRole: root.hasMultipleMonitors ? "Primary" : "Single",
                    monitorTarget: "primary",
                    enabled: bar.enabled !== false,
                    isSecondary: false,
                    rawBar: bar
                });

                if (root.hasMultipleMonitors && secMon) {
                    list.push({
                        barIndex: i,
                        display: "secondary",
                        name: (rawBars.length === 1 && i === 0) ? "Secondary Bar" : baseName,
                        pos: secPos,
                        posLabel: secPos.charAt(0).toUpperCase() + secPos.slice(1),
                        monitor: secMon,
                        monitorRole: "Secondary",
                        monitorTarget: "secondary",
                        enabled: bar.enabled !== false,
                        isSecondary: true,
                        rawBar: bar
                    });
                }
            } else if (dispTarget === "secondary") {
                const targetMon = secMon || (root.hasMultipleMonitors ? "Secondary" : primMon);
                list.push({
                    barIndex: i,
                    display: root.hasMultipleMonitors ? "secondary" : "primary",
                    name: baseName,
                    pos: secPos,
                    posLabel: secPos.charAt(0).toUpperCase() + secPos.slice(1),
                    monitor: targetMon,
                    monitorRole: root.hasMultipleMonitors ? "Secondary" : "Single",
                    monitorTarget: "secondary",
                    enabled: bar.enabled !== false,
                    isSecondary: root.hasMultipleMonitors,
                    rawBar: bar
                });
            } else {
                const targetMon = (dispTarget === "primary") ? primMon : root.getMonitorNameForTarget(dispTarget);
                list.push({
                    barIndex: i,
                    display: "primary",
                    name: baseName,
                    pos: primPos,
                    posLabel: primPos.charAt(0).toUpperCase() + primPos.slice(1),
                    monitor: targetMon,
                    monitorRole: root.hasMultipleMonitors ? "Primary" : "Single",
                    monitorTarget: "primary",
                    enabled: bar.enabled !== false,
                    isSecondary: false,
                    rawBar: bar
                });
            }
        }
        return list;
    }

    readonly property var desktopBarTabs: {
        const all = root.allDesktopBarTabs;
        if (!root.hasMultipleMonitors || root.selectedMonitorFilter === "all") {
            return all;
        }
        return all.filter(t => t.monitorTarget === root.selectedMonitorFilter);
    }

    function currentBarId() {
        return (BarConfig.currentBar && BarConfig.currentBar.id) ? String(BarConfig.currentBar.id) : "bar_1";
    }

    function withAlpha(col, alpha) {
        if (!col) return Qt.rgba(0, 0, 0, alpha);
        const c = Qt.color(col);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    function _trackColorDeps() {
        if (root.theme) {
            void root.theme.currentName;
            void root.theme.customAccent;
            void root.theme.previewAccent;
            void root.theme.wallpaperMode;
            void root.theme.accentPrimary;
            void root.theme.accentCyan;
            void root.theme.accentGreen;
            void root.theme.accentOrange;
            void root.theme.accentRed;
            void root.theme.textPrimary;
            void root.theme.textSecondary;
            void root.theme.textMuted;
            void root.theme.bgBase;
            void root.theme.themes;
        }
        void BarConfig.selectedBarIndex;
        void BarConfig.removedWidgets;
    }

    function getBlockColorSpec(widgetId) {
        _trackColorDeps();
        if (!widgetId) return "";
        const prefix = "@color:" + currentBarId() + ":" + widgetId + "=";
        const rem = BarConfig.removedWidgets || [];
        for (let i = 0; i < rem.length; i++) {
            const s = String(rem[i]);
            if (s.indexOf(prefix) === 0) return s.substring(prefix.length).trim();
        }
        return "";
    }

    function setBlockColorSpec(widgetId, spec) {
        if (!widgetId) return;
        const prefix = "@color:" + currentBarId() + ":" + widgetId + "=";
        let rem = (BarConfig.removedWidgets || []).filter(item => String(item).indexOf(prefix) !== 0);
        const clean = spec ? String(spec).trim() : "";
        if (clean !== "") rem.push(prefix + clean);
        BarConfig.removedWidgets = rem;
        BarConfig.saveConfig();
    }

    function setPanelBlocksColorSpec(panelIndex, spec) {
        const pList = BarConfig.panels || [];
        if (panelIndex < 0 || panelIndex >= pList.length) return;
        const widgets = pList[panelIndex] || [];
        const bId = currentBarId();
        let rem = (BarConfig.removedWidgets || []).slice();
        const clean = spec ? String(spec).trim() : "";
        for (let i = 0; i < widgets.length; i++) {
            const prefix = "@color:" + bId + ":" + widgets[i] + "=";
            rem = rem.filter(item => String(item).indexOf(prefix) !== 0);
            if (clean !== "") rem.push(prefix + clean);
        }
        BarConfig.removedWidgets = rem;
        BarConfig.saveConfig();
    }

    function getPanelColorSpec(panelIndex) {
        _trackColorDeps();
        const pList = BarConfig.panels || [];
        if (panelIndex < 0 || panelIndex >= pList.length) return "";
        const widgets = pList[panelIndex] || [];
        if (widgets.length === 0) return "";
        const firstSpec = getBlockColorSpec(widgets[0]);
        for (let i = 1; i < widgets.length; i++) {
            if (getBlockColorSpec(widgets[i]) !== firstSpec) return "";
        }
        return firstSpec;
    }

    function clearAllBlockColorsForCurrentBar() {
        const prefix = "@color:" + currentBarId() + ":";
        BarConfig.removedWidgets = (BarConfig.removedWidgets || []).filter(item => String(item).indexOf(prefix) !== 0);
        BarConfig.saveConfig();
    }

    function getActiveTargetSpec() {
        if (root.selectedColorTargetType === "bar") {
            return BarConfig.currentBar ? (BarConfig.currentBar.barColor || "") : (BarConfig.barColor || "");
        }
        return root.selectedColorTargetType === "panel"
            ? root.getPanelColorSpec(root.selectedColorPanelIndex)
            : root.getBlockColorSpec(root.selectedColorWidgetId);
    }

    function applyColorToActiveTarget(spec) {
        if (root.selectedColorTargetType === "bar") {
            BarConfig.updateBarProp("barColor", spec);
        } else if (root.selectedColorTargetType === "panel") {
            root.setPanelBlocksColorSpec(root.selectedColorPanelIndex, spec);
        } else {
            root.setBlockColorSpec(root.selectedColorWidgetId, spec);
        }
    }

    function resolveThemeSpec(spec, fallbackColor) {
        _trackColorDeps();
        const fb = fallbackColor !== undefined ? fallbackColor : root.theme.accentPrimary;
        if (!spec || String(spec).trim() === "") return fb;
        const s = String(spec).trim();
        try {
            if (s.indexOf("theme:") === 0) {
                const parts = s.split(":");
                if (parts.length >= 3) {
                    const tName = parts.slice(1, parts.length - 1).join(":");
                    const roleKey = parts[parts.length - 1];
                    const tList = (root.theme && root.theme.themes) ? root.theme.themes : [];
                    for (let i = 0; i < tList.length; i++) {
                        if (tList[i] && tList[i].name === tName && tList[i][roleKey]) {
                            return Qt.color(String(tList[i][roleKey]));
                        }
                    }
                }
            }
            if (root.theme && root.theme[s] !== undefined && typeof root.theme[s] !== "function") {
                return root.theme[s];
            }
            if (root.theme && root.theme.current && root.theme.current[s]) {
                return Qt.color(String(root.theme.current[s]));
            }
            if (s.charAt(0) === "#") return Qt.color(s);
        } catch (e) {}
        return fb;
    }

    function getSpecLabel(spec) {
        if (!spec || String(spec).trim() === "") return "Auto";
        const s = String(spec).trim();
        if (s.indexOf("theme:") === 0) {
            const parts = s.split(":");
            if (parts.length >= 3) {
                const tName = parts.slice(1, parts.length - 1).join(":");
                const roleKey = parts[parts.length - 1];
                return tName + " · " + roleKey.replace("accent", "").replace("text", "");
            }
        }
        for (let i = 0; i < root.themeRoles.length; i++) {
            if (root.themeRoles[i].key === s) return root.themeRoles[i].label;
        }
        return s;
    }

    function getWidgetPanelBadge(widgetId) {
        const pList = BarConfig.panels || [];
        for (let p = 0; p < pList.length; p++) {
            if ((pList[p] || []).indexOf(widgetId) !== -1) return "P" + (p + 1);
        }
        return "Unused";
    }

    function startBlockDrag(widgetId, srcPanelIdx, srcItemIdx, rootX, rootY) {
        root.draggedWidgetId = widgetId;
        root.dragSourcePanelIndex = srcPanelIdx;
        root.dragSourceItemIndex = srcItemIdx;
        root.dragMouseX = rootX;
        root.dragMouseY = rootY;
        root.dragHoverPanelIndex = srcPanelIdx;
        root.dragHoverItemIndex = srcItemIdx;
        root.isDraggingBlock = true;
        updateBlockDragHover(rootX, rootY);
    }

    function updateBlockDragHover(rootX, rootY) {
        root.dragMouseX = rootX;
        root.dragMouseY = rootY;
        if (!root.isDraggingBlock) return;

        for (let p = 0; p < layoutCard.panelRepeater.count; p++) {
            const panelCard = layoutCard.panelRepeater.itemAt(p);
            if (!panelCard) continue;
            const pt = panelCard.mapFromItem(root, rootX, rootY);
            if (pt.x >= -8 && pt.x <= panelCard.width + 8 && pt.y >= -8 && pt.y <= panelCard.height + 8) {
                root.dragHoverPanelIndex = p;
                const blocksRep = panelCard.blocksRepeater;
                if (!blocksRep || blocksRep.count === 0) {
                    root.dragHoverItemIndex = 0;
                    return;
                }
                let foundIdx = blocksRep.count;
                for (let i = 0; i < blocksRep.count; i++) {
                    const cItem = blocksRep.itemAt(i);
                    if (!cItem) continue;
                    const cPt = cItem.mapFromItem(root, rootX, rootY);
                    if (cPt.y <= cItem.height * 0.5) {
                        foundIdx = i;
                        break;
                    }
                }
                root.dragHoverItemIndex = foundIdx;
                return;
            }
        }

        if (layoutCard.poolCard && root.dragSourcePanelIndex >= 0) {
            const poolPt = layoutCard.poolCard.mapFromItem(root, rootX, rootY);
            if (poolPt.x >= -8 && poolPt.x <= layoutCard.poolCard.width + 8 && poolPt.y >= -8 && poolPt.y <= layoutCard.poolCard.height + 8) {
                root.dragHoverPanelIndex = -2;
                root.dragHoverItemIndex = -1;
                return;
            }
        }

        root.dragHoverPanelIndex = -1;
        root.dragHoverItemIndex = -1;
    }

    function finishBlockDrag() {
        if (!root.isDraggingBlock) return;
        const wId = root.draggedWidgetId;
        const targetP = root.dragHoverPanelIndex;
        const targetI = root.dragHoverItemIndex;
        const srcP = root.dragSourcePanelIndex;

        root.isDraggingBlock = false;
        root.dragHoverPanelIndex = -1;
        root.dragHoverItemIndex = -1;

        if (!wId) return;
        if (targetP === -2) {
            BarConfig.moveWidgetToPanelAt(wId, -1, -1);
        } else if (targetP >= 0) {
            if (srcP !== targetP && !BarConfig.canAddWidgetToPanel(wId, targetP)) {
                root.showToast("Already maxed out, please move somewhere else", true);
                return;
            }
            if (!BarConfig.moveWidgetToPanelAt(wId, targetP, targetI)) {
                root.showToast("Already maxed out, please move somewhere else", true);
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 24
        clip: true
        interactive: !root.isDraggingBlock
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
            width: parent.width - 10
            spacing: 18

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 3
                    Text {
                        text: "Bar Settings"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                    Text {
                        text: "Configure modular building blocks, panel count, block colors, and bar appearance"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
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
                    onClicked: openBackupProc.running = true
                }

                ActionButton {
                    iconText: "󰦛"
                    label: "Reset to Default"
                    onClicked: BarConfig.resetDefaults()
                }
            }

            Connections {
                target: BarConfig
                function onSelectedBarIndexChanged() {
                    subTabContentAnim.restart();
                }
            }

            ParallelAnimation {
                id: subTabContentAnim
                NumberAnimation {
                    target: subTabContentContainer
                    property: "opacity"
                    from: 0.3
                    to: 1.0
                    duration: 210
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: subTabContentTranslate
                    property: "y"
                    from: 6
                    to: 0
                    duration: 210
                    easing.type: Easing.OutCubic
                }
            }

            BarListCard {
                root: root
            }

            BarSubTabSelector {
                root: root
            }

            ColumnLayout {
                id: subTabContentContainer
                Layout.fillWidth: true
                spacing: 20
                transform: Translate { id: subTabContentTranslate; y: 0 }

                BarLayoutCard {
                    id: layoutCard
                    root: root
                }

                ColumnLayout {
                    visible: root.currentSubTab === 1
                    Layout.fillWidth: true
                    spacing: 16

                    ColorTargetCard {
                        root: root
                    }

                    ColorAssignCard {
                        root: root
                    }
                }

                ColumnLayout {
                    id: generalTabCol
                    visible: root.currentSubTab === 2
                    Layout.fillWidth: true
                    spacing: 20

                    readonly property string curPos: BarConfig.currentBar ? BarConfig.currentBar.position : BarConfig.position
                    readonly property bool curIsVert: (curPos === "left" || curPos === "right")
                    readonly property int curHeight: BarConfig.currentBar ? Number(BarConfig.currentBar.barHeight) : BarConfig.barHeight
                    readonly property bool curFloating: BarConfig.currentBar ? Boolean(BarConfig.currentBar.floating) : BarConfig.floating
                    readonly property real curOpacity: BarConfig.currentBar ? Number(BarConfig.currentBar.barOpacity) : BarConfig.barOpacity
                    readonly property int curPillRadius: BarConfig.currentBar ? (BarConfig.currentBar.pillRadius !== undefined ? Number(BarConfig.currentBar.pillRadius) : 10) : BarConfig.pillRadius
                    readonly property real curPillOpacity: BarConfig.currentBar ? (BarConfig.currentBar.pillOpacity !== undefined ? Number(BarConfig.currentBar.pillOpacity) : 1.0) : BarConfig.pillOpacity
                    readonly property bool curHidePill: BarConfig.currentBar ? Boolean(BarConfig.currentBar.hidePill) : BarConfig.hidePill
                    readonly property string curActiveStyle: BarConfig.currentBar ? (BarConfig.currentBar.activeStyle || BarConfig.activeStyle || "pill") : (BarConfig.activeStyle || "pill")
                    readonly property string curBarColor: BarConfig.currentBar ? (BarConfig.currentBar.barColor || "") : (BarConfig.barColor || "")
                    readonly property bool curAllMonitors: BarConfig.currentBar ? Boolean(BarConfig.currentBar.allMonitors) : BarConfig.allMonitors
                    readonly property string curDisplayTarget: BarConfig.currentBar ? (BarConfig.currentBar.displayTarget || (BarConfig.currentBar.allMonitors ? "all" : "primary")) : BarConfig.displayTarget
                    readonly property string curSecondaryMode: BarConfig.currentBar ? (BarConfig.currentBar.secondaryMode || "custom") : BarConfig.secondaryMode
                    readonly property bool curBlankOnSecondary: BarConfig.currentBar ? (BarConfig.currentBar.blankOnSecondary !== undefined ? Boolean(BarConfig.currentBar.blankOnSecondary) : false) : BarConfig.blankOnSecondary
                    readonly property bool curEnabled: BarConfig.currentBar ? (BarConfig.currentBar.enabled !== false) : BarConfig.barVisible

                    GeneralBarCard {
                        root: root
                    }

                    NetworkSpeedOptionsCard {
                        root: root
                    }

                    ClockOptionsCard {
                        root: root
                    }

                    WorkspacesOptionsCard {
                        root: root
                    }

                    GlobalMenuOptionsCard {
                        root: root
                    }

                    WeatherOptionsCard {
                        root: root
                    }

                    BatteryOptionsCard {
                        root: root
                    }

                    CavaOptionsCard {
                        root: root
                    }

                    HardwareMonitorOptionsCard {
                        root: root
                    }
                }
            }
        }
    }

    DragGhostCard {
        root: root
    }

    // Add Bar Confirmation Modal Overlay (for 2 or more monitors)
    AddBarConfirmModal {
        root: root
    }

    // Feedback Toast (bottom floating notification)
    StatusToast {
        root: root
    }
}
