import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var theme
    required property string font
    required property string selectedPreset
    required property var detectedTools

    signal presetChosen(string name)
    signal finishRequested()
    signal skipRequested()
    signal launchIpcRequested(string target, string fnName)

    property int step: 0
    readonly property var stepTitles: ["1. Choose Preset", "2. Theme & Wallpaper", "3. Shortcuts & Ready"]

    readonly property var presetOptions: [
        {
            id: "laptop",
            icon: "󰌢",
            title: "Laptop",
            desc: "Compact bar with battery, brightness, Wi-Fi, balanced toasts & 2-panel Control Center."
        },
        {
            id: "pc",
            icon: "󰍹",
            title: "PC / Desktop",
            desc: "Full bar with CPU, RAM, network speed, weather, 3-panel Control Center & full lockscreen."
        },
        {
            id: "gaming",
            icon: "󰊴",
            title: "Gaming",
            desc: "1s CPU/GPU/temp polling, idle inhibitor, compact bottom-right toasts & minimal lockscreen."
        },
        {
            id: "minimal",
            icon: "󰕮",
            title: "Minimal",
            desc: "Floating translucent bar, compact toasts, 1-panel vertical Control Center & clean lockscreen."
        }
    ]

    readonly property var shortcutItems: [
        { keys: "SUPER + D", label: "App Launcher" },
        { keys: "SUPER + I", label: "Settings" },
        { keys: "SUPER + H", label: "Keybinds Cheat Sheet" },
        { keys: "SUPER + V", label: "Clipboard History" },
        { keys: "SUPER + L", label: "Lock Screen" },
        { keys: "ALT + Tab", label: "Window Switcher" }
    ]

    readonly property var toolItems: [
        { key: "awww", label: "Wallpaper (awww/swww)" },
        { key: "wallust", label: "Palette (wallust/matugen)" },
        { key: "cliphist", label: "Clipboard (cliphist)" },
        { key: "cava", label: "Audio Visualizer (cava)" },
        { key: "grim", label: "Screenshot (grim)" },
        { key: "magick", label: "ImageMagick (magick)" }
    ]

    visible: true
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-setup-wizard"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Dimmed backdrop
    Rectangle {
        anchors.fill: parent
        color: "#66000000"
        MouseArea {
            anchors.fill: parent
            onClicked: root.skipRequested()
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.skipRequested()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(700, root.width - 64)
        height: Math.min(540, root.height - 64)
        radius: 18
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1
        clip: true

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Welcome to canting-shell"
                        font.family: root.font
                        font.pixelSize: 20
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "Draw your own palette — configure your initial setup in a few clicks."
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textMuted
                    }
                }

                Rectangle {
                    radius: 8
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder
                    border.width: 1
                    implicitWidth: stepBadge.implicitWidth + 16
                    implicitHeight: 28

                    Text {
                        id: stepBadge
                        anchors.centerIn: parent
                        text: root.stepTitles[root.step]
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentPrimary
                    }
                }
            }

            // Step indicator bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        required property int index
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: index <= root.step ? root.theme.accentPrimary : root.theme.bgBorder
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // Step content
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.step

                // Step 0: Presets
                GridLayout {
                    columns: 2
                    rowSpacing: 12
                    columnSpacing: 12

                    Repeater {
                        model: root.presetOptions
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool isSel: root.selectedPreset === modelData.id

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: isSel ? root.theme.bgHover : root.theme.bgSurface
                            border.color: isSel ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: isSel ? 2 : 1

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.presetChosen(modelData.id)
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Text {
                                        text: modelData.icon
                                        font.family: root.font
                                        font.pixelSize: 22
                                        color: isSel ? root.theme.accentPrimary : root.theme.textSecondary
                                    }

                                    Text {
                                        text: modelData.title
                                        font.family: root.font
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: root.theme.textPrimary
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        visible: isSel
                                        radius: 6
                                        color: root.theme.accentPrimary
                                        implicitWidth: activeLbl.implicitWidth + 12
                                        implicitHeight: 20

                                        Text {
                                            id: activeLbl
                                            anchors.centerIn: parent
                                            text: "Active"
                                            font.family: root.font
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: root.theme.bgBase
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: modelData.desc
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textSecondary
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                // Step 1: Theme & Wallpaper
                ColumnLayout {
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "Starter Palette"
                            font.family: root.font
                            font.pixelSize: 14
                            font.bold: true
                            color: root.theme.textPrimary
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            radius: 8
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1
                            implicitWidth: modeTxt.implicitWidth + 20
                            implicitHeight: 32

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.theme.toggleDarkLight()
                            }

                            Text {
                                id: modeTxt
                                anchors.centerIn: parent
                                text: root.theme.isDark ? "󰖔  Dark Mode" : "󰖨  Light Mode"
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.theme.textPrimary
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        rowSpacing: 10
                        columnSpacing: 10

                        Repeater {
                            model: Math.min(8, root.theme.themes ? root.theme.themes.length : 0)
                            delegate: Rectangle {
                                required property int index
                                readonly property var themeObj: root.theme.themes[index]
                                readonly property bool isCur: root.theme.currentIndex === index

                                Layout.fillWidth: true
                                height: 64
                                radius: 10
                                color: themeObj ? themeObj.bgSurface : root.theme.bgSurface
                                border.color: isCur ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: isCur ? 2 : 1

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.theme.setTheme(index)
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    Row {
                                        spacing: 4
                                        Rectangle { width: 14; height: 14; radius: 7; color: themeObj ? themeObj.bgBase : "#000" }
                                        Rectangle { width: 14; height: 14; radius: 7; color: themeObj ? themeObj.accentPrimary : "#fff" }
                                        Rectangle { width: 14; height: 14; radius: 7; color: themeObj ? themeObj.accentSecondary : "#888" }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: themeObj ? themeObj.name : ""
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: isCur
                                        color: themeObj ? themeObj.textPrimary : root.theme.textPrimary
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 10
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.launchIpcRequested("theme", "toggle")
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰏘  Browse 200+ Themes"
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.theme.textPrimary
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 10
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder
                            border.width: 1

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.launchIpcRequested("wallpaper", "toggle")
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰸉  Open Wallpaper Picker"
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.theme.textPrimary
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // Step 2: Shortcuts & Tools
                ColumnLayout {
                    spacing: 14

                    Text {
                        text: "Essential Shortcuts"
                        font.family: root.font
                        font.pixelSize: 14
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 10

                        Repeater {
                            model: root.shortcutItems
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 34
                                radius: 8
                                color: root.theme.bgSurface
                                border.color: root.theme.bgBorder
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10

                                    Text {
                                        text: modelData.label
                                        font.family: root.font
                                        font.pixelSize: 12
                                        color: root.theme.textPrimary
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.keys
                                        font.family: root.font
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: root.theme.accentPrimary
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "Detected Optional Tools"
                        font.family: root.font
                        font.pixelSize: 14
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 8
                        columnSpacing: 8

                        Repeater {
                            model: root.toolItems
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool installed: Boolean(root.detectedTools && root.detectedTools[modelData.key])
                                Layout.fillWidth: true
                                height: 30
                                radius: 8
                                color: root.theme.bgSurface
                                border.color: installed ? root.theme.accentPrimary : root.theme.bgBorder
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: (installed ? "✓ " : "○ ") + modelData.label
                                    font.family: root.font
                                    font.pixelSize: 11
                                    color: installed ? root.theme.textPrimary : root.theme.textMuted
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Skip setup"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textMuted

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.skipRequested()
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: root.step > 0
                    radius: 8
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder
                    border.width: 1
                    implicitWidth: 84
                    implicitHeight: 34

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.step = Math.max(0, root.step - 1)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Back"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                    }
                }

                Rectangle {
                    radius: 8
                    color: root.theme.accentPrimary
                    implicitWidth: 96
                    implicitHeight: 34

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.step < 2) {
                                root.step++;
                            } else {
                                root.finishRequested();
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.step < 2 ? "Next" : "Finish"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.bgBase
                    }
                }
            }
        }
    }
}
