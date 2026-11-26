import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "../../../bar"
import "../Common"

ColumnLayout {
    id: shortcutsSec

    required property var rootRef
    required property var curAppShortcuts

    Layout.fillWidth: true
    spacing: 10

    property string appSearchQuery: ""

    // Cached sorted desktop entries + O(1) lookup map (avoids O(P * N log N) re-sorts)
    readonly property var sortedDesktopEntries: {
        const list = (DesktopEntries && DesktopEntries.applications && DesktopEntries.applications.values)
            ? [...DesktopEntries.applications.values]
            : [];
        return list.filter(e => e && e.name && !e.noDisplay).sort((a, b) => (a.name || "").localeCompare(b.name || ""));
    }

    readonly property var desktopEntryByKey: {
        const map = {};
        const all = shortcutsSec.sortedDesktopEntries;
        for (let i = 0; i < all.length; i++) {
            const e = all[i];
            if (e.id) map[String(e.id).toLowerCase()] = e;
            if (e.name) map[String(e.name).toLowerCase()] = e;
        }
        return map;
    }

    function findDesktopEntry(appId) {
        const target = String(appId || "").trim().toLowerCase();
        if (!target) return null;
        return shortcutsSec.desktopEntryByKey[target] || DesktopEntries.heuristicLookup(appId) || null;
    }

    readonly property var pinnedAppEntries: {
        const ids = shortcutsSec.curAppShortcuts || [];
        const out = [];
        for (let i = 0; i < ids.length; i++) {
            const e = shortcutsSec.findDesktopEntry(ids[i]);
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

    readonly property var pinnedKeyIndexMap: {
        const map = {};
        const list = shortcutsSec.curAppShortcuts || [];
        for (let i = 0; i < list.length; i++) {
            const cur = String(list[i] || "").toLowerCase();
            if (cur && map[cur] === undefined) map[cur] = i;
        }
        return map;
    }

    function findPinnedIndex(entry) {
        if (!entry) return -1;
        const map = shortcutsSec.pinnedKeyIndexMap;
        const eid = String(entry.id || entry.name || "").toLowerCase();
        if (eid && map[eid] !== undefined) return map[eid];
        const ename = String(entry.name || "").toLowerCase();
        if (ename && map[ename] !== undefined) return map[ename];
        return -1;
    }

    readonly property var filteredDesktopApps: {
        const q = shortcutsSec.appSearchQuery.trim().toLowerCase();
        const all = shortcutsSec.sortedDesktopEntries;
        return all.filter(e => {
            if (shortcutsSec.findPinnedIndex(e) !== -1) return false;
            if (q === "") return true;
            const eid = String(e.id || "").toLowerCase();
            return (e.name && e.name.toLowerCase().includes(q)) ||
                   (e.genericName && e.genericName.toLowerCase().includes(q)) ||
                   eid.includes(q);
        });
    }

    function addAppShortcut(appId) {
        let list = (shortcutsSec.curAppShortcuts || []).slice();
        if (list.indexOf(appId) !== -1) return;
        list.push(appId);
        BarConfig.updateBarProp("islandAppShortcuts", list);
    }

    function removeAppShortcut(appId) {
        let list = (shortcutsSec.curAppShortcuts || []).slice();
        const lower = String(appId || "").toLowerCase();
        const idx = list.findIndex(x => String(x || "").toLowerCase() === lower);
        if (idx === -1) return;
        list.splice(idx, 1);
        BarConfig.updateBarProp("islandAppShortcuts", list);
    }

    function reorderAppShortcut(appId, targetIdx) {
        let list = (shortcutsSec.curAppShortcuts || []).slice();
        const lower = String(appId || "").toLowerCase();
        const fromIdx = list.findIndex(x => String(x || "").toLowerCase() === lower);
        if (fromIdx === -1) return;
        const clamped = Math.max(0, Math.min(list.length - 1, targetIdx));
        if (clamped === fromIdx) return;
        const item = list.splice(fromIdx, 1)[0];
        list.splice(clamped, 0, item);
        BarConfig.updateBarProp("islandAppShortcuts", list);
    }

    // 1. Pinned Apps Strip
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: pinnedAppsCol.implicitHeight + 20
        radius: 10
        color: shortcutsSec.rootRef.theme.bgBase
        border.color: shortcutsSec.rootRef.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: pinnedAppsCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Pinned Apps"
                    font.family: shortcutsSec.rootRef.font
                    font.pixelSize: Style.px(11)
                    font.bold: true
                    color: shortcutsSec.rootRef.theme.accentPrimary
                }

                Rectangle {
                    implicitWidth: pinBadgeTxt.implicitWidth + 10
                    implicitHeight: 18
                    radius: 9
                    color: shortcutsSec.rootRef.withAlpha(shortcutsSec.rootRef.theme.textMuted, 0.12)

                    Text {
                        id: pinBadgeTxt
                        anchors.centerIn: parent
                        text: "(" + (shortcutsSec.curAppShortcuts || []).length + ")"
                        font.family: shortcutsSec.rootRef.font
                        font.pixelSize: Style.px(10)
                        color: shortcutsSec.rootRef.theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Flow {
                visible: (shortcutsSec.curAppShortcuts || []).length > 0
                Layout.fillWidth: true
                spacing: 8
                move: Transition { NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic } }
                add: Transition { NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic } }

                Repeater {
                    id: activeAppRepeater
                    model: ScriptModel {
                        values: shortcutsSec.pinnedAppEntries
                        objectProp: "id"
                    }
                    delegate: Rectangle {
                        id: actAppCard
                        required property var modelData
                        required property int index
                        readonly property string resolvedIcon: (modelData.icon ?? "") !== "" ? Quickshell.iconPath(modelData.icon, true) : ""
                        readonly property bool hasIcon: resolvedIcon !== ""

                        width: 94
                        height: 76
                        radius: 10
                        color: aActHov.hovered ? shortcutsSec.rootRef.theme.bgHover : shortcutsSec.rootRef.theme.bgSurface
                        border.color: aActHov.hovered ? shortcutsSec.rootRef.theme.accentPrimary : shortcutsSec.rootRef.theme.bgBorder
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        HoverHandler { id: aActHov }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 5
                            implicitWidth: pinIdxTxt.implicitWidth + 8
                            height: 14
                            radius: 4
                            color: shortcutsSec.rootRef.theme.accentPrimary

                            Text {
                                id: pinIdxTxt
                                anchors.centerIn: parent
                                text: "#" + (actAppCard.index + 1)
                                font.family: shortcutsSec.rootRef.font
                                font.pixelSize: 8
                                font.bold: true
                                color: shortcutsSec.rootRef.theme.bgBase
                            }
                        }

                        MiniIconButton {
                            z: 3
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 4
                            iconText: "󰅖"
                            dangerHover: true
                            onClicked: shortcutsSec.removeAppShortcut(actAppCard.modelData.id)
                        }

                        MiniIconButton {
                            z: 3
                            visible: aActHov.hovered && actAppCard.index > 0
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.margins: 3
                            iconText: "󰅁"
                            onClicked: shortcutsSec.reorderAppShortcut(actAppCard.modelData.id, actAppCard.index - 1)
                        }

                        MiniIconButton {
                            z: 3
                            visible: aActHov.hovered && actAppCard.index < activeAppRepeater.count - 1
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: 3
                            iconText: "󰅂"
                            onClicked: shortcutsSec.reorderAppShortcut(actAppCard.modelData.id, actAppCard.index + 1)
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
                                    asynchronous: true
                                    source: actAppCard.resolvedIcon
                                    visible: actAppCard.hasIcon
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰀻"
                                    color: shortcutsSec.rootRef.theme.accentPrimary
                                    font.pixelSize: Style.px(20)
                                    font.family: shortcutsSec.rootRef.font
                                    visible: !actAppCard.hasIcon
                                }
                            }

                            Text {
                                width: parent.width
                                text: actAppCard.modelData.name
                                font.family: shortcutsSec.rootRef.font
                                font.pixelSize: Style.px(10)
                                font.bold: true
                                color: shortcutsSec.rootRef.theme.textPrimary
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: (shortcutsSec.curAppShortcuts || []).length === 0
                Layout.fillWidth: true
                implicitHeight: 68
                radius: 8
                color: "transparent"
                border.color: shortcutsSec.rootRef.theme.bgBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "No pinned apps yet — click an app below to pin it"
                    font.family: shortcutsSec.rootRef.font
                    font.pixelSize: Style.px(11)
                    color: shortcutsSec.rootRef.theme.textMuted
                }
            }
        }
    }

    // 2. Installed Applications Grid
    Rectangle {
        id: availAppPanel
        Layout.fillWidth: true
        implicitHeight: appPickerCol.implicitHeight + 24
        radius: 10
        color: shortcutsSec.rootRef.theme.bgBase
        border.color: shortcutsSec.rootRef.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: appPickerCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Installed Applications"
                    font.family: shortcutsSec.rootRef.font
                    font.pixelSize: Style.px(11)
                    font.bold: true
                    color: shortcutsSec.rootRef.theme.accentPrimary
                }

                Text {
                    text: "(" + shortcutsSec.filteredDesktopApps.length + " installed)"
                    font.family: shortcutsSec.rootRef.font
                    font.pixelSize: Style.px(11)
                    color: shortcutsSec.rootRef.theme.textMuted
                }

                Item { Layout.fillWidth: true }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: shortcutsSec.rootRef.theme.bgSurface
                border.color: appSearchInput.activeFocus ? shortcutsSec.rootRef.theme.accentPrimary : shortcutsSec.rootRef.theme.bgBorder
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "󰍉"
                        color: appSearchInput.activeFocus ? shortcutsSec.rootRef.theme.accentPrimary : shortcutsSec.rootRef.theme.textMuted
                        font.pixelSize: Style.px(13)
                        font.family: shortcutsSec.rootRef.font
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
                            color: shortcutsSec.rootRef.theme.textPrimary
                            font.pixelSize: Style.px(12)
                            font.family: shortcutsSec.rootRef.font
                            clip: true
                            selectByMouse: true
                            onTextChanged: shortcutsSec.appSearchQuery = text
                        }

                        Text {
                            text: "Search applications to pin..."
                            color: shortcutsSec.rootRef.theme.textMuted
                            font.pixelSize: Style.px(12)
                            font.family: shortcutsSec.rootRef.font
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

            GridView {
                id: islandAppGrid
                Layout.fillWidth: true
                Layout.preferredHeight: 240
                cellWidth: Math.max(100, Math.floor(width / 5))
                cellHeight: 78
                clip: true
                cacheBuffer: 0
                boundsBehavior: Flickable.StopAtBounds
                model: shortcutsSec.filteredDesktopApps

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: shortcutsSec.rootRef.theme.bgBorder
                    }
                }

                delegate: Item {
                    id: appGridCell
                    required property var modelData
                    required property int index
                    width: islandAppGrid.cellWidth
                    height: islandAppGrid.cellHeight

                    readonly property string resolvedIcon: (appGridCell.modelData.icon ?? "") !== "" ? Quickshell.iconPath(appGridCell.modelData.icon, true) : ""
                    readonly property bool hasIcon: resolvedIcon !== ""
                    readonly property int pinnedSlot: shortcutsSec.findPinnedIndex(appGridCell.modelData)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: 10
                        color: appGridCell.pinnedSlot >= 0
                            ? shortcutsSec.rootRef.withAlpha(shortcutsSec.rootRef.theme.accentPrimary, 0.1)
                            : (cellHoverArea.containsMouse ? shortcutsSec.rootRef.theme.bgHover : shortcutsSec.rootRef.theme.bgSurface)
                        border.color: cellHoverArea.containsMouse || appGridCell.pinnedSlot >= 0
                            ? shortcutsSec.rootRef.theme.accentPrimary
                            : shortcutsSec.rootRef.theme.bgBorder
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            visible: appGridCell.pinnedSlot >= 0
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 4
                            implicitWidth: pinnedBadgeTxt.implicitWidth + 8
                            height: 14
                            radius: 4
                            color: shortcutsSec.rootRef.theme.accentPrimary

                            Text {
                                id: pinnedBadgeTxt
                                anchors.centerIn: parent
                                text: "#" + (appGridCell.pinnedSlot + 1)
                                font.family: shortcutsSec.rootRef.font
                                font.pixelSize: 8
                                font.bold: true
                                color: shortcutsSec.rootRef.theme.bgBase
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
                                    asynchronous: true
                                    source: appGridCell.resolvedIcon
                                    visible: appGridCell.hasIcon
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰀻"
                                    color: shortcutsSec.rootRef.theme.accentPrimary
                                    font.pixelSize: Style.px(20)
                                    font.family: shortcutsSec.rootRef.font
                                    visible: !appGridCell.hasIcon
                                }
                            }

                            Text {
                                width: parent.width
                                text: appGridCell.modelData.name ?? ""
                                color: (cellHoverArea.containsMouse || appGridCell.pinnedSlot >= 0) ? shortcutsSec.rootRef.theme.textPrimary : shortcutsSec.rootRef.theme.textSecondary
                                font.pixelSize: Style.px(10)
                                font.family: shortcutsSec.rootRef.font
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
                                    shortcutsSec.removeAppShortcut(eid);
                                } else {
                                    shortcutsSec.addAppShortcut(eid);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
