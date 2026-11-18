import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: legendRoot

    required property var theme
    required property string font
    required property bool shown

    property string copiedIpcCmd: ""

    readonly property var ipcLegendItems: [
        { label: "App Launcher", cmd: "qs ipc call launcher toggle" },
        { label: "App Grid", cmd: "qs ipc call appgrid toggle" },
        { label: "Settings", cmd: "qs ipc call settings toggle" },
        { label: "Keybinds Cheat Sheet", cmd: "qs ipc call keybinds toggle" },
        { label: "Clipboard History", cmd: "qs ipc call clipboard toggle" },
        { label: "Lock Screen", cmd: "qs ipc call lockscreen lock" },
        { label: "Overview", cmd: "qs ipc call overview toggle" },
        { label: "Window Switcher", cmd: "qs ipc call overview switcher" },
        { label: "Power Menu", cmd: "qs ipc call powermenu toggle" },
        { label: "Screenshot HUD", cmd: "qs ipc call screenshot toggle" },
        { label: "Screenshot Area", cmd: "qs ipc call screenshot area" },
        { label: "Wallpaper Picker", cmd: "qs ipc call wallpaper toggle" },
        { label: "Theme Switcher", cmd: "qs ipc call theme toggle" },
        { label: "Toggle Dark/Light", cmd: "qs ipc call theme toggleDarkLight" },
        { label: "Monitor Manager", cmd: "qs ipc call monitors toggle" },
        { label: "Toggle Bar", cmd: "qs ipc call bar toggle" },
        { label: "Idle Inhibitor", cmd: "qs ipc call idle toggle" },
        { label: "Notifications DND", cmd: "qs ipc call notifications dnd_toggle" }
    ]

    Timer {
        id: copiedResetTimer
        interval: 1500
        onTriggered: legendRoot.copiedIpcCmd = ""
    }

    Layout.preferredWidth: legendRoot.shown ? 280 : 0
    Layout.fillHeight: true
    visible: Layout.preferredWidth > 2
    opacity: legendRoot.shown ? 1.0 : 0.0
    Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

    radius: 10
    color: legendRoot.theme.bgSurface
    border.color: legendRoot.theme.bgBorder
    border.width: 1
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "IPC Calls Legend"
                font.family: legendRoot.font
                font.pixelSize: 12
                font.bold: true
                color: legendRoot.theme.textPrimary
            }

            Text {
                text: "Click any command to copy for exec bindings"
                font.family: legendRoot.font
                font.pixelSize: 10
                color: legendRoot.theme.textMuted
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: legendRoot.theme.bgBorder
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: legendRoot.ipcLegendItems
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property var modelData
                readonly property bool isCopied: legendRoot.copiedIpcCmd === modelData.cmd
                width: ListView.view.width
                implicitHeight: ipcItemCol.implicitHeight + 12
                radius: 7
                color: ipcItemMouse.containsMouse ? legendRoot.theme.bgHover : legendRoot.theme.bgBase
                border.color: isCopied
                    ? legendRoot.theme.accentPrimary
                    : (ipcItemMouse.containsMouse ? Qt.rgba(legendRoot.theme.accentPrimary.r, legendRoot.theme.accentPrimary.g, legendRoot.theme.accentPrimary.b, 0.55) : legendRoot.theme.bgBorder)
                border.width: 1
                scale: ipcItemMouse.pressed ? 0.97 : (ipcItemMouse.containsMouse ? 1.01 : 1.0)
                Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 130; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: ipcItemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["wl-copy", modelData.cmd]);
                        legendRoot.copiedIpcCmd = modelData.cmd;
                        copiedResetTimer.restart();
                    }
                }

                ColumnLayout {
                    id: ipcItemCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: modelData.label
                            font.family: legendRoot.font
                            font.pixelSize: 11
                            font.bold: true
                            color: legendRoot.theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: isCopied ? "Copied" : "󰆏"
                            font.family: legendRoot.font
                            font.pixelSize: isCopied ? 10 : 11
                            font.bold: isCopied
                            color: isCopied ? legendRoot.theme.accentPrimary : legendRoot.theme.textMuted
                        }
                    }

                    Text {
                        text: modelData.cmd
                        font.family: "monospace"
                        font.pixelSize: 10
                        color: legendRoot.theme.accentPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
