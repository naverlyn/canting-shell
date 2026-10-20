import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"
import ".."

Item {
    required property var root
    id: self
    Layout.fillWidth: true
    implicitHeight: root.isAddingKeybind ? (addDrawerRect.implicitHeight + 12) : 0
    visible: implicitHeight > 0
    opacity: root.isAddingKeybind ? 1.0 : 0.0
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    Rectangle {
        id: addDrawerRect
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 4
        }
        implicitHeight: addCol.implicitHeight + 20
        radius: 10
        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
        border.color: root.theme.accentPrimary
        border.width: 1

        ColumnLayout {
            id: addCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 12

            Text {
                text: "Create New Keybinding"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            /* Form Row 1: Name / Description */
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Name:"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.preferredWidth: 70
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 6
                    color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                    border.color: addNameInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                    border.width: addNameInput.activeFocus ? 2 : 1

                    TextInput {
                        id: addNameInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                        clip: true
                        onTextChanged: root.addName = text

                        Text {
                            text: "Shortcut Name (e.g. Browser, Terminal, Screenshot)"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            visible: !addNameInput.text && !addNameInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            /* Form Row 2: Dispatcher & Command */
            KeyboardActionField {
                root: self.root
            }

            /* Form Row 2b: Custom Dispatcher Name (if custom selected) */
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: root.addDispatcher === "custom"

                Text {
                    text: "Dispatcher:"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.preferredWidth: 70
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 6
                    color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                    border.color: addCustomDispInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                    border.width: addCustomDispInput.activeFocus ? 2 : 1

                    TextInput {
                        id: addCustomDispInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                        clip: true
                        onTextChanged: root.addCustomDisp = text

                        Text {
                            text: "Hyprland dispatcher name (e.g. splitratio, movetoworkspace, pin)"
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            visible: !addCustomDispInput.text && !addCustomDispInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            /* Form Row 2c: Command / Argument */
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: root.addDispatcher !== "killactive" && root.addDispatcher !== "togglefloating"

                Text {
                    text: root.addDispatcher === "workspace" ? "Workspace:" :
                          (root.addDispatcher === "fullscreen" ? "Mode:" :
                          (root.addDispatcher === "custom" ? "Argument:" : "Command:"))
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.preferredWidth: 70
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 6
                    color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                    border.color: addArgInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                    border.width: addArgInput.activeFocus ? 2 : 1

                    TextInput {
                        id: addArgInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: root.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                        clip: true
                        onTextChanged: root.addArg = text

                        Text {
                            text: root.addDispatcher === "workspace" ? "Workspace number or name (e.g. 1, 2, m+1)" :
                                  (root.addDispatcher === "fullscreen" ? "0 (toggle fullscreen) or 1 (maximize)" :
                                  (root.addDispatcher === "custom" ? "Optional argument (e.g. 1, +0.1, or l)" : "Command to run (e.g. firefox, kitty, grim -g ...)"))
                            font.family: root.font
                            font.pixelSize: 11
                            color: root.theme.textSecondary
                            visible: !addArgInput.text && !addArgInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            /* Form Row 2d: Static Dispatcher Info */
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: root.addDispatcher === "killactive" || root.addDispatcher === "togglefloating"

                Text {
                    text: "Detail:"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.preferredWidth: 70
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.addDispatcher === "killactive" ? "Closes the active window (no extra parameters needed)." : "Toggles window floating / tiling state (no extra parameters needed)."
                    font.family: root.font
                    font.pixelSize: 11
                    font.italic: true
                    color: root.theme.textSecondary
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            /* Form Row 3: Modifiers Selection */
            KeyboardModifiersField {
                root: self.root
            }

            /* Form Row 4: Key Input + Record Button + Live Preview */
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Key:"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.textSecondary
                    Layout.preferredWidth: 70
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    width: 110
                    height: 30
                    radius: 6
                    color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                    border.color: addKeyInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                    border.width: addKeyInput.activeFocus ? 2 : 1

                    TextInput {
                        id: addKeyInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.addKey
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textPrimary
                        clip: true
                        onTextChanged: {
                            if (text !== root.addKey) root.addKey = text;
                        }
                    }
                }

                // Record Key Button
                Rectangle {
                    implicitWidth: addRecLabel.implicitWidth + 16
                    height: 30
                    radius: 6
                    color: root.isCapturingAddKey ? root.theme.accentPrimary : (addRecMouse.containsMouse ? (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.12)) : (root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)))
                    border.color: root.isCapturingAddKey ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            id: addRecLabel
                            text: root.isCapturingAddKey ? "Listening... Press keys (Esc cancels)" : "Record Key"
                            font.family: root.font
                            font.pixelSize: 11
                            font.bold: true
                            color: root.isCapturingAddKey ? root.theme.bgBase : root.theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: addRecMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.isCapturingAddKey = !root.isCapturingAddKey;
                            if (root.isCapturingAddKey) {
                                root.keyCaptureItemRef.forceActiveFocus();
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Preview Pills
                RowLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Preview:"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }

                    Repeater {
                        model: root.getAddPreviewPills()
                        Rectangle {
                            required property var modelData
                            implicitWidth: addPrevPillText.implicitWidth + 10
                            height: 22
                            radius: 5
                            color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)
                            border.color: root.theme.accentPrimary
                            border.width: 1

                            Text {
                                id: addPrevPillText
                                anchors.centerIn: parent
                                text: modelData
                                font.family: root.font
                                font.pixelSize: 10
                                font.bold: true
                                color: root.theme.textPrimary
                            }
                        }
                    }
                }
            }

            /* Form Row 5: Action Buttons & Target Notice */
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                // Cancel
                Rectangle {
                    implicitWidth: cancelAddText.implicitWidth + 24
                    height: 30
                    radius: 7
                    color: cancelAddHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase
                    border.color: cancelAddHover.hovered ? root.theme.textSecondary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: cancelAddHover }

                    Text {
                        id: cancelAddText
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: cancelAddHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.isAddingKeybind = false;
                            root.isCapturingAddKey = false;
                        }
                    }
                }

                // Add & Save
                Rectangle {
                    implicitWidth: saveAddText.implicitWidth + 28
                    height: 30
                    radius: 7
                    readonly property bool canSave: root.addKey.trim().length > 0
                    color: canSave
                        ? (saveAddHover.hovered ? Qt.lighter(root.theme.accentPrimary, 1.1) : root.theme.accentPrimary)
                        : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                    opacity: canSave ? 1.0 : 0.5

                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on opacity { NumberAnimation { duration: 140 } }

                    HoverHandler { id: saveAddHover }

                    Text {
                        id: saveAddText
                        anchors.centerIn: parent
                        text: "Add Keybind"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: parent.canSave ? root.theme.bgBase : root.theme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: parent.canSave ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: parent.canSave
                        onClicked: root.saveNewKeybind()
                    }
                }
            }
        }
    }
}
