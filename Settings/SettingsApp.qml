import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../ThemeSwitcher"
import "./Components"
import "./Components/Common"

Scope {
    id: root
    property var theme: Theme
    property string font: "Hack Nerd Font"
    
    // UI state: 0: WiFi, 1: Bluetooth, 2: Sound, 3: Notifications, 4: Power, 5: Mouse, 6: Keyboard, 7: Applications, 8: Display, 9: Appearance, 10: Bar Settings, 11: About, 12: Lock Screen, 13: Animations, 14: Hyprland Settings, 15: Wallpaper, 16: OSD, 17: Control Center, 18: Backup & Restore
    property int currentTab: 0
    property var tabs: ["Wi-Fi", "Bluetooth", "Sound", "Notifications", "Power", "Mouse", "Keyboard", "Applications", "Display", "Appearance", "Bar Settings", "About", "Lock Screen", "Animations", "Hyprland Settings", "Wallpaper", "On-Screen Display", "Control Center", "Backup & Restore"]
    property var tabIcons: ["󰖩", "󰂯", "󰕾", "󰂚", "󰐥", "󰍽", "󰌌", "󰵆", "󰍹", "󰏘", "󰮲", "", "󰌾", "󰑈", "", "󰸉", "󰍹", "󰕮", "󰁯"]

    property var sections: [
        {
            category: "System",
            items: [
                { id: "wifi", name: "Wi-Fi", icon: "󰖩", pageIndex: 0 },
                { id: "bluetooth", name: "Bluetooth", icon: "󰂯", pageIndex: 1 },
                { id: "sound", name: "Sound", icon: "󰕾", pageIndex: 2 },
                { id: "power", name: "Power", icon: "󰐥", pageIndex: 4 }
            ]
        },
        {
            category: "Hardware",
            items: [
                { id: "display", name: "Display", icon: "󰍹", pageIndex: 8 },
                { id: "mouse", name: "Mouse & Touchpad", icon: "󰍽", pageIndex: 5 },
                { id: "keyboard", name: "Keyboard", icon: "󰌌", pageIndex: 6 },
                { id: "apps", name: "Applications", icon: "󰵆", pageIndex: 7 }
            ]
        },
        {
            category: "Hyprland",
            items: [
                { id: "hyprland", name: "Hyprland Settings", icon: "", pageIndex: 14 },
                { id: "animations", name: "Animations", icon: "󰑈", pageIndex: 13 },
                { id: "hyprlock", name: "Lock Screen", icon: "󰌾", pageIndex: 12 }
            ]
        },
        {
            category: "Quickshell",
            items: [
                { id: "bar", name: "Bar Settings", icon: "󰮲", pageIndex: 10 },
                { id: "controlcenter", name: "Control Center", icon: "󰕮", pageIndex: 17 },
                { id: "appearance", name: "Appearance", icon: "󰏘", pageIndex: 9 },
                { id: "wallpaper", name: "Wallpaper", icon: "󰸉", pageIndex: 15 },
                { id: "notifications", name: "Notifications", icon: "󰂚", pageIndex: 3 },
                { id: "osd", name: "On-Screen Display", icon: "󰍹", pageIndex: 16 },
                { id: "backup", name: "Backup & Restore", icon: "󰁯", pageIndex: 18 }
            ]
        },
        {
            category: "About",
            items: [
                { id: "about", name: "About", icon: "", pageIndex: 11 }
            ]
        }
    ]

    onCurrentTabChanged: {
        if (root.theme) {
            root.theme.previewIndex = -1;
            root.theme.previewAccent = "";
        }
    }

    property bool windowActive: false

    function openSettings() {
        closeTimer.stop();
        settingsWindow.visible = true;
        Qt.callLater(() => {
            root.windowActive = true;
            winCard.forceActiveFocus();
        });
    }

    function closeSettings() {
        root.windowActive = false;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 180
        repeat: false
        onTriggered: {
            settingsWindow.visible = false;
        }
    }

    IpcHandler {
        target: "settings"
        function toggle() {
            if (settingsWindow.visible && root.windowActive) {
                root.closeSettings();
            } else {
                root.openSettings();
            }
        }
        function open(tabName: string) {
            if (tabName !== undefined && tabName !== "") {
                let target = String(tabName).toLowerCase().trim();
                for (let s = 0; s < root.sections.length; s++) {
                    for (let i = 0; i < root.sections[s].items.length; i++) {
                        let item = root.sections[s].items[i];
                        if (item.name.toLowerCase().includes(target) || (item.id && item.id.toLowerCase() === target)) {
                            root.currentTab = item.pageIndex;
                            root.openSettings();
                            return;
                        }
                    }
                }
            }
            root.openSettings();
        }
    }

    PanelWindow {
        id: settingsWindow
        visible: false
        focusable: true
        color: "transparent"

        onVisibleChanged: {
            if (!visible && root.theme) {
                root.theme.previewIndex = -1;
                root.theme.previewAccent = "";
            }
            if (visible) {
                winCard.forceActiveFocus();
            }
        }

        Shortcut {
            sequence: "Escape"
            context: Qt.WindowShortcut
            enabled: settingsWindow.visible
            onActivated: root.closeSettings()
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-settings"

        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Overlay backdrop
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeSettings()

            Rectangle {
                anchors.fill: parent
                color: root.theme.bgOverlay ?? "#80000000"
                opacity: root.windowActive ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }

        // Floating Draggable & Resizable Window Card
        Rectangle {
            id: winCard
            width: 1180
            height: 760
            x: Math.max(10, (settingsWindow.width - width) / 2)
            y: Math.max(10, (settingsWindow.height - height) / 2)
            radius: 14
            color: root.theme.bgBase
            border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)
            border.width: 1
            opacity: root.windowActive ? 1.0 : 0.0
            scale: root.windowActive ? 1.0 : 0.96

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            focus: true
            Keys.onEscapePressed: (event) => {
                root.closeSettings();
                event.accepted = true;
            }

            readonly property int minWidth: 880
            readonly property int minHeight: 560
            property int sidebarWidth: 240

            // Absorb clicks on background
            MouseArea { anchors.fill: parent }

            // Drag Header Area
            MouseArea {
                id: dragHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 48
                cursorShape: Qt.OpenHandCursor
                property point dragStart

                onPressed: (mouse) => {
                    dragStart = Qt.point(mouse.x, mouse.y);
                    cursorShape = Qt.ClosedHandCursor;
                }
                onReleased: cursorShape = Qt.OpenHandCursor
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        let dx = mouse.x - dragStart.x;
                        let dy = mouse.y - dragStart.y;
                        winCard.x = Math.max(0, Math.min(settingsWindow.width - winCard.width, winCard.x + dx));
                        winCard.y = Math.max(0, Math.min(settingsWindow.height - winCard.height, winCard.y + dy));
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Sidebar
                // Sidebar
                SettingsSidebar {
                    id: sidebarRect
                    hostApp: root
                    hostWindow: settingsWindow
                    winCard: winCard
                }

                // Main Content Area with Close Button & Smooth Tab Animations
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // Close Button in Top Right
                    Rectangle {
                        z: 99
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 6
                        anchors.rightMargin: 12
                        width: 26
                        height: 26
                        radius: 13
                        color: closeMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.1)) : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: root.font
                            font.pixelSize: 12
                            color: closeMouse.containsMouse ? root.theme.accentRed ?? "#f7768e" : root.theme.textMuted

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeSettings()
                        }
                    }


                    // 0: Wi-Fi
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 0
                        pageComponent: WifiSettings { theme: root.theme; font: root.font }
                    }

                    // 1: Bluetooth
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 1
                        pageComponent: BluetoothSettings { theme: root.theme; font: root.font }
                    }

                    // 2: Sound
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 2
                        pageComponent: SoundSettings { theme: root.theme; font: root.font }
                    }

                    // 3: Notifications
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 3
                        pageComponent: NotificationSettings { theme: root.theme; font: root.font }
                    }

                    // 4: Power
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 4
                        pageComponent: PowerSettings { theme: root.theme; font: root.font }
                    }

                    // 5: Mouse & Touchpad
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 5
                        pageComponent: MouseSettings { theme: root.theme; font: root.font }
                    }

                    // 6: Keyboard
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 6
                        pageComponent: KeyboardSettings { theme: root.theme; font: root.font }
                    }

                    // 7: Default Applications
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 7
                        pageComponent: DefaultAppsSettings { theme: root.theme; font: root.font }
                    }

                    // 8: Display
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 8
                        pageComponent: DisplaySettings { theme: root.theme; font: root.font }
                    }

                    // 9: Appearance
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 9
                        pageComponent: AppearanceSettings { theme: root.theme; font: root.font }
                    }

                    // 10: Bar Settings
                    SettingsPageContainer {
                        id: barSettingsPageLoader
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 10
                        pageComponent: BarSettings { theme: root.theme; font: root.font }
                    }

                    // 11: About
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 11
                        pageComponent: AboutSettings { theme: root.theme; font: root.font }
                    }

                    // 12: Lock Screen (Hyprlock)
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 12
                        pageComponent: HyprlockSettings { theme: root.theme; font: root.font }
                    }

                    // 13: Animations
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 13
                        pageComponent: AnimationSettings { theme: root.theme; font: root.font }
                    }

                    // 14: Hyprland Settings
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 14
                        pageComponent: HyprlandSettings { theme: root.theme; font: root.font }
                    }

                    // 15: Wallpaper
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 15
                        pageComponent: WallpaperSettings { theme: root.theme; font: root.font }
                    }

                    // 16: On-Screen Display (OSD)
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 16
                        pageComponent: OSDSettings { theme: root.theme; font: root.font }
                    }

                    // 17: Control Center
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 17
                        pageComponent: ControlCenterSettings { theme: root.theme; font: root.font }
                    }

                    // 18: Backup & Restore
                    SettingsPageContainer {
                        hostApp: root
                        hostWindow: settingsWindow
                        pageIndex: 18
                        pageComponent: BackupRestoreSettings { theme: root.theme; font: root.font }
                    }
                }
            }

            // --- 8-Direction Window Resize Handles ---
            SettingsResizeHandles {
                winCard: winCard
            }
        }
    }
}
