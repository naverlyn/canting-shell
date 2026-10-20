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
import "./Hyprlock"

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
    clip: true
    color: cardHover.hovered ? (cardRoot.theme.bgHover ?? Qt.rgba(1, 1, 1, 0.05)) : (cardRoot.theme.bgSurface ?? Qt.rgba(0, 0, 0, 0.2))
    border.color: isExpanded 
        ? (cardRoot.theme.accentPrimary ?? "#7aa2f7") 
        : (cardHover.hovered ? Qt.rgba(cardRoot.theme.accentPrimary.r, cardRoot.theme.accentPrimary.g, cardRoot.theme.accentPrimary.b, 0.4) : (cardRoot.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.08)))
    border.width: isExpanded ? 1.5 : 1

    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
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

    function resolveColor(colStr) {
        if (!colStr) return "#ffffff";
        let str = String(colStr).trim();
        if (str.startsWith("#")) return str;
        if (str.startsWith("rgb(") || str.startsWith("rgba(")) {
            let m = str.match(/rgba?\(\s*([0-9a-fA-F]{6})\s*\)/);
            if (m) return "#" + m[1];
            let m2 = str.match(/rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/);
            if (m2) return Qt.rgba(parseInt(m2[1])/255, parseInt(m2[2])/255, parseInt(m2[3])/255, 1);
        }
        const wallustMap = {
            "$color0": "#404145", "$color1": "#131B43", "$color2": "#464F58", "$color3": "#4D576B",
            "$color4": "#6B777D", "$color5": "#A2B3B5", "$color6": "#A2B3B5", "$color7": "#E3EEF0",
            "$color8": "#9FA7A8", "$color9": "#828bb8", "$color10": "#5E6A76", "$color11": "#67748F",
            "$color12": "#8F9EA7", "$color13": "#D8EEF1", "$color14": "#D8EEF1", "$color15": "#E3EEF0",
            "$foreground": "#F1F9FA", "$background": "#1A1A1E",
            "$accentPrimary": (cardRoot.theme && cardRoot.theme.accentPrimary) ? String(cardRoot.theme.accentPrimary) : "#7aa2f7"
        };
        if (wallustMap[str]) return wallustMap[str];
        return "#ffffff";
    }

    property string testOutput: ""
    property bool isEvaluating: false

    onBlockDataChanged: {
        editPosX = blockData && blockData.position_x !== undefined ? blockData.position_x : 0;
        editPosY = blockData && blockData.position_y !== undefined ? blockData.position_y : 0;
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
            editColor = blockData && blockData.color ? blockData.color : "$color8";
        }
    }

    readonly property string scriptPath: Qt.resolvedUrl("../scripts/manage_hyprlock.sh").toString().replace(/^file:\/\//, "")

    // Shell script execution runner
    Process {
        id: evalProc
        property string cmdToRun: ""
        command: [cardRoot.scriptPath, "eval", cmdToRun]
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
        HyprlockBlockHeaderRow {
            hostCard: cardRoot
        }

        /* --- Summary Row (Visible when collapsed) --- */
        HyprlockBlockCommandPreviewRow {
            hostCard: cardRoot
        }

        // Compact execution output pill (if tested and collapsed)
        HyprlockBlockOutputPill {
            hostCard: cardRoot
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
                    color: cardRoot.theme.textPrimary
                    Layout.preferredWidth: 140
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 6
                    color: cardRoot.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                    border.color: cardRoot.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
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
                        color: cardRoot.theme.textPrimary
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
                    color: cardRoot.theme.textPrimary
                    Layout.preferredWidth: 140
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 6
                    color: cardRoot.theme.bgBase ?? Qt.rgba(0, 0, 0, 0.25)
                    border.color: cardRoot.theme.bgBorder ?? Qt.rgba(1, 1, 1, 0.1)
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
                            color: !cardRoot.editIsCmd ? cardRoot.theme.bgSelected : "transparent"
                            border.color: !cardRoot.editIsCmd ? (cardRoot.theme.accentPrimary ?? "#7aa2f7") : "transparent"
                            border.width: !cardRoot.editIsCmd ? 1 : 0

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Plain Text / Variables ($USER)"
                                font.family: cardRoot.font
                                font.pixelSize: 11
                                font.bold: !cardRoot.editIsCmd
                                color: !cardRoot.editIsCmd ? (cardRoot.theme.accentPrimary ?? "#7aa2f7") : (cardRoot.theme.textSecondary ?? "#9aa5ce")

                                Behavior on color { ColorAnimation { duration: 140 } }
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
                            color: cardRoot.editIsCmd ? cardRoot.theme.bgSelected : "transparent"
                            border.color: cardRoot.editIsCmd ? (cardRoot.theme.accentPrimary ?? "#7aa2f7") : "transparent"
                            border.width: cardRoot.editIsCmd ? 1 : 0

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Shell Script (cmd[update])"
                                font.family: cardRoot.font
                                font.pixelSize: 11
                                font.bold: cardRoot.editIsCmd
                                color: cardRoot.editIsCmd ? (cardRoot.theme.accentPrimary ?? "#7aa2f7") : (cardRoot.theme.textSecondary ?? "#9aa5ce")

                                Behavior on color { ColorAnimation { duration: 140 } }
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
            HyprlockBlockShellFields {
                hostCard: cardRoot
            }

            // Plain Text / Variable Fields (when editIsCmd is false)
            HyprlockBlockTextFields {
                hostCard: cardRoot
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // Position & Typography Controls
            HyprlockBlockPositionTypographyRow {
                hostCard: cardRoot
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // Color Configuration Section
            HyprlockBlockColorSection {
                hostCard: cardRoot
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // Footer Action Buttons
            HyprlockBlockFooterActions {
                hostCard: cardRoot
            }
        }
    }
}
