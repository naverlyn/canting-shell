import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"

    signal closeParentRequested()

    property bool isPickerOpen: false
    property int targetSlotIndex: -1 // -1 = append/toggle, >= 0 = replace specific slot
    property var appUsage: ({})
    readonly property string usageCachePath: "$HOME/.cache/qs_app_usage.json"

    width: parent ? parent.width : 300
    height: appsCol.implicitHeight + 24
    implicitHeight: appsCol.implicitHeight + 24
    implicitWidth: 300
    radius: 10
    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
    border.color: root.theme.bgBorder
    border.width: 1

    Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Process {
        id: appLaunchProc
        running: false
    }

    Process {
        id: loadUsageProc
        command: ["sh", "-c", "cat \"$HOME/.cache/qs_app_usage.json\" 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim() || "{}");
                    if (parsed && typeof parsed === "object") root.appUsage = parsed;
                } catch (e) {
                    root.appUsage = ({});
                }
            }
        }
    }

    Process {
        id: saveUsageProc
        running: false
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

    function recordAppLaunch(entry) {
        const key = getAppKey(entry);
        if (!key) return;
        const next = Object.assign({}, root.appUsage);
        const prev = next[key] || { count: 0, lastUsed: 0 };
        next[key] = { count: (prev.count || 0) + 1, lastUsed: Date.now() };
        root.appUsage = next;
        saveUsageProc.command = [
            "python3", "-c",
            "import os, sys; p = os.path.expanduser('~/.cache/qs_app_usage.json'); open(p, 'w').write(sys.argv[1])",
            JSON.stringify(next)
        ];
        saveUsageProc.running = true;
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
        const resolved = Quickshell.iconPath(iconStr, true);
        return resolved !== "";
    }

    function launchApp(app) {
        if (!app) return;
        root.closeParentRequested();
        if (app.cmd === "__appgrid__") {
            appLaunchProc.command = ["qs", "ipc", "call", "appgrid", "toggle"];
            appLaunchProc.running = true;
            return;
        }
        if (app.cmd === "__settings__") {
            appLaunchProc.command = [
                "sh", "-c",
                "qs -p \"$HOME/.config/quickshell/Settings/SettingsApp.qml\" >/dev/null 2>&1 &"
            ];
            appLaunchProc.running = true;
            return;
        }
        const entry = app.desktopEntry || findDesktopEntry(app);
        if (entry) {
            recordAppLaunch(entry);
            entry.execute();
            return;
        }
        if (app.cmd) {
            appLaunchProc.command = ["sh", "-c", "(" + app.cmd + ") >/dev/null 2>&1 &"];
            appLaunchProc.running = true;
        }
    }

    // Sorted desktop applications from AppGrid (frecency + alphabetical)
    readonly property var sortedDesktopApps: {
        const usage = root.appUsage;
        const all = [...DesktopEntries.applications.values];
        return all.sort((a, b) => {
            const sa = root.getFrecencyScore(a, usage);
            const sb = root.getFrecencyScore(b, usage);
            if (sa !== sb) return sb - sa;
            return (a.name || "").localeCompare(b.name || "");
        });
    }

    // Filtered desktop applications for the inline AppGrid picker
    readonly property var filteredDesktopApps: {
        if (!root.isPickerOpen && !ControlCenterConfig.isLiveEdit) return [];
        const all = root.sortedDesktopApps;
        const q = appSearchInput.text.trim().toLowerCase();
        if (q === "") return all;
        const usage = root.appUsage;
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
            const sa = root.getFrecencyScore(a, usage);
            const sb = root.getFrecencyScore(b, usage);
            if (sa !== sb) return sb - sa;
            return an.localeCompare(bn);
        });
    }

    // Resolved list of exactly quickAppsMaxCount (3..15) apps (configured + AppGrid top apps fallback)
    readonly property var displayedApps: {
        const targetCount = Math.max(3, Math.min(15, ControlCenterConfig.quickAppsMaxCount));
        const configured = ControlCenterConfig.quickApps || [];
        let result = [];
        let usedKeys = ({});

        for (let i = 0; i < configured.length && result.length < targetCount; i++) {
            const item = configured[i];
            if (!item) continue;
            const entry = root.findDesktopEntry(item);
            const key = (item.desktopId || item.id || item.label || "").toLowerCase();
            if (key) usedKeys[key] = true;
            if (entry) {
                const eKey = root.getAppKey(entry).toLowerCase();
                if (eKey) usedKeys[eKey] = true;
            }
            result.push({
                slotIndex: result.length,
                id: item.id || ("slot_" + i),
                desktopId: item.desktopId || (entry ? root.getAppKey(entry) : ""),
                label: item.label || (entry ? entry.name : "App"),
                icon: item.icon || (entry ? entry.icon : "󰀻"),
                cmd: item.cmd || "",
                desktopEntry: entry
            });
        }

        const desktopList = root.sortedDesktopApps;
        for (let j = 0; j < desktopList.length && result.length < targetCount; j++) {
            const d = desktopList[j];
            const dKey = root.getAppKey(d).toLowerCase();
            const dName = (d.name || "").toLowerCase();
            if ((dKey && usedKeys[dKey]) || (dName && usedKeys[dName])) continue;
            if (dKey) usedKeys[dKey] = true;
            if (dName) usedKeys[dName] = true;
            result.push({
                slotIndex: result.length,
                id: dKey || ("auto_" + j),
                desktopId: root.getAppKey(d),
                label: d.name || "App",
                icon: d.icon || "󰀻",
                cmd: "",
                desktopEntry: d
            });
        }

        return result;
    }

    // Balanced row partitioning for 3..15 items so there is NEVER an empty square gap
    readonly property var balancedAppRows: {
        const list = root.displayedApps || [];
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

    ColumnLayout {
        id: appsCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 12
        }
        spacing: 10

        // Header Row: Title + Count Stepper (3..15) + AppGrid Picker Toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "󰀻"
                font.family: root.font
                font.pixelSize: 13
                color: root.theme.accentPrimary
            }

            Text {
                text: "Quick Launch"
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }

            // App Count Stepper (3 to 15 max)
            Rectangle {
                height: 22
                implicitWidth: countStepperRow.implicitWidth + 10
                radius: 6
                color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
                border.color: root.theme.bgBorder
                border.width: 1

                RowLayout {
                    id: countStepperRow
                    anchors.centerIn: parent
                    spacing: 4

                    // Decrease count (-)
                    Rectangle {
                        width: 16
                        height: 16
                        radius: 4
                        color: decMouse.containsMouse
                            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.22)
                            : "transparent"
                        opacity: ControlCenterConfig.quickAppsMaxCount > 3 ? 1.0 : 0.35

                        Text {
                            anchors.centerIn: parent
                            text: "−"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: decMouse.containsMouse ? root.theme.accentPrimary : root.theme.textSecondary
                        }

                        MouseArea {
                            id: decMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: ControlCenterConfig.quickAppsMaxCount > 3 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (ControlCenterConfig.quickAppsMaxCount > 3) {
                                    ControlCenterConfig.setQuickAppsMaxCount(ControlCenterConfig.quickAppsMaxCount - 1);
                                }
                            }
                        }
                    }

                    Text {
                        text: ControlCenterConfig.quickAppsMaxCount + " apps"
                        font.family: root.font
                        font.pixelSize: 9
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    // Increase count (+) up to 15
                    Rectangle {
                        width: 16
                        height: 16
                        radius: 4
                        color: incMouse.containsMouse
                            ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.22)
                            : "transparent"
                        opacity: ControlCenterConfig.quickAppsMaxCount < 15 ? 1.0 : 0.35

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: incMouse.containsMouse ? root.theme.accentPrimary : root.theme.textSecondary
                        }

                        MouseArea {
                            id: incMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: ControlCenterConfig.quickAppsMaxCount < 15 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (ControlCenterConfig.quickAppsMaxCount < 15) {
                                    ControlCenterConfig.setQuickAppsMaxCount(ControlCenterConfig.quickAppsMaxCount + 1);
                                }
                            }
                        }
                    }
                }
            }

            // Open AppGrid Picker / Edit button
            Rectangle {
                height: 22
                implicitWidth: editAppsRow.implicitWidth + 12
                radius: 6
                color: (root.isPickerOpen || editAppsMouse.containsMouse)
                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.2)
                    : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)
                border.color: root.isPickerOpen ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                Row {
                    id: editAppsRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: root.isPickerOpen ? "Done" : "Apps"
                        font.family: root.font
                        font.pixelSize: 9
                        font.bold: true
                        color: root.isPickerOpen ? root.theme.accentPrimary : root.theme.textSecondary
                    }
                }

                MouseArea {
                    id: editAppsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isPickerOpen = !root.isPickerOpen;
                        if (root.isPickerOpen) {
                            loadUsageProc.running = true;
                            if (root.targetSlotIndex < 0) root.targetSlotIndex = 0;
                        } else {
                            root.targetSlotIndex = -1;
                        }
                    }
                }
            }
        }

        // Gap-Free Balanced Rows of App Tiles
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.balancedAppRows

                delegate: RowLayout {
                    id: rowLayoutItem
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: rowLayoutItem.modelData

                        delegate: Rectangle {
                            id: appTile
                            required property var modelData
                            required property int index

                            readonly property int slotIdx: modelData.slotIndex
                            readonly property bool inEditMode: root.isPickerOpen || ControlCenterConfig.isLiveEdit
                            readonly property bool isSelectedSlot: inEditMode && root.targetSlotIndex === slotIdx
                            readonly property bool hasSysIcon: root.isSystemIcon(modelData.icon)

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 56
                            implicitHeight: 56
                            height: 56
                            radius: 8
                            scale: appMouse.pressed ? 0.94 : (appHover.hovered ? 1.02 : 1.0)
                            color: isSelectedSlot
                                ? root.theme.bgSelected
                                : (appHover.hovered
                                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.16)
                                    : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05))
                            border.color: isSelectedSlot || appHover.hovered
                                ? root.theme.accentPrimary
                                : (inEditMode
                                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.35)
                                    : Qt.rgba(root.theme.bgBorder.r, root.theme.bgBorder.g, root.theme.bgBorder.b, 0.6))
                            border.width: isSelectedSlot ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on border.color { ColorAnimation { duration: 130 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            HoverHandler { id: appHover }

                            ColumnLayout {
                                anchors.centerIn: parent
                                width: parent.width - 8
                                spacing: 3

                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 22
                                    height: 22

                                    IconImage {
                                        anchors.fill: parent
                                        visible: appTile.hasSysIcon
                                        source: appTile.hasSysIcon ? Quickshell.iconPath(appTile.modelData.icon, true) : ""
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !appTile.hasSysIcon
                                        text: appTile.modelData.icon || "󰀻"
                                        font.family: root.font
                                        font.pixelSize: 16
                                        color: (appTile.isSelectedSlot || appHover.hovered) ? root.theme.accentPrimary : root.theme.textPrimary
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: appTile.modelData.label || "App"
                                    font.family: root.font
                                    font.pixelSize: 9
                                    font.bold: appTile.isSelectedSlot || appHover.hovered
                                    color: (appTile.isSelectedSlot || appHover.hovered) ? root.theme.textPrimary : root.theme.textSecondary
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: appMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (appTile.inEditMode) {
                                        root.targetSlotIndex = appTile.slotIdx;
                                        root.isPickerOpen = true;
                                        loadUsageProc.running = true;
                                    } else {
                                        root.launchApp(appTile.modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Inline AppGrid-Style Application Picker (matches AppLauncher/AppGrid.qml)
        Rectangle {
            visible: root.isPickerOpen
            Layout.fillWidth: true
            implicitHeight: pickerCol.implicitHeight + 20
            radius: 10
            color: root.theme.bgBase
            border.color: root.theme.accentPrimary
            border.width: 1

            ColumnLayout {
                id: pickerCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: root.targetSlotIndex >= 0
                            ? ("Pick app for Slot " + (root.targetSlotIndex + 1) + " (click any tile above to switch slot)")
                            : "Click an app below to add to Quick Launch"
                        font.family: root.font
                        font.pixelSize: 10
                        font.bold: true
                        color: root.theme.accentPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Open full bar AppGrid button
                    Rectangle {
                        height: 20
                        implicitWidth: openGridTxt.implicitWidth + 12
                        radius: 5
                        color: openGridMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                        border.color: root.theme.bgBorder
                        border.width: 1

                        Text {
                            id: openGridTxt
                            anchors.centerIn: parent
                            text: "Full AppGrid"
                            font.family: root.font
                            font.pixelSize: 9
                            font.bold: true
                            color: root.theme.textSecondary
                        }

                        MouseArea {
                            id: openGridMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.closeParentRequested();
                                appLaunchProc.command = ["qs", "ipc", "call", "appgrid", "toggle"];
                                appLaunchProc.running = true;
                            }
                        }
                    }

                    // Reset defaults button
                    Rectangle {
                        height: 20
                        implicitWidth: resetAppsTxt.implicitWidth + 12
                        radius: 5
                        color: resetAppsMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                        border.color: root.theme.bgBorder
                        border.width: 1

                        Text {
                            id: resetAppsTxt
                            anchors.centerIn: parent
                            text: "Reset"
                            font.family: root.font
                            font.pixelSize: 9
                            font.bold: true
                            color: root.theme.textSecondary
                        }

                        MouseArea {
                            id: resetAppsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ControlCenterConfig.resetQuickApps()
                        }
                    }
                }

                // AppGrid Search Bar (uses theme.bgSurface, theme.textPrimary, theme.textMuted)
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: root.theme.bgSurface
                    border.color: appSearchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "󰍉"
                            color: root.theme.textMuted
                            font.pixelSize: 12
                            font.family: root.font
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
                                color: root.theme.textPrimary
                                font.pixelSize: 11
                                font.family: root.font
                                clip: true
                                selectByMouse: true
                            }

                            Text {
                                text: "Search applications..."
                                color: root.theme.textMuted
                                font.pixelSize: 11
                                font.family: root.font
                                anchors.verticalCenter: parent.verticalCenter
                                visible: appSearchInput.text === ""
                            }
                        }
                    }
                }

                // AppGrid GridView of Installed Desktop Applications
                GridView {
                    id: pickerGrid
                    Layout.fillWidth: true
                    Layout.preferredHeight: 168
                    cellWidth: Math.floor(width / 4)
                    cellHeight: 56
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.filteredDesktopApps

                    delegate: Item {
                        id: pickerCell
                        required property var modelData
                        required property int index
                        width: pickerGrid.cellWidth
                        height: pickerGrid.cellHeight

                        readonly property bool hasIcon: (pickerCell.modelData.icon ?? "") !== "" && Quickshell.iconPath(pickerCell.modelData.icon ?? "", true) !== ""

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 8
                            color: pickerCellMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                            border.color: pickerCellMouse.containsMouse ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                width: parent.width - 8
                                spacing: 3

                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 22
                                    height: 22

                                    IconImage {
                                        anchors.fill: parent
                                        source: pickerCell.hasIcon ? Quickshell.iconPath(pickerCell.modelData.icon ?? "", true) : ""
                                        visible: pickerCell.hasIcon
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰀻"
                                        color: root.theme.accentPrimary
                                        font.pixelSize: 15
                                        font.family: root.font
                                        visible: !pickerCell.hasIcon
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: pickerCell.modelData.name ?? ""
                                    color: pickerCellMouse.containsMouse ? root.theme.textPrimary : root.theme.textSecondary
                                    font.pixelSize: 9
                                    font.family: root.font
                                    font.bold: pickerCellMouse.containsMouse
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: pickerCellMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const entry = pickerCell.modelData;
                                    const key = root.getAppKey(entry);
                                    const slot = root.targetSlotIndex >= 0
                                        ? root.targetSlotIndex
                                        : Math.min(14, root.displayedApps.length - 1);
                                    ControlCenterConfig.replaceQuickAppAt(
                                        slot,
                                        entry.name || "App",
                                        entry.icon || "󰀻",
                                        "",
                                        key,
                                        root.displayedApps
                                    );
                                    // Advance to next slot automatically for fast assignment
                                    root.targetSlotIndex = (slot + 1) % ControlCenterConfig.quickAppsMaxCount;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
