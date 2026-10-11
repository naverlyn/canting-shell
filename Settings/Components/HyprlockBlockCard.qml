/*
 * HyprlockBlockCard.qml
 *
 * Interactive building block card representing a text/command label in hyprlock.conf.
 * Supports:
 *   - Live toggle (enable/disable label in lock screen)
 *   - Plain text & Hyprland variables ($USER, $LAYOUT, $TIME, etc.)
 *   - Shell script commands (cmd[update:interval] <command>)
 *   - In-app execution and live output testing of shell scripts
 *   - Screen position & alignment controls (halign, valign, x/y offsets)
 *   - Strictly text-based controls (no icons) matching GNOME/Libadwaita aesthetic.
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Rectangle {
    id: cardRoot

    property var blockData: ({})
    property int blockIndex: 0
    property var theme
    property string font: "Hack Nerd Font"
    property bool isExpanded: false

    signal blockSaved(int index, var payload)
    signal blockDeleted(int index)

    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 24
    radius: 10
    color: cardHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.05)) : (root.theme.bgSurface ?? Qt.rgba(0, 0, 0, 0.2))
    border.color: isExpanded 
        ? (root.theme.accentPrimary ?? "#7aa2f7") 
        : (cardHover.hovered ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.4) : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
    border.width: isExpanded ? 1.5 : 1

    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on color { ColorAnimation { duration: 150 } }

    HoverHandler { id: cardHover }

    // Live editing state properties
    property bool editEnabled: blockData && blockData.enabled !== undefined ? blockData.enabled : true
    property string editName: blockData && blockData.name ? blockData.name : "Label"
    property bool editIsCmd: blockData && blockData.is_cmd !== undefined ? blockData.is_cmd : false
    property int editCmdInterval: blockData && blockData.cmd_interval ? blockData.cmd_interval : 1000
    property string editCmdBody: blockData && blockData.cmd_body ? blockData.cmd_body : ""
    property string editRawText: blockData && blockData.raw_text ? blockData.raw_text : ""
    property int editFontSize: blockData && blockData.font_size ? blockData.font_size : 14
    property string editHalign: blockData && blockData.halign ? blockData.halign : "center"
    property string editValign: blockData && blockData.valign ? blockData.valign : "center"
    property int editPosX: blockData && blockData.position_x !== undefined ? blockData.position_x : 0
    property int editPosY: blockData && blockData.position_y !== undefined ? blockData.position_y : 0
    property string editColor: blockData && blockData.color ? blockData.color : "$color8"

    property string testOutput: ""
    property bool isEvaluating: false

    onBlockDataChanged: {
        if (!isExpanded) {
            editEnabled = blockData && blockData.enabled !== undefined ? blockData.enabled : true;
            editName = blockData && blockData.name ? blockData.name : "Label";
            editIsCmd = blockData && blockData.is_cmd !== undefined ? blockData.is_cmd : false;
            editCmdInterval = blockData && blockData.cmd_interval ? blockData.cmd_interval : 1000;
            editCmdBody = blockData && blockData.cmd_body ? blockData.cmd_body : "";
            editRawText = blockData && blockData.raw_text ? blockData.raw_text : "";
            editFontSize = blockData && blockData.font_size ? blockData.font_size : 14;
            editHalign = blockData && blockData.halign ? blockData.halign : "center";
            editValign = blockData && blockData.valign ? blockData.valign : "center";
            editPosX = blockData && blockData.position_x !== undefined ? blockData.position_x : 0;
            editPosY = blockData && blockData.position_y !== undefined ? blockData.position_y : 0;
            editColor = blockData && blockData.color ? blockData.color : "$color8";
        }
    }

    // Shell script execution runner
    Process {
        id: evalProc
        property string cmdToRun: ""
        command: ["/home/xeana/.config/quickshell/Settings/scripts/manage_hyprlock.sh", "eval", cmdToRun]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                cardRoot.isEvaluating = false;
                try {
                    const res = JSON.parse(text);
                    cardRoot.testOutput = (res && res.output !== undefined) ? res.output : text.trim();
                } catch(e) {
                    cardRoot.testOutput = text.trim();
                }
            }
        }
    }

    function runTest() {
        let cmd = cardRoot.editIsCmd ? cardRoot.editCmdBody : cardRoot.editRawText;
        if (!cmd || cmd.trim() === "") {
            cardRoot.testOutput = "(empty command or text)";
            return;
        }
        cardRoot.isEvaluating = true;
        cardRoot.testOutput = "Executing shell script...";
        evalProc.cmdToRun = cmd;
        evalProc.running = true;
    }

    function saveChanges() {
        let finalRaw = "";
        if (cardRoot.editIsCmd) {
            let interval = cardRoot.editCmdInterval > 0 ? cardRoot.editCmdInterval : 1000;
            finalRaw = "cmd[update:" + interval + "] " + cardRoot.editCmdBody.trim();
        } else {
            finalRaw = cardRoot.editRawText.trim();
        }

        let payload = {
            enabled: cardRoot.editEnabled,
            name: cardRoot.editName.trim(),
            raw_text: finalRaw,
            font_size: cardRoot.editFontSize,
            font_family: (cardRoot.blockData && cardRoot.blockData.font_family) ? cardRoot.blockData.font_family : "Victor Mono Bold Oblique",
            position_x: cardRoot.editPosX,
            position_y: cardRoot.editPosY,
            halign: cardRoot.editHalign,
            valign: cardRoot.editValign,
            color: cardRoot.editColor.trim()
        };

        cardRoot.blockSaved(cardRoot.blockIndex, payload);
        cardRoot.isExpanded = false;
    }

    ColumnLayout {
        id: mainLayout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 10

        /* --- Header Row --- */
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Block Name
            Text {
                text: cardRoot.editName
                font.family: cardRoot.font
                font.pixelSize: 13
                font.bold: true
                color: cardRoot.editEnabled ? (root.theme.textPrimary ?? "#ffffff") : (root.theme.textMuted ?? "#666666")
                Layout.alignment: Qt.AlignVCenter
            }

            // Mode Badge Pill
            Rectangle {
                height: 20
                implicitWidth: badgeText.implicitWidth + 12
                radius: 4
                color: cardRoot.editIsCmd ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.14) : Qt.rgba(1, 1, 1, 0.06)
                border.color: cardRoot.editIsCmd ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.3) : Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: cardRoot.editIsCmd ? ("cmd (" + (cardRoot.editCmdInterval >= 1000 ? ((cardRoot.editCmdInterval / 1000) + "s") : (cardRoot.editCmdInterval + "ms")) + ")") : "text"
                    font.family: cardRoot.font
                    font.pixelSize: 10
                    font.bold: true
                    color: cardRoot.editIsCmd ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textSecondary ?? "#9aa5ce")
                }
            }

            // Custom block indicator
            Rectangle {
                visible: cardRoot.blockData && cardRoot.blockData.is_custom
                height: 20
                implicitWidth: customBadgeText.implicitWidth + 12
                radius: 4
                color: Qt.rgba(0.9, 0.7, 0.2, 0.15)
                border.color: Qt.rgba(0.9, 0.7, 0.2, 0.35)
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: customBadgeText
                    anchors.centerIn: parent
                    text: "custom"
                    font.family: cardRoot.font
                    font.pixelSize: 10
                    font.bold: true
                    color: "#e0af68"
                }
            }

            Item { Layout.fillWidth: true }

            // Master Toggle Switch
            Rectangle {
                id: blockSwitchTrack
                width: 44
                height: 24
                radius: 12
                color: cardRoot.editEnabled ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgSelected ?? Qt.rgba(1, 1, 1, 0.15))
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: 140 } }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: cardRoot.editEnabled ? parent.width - width - 3 : 3
                    color: cardRoot.editEnabled ? "#ffffff" : (root.theme.textPrimary ?? "#c0caf5")

                    Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        cardRoot.editEnabled = !cardRoot.editEnabled;
                        let payload = {
                            enabled: cardRoot.editEnabled,
                            name: cardRoot.editName,
                            raw_text: (cardRoot.blockData && cardRoot.blockData.raw_text) ? cardRoot.blockData.raw_text : cardRoot.editRawText
                        };
                        cardRoot.blockSaved(cardRoot.blockIndex, payload);
                    }
                }
            }

            // Edit / Done Button (Clean Text)
            Rectangle {
                implicitWidth: editBtnText.implicitWidth + 20
                height: 28
                radius: 6
                color: editHover.hovered ? (root.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.12)) : Qt.rgba(1, 1, 1, 0.06)
                border.color: cardRoot.isExpanded ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1))
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                HoverHandler { id: editHover }

                Text {
                    id: editBtnText
                    anchors.centerIn: parent
                    text: cardRoot.isExpanded ? "Close" : "Edit"
                    font.family: cardRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: cardRoot.isExpanded ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cardRoot.isExpanded = !cardRoot.isExpanded
                }
            }
        }

        /* --- Summary Row (Visible when collapsed) --- */
        RowLayout {
            visible: !cardRoot.isExpanded
            Layout.fillWidth: true
            spacing: 8

            // Text / Command Monospace Box
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumWidth: 100
                height: 30
                radius: 6
                color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3)
                border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                TextInput {
                    id: summaryInput
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    text: (cardRoot.blockData && cardRoot.blockData.raw_text) ? cardRoot.blockData.raw_text : cardRoot.editRawText
                    font.family: cardRoot.font
                    font.pixelSize: 11
                    color: cardRoot.editEnabled ? (root.theme.textSecondary ?? "#9aa5ce") : (root.theme.textMuted ?? "#666666")
                    selectByMouse: true
                    onEditingFinished: {
                        if (cardRoot.editIsCmd) {
                            let m = text.match(/^cmd\[update:\d+\]\s*(.*)$/);
                            if (m) {
                                cardRoot.editCmdBody = m[1];
                            } else {
                                cardRoot.editCmdBody = text;
                            }
                        } else {
                            cardRoot.editRawText = text;
                        }
                        let payload = {
                            enabled: cardRoot.editEnabled,
                            name: cardRoot.editName,
                            raw_text: text
                        };
                        cardRoot.blockSaved(cardRoot.blockIndex, payload);
                    }
                }
            }

            // Compact "Run / Test" Button for Shell Commands
            Rectangle {
                visible: cardRoot.editIsCmd
                implicitWidth: runSummaryText.implicitWidth + 20
                height: 30
                radius: 6
                color: runSummaryHover.hovered ? (root.theme.accentPrimary ?? "#7aa2f7") : Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.15)
                border.color: root.theme.accentPrimary ?? "#7aa2f7"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                HoverHandler { id: runSummaryHover }

                Text {
                    id: runSummaryText
                    anchors.centerIn: parent
                    text: cardRoot.isEvaluating ? "Running..." : "Run Test"
                    font.family: cardRoot.font
                    font.pixelSize: 10
                    font.bold: true
                    color: runSummaryHover.hovered ? "#ffffff" : (root.theme.accentPrimary ?? "#7aa2f7")
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !cardRoot.isEvaluating
                    onClicked: cardRoot.runTest()
                }
            }
        }

        // Compact execution output pill (if tested and collapsed)
        Rectangle {
            visible: !cardRoot.isExpanded && cardRoot.testOutput !== ""
            Layout.fillWidth: true
            implicitHeight: testOutRow.implicitHeight + 8
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.45)
            border.color: root.theme.accentPrimary ?? "#7aa2f7"
            border.width: 1

            RowLayout {
                id: testOutRow
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: 8
                }
                spacing: 8

                Text {
                    text: "Output:"
                    font.family: cardRoot.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.theme.accentPrimary ?? "#7aa2f7"
                }

                Text {
                    text: cardRoot.testOutput
                    font.family: cardRoot.font
                    font.pixelSize: 11
                    color: root.theme.textPrimary ?? "#ffffff"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 20
                    height: 20
                    radius: 4
                    color: closeOutHover.hovered ? Qt.rgba(1,1,1,0.2) : "transparent"
                    HoverHandler { id: closeOutHover }
                    Text {
                        anchors.centerIn: parent
                        text: "x"
                        font.family: cardRoot.font
                        font.pixelSize: 11
                        color: root.theme.textMuted ?? "#888888"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.testOutput = ""
                    }
                }
            }
        }

        /* --- Expanded Smart Editor Section --- */
        ColumnLayout {
            visible: cardRoot.isExpanded
            Layout.fillWidth: true
            spacing: 12

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // Block Name Field
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "Block Name"
                    font.family: cardRoot.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textPrimary
                    Layout.preferredWidth: 140
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 6
                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    TextInput {
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        text: cardRoot.editName
                        font.family: cardRoot.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                        selectByMouse: true
                        onTextChanged: cardRoot.editName = text
                    }
                }
            }

            // Mode Selector: Plain Text vs Shell Script
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "Content Type"
                    font.family: cardRoot.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textPrimary
                    Layout.preferredWidth: 140
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 6
                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 4

                        // Option 1: Plain Text / Variable
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 4
                            color: !cardRoot.editIsCmd ? root.theme.bgSelected : "transparent"
                            border.color: !cardRoot.editIsCmd ? (root.theme.accentPrimary ?? "#7aa2f7") : "transparent"
                            border.width: !cardRoot.editIsCmd ? 1 : 0

                            Text {
                                anchors.centerIn: parent
                                text: "Plain Text / Variables ($USER)"
                                font.family: cardRoot.font
                                font.pixelSize: 11
                                font.bold: !cardRoot.editIsCmd
                                color: !cardRoot.editIsCmd ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textSecondary ?? "#9aa5ce")
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: cardRoot.editIsCmd = false
                            }
                        }

                        // Option 2: Shell Script (cmd)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 4
                            color: cardRoot.editIsCmd ? root.theme.bgSelected : "transparent"
                            border.color: cardRoot.editIsCmd ? (root.theme.accentPrimary ?? "#7aa2f7") : "transparent"
                            border.width: cardRoot.editIsCmd ? 1 : 0

                            Text {
                                anchors.centerIn: parent
                                text: "Shell Script (cmd[update])"
                                font.family: cardRoot.font
                                font.pixelSize: 11
                                font.bold: cardRoot.editIsCmd
                                color: cardRoot.editIsCmd ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textSecondary ?? "#9aa5ce")
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: cardRoot.editIsCmd = true
                            }
                        }
                    }
                }
            }

            // Shell Script Fields (when editIsCmd is true)
            ColumnLayout {
                visible: cardRoot.editIsCmd
                Layout.fillWidth: true
                spacing: 8

                // Update Interval Selector
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "Update Interval"
                        font.family: cardRoot.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textPrimary
                        Layout.preferredWidth: 140
                    }

                    // Interval Presets
                    RowLayout {
                        spacing: 6
                        Layout.fillWidth: true

                        Repeater {
                            model: [
                                { label: "1s (1000ms)", val: 1000 },
                                { label: "5s (5000ms)", val: 5000 },
                                { label: "1m (60000ms)", val: 60000 },
                                { label: "1h (3600000ms)", val: 3600000 }
                            ]
                            delegate: Rectangle {
                                implicitWidth: intLabel.implicitWidth + 14
                                height: 28
                                radius: 5
                                color: cardRoot.editCmdInterval === modelData.val ? root.theme.bgSelected : Qt.rgba(1, 1, 1, 0.04)
                                border.color: cardRoot.editCmdInterval === modelData.val ? root.theme.accentPrimary : Qt.rgba(1, 1, 1, 0.08)
                                border.width: 1

                                Text {
                                    id: intLabel
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: cardRoot.font
                                    font.pixelSize: 10
                                    font.bold: cardRoot.editCmdInterval === modelData.val
                                    color: cardRoot.editCmdInterval === modelData.val ? (root.theme.accentPrimary ?? "#7aa2f7") : (root.theme.textPrimary ?? "#ffffff")
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: cardRoot.editCmdInterval = modelData.val
                                }
                            }
                        }
                    }
                }

                // Command / Script Input
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Shell Script Command"
                        font.family: cardRoot.font
                        font.pixelSize: 12
                        font.bold: true
                        color: root.theme.textPrimary
                    }

                    Text {
                        text: "Executed in bash. Can run system binaries, scripts ($HOME/.config/hypr/scripts), or pipe output."
                        font.family: cardRoot.font
                        font.pixelSize: 11
                        color: root.theme.textSecondary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 6
                        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1

                        TextInput {
                            id: cmdInput
                            anchors {
                                fill: parent
                                leftMargin: 10
                                rightMargin: 10
                            }
                            verticalAlignment: TextInput.AlignVCenter
                            text: cardRoot.editCmdBody
                            font.family: cardRoot.font
                            font.pixelSize: 12
                            color: root.theme.textPrimary
                            selectByMouse: true
                            onTextChanged: cardRoot.editCmdBody = text
                        }
                    }
                }

                // Live Run / Test Command Box
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        implicitWidth: runBtnText.implicitWidth + 24
                        height: 32
                        radius: 6
                        color: runBtnHover.hovered ? (root.theme.accentPrimary ?? "#7aa2f7") : Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.2)
                        border.color: root.theme.accentPrimary ?? "#7aa2f7"
                        border.width: 1

                        HoverHandler { id: runBtnHover }

                        Text {
                            id: runBtnText
                            anchors.centerIn: parent
                            text: cardRoot.isEvaluating ? "Executing..." : "Execute & Test Output"
                            font.family: cardRoot.font
                            font.pixelSize: 11
                            font.bold: true
                            color: runBtnHover.hovered ? "#ffffff" : (root.theme.accentPrimary ?? "#7aa2f7")
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: !cardRoot.isEvaluating
                            onClicked: cardRoot.runTest()
                        }
                    }

                    Text {
                        text: cardRoot.isEvaluating ? "Running in bash..." : (cardRoot.testOutput !== "" ? "Command finished" : "Click to test output live")
                        font.family: cardRoot.font
                        font.pixelSize: 11
                        color: root.theme.textMuted ?? "#888888"
                    }
                }

                // Live Execution Output Box
                Rectangle {
                    visible: cardRoot.testOutput !== ""
                    Layout.fillWidth: true
                    implicitHeight: Math.max(38, evalOutputText.implicitHeight + 16)
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.45)
                    border.color: root.theme.accentPrimary ?? "#7aa2f7"
                    border.width: 1

                    Text {
                        id: evalOutputText
                        anchors {
                            fill: parent
                            margins: 10
                        }
                        text: cardRoot.testOutput
                        font.family: cardRoot.font
                        font.pixelSize: 11
                        color: root.theme.textPrimary ?? "#ffffff"
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }

            // Plain Text / Variable Fields (when editIsCmd is false)
            ColumnLayout {
                visible: !cardRoot.editIsCmd
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Text / Variable Value"
                    font.family: cardRoot.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 6
                    color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.3)
                    border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    TextInput {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        text: cardRoot.editRawText
                        font.family: cardRoot.font
                        font.pixelSize: 12
                        color: root.theme.textPrimary
                        selectByMouse: true
                        onTextChanged: cardRoot.editRawText = text
                    }
                }

                // Quick Insert Variable Buttons
                RowLayout {
                    spacing: 6
                    Text {
                        text: "Quick Insert:"
                        font.family: cardRoot.font
                        font.pixelSize: 10
                        color: root.theme.textMuted
                    }

                    Repeater {
                        model: ["$USER", "$LAYOUT", "$TIME", "Locked"]
                        delegate: Rectangle {
                            implicitWidth: pillText.implicitWidth + 12
                            height: 22
                            radius: 4
                            color: pillHover.hovered ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.06)
                            border.color: Qt.rgba(1,1,1,0.1)
                            border.width: 1

                            HoverHandler { id: pillHover }

                            Text {
                                id: pillText
                                anchors.centerIn: parent
                                text: modelData
                                font.family: cardRoot.font
                                font.pixelSize: 10
                                color: root.theme.textSecondary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    cardRoot.editRawText = modelData;
                                }
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // Position & Typography Controls
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Horizontal Alignment
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Horizontal Align"
                        font.family: cardRoot.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 5
                        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: 2

                            Repeater {
                                model: ["left", "center", "right"]
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 3
                                    color: cardRoot.editHalign === modelData ? root.theme.bgSelected : "transparent"
                                    border.color: cardRoot.editHalign === modelData ? root.theme.accentPrimary : "transparent"
                                    border.width: cardRoot.editHalign === modelData ? 1 : 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                        font.family: cardRoot.font
                                        font.pixelSize: 10
                                        font.bold: cardRoot.editHalign === modelData
                                        color: cardRoot.editHalign === modelData ? (root.theme.accentPrimary ?? "#7aa2f7") : root.theme.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: cardRoot.editHalign = modelData
                                    }
                                }
                            }
                        }
                    }
                }

                // Vertical Alignment
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Vertical Align"
                        font.family: cardRoot.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 5
                        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: 2

                            Repeater {
                                model: ["top", "center", "bottom"]
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 3
                                    color: cardRoot.editValign === modelData ? root.theme.bgSelected : "transparent"
                                    border.color: cardRoot.editValign === modelData ? root.theme.accentPrimary : "transparent"
                                    border.width: cardRoot.editValign === modelData ? 1 : 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                        font.family: cardRoot.font
                                        font.pixelSize: 10
                                        font.bold: cardRoot.editValign === modelData
                                        color: cardRoot.editValign === modelData ? (root.theme.accentPrimary ?? "#7aa2f7") : root.theme.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: cardRoot.editValign = modelData
                                    }
                                }
                            }
                        }
                    }
                }

                // Coordinates (X, Y)
                ColumnLayout {
                    Layout.preferredWidth: 140
                    spacing: 4

                    Text {
                        text: "Offset (X, Y)"
                        font.family: cardRoot.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    RowLayout {
                        spacing: 4
                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: 5
                            color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1

                            TextInput {
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                text: String(cardRoot.editPosX)
                                font.family: cardRoot.font
                                font.pixelSize: 11
                                color: root.theme.textPrimary
                                selectByMouse: true
                                onTextChanged: {
                                    let v = parseInt(text);
                                    if (!isNaN(v)) cardRoot.editPosX = v;
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: 5
                            color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                            border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1

                            TextInput {
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                text: String(cardRoot.editPosY)
                                font.family: cardRoot.font
                                font.pixelSize: 11
                                color: root.theme.textPrimary
                                selectByMouse: true
                                onTextChanged: {
                                    let v = parseInt(text);
                                    if (!isNaN(v)) cardRoot.editPosY = v;
                                }
                            }
                        }
                    }
                }

                // Font Size
                ColumnLayout {
                    Layout.preferredWidth: 80
                    spacing: 4

                    Text {
                        text: "Font Size"
                        font.family: cardRoot.font
                        font.pixelSize: 11
                        font.bold: true
                        color: root.theme.textSecondary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 5
                        color: root.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                        border.color: root.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        TextInput {
                            anchors.fill: parent
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            text: String(cardRoot.editFontSize)
                            font.family: cardRoot.font
                            font.pixelSize: 11
                            color: root.theme.textPrimary
                            selectByMouse: true
                            onTextChanged: {
                                let v = parseInt(text);
                                if (!isNaN(v)) cardRoot.editFontSize = v;
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // Footer Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Delete Button (for custom blocks)
                Rectangle {
                    visible: cardRoot.blockData && cardRoot.blockData.is_custom
                    implicitWidth: delText.implicitWidth + 20
                    height: 32
                    radius: 6
                    color: delHover.hovered ? (root.theme.accentRed ?? "#f7768e") : Qt.rgba(0.9, 0.3, 0.3, 0.15)
                    border.color: root.theme.accentRed ?? "#f7768e"
                    border.width: 1

                    HoverHandler { id: delHover }

                    Text {
                        id: delText
                        anchors.centerIn: parent
                        text: "Delete Block"
                        font.family: cardRoot.font
                        font.pixelSize: 11
                        font.bold: true
                        color: delHover.hovered ? "#ffffff" : (root.theme.accentRed ?? "#f7768e")
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.blockDeleted(cardRoot.blockIndex)
                    }
                }

                Item { Layout.fillWidth: true }

                // Cancel / Close Button
                Rectangle {
                    implicitWidth: cancelText.implicitWidth + 20
                    height: 32
                    radius: 6
                    color: cancelHover.hovered ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.05)
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    HoverHandler { id: cancelHover }

                    Text {
                        id: cancelText
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: cardRoot.font
                        font.pixelSize: 11
                        color: root.theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.isExpanded = false
                    }
                }

                // Save & Apply Button
                Rectangle {
                    implicitWidth: saveText.implicitWidth + 24
                    height: 32
                    radius: 6
                    color: saveHover.hovered ? (root.theme.accentPrimary ?? "#7aa2f7") : Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.85)

                    Behavior on color { ColorAnimation { duration: 120 } }
                    HoverHandler { id: saveHover }

                    Text {
                        id: saveText
                        anchors.centerIn: parent
                        text: "Apply Changes"
                        font.family: cardRoot.font
                        font.pixelSize: 11
                        font.bold: true
                        color: "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.saveChanges()
                    }
                }
            }
        }
    }
}
