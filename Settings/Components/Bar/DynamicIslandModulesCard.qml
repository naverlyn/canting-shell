import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../../../bar"
import "../../../ControlCenter"
import "../Common"
import ".."

ColumnLayout {
    required property var root
    id: self
    Layout.fillWidth: true
    spacing: 8

    readonly property var curBar: BarConfig.currentBar
    readonly property var curModules: {
        void BarConfig.panelsRevision;
        return (curBar && Array.isArray(curBar.islandModules) && curBar.islandModules.length > 0)
            ? curBar.islandModules
            : BarConfig.islandModules;
    }
    readonly property var curControlTiles: {
        void BarConfig.panelsRevision;
        return (curBar && Array.isArray(curBar.islandControlTiles))
            ? curBar.islandControlTiles
            : (BarConfig.islandControlTiles || []);
    }
    readonly property bool isCustomControls: curControlTiles && curControlTiles.length > 0
    readonly property var curAppShortcuts: {
        void BarConfig.panelsRevision;
        return (curBar && Array.isArray(curBar.islandAppShortcuts))
            ? curBar.islandAppShortcuts
            : (BarConfig.islandAppShortcuts || []);
    }
    property string appSearchQuery: ""

    // Drag-to-reorder state for Hub Modules
    property string dragModId: ""
    property string dragModLabel: ""
    property bool dragModFromAvail: false
    property bool dragModOverAvail: false
    property int dragHoverModIndex: -1
    property real dragModX: 0
    property real dragModY: 0

    // Drag-to-reorder state for Custom Control Tiles
    property string dragTileId: ""
    property string dragTileLabel: ""
    property bool dragTileFromAvail: false
    property bool dragTileOverAvail: false
    property int dragHoverTileIndex: -1
    property real dragTileX: 0
    property real dragTileY: 0

    function updateModDrag(selfX, selfY) {
        self.dragModX = selfX;
        self.dragModY = selfY;
        const ap = activeModPanel.mapFromItem(self, selfX, selfY);
        if (ap.x >= -8 && ap.x <= activeModPanel.width + 8 && ap.y >= -8 && ap.y <= activeModPanel.height + 8) {
            self.dragModOverAvail = false;
            const listPt = activeModListCol.mapFromItem(self, selfX, selfY);
            const cnt = activeModRepeater.count;
            let found = cnt;
            for (let i = 0; i < cnt; i++) {
                const it = activeModRepeater.itemAt(i);
                if (!it) continue;
                if (listPt.y <= it.y + it.height * 0.5) {
                    found = i;
                    break;
                }
            }
            self.dragHoverModIndex = found;
            return;
        }
        const avp = availModPanel.mapFromItem(self, selfX, selfY);
        if (!self.dragModFromAvail && avp.x >= -8 && avp.x <= availModPanel.width + 8 && avp.y >= -8 && avp.y <= availModPanel.height + 8) {
            self.dragModOverAvail = true;
            self.dragHoverModIndex = -1;
            return;
        }
        self.dragModOverAvail = false;
        self.dragHoverModIndex = -1;
    }

    function finishModDrag() {
        const id = self.dragModId;
        if (!id) return;
        if (self.dragModOverAvail && !self.dragModFromAvail) {
            self.removeModule(id);
        } else if (self.dragHoverModIndex >= 0) {
            let list = (self.curModules || []).slice();
            const fromIdx = list.indexOf(id);
            let target = self.dragHoverModIndex;
            if (fromIdx !== -1) {
                list.splice(fromIdx, 1);
                if (fromIdx < target) target = Math.max(0, target - 1);
            }
            target = Math.max(0, Math.min(list.length, target));
            list.splice(target, 0, id);
            BarConfig.updateBarProp("islandModules", list);
        }
        self.dragModId = "";
        self.dragModLabel = "";
        self.dragModFromAvail = false;
        self.dragModOverAvail = false;
        self.dragHoverModIndex = -1;
    }

    function updateTileDrag(selfX, selfY) {
        self.dragTileX = selfX;
        self.dragTileY = selfY;
        const ap = activeTilePanel.mapFromItem(self, selfX, selfY);
        if (ap.x >= -8 && ap.x <= activeTilePanel.width + 8 && ap.y >= -8 && ap.y <= activeTilePanel.height + 8) {
            self.dragTileOverAvail = false;
            const listPt = activeTileListCol.mapFromItem(self, selfX, selfY);
            const cnt = activeTileRepeater.count;
            let found = cnt;
            for (let i = 0; i < cnt; i++) {
                const it = activeTileRepeater.itemAt(i);
                if (!it) continue;
                if (listPt.y <= it.y + it.height * 0.5) {
                    found = i;
                    break;
                }
            }
            self.dragHoverTileIndex = found;
            return;
        }
        const avp = availTilePanel.mapFromItem(self, selfX, selfY);
        if (!self.dragTileFromAvail && avp.x >= -8 && avp.x <= availTilePanel.width + 8 && avp.y >= -8 && avp.y <= availTilePanel.height + 8) {
            self.dragTileOverAvail = true;
            self.dragHoverTileIndex = -1;
            return;
        }
        self.dragTileOverAvail = false;
        self.dragHoverTileIndex = -1;
    }

    function finishTileDrag() {
        const id = self.dragTileId;
        if (!id) return;
        if (self.dragTileOverAvail && !self.dragTileFromAvail) {
            self.removeControlTile(id);
        } else if (self.dragHoverTileIndex >= 0) {
            let list = (self.curControlTiles || []).slice();
            const fromIdx = list.indexOf(id);
            let target = self.dragHoverTileIndex;
            if (fromIdx !== -1) {
                list.splice(fromIdx, 1);
                if (fromIdx < target) target = Math.max(0, target - 1);
            }
            target = Math.max(0, Math.min(list.length, target));
            list.splice(target, 0, id);
            BarConfig.updateBarProp("islandControlTiles", list);
        }
        self.dragTileId = "";
        self.dragTileLabel = "";
        self.dragTileFromAvail = false;
        self.dragTileOverAvail = false;
        self.dragHoverTileIndex = -1;
    }

    function getDefaultControlCenterTileIds() {
        const seen = {};
        const out = [];
        const enabled = ControlCenterConfig.enabledTiles || [];
        for (let i = 0; i < enabled.length; i++) {
            const tid = enabled[i] ? enabled[i].id : "";
            if (tid && !seen[tid]) { seen[tid] = true; out.push(tid); }
        }
        const cards = ControlCenterConfig.enabledCards || [];
        for (let c = 0; c < cards.length; c++) {
            const cid = cards[c] ? String(cards[c].id || "") : "";
            if (cid.indexOf("tile:") === 0) {
                const tid = cid.substring(5);
                if (tid && !seen[tid]) { seen[tid] = true; out.push(tid); }
            }
        }
        return out.length > 0 ? out : ["wifi", "bluetooth", "dnd", "caffeine", "nightlight", "darkmode"];
    }

    function setControlsSourceMode(mode) {
        if (mode === "sync") {
            BarConfig.updateBarProp("islandControlTiles", []);
        } else if (!self.isCustomControls) {
            BarConfig.updateBarProp("islandControlTiles", self.getDefaultControlCenterTileIds());
        }
    }

    function isModuleEnabled(modId) {
        return (self.curModules || []).indexOf(modId) !== -1;
    }

    function addModule(modId) {
        let list = (self.curModules || []).slice();
        if (list.indexOf(modId) !== -1) return;
        list.push(modId);
        BarConfig.updateBarProp("islandModules", list);
    }

    function removeModule(modId) {
        let list = (self.curModules || []).slice();
        const idx = list.indexOf(modId);
        if (idx === -1) return;
        if (list.length <= 1) {
            self.root.showToast("Keep at least one Dynamic Island module enabled", true);
            return;
        }
        list.splice(idx, 1);
        BarConfig.updateBarProp("islandModules", list);
    }

    function reorderModule(modId, targetIdx) {
        let list = (self.curModules || []).slice();
        const fromIdx = list.indexOf(modId);
        if (fromIdx === -1) return;
        const clamped = Math.max(0, Math.min(list.length - 1, targetIdx));
        if (clamped === fromIdx) return;
        list.splice(fromIdx, 1);
        list.splice(clamped, 0, modId);
        BarConfig.updateBarProp("islandModules", list);
    }

    function getActiveModuleDefs() {
        const enabled = self.curModules || [];
        const all = BarConfig.islandModuleDefinitions || [];
        const out = [];
        for (let i = 0; i < enabled.length; i++) {
            for (let j = 0; j < all.length; j++) {
                if (all[j].id === enabled[i]) { out.push(all[j]); break; }
            }
        }
        return out;
    }

    function getAvailableModuleDefs() {
        const enabled = self.curModules || [];
        const all = BarConfig.islandModuleDefinitions || [];
        const out = [];
        for (let k = 0; k < all.length; k++) {
            if (enabled.indexOf(all[k].id) === -1) out.push(all[k]);
        }
        return out;
    }

    function addControlTile(tid) {
        let list = (self.curControlTiles || []).slice();
        if (list.indexOf(tid) !== -1) return;
        list.push(tid);
        BarConfig.updateBarProp("islandControlTiles", list);
    }

    function removeControlTile(tid) {
        let list = (self.curControlTiles || []).slice();
        const idx = list.indexOf(tid);
        if (idx === -1) return;
        if (list.length <= 1) {
            self.root.showToast("Keep at least one quick control tile enabled", true);
            return;
        }
        list.splice(idx, 1);
        BarConfig.updateBarProp("islandControlTiles", list);
    }

    function reorderControlTile(tid, targetIdx) {
        let list = (self.curControlTiles || []).slice();
        const fromIdx = list.indexOf(tid);
        if (fromIdx === -1) return;
        const clamped = Math.max(0, Math.min(list.length - 1, targetIdx));
        if (clamped === fromIdx) return;
        list.splice(fromIdx, 1);
        list.splice(clamped, 0, tid);
        BarConfig.updateBarProp("islandControlTiles", list);
    }

    function getActiveControlTileDefs() {
        const enabled = self.curControlTiles || [];
        const all = ControlCenterConfig.allTileDefs || [];
        const out = [];
        for (let i = 0; i < enabled.length; i++) {
            for (let j = 0; j < all.length; j++) {
                if (all[j].id === enabled[i]) { out.push(all[j]); break; }
            }
        }
        return out;
    }

    function getAvailableControlTileDefs() {
        const enabled = self.curControlTiles || [];
        const all = ControlCenterConfig.allTileDefs || [];
        const out = [];
        for (let k = 0; k < all.length; k++) {
            if (enabled.indexOf(all[k].id) === -1) out.push(all[k]);
        }
        return out;
    }

    function getAllDesktopEntries() {
        const list = (DesktopEntries && DesktopEntries.applications && DesktopEntries.applications.values)
            ? [...DesktopEntries.applications.values]
            : [];
        return list.filter(e => e && e.name && !e.noDisplay).sort((a, b) => (a.name || "").localeCompare(b.name || ""));
    }

    function findDesktopEntry(appId) {
        const target = String(appId || "").trim().toLowerCase();
        if (!target) return null;
        const all = getAllDesktopEntries();
        for (let i = 0; i < all.length; i++) {
            if (String(all[i].id || "").toLowerCase() === target || String(all[i].name || "").toLowerCase() === target) {
                return all[i];
            }
        }
        return DesktopEntries.heuristicLookup(appId) || null;
    }

    function getPinnedAppEntries() {
        const ids = self.curAppShortcuts || [];
        const out = [];
        for (let i = 0; i < ids.length; i++) {
            const e = self.findDesktopEntry(ids[i]);
            if (e) {
                out.push({
                    id: String(e.id || ids[i]),
                    name: String(e.name || ids[i]),
                    icon: String(e.icon || "")
                });
            }
        }
        return out;
    }

    function getFilteredDesktopApps() {
        const q = self.appSearchQuery.trim().toLowerCase();
        const all = self.getAllDesktopEntries();
        return all.filter(e => {
            if (self.findPinnedIndex(e) !== -1) return false;
            if (q === "") return true;
            const eid = String(e.id || "").toLowerCase();
            return (e.name && e.name.toLowerCase().includes(q)) ||
                   (e.genericName && e.genericName.toLowerCase().includes(q)) ||
                   eid.includes(q);
        });
    }

    function findPinnedIndex(entry) {
        if (!entry) return -1;
        const eid = String(entry.id || entry.name || "").toLowerCase();
        const ename = String(entry.name || "").toLowerCase();
        const list = self.curAppShortcuts || [];
        for (let i = 0; i < list.length; i++) {
            const cur = String(list[i] || "").toLowerCase();
            if (cur === eid || cur === ename) return i;
        }
        return -1;
    }

    function addAppShortcut(appId) {
        let list = (self.curAppShortcuts || []).slice();
        if (list.indexOf(appId) !== -1) return;
        list.push(appId);
        BarConfig.updateBarProp("islandAppShortcuts", list);
    }

    function removeAppShortcut(appId) {
        let list = (self.curAppShortcuts || []).slice();
        const lower = String(appId || "").toLowerCase();
        const idx = list.findIndex(x => String(x || "").toLowerCase() === lower);
        if (idx === -1) return;
        list.splice(idx, 1);
        BarConfig.updateBarProp("islandAppShortcuts", list);
    }

    function reorderAppShortcut(appId, targetIdx) {
        let list = (self.curAppShortcuts || []).slice();
        const lower = String(appId || "").toLowerCase();
        const fromIdx = list.findIndex(x => String(x || "").toLowerCase() === lower);
        if (fromIdx === -1) return;
        const clamped = Math.max(0, Math.min(list.length - 1, targetIdx));
        if (clamped === fromIdx) return;
        const item = list.splice(fromIdx, 1)[0];
        list.splice(clamped, 0, item);
        BarConfig.updateBarProp("islandAppShortcuts", list);
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 8

        Text {
            text: "Dynamic Island Hub Modules"
            font.family: Style.font
            font.pixelSize: Style.px(13)
            font.bold: Style.boldHeadings
            font.letterSpacing: Style.letterSpacing
            font.hintingPreference: Style.fontHintingEnum
            antialiasing: Style.fontAntialiasing
            renderType: Style.fontRenderTypeEnum
            color: Style.theme.textSecondary
            Layout.minimumWidth: implicitWidth
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }
    }

    Rectangle {
        id: outerCard
        Layout.fillWidth: true
        implicitHeight: innerCol.implicitHeight + 24
        radius: 12
        color: Style.theme.bgSurface
        border.color: Style.theme.bgBorder
        border.width: 1

        // Floating drag ghost following the cursor (matching DragGhostCard.qml)
        Rectangle {
            id: modGhost
            readonly property bool isMod: self.dragModId !== ""
            readonly property bool isTile: self.dragTileId !== ""
            readonly property bool active: isMod || isTile
            readonly property bool isRemoving: (isMod && self.dragModOverAvail && !self.dragModFromAvail)
                || (isTile && self.dragTileOverAvail && !self.dragTileFromAvail)
            readonly property string labelText: isMod ? self.dragModLabel : self.dragTileLabel
            readonly property real targetX: isMod ? self.dragModX : self.dragTileX
            readonly property real targetY: isMod ? self.dragModY : self.dragTileY

            visible: opacity > 0.01
            z: 9999
            implicitWidth: ghostTxt.implicitWidth + 28
            width: implicitWidth
            height: 36
            radius: 8
            x: Math.max(4, Math.min(outerCard.width - width - 4, targetX - outerCard.x - (width / 2)))
            y: Math.max(4, Math.min(outerCard.height - height - 4, targetY - outerCard.y - (height / 2)))
            scale: active ? 1.04 : 0.92
            opacity: active ? 0.96 : 0.0
            color: isRemoving ? self.root.withAlpha(self.root.theme.accentRed, 0.18) : self.root.theme.bgSelected
            border.color: isRemoving ? self.root.theme.accentRed : self.root.theme.accentPrimary
            border.width: 1.5

            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

            Text {
                id: ghostTxt
                anchors.centerIn: parent
                text: modGhost.isRemoving ? ("Remove " + modGhost.labelText) : modGhost.labelText
                font.family: self.root.font
                font.pixelSize: 11
                font.bold: true
                color: modGhost.isRemoving ? self.root.theme.accentRed : self.root.theme.textPrimary
            }
        }

        ColumnLayout {
            id: innerCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 12

            // 2-Column Panel Layout matching BarLayoutCard (Active Modules | Available Modules)
            GridLayout {
                columns: 2
                columnSpacing: 12
                rowSpacing: 12
                Layout.fillWidth: true

                // Left Panel: Active Hub Modules (Drag-to-reorder)
                Rectangle {
                    id: activeModPanel
                    readonly property var activeList: self.getActiveModuleDefs()
                    readonly property bool isPanelTarget: self.dragModId !== "" && !self.dragModOverAvail && self.dragHoverModIndex >= 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: Math.max(190, activeCol.implicitHeight + 20)
                    radius: 10
                    color: isPanelTarget ? self.root.withAlpha(self.root.theme.accentPrimary, 0.06) : self.root.theme.bgBase
                    border.color: isPanelTarget ? self.root.theme.accentPrimary : self.root.theme.bgBorder
                    border.width: isPanelTarget ? 1.5 : 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        id: activeCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 10
                        }
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 30
                            radius: 7
                            color: self.root.theme.bgSelected

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 6

                                Text {
                                    text: "Active Modules"
                                    font.family: self.root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: self.root.theme.accentPrimary
                                }

                                Rectangle {
                                    implicitWidth: actBadgeTxt.implicitWidth + 10
                                    implicitHeight: 18
                                    radius: 9
                                    color: self.root.withAlpha(self.root.theme.textMuted, 0.12)

                                    Text {
                                        id: actBadgeTxt
                                        anchors.centerIn: parent
                                        text: "(" + (self.curModules || []).length + ")"
                                        font.family: self.root.font
                                        font.pixelSize: 10
                                        color: self.root.theme.textMuted
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }

                        Column {
                            id: activeModListCol
                            Layout.fillWidth: true
                            spacing: 6
                            move: Transition { NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic } }
                            add: Transition { NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic } }

                            Repeater {
                                id: activeModRepeater
                                model: ScriptModel {
                                    values: self.getActiveModuleDefs()
                                    objectProp: "id"
                                }
                                delegate: Rectangle {
                                    id: activeModCard
                                    required property var modelData
                                    required property int index
                                    width: activeModListCol.width
                                    readonly property bool isDragged: self.dragModId === modelData.id
                                    readonly property bool isBeforeThis: self.dragModId !== "" && !isDragged && self.dragHoverModIndex === index
                                    readonly property bool isAfterThis: self.dragModId !== "" && !isDragged && (
                                        (self.dragHoverModIndex === index + 1) ||
                                        (index === activeModRepeater.count - 1 && self.dragHoverModIndex >= activeModRepeater.count)
                                    )
                                    readonly property bool isDropTarget: isBeforeThis || isAfterThis

                                    height: 38
                                    radius: 8
                                    scale: isDragged ? 0.96 : 1.0
                                    opacity: isDragged ? 0.35 : 1.0
                                    color: isDropTarget
                                        ? self.root.theme.bgSelected
                                        : (actCardHover.hovered ? self.root.theme.bgHover : self.root.theme.bgBase)
                                    border.color: (isDropTarget || isDragged)
                                        ? self.root.theme.accentPrimary
                                        : (actCardHover.hovered ? self.root.theme.accentPrimary : self.root.theme.bgBorder)
                                    border.width: isDropTarget ? 1.5 : 1

                                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                    HoverHandler { id: actCardHover }

                                    Rectangle {
                                        visible: activeModCard.isDropTarget
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        y: activeModCard.isAfterThis ? parent.height - 3 : 1
                                        height: 2
                                        radius: 1
                                        color: self.root.theme.accentPrimary
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Text {
                                            text: "󰍜"
                                            font.family: self.root.font
                                            font.pixelSize: 11
                                            color: actCardHover.hovered ? self.root.theme.textSecondary : self.root.theme.textMuted
                                            opacity: actCardHover.hovered ? 0.85 : 0.35
                                            Layout.preferredWidth: 12
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: activeModCard.modelData.icon || "󰄲"
                                            font.family: self.root.font
                                            font.pixelSize: 13
                                            color: self.root.theme.accentPrimary
                                            horizontalAlignment: Text.AlignHCenter
                                            Layout.preferredWidth: 18
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: activeModCard.modelData.name
                                            font.family: self.root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: self.root.theme.textPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        RowLayout {
                                            id: modBtnRow
                                            z: 2
                                            spacing: 3
                                            Layout.alignment: Qt.AlignVCenter

                                            MiniIconButton {
                                                visible: actCardHover.hovered && activeModCard.index > 0
                                                iconText: "󰅃"
                                                onClicked: self.reorderModule(activeModCard.modelData.id, activeModCard.index - 1)
                                            }

                                            MiniIconButton {
                                                visible: actCardHover.hovered && activeModCard.index < activeModRepeater.count - 1
                                                iconText: "󰅀"
                                                onClicked: self.reorderModule(activeModCard.modelData.id, activeModCard.index + 1)
                                            }

                                            MiniIconButton {
                                                visible: (self.curModules || []).length > 1
                                                iconText: "󰅖"
                                                dangerHover: true
                                                onClicked: self.removeModule(activeModCard.modelData.id)
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.rightMargin: modBtnRow.width + 10
                                        preventStealing: true
                                        cursorShape: self.dragModId !== "" ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                        property real pressX: 0
                                        property real pressY: 0
                                        property bool dragging: false

                                        onPressed: (mouse) => {
                                            pressX = mouse.x;
                                            pressY = mouse.y;
                                            dragging = false;
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (!pressed) return;
                                            const pt = mapToItem(self, mouse.x, mouse.y);
                                            if (!dragging && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
                                                dragging = true;
                                                self.dragModId = activeModCard.modelData.id;
                                                self.dragModLabel = activeModCard.modelData.name;
                                                self.dragModFromAvail = false;
                                            }
                                            if (dragging) {
                                                self.updateModDrag(pt.x, pt.y);
                                            }
                                        }
                                        onReleased: (mouse) => {
                                            if (dragging) {
                                                const pt = mapToItem(self, mouse.x, mouse.y);
                                                self.updateModDrag(pt.x, pt.y);
                                                self.finishModDrag();
                                            }
                                            dragging = false;
                                        }
                                        onCanceled: {
                                            if (dragging) self.finishModDrag();
                                            dragging = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Right Panel: Available Hub Modules (Click or drag to add; drop active module here to remove)
                Rectangle {
                    id: availModPanel
                    readonly property var availList: self.getAvailableModuleDefs()
                    readonly property bool isPoolTarget: self.dragModId !== "" && self.dragModOverAvail && !self.dragModFromAvail
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: Math.max(190, availCol.implicitHeight + 20)
                    radius: 10
                    color: isPoolTarget ? self.root.withAlpha(self.root.theme.accentRed, 0.12) : self.root.theme.bgBase
                    border.color: isPoolTarget ? self.root.theme.accentRed : self.root.theme.bgBorder
                    border.width: isPoolTarget ? 1.5 : 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    ColumnLayout {
                        id: availCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 10
                        }
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 30
                            radius: 7
                            color: self.root.theme.bgSelected

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 6

                                Text {
                                    text: "Available Modules"
                                    font.family: self.root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: self.root.theme.textSecondary
                                }

                                Rectangle {
                                    implicitWidth: avBadgeTxt.implicitWidth + 10
                                    implicitHeight: 18
                                    radius: 9
                                    color: self.root.withAlpha(self.root.theme.textMuted, 0.12)

                                    Text {
                                        id: avBadgeTxt
                                        anchors.centerIn: parent
                                        text: "(" + self.getAvailableModuleDefs().length + ")"
                                        font.family: self.root.font
                                        font.pixelSize: 10
                                        color: self.root.theme.textMuted
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: self.getAvailableModuleDefs()
                                delegate: Rectangle {
                                    id: availModCard
                                    required property var modelData
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: 8
                                    color: avHover.hovered ? self.root.theme.bgHover : self.root.theme.bgBase
                                    border.color: avHover.hovered ? self.root.theme.accentPrimary : self.root.theme.bgBorder
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    HoverHandler { id: avHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Text {
                                            text: availModCard.modelData.icon || "󰄲"
                                            font.family: self.root.font
                                            font.pixelSize: 13
                                            color: avHover.hovered ? self.root.theme.accentPrimary : self.root.theme.textMuted
                                            horizontalAlignment: Text.AlignHCenter
                                            Layout.preferredWidth: 18
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            text: availModCard.modelData.name
                                            font.family: self.root.font
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: avHover.hovered ? self.root.theme.textPrimary : self.root.theme.textSecondary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Text {
                                            visible: avHover.hovered
                                            text: "󰐕"
                                            font.family: self.root.font
                                            font.pixelSize: 12
                                            color: self.root.theme.accentPrimary
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        preventStealing: true
                                        cursorShape: self.dragModId !== "" ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                        property real pressX: 0
                                        property real pressY: 0
                                        property bool dragging: false

                                        onPressed: (mouse) => {
                                            pressX = mouse.x;
                                            pressY = mouse.y;
                                            dragging = false;
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (!pressed) return;
                                            const pt = mapToItem(self, mouse.x, mouse.y);
                                            if (!dragging && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
                                                dragging = true;
                                                self.dragModId = availModCard.modelData.id;
                                                self.dragModLabel = availModCard.modelData.name;
                                                self.dragModFromAvail = true;
                                            }
                                            if (dragging) {
                                                self.updateModDrag(pt.x, pt.y);
                                            }
                                        }
                                        onReleased: (mouse) => {
                                            if (dragging) {
                                                const pt = mapToItem(self, mouse.x, mouse.y);
                                                self.updateModDrag(pt.x, pt.y);
                                                self.finishModDrag();
                                            } else {
                                                self.addModule(availModCard.modelData.id);
                                            }
                                            dragging = false;
                                        }
                                        onCanceled: {
                                            if (dragging) self.finishModDrag();
                                            dragging = false;
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                visible: self.getAvailableModuleDefs().length === 0
                                Layout.fillWidth: true
                                implicitHeight: 70
                                radius: 8
                                color: "transparent"
                                border.color: self.root.theme.bgBorder
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "All modules active"
                                    font.family: self.root.font
                                    font.pixelSize: 11
                                    color: self.root.theme.textMuted
                                }
                            }
                        }
                    }
                }
            }

            // Quick Controls Tiles section (visible only when Quick Controls module is enabled)
            AnimatedSection {
                expanded: self.isModuleEnabled("quickControls")

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: qcInnerCol.implicitHeight + 16
                    radius: 10
                    color: self.root.theme.bgBase
                    border.color: self.root.theme.bgBorder
                    border.width: 1

                    ColumnLayout {
                        id: qcInnerCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 8
                        }
                        spacing: 8

                        PreferenceRow {
                            title: "Quick Controls Tiles"

                            AppDropdown {
                                theme: self.root.theme
                                font: self.root.font
                                Layout.preferredWidth: 380
                                implicitWidth: 380
                                menuWidth: 380
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                currentValue: self.isCustomControls ? "custom" : "sync"
                                options: [
                                    { desktop: "sync",   name: "Sync with Control Center", desc: "" },
                                    { desktop: "custom", name: "Custom Tile Selection",    desc: "" }
                                ]
                                onSelected: (val) => self.setControlsSourceMode(val)
                            }
                        }

                        AnimatedSection {
                            expanded: self.isCustomControls

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 6
                                Layout.rightMargin: 6
                                Layout.bottomMargin: 4
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Drag active tiles to reorder, or click available tiles to add"
                                        font.family: self.root.font
                                        font.pixelSize: 11
                                        color: self.root.theme.textSecondary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    ActionButton {
                                        iconText: ""
                                        label: "Sync from Control Center"
                                        btnHeight: 26
                                        onClicked: {
                                            BarConfig.updateBarProp("islandControlTiles", self.getDefaultControlCenterTileIds());
                                            self.root.showToast("Copied tiles from Control Center");
                                        }
                                    }
                                }

                                GridLayout {
                                    columns: 2
                                    columnSpacing: 12
                                    rowSpacing: 12
                                    Layout.fillWidth: true

                                    // Active Tiles
                                    Rectangle {
                                        id: activeTilePanel
                                        readonly property bool isPanelTarget: self.dragTileId !== "" && !self.dragTileOverAvail && self.dragHoverTileIndex >= 0
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        implicitHeight: Math.max(150, actTileCol.implicitHeight + 16)
                                        radius: 9
                                        color: isPanelTarget ? self.root.withAlpha(self.root.theme.accentPrimary, 0.06) : self.root.theme.bgSurface
                                        border.color: isPanelTarget ? self.root.theme.accentPrimary : self.root.theme.bgBorder
                                        border.width: isPanelTarget ? 1.5 : 1
                                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                        ColumnLayout {
                                            id: actTileCol
                                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                                            spacing: 6

                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 28
                                                radius: 6
                                                color: self.root.theme.bgSelected
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: 10
                                                    text: "Active Tiles (" + (self.curControlTiles || []).length + ")"
                                                    font.family: self.root.font
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: self.root.theme.accentPrimary
                                                }
                                            }

                                            Column {
                                                id: activeTileListCol
                                                Layout.fillWidth: true
                                                spacing: 6
                                                move: Transition { NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic } }
                                                add: Transition { NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic } }

                                                Repeater {
                                                    id: activeTileRepeater
                                                    model: ScriptModel {
                                                        values: self.getActiveControlTileDefs()
                                                        objectProp: "id"
                                                    }
                                                    delegate: Rectangle {
                                                        id: actTileCard
                                                        required property var modelData
                                                        required property int index
                                                        width: activeTileListCol.width
                                                        readonly property bool isDragged: self.dragTileId === modelData.id
                                                        readonly property bool isBeforeThis: self.dragTileId !== "" && !isDragged && self.dragHoverTileIndex === index
                                                        readonly property bool isAfterThis: self.dragTileId !== "" && !isDragged && (
                                                            (self.dragHoverTileIndex === index + 1) ||
                                                            (index === activeTileRepeater.count - 1 && self.dragHoverTileIndex >= activeTileRepeater.count)
                                                        )
                                                        readonly property bool isDropTarget: isBeforeThis || isAfterThis

                                                        height: 36
                                                        radius: 8
                                                        scale: isDragged ? 0.96 : 1.0
                                                        opacity: isDragged ? 0.35 : 1.0
                                                        color: isDropTarget
                                                            ? self.root.theme.bgSelected
                                                            : (tActHov.hovered ? self.root.theme.bgHover : self.root.theme.bgBase)
                                                        border.color: (isDropTarget || isDragged)
                                                            ? self.root.theme.accentPrimary
                                                            : (tActHov.hovered ? self.root.theme.accentPrimary : self.root.theme.bgBorder)
                                                        border.width: isDropTarget ? 1.5 : 1
                                                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                                        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                                        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                                        HoverHandler { id: tActHov }

                                                        Rectangle {
                                                            visible: actTileCard.isDropTarget
                                                            anchors.left: parent.left
                                                            anchors.right: parent.right
                                                            anchors.leftMargin: 8
                                                            anchors.rightMargin: 8
                                                            y: actTileCard.isAfterThis ? parent.height - 3 : 1
                                                            height: 2
                                                            radius: 1
                                                            color: self.root.theme.accentPrimary
                                                        }

                                                        RowLayout {
                                                            anchors.fill: parent
                                                            anchors.leftMargin: 8
                                                            anchors.rightMargin: 8
                                                            spacing: 6

                                                            Text {
                                                                text: "󰍜"
                                                                font.family: self.root.font
                                                                font.pixelSize: 11
                                                                color: tActHov.hovered ? self.root.theme.textSecondary : self.root.theme.textMuted
                                                                opacity: tActHov.hovered ? 0.85 : 0.35
                                                                Layout.preferredWidth: 12
                                                                Layout.alignment: Qt.AlignVCenter
                                                            }

                                                            Text {
                                                                text: actTileCard.modelData.icon || "󰕰"
                                                                font.family: self.root.font
                                                                font.pixelSize: 13
                                                                color: self.root.theme.accentPrimary
                                                                horizontalAlignment: Text.AlignHCenter
                                                                Layout.preferredWidth: 18
                                                                Layout.alignment: Qt.AlignVCenter
                                                            }

                                                            Text {
                                                                text: actTileCard.modelData.label
                                                                font.family: self.root.font
                                                                font.pixelSize: 11
                                                                font.bold: true
                                                                color: self.root.theme.textPrimary
                                                                elide: Text.ElideRight
                                                                Layout.fillWidth: true
                                                                Layout.alignment: Qt.AlignVCenter
                                                            }

                                                            RowLayout {
                                                                id: tileBtnRow
                                                                z: 2
                                                                spacing: 3
                                                                Layout.alignment: Qt.AlignVCenter

                                                                MiniIconButton {
                                                                    visible: tActHov.hovered && actTileCard.index > 0
                                                                    iconText: "󰅃"
                                                                    onClicked: self.reorderControlTile(actTileCard.modelData.id, actTileCard.index - 1)
                                                                }

                                                                MiniIconButton {
                                                                    visible: tActHov.hovered && actTileCard.index < activeTileRepeater.count - 1
                                                                    iconText: "󰅀"
                                                                    onClicked: self.reorderControlTile(actTileCard.modelData.id, actTileCard.index + 1)
                                                                }

                                                                MiniIconButton {
                                                                    visible: (self.curControlTiles || []).length > 1
                                                                    iconText: "󰅖"
                                                                    dangerHover: true
                                                                    onClicked: self.removeControlTile(actTileCard.modelData.id)
                                                                }
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            anchors.rightMargin: tileBtnRow.width + 10
                                                            preventStealing: true
                                                            cursorShape: self.dragTileId !== "" ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                                            property real pressX: 0
                                                            property real pressY: 0
                                                            property bool dragging: false

                                                            onPressed: (mouse) => {
                                                                pressX = mouse.x;
                                                                pressY = mouse.y;
                                                                dragging = false;
                                                            }
                                                            onPositionChanged: (mouse) => {
                                                                if (!pressed) return;
                                                                const pt = mapToItem(self, mouse.x, mouse.y);
                                                                if (!dragging && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
                                                                    dragging = true;
                                                                    self.dragTileId = actTileCard.modelData.id;
                                                                    self.dragTileLabel = actTileCard.modelData.label;
                                                                    self.dragTileFromAvail = false;
                                                                }
                                                                if (dragging) {
                                                                    self.updateTileDrag(pt.x, pt.y);
                                                                }
                                                            }
                                                            onReleased: (mouse) => {
                                                                if (dragging) {
                                                                    const pt = mapToItem(self, mouse.x, mouse.y);
                                                                    self.updateTileDrag(pt.x, pt.y);
                                                                    self.finishTileDrag();
                                                                }
                                                                dragging = false;
                                                            }
                                                            onCanceled: {
                                                                if (dragging) self.finishTileDrag();
                                                                dragging = false;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Available Tiles
                                    Rectangle {
                                        id: availTilePanel
                                        readonly property bool isPoolTarget: self.dragTileId !== "" && self.dragTileOverAvail && !self.dragTileFromAvail
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        implicitHeight: Math.max(150, avTileCol.implicitHeight + 16)
                                        radius: 9
                                        color: isPoolTarget ? self.root.withAlpha(self.root.theme.accentRed, 0.12) : self.root.theme.bgSurface
                                        border.color: isPoolTarget ? self.root.theme.accentRed : self.root.theme.bgBorder
                                        border.width: isPoolTarget ? 1.5 : 1
                                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                        ColumnLayout {
                                            id: avTileCol
                                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                                            spacing: 6

                                            Rectangle {
                                                Layout.fillWidth: true
                                                height: 28
                                                radius: 6
                                                color: self.root.theme.bgSelected
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: 10
                                                    text: "Available Tiles (" + self.getAvailableControlTileDefs().length + ")"
                                                    font.family: self.root.font
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: self.root.theme.textSecondary
                                                }
                                            }

                                            Repeater {
                                                model: self.getAvailableControlTileDefs()
                                                delegate: Rectangle {
                                                    id: avTileCard
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    height: 36
                                                    radius: 8
                                                    color: tAvHov.hovered ? self.root.theme.bgHover : self.root.theme.bgBase
                                                    border.color: tAvHov.hovered ? self.root.theme.accentPrimary : self.root.theme.bgBorder
                                                    border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                                    Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                                    HoverHandler { id: tAvHov }

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 8
                                                        anchors.rightMargin: 8
                                                        spacing: 6

                                                        Text {
                                                            text: avTileCard.modelData.icon || "󰕰"
                                                            font.family: self.root.font
                                                            font.pixelSize: 13
                                                            color: tAvHov.hovered ? self.root.theme.accentPrimary : self.root.theme.textMuted
                                                            horizontalAlignment: Text.AlignHCenter
                                                            Layout.preferredWidth: 18
                                                            Layout.alignment: Qt.AlignVCenter
                                                        }

                                                        Text {
                                                            text: avTileCard.modelData.label
                                                            font.family: self.root.font
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            color: tAvHov.hovered ? self.root.theme.textPrimary : self.root.theme.textSecondary
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                            Layout.alignment: Qt.AlignVCenter
                                                        }

                                                        Text {
                                                            visible: tAvHov.hovered
                                                            text: "󰐕"
                                                            font.family: self.root.font
                                                            font.pixelSize: 12
                                                            color: self.root.theme.accentPrimary
                                                            Layout.alignment: Qt.AlignVCenter
                                                        }
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        preventStealing: true
                                                        cursorShape: self.dragTileId !== "" ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                                        property real pressX: 0
                                                        property real pressY: 0
                                                        property bool dragging: false

                                                        onPressed: (mouse) => {
                                                            pressX = mouse.x;
                                                            pressY = mouse.y;
                                                            dragging = false;
                                                        }
                                                        onPositionChanged: (mouse) => {
                                                            if (!pressed) return;
                                                            const pt = mapToItem(self, mouse.x, mouse.y);
                                                            if (!dragging && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
                                                                dragging = true;
                                                                self.dragTileId = avTileCard.modelData.id;
                                                                self.dragTileLabel = avTileCard.modelData.label;
                                                                self.dragTileFromAvail = true;
                                                            }
                                                            if (dragging) {
                                                                self.updateTileDrag(pt.x, pt.y);
                                                            }
                                                        }
                                                        onReleased: (mouse) => {
                                                            if (dragging) {
                                                                const pt = mapToItem(self, mouse.x, mouse.y);
                                                                self.updateTileDrag(pt.x, pt.y);
                                                                self.finishTileDrag();
                                                            } else {
                                                                self.addControlTile(avTileCard.modelData.id);
                                                            }
                                                            dragging = false;
                                                        }
                                                        onCanceled: {
                                                            if (dragging) self.finishTileDrag();
                                                            dragging = false;
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                visible: self.getAvailableControlTileDefs().length === 0
                                                Layout.fillWidth: true
                                                implicitHeight: 60
                                                radius: 8
                                                color: "transparent"
                                                border.color: self.root.theme.bgBorder
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "All tiles active"
                                                    font.family: self.root.font
                                                    font.pixelSize: 11
                                                    color: self.root.theme.textMuted
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

            // App Shortcuts section (Pinned Apps strip on top + AppGrid-style picker below)
            AnimatedSection {
                expanded: self.isModuleEnabled("appShortcuts")

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // 1. Pinned Apps Strip (top)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: pinnedAppsCol.implicitHeight + 20
                        radius: 10
                        color: self.root.theme.bgBase
                        border.color: self.root.theme.bgBorder
                        border.width: 1

                        ColumnLayout {
                            id: pinnedAppsCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 10
                            }
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Pinned Apps"
                                    font.family: self.root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: self.root.theme.accentPrimary
                                }

                                Rectangle {
                                    implicitWidth: pinBadgeTxt.implicitWidth + 10
                                    implicitHeight: 18
                                    radius: 9
                                    color: self.root.withAlpha(self.root.theme.textMuted, 0.12)

                                    Text {
                                        id: pinBadgeTxt
                                        anchors.centerIn: parent
                                        text: "(" + (self.curAppShortcuts || []).length + ")"
                                        font.family: self.root.font
                                        font.pixelSize: 10
                                        color: self.root.theme.textMuted
                                    }
                                }

                                Item { Layout.fillWidth: true }

                            }

                            Flow {
                                id: pinnedAppsFlow
                                visible: (self.curAppShortcuts || []).length > 0
                                Layout.fillWidth: true
                                spacing: 8
                                move: Transition { NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic } }
                                add: Transition { NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic } }

                                Repeater {
                                    id: activeAppRepeater
                                    model: ScriptModel {
                                        values: self.getPinnedAppEntries()
                                        objectProp: "id"
                                    }
                                    delegate: Rectangle {
                                        id: actAppCard
                                        required property var modelData
                                        required property int index
                                        readonly property bool hasIcon: (modelData.icon ?? "") !== "" && Quickshell.iconPath(modelData.icon ?? "", true) !== ""

                                        width: 94
                                        height: 76
                                        radius: 10
                                        color: aActHov.hovered ? self.root.theme.bgHover : self.root.theme.bgSurface
                                        border.color: aActHov.hovered ? self.root.theme.accentPrimary : self.root.theme.bgBorder
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                        HoverHandler { id: aActHov }

                                        // Order badge (#1, #2, ...)
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.margins: 5
                                            implicitWidth: pinIdxTxt.implicitWidth + 8
                                            height: 14
                                            radius: 4
                                            color: self.root.theme.accentPrimary

                                            Text {
                                                id: pinIdxTxt
                                                anchors.centerIn: parent
                                                text: "#" + (actAppCard.index + 1)
                                                font.family: self.root.font
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: self.root.theme.bgBase
                                            }
                                        }

                                        // Unpin button (top-right)
                                        MiniIconButton {
                                            z: 3
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: 4
                                            iconText: "󰅖"
                                            dangerHover: true
                                            onClicked: self.removeAppShortcut(actAppCard.modelData.id)
                                        }

                                        // Left/Right reorder arrows on hover (bottom corners)
                                        MiniIconButton {
                                            z: 3
                                            visible: aActHov.hovered && actAppCard.index > 0
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.margins: 3
                                            iconText: "󰅁"
                                            onClicked: self.reorderAppShortcut(actAppCard.modelData.id, actAppCard.index - 1)
                                        }

                                        MiniIconButton {
                                            z: 3
                                            visible: aActHov.hovered && actAppCard.index < activeAppRepeater.count - 1
                                            anchors.bottom: parent.bottom
                                            anchors.right: parent.right
                                            anchors.margins: 3
                                            iconText: "󰅂"
                                            onClicked: self.reorderAppShortcut(actAppCard.modelData.id, actAppCard.index + 1)
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            width: parent.width - 12
                                            spacing: 5

                                            Item {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: 30
                                                height: 30

                                                IconImage {
                                                    anchors.centerIn: parent
                                                    implicitSize: 30
                                                    source: actAppCard.hasIcon ? Quickshell.iconPath(actAppCard.modelData.icon ?? "", true) : ""
                                                    visible: actAppCard.hasIcon
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰀻"
                                                    color: self.root.theme.accentPrimary
                                                    font.pixelSize: 20
                                                    font.family: self.root.font
                                                    visible: !actAppCard.hasIcon
                                                }
                                            }

                                            Text {
                                                width: parent.width
                                                text: actAppCard.modelData.name
                                                font.family: self.root.font
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: self.root.theme.textPrimary
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                visible: (self.curAppShortcuts || []).length === 0
                                Layout.fillWidth: true
                                implicitHeight: 68
                                radius: 8
                                color: "transparent"
                                border.color: self.root.theme.bgBorder
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "No pinned apps yet — click an app below to pin it"
                                    font.family: self.root.font
                                    font.pixelSize: 11
                                    color: self.root.theme.textMuted
                                }
                            }
                        }
                    }

                    // 2. Installed Applications Grid (matching ControlCenterQuickLaunchCard)
                    Rectangle {
                        id: availAppPanel
                        readonly property var filteredApps: self.getFilteredDesktopApps()
                        Layout.fillWidth: true
                        implicitHeight: appPickerCol.implicitHeight + 24
                        radius: 10
                        color: self.root.theme.bgBase
                        border.color: self.root.theme.bgBorder
                        border.width: 1

                        ColumnLayout {
                            id: appPickerCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 12
                            }
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Installed Applications"
                                    font.family: self.root.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: self.root.theme.accentPrimary
                                }

                                Text {
                                    text: "(" + availAppPanel.filteredApps.length + " installed)"
                                    font.family: self.root.font
                                    font.pixelSize: 11
                                    color: self.root.theme.textMuted
                                }

                                Item { Layout.fillWidth: true }
                            }

                            // Full-width Search Bar
                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: 8
                                color: self.root.theme.bgSurface
                                border.color: appSearchInput.activeFocus ? self.root.theme.accentPrimary : self.root.theme.bgBorder
                                border.width: 1
                                Behavior on border.color { ColorAnimation { duration: 140 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: "󰍉"
                                        color: appSearchInput.activeFocus ? self.root.theme.accentPrimary : self.root.theme.textMuted
                                        font.pixelSize: 13
                                        font.family: self.root.font
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        implicitHeight: appSearchInput.implicitHeight

                                        TextInput {
                                            id: appSearchInput
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: self.root.theme.textPrimary
                                            font.pixelSize: 12
                                            font.family: self.root.font
                                            clip: true
                                            selectByMouse: true
                                            onTextChanged: self.appSearchQuery = text
                                        }

                                        Text {
                                            text: "Search applications to pin..."
                                            color: self.root.theme.textMuted
                                            font.pixelSize: 12
                                            font.family: self.root.font
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: appSearchInput.text === ""
                                        }
                                    }

                                    MiniIconButton {
                                        visible: appSearchInput.text !== ""
                                        iconText: "󰅖"
                                        onClicked: appSearchInput.text = ""
                                    }
                                }
                            }

                            // 5-column GridView of Installed Desktop Applications
                            GridView {
                                id: islandAppGrid
                                Layout.fillWidth: true
                                Layout.preferredHeight: 240
                                cellWidth: Math.max(100, Math.floor(width / 5))
                                cellHeight: 78
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                model: availAppPanel.filteredApps

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    contentItem: Rectangle {
                                        implicitWidth: 4
                                        radius: 2
                                        color: self.root.theme.bgBorder
                                    }
                                }

                                delegate: Item {
                                    id: appGridCell
                                    required property var modelData
                                    required property int index
                                    width: islandAppGrid.cellWidth
                                    height: islandAppGrid.cellHeight

                                    readonly property bool hasIcon: (appGridCell.modelData.icon ?? "") !== "" && Quickshell.iconPath(appGridCell.modelData.icon ?? "", true) !== ""
                                    readonly property int pinnedSlot: self.findPinnedIndex(appGridCell.modelData)

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 3
                                        radius: 10
                                        color: appGridCell.pinnedSlot >= 0
                                            ? self.root.withAlpha(self.root.theme.accentPrimary, 0.1)
                                            : (cellHoverArea.containsMouse ? self.root.theme.bgHover : self.root.theme.bgSurface)
                                        border.color: cellHoverArea.containsMouse || appGridCell.pinnedSlot >= 0
                                            ? self.root.theme.accentPrimary
                                            : self.root.theme.bgBorder
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        // Pinned Slot Badge
                                        Rectangle {
                                            visible: appGridCell.pinnedSlot >= 0
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: 4
                                            implicitWidth: pinnedBadgeTxt.implicitWidth + 8
                                            height: 14
                                            radius: 4
                                            color: self.root.theme.accentPrimary

                                            Text {
                                                id: pinnedBadgeTxt
                                                anchors.centerIn: parent
                                                text: "#" + (appGridCell.pinnedSlot + 1)
                                                font.family: self.root.font
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: self.root.theme.bgBase
                                            }
                                        }

                                        Column {
                                            anchors.centerIn: parent
                                            width: parent.width - 10
                                            spacing: 5

                                            Item {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: 30
                                                height: 30

                                                IconImage {
                                                    anchors.centerIn: parent
                                                    implicitSize: 30
                                                    source: appGridCell.hasIcon ? Quickshell.iconPath(appGridCell.modelData.icon ?? "", true) : ""
                                                    visible: appGridCell.hasIcon
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰀻"
                                                    color: self.root.theme.accentPrimary
                                                    font.pixelSize: 20
                                                    font.family: self.root.font
                                                    visible: !appGridCell.hasIcon
                                                }
                                            }

                                            Text {
                                                width: parent.width
                                                text: appGridCell.modelData.name ?? ""
                                                color: (cellHoverArea.containsMouse || appGridCell.pinnedSlot >= 0) ? self.root.theme.textPrimary : self.root.theme.textSecondary
                                                font.pixelSize: 10
                                                font.family: self.root.font
                                                font.bold: cellHoverArea.containsMouse || appGridCell.pinnedSlot >= 0
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                            }
                                        }

                                        MouseArea {
                                            id: cellHoverArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const eid = String(appGridCell.modelData.id || appGridCell.modelData.name || "");
                                                if (!eid) return;
                                                if (appGridCell.pinnedSlot >= 0) {
                                                    self.removeAppShortcut(eid);
                                                } else {
                                                    self.addAppShortcut(eid);
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
