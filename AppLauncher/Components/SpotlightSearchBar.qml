import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var theme
    required property string font
    required property bool commandMode
    required property string prefixMode
    required property string searchQuery
    required property string commandQuery
    required property int selectedIndex
    required property int activeListCount
    required property bool userExpanded
    required property var commandHistory
    required property string copyFeedbackText

    property int cmdHistoryIndex: -1
    property string cmdDraft: ""
    property bool _navigatingHistory: false

    signal searchQueryUpdated(string text)
    signal commandQueryUpdated(string text)
    signal modeSwitchRequested(bool toCommandMode)
    signal expandRequested()
    signal collapseRequested()
    signal selectionRequested(int index)
    signal activateRequested()
    signal commandExecuteRequested(string cmd)
    signal closeRequested()

    function initAndFocus() {
        root.cmdHistoryIndex = -1;
        root.cmdDraft = "";
        searchInput.text = root.searchQuery;
        commandInput.text = root.commandQuery;
        focusActiveInput();
    }

    function focusActiveInput() {
        if (root.commandMode) {
            commandInput.forceActiveFocus();
        } else {
            searchInput.forceActiveFocus();
        }
    }

    Layout.fillWidth: true
    Layout.preferredHeight: 60
    height: 60
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 16
        spacing: 14

        // Left Search / Mode Icon with smooth morph/rotation animation
        Item {
            implicitWidth: 20
            implicitHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "󰍉"
                color: root.theme.accentPrimary
                font.pixelSize: 20
                font.family: root.font
                font.bold: true
                opacity: root.commandMode ? 0.0 : 1.0
                scale: root.commandMode ? 0.6 : 1.0
                rotation: root.commandMode ? -90 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                anchors.centerIn: parent
                text: "$"
                color: root.theme.accentPrimary
                font.pixelSize: 20
                font.family: root.font
                font.bold: true
                opacity: root.commandMode ? 1.0 : 0.0
                scale: root.commandMode ? 1.0 : 0.6
                rotation: root.commandMode ? 0 : 90
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // Central Search Input Field
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Applications / Smart Prefix Input
            Item {
                anchors.fill: parent
                opacity: root.commandMode ? 0.0 : 1.0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 160 } }

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    enabled: !root.commandMode
                    color: root.theme.textPrimary
                    font.pixelSize: 15
                    font.family: root.font
                    clip: true
                    selectByMouse: true
                    Accessible.role: Accessible.EditableText
                    Accessible.name: "Search applications"

                    onTextChanged: root.searchQueryUpdated(searchInput.text)
                    Keys.onEscapePressed: root.closeRequested()

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Right && searchInput.cursorPosition === searchInput.text.length) {
                            event.accepted = true;
                            root.modeSwitchRequested(true);
                        } else if (event.key === Qt.Key_Down) {
                            event.accepted = true;
                            if (!root.userExpanded && searchInput.text === "") {
                                root.expandRequested();
                            } else {
                                root.selectionRequested(Math.min(root.selectedIndex + 1, root.activeListCount - 1));
                            }
                        } else if (event.key === Qt.Key_Up) {
                            event.accepted = true;
                            if (root.selectedIndex === 0 && searchInput.text === "") {
                                root.collapseRequested();
                            } else {
                                root.selectionRequested(Math.max(root.selectedIndex - 1, 0));
                            }
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true;
                            root.activateRequested();
                        } else if (event.key === Qt.Key_Tab) {
                            event.accepted = true;
                            root.modeSwitchRequested(true);
                        }
                    }
                }

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: "Search apps, =calc, @window, or ↓ to browse..."
                    color: root.theme.textMuted
                    font.pixelSize: 15
                    font.family: root.font
                    visible: searchInput.text === ""
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            // Commands Input
            Item {
                anchors.fill: parent
                opacity: root.commandMode ? 1.0 : 0.0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 160 } }

                TextInput {
                    id: commandInput
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    enabled: root.commandMode
                    color: root.theme.textPrimary
                    font.pixelSize: 15
                    font.family: root.font
                    clip: true
                    selectByMouse: true
                    Accessible.role: Accessible.EditableText
                    Accessible.name: "Execute shell command"
                    onTextChanged: {
                        if (!root._navigatingHistory) {
                            root.cmdHistoryIndex = -1;
                        }
                        root.commandQueryUpdated(commandInput.text);
                    }

                    Keys.onEscapePressed: root.closeRequested()

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Left && commandInput.cursorPosition === 0) {
                            event.accepted = true;
                            root.modeSwitchRequested(false);
                        } else if (event.key === Qt.Key_Up) {
                            event.accepted = true;
                            if (root.commandHistory && root.commandHistory.length > 0) {
                                if (root.cmdHistoryIndex === -1) {
                                    root.cmdDraft = commandInput.text;
                                }
                                const nextIdx = Math.min(root.cmdHistoryIndex + 1, root.commandHistory.length - 1);
                                root.cmdHistoryIndex = nextIdx;
                                root._navigatingHistory = true;
                                commandInput.text = root.commandHistory[nextIdx];
                                commandInput.cursorPosition = commandInput.text.length;
                                root._navigatingHistory = false;
                            }
                        } else if (event.key === Qt.Key_Down) {
                            event.accepted = true;
                            if (root.cmdHistoryIndex > 0) {
                                root.cmdHistoryIndex -= 1;
                                root._navigatingHistory = true;
                                commandInput.text = root.commandHistory[root.cmdHistoryIndex];
                                commandInput.cursorPosition = commandInput.text.length;
                                root._navigatingHistory = false;
                            } else if (root.cmdHistoryIndex === 0) {
                                root.cmdHistoryIndex = -1;
                                root._navigatingHistory = true;
                                commandInput.text = root.cmdDraft;
                                commandInput.cursorPosition = commandInput.text.length;
                                root._navigatingHistory = false;
                            }
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true;
                            root.commandExecuteRequested(commandInput.text);
                        } else if (event.key === Qt.Key_Tab) {
                            event.accepted = true;
                            root.modeSwitchRequested(false);
                        }
                    }
                }

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: "Type shell command (e.g. btop, kitty, reboot)..."
                    color: root.theme.textMuted
                    font.pixelSize: 15
                    font.family: root.font
                    visible: commandInput.text === ""
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }

        // Copy feedback pill
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            visible: root.copyFeedbackText !== ""
            implicitWidth: copyFeedbackLabel.implicitWidth + 14
            implicitHeight: 24
            radius: 12
            color: root.theme.bgSurface
            border.color: root.theme.accentPrimary
            border.width: 1

            Text {
                id: copyFeedbackLabel
                anchors.centerIn: parent
                text: "✓ " + root.copyFeedbackText
                color: root.theme.accentPrimary
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
            }
        }

        // Right-aligned Interactive Mode Switch Pill
        Rectangle {
            id: modeBtn
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: modeRow.implicitWidth + 16
            implicitHeight: 28
            radius: 14
            color: modeHover.hovered ? root.theme.bgHover : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            HoverHandler { id: modeHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.modeSwitchRequested(!root.commandMode)
            }

            Row {
                id: modeRow
                anchors.centerIn: parent
                spacing: 6

                Item {
                    implicitWidth: Math.max(appsLabel.implicitWidth, cmdLabel.implicitWidth)
                    implicitHeight: Math.max(appsLabel.implicitHeight, cmdLabel.implicitHeight)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Text {
                        id: appsLabel
                        text: root.prefixMode === "calc"
                            ? "Calc"
                            : (root.prefixMode === "window" ? "Windows" : "Apps")
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: modeHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.commandMode ? -14 : 0
                        opacity: root.commandMode ? 0.0 : 1.0
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        id: cmdLabel
                        text: "Command"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: true
                        color: modeHover.hovered ? root.theme.textPrimary : root.theme.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.commandMode ? 0 : 14
                        opacity: root.commandMode ? 1.0 : 0.0
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Tab"
                    font.family: root.font
                    font.pixelSize: 10
                    color: root.theme.textMuted
                    opacity: 0.8
                }
            }
        }
    }
}
