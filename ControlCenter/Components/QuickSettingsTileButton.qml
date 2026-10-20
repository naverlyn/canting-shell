import QtQuick
import QtQuick.Layouts
import "../../bar"
import ".."

            Rectangle {
                id: tileBtn
    required property var hostGrid
                required property var modelData
                required property int index

                readonly property string tid: modelData.id
                readonly property var activeTileList: hostGrid.activeTileModel
                readonly property bool isLastOdd: (tileBtn.index === activeTileList.length - 1) && (activeTileList.length % 2 === 1)
                readonly property bool isBeingDragged: hostGrid.isDragging && hostGrid.draggedTileId === tileBtn.tid
                readonly property bool isDropTarget: hostGrid.isDragging && hostGrid.dragHoverIndex === tileBtn.index && hostGrid.draggedTileId !== tileBtn.tid
                readonly property real singleColWidth: Math.max(80, Math.floor((hostGrid.width - 8) / 2))

                Layout.fillWidth: true
                Layout.preferredWidth: isLastOdd ? hostGrid.width : singleColWidth
                Layout.minimumWidth: isLastOdd ? hostGrid.width : singleColWidth
                Layout.maximumWidth: isLastOdd ? hostGrid.width : singleColWidth
                Layout.columnSpan: isLastOdd ? 2 : 1
                Layout.preferredHeight: 40
                implicitHeight: 40
                height: 40
                radius: 8

                scale: isBeingDragged ? 0.94 : (isDropTarget ? 1.04 : (tileClickArea.pressed ? 0.98 : 1.0))

                // Determine active state per tile
                readonly property bool isActive: {
                    switch (tileBtn.tid) {
                    case "wifi": return hostGrid.wifiEnabled;
                    case "nightlight": return hostGrid.nightLightEnabled;
                    case "caffeine": return SystemInfo.idleInhibited;
                    case "dnd": return hostGrid.dndEnabled;
                    case "mic": return hostGrid.micMuted;
                    case "mute": return hostGrid.sinkMuted;
                    case "gamemode": return hostGrid.gameModeEnabled;
                    case "darkmode": return hostGrid.isDarkMode;
                    case "bluetooth": return hostGrid.btAvailable && hostGrid.btEnabled;
                    case "airplane": return hostGrid.airplaneEnabled;
                    default: return false;
                    }
                }

                readonly property bool isAvailable: {
                    if (tileBtn.tid === "bluetooth") return hostGrid.btAvailable;
                    return true;
                }

                readonly property bool isHovered: ControlCenterConfig.isLiveEdit ? editDragArea.containsMouse : tileClickArea.containsMouse

                opacity: isBeingDragged ? 0.35 : (isAvailable ? 1.0 : 0.55)

                // Tile background color
                color: {
                    if (tileBtn.tid === "mic" && hostGrid.micMuted) {
                        return isHovered
                            ? Qt.rgba(hostGrid.theme.accentRed.r, hostGrid.theme.accentRed.g, hostGrid.theme.accentRed.b, 0.30)
                            : Qt.rgba(hostGrid.theme.accentRed.r, hostGrid.theme.accentRed.g, hostGrid.theme.accentRed.b, 0.22);
                    }
                    if (tileBtn.tid === "mute" && hostGrid.sinkMuted) {
                        return isHovered
                            ? Qt.rgba(hostGrid.theme.accentRed.r, hostGrid.theme.accentRed.g, hostGrid.theme.accentRed.b, 0.30)
                            : Qt.rgba(hostGrid.theme.accentRed.r, hostGrid.theme.accentRed.g, hostGrid.theme.accentRed.b, 0.22);
                    }
                    if (isActive) {
                        return isHovered
                            ? Qt.lighter(hostGrid.theme.accentPrimary, 1.12)
                            : hostGrid.theme.accentPrimary;
                    }
                    if (isHovered) {
                        return Qt.rgba(hostGrid.theme.textPrimary.r, hostGrid.theme.textPrimary.g, hostGrid.theme.textPrimary.b, 0.12);
                    }
                    return Qt.rgba(hostGrid.theme.textPrimary.r, hostGrid.theme.textPrimary.g, hostGrid.theme.textPrimary.b, 0.06);
                }

                border.color: {
                    if (isDropTarget) {
                        return hostGrid.theme.accentPrimary;
                    }
                    if (ControlCenterConfig.isLiveEdit) {
                        return isHovered ? hostGrid.theme.accentPrimary : Qt.rgba(hostGrid.theme.accentPrimary.r, hostGrid.theme.accentPrimary.g, hostGrid.theme.accentPrimary.b, 0.45);
                    }
                    if ((tileBtn.tid === "mic" && hostGrid.micMuted) || (tileBtn.tid === "mute" && hostGrid.sinkMuted)) {
                        return hostGrid.theme.accentRed;
                    }
                    if (isActive) return "transparent";
                    return hostGrid.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08);
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
                        font.family: hostGrid.font
                        font.pixelSize: 16
                        color: {
                            if ((tileBtn.tid === "mic" && hostGrid.micMuted) || (tileBtn.tid === "mute" && hostGrid.sinkMuted)) {
                                return hostGrid.theme.accentRed;
                            }
                            return tileBtn.isActive ? hostGrid.theme.bgBase : hostGrid.theme.textPrimary;
                        }
                        text: {
                            switch (tileBtn.tid) {
                            case "wifi": return hostGrid.wifiEnabled ? "󰖩" : "󰖪";
                            case "nightlight": return hostGrid.nightLightEnabled ? "󰛨" : "󰛩";
                            case "caffeine": return SystemInfo.idleInhibited ? "" : "";
                            case "dnd": return hostGrid.dndEnabled ? "󰂛" : "󰂚";
                            case "mic": return hostGrid.micMuted ? "󰍭" : "󰍬";
                            case "mute": return hostGrid.sinkMuted ? "󰝟" : "󰕾";
                            case "gamemode": return "󰊴";
                            case "clipboard": return "󰅍";
                            case "darkmode": return hostGrid.isDarkMode ? "󰔎" : "󰃚";
                            case "emoji": return "󰞅";
                            case "screenshot": return "󰄄";
                            case "lock": return "󰌾";
                            case "bluetooth": return (hostGrid.btAvailable && hostGrid.btEnabled) ? "󰂯" : "󰂲";
                            case "airplane": return hostGrid.airplaneEnabled ? "󰀝" : "󰀞";
                            default: return tileBtn.modelData.icon ?? "󰅃";
                            }
                        }
                    }

                    Text {
                        id: tileLabel
                        font.family: hostGrid.font
                        font.pixelSize: 12
                        font.bold: tileBtn.isActive
                        elide: Text.ElideRight
                        Layout.maximumWidth: tileBtn.isLastOdd ? 200 : 100
                        color: {
                            if ((tileBtn.tid === "mic" && hostGrid.micMuted) || (tileBtn.tid === "mute" && hostGrid.sinkMuted)) {
                                return hostGrid.theme.accentRed;
                            }
                            return tileBtn.isActive ? hostGrid.theme.bgBase : hostGrid.theme.textPrimary;
                        }
                        text: {
                            switch (tileBtn.tid) {
                            case "wifi":
                                return (hostGrid.wifiEnabled && hostGrid.currentSsid !== "") ? hostGrid.currentSsid : "Wi-Fi";
                            case "nightlight":
                                return "Night Light";
                            case "caffeine":
                                return SystemInfo.idleInhibited ? "Awake: On" : "Keep Awake";
                            case "dnd":
                                return hostGrid.dndEnabled ? "DND: On" : "DND";
                            case "mic":
                                return hostGrid.micMuted ? "Mic Muted" : "Microphone";
                            case "mute":
                                return hostGrid.sinkMuted ? "Audio Muted" : "Mute Audio";
                            case "gamemode":
                                return hostGrid.gameModeEnabled ? "Game: On" : "Game Mode";
                            case "clipboard":
                                return "Clipboard";
                            case "darkmode":
                                return hostGrid.isDarkMode ? "Dark Mode" : "Light Mode";
                            case "emoji":
                                return "Emoji Picker";
                            case "screenshot":
                                return "Screenshot";
                            case "lock":
                                return "Lock";
                            case "bluetooth":
                                return hostGrid.btAvailable ? (hostGrid.btEnabled ? "Bluetooth" : "Bluetooth: Off") : "No BT";
                            case "airplane":
                                return hostGrid.airplaneEnabled ? "Airplane: On" : "Airplane";
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
                    cursorShape: hostGrid.isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

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
                        const pt = editDragArea.mapToItem(hostGrid, mouse.x, mouse.y);
                        if (!dragStarted && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 5) {
                            dragStarted = true;
                            hostGrid.startTileDrag(tileBtn.tid, tileBtn.index, pt.x, pt.y);
                        } else if (dragStarted) {
                            hostGrid.updateTileDrag(pt.x, pt.y);
                        }
                    }

                    onReleased: (mouse) => {
                        if (dragStarted) {
                            const pt = editDragArea.mapToItem(hostGrid, mouse.x, mouse.y);
                            hostGrid.updateTileDrag(pt.x, pt.y);
                            hostGrid.finishTileDrag();
                            dragStarted = false;
                        }
                    }

                    onCanceled: {
                        if (dragStarted) {
                            hostGrid.finishTileDrag();
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
                    color: removeClickArea.containsMouse ? Qt.lighter(hostGrid.theme.accentRed ?? "#e05252", 1.15) : (hostGrid.theme.accentRed ?? "#e05252")
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
                                hostGrid.toggleWifi();
                            } else {
                                hostGrid.openWifiRequested();
                            }
                            break;
                        case "nightlight":
                            hostGrid.toggleNightLight();
                            break;
                        case "caffeine":
                            SystemInfo.toggleIdleInhibitor();
                            break;
                        case "dnd":
                            hostGrid.togglednd();
                            break;
                        case "mic":
                            hostGrid.toggleMic();
                            break;
                        case "mute":
                            hostGrid.toggleSinkMute();
                            break;
                        case "gamemode":
                            hostGrid.toggleGameMode();
                            break;
                        case "clipboard":
                            hostGrid.openClipboard();
                            break;
                        case "darkmode":
                            hostGrid.toggleDarkMode();
                            break;
                        case "emoji":
                            hostGrid.openEmoji();
                            break;
                        case "screenshot":
                            hostGrid.takeScreenshot();
                            break;
                        case "lock":
                            hostGrid.lockSession();
                            break;
                        case "bluetooth":
                            hostGrid.toggleBt();
                            break;
                        case "airplane":
                            hostGrid.toggleAirplane();
                            break;
                    }
                }
            }
        }
