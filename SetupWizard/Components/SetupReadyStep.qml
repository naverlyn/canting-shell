import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: root

    required property var theme
    required property string font
    required property var detectedTools
    required property string scriptPath

    signal refreshToolsRequested()

    property bool isInstalling: false
    property string installingTarget: ""
    property string installLog: ""
    property int lastExitCode: -1

    readonly property var toolItems: [
        { key: "awww", label: "Wallpaper (awww/swww)" },
        { key: "wallust", label: "Palette (wallust/matugen)" },
        { key: "cliphist", label: "Clipboard (cliphist)" },
        { key: "cava", label: "Audio Visualizer (cava)" },
        { key: "grim", label: "Screenshot (grim)" },
        { key: "magick", label: "ImageMagick (magick)" },
        { key: "kitty", label: "Terminal (kitty/alacritty/foot)" }
    ]

    readonly property var missingKeys: {
        const out = [];
        for (let i = 0; i < root.toolItems.length; i++) {
            const k = root.toolItems[i].key;
            if (!root.detectedTools || !root.detectedTools[k]) {
                out.push(k);
            }
        }
        return out;
    }

    function appendLog(line) {
        if (root.installLog !== "") {
            root.installLog += "\n" + line;
        } else {
            root.installLog = line;
        }
        Qt.callLater(() => {
            if (termFlickable.contentHeight > termFlickable.height) {
                termFlickable.contentY = termFlickable.contentHeight - termFlickable.height;
            }
        });
    }

    function installKeys(keys, label) {
        if (root.isInstalling || !keys || keys.length === 0) return;
        root.isInstalling = true;
        root.installingTarget = label;
        root.lastExitCode = -1;
        root.installLog = "";
        installProc.command = ["python3", root.scriptPath, "install_tools"].concat(keys);
        installProc.running = true;
    }

    Process {
        id: installProc
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.appendLog(String(data))
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: data => root.appendLog(String(data))
        }
        onExited: (exitCode, exitStatus) => {
            root.isInstalling = false;
            root.lastExitCode = exitCode;
            root.refreshToolsRequested();
        }
    }

    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: "Detected Optional Tools"
            font.family: root.font
            font.pixelSize: 14
            font.bold: true
            color: root.theme.textPrimary
            Layout.fillWidth: true
        }

        Rectangle {
            visible: root.missingKeys.length > 0
            radius: 7
            color: root.isInstalling
                ? root.theme.bgSurface
                : (installAllMouse.containsMouse ? Qt.lighter(root.theme.accentPrimary, 1.12) : root.theme.accentPrimary)
            border.color: root.isInstalling ? root.theme.bgBorder : "transparent"
            border.width: 1
            implicitWidth: installAllLbl.implicitWidth + 18
            implicitHeight: 26
            opacity: root.isInstalling ? 0.6 : 1.0
            scale: (!root.isInstalling && installAllMouse.pressed) ? 0.96 : ((!root.isInstalling && installAllMouse.containsMouse) ? 1.03 : 1.0)
            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            MouseArea {
                id: installAllMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !root.isInstalling
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.installKeys(root.missingKeys, "all missing tools")
            }

            Text {
                id: installAllLbl
                anchors.centerIn: parent
                text: root.isInstalling ? "Installing..." : "Install All Missing (" + root.missingKeys.length + ")"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.isInstalling ? root.theme.textMuted : root.theme.bgBase
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: toolsListCol.implicitHeight + 16
        radius: 10
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: toolsListCol
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Repeater {
                model: root.toolItems
                delegate: RowLayout {
                    required property var modelData
                    readonly property bool installed: Boolean(root.detectedTools && root.detectedTools[modelData.key])
                    Layout.fillWidth: true
                    height: 24
                    spacing: 5

                    Text {
                        text: modelData.label + " is"
                        font.family: root.font
                        font.pixelSize: 12
                        color: installed ? root.theme.textPrimary : root.theme.textMuted
                    }

                    Text {
                        text: installed ? "installed" : "not installed"
                        font.family: root.font
                        font.pixelSize: 12
                        font.bold: installed
                        color: installed ? root.theme.accentPrimary : root.theme.textMuted
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        visible: !installed
                        radius: 6
                        color: installOneMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase
                        border.color: installOneMouse.containsMouse ? root.theme.accentPrimary : root.theme.bgBorder
                        border.width: 1
                        implicitWidth: installOneLbl.implicitWidth + 14
                        implicitHeight: 22
                        opacity: root.isInstalling ? 0.45 : 1.0
                        scale: (!root.isInstalling && installOneMouse.pressed) ? 0.95 : ((!root.isInstalling && installOneMouse.containsMouse) ? 1.03 : 1.0)
                        Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutQuad } }
                        Behavior on border.color { ColorAnimation { duration: 130; easing.type: Easing.OutQuad } }
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

                        MouseArea {
                            id: installOneMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !root.isInstalling
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.installKeys([modelData.key], modelData.label)
                        }

                        Text {
                            id: installOneLbl
                            anchors.centerIn: parent
                            text: "Install"
                            font.family: root.font
                            font.pixelSize: 10
                            font.bold: true
                            color: root.theme.accentPrimary
                        }
                    }
                }
            }
        }
    }

    // Live terminal output when installing optional tools
    Rectangle {
        visible: root.isInstalling || root.installLog !== ""
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 110
        radius: 10
        color: "#11131a"
        border.color: root.isInstalling
            ? root.theme.accentPrimary
            : (root.lastExitCode === 0 ? root.theme.accentGreen : root.theme.bgBorder)
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.isInstalling
                        ? ("Installing " + root.installingTarget + "...")
                        : (root.lastExitCode === 0 ? "Installation complete" : "Installation finished (exit " + root.lastExitCode + ")")
                    font.family: root.font
                    font.pixelSize: 11
                    font.bold: true
                    color: root.isInstalling
                        ? root.theme.accentPrimary
                        : (root.lastExitCode === 0 ? root.theme.accentGreen : root.theme.accentRed)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    visible: !root.isInstalling
                    text: "Hide"
                    font.family: root.font
                    font.pixelSize: 10
                    color: hideTermMouse.containsMouse ? root.theme.textPrimary : root.theme.textMuted

                    MouseArea {
                        id: hideTermMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.installLog = "";
                            root.lastExitCode = -1;
                        }
                    }
                }
            }

            Flickable {
                id: termFlickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: termLogText.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                TextEdit {
                    id: termLogText
                    width: termFlickable.width
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAnywhere
                    text: root.installLog
                    font.family: "monospace"
                    font.pixelSize: 10
                    color: "#d8dee9"
                }
            }
        }
    }

    Rectangle {
        visible: !root.isInstalling && root.installLog === ""
        Layout.fillWidth: true
        implicitHeight: readyInfoCol.implicitHeight + 24
        radius: 10
        color: root.theme.bgSurface
        border.color: root.theme.bgBorder
        border.width: 1

        ColumnLayout {
            id: readyInfoCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text {
                text: "You're ready to go"
                font.family: root.font
                font.pixelSize: 13
                font.bold: true
                color: root.theme.textPrimary
            }

            Text {
                text: "You can reopen this wizard anytime with `qs ipc call setup open`, or fine-tune everything in Settings (`SUPER + I`)."
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textMuted
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    Item {
        visible: !root.isInstalling && root.installLog === ""
        Layout.fillHeight: true
    }
}
