import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"
    property int currentBrightness: 50
    property bool hasBacklightDevice: true

    width: parent ? parent.width : 300
    height: brightnessCol.implicitHeight + 24
    implicitHeight: height
    implicitWidth: width
    radius: 10
    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
    border.color: root.theme.bgBorder
    border.width: 1

    // File watcher to sync live if brightness changes externally (e.g. Fn keys)
    FileView {
        id: brightnessWatchFile
        path: ""
        watchChanges: true
        onFileChanged: root.refresh()
    }

    Process {
        id: backlightDiscovery
        command: ["sh", "-c", "ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -n 1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p) brightnessWatchFile.path = p;
            }
        }
    }

    // Read current brightness
    Process {
        id: brightnessStatusProc
        command: ["sh", "-c", "if [ -n \"$(ls -A /sys/class/backlight 2>/dev/null)\" ]; then brightnessctl -c backlight -m 2>/dev/null | head -n 1; else brightnessctl -m 2>/dev/null | head -n 1; fi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim();
                if (!line) return;
                const parts = line.split(",");
                // brightnessctl -m format: device_name,class,current_value,percentage,max_value
                if (parts.length >= 4) {
                    root.hasBacklightDevice = (parts[1] === "backlight");
                    const pctStr = parts[3].indexOf("%") !== -1 ? parts[3] : (parts[4] || "");
                    const val = parseInt(pctStr.replace("%", "").trim());
                    if (!isNaN(val)) root.currentBrightness = Math.max(0, Math.min(100, val));
                }
            }
        }
    }

    // Set brightness
    Process {
        id: setBrightnessProc
        running: false
    }

    function setBrightness(percent) {
        const clamped = Math.max(1, Math.min(100, Math.round(percent)));
        root.currentBrightness = clamped;
        if (root.hasBacklightDevice) {
            setBrightnessProc.command = ["brightnessctl", "-c", "backlight", "set", clamped + "%"];
        } else {
            setBrightnessProc.command = ["brightnessctl", "set", clamped + "%"];
        }
        setBrightnessProc.running = true;
    }

    function refresh() {
        brightnessStatusProc.running = true;
    }

    Component.onCompleted: {
        root.refresh();
    }

    Connections {
        target: (typeof controlCenter !== "undefined") ? controlCenter : null
        function onRefreshRequested() { root.refresh(); }
    }

    ColumnLayout {
        id: brightnessCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 12
        }
        spacing: 10

        Text {
            text: "Brightness"
            font.family: root.font
            font.pixelSize: 12
            font.bold: true
            color: root.theme.textPrimary
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Brightness Icon
            Rectangle {
                width: 28; height: 28; radius: 7
                color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "󰃠"
                    font.family: root.font
                    font.pixelSize: 15
                    color: root.theme.textPrimary
                }
            }

            // Brightness Slider
            Rectangle {
                id: sliderBg
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.18)

                Rectangle {
                    id: sliderFill
                    height: parent.height
                    radius: 4
                    width: Math.min(parent.width, parent.width * (root.currentBrightness / 100.0))
                    color: root.theme.accentPrimary
                    Behavior on width {
                        enabled: !sliderMouse.pressed
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }
                }

                Rectangle {
                    width: 14; height: 14; radius: 7
                    y: (parent.height - height) / 2
                    x: Math.max(0, Math.min(sliderBg.width - width, sliderFill.width - (width / 2)))
                    color: root.theme.textPrimary
                }

                MouseArea {
                    id: sliderMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => updateBrightness(mouse.x, width)
                    onPositionChanged: (mouse) => { if (pressed) updateBrightness(mouse.x, width) }

                    function updateBrightness(mouseX, totalWidth) {
                        const percent = Math.max(0, Math.min(100, Math.round((mouseX / totalWidth) * 100)));
                        root.currentBrightness = percent;
                        root.setBrightness(percent);
                    }
                }
            }

            // Percentage
            Text {
                text: root.currentBrightness + "%"
                font.family: root.font
                font.pixelSize: 11
                font.bold: true
                color: root.theme.textSecondary
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
