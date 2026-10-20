import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Keyboard"
import "../Common"

ColumnLayout {
    required property var root
    property alias keyboardKeyRepeatGroupInstRef: keyboardKeyRepeatGroupInst
    id: mainCol
    width: parent.width
    spacing: 20

    Text {
        text: "Keyboard"
        font.family: root.font
        font.pixelSize: 20
        font.bold: true
        color: root.theme.textPrimary
        Layout.fillWidth: true
    }

    /* Key Repeat Group */
    KeyboardKeyRepeatGroup {
        id: keyboardKeyRepeatGroupInst
        root: mainCol.root
    }

    /* Layout & Options Group */
    KeyboardLayoutOptionsGroup {
        root: mainCol.root
    }

    /* Shortcuts Group */
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8

            Text {
                text: "Hyprland Keybindings"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textSecondary
            }

            Text {
                text: "(" + root.rawBinds.length + ")"
                font.family: root.font
                font.pixelSize: 12
                color: root.theme.textSecondary
                opacity: 0.7
            }

            Item { Layout.fillWidth: true }

            /* Add Keybind Toggle Button (Text-only, no icon) */
            Rectangle {
                implicitWidth: addBtnText.implicitWidth + 24
                height: 30
                radius: 7
                color: addBtnHover.hovered
                    ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08))
                    : (root.isAddingKeybind ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.04)))
                border.color: root.isAddingKeybind || addBtnHover.hovered ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                border.width: 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: addBtnHover }

                Text {
                    id: addBtnText
                    anchors.centerIn: parent
                    text: root.isAddingKeybind ? "Close Form" : "Add Keybind"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.isAddingKeybind || addBtnHover.hovered ? root.theme.accentPrimary : root.theme.textPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isAddingKeybind = !root.isAddingKeybind;
                        if (root.isAddingKeybind) {
                            root.editingItem = null;
                        }
                        root.isCapturingAddKey = false;
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: shortcutsCol.implicitHeight + 16
            radius: 12
            color: root.theme.bgSurface
            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            ColumnLayout {
                id: shortcutsCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 8
                }
                spacing: 0

                /* Add Keybind Form Drawer */
                KeyboardAddKeybindFormDrawer {
                    root: mainCol.root
                }

                /* Search Bar Row */
                Item {
                    Layout.fillWidth: true
                    height: 48

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 8
                        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.2)
                        border.color: searchInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                        border.width: searchInput.activeFocus ? 2 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: "󰍉"
                                font.family: root.font
                                font.pixelSize: 14
                                color: root.theme.textSecondary
                                Layout.alignment: Qt.AlignVCenter
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                font.family: root.font
                                font.pixelSize: 13
                                color: root.theme.textPrimary
                                clip: true
                                selectByMouse: true
                                onTextChanged: root.searchQuery = text

                                Text {
                                    text: "Search shortcuts (e.g. kitty, workspace, toggle)..."
                                    font.family: root.font
                                    font.pixelSize: 12
                                    color: root.theme.textSecondary
                                    visible: !searchInput.text && !searchInput.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: "✕"
                                font.family: root.font
                                font.pixelSize: 13
                                color: clearSearchMouse.containsMouse ? root.theme.textPrimary : root.theme.textSecondary
                                visible: searchInput.text.length > 0

                                MouseArea {
                                    id: clearSearchMouse
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        searchInput.text = "";
                                        root.searchQuery = "";
                                    }
                                }
                            }
                        }
                    }
                }

                /* Divider */
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.05)
                }

                /* Shortcuts Repeater */
                Repeater {
                    model: root.filteredBinds

                    KeyboardShortcutRowDelegate {
                        root: mainCol.root
                    }
                }

                /* Empty State if no match */
                Item {
                    Layout.fillWidth: true
                    height: 60
                    visible: root.filteredBinds.length === 0

                    Text {
                        anchors.centerIn: parent
                        text: "No matching shortcuts found"
                        font.family: root.font
                        font.pixelSize: 13
                        color: root.theme.textSecondary
                    }
                }

                /* "Show All" toggle button if list is truncated and no active search */
                Item {
                    Layout.fillWidth: true
                    height: 44
                    visible: !root.showAllShortcuts && !root.searchQuery && root.rawBinds.length > 15

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 8
                        color: showAllMouse.containsMouse ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"

                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "Show all " + root.rawBinds.length + " shortcuts"
                                font.family: root.font
                                font.pixelSize: 12
                                font.bold: true
                                color: root.theme.accentPrimary
                            }

                            Text {
                                text: "󰅀"
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.theme.accentPrimary
                            }
                        }

                        MouseArea {
                            id: showAllMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showAllShortcuts = true
                        }
                    }
                }
            }
        }
    }
}
