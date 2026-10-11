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

    property bool viewNotifications: false

    // Layer-shell panel in the top-right corner, below the bar.
    screen: (anchorTarget && anchorTarget.QsWindow.window) ? anchorTarget.QsWindow.window.screen : null
    anchors {
        top: BarConfig.position === "top"
        bottom: BarConfig.position === "bottom"
        right: true
    }
    margins {
        top: BarConfig.position === "top" ? (BarConfig.barHeight + (BarConfig.floating ? 12 : 6)) : 0
        bottom: BarConfig.position === "bottom" ? (BarConfig.barHeight + (BarConfig.floating ? 12 : 6)) : 0
        right: 10
    }
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay

    visible: false
    implicitWidth: 320
    implicitHeight: (screen ? screen.height : 1080) - 48
    mask: Region { item: ccMainRect }
    color: "transparent"

    // Grab keyboard/pointer: Esc and clicks outside close it. The bar window is included
    // so clicking the bar's control center button still works as a toggle.
    HyprlandFocusGrab {
        windows: controlCenter.anchorTarget
            ? [controlCenter, controlCenter.anchorTarget.QsWindow.window]
            : [controlCenter]
        active: controlCenter.visible
        onCleared: controlCenter.visible = false
    }

    // Esc handled at app level: whichever of our windows holds focus will trigger it
    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: controlCenter.visible
        onActivated: controlCenter.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            brightnessSlider.refresh();
            quickSettings.refresh();
            ccMainRect.forceActiveFocus();
        }
    }

    // Control Center Root Card
    Rectangle {
        id: ccMainRect
        anchors {
            top: BarConfig.position === "top" ? parent.top : undefined
            bottom: BarConfig.position === "bottom" ? parent.bottom : undefined
            left: parent.left
            right: parent.right
        }
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