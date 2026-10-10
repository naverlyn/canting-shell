import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    property var theme
    property string font

    property var displays: []
    property int brightness: 50

    Process {
        id: displayProc
        command: ["sh", "-c", "hyprctl monitors -j | awk '/\"name\"/ {match($0, /\"name\": \"([^\"]+)\"/, a); name=a[1]} /\"width\"/ {w=$2; sub(/,/, \"\", w)} /\"height\"/ {h=$2; sub(/,/, \"\", h)} /\"refreshRate\"/ {r=$2; sub(/,/, \"\", r); print name\" \"w\"x\"h\" @ \"r\"Hz\"}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const res = [];
                for (const line of lines) {
                    if (!line) continue;
                    const parts = line.split(" ");
                    if (parts.length >= 2) {
                        res.push({
                            name: parts[0],
                            resolution: parts.slice(1).join(" ")
                        });
                    }
                }
                root.displays = res;
            }
        }
    }

    Process {
        id: brightProc
        command: ["brightnessctl", "i", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length >= 4) {
                    const pct = parseInt(parts[3].replace("%", ""));
                    if (!isNaN(pct)) root.brightness = pct;
                }
            }
        }
    }

    Process {
        id: openMonitorsProc
        command: ["qs", "ipc", "call", "monitors", "toggle"]
        running: false
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: {
            displayProc.running = true;
            brightProc.running = true;
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 20

            Text {
                text: "Displays"
                font.family: root.font
                font.pixelSize: 20
                font.bold: true
                color: root.theme.textPrimary
                Layout.fillWidth: true
            }

            // Display Monitor Cards
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                model: root.displays
                interactive: false
                spacing: 8
                
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 64
                    radius: 8
                    color: root.theme.bgSelected
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16

                        Text {
                            text: "󰍹"
                            font.family: root.font
                            font.pixelSize: 24
                            color: root.theme.accentPrimary
                        }

                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: modelData.name
                                font.family: root.font
                                font.pixelSize: 14
                                font.bold: true
                                color: root.theme.textPrimary
                            }
                            Text {
                                text: modelData.resolution
                                font.family: root.font
                                font.pixelSize: 12
                                color: root.theme.textSecondary
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }

            // Brightness Control Section with Slider Ball Handle
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Brightness: " + root.brightness + "%"
                    font.family: root.font
                    font.pixelSize: 13
                    font.bold: true
                    color: root.theme.textPrimary
                }

                Rectangle {
                    id: sliderTrack
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: root.theme.bgSelected

                    // Progress Fill Bar
                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        width: Math.max(0, Math.min(parent.width, parent.width * (root.brightness / 100)))
                        color: root.theme.accentPrimary
                    }

                    // Slider Ball / Knob
                    Rectangle {
                        id: sliderBall
                        width: sliderMouse.containsMouse || sliderMouse.pressed ? 18 : 14
                        height: width
                        radius: width / 2
                        color: root.theme.accentPrimary
                        border.color: root.theme.bgBase
                        border.width: 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(sliderTrack.width - width, (sliderTrack.width * (root.brightness / 100)) - (width / 2)))

                        Behavior on width { NumberAnimation { duration: 100 } }
                        Behavior on x { NumberAnimation { duration: sliderMouse.pressed ? 0 : 80; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: sliderMouse
                        anchors.fill: parent
                        anchors.margins: -6 // Larger clickable/touch target
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                let pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)));
                                setBrightProc.command = ["brightnessctl", "s", pct + "%"];
                                setBrightProc.running = true;
                                root.brightness = pct;
                            }
                        }
                        onClicked: (mouse) => {
                            let pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)));
                            setBrightProc.command = ["brightnessctl", "s", pct + "%"];
                            setBrightProc.running = true;
                            root.brightness = pct;
                        }
                    }
                    
                    Process { id: setBrightProc }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.08)
            }

            // Advanced Display Settings Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "Advanced Settings"
                    font.family: root.font
                    font.pixelSize: 15
                    font.bold: true
                    color: root.theme.accentPrimary
                    Layout.fillWidth: true
                }

                // Monitor Layout & Manager Launcher Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 64
                    radius: 8
                    color: monMouse.containsMouse ? (root.theme.bgHover ?? Qt.rgba(1,1,1,0.05)) : root.theme.bgSelected
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        Text {
                            text: "󰆍"
                            font.family: root.font
                            font.pixelSize: 22
                            color: root.theme.accentPrimary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "Monitor Layout & Arrangement"
                                font.family: root.font
                                font.pixelSize: 13
                                font.bold: true
                                color: root.theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "Drag to reposition, scale, rotate, or set mirror modes"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textSecondary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 28
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            width: 100
                            height: 28
                            radius: 6
                            color: root.theme.bgSurface
                            border.color: root.theme.bgBorder ?? Qt.rgba(1,1,1,0.1)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Open Editor"
                                font.family: root.font
                                font.pixelSize: 11
                                color: root.theme.textPrimary
                            }
                        }
                    }

                    MouseArea {
                        id: monMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openMonitorsProc.running = true
                    }
                }
            }
        }
    }
}
