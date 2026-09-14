import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications

PopupWindow {
    id: controlCenter

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"
    property var anchorTarget

    // Toggle states
    property bool wifiEnabled: true

    anchor.window: anchorTarget ? anchorTarget.QsWindow.window : null
    anchor.rect.x: anchorTarget ? anchorTarget.x + anchorTarget.width : 0
    anchor.rect.y: anchorTarget ? anchorTarget.y + anchorTarget.height + 6 : 0
    anchor.rect.width: anchorTarget ? anchorTarget.width : 0
    anchor.rect.height: anchorTarget ? anchorTarget.height : 0

    // Anchor to the bottom-right of the target button
    anchor.edges: Edges.Bottom | Edges.Right
    // Direct gravity downward and leftward into the screen space
    anchor.gravity: Edges.Bottom | Edges.Left

    
    visible: false
    implicitWidth: 320
    implicitHeight: contentColumn.implicitHeight + 24
    color: "transparent"

    // Check if microphone are exist
    PwObjectTracker {
        id: micTracker
        objects: [Pipewire.defaultAudioSource]
    }
    Process { id: wifiProc; running: false }

    // wifi state
    function toggleWifi() {
        wifiEnabled = !wifiEnabled
        wifiProc.command = ["nmcli", "radio", "wifi", wifiEnabled ? "on" : "off"]
        wifiProc.running = true
    }

    // Control Center
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: (controlCenter.theme && controlCenter.theme.bgSurface) || "#1e1e1e" // fallback
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        Column {
            id: contentColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 12

            RowLayout {
                width: parent.width
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 8
                    color: wifiEnabled ? (controlCenter.theme.accentPrimary ? controlCenter.theme.bgSurface : "#4b6584") : Qt.rgba(1,1,1,0.05)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: wifiEnabled ? "󰖩" : "󰖪"
                            font.family: controlCenter.font
                            font.pixelSize: 16
                            color: wifiEnabled ? "#ffffff" : (controlCenter.theme.accentPrimary ? controlCenter.theme.textMuted : "#888")
                        }
                        Text {
                            text: wifiEnabled ? "Wi-Fi" : "Wi-Fi"
                            font.family: controlCenter.font
                            font.pixelSize: 12
                            color: wifiEnabled ? "#ffffff" : (controlCenter.theme.bgSurface ? controlCenter.theme.textPrimary : "#fff")
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toggleWifi()
                    }
                }
            }

            ColumnLayout {
                width: parent.width
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: {
                            const sink = Pipewire.defaultAudioSink;
                            const name = sink && sink.description ? sink.description : "Volume";
                            return "󰕾  " + name;
                        }
                        font.family: controlCenter.font
                        font.pixelSize: 12
                        color: controlCenter.theme.textPrimary ? controlCenter.theme.textSecondary : "#fff"
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: {
                            const sink = Pipewire.defaultAudioSink;
                            if (!sink || !sink.audio) return "0%";
                            return sink.audio.muted ? "Muted" : Math.round(sink.audio.volume * 100) + "%";
                        }
                        font.family: controlCenter.font
                        font.pixelSize: 11
                        color: controlCenter.theme.textPrimary ? controlCenter.theme.textSecondary : "#aaa"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 10
                    radius: 5
                    color: Qt.rgba(1, 1, 1, 0.1)

                    Rectangle {
                        height: parent.height
                        radius: 5
                        width: {
                            const sink = Pipewire.defaultAudioSink;
                            if (!sink || !sink.audio) return 0;
                            return Math.min(parent.width, parent.width * sink.audio.volume);
                        }
                        color: controlCenter.theme.accentPrimary ? controlCenter.theme.bgSurface : "#4b6584"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: (mouse) => updateVolume(mouse.x, width)
                        onPositionChanged: (mouse) => {
                            if (pressed) updateVolume(mouse.x, width)
                        }

                        function updateVolume(mouseX, totalWidth) {
                            const sink = Pipewire.defaultAudioSink;
                            if (sink && sink.audio) {
                                const newVol = Math.max(0, Math.min(1.0, mouseX / totalWidth));
                                sink.audio.volume = newVol;
                                if (sink.audio.muted) sink.audio.muted = false;
                            }
                        }
                    }
                }

                // Microphone Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: {
                            const source = Pipewire.defaultAudioSource;
                            const name = source && source.description ? source.description : "Microphone";
                            return "󰍬  " + name;
                        }
                        font.family: controlCenter.font
                        font.pixelSize: 12
                        color: controlCenter.theme.textPrimary ? controlCenter.theme.textSecondary : "#fff"
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: {
                            const source = Pipewire.defaultAudioSource;
                            if (!source || !source.audio) return "0%";
                            return source.audio.muted ? "Muted" : Math.round(source.audio.volume * 100) + "%";
                        }
                        font.family: controlCenter.font
                        font.pixelSize: 11
                        color: controlCenter.theme.textPrimary ? controlCenter.theme.textSecondary : "#aaa"
                    }
                }

                // Microphone Slider Block
                Rectangle {
                    Layout.fillWidth: true
                    height: 10
                    radius: 5
                    color: Qt.rgba(1, 1, 1, 0.1)

                    Rectangle {
                        height: parent.height
                        radius: 5
                        width: {
                            const source = Pipewire.defaultAudioSource;
                            if (!source || !source.audio) return 0;
                            return Math.min(parent.width, parent.width * source.audio.volume);
                        }
                        color: controlCenter.theme.accentPrimary ? controlCenter.theme.bgSurface : "#4b6584"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: (mouse) => updateVolume(mouse.x, width)
                        onPositionChanged: (mouse) => {
                            if (pressed) updateVolume(mouse.x, width)
                        }

                        function updateVolume(mouseX, totalWidth) {
                            const source = Pipewire.defaultAudioSource;
                            if (source && source.audio) {
                                const newVol = Math.max(0, Math.min(1.0, mouseX / totalWidth));
                                source.audio.volume = newVol;
                                if (source.audio.muted) source.audio.muted = false;
                            }
                        }
                    }
                }
            }
            
            // MPRIS
            Rectangle {
                width: parent.width
                height: 84
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.05)
                visible: root.activePlayer !== null

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    // Top section: Album Art & Track Info
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            width: 36; height: 36; radius: 6
                            color: "#333333"
                            Text { text: "󰎈"; anchors.centerIn: parent; font.family: controlCenter.font; color: "#888" }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true

                            Text {
                                text: root.activePlayer ? (root.activePlayer.trackTitle || "Unknown Title") : ""
                                font.family: controlCenter.font
                                font.pixelSize: 12
                                font.bold: true
                                color: controlCenter.theme.bgSurface ? controlCenter.theme.textPrimary : "#fff"
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: root.activePlayer ? (root.activePlayer.trackArtist || "Unknown Artist") : ""
                                font.family: controlCenter.font
                                font.pixelSize: 10
                                color: controlCenter.theme.bgSurface ? controlCenter.theme.textSecondary : "#aaa"
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                    
                    // Playback Control
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 32

                        Rectangle {
                            height: 24
                            width: prevControl.width + 24
                            radius: 12
                            color: (controlCenter.theme && controlCenter.theme.bgSurface) || "#1e1e1e"

                            Row {
                                id: prevControl
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    text: "󰒮"
                                    font.family: controlCenter.font
                                    font.pixelSize: 16
                                    color: controlCenter.theme.bgSurface ? controlCenter.theme.textPrimary : "#fff"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (root.activePlayer) root.activePlayer.previous()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            height: 24
                            width: playControl.width + 24
                            radius: 12
                            color: (controlCenter.theme && controlCenter.theme.bgSurface) || "#1e1e1e"

                            Row {
                                id: playControl
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    text: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
                                    font.family: controlCenter.font
                                    font.pixelSize: 18
                                    color: controlCenter.theme.textPrimary ? controlCenter.theme.textSecondary : "#fff"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            height: 24
                            width: nextControl.width + 24
                            radius: 12
                            color: (controlCenter.theme && controlCenter.theme.bgSurface) || "#1e1e1e"

                            Row {
                                id: nextControl
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    text: "󰒭"
                                    font.family: controlCenter.font
                                    font.pixelSize: 16
                                    color: controlCenter.theme.textPrimary ? controlCenter.theme.textSecondary : "#fff"
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (root.activePlayer) root.activePlayer.next()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}