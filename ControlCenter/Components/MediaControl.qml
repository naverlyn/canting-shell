import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"

    // Pick a playing/loaded player first
    readonly property var player: {
        const list = Mpris.players.values;
        const playing = list.find(p => p.isPlaying && p.trackTitle && p.trackTitle.trim() !== "");
        if (playing) return playing;
        const loaded = list.find(p => p.trackTitle && p.trackTitle.trim() !== "");
        if (loaded) return loaded;
        return null;
    }

    // Hide the panel when no track is loaded
    readonly property bool hasMedia: player !== null
        && ((player.trackTitle && player.trackTitle.trim() !== "") || player.isPlaying)

    property real currentPos: player ? player.position : 0
    readonly property real trackLen: (player && player.length > 0) ? player.length : 0

    visible: hasMedia
    width: parent ? parent.width : 300
    height: mprisCol.implicitHeight + 28
    radius: 10
    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.05)
    border.color: root.theme.bgBorder
    border.width: 1

    function formatTime(seconds) {
        if (!seconds || seconds < 0 || isNaN(seconds)) return "0:00";
        const totalSec = Math.floor(seconds);
        const mins = Math.floor(totalSec / 60);
        const secs = totalSec % 60;
        return mins + ":" + (secs < 10 ? "0" + secs : secs);
    }

    // Poll player position every second while playing
    Timer {
        interval: 1000
        running: root.visible && root.player !== null && root.player.isPlaying
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.player) {
                root.player.positionChanged();
                root.currentPos = root.player.position;
            }
        }
    }

    Connections {
        target: root.player
        function onPositionChanged() {
            if (!seekMouse.pressed && root.player) {
                root.currentPos = root.player.position;
            }
        }
        function onTrackTitleChanged() {
            if (root.player) root.currentPos = root.player.position;
        }
    }

    ColumnLayout {
        id: mprisCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 14
        }
        spacing: 12

        // 1. Top: Centered Song Title & Artist Name
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.player ? (root.player.trackTitle || "Unknown Title") : "Unknown Title"
                font.family: root.font
                font.pixelSize: 14
                font.bold: true
                color: root.theme.textPrimary
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.player ? (root.player.trackArtist || "Unknown Artist") : "Unknown Artist"
                font.family: root.font
                font.pixelSize: 11
                color: root.theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // 2. Center: Album Art
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 120
            height: 120
            radius: 10
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1
            clip: true

            // Fallback Icon when no Album Art is available
            Text {
                anchors.centerIn: parent
                text: "󰎈"
                font.family: root.font
                font.pixelSize: 42
                color: root.theme.textMuted
                visible: albumArtImg.status !== Image.Ready
            }

            Image {
                id: albumArtImg
                anchors.fill: parent
                anchors.margins: 1
                source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
        }

        // 3. Seek Bar + Timestamps
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            // Progress Track
            Item {
                id: seekBarContainer
                Layout.fillWidth: true
                height: 14

                Rectangle {
                    id: seekTrackBg
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.18)

                    Rectangle {
                        id: seekTrackFill
                        height: parent.height
                        radius: 2
                        width: {
                            if (root.trackLen <= 0) return 0;
                            const ratio = Math.max(0, Math.min(1, root.currentPos / root.trackLen));
                            return parent.width * ratio;
                        }
                        color: root.theme.accentPrimary
                    }
                }

                // Seek Thumb
                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(seekBarContainer.width - width, seekTrackFill.width - (width / 2)))
                    color: root.theme.textPrimary
                }

                MouseArea {
                    id: seekMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.player !== null && root.trackLen > 0
                    onPressed: (mouse) => seekTo(mouse.x)
                    onPositionChanged: (mouse) => {
                        if (pressed) seekTo(mouse.x);
                    }
                    function seekTo(mouseX) {
                        if (root.player && root.trackLen > 0) {
                            const ratio = Math.max(0, Math.min(1, mouseX / seekBarContainer.width));
                            const targetPos = ratio * root.trackLen;
                            root.currentPos = targetPos;
                            if (root.player.canSeek) {
                                root.player.position = targetPos;
                            }
                        }
                    }
                }
            }

            // Timestamps Row (1:28 ... 4:15)
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.formatTime(root.currentPos)
                    font.family: root.font
                    font.pixelSize: 10
                    color: root.theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.formatTime(root.trackLen)
                    font.family: root.font
                    font.pixelSize: 10
                    color: root.theme.textSecondary
                }
            }
        }

        // 4. Bottom: Transport Controls (Shuffle, Prev, Play/Pause Circle, Next, Loop)
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 18

            // Shuffle Button
            Item {
                width: 28; height: 28
                Layout.alignment: Qt.AlignVCenter
                Text {
                    anchors.centerIn: parent
                    text: "󰒟"
                    font.family: root.font
                    font.pixelSize: 16
                    color: (root.player && root.player.shuffle) 
                        ? root.theme.textPrimary 
                        : root.theme.textMuted
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player && root.player.shuffleSupported) {
                            root.player.shuffle = !root.player.shuffle;
                        }
                    }
                }
            }

            // Previous Button
            Item {
                width: 32; height: 32
                Layout.alignment: Qt.AlignVCenter
                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.family: root.font
                    font.pixelSize: 22
                    color: prevMouse.containsMouse 
                        ? root.theme.textPrimary 
                        : root.theme.textSecondary
                }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.player) root.player.previous()
                }
            }

            // Center Play / Pause Circle Button
            Rectangle {
                width: 42
                height: 42
                radius: 21
                Layout.alignment: Qt.AlignVCenter
                color: playMouse.containsMouse
                    ? root.theme.accentCyan
                    : root.theme.accentPrimary

                Text {
                    anchors.centerIn: parent
                    text: (root.player && root.player.isPlaying) ? "󰏤" : "󰐊"
                    font.family: root.font
                    font.pixelSize: 20
                    color: root.theme.bgBase
                }

                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.player) root.player.togglePlaying()
                }
            }

            // Next Button
            Item {
                width: 32; height: 32
                Layout.alignment: Qt.AlignVCenter
                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.family: root.font
                    font.pixelSize: 22
                    color: nextMouse.containsMouse 
                        ? root.theme.textPrimary 
                        : root.theme.textSecondary
                }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.player) root.player.next()
                }
            }

            // Repeat / Loop Button
            Item {
                width: 28; height: 28
                Layout.alignment: Qt.AlignVCenter
                Text {
                    anchors.centerIn: parent
                    text: (root.player && root.player.loopState === MprisLoopState.Track) ? "󰑘" : "󰑖"
                    font.family: root.font
                    font.pixelSize: 16
                    color: (root.player && root.player.loopState !== MprisLoopState.None) 
                        ? root.theme.textPrimary 
                        : root.theme.textMuted
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player && root.player.loopSupported) {
                            if (root.player.loopState === MprisLoopState.None) {
                                root.player.loopState = MprisLoopState.Playlist;
                            } else if (root.player.loopState === MprisLoopState.Playlist) {
                                root.player.loopState = MprisLoopState.Track;
                            } else {
                                root.player.loopState = MprisLoopState.None;
                            }
                        }
                    }
                }
            }
        }
    }
}
