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
    property string font: "Lato Nerd Font"
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
    property string editFontFamily: blockData && blockData.font_family ? blockData.font_family : "$font"
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
        const t = cardRoot.theme || {};
        const pHex   = String(t.accentPrimary ?? "#cba6f7");
        const cHex   = String(t.accentCyan ?? "#89b4fa");
        const gHex   = String(t.accentGreen ?? "#a6e3a1");
        const oHex   = String(t.accentOrange ?? "#fab387");
        const rHex   = String(t.accentRed ?? "#f38ba8");
        const bgBase = String(t.bgBase ?? "#1e1e2e");
        const bgSurf = String(t.bgSurface ?? "#313244");
        const bgHov  = String(t.bgHover ?? "#45475a");
        const bgSel  = String(t.bgSelected ?? "#585b70");
        const txtPri = String(t.textPrimary ?? "#cdd6f4");
        const txtSec = String(t.textSecondary ?? "#bac2de");
        const txtMut = String(t.textMuted ?? "#a6adc8");

        const wallustMap = {
            "$color0": bgSurf, "$color1": rHex, "$color2": gHex, "$color3": oHex,
            "$color4": cHex, "$color5": pHex, "$color6": cHex, "$color7": txtSec,
            "$color8": txtMut, "$color9": rHex, "$color10": txtSec, "$color11": oHex,
            "$color12": cHex, "$color13": pHex, "$color14": gHex, "$color15": txtPri,
            "$foreground": txtPri, "$background": bgBase,
            "$accentPrimary": pHex, "$accent": pHex,
            "$mauve": pHex, "$pink": pHex,
            "$blue": cHex, "$sapphire": cHex, "$sky": cHex, "$lavender": cHex,
            "$teal": gHex, "$green": gHex,
            "$yellow": oHex, "$peach": oHex,
            "$maroon": rHex, "$red": rHex, "$flamingo": rHex,
            "$rosewater": txtPri,
            "$text": txtPri, "$subtext1": txtSec, "$subtext0": txtMut,
            "$surface2": bgSel, "$surface1": bgHov, "$surface0": bgSurf,
            "$overlay2": txtMut, "$overlay1": bgSel, "$overlay0": bgHov,
            "$base": bgBase, "$mantle": bgBase, "$crust": bgBase
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
            editFontFamily = blockData && blockData.font_family ? blockData.font_family : "$font";
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
            font_family: cardRoot.editFontFamily.trim() !== "" ? cardRoot.editFontFamily.trim() : "$font",
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
