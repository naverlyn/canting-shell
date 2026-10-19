import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../bar"
import ".."

ColumnLayout {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"

    // Toggle states
    property bool wifiEnabled: true
    property string currentSsid: ""
    property bool btEnabled: false
    property bool btAvailable: false
    property bool dndEnabled: false
    property bool airplaneEnabled: false
    property bool nightLightEnabled: false
    property bool gameModeEnabled: false
    property bool isDarkMode: true

    readonly property bool micMuted: {
        if (!Pipewire.defaultAudioSource || !Pipewire.defaultAudioSource.audio) return false;
        return Pipewire.defaultAudioSource.audio.muted;
    }

    readonly property bool sinkMuted: {
        if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return false;
        return Pipewire.defaultAudioSink.audio.muted;
    }

    readonly property string nightLightScript: Qt.resolvedUrl("../scripts/nightlight.sh").toString().replace(/^file:\/\//, "")

    signal openWifiRequested()
    signal closeParentRequested()

    // Drag & Drop State for Live Edit Mode
    property bool isDragging: false
    property string draggedTileId: ""
    property int dragSourceIndex: -1
    property int dragHoverIndex: -1
    property real dragMouseX: 0
    property real dragMouseY: 0

    function startTileDrag(tid, srcIdx, rootX, rootY) {
        draggedTileId = tid;
        dragSourceIndex = srcIdx;
        dragHoverIndex = srcIdx;
        dragMouseX = rootX;
        dragMouseY = rootY;
        isDragging = true;
    }

    function updateTileDrag(rootX, rootY) {
        dragMouseX = rootX;
        dragMouseY = rootY;
        if (!isDragging) return;
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

    function finishTileDrag() {
        if (!isDragging) return;
        const srcIdx = dragSourceIndex;
        const targetIdx = dragHoverIndex;
        isDragging = false;
        draggedTileId = "";
        dragHoverIndex = -1;
        dragSourceIndex = -1;
        if (srcIdx >= 0 && targetIdx >= 0 && srcIdx !== targetIdx) {
            ControlCenterConfig.moveEnabledTile(srcIdx, targetIdx);
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

    // DND Processes
    Process {
        id: dndProc
        command: ["swaync-client", "-d"]
        running: false
    }

    Process {
        id: dndStatusProc
        command: ["swaync-client", "-D"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.dndEnabled = (text.trim() === "true");
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
        command: ["sh", "-c", "$HOME/.config/hypr/scripts/GameMode.sh"]
        running: false
        onExited: gameModeStatusProc.running = true
    }

    // Dark / Light Mode Processes
    Process {
        id: darkStatusProc
        command: ["sh", "-c", "cat $HOME/.cache/.theme_mode 2>/dev/null || echo 'Dark'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.isDarkMode = (text.trim() !== "Light");
            }
        }
    }

    Process {
        id: darkToggleProc
        command: ["sh", "-c", "$HOME/.config/hypr/scripts/DarkLight.sh"]
        running: false
        onExited: darkStatusProc.running = true
    }

    // Clipboard Process
    Process {
        id: clipProc
        command: ["sh", "-c", "qs ipc call clipboard toggle 2>/dev/null || quickshell ipc call clipboard toggle 2>/dev/null || $HOME/.config/hypr/scripts/ClipManager.sh"]
        running: false
    }

    // Emoji Process
    Process {
        id: emojiProc
        command: ["sh", "-c", "$HOME/.config/hypr/scripts/RofiEmoji.sh"]
        running: false
    }

    // Screenshot Process
    Process {
        id: screenshotProc
        command: ["sh", "-c", "sleep 0.2 && ($HOME/.config/hypr/scripts/ScreenShot.sh --area || grimblast copy area || hyprshot -m region)"]
        running: false
    }

    // Lock Process
    Process {
        id: lockProc
        command: ["sh", "-c", "hyprlock"]
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
        btProc.command = ["bluetoothctl", "power", targetState ? "on" : "off"];
        btProc.running = true;
    }

    function togglednd() {
        root.dndEnabled = !root.dndEnabled;
        dndProc.running = true;
    }

    function toggleAirplane() {
        const notifIcon = "$HOME/.config/swaync/images/ja.png";
        if (root.airplaneEnabled) {
            root.airplaneEnabled = false;
            root.wifiEnabled = true;
            airplaneProc.command = [
                "sh", "-c",
                `rfkill unblock wifi && notify-send -u low -i "${notifIcon}" " Airplane" " mode: OFF"`
            ];
        } else {
            root.airplaneEnabled = true;
            root.wifiEnabled = false;
            root.currentSsid = "";
            airplaneProc.command = [
                "sh", "-c",
                `rfkill block wifi && notify-send -u low -i "${notifIcon}" " Airplane" " mode: ON"`
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
        darkToggleProc.running = true;
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
        dndStatusProc.running = true;
        airplaneStatusProc.running = true;
        nlStatusProc.running = true;
        gameModeStatusProc.running = true;
        darkStatusProc.running = true;
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
        visible: ControlCenterConfig.isLiveEdit && ControlCenterConfig.enabledTiles.length === 0
        Layout.fillWidth: true
        implicitHeight: 40
        radius: 8
        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
        border.color: root.theme.bgBorder
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "No quick settings tiles enabled"
            font.family: root.font
            font.pixelSize: 11
            color: root.theme.textSecondary
        }
    }

    // 1. Grouped 2x2 Connectivity Card (iOS / Android Control Center)
    Rectangle {
        id: tileGroupCard
        visible: ControlCenterConfig.groupTilesEnabled && ControlCenterConfig.groupedTiles.length > 0
        Layout.fillWidth: true
        implicitHeight: groupGrid.implicitHeight + 16
        radius: 12
        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
        border.color: root.theme.bgBorder
        border.width: 1

        GridLayout {
            id: groupGrid
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
            }
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: ControlCenterConfig.groupedTiles
                delegate: Rectangle {
                    id: groupTileBtn
                    required property var modelData
                    required property int index
                    readonly property string tid: modelData.id
                    readonly property bool isActive: root.isTileActive(groupTileBtn.tid)
                    readonly property bool isHovered: groupTileHover.hovered

                    Layout.fillWidth: true
                    height: 50
                    radius: 10
                    color: {
                        if (groupTileBtn.tid === "mic" && root.micMuted) return Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.25);
                        if (groupTileBtn.tid === "mute" && root.sinkMuted) return Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.25);
                        if (isActive) return isHovered ? Qt.lighter(root.theme.accentPrimary, 1.12) : root.theme.accentPrimary;
                        return isHovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12) : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06);
                    }
                    border.color: isActive ? "transparent" : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 130 } }

                    HoverHandler { id: groupTileHover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: groupTileBtn.isActive ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.10)
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                font.family: root.font
                                font.pixelSize: 14
                                color: groupTileBtn.isActive ? (root.theme.bgBase ?? "#ffffff") : root.theme.textPrimary
                                text: root.getTileIcon(groupTileBtn.tid)
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: groupTileBtn.modelData.label ?? ""
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: true
                                color: groupTileBtn.isActive ? (root.theme.bgBase ?? "#ffffff") : root.theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: {
                                    if (groupTileBtn.tid === "wifi") return root.wifiEnabled ? (root.currentSsid || "On") : "Off";
                                    if (groupTileBtn.tid === "bluetooth") return (root.btAvailable && root.btEnabled) ? "On" : "Off";
                                    if (groupTileBtn.tid === "airplane") return root.airplaneEnabled ? "On" : "Off";
                                    if (groupTileBtn.tid === "dnd") return root.dndEnabled ? "On" : "Off";
                                    return groupTileBtn.isActive ? "On" : "Off";
                                }
                                font.family: root.font
                                font.pixelSize: 9
                                color: groupTileBtn.isActive ? Qt.rgba(1, 1, 1, 0.75) : root.theme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => root.triggerTileAction(groupTileBtn.tid, mouse.button === Qt.RightButton)
                    }
                }
            }
        }
    }

    // 2. Ungrouped / Standalone Quick Tiles Grid
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 8
        columnSpacing: 8
        visible: (ControlCenterConfig.groupTilesEnabled ? ControlCenterConfig.ungroupedTiles.length : ControlCenterConfig.enabledTiles.length) > 0

        Repeater {
            id: tilesRepeater
            model: ControlCenterConfig.groupTilesEnabled ? ControlCenterConfig.ungroupedTiles : ControlCenterConfig.enabledTiles

            delegate: Rectangle {
                id: tileBtn
                required property var modelData
                required property int index

                readonly property string tid: modelData.id
                readonly property bool isLastOdd: (tileBtn.index === ControlCenterConfig.enabledTiles.length - 1) && (ControlCenterConfig.enabledTiles.length % 2 === 1)
                readonly property bool isBeingDragged: root.isDragging && root.draggedTileId === tileBtn.tid
                readonly property bool isDropTarget: root.isDragging && root.dragHoverIndex === tileBtn.index && root.draggedTileId !== tileBtn.tid

                Layout.fillWidth: true
                Layout.columnSpan: isLastOdd ? 2 : 1
                Layout.preferredHeight: 40
                implicitHeight: 40
                height: 40
                radius: 8

                scale: isBeingDragged ? 0.94 : (isDropTarget ? 1.04 : (tileClickArea.pressed ? 0.98 : 1.0))

                // Determine active state per tile
                readonly property bool isActive: {
                    switch (tileBtn.tid) {
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

                readonly property bool isAvailable: {
                    if (tileBtn.tid === "bluetooth") return root.btAvailable;
                    return true;
                }

                readonly property bool isHovered: ControlCenterConfig.isLiveEdit ? editDragArea.containsMouse : tileClickArea.containsMouse

                opacity: isBeingDragged ? 0.35 : (isAvailable ? 1.0 : 0.55)

                // Tile background color
                color: {
                    if (tileBtn.tid === "mic" && root.micMuted) {
                        return isHovered
                            ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.30)
                            : Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.22);
                    }
                    if (tileBtn.tid === "mute" && root.sinkMuted) {
                        return isHovered
                            ? Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.30)
                            : Qt.rgba(root.theme.accentRed.r, root.theme.accentRed.g, root.theme.accentRed.b, 0.22);
                    }
                    if (isActive) {
                        return isHovered
                            ? Qt.lighter(root.theme.accentPrimary, 1.12)
                            : root.theme.accentPrimary;
                    }
                    if (isHovered) {
                        return Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12);
                    }
                    return Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06);
                }

                border.color: {
                    if (isDropTarget) {
                        return root.theme.accentPrimary;
                    }
                    if (ControlCenterConfig.isLiveEdit) {
                        return isHovered ? root.theme.accentPrimary : Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.45);
                    }
                    if ((tileBtn.tid === "mic" && root.micMuted) || (tileBtn.tid === "mute" && root.sinkMuted)) {
                        return root.theme.accentRed;
                    }
                    if (isActive) return "transparent";
                    return root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08);
                }
                border.width: (isDropTarget || ControlCenterConfig.isLiveEdit) ? 1.5 : 1

                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                // Display icon & label
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        id: tileIcon
                        font.family: root.font
                        font.pixelSize: 16
                        color: {
                            if ((tileBtn.tid === "mic" && root.micMuted) || (tileBtn.tid === "mute" && root.sinkMuted)) {
                                return root.theme.accentRed;
                            }
                            return tileBtn.isActive ? root.theme.bgBase : root.theme.textPrimary;
                        }
                        text: {
                            switch (tileBtn.tid) {
                            case "wifi": return root.wifiEnabled ? "󰖩" : "󰖪";
                            case "nightlight": return root.nightLightEnabled ? "󰛨" : "󰛩";
                            case "caffeine": return SystemInfo.idleInhibited ? "" : "";
                            case "dnd": return root.dndEnabled ? "󰂛" : "󰂚";
                            case "mic": return root.micMuted ? "󰍭" : "󰍬";
                            case "mute": return root.sinkMuted ? "󰝟" : "󰕾";
                            case "gamemode": return "󰊴";
                            case "clipboard": return "󰅍";
                            case "darkmode": return root.isDarkMode ? "󰔎" : "󰃚";
                            case "emoji": return "󰞅";
                            case "screenshot": return "󰄄";
                            case "lock": return "󰌾";
                            case "bluetooth": return (root.btAvailable && root.btEnabled) ? "󰂯" : "󰂲";
                            case "airplane": return root.airplaneEnabled ? "󰀝" : "󰀞";
                            default: return tileBtn.modelData.icon ?? "󰅃";
                            }
                        }
                    }

                    Text {
                        id: tileLabel
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: tileBtn.isActive
                        elide: Text.ElideRight
                        Layout.maximumWidth: tileBtn.isLastOdd ? 200 : 100
                        color: {
                            if ((tileBtn.tid === "mic" && root.micMuted) || (tileBtn.tid === "mute" && root.sinkMuted)) {
                                return root.theme.accentRed;
                            }
                            return tileBtn.isActive ? root.theme.bgBase : root.theme.textPrimary;
                        }
                        text: {
                            switch (tileBtn.tid) {
                            case "wifi":
                                return (root.wifiEnabled && root.currentSsid !== "") ? root.currentSsid : "Wi-Fi";
                            case "nightlight":
                                return "Night Light";
                            case "caffeine":
                                return SystemInfo.idleInhibited ? "Awake: On" : "Keep Awake";
                            case "dnd":
                                return root.dndEnabled ? "DND: On" : "DND";
                            case "mic":
                                return root.micMuted ? "Mic Muted" : "Microphone";
                            case "mute":
                                return root.sinkMuted ? "Audio Muted" : "Mute Audio";
                            case "gamemode":
                                return root.gameModeEnabled ? "Game: On" : "Game Mode";
                            case "clipboard":
                                return "Clipboard";
                            case "darkmode":
                                return root.isDarkMode ? "Dark Mode" : "Light Mode";
                            case "emoji":
                                return "Emoji Picker";
                            case "screenshot":
                                return "Screenshot";
                            case "lock":
                                return "Lock";
                            case "bluetooth":
                                return root.btAvailable ? (root.btEnabled ? "Bluetooth" : "Bluetooth: Off") : "No BT";
                            case "airplane":
                                return root.airplaneEnabled ? "Airplane: On" : "Airplane";
                            default:
                                return tileBtn.modelData.label ?? "";
                            }
                        }
                    }
                }

                // Drag-and-drop MouseArea in live edit mode
                MouseArea {
                    id: editDragArea
                    anchors.fill: parent
                    hoverEnabled: true
                    visible: ControlCenterConfig.isLiveEdit
                    preventStealing: true
                    cursorShape: root.isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                    property real pressX: 0
                    property real pressY: 0
                    property bool dragStarted: false

                    onPressed: (mouse) => {
                        pressX = mouse.x;
                        pressY = mouse.y;
                        dragStarted = false;
                    }

                    onPositionChanged: (mouse) => {
                        if (!pressed) return;
                        const pt = editDragArea.mapToItem(root, mouse.x, mouse.y);
                        if (!dragStarted && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 5) {
                            dragStarted = true;
                            root.startTileDrag(tileBtn.tid, tileBtn.index, pt.x, pt.y);
                        } else if (dragStarted) {
                            root.updateTileDrag(pt.x, pt.y);
                        }
                    }

                    onReleased: (mouse) => {
                        if (dragStarted) {
                            const pt = editDragArea.mapToItem(root, mouse.x, mouse.y);
                            root.updateTileDrag(pt.x, pt.y);
                            root.finishTileDrag();
                            dragStarted = false;
                        }
                    }

                    onCanceled: {
                        if (dragStarted) {
                            root.finishTileDrag();
                            dragStarted = false;
                        }
                    }
                }

                // Remove ✕ badge in live edit mode
                Rectangle {
                    visible: ControlCenterConfig.isLiveEdit
                    width: 18
                    height: 18
                    radius: 9
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -4
                    anchors.rightMargin: -4
                    color: removeClickArea.containsMouse ? Qt.lighter(root.theme.accentRed ?? "#e05252", 1.15) : (root.theme.accentRed ?? "#e05252")
                    border.color: "#ffffff"
                    border.width: 1
                    z: 15

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 9
                        font.bold: true
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: removeClickArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        onClicked: ControlCenterConfig.removeTile(tileBtn.tid)
                    }
                }

                MouseArea {
                    id: tileClickArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !ControlCenterConfig.isLiveEdit
                    acceptedButtons: tileBtn.tid === "wifi" ? (Qt.LeftButton | Qt.RightButton) : Qt.LeftButton
                    cursorShape: tileBtn.isAvailable ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                    preventStealing: true

                    onClicked: (mouse) => {

                        switch (tileBtn.tid) {
                        case "wifi":
                            if (mouse.button === Qt.RightButton) {
                                root.toggleWifi();
                            } else {
                                root.openWifiRequested();
                            }
                            break;
                        case "nightlight":
                            root.toggleNightLight();
                            break;
                        case "caffeine":
                            SystemInfo.toggleIdleInhibitor();
                            break;
                        case "dnd":
                            root.togglednd();
                            break;
                        case "mic":
                            root.toggleMic();
                            break;
                        case "mute":
                            root.toggleSinkMute();
                            break;
                        case "gamemode":
                            root.toggleGameMode();
                            break;
                        case "clipboard":
                            root.openClipboard();
                            break;
                        case "darkmode":
                            root.toggleDarkMode();
                            break;
                        case "emoji":
                            root.openEmoji();
                            break;
                        case "screenshot":
                            root.takeScreenshot();
                            break;
                        case "lock":
                            root.lockSession();
                            break;
                        case "bluetooth":
                            root.toggleBt();
                            break;
                        case "airplane":
                            root.toggleAirplane();
                            break;
                    }
                }
            }
        }
    }
}

    // Floating drag ghost for live edit mode
    Rectangle {
        id: dragGhost
        readonly property bool active: root.isDragging && root.draggedTileId !== ""
        visible: opacity > 0.01
        z: 9999
        width: 140
        height: 40
        radius: 8
        color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.22)
        border.color: root.theme.accentPrimary
        border.width: 1.5
        scale: active ? 1.05 : 0.85
        opacity: active ? 0.95 : 0.0
        x: Math.max(0, Math.min(root.width - width, root.dragMouseX - (width / 2)))
        y: Math.max(0, Math.min(root.height - height, root.dragMouseY - (height / 2)))

        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
                font.family: root.font
                font.pixelSize: 15
                color: root.theme.accentPrimary
                text: {
                    const def = ControlCenterConfig.getTileDef(root.draggedTileId);
                    return def ? def.icon : "󰒓";
                }
            }

            Text {
                font.family: root.font
                font.pixelSize: 12
                font.bold: true
                color: root.theme.textPrimary
                text: {
                    const def = ControlCenterConfig.getTileDef(root.draggedTileId);
                    return def ? def.label : "";
                }
            }
        }
    }

}

