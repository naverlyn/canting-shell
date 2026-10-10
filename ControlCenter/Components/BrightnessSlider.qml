import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    property var theme
    property string font: "Hack Nerd Font"
    property int currentBrightness: 50

    width: parent ? parent.width : 300
    height: brightnessCol.implicitHeight + 24
    radius: 10
    color: root.theme ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05) : Qt.rgba(1, 1, 1, 0.05)
    border.color: root.theme ? root.theme.bgBorder : Qt.rgba(1, 1, 1, 0.06)
    border.width: 1

    // Read current brightness
    Process {
        id: brightnessStatusProc
        command: ["sh", "-c", "brightnessctl -m | head -n 1 | awk -F, '{print $5}' | tr -d '%'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(text.trim());
                if (!isNaN(val)) root.currentBrightness = val;
            }
        }
    }

    // Set brightness
    Process {
        id: setBrightnessProc
        running: false
    }

    function setBrightness(percent) {
        setBrightnessProc.command = ["brightnessctl", "set", Math.round(percent) + "%"];
        setBrightnessProc.running = true;
    }

    function refresh() {
        brightnessStatusProc.running = true;
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
            color: root.theme ? root.theme.textPrimary : "#cdd6f4"
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Brightness Icon
            Rectangle {
                width: 28; height: 28; radius: 7
                color: root.theme ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.06) : Qt.rgba(1, 1, 1, 0.05)

                Text {
                    anchors.centerIn: parent
                    text: "󰃠"
                    font.family: root.font
                    font.pixelSize: 15
                    color: root.theme ? root.theme.textPrimary : "#cdd6f4"
                }
            }

            // Brightness Slider
            Rectangle {
                id: sliderBg
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: root.theme 
                    ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.18) 
                    : Qt.rgba(1, 1, 1, 0.15)

                Rectangle {
                    id: sliderFill
                    height: parent.height
                    radius: 4
                    width: Math.min(parent.width, parent.width * (root.currentBrightness / 100.0))
                    color: root.theme ? root.theme.accentPrimary : "#a6e3a1"
                    Behavior on width {
                        enabled: !sliderMouse.pressed
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }
                }

                Rectangle {
                    width: 14; height: 14; radius: 7
                    y: (parent.height - height) / 2
                    x: Math.max(0, Math.min(sliderBg.width - width, sliderFill.width - (width / 2)))
                    color: root.theme ? root.theme.textPrimary : "#cdd6f4"
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
                color: root.theme ? root.theme.textSecondary : "#a6adc8"
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
