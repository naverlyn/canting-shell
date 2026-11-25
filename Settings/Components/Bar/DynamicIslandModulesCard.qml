import QtQuick
import QtQuick.Layouts
import "../../../bar"
import "../Common"

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
    readonly property var curAppShortcuts: {
        void BarConfig.panelsRevision;
        return (curBar && Array.isArray(curBar.islandAppShortcuts))
            ? curBar.islandAppShortcuts
            : (BarConfig.islandAppShortcuts || []);
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

    readonly property var activeModuleDefs: {
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

    readonly property var availableModuleDefs: {
        const enabled = self.curModules || [];
        const all = BarConfig.islandModuleDefinitions || [];
        const out = [];
        for (let k = 0; k < all.length; k++) {
            if (enabled.indexOf(all[k].id) === -1) out.push(all[k]);
        }
        return out;
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
        Layout.fillWidth: true
        implicitHeight: innerCol.implicitHeight + 24
        radius: 12
        color: Style.theme.bgSurface
        border.color: Style.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: innerCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 12

            DualListDragEditor {
                rootRef: self.root
                activeItems: self.activeModuleDefs
                availableItems: self.availableModuleDefs
                idKey: "id"
                labelKey: "name"
                iconKey: "icon"
                fallbackIcon: "󰄲"
                minActiveCount: 1
                activeTitle: "Active Modules"
                availableTitle: "Available Modules"
                emptyAvailableText: "All modules active"
                minPanelHeight: 190
                cardHeight: 38
                panelSurfaceColor: self.root.theme.bgBase
                onAddRequested: (id) => self.addModule(id)
                onRemoveRequested: (id) => self.removeModule(id)
                onReorderRequested: (id, idx) => self.reorderModule(id, idx)
            }

            AnimatedSection {
                expanded: self.isModuleEnabled("quickControls")

                Loader {
                    id: qcLoader
                    Layout.fillWidth: true
                    active: self.isModuleEnabled("quickControls")
                    visible: active
                    sourceComponent: IslandQuickControlsSection {
                        rootRef: self.root
                        curControlTiles: self.curControlTiles
                    }
                }
            }

            AnimatedSection {
                expanded: self.isModuleEnabled("appShortcuts")

                Loader {
                    id: appShortcutsLoader
                    Layout.fillWidth: true
                    active: self.isModuleEnabled("appShortcuts")
                    visible: active
                    sourceComponent: IslandAppShortcutsSection {
                        rootRef: self.root
                        curAppShortcuts: self.curAppShortcuts
                    }
                }
            }
        }
    }
}
