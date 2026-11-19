import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../../../bar"
import "../../../ControlCenter"
import "../.."
import "../Common"
import ".."
import "../../../utils/AppFrecencyUtils.js" as AppFrecencyUtils


    ColumnLayout {
    id: quickLaunchCard
    required property var root
    property int selectedSlotIndex: 0
    property var appUsage: ({})
    function getAppKey(entry) {
        return AppFrecencyUtils.getAppKey(entry);
    }
    function getFrecencyScore(entry, usageMap) {
        return AppFrecencyUtils.getFrecencyScore(entry, usageMap);
    }
    function findDesktopEntry(appItem) {
        if (!appItem) return null;
        const all = [...DesktopEntries.applications.values];
        const targetId = (appItem.desktopId || appItem.id || "").toLowerCase();
        const targetLabel = (appItem.label || "").toLowerCase();
        if (targetId) {
            for (let i = 0; i < all.length; i++) {
                const e = all[i];
                if ((e.id && e.id.toLowerCase() === targetId) || (e.name && e.name.toLowerCase() === targetId)) {
                    return e;
                }
            }
        }
        if (targetLabel) {
            for (let i = 0; i < all.length; i++) {
                const e = all[i];
                if (e.name && e.name.toLowerCase() === targetLabel) {
                    return e;
                }
            }
        }
        return null;
    }
    function isSystemIcon(iconStr) {
        if (!iconStr || iconStr.length <= 2) return false;
        return Quickshell.iconPath(iconStr, true) !== "";
    }
    function findAssignedSlotForEntry(entry) {
        if (!entry) return -1;
        const eKey = quickLaunchCard.getAppKey(entry).toLowerCase();
        const eName = (entry.name || "").toLowerCase();
        const list = quickLaunchCard.displayedQuickApps || [];
        for (let i = 0; i < list.length; i++) {
            const item = list[i];
            const dId = (item.desktopId || item.id || "").toLowerCase();
            const dLbl = (item.label || "").toLowerCase();
            if ((eKey && dId === eKey) || (eName && dLbl === eName)) return i;
        }
        return -1;
    }
    readonly property var sortedDesktopApps: {
        const usage = quickLaunchCard.appUsage;
        const all = [...DesktopEntries.applications.values];
        return all.sort((a, b) => {
            const sa = quickLaunchCard.getFrecencyScore(a, usage);
            const sb = quickLaunchCard.getFrecencyScore(b, usage);
            if (sa !== sb) return sb - sa;
            return (a.name || "").localeCompare(b.name || "");
        });
    }
    readonly property var filteredDesktopApps: {
        const all = quickLaunchCard.sortedDesktopApps;
        const q = settingsAppSearch.text.trim().toLowerCase();
        if (q === "") return all;
        const usage = quickLaunchCard.appUsage;
        return all.filter(d =>
            (d.name && d.name.toLowerCase().includes(q)) ||
            (d.genericName && d.genericName.toLowerCase().includes(q)) ||
            (d.keywords && d.keywords.some(k => k.toLowerCase().includes(q))) ||
            (d.categories && d.categories.some(c => c.toLowerCase().includes(q)))
        ).sort((a, b) => {
            const an = (a.name || "").toLowerCase();
            const bn = (b.name || "").toLowerCase();
            const as = an.startsWith(q);
            const bs = bn.startsWith(q);
            if (as && !bs) return -1;
            if (!as && bs) return 1;
            const sa = quickLaunchCard.getFrecencyScore(a, usage);
            const sb = quickLaunchCard.getFrecencyScore(b, usage);
            if (sa !== sb) return sb - sa;
            return an.localeCompare(bn);
        });
    }
    readonly property var displayedQuickApps: {
        const targetCount = Math.max(3, Math.min(15, ControlCenterConfig.quickAppsMaxCount));
        const configured = ControlCenterConfig.quickApps || [];
        let result = [];
        let usedKeys = ({});

        for (let i = 0; i < configured.length && result.length < targetCount; i++) {
            const item = configured[i];
            if (!item) continue;
            const entry = quickLaunchCard.findDesktopEntry(item);
            const key = (item.desktopId || item.id || item.label || "").toLowerCase();
            if (key) usedKeys[key] = true;
            if (entry) {
                const eKey = quickLaunchCard.getAppKey(entry).toLowerCase();
                if (eKey) usedKeys[eKey] = true;
            }
            result.push({
                slotIndex: result.length,
                id: item.id || ("slot_" + i),
                desktopId: item.desktopId || (entry ? quickLaunchCard.getAppKey(entry) : ""),
                label: item.label || (entry ? entry.name : "App"),
                icon: (entry && entry.icon && quickLaunchCard.isSystemIcon(entry.icon)) ? entry.icon : (item.icon || "󰀻"),
                cmd: item.cmd || ""
            });
        }

        const desktopList = quickLaunchCard.sortedDesktopApps;
        for (let j = 0; j < desktopList.length && result.length < targetCount; j++) {
            const d = desktopList[j];
            const dKey = quickLaunchCard.getAppKey(d).toLowerCase();
            const dName = (d.name || "").toLowerCase();
            if ((dKey && usedKeys[dKey]) || (dName && usedKeys[dName])) continue;
            if (dKey) usedKeys[dKey] = true;
            if (dName) usedKeys[dName] = true;
            result.push({
                slotIndex: result.length,
                id: dKey || ("auto_" + j),
                desktopId: quickLaunchCard.getAppKey(d),
                label: d.name || "App",
                icon: d.icon || "󰀻",
                cmd: ""
            });
        }
        return result;
    }
    readonly property var balancedQuickAppRows: {
        const list = quickLaunchCard.displayedQuickApps || [];
        const n = list.length;
        if (n === 0) return [];
        let sizes = [];
        if (n <= 4) sizes = [n];
        else if (n === 5) sizes = [3, 2];
        else if (n === 6) sizes = [3, 3];
        else if (n === 7) sizes = [4, 3];
        else if (n === 8) sizes = [4, 4];
        else if (n === 9) sizes = [3, 3, 3];
        else if (n === 10) sizes = [5, 5];
        else if (n === 11) sizes = [4, 4, 3];
        else if (n === 12) sizes = [4, 4, 4];
        else if (n === 13) sizes = [5, 4, 4];
        else if (n === 14) sizes = [5, 5, 4];
        else sizes = [5, 5, 5];

        let rows = [];
        let offset = 0;
        for (let r = 0; r < sizes.length; r++) {
            const count = sizes[r];
            rows.push(list.slice(offset, offset + count));
            offset += count;
        }
        return rows;
    }
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            Text {
                text: "Quick Launch & App Grid"
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
            implicitHeight: innerCol.implicitHeight + 12 * 2
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
            Process {
                id: usageReaderProc
                command: ["sh", "-c", "cat \"$HOME/.cache/qs_app_usage.json\" 2>/dev/null || echo '{}'"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            const parsed = JSON.parse(text.trim() || "{}");
                            if (parsed && typeof parsed === "object") quickLaunchCard.appUsage = parsed;
                        } catch (e) {
                            quickLaunchCard.appUsage = ({});
                        }
                    }
                }
            }











                SettingSliderRow {
                    title: "Quick Launch App Count"
                    value: ControlCenterConfig.quickAppsMaxCount
                    minVal: 3
                    maxVal: 15
                    step: 1
                    unit: " apps"
                    presets: [
                        { label: "3 Apps", val: 3 },
                        { label: "8 Apps", val: 8 },
                        { label: "10 Apps", val: 10 },
                        { label: "15 Max", val: 15 }
                    ]
                    onValueModified: (val) => {
                        ControlCenterConfig.setQuickAppsMaxCount(val);
                        if (quickLaunchCard.selectedSlotIndex >= val) {
                            quickLaunchCard.selectedSlotIndex = Math.max(0, val - 1);
                        }
                    }
                }

                RowDivider {}

                // Live Interactive Quick Launch Preview Grid
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: previewGridCol.implicitHeight + 24
                    radius: 10
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder
                    border.width: 1

                    ColumnLayout {
                        id: previewGridCol
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
                                text: "󰀻"
                                font.family: root.font
                                font.pixelSize: 13
                                color: root.theme.accentPrimary
                            }

                            Text {
                                text: "Quick Launch Layout Preview (" + ControlCenterConfig.quickAppsMaxCount + " / 15 Apps)"
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: true
                                color: root.theme.textPrimary
                            }

                            Rectangle {
                                implicitWidth: activeSlotBadge.implicitWidth + 12
                                implicitHeight: 20
                                radius: 10
                                color: root.withAlpha(root.theme.accentPrimary, 0.14)

                                Text {
                                    id: activeSlotBadge
                                    anchors.centerIn: parent
                                    text: "Editing Slot #" + (quickLaunchCard.selectedSlotIndex + 1)
                                    font.family: root.font
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: root.theme.accentPrimary
                                }
                            }

                            Item { Layout.fillWidth: true }

                            ActionButton {
                                iconText: "󰦛"
                                label: "Reset Apps"
                                btnHeight: 28
                                onClicked: {
                                    ControlCenterConfig.resetQuickApps();
                                    quickLaunchCard.selectedSlotIndex = 0;
                                    root.showToast("Restored default Quick Launch apps");
                                }
                            }
                        }

                        // Balanced Rows Matching QuickAppsCard.qml (Zero Square Gaps)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: quickLaunchCard.balancedQuickAppRows

                                delegate: RowLayout {
                                    id: previewRow
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Repeater {
                                        model: previewRow.modelData

                                        delegate: Rectangle {
                                            id: previewTile
                                            required property var modelData
                                            required property int index

                                            readonly property int slotIdx: modelData.slotIndex
                                            readonly property bool isSel: quickLaunchCard.selectedSlotIndex === slotIdx
                                            readonly property bool hasSysIcon: quickLaunchCard.isSystemIcon(modelData.icon)

                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            Layout.preferredHeight: 62
                                            implicitHeight: 62
                                            height: 62
                                            radius: 9
                                            scale: previewTileMouse.pressed ? 0.96 : (previewTileHover.hovered ? 1.02 : 1.0)
                                            color: isSel
                                                ? root.theme.bgSelected
                                                : (previewTileHover.hovered ? root.theme.bgHover : root.theme.bgSurface)
                                            border.color: isSel
                                                ? root.theme.accentPrimary
                                                : (previewTileHover.hovered ? root.withAlpha(root.theme.accentPrimary, 0.5) : root.theme.bgBorder)
                                            border.width: isSel ? 1.5 : 1

                                            Behavior on color { ColorAnimation { duration: 130 } }
                                            Behavior on border.color { ColorAnimation { duration: 130 } }
                                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                            HoverHandler { id: previewTileHover }

                                            // Slot number badge in top-left
                                            Rectangle {
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.margins: 5
                                                implicitWidth: slotNumTxt.implicitWidth + 8
                                                height: 15
                                                radius: 4
                                                color: previewTile.isSel
                                                    ? root.theme.accentPrimary
                                                    : root.withAlpha(root.theme.textMuted, 0.16)

                                                Text {
                                                    id: slotNumTxt
                                                    anchors.centerIn: parent
                                                    text: "#" + (previewTile.slotIdx + 1)
                                                    font.family: root.font
                                                    font.pixelSize: 8
                                                    font.bold: true
                                                    color: previewTile.isSel ? root.theme.bgBase : root.theme.textSecondary
                                                }
                                            }

                                            // Reorder left/right buttons on hover
                                            Row {
                                                z: 3
                                                visible: previewTileHover.hovered
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.margins: 4
                                                spacing: 2

                                                MiniIconButton {
                                                    visible: previewTile.slotIdx > 0
                                                    iconText: "󰅁"
                                                    onClicked: {
                                                        ControlCenterConfig.moveQuickAppInFullList(previewTile.slotIdx, previewTile.slotIdx - 1, quickLaunchCard.displayedQuickApps);
                                                        quickLaunchCard.selectedSlotIndex = previewTile.slotIdx - 1;
                                                    }
                                                }

                                                MiniIconButton {
                                                    visible: previewTile.slotIdx < ControlCenterConfig.quickAppsMaxCount - 1
                                                    iconText: "󰅂"
                                                    onClicked: {
                                                        ControlCenterConfig.moveQuickAppInFullList(previewTile.slotIdx, previewTile.slotIdx + 1, quickLaunchCard.displayedQuickApps);
                                                        quickLaunchCard.selectedSlotIndex = previewTile.slotIdx + 1;
                                                    }
                                                }
                                            }

                                            Column {
                                                anchors.centerIn: parent
                                                width: parent.width - 12
                                                spacing: 4

                                                Item {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: 24
                                                    height: 24

                                                    IconImage {
                                                        anchors.centerIn: parent
                                                        implicitSize: 24
                                                        visible: previewTile.hasSysIcon
                                                        source: previewTile.hasSysIcon ? Quickshell.iconPath(previewTile.modelData.icon, true) : ""
                                                    }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        visible: !previewTile.hasSysIcon
                                                        text: previewTile.modelData.icon || "󰀻"
                                                        font.family: root.font
                                                        font.pixelSize: 17
                                                        color: previewTile.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                                    }
                                                }

                                                Text {
                                                    width: parent.width
                                                    horizontalAlignment: Text.AlignHCenter
                                                    text: previewTile.modelData.label || "App"
                                                    font.family: root.font
                                                    font.pixelSize: 10
                                                    font.bold: previewTile.isSel || previewTileHover.hovered
                                                    color: previewTile.isSel ? root.theme.textPrimary : root.theme.textSecondary
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            MouseArea {
                                                id: previewTileMouse
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: quickLaunchCard.selectedSlotIndex = previewTile.slotIdx
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // AppGrid Application Selector Box
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: settingsPickerCol.implicitHeight + 24
                    radius: 10
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder
                    border.width: 1

                    ColumnLayout {
                        id: settingsPickerCol
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
                                text: "AppGrid Applications"
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: root.theme.accentPrimary
                            }

                            Text {
                                text: "(" + quickLaunchCard.filteredDesktopApps.length + " installed)"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textMuted
                            }

                            Item { Layout.fillWidth: true }
                        }

                        // Search Bar (AppGrid style)
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 8
                            color: root.theme.bgSurface
                            border.color: settingsAppSearch.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: "󰍉"
                                    color: settingsAppSearch.activeFocus ? root.theme.accentPrimary : root.theme.textMuted
                                    font.pixelSize: 13
                                    font.family: root.font
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitHeight: settingsAppSearch.implicitHeight

                                    TextInput {
                                        id: settingsAppSearch
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: root.theme.textPrimary
                                        font.pixelSize: 12
                                        font.family: root.font
                                        clip: true
                                        selectByMouse: true
                                    }

                                    Text {
                                        text: "Search applications to assign to Slot #" + (quickLaunchCard.selectedSlotIndex + 1) + "..."
                                        color: root.theme.textMuted
                                        font.pixelSize: 12
                                        font.family: root.font
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: settingsAppSearch.text === ""
                                    }
                                }

                                MiniIconButton {
                                    visible: settingsAppSearch.text !== ""
                                    iconText: "󰅖"
                                    onClicked: settingsAppSearch.text = ""
                                }
                            }
                        }

                        // GridView of Installed Desktop Applications
                        GridView {
                            id: settingsAppGrid
                            Layout.fillWidth: true
                            Layout.preferredHeight: 240
                            cellWidth: Math.max(100, Math.floor(width / 5))
                            cellHeight: 78
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: quickLaunchCard.filteredDesktopApps

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle {
                                    implicitWidth: 4
                                    radius: 2
                                    color: root.theme.bgBorder
                                }
                            }

                            delegate: Item {
                                id: appGridCell
                                required property var modelData
                                required property int index
                                width: settingsAppGrid.cellWidth
                                height: settingsAppGrid.cellHeight

                                readonly property bool hasIcon: (appGridCell.modelData.icon ?? "") !== "" && Quickshell.iconPath(appGridCell.modelData.icon ?? "", true) !== ""
                                readonly property int assignedSlot: quickLaunchCard.findAssignedSlotForEntry(appGridCell.modelData)

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    radius: 10
                                    color: appGridCell.assignedSlot >= 0
                                        ? root.withAlpha(root.theme.accentPrimary, 0.1)
                                        : (cellHoverArea.containsMouse ? root.theme.bgHover : root.theme.bgSurface)
                                    border.color: cellHoverArea.containsMouse || appGridCell.assignedSlot >= 0
                                        ? root.theme.accentPrimary
                                        : root.theme.bgBorder
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    // Assigned Slot Badge
                                    Rectangle {
                                        visible: appGridCell.assignedSlot >= 0
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 4
                                        implicitWidth: assignedTxt.implicitWidth + 8
                                        height: 14
                                        radius: 4
                                        color: root.theme.accentPrimary

                                        Text {
                                            id: assignedTxt
                                            anchors.centerIn: parent
                                            text: "#" + (appGridCell.assignedSlot + 1)
                                            font.family: root.font
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: root.theme.bgBase
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
                                                color: root.theme.accentPrimary
                                                font.pixelSize: 20
                                                font.family: root.font
                                                visible: !appGridCell.hasIcon
                                            }
                                        }

                                        Text {
                                            width: parent.width
                                            text: appGridCell.modelData.name ?? ""
                                            color: (cellHoverArea.containsMouse || appGridCell.assignedSlot >= 0) ? root.theme.textPrimary : root.theme.textSecondary
                                            font.pixelSize: 10
                                            font.family: root.font
                                            font.bold: cellHoverArea.containsMouse || appGridCell.assignedSlot >= 0
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
                                            const entry = appGridCell.modelData;
                                            const key = quickLaunchCard.getAppKey(entry);
                                            const slot = Math.max(0, Math.min(ControlCenterConfig.quickAppsMaxCount - 1, quickLaunchCard.selectedSlotIndex));
                                            ControlCenterConfig.replaceQuickAppAt(
                                                slot,
                                                entry.name || "App",
                                                entry.icon || "󰀻",
                                                "",
                                                key,
                                                quickLaunchCard.displayedQuickApps
                                            );
                                            root.showToast("Assigned " + (entry.name || "App") + " to Slot #" + (slot + 1));
                                            quickLaunchCard.selectedSlotIndex = (slot + 1) % ControlCenterConfig.quickAppsMaxCount;
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
