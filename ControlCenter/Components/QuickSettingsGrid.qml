import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../bar"
import "../../ThemeSwitcher"
import "../../notifications"
import ".."

ColumnLayout {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Lato Nerd Font"
    property string mode: "tiles" // "connectivity", "tiles", "tiles2", "both" or "panelTiles"

    // "panelTiles" mode: individual tiles placed directly in a panel
    property var tileIds: []
    property int panelIndex: -1
    property int blockStart: 0
    readonly property bool isPanelTiles: root.mode === "panelTiles"
    // Extra pixels added to the last tile row (used to equalise panel heights)
    property real extraHeight: 0
    // Quick Tiles cards are drawn inside a rounded card, like the Connectivity group
    readonly property bool carded: root.mode === "tiles" || root.mode === "tiles2" || root.mode === "both"
    readonly property real tileAreaWidth: root.carded ? root.width - 16 : root.width

    // Toggle states
    property bool wifiEnabled: true
    property string currentSsid: ""
    property bool btEnabled: false
    property bool btAvailable: false
    readonly property bool dndEnabled: NotificationService.doNotDisturb
    property bool airplaneEnabled: false
    property bool nightLightEnabled: false
    property bool gameModeEnabled: false
    readonly property bool isDarkMode: (root.theme && root.theme.isDark !== undefined) ? root.theme.isDark : Theme.isDark

    readonly property bool micMuted: {
        if (!Pipewire.defaultAudioSource || !Pipewire.defaultAudioSource.audio) return false;
        return Pipewire.defaultAudioSource.audio.muted;
    }

    readonly property bool sinkMuted: {
        if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return false;
        return Pipewire.defaultAudioSink.audio.muted;
    }

    readonly property string nightLightScript: Qt.resolvedUrl("../scripts/nightlight.sh").toString().replace(/^file:\/\//, "")
    readonly property string gameModeScript: Qt.resolvedUrl("../scripts/gamemode.sh").toString().replace(/^file:\/\//, "")
    readonly property string emojiScript: Qt.resolvedUrl("../scripts/emoji.sh").toString().replace(/^file:\/\//, "")

    signal openWifiRequested()
    signal closeParentRequested()

    // Drag & Drop State for Live Edit Mode
    property bool isDragging: false
    property string draggedTileId: ""
    property int dragSourceIndex: -1
    property int dragHoverIndex: -1
    property real dragMouseX: 0
    property real dragMouseY: 0

    // Index (within this block) of the tile under a point given in the control center main rect
    function tileIndexAtMain(mx, my, mainRect) {
        for (let i = 0; i < tilesRepeater.count; i++) {
            const item = tilesRepeater.itemAt(i);
            if (!item) continue;
            const pt = item.mapFromItem(mainRect, mx, my);
            if (pt.x >= -4 && pt.x <= item.width + 4 && pt.y >= -4 && pt.y <= item.height + 4) return i;
        }
        return -1;
    }

    readonly property var hostCenterRef: (typeof controlCenter !== "undefined") ? controlCenter : null

    function startTileDrag(tid, srcIdx, rootX, rootY) {
        draggedTileId = tid;
        dragSourceIndex = srcIdx;
        dragHoverIndex = srcIdx;
        dragMouseX = rootX;
        dragMouseY = rootY;
        isDragging = true;
        if (root.isPanelTiles && root.hostCenterRef) {
            const p = root.mapToItem(root.hostCenterRef.mainRect, rootX, rootY);
            root.hostCenterRef.startCardDrag("tile:" + tid, -1, p.x, p.y);
        }
    }

    function updateTileDrag(rootX, rootY) {
        dragMouseX = rootX;
        dragMouseY = rootY;
        if (!isDragging) return;
        if (root.isPanelTiles && root.hostCenterRef) {
            const p = root.mapToItem(root.hostCenterRef.mainRect, rootX, rootY);
            root.hostCenterRef.updateCardDrag(p.x, p.y);
            return;
        }
        for (let i = 0; i < tilesRepeater.count; i++) {
            const item = tilesRepeater.itemAt(i);
            if (!item) continue;
            const pt = item.mapFromItem(root, rootX, rootY);
            if (pt.x >= 0 && pt.x <= item.width && pt.y >= 0 && pt.y <= item.height) {
                dragHoverIndex = i;
                return;
            }
        }
    }

    readonly property var activeTileModel: {
        if (root.mode === "panelTiles") {
            let res = [];
            for (let i = 0; i < root.tileIds.length; i++) {
                const def = ControlCenterConfig.getTileDef(root.tileIds[i]);
                if (def) res.push({ id: def.id, label: def.label, icon: def.icon, desc: def.desc });
            }
            return res;
        }
        if (root.mode === "tiles2") return ControlCenterConfig.secondaryTiles;
        return (ControlCenterConfig.isCardVisible("connectivity") || ControlCenterConfig.groupTilesEnabled)
            ? ControlCenterConfig.ungroupedTiles
            : ControlCenterConfig.enabledTiles;
    }

    function finishTileDrag() {
        if (!isDragging) return;
        const srcIdx = dragSourceIndex;
        const targetIdx = dragHoverIndex;
        isDragging = false;
        draggedTileId = "";
        dragHoverIndex = -1;
        dragSourceIndex = -1;
        if (root.isPanelTiles) {
            if (root.hostCenterRef) root.hostCenterRef.finishCardDrag();
            return;
        }
        if (srcIdx >= 0 && targetIdx >= 0 && srcIdx !== targetIdx) {
            if (root.mode === "tiles2") {
                ControlCenterConfig.moveSecondaryTile(srcIdx, targetIdx);
            } else {
                ControlCenterConfig.moveUngroupedTile(srcIdx, targetIdx);
            }
        }
    }

    width: parent ? parent.width : 300
    spacing: 8

    // Wi-Fi Processes
    Process {
        id: wifiProc
        running: false
        onExited: {
            wifiStatusProc.running = true;
            activeSsidProc.running = true;
        }
    }

    Process {
        id: wifiStatusProc
        command: ["nmcli", "radio", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = (text.trim() === "enabled");
            }
        }
    }

    Process {
        id: activeSsidProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.currentSsid = text.trim()
        }
    }

    // Bluetooth Processes
    Process {
        id: btProc
        running: false
        onExited: btStatusProc.running = true
    }

    Process {
        id: btStatusProc
        command: [
            "sh", "-c",
            "if [ -z \"$(ls -A /sys/class/bluetooth 2>/dev/null)\" ]; then echo 'none'; elif bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then echo 'on'; else echo 'off'; fi"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const res = text.trim();
                if (res === "none") {
                    root.btAvailable = false;
                    root.btEnabled = false;
                } else {
                    root.btAvailable = true;
                    root.btEnabled = (res === "on");
                }
            }
        }
    }

    // Airplane Mode Processes
    Process { id: airplaneProc; running: false }

    Process {
        id: airplaneStatusProc
        command: ["sh", "-c", "rfkill list wifi | grep -o 'Soft blocked: yes'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const blocked = text.trim() !== "";
                root.airplaneEnabled = blocked;
                if (blocked) root.wifiEnabled = false;
            }
        }
    }

    // Night Light Processes
    Process {
        id: nlStatusProc
        command: ["bash", root.nightLightScript, "status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.nightLightEnabled = (text.trim() === "on");
            }
        }
    }

    Process {
        id: nlToggleProc
        command: ["bash", root.nightLightScript, "toggle"]
        running: false
        onExited: nlStatusProc.running = true
    }

    // Game Mode Processes
    Process {
        id: gameModeStatusProc
        command: ["sh", "-c", "hyprctl getoption animations:enabled 2>/dev/null | awk 'NR==1{print $2}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.gameModeEnabled = (text.trim() === "0");
            }
        }
    }

    Process {
        id: gameModeToggleProc
        command: ["bash", root.gameModeScript]
        running: false
        onExited: gameModeStatusProc.running = true
    }

    // Clipboard Process
    Process {
        id: clipProc
        command: ["sh", "-c", "qs ipc call clipboard toggle 2>/dev/null || quickshell ipc call clipboard toggle"]
        running: false
    }

    // Emoji Process
    Process {
        id: emojiProc
        command: ["bash", root.emojiScript]
        running: false
    }

    // Screenshot Process
    Process {
        id: screenshotProc
        command: ["sh", "-c", "sleep 0.15 && qs ipc call screenshot toggle"]
        running: false
    }

    // Lock Process
    Process {
        id: lockProc
        command: ["sh", "-c", "sleep 0.15 && qs ipc call lockscreen lock"]
        running: false
    }

    function setWifi(enabled) {
        if (root.wifiEnabled === enabled) return;
        root.wifiEnabled = enabled;
        if (root.wifiEnabled) {
            root.airplaneEnabled = false;
            activeSsidProc.running = true;
        } else {
            root.currentSsid = "";
        }
        wifiProc.command = ["nmcli", "radio", "wifi", root.wifiEnabled ? "on" : "off"];
        wifiProc.running = true;
    }

    function toggleWifi() {
        setWifi(!root.wifiEnabled);
    }

    function toggleBt() {
        if (!root.btAvailable) {
            btStatusProc.running = true;
            return;
        }
        const targetState = !root.btEnabled;
        btProc.command = targetState
            ? ["sh", "-c", "rfkill unblock bluetooth 2>/dev/null || true; bluetoothctl power on"]
            : ["bluetoothctl", "power", "off"];
        btProc.running = true;
    }

    function togglednd() {
        NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
    }

    function toggleAirplane() {
        if (root.airplaneEnabled) {
            root.airplaneEnabled = false;
            root.wifiEnabled = true;
            airplaneProc.command = [
                "sh", "-c",
                "rfkill unblock wifi && notify-send -u low -i network-wireless-signal-excellent-symbolic \"Airplane Mode\" \"OFF\""
            ];
        } else {
            root.airplaneEnabled = true;
            root.wifiEnabled = false;
            root.currentSsid = "";
            airplaneProc.command = [
                "sh", "-c",
                "rfkill block wifi && notify-send -u low -i airplane-mode-symbolic \"Airplane Mode\" \"ON\""
            ];
        }
        airplaneProc.running = true;
    }

    function toggleNightLight() {
        nlToggleProc.running = true;
    }

    function toggleMic() {
        if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
            Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted;
        }
    }

    function toggleSinkMute() {
        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
        }
    }

    function toggleGameMode() {
        gameModeToggleProc.running = true;
    }

    function toggleDarkMode() {
        if (root.theme && typeof root.theme.toggleDarkLight === "function") {
            root.theme.toggleDarkLight();
        } else {
            Theme.toggleDarkLight();
        }
    }

    function openClipboard() {
        root.closeParentRequested();
        clipProc.running = true;
    }

    function openEmoji() {
        root.closeParentRequested();
        emojiProc.running = true;
    }

    function takeScreenshot() {
        root.closeParentRequested();
        screenshotProc.running = true;
    }

    function lockSession() {
        root.closeParentRequested();
        lockProc.running = true;
    }

    function refresh() {
        wifiStatusProc.running = true;
        activeSsidProc.running = true;
        btStatusProc.running = true;
        airplaneStatusProc.running = true;
        nlStatusProc.running = true;
        gameModeStatusProc.running = true;
    }

    Component.onCompleted: refresh()

    Connections {
        target: (typeof controlCenter !== "undefined") ? controlCenter : null
        function onRefreshRequested() { root.refresh(); }
    }


    function isTileActive(tid) {
        switch (tid) {
        case "wifi": return root.wifiEnabled;
        case "nightlight": return root.nightLightEnabled;
        case "caffeine": return SystemInfo.idleInhibited;
        case "dnd": return root.dndEnabled;
        case "mic": return root.micMuted;
        case "mute": return root.sinkMuted;
        case "gamemode": return root.gameModeEnabled;
        case "darkmode": return root.isDarkMode;
        case "bluetooth": return root.btAvailable && root.btEnabled;
        case "airplane": return root.airplaneEnabled;
        default: return false;
        }
    }

    function getTileIcon(tid) {
        switch (tid) {
        case "wifi": return root.wifiEnabled ? "󰖩" : "󰖪";
        case "nightlight": return root.nightLightEnabled ? "󰛨" : "󰛩";
        case "caffeine": return SystemInfo.idleInhibited ? "" : "";
        case "dnd": return root.dndEnabled ? "󰂛" : "󰂚";
        case "mic": return root.micMuted ? "󰍭" : "󰍬";
        case "mute": return root.sinkMuted ? "󰝟" : "󰕾";
        case "gamemode": return "󰊴";
        case "clipboard": return "󰅍";
        case "darkmode": return root.isDarkMode ? "󰔎" : "󰔏";
        case "emoji": return "󰞅";
        case "screenshot": return "󰄄";
        case "lock": return "󰌾";
        case "bluetooth": return (root.btAvailable && root.btEnabled) ? "󰂯" : "󰂲";
        case "airplane": return "󰀝";
        default: return "󰒓";
        }
    }

    function triggerTileAction(tid, isRightClick) {
        switch (tid) {
        case "wifi":
            if (isRightClick) root.toggleWifi();
            else root.openWifiRequested();
            break;
        case "nightlight": root.toggleNightLight(); break;
        case "caffeine": SystemInfo.toggleIdleInhibitor(); break;
        case "dnd": root.togglednd(); break;
        case "mic": root.toggleMic(); break;
        case "mute": root.toggleSinkMute(); break;
        case "gamemode": root.toggleGameMode(); break;
        case "clipboard": root.openClipboard(); break;
        case "darkmode": root.toggleDarkMode(); break;
        case "emoji": root.openEmoji(); break;
        case "screenshot": root.takeScreenshot(); break;
        case "lock": root.lockSession(); break;
        case "bluetooth": root.toggleBt(); break;
        case "airplane": root.toggleAirplane(); break;
        }
    }

    // Empty state placeholder in live edit mode
    Rectangle {
        visible: ControlCenterConfig.isLiveEdit && (
            root.mode === "connectivity"
                ? ControlCenterConfig.groupedTiles.length === 0
                : root.activeTileModel.length === 0
        )
        Layout.fillWidth: true
        implicitHeight: 40
        radius: 8
        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
        border.color: root.theme.bgBorder
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: root.mode === "connectivity"
                ? "No connectivity tiles assigned"
                : (root.mode === "tiles2" ? "No Quick Tiles 2 assigned (click + below)" : "No quick settings tiles enabled")
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textSecondary
        }
    }

    // 1. Grouped 2x2 Connectivity Card (iOS / Android Control Center)
    QuickSettingsConnectivityGroup {
        id: tileGroupCard
        hostGrid: root
        visible: (root.mode === "connectivity" || (root.mode === "both" && ControlCenterConfig.groupTilesEnabled))
            && ControlCenterConfig.groupedTiles.length > 0
    }

    // 2. Ungrouped / Standalone Quick Tiles Grid (Primary "tiles" or Secondary "tiles2")
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: tilesGrid.implicitHeight + (root.carded ? 16 : 0)
            + (tilesTitle.visible ? tilesTitle.height + 6 : 0)
        Layout.preferredHeight: implicitHeight
        radius: 12
        color: root.carded
            ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
            : "transparent"
        border.color: root.carded ? root.theme.bgBorder : "transparent"
        border.width: root.carded ? 1 : 0
        visible: (root.mode === "tiles" || root.mode === "tiles2" || root.mode === "both" || root.isPanelTiles)
            && root.activeTileModel.length > 0

        // Card title (hidden in edit mode, where the module toolbar already shows the name)
        Text {
            id: tilesTitle
            visible: root.carded && (ControlCenterConfig.isLiveEdit || text !== "")
            readonly property string cardKey: root.mode === "tiles2" ? "quickSettings2" : "quickSettings"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 12
            anchors.topMargin: 8
            height: 14
            text: ControlCenterConfig.isLiveEdit ? "" : ControlCenterConfig.getCardTitle(cardKey)
            font.family: root.font
            font.pixelSize: 10
            font.bold: true
            color: root.theme.textSecondary

            // Inline editor (live edit): click, type, press Enter
            TextInput {
                id: tilesTitleEdit
                visible: ControlCenterConfig.isLiveEdit
                width: Math.max(80, root.width - 40)
                height: 14
                text: ControlCenterConfig.getCardTitle(tilesTitle.cardKey)
                font.family: root.font
                font.pixelSize: 10
                font.bold: true
                color: root.theme.textPrimary
                selectByMouse: true
                clip: true
                maximumLength: 28
                onEditingFinished: ControlCenterConfig.setCardTitle(tilesTitle.cardKey, text)

                Text {
                    visible: parent.text === "" && !parent.activeFocus
                    text: "Add a title…"
                    font: parent.font
                    color: root.theme.textMuted
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.bottom
                    height: 1
                    color: parent.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                }
            }
        }

        GridLayout {
            id: tilesGrid
            anchors {
                left: parent.left
                right: parent.right
                top: tilesTitle.visible ? tilesTitle.bottom : parent.top
                topMargin: root.carded ? (tilesTitle.visible ? 6 : 8) : 0
                leftMargin: root.carded ? 8 : 0
                rightMargin: root.carded ? 8 : 0
            }
            columns: 2
            rowSpacing: 8
            columnSpacing: 8
            uniformCellWidths: true

            Repeater {
                id: tilesRepeater
                model: root.activeTileModel

                delegate: QuickSettingsTileButton {
                    hostGrid: root
                }
            }
        }
    }

    // Quick Add Tile row in Live Edit Mode (always available while tiles remain unassigned)
    Flow {
        visible: ControlCenterConfig.isLiveEdit
            && ControlCenterConfig.unassignedTiles.length > 0
            && ((root.mode === "tiles" || root.mode === "tiles2")
                || (root.mode === "connectivity" && ControlCenterConfig.groupedTiles.length < ControlCenterConfig.groupCapacity))
        Layout.fillWidth: true
        spacing: 5

        Repeater {
            model: ControlCenterConfig.unassignedTiles
            delegate: Rectangle {
                required property var modelData
                height: 24
                implicitWidth: addTileRow.implicitWidth + 14
                radius: 12
                color: addTileMouse.containsMouse
                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.18)
                    : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
                border.color: addTileMouse.containsMouse ? root.theme.accentPrimary : root.theme.bgBorder
                border.width: 1

                Row {
                    id: addTileRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: (modelData.icon || "󰒓")
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.accentPrimary
                    }

                    Text {
                        text: modelData.label || ""
                        font.family: root.font
                        font.pixelSize: 10
                        color: root.theme.textPrimary
                    }
                }

                MouseArea {
                    id: addTileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.mode === "connectivity") {
                            ControlCenterConfig.setGroupTilesEnabled(true);
                            ControlCenterConfig.addTileToGroup(modelData.id);
                        } else if (root.mode === "tiles2") {
                            ControlCenterConfig.addTileToSecondary(modelData.id);
                        } else {
                            ControlCenterConfig.setTileEnabled(modelData.id, true);
                        }
                    }
                }
            }
        }
    }

    // Floating drag ghost for live edit mode
    QuickSettingsTileDragGhost {
        id: dragGhost
        hostGrid: root
    }
}
