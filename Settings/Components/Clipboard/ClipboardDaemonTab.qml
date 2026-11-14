import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../../../Clipboard"
import "../Common"

ColumnLayout {
    required property var root
    Layout.fillWidth: true
    spacing: 16
    visible: root.currentSubTab === 2

    // Daemon Status Card
    SectionCard {
        title: "Clipboard Watcher Daemon (cliphist store)"
        subtitle: "Real-time background listener capturing selection updates via wl-paste"
        contentMargins: 8
        contentSpacing: 0

        Item {
            Layout.fillWidth: true
            height: 64

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 14

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 8
                        Text {
                            text: root.daemonRunning ? "Watcher Daemon is Active" : "Watcher Daemon is Stopped"
                            font.family: root.font
                            font.pixelSize: 13
                            font.bold: true
                            color: root.theme.textPrimary
                        }

                        Rectangle {
                            implicitWidth: dStatusTxt.implicitWidth + 8
                            implicitHeight: 18
                            radius: 4
                            color: root.daemonRunning
                                ? Qt.rgba(0.2, 0.8, 0.4, 0.15)
                                : Qt.rgba(0.9, 0.3, 0.3, 0.15)

                            Text {
                                id: dStatusTxt
                                anchors.centerIn: parent
                                text: root.daemonRunning ? "RUNNING" : "INACTIVE"
                                font.family: "JetBrains Mono, monospace"
                                font.pixelSize: 9
                                font.bold: true
                                color: root.daemonRunning
                                    ? (root.theme.accentGreen)
                                    : (root.theme.accentRed)
                            }
                        }
                    }

                    Text {
                        text: "wl-paste --watch cliphist store tracks clipboard changes in real time"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                // Action Buttons (Right-aligned matching stats row)
                RowLayout {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    ActionButton {
                        label: root.daemonRunning ? "Stop Daemon" : "Start Daemon"
                        iconText: root.daemonRunning ? "󰓛" : "󰐊"
                        danger: root.daemonRunning
                        btnHeight: 30
                        onClicked: {
                            if (root.daemonRunning) {
                                root.stopDaemon();
                            } else {
                                root.startDaemon();
                            }
                        }
                    }

                    ActionButton {
                        label: "Refresh"
                        iconText: "󰑐"
                        btnHeight: 30
                        onClicked: root.queryStatus()
                    }
                }
            }
        }

        RowDivider {}

        // Database Stats Row
        Item {
            Layout.fillWidth: true
            height: 52

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 20

                // Stat 1: Total Stored Items
                RowLayout {
                    spacing: 8
                    Text {
                        text: "󰅌"
                        font.family: root.font
                        font.pixelSize: 14
                        color: root.theme.accentPrimary
                    }
                    Text {
                        text: "Total Clips:"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                    }
                    Text {
                        text: String(root.totalStoredItems)
                        font.family: "JetBrains Mono, monospace"
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                }

                // Stat 2: DB File Size
                RowLayout {
                    spacing: 8
                    Text {
                        text: "󰋊"
                        font.family: root.font
                        font.pixelSize: 14
                        color: root.theme.accentCyan
                    }
                    Text {
                        text: "Database Size:"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                    }
                    Text {
                        text: root.dbSizeFormatted
                        font.family: "JetBrains Mono, monospace"
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                }

                // Stat 3: Cached Thumbnails
                RowLayout {
                    spacing: 8
                    Text {
                        text: "󰋩"
                        font.family: root.font
                        font.pixelSize: 14
                        color: root.theme.accentGreen
                    }
                    Text {
                        text: "Cached Thumbs:"
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textSecondary
                    }
                    Text {
                        text: String(root.thumbsCount)
                        font.family: "JetBrains Mono, monospace"
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textPrimary
                    }
                }

                Item { Layout.fillWidth: true }

                // Test Copy button
                ActionButton {
                    label: "Test Copy Snippet"
                    iconText: "󰅍"
                    btnHeight: 30
                    onClicked: root.testCopy()
                }
            }
        }
    }

    // System & Shortcut Integration Card
    SectionCard {
        title: "System & Shortcut Integration"
        subtitle: "Default global bindings and command line interaction points"
        contentMargins: 8
        contentSpacing: 0

        Item {
            Layout.fillWidth: true
            height: 52

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Global Keybind (Hyprland)"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "Toggles the Quickshell clipboard window overlay"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: keyTxt.implicitWidth + 16
                    height: 26
                    radius: 6
                    color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                    border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    Text {
                        id: keyTxt
                        anchors.centerIn: parent
                        text: "SUPER + V"
                        font.family: "JetBrains Mono, monospace"
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.accentPrimary
                    }
                }
            }
        }

        RowDivider {}

        Item {
            Layout.fillWidth: true
            height: 52

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "CLI Toggle Command"
                        font.family: root.font
                        font.pixelSize: 13
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "Programmatic IPC call to toggle the clipboard UI"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                    Rectangle {
                        implicitWidth: cliTxt.implicitWidth + 16
                        height: 26
                        radius: 6
                        color: (root.theme && root.theme.bgBase) ? root.theme.bgBase : Qt.rgba(0, 0, 0, 0.3)
                        border.color: (root.theme && root.theme.bgBorder) ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.12)
                        border.width: 1

                        Text {
                            id: cliTxt
                            anchors.centerIn: parent
                            text: "qs ipc call clipboard toggle"
                            font.family: "JetBrains Mono, monospace"
                            font.pixelSize: 11
                            font.bold: true
                            color: root.theme.accentCyan
                        }
                    }

                    ActionButton {
                        label: "Copy"
                        iconText: "󰅍"
                        btnHeight: 26
                        onClicked: {
                            testCopyProc.command = ["wl-copy", "qs ipc call clipboard toggle"];
                            testCopyProc.running = true;
                            root.showToast("Copied CLI command to clipboard");
                        }
                    }
                }
            }
        }
    }
}
