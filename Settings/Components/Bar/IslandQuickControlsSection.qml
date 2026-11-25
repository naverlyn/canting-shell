import QtQuick
import QtQuick.Layouts
import "../../../bar"
import "../../../ControlCenter"
import "../Common"
import ".."

Rectangle {
    id: qcCard

    required property var rootRef
    required property var curControlTiles
    readonly property bool isCustomControls: curControlTiles && curControlTiles.length > 0

    Layout.fillWidth: true
    implicitHeight: qcInnerCol.implicitHeight + 16
    radius: 10
    color: rootRef.theme.bgBase
    border.color: rootRef.theme.bgBorder
    border.width: 1

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
        } else if (!qcCard.isCustomControls) {
            BarConfig.updateBarProp("islandControlTiles", qcCard.getDefaultControlCenterTileIds());
        }
    }

    function addControlTile(tid) {
        let list = (qcCard.curControlTiles || []).slice();
        if (list.indexOf(tid) !== -1) return;
        list.push(tid);
        BarConfig.updateBarProp("islandControlTiles", list);
    }

    function removeControlTile(tid) {
        let list = (qcCard.curControlTiles || []).slice();
        const idx = list.indexOf(tid);
        if (idx === -1) return;
        if (list.length <= 1) {
            qcCard.rootRef.showToast("Keep at least one quick control tile enabled", true);
            return;
        }
        list.splice(idx, 1);
        BarConfig.updateBarProp("islandControlTiles", list);
    }

    function reorderControlTile(tid, targetIdx) {
        let list = (qcCard.curControlTiles || []).slice();
        const fromIdx = list.indexOf(tid);
        if (fromIdx === -1) return;
        const clamped = Math.max(0, Math.min(list.length - 1, targetIdx));
        if (clamped === fromIdx) return;
        list.splice(fromIdx, 1);
        list.splice(clamped, 0, tid);
        BarConfig.updateBarProp("islandControlTiles", list);
    }

    readonly property var activeTileDefs: {
        const enabled = qcCard.curControlTiles || [];
        const all = ControlCenterConfig.allTileDefs || [];
        const out = [];
        for (let i = 0; i < enabled.length; i++) {
            for (let j = 0; j < all.length; j++) {
                if (all[j].id === enabled[i]) { out.push(all[j]); break; }
            }
        }
        return out;
    }

    readonly property var availableTileDefs: {
        const enabled = qcCard.curControlTiles || [];
        const all = ControlCenterConfig.allTileDefs || [];
        const out = [];
        for (let k = 0; k < all.length; k++) {
            if (enabled.indexOf(all[k].id) === -1) out.push(all[k]);
        }
        return out;
    }

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
                theme: qcCard.rootRef.theme
                font: qcCard.rootRef.font
                Layout.preferredWidth: 380
                implicitWidth: 380
                menuWidth: 380
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                currentValue: qcCard.isCustomControls ? "custom" : "sync"
                options: [
                    { desktop: "sync",   name: "Sync with Control Center", desc: "" },
                    { desktop: "custom", name: "Custom Tile Selection",    desc: "" }
                ]
                onSelected: (val) => qcCard.setControlsSourceMode(val)
            }
        }

        AnimatedSection {
            expanded: qcCard.isCustomControls

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
                        font.family: qcCard.rootRef.font
                        font.pixelSize: 11
                        color: qcCard.rootRef.theme.textSecondary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    ActionButton {
                        iconText: ""
                        label: "Sync from Control Center"
                        btnHeight: 26
                        onClicked: {
                            BarConfig.updateBarProp("islandControlTiles", qcCard.getDefaultControlCenterTileIds());
                            qcCard.rootRef.showToast("Copied tiles from Control Center");
                        }
                    }
                }

                DualListDragEditor {
                    rootRef: qcCard.rootRef
                    activeItems: qcCard.activeTileDefs
                    availableItems: qcCard.availableTileDefs
                    idKey: "id"
                    labelKey: "label"
                    iconKey: "icon"
                    fallbackIcon: "󰕰"
                    minActiveCount: 1
                    activeTitle: "Active Tiles"
                    availableTitle: "Available Tiles"
                    emptyAvailableText: "All tiles active"
                    minPanelHeight: 150
                    cardHeight: 36
                    panelSurfaceColor: qcCard.rootRef.theme.bgSurface
                    onAddRequested: (id) => qcCard.addControlTile(id)
                    onRemoveRequested: (id) => qcCard.removeControlTile(id)
                    onReorderRequested: (id, idx) => qcCard.reorderControlTile(id, idx)
                }
            }
        }
    }
}
