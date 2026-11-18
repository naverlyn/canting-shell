import QtQuick
import QtQuick.Layouts
import "../../Settings/Components"

ColumnLayout {
    id: root

    required property var theme
    required property string font
    property bool customizingShortcuts: false
    property bool showIpcLegend: true

    readonly property var shortcutItems: [
        { keys: "SUPER + D", label: "App Launcher" },
        { keys: "SUPER + I", label: "Settings" },
        { keys: "SUPER + H", label: "Keybinds Cheat Sheet" },
        { keys: "SUPER + V", label: "Clipboard History" },
        { keys: "SUPER + L", label: "Lock Screen" },
        { keys: "ALT + Tab", label: "Window Switcher" }
    ]

    spacing: 12

    ColumnLayout {
        visible: !root.customizingShortcuts
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

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

        Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: 10
            color: customShortcutsMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
            border.color: customShortcutsMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55) : root.theme.bgBorder
            border.width: 1
            scale: customShortcutsMouse.pressed ? 0.98 : (customShortcutsMouse.containsMouse ? 1.01 : 1.0)
            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
            Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

            MouseArea {
                id: customShortcutsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.customizingShortcuts = true
            }

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰌌"
                    font.family: root.font
                    font.pixelSize: 16
                    color: root.theme.accentPrimary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Customize shortcuts"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    // Inline KeyboardSettings + IPC Calls Legend view
    ColumnLayout {
        visible: root.customizingShortcuts
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                radius: 8
                color: backShortcutsMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                border.color: backShortcutsMouse.containsMouse
                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55)
                    : root.theme.bgBorder
                border.width: 1
                implicitWidth: backShortcutsLbl.implicitWidth + 20
                implicitHeight: 28
                scale: backShortcutsMouse.pressed ? 0.96 : (backShortcutsMouse.containsMouse ? 1.03 : 1.0)
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: backShortcutsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.customizingShortcuts = false
                }

                Text {
                    id: backShortcutsLbl
                    anchors.centerIn: parent
                    text: "Back to Shortcuts"
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                radius: 8
                color: root.showIpcLegend
                    ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.14)
                    : (legendToggleMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface)
                border.color: root.showIpcLegend
                    ? root.theme.accentPrimary
                    : (legendToggleMouse.containsMouse ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.55) : root.theme.bgBorder)
                border.width: 1
                implicitWidth: legendToggleRow.implicitWidth + 18
                implicitHeight: 28
                scale: legendToggleMouse.pressed ? 0.96 : (legendToggleMouse.containsMouse ? 1.03 : 1.0)
                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: legendToggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showIpcLegend = !root.showIpcLegend
                }

                Row {
                    id: legendToggleRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰅴"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.showIpcLegend ? root.theme.accentPrimary : root.theme.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "IPC Calls Legend"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: root.showIpcLegend
                        color: root.showIpcLegend ? root.theme.accentPrimary : root.theme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.showIpcLegend ? 12 : 0
            Behavior on spacing { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Loader {
                active: root.customizingShortcuts
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: Component {
                    KeyboardSettings {
                        theme: root.theme
                        font: root.font
                    }
                }
            }

            SetupIpcLegendPanel {
                theme: root.theme
                font: root.font
                shown: root.showIpcLegend
            }
        }
    }
}
