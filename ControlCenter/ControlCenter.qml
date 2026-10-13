import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "./Components"
import "../bar"

PanelWindow {
    id: controlCenter

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"
    property var anchorTarget
    property string barPosition: BarConfig.position
    property int barThickness: BarConfig.barHeight
    property bool barFloating: BarConfig.floating
    property int barWindowWidth: 0
    property int barWindowHeight: 0

    property bool viewNotifications: false

    property real anchorCenterX: 0
    property real anchorCenterY: 0
    property real targetWinWidth: 1920
    property real targetWinHeight: 1080

    function updateAnchorMetrics() {
        if (!anchorTarget || !anchorTarget.QsWindow || !anchorTarget.QsWindow.window) return;
        const win = anchorTarget.QsWindow.window;
        targetWinWidth = win.width > 0 ? win.width : (screen ? screen.width : 1920);
        targetWinHeight = win.height > 0 ? win.height : (screen ? screen.height : 1080);
        const pt = anchorTarget.mapToItem(null, anchorTarget.width / 2, anchorTarget.height / 2);
        anchorCenterX = pt.x;
        anchorCenterY = pt.y;
    }

    function edgeBarClearance(edgePos) {
        const list = BarConfig.bars || [];
        let maxClearance = 0;
        for (let i = 0; i < list.length; i++) {
            const b = list[i];
            if (!b || b.enabled === false || b.position !== edgePos) continue;
            const h = b.barHeight !== undefined ? b.barHeight : 38;
            const fl = b.floating !== undefined ? b.floating : false;
            const isV = (edgePos === "left" || edgePos === "right");
            const c = isV ? (h + 16 + (fl ? 12 : 0)) : (h + (fl ? 12 : 6));
            if (c > maxClearance) maxClearance = c;
        }
        return maxClearance;
    }

    readonly property bool isVertBar: barPosition === "left" || barPosition === "right"
    readonly property bool isHorizLeftPanel: !isVertBar && (anchorCenterX > 0 && anchorCenterX < targetWinWidth * 0.38)
    readonly property bool isHorizCenterPanel: !isVertBar && (anchorCenterX >= targetWinWidth * 0.38 && anchorCenterX <= targetWinWidth * 0.62)
    readonly property bool isVertBottomPanel: isVertBar && (anchorCenterY > targetWinHeight * 0.62)
    readonly property bool isVertCenterPanel: isVertBar && (anchorCenterY >= targetWinHeight * 0.38 && anchorCenterY <= targetWinHeight * 0.62)

    readonly property int ownHorizClearance: Math.max(barWindowHeight, barThickness + (barFloating ? 12 : 6)) + 6
    readonly property int ownVertClearance: Math.max(barWindowWidth, barThickness + 16 + (barFloating ? 12 : 0)) + 8

    screen: (anchorTarget && anchorTarget.QsWindow.window) ? anchorTarget.QsWindow.window.screen : null
    anchors {
        top: controlCenter.barPosition !== "bottom"
        bottom: controlCenter.barPosition === "bottom"
        left: controlCenter.barPosition === "left" || controlCenter.isHorizLeftPanel || controlCenter.isHorizCenterPanel
        right: controlCenter.barPosition === "right" || (!controlCenter.isVertBar && !controlCenter.isHorizLeftPanel && !controlCenter.isHorizCenterPanel)
    }
    margins {
        top: controlCenter.barPosition === "top"
            ? controlCenter.ownHorizClearance
            : Math.max(10, controlCenter.edgeBarClearance("top") + 8)
        bottom: controlCenter.barPosition === "bottom"
            ? controlCenter.ownHorizClearance
            : Math.max(10, controlCenter.edgeBarClearance("bottom") + 8)
        left: {
            if (controlCenter.barPosition === "left") return controlCenter.ownVertClearance;
            if (controlCenter.isHorizCenterPanel) {
                return Math.max(10, Math.round(controlCenter.anchorCenterX - (controlCenter.implicitWidth / 2)));
            }
            if (controlCenter.isHorizLeftPanel) {
                return Math.max(10, controlCenter.edgeBarClearance("left") + 10);
            }
            return 0;
        }
        right: {
            if (controlCenter.barPosition === "right") return controlCenter.ownVertClearance;
            if (!controlCenter.isVertBar && !controlCenter.isHorizLeftPanel && !controlCenter.isHorizCenterPanel) {
                return Math.max(10, controlCenter.edgeBarClearance("right") + 10);
            }
            return 0;
        }
    }
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay

    visible: false
    implicitWidth: 320
    implicitHeight: (screen ? screen.height : 1080) - margins.top - margins.bottom
    mask: Region { item: ccMainRect }
    color: "transparent"

    HyprlandFocusGrab {
        windows: controlCenter.anchorTarget
            ? [controlCenter, controlCenter.anchorTarget.QsWindow.window]
            : [controlCenter]
        active: controlCenter.visible
        onCleared: controlCenter.visible = false
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: controlCenter.visible
        onActivated: controlCenter.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            updateAnchorMetrics();
            brightnessSlider.refresh();
            quickSettings.refresh();
            ccMainRect.forceActiveFocus();
        }
    }

    Component.onCompleted: updateAnchorMetrics()

    Rectangle {
        id: ccMainRect
        anchors {
            top: (!controlCenter.isVertBar && controlCenter.barPosition !== "bottom") || (controlCenter.isVertBar && !controlCenter.isVertBottomPanel && !controlCenter.isVertCenterPanel)
                ? parent.top
                : undefined
            bottom: (controlCenter.barPosition === "bottom") || (controlCenter.isVertBar && controlCenter.isVertBottomPanel)
                ? parent.bottom
                : undefined
            left: parent.left
            right: parent.right
        }
        y: (controlCenter.isVertBar && controlCenter.isVertCenterPanel)
            ? Math.max(0, Math.min(parent.height - height, Math.round(controlCenter.anchorCenterY - controlCenter.margins.top - (height / 2))))
            : 0
        height: contentColumn.implicitHeight + 24
        radius: 12
        color: controlCenter.theme.bgSurface
        border.color: controlCenter.theme.bgBorder
        border.width: 1

        focus: true
        Keys.onEscapePressed: controlCenter.visible = false

        opacity: controlCenter.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Column {
            id: contentColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 12

            // Top Header: Profile, Battery, Settings, Power
            ControlCenterHeader {
                id: header
                width: parent.width
                theme: controlCenter.theme
                font: controlCenter.font
                onCloseRequested: controlCenter.visible = false
            }

            // Tab Switcher: Control Center / Notifications
            ViewSwitcher {
                id: switcher
                width: parent.width
                theme: controlCenter.theme
                font: controlCenter.font
                viewNotifications: controlCenter.viewNotifications
                onViewNotificationsChanged: controlCenter.viewNotifications = viewNotifications
            }

            // Main Content Container
            Item {
                width: parent.width
                height: (controlCenter.viewNotifications && notificationsView.historyModel.length > 0)
                    ? notificationsView.implicitHeight
                    : controlCenterView.implicitHeight
                clip: true
                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                // 1. Control Center View
                Column {
                    id: controlCenterView
                    width: parent.width
                    opacity: controlCenter.viewNotifications ? 0 : 1
                    x: controlCenter.viewNotifications ? -30 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    spacing: 12

                    // Quick Settings Toggles (Wi-Fi, Bluetooth, Airplane, DND)
                    QuickSettingsGrid {
                        id: quickSettings
                        width: parent.width
                        theme: controlCenter.theme
                        font: controlCenter.font
                        onOpenWifiRequested: {
                            controlCenter.visible = false;
                            wifiModal.visible = true;
                        }
                    }

                    // Brightness Slider
                    BrightnessSlider {
                        id: brightnessSlider
                        width: parent.width
                        theme: controlCenter.theme
                        font: controlCenter.font
                    }

                    // Audio Section (Speaker & Microphone)
                    AudioSection {
                        id: audioSection
                        width: parent.width
                        theme: controlCenter.theme
                        font: controlCenter.font
                    }

                    // MPRIS Media Controls
                    MediaControl {
                        id: mediaControl
                        width: parent.width
                        theme: controlCenter.theme
                        font: controlCenter.font
                    }
                }

                // 2. Notifications View
                NotificationsView {
                    id: notificationsView
                    width: parent.width
                    opacity: controlCenter.viewNotifications ? 1 : 0
                    x: controlCenter.viewNotifications ? 0 : 30
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    theme: controlCenter.theme
                    font: controlCenter.font
                }
            }
        }
    }

    // Modal Wi-Fi Selector Dialog
    WifiSelectorModal {
        id: wifiModal
        theme: controlCenter.theme
        font: controlCenter.font
        wifiEnabled: quickSettings.wifiEnabled
        onSetWifiRequested: (enabled) => quickSettings.setWifi(enabled)
        onToggleWifiRequested: quickSettings.toggleWifi()
        onNetworkConnected: (ssid) => {
            quickSettings.refresh();
        }
        onNetworkDisconnected: (ssid) => {
            quickSettings.refresh();
        }
    }
}