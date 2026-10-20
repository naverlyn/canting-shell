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

ColumnLayout {
    required property var root
    id: optionsCol
    Layout.fillWidth: true
    spacing: 20

    property int selectedSlotIndex: 0
    property var appUsage: ({})

    Process {
        id: usageReaderProc
        command: ["sh", "-c", "cat \"$HOME/.cache/qs_app_usage.json\" 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim() || "{}");
                    if (parsed && typeof parsed === "object") optionsCol.appUsage = parsed;
                } catch (e) {
                    optionsCol.appUsage = ({});
                }
            }
        }
    }

    function getAppKey(entry) {
        return (entry && (entry.id || entry.name)) ? (entry.id || entry.name) : "";
    }

    function getFrecencyScore(entry, usageMap) {
        const key = getAppKey(entry);
        if (!key || !usageMap || !usageMap[key]) return 0;
        const item = usageMap[key];
        const count = item.count || 0;
        if (count <= 0) return 0;
        return (item.lastUsed || 0) + (count * 86400000);
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
        const eKey = optionsCol.getAppKey(entry).toLowerCase();
        const eName = (entry.name || "").toLowerCase();
        const list = optionsCol.displayedQuickApps || [];
        for (let i = 0; i < list.length; i++) {
            const item = list[i];
            const dId = (item.desktopId || item.id || "").toLowerCase();
            const dLbl = (item.label || "").toLowerCase();
            if ((eKey && dId === eKey) || (eName && dLbl === eName)) return i;
        }
        return -1;
    }

    readonly property var sortedDesktopApps: {
        const usage = optionsCol.appUsage;
        const all = [...DesktopEntries.applications.values];
        return all.sort((a, b) => {
            const sa = optionsCol.getFrecencyScore(a, usage);
            const sb = optionsCol.getFrecencyScore(b, usage);
            if (sa !== sb) return sb - sa;
            return (a.name || "").localeCompare(b.name || "");
        });
    }

    readonly property var filteredDesktopApps: {
        const all = optionsCol.sortedDesktopApps;
        const q = settingsAppSearch.text.trim().toLowerCase();
        if (q === "") return all;
        const usage = optionsCol.appUsage;
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
            const sa = optionsCol.getFrecencyScore(a, usage);
            const sb = optionsCol.getFrecencyScore(b, usage);
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
            const entry = optionsCol.findDesktopEntry(item);
            const key = (item.desktopId || item.id || item.label || "").toLowerCase();
            if (key) usedKeys[key] = true;
            if (entry) {
                const eKey = optionsCol.getAppKey(entry).toLowerCase();
                if (eKey) usedKeys[eKey] = true;
            }
            result.push({
                slotIndex: result.length,
                id: item.id || ("slot_" + i),
                desktopId: item.desktopId || (entry ? optionsCol.getAppKey(entry) : ""),
                label: item.label || (entry ? entry.name : "App"),
                icon: (entry && entry.icon && optionsCol.isSystemIcon(entry.icon)) ? entry.icon : (item.icon || "󰀻"),
                cmd: item.cmd || ""
            });
        }

        const desktopList = optionsCol.sortedDesktopApps;
        for (let j = 0; j < desktopList.length && result.length < targetCount; j++) {
            const d = desktopList[j];
            const dKey = optionsCol.getAppKey(d).toLowerCase();
            const dName = (d.name || "").toLowerCase();
            if ((dKey && usedKeys[dKey]) || (dName && usedKeys[dName])) continue;
            if (dKey) usedKeys[dKey] = true;
            if (dName) usedKeys[dName] = true;
            result.push({
                slotIndex: result.length,
                id: dKey || ("auto_" + j),
                desktopId: optionsCol.getAppKey(d),
                label: d.name || "App",
                icon: d.icon || "󰀻",
                cmd: ""
            });
        }
        return result;
    }

    readonly property var balancedQuickAppRows: {
        const list = optionsCol.displayedQuickApps || [];
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

    // Card 1: Media Player & Visualizer Options
    SectionCard {
        title: "Media Player & Visualizer Options"
        subtitle: "Configure MPRIS playback card style, auto-hide behavior, and Cava spectrum"
        contentMargins: 8
        contentSpacing: 0

        // Row 1: MPRIS Player Style (Compact vs Full Banner)
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
                        text: "MPRIS Player Style"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "Auto switches to Compact when stacked with other modules in a panel, or Big when alone"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    id: mprisSegTrack
                    implicitWidth: 270
                    implicitHeight: 32
                    width: 270
                    height: 32
                    radius: 7
                    color: root.theme.bgBase
                    border.color: root.theme.bgBorder
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    readonly property int activeIdx: ControlCenterConfig.mediaWidgetStyle === "auto"
                        ? 0
                        : (ControlCenterConfig.mediaWidgetStyle === "compact" ? 1 : 2)
                    readonly property real cellWidth: (width - 6 - 8) / 3

                    Rectangle {
                        y: 3
                        height: parent.height - 6
                        width: mprisSegTrack.cellWidth
                        x: 3 + mprisSegTrack.activeIdx * (mprisSegTrack.cellWidth + 4)
                        radius: 5
                        color: root.theme.bgSelected
                        border.color: root.theme.accentPrimary
                        border.width: 1

                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 4

                        Repeater {
                            model: [
                                { label: "Auto", value: "auto" },
                                { label: "Compact", value: "compact" },
                                { label: "Big Banner", value: "full" }
                            ]

                            delegate: Rectangle {
                                id: mprisBtn
                                required property var modelData
                                readonly property bool isSel: ControlCenterConfig.mediaWidgetStyle === modelData.value

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 5
                                scale: mprisMouse.pressed ? 0.95 : 1.0
                                color: !isSel && mprisHover.hovered ? root.theme.bgHover : "transparent"

                                Behavior on scale { NumberAnimation { duration: 100 } }
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: mprisHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: mprisBtn.modelData.label
                                    font.family: root.font
                                    font.pixelSize: 11
                                    font.bold: mprisBtn.isSel
                                    color: mprisBtn.isSel ? root.theme.accentPrimary : root.theme.textSecondary
                                    opacity: mprisBtn.isSel || mprisHover.hovered ? 1.0 : 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    id: mprisMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ControlCenterConfig.setMediaWidgetStyle(mprisBtn.modelData.value);
                                        root.showToast("MPRIS style set to " + mprisBtn.modelData.label);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowDivider {}

        // Row 2: Auto-Hide Media Player
        SettingToggleRow {
            title: "Auto-Hide Media Player"
            desc: "Automatically hide the media card when no MPRIS audio player is active"
            checked: ControlCenterConfig.mediaAutoHide
            onToggled: (val) => {
                ControlCenterConfig.setCardVisible("mediaAutoHide", val);
                root.showToast(val ? "Media auto-hide enabled" : "Media auto-hide disabled");
            }
        }

        RowDivider {}

        // Row 3: Show Cava Equalizer in Media Player
        SettingToggleRow {
            title: "Show Cava Equalizer in Media Player"
            desc: "Display live audio spectrum visualizer inside the media player card"
            checked: ControlCenterConfig.mediaShowCava
            onToggled: (val) => {
                ControlCenterConfig.setMediaShowCava(val);
                root.showToast(val ? "Media Cava equalizer enabled" : "Media Cava equalizer disabled");
            }
        }
    }

    // Card 2: Polished Quick Launch & App Grid Configuration
    SectionCard {
        title: "Quick Launch & App Grid"
        subtitle: "Configure how many apps appear in Quick Launch (3 to 15 max) and assign apps from your AppGrid menu"

        SettingSliderRow {
            title: "Quick Launch App Count"
            desc: "Number of app shortcuts displayed in the Quick Launch module (3 to 15 max)"
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
                if (optionsCol.selectedSlotIndex >= val) {
                    optionsCol.selectedSlotIndex = Math.max(0, val - 1);
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
                            text: "Editing Slot #" + (optionsCol.selectedSlotIndex + 1)
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
                            optionsCol.selectedSlotIndex = 0;
                            root.showToast("Restored default Quick Launch apps");
                        }
                    }
                }

                // Balanced Rows Matching QuickAppsCard.qml (Zero Square Gaps)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: optionsCol.balancedQuickAppRows

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
                                    readonly property bool isSel: optionsCol.selectedSlotIndex === slotIdx
                                    readonly property bool hasSysIcon: optionsCol.isSystemIcon(modelData.icon)

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
                                                ControlCenterConfig.moveQuickAppInFullList(previewTile.slotIdx, previewTile.slotIdx - 1, optionsCol.displayedQuickApps);
                                                optionsCol.selectedSlotIndex = previewTile.slotIdx - 1;
                                            }
                                        }

                                        MiniIconButton {
                                            visible: previewTile.slotIdx < ControlCenterConfig.quickAppsMaxCount - 1
                                            iconText: "󰅂"
                                            onClicked: {
                                                ControlCenterConfig.moveQuickAppInFullList(previewTile.slotIdx, previewTile.slotIdx + 1, optionsCol.displayedQuickApps);
                                                optionsCol.selectedSlotIndex = previewTile.slotIdx + 1;
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        width: parent.width - 12
                                        spacing: 4

                                        Item {
                                            Layout.alignment: Qt.AlignHCenter
                                            width: 24
                                            height: 24

                                            IconImage {
                                                anchors.fill: parent
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
                                            Layout.fillWidth: true
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
                                        onClicked: optionsCol.selectedSlotIndex = previewTile.slotIdx
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
                        text: "(" + optionsCol.filteredDesktopApps.length + " installed)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textMuted
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Click any application below to assign it to Slot #" + (optionsCol.selectedSlotIndex + 1)
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.textSecondary
                    }
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
                                text: "Search applications to assign to Slot #" + (optionsCol.selectedSlotIndex + 1) + "..."
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
                    model: optionsCol.filteredDesktopApps

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
                        readonly property int assignedSlot: optionsCol.findAssignedSlotForEntry(appGridCell.modelData)

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

                            ColumnLayout {
                                anchors.centerIn: parent
                                width: parent.width - 10
                                spacing: 5

                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 30
                                    height: 30

                                    IconImage {
                                        anchors.fill: parent
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
                                    Layout.fillWidth: true
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
                                    const key = optionsCol.getAppKey(entry);
                                    const slot = Math.max(0, Math.min(ControlCenterConfig.quickAppsMaxCount - 1, optionsCol.selectedSlotIndex));
                                    ControlCenterConfig.replaceQuickAppAt(
                                        slot,
                                        entry.name || "App",
                                        entry.icon || "󰀻",
                                        "",
                                        key,
                                        optionsCol.displayedQuickApps
                                    );
                                    root.showToast("Assigned " + (entry.name || "App") + " to Slot #" + (slot + 1));
                                    optionsCol.selectedSlotIndex = (slot + 1) % ControlCenterConfig.quickAppsMaxCount;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Card 3: Visible Flyout Sections
    SectionCard {
        title: "Active Flyout Sections"
        subtitle: "Quickly toggle visibility for each modular Control Center section"
        contentMargins: 8
        contentSpacing: 0

        Repeater {
            model: ControlCenterConfig.allCardDefs
            delegate: ColumnLayout {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: 0

                RowDivider {
                    visible: index > 0
                }

                SettingToggleRow {
                    title: modelData.label
                    desc: modelData.desc
                    checked: ControlCenterConfig.isCardVisible(modelData.id)
                    onToggled: (val) => {
                        ControlCenterConfig.setCardVisible(modelData.id, val);
                        root.showToast((val ? "Enabled " : "Hidden ") + modelData.label);
                    }
                }
            }
        }
    }
}

