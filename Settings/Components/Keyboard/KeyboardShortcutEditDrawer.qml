import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../Common"

Rectangle {
    required property var root
    required property var rowItem
    required property var mainRowRect
    required property var modelData
    id: editDrawer
    anchors {
        top: mainRowRect.bottom
        left: parent.left
        right: parent.right
        leftMargin: 8
        rightMargin: 8
        topMargin: 2
    }
    implicitHeight: rowItem.isEditing ? (drawerCol.implicitHeight + 20) : 0
    visible: opacity > 0 || implicitHeight > 0
    opacity: rowItem.isEditing ? 1.0 : 0.0
    radius: 8
    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3)
    border.color: root.theme.accentPrimary
    border.width: 1
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 160 } }

    ColumnLayout {
        id: drawerCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 10

        /* Row 0: Keybinding Name / Label */
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
                radius: 7
                color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                border.color: editNameInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                border.width: editNameInput.activeFocus ? 2 : 1

                TextInput {
                    id: editNameInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.editName
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    onTextChanged: {
                        if (text !== root.editName) root.editName = text;
                    }

                    Text {
                        text: "Shortcut Name (e.g. Browser, Terminal, Screenshot)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                        visible: !editNameInput.text && !editNameInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        /* Row 0a: Action Dispatcher Selection */
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Action:"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 70
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                id: editActionSegmentTrack
                implicitWidth: 400
                Layout.fillWidth: true
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                readonly property var options: root.editDispatcherOptions
                readonly property int activeIdx: {
                    for (let i = 0; i < options.length; i++) {
                        if (options[i].val === root.editDispatcher) return i;
                    }
                    return 0;
                }
                readonly property real cellWidth: (width - 6 - ((options.length - 1) * 4)) / Math.max(1, options.length)

                /* Sliding Pill */
                Rectangle {
                    y: 3
                    height: parent.height - 6
                    width: editActionSegmentTrack.cellWidth
                    x: 3 + editActionSegmentTrack.activeIdx * (editActionSegmentTrack.cellWidth + 4)
                    radius: 5
                    color: root.theme.bgSelected
                    border.color: root.theme.accentPrimary
                    border.width: 1

                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    Repeater {
                        model: editActionSegmentTrack.options

                        delegate: Rectangle {
                            id: eSegBtn
                            required property var modelData
                            required property int index
                            readonly property bool isSel: editActionSegmentTrack.activeIdx === index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: !isSel && eSegHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: eSegHover }

                            Text {
                                anchors.centerIn: parent
                                text: eSegBtn.modelData.name
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: eSegBtn.isSel
                                color: eSegBtn.isSel ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: eSegBtn.isSel || eSegHover.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.editDispatcher = eSegBtn.modelData.val;
                                }
                            }
                        }
                    }
                }
            }

        }

        /* Row 0b: Custom Dispatcher Name (if custom selected) */
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: root.editDispatcher === "custom"

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
                radius: 7
                color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                border.color: customDispEditInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                border.width: customDispEditInput.activeFocus ? 2 : 1

                TextInput {
                    id: customDispEditInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.editCustomDisp
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    onTextChanged: {
                        if (text !== root.editCustomDisp) root.editCustomDisp = text;
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !customDispEditInput.text && !customDispEditInput.activeFocus
                        text: "Hyprland dispatcher name (e.g. splitratio, layoutmsg, movetoworkspace)"
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }
            }
        }

        /* Row 0c: Command / Argument / Parameter Input */
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: root.editDispatcher !== "killactive" && root.editDispatcher !== "togglefloating"

            Text {
                text: root.editDispatcher === "exec" ? "Command:" :
                      (root.editDispatcher === "workspace" ? "Workspace:" :
                      (root.editDispatcher === "fullscreen" ? "Mode:" :
                      (root.editDispatcher === "custom" ? "Argument:" : "Parameter:")))
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
                radius: 7
                color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                border.color: cmdEditInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                border.width: cmdEditInput.activeFocus ? 2 : 1

                TextInput {
                    id: cmdEditInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.editArg
                    font.family: root.font
                    font.pixelSize: 12
                    color: root.theme.textPrimary
                    clip: true
                    onTextChanged: {
                        if (text !== root.editArg) root.editArg = text;
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !cmdEditInput.text && !cmdEditInput.activeFocus
                        text: root.editDispatcher === "exec" ? "Application or command (e.g. kitty, thunar)" :
                              (root.editDispatcher === "workspace" ? "Workspace index or name (e.g. 1, 2, m+1)" :
                              (root.editDispatcher === "fullscreen" ? "0 (toggle fullscreen) or 1 (maximize)" : "Optional arguments"))
                        font.family: root.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }
                }
            }
        }

        /* Row 0d: Static Dispatcher Info */
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: root.editDispatcher === "killactive" || root.editDispatcher === "togglefloating"

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
                text: root.editDispatcher === "killactive" ? "Closes the active window (no extra parameters needed)." : "Toggles window floating / tiling state (no extra parameters needed)."
                font.family: root.font
                font.pixelSize: 11
                font.italic: true
                color: root.theme.textSecondary
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }
        }

        /* Row 1: Modifiers Selection */
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Modifiers:"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 70
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                implicitWidth: 280
                Layout.preferredWidth: 280
                height: 32
                radius: 7
                color: root.theme.bgBase
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    Repeater {
                        model: [
                            { label: "Super", id: "super" },
                            { label: "Ctrl",  id: "ctrl" },
                            { label: "Alt",   id: "alt" },
                            { label: "Shift", id: "shift" }
                        ]

                        delegate: Rectangle {
                            id: editModBtn
                            required property var modelData
                            readonly property bool isActive: {
                                if (modelData.id === "super") return root.editSuper;
                                if (modelData.id === "ctrl")  return root.editCtrl;
                                if (modelData.id === "alt")   return root.editAlt;
                                if (modelData.id === "shift") return root.editShift;
                                return false;
                            }

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 5
                            color: isActive ? root.theme.bgSelected : (editModHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : "transparent")
                            border.color: isActive ? root.theme.accentPrimary : "transparent"
                            border.width: isActive ? 1 : 0

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: editModHover }

                            Text {
                                anchors.centerIn: parent
                                text: editModBtn.modelData.label
                                font.family: root.font
                                font.pixelSize: 11
                                font.bold: editModBtn.isActive
                                color: editModBtn.isActive ? root.theme.accentPrimary : root.theme.textPrimary
                                opacity: editModBtn.isActive || editModHover.hovered ? 1.0 : 0.75
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (editModBtn.modelData.id === "super") root.editSuper = !root.editSuper;
                                    else if (editModBtn.modelData.id === "ctrl")  root.editCtrl = !root.editCtrl;
                                    else if (editModBtn.modelData.id === "alt")   root.editAlt = !root.editAlt;
                                    else if (editModBtn.modelData.id === "shift") root.editShift = !root.editShift;
                                }
                            }
                        }
                    }
                }
            }
        }

        /* Row 2: Key Text Input + Record Key Button + Live Preview */
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

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
                Layout.preferredWidth: 190
                height: 32
                radius: 7
                color: root.theme.bgSurface ?? Qt.rgba(1, 1, 1, 0.05)
                border.color: keyEditInput.activeFocus ? root.theme.accentPrimary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                border.width: keyEditInput.activeFocus ? 2 : 1

                TextInput {
                    id: keyEditInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.editKey
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textPrimary
                    clip: true
                    onTextChanged: {
                        if (text !== root.editKey) root.editKey = text;
                    }
                }
            }

            /* Record Shortcut Button */
            Rectangle {
                implicitWidth: recLabel.implicitWidth + 24
                height: 32
                radius: 7
                color: root.isCapturingKey
                    ? root.theme.accentPrimary
                    : (recHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase)
                border.color: root.isCapturingKey
                    ? root.theme.accentPrimary
                    : (recHover.hovered ? root.theme.textSecondary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
                border.width: 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: recHover }

                Text {
                    id: recLabel
                    anchors.centerIn: parent
                    text: root.isCapturingKey ? "Listening... (Esc cancels)" : "Record Key"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.isCapturingKey ? root.theme.bgBase : (recHover.hovered ? root.theme.textPrimary : root.theme.textSecondary)
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isCapturingKey = !root.isCapturingKey;
                        if (root.isCapturingKey) {
                            root.keyCaptureItemRef.forceActiveFocus();
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            /* Preview Pills */
            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "New:"
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                }

                Repeater {
                    model: root.getEditPreviewPills()
                    Rectangle {
                        required property var modelData
                        implicitWidth: prevPillText.implicitWidth + 12
                        height: 24
                        radius: 5
                        color: root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15)
                        border.color: root.theme.accentPrimary
                        border.width: 1

                        Text {
                            id: prevPillText
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

        /* Row 3: Action Buttons */
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 30 : 0
            spacing: 8
            visible: !rowItem.isConfirmingUnbind

            // Unbind Button (Text-only, danger hover)
            Rectangle {
                implicitWidth: delText.implicitWidth + 24
                height: 30
                radius: 7
                color: delHover.hovered ? Qt.rgba(0.9, 0.2, 0.2, 0.15) : root.theme.bgBase
                border.color: delHover.hovered ? Qt.rgba(0.9, 0.2, 0.2, 0.5) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                border.width: 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: delHover }

                Text {
                    id: delText
                    anchors.centerIn: parent
                    text: "Unbind"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: delHover.hovered ? "#ff5555" : root.theme.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.confirmingUnbindUid = rowItem.modelData.uid
                }
            }

            Item { Layout.fillWidth: true }

            // Cancel
            Rectangle {
                implicitWidth: cancelText.implicitWidth + 24
                height: 30
                radius: 7
                color: cancelHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.08)) : root.theme.bgBase
                border.color: cancelHover.hovered ? root.theme.textSecondary : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08))
                border.width: 1

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                HoverHandler { id: cancelHover }

                Text {
                    id: cancelText
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: cancelHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.editingUid = -1;
                        root.editingItem = null;
                        root.isCapturingKey = false;
                        root.confirmingUnbindUid = -1;
                    }
                }
            }

            // Save & Apply
            Rectangle {
                implicitWidth: saveText.implicitWidth + 28
                height: 30
                radius: 7
                readonly property bool canSave: root.editKey.trim().length > 0
                color: canSave
                    ? (saveHover.hovered ? Qt.lighter(root.theme.accentPrimary, 1.1) : root.theme.accentPrimary)
                    : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                opacity: canSave ? 1.0 : 0.5

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on opacity { NumberAnimation { duration: 140 } }

                HoverHandler { id: saveHover }

                Text {
                    id: saveText
                    anchors.centerIn: parent
                    text: "Save & Apply"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: parent.canSave ? root.theme.bgBase : root.theme.textMuted
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: parent.canSave ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: parent.canSave
                    onClicked: root.applyEditedKeybind()
                }
            }
        }

        /* Row 3b: Inline Confirmation Bar (When Unbind is clicked) */
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 34 : 0
            height: 34
            radius: 7
            color: Qt.rgba(0.9, 0.2, 0.2, 0.1)
            border.color: Qt.rgba(0.9, 0.2, 0.2, 0.35)
            border.width: 1
            visible: rowItem.isConfirmingUnbind

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 10

                Text {
                    text: "Are you sure you want to remove this keybind?"
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: "#ff6b6b"
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Cancel Button
                Rectangle {
                    implicitWidth: cancelPromptText.implicitWidth + 20
                    height: 26
                    radius: 6
                    color: confCancelHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : root.theme.bgBase
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: confCancelHover }

                    Text {
                        id: cancelPromptText
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.confirmingUnbindUid = -1
                    }
                }

                // Confirm Yes Button
                Rectangle {
                    implicitWidth: yesBtnText.implicitWidth + 20
                    height: 26
                    radius: 6
                    color: confYesHover.hovered ? "#ee3333" : "#ff5555"

                    Behavior on color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: confYesHover }

                    Text {
                        id: yesBtnText
                        anchors.centerIn: parent
                        text: "Yes, Unbind"
                        font.family: root.font
                        font.pixelSize: 11
                        font.bold: true
                        color: "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.confirmingUnbindUid = -1;
                            root.deleteKeybind(rowItem.modelData);
                        }
                    }
                }
            }
        }
    }
}
