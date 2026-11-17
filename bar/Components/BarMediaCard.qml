import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import ".."

Rectangle {
    id: root

    property var theme: DefaultTheme {}
    property string font: "Lato Nerd Font"

    readonly property var player: {
        const list = Mpris.players.values;
        const playing = list.find(p => p.isPlaying && p.trackTitle && p.trackTitle.trim() !== "");
        if (playing) return playing;
        const loaded = list.find(p => p.trackTitle && p.trackTitle.trim() !== "");
        if (loaded) return loaded;
        return null;
    }

    readonly property bool hasMedia: player !== null
        && ((player.trackTitle && player.trackTitle.trim() !== "") || player.isPlaying)

    property real currentPos: player ? player.position : 0
    readonly property real trackLen: (player && player.length > 0) ? player.length : 0
    readonly property bool isCompact: BarConfig.mediaPopupStyle === "compact"
    readonly property bool showArt: BarConfig.mediaShowAlbumArt !== false
    readonly property bool showSeek: BarConfig.mediaShowSeekbar !== false

    visible: hasMedia
    width: parent ? parent.width : 300
    height: mainCol.implicitHeight + (isCompact ? 20 : 24)
    implicitHeight: height
    implicitWidth: 300
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
        id: mainCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: root.isCompact ? 10 : 12
        }
        spacing: root.isCompact ? 8 : 10

        // FULL LAYOUT: Centered Title/Artist -> Centered Large Art
        ColumnLayout {
            visible: !root.isCompact
            Layout.fillWidth: true
            spacing: 10

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
                    text: root.player ? (root.player.trackArtist || root.player.albumTitle || "Unknown Artist") : ""
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                visible: root.showArt
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 110
                Layout.preferredHeight: 110
                radius: 12
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1
                clip: true

                Text {
                    anchors.centerIn: parent
                    text: "󰎈"
                    font.family: root.font
                    font.pixelSize: 36
                    color: root.theme.accentPrimary
                    visible: fullArtImg.status !== Image.Ready
                }

                Image {
                    id: fullArtImg
                    anchors.fill: parent
                    anchors.margins: 1
                    source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
                    sourceSize.width: 220
                    sourceSize.height: 220
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }
        }

        // COMPACT LAYOUT: Small Art + Title/Artist + Inline Controls
        RowLayout {
            visible: root.isCompact
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                visible: root.showArt
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 8
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1
                clip: true

                Text {
                    anchors.centerIn: parent
                    text: "󰎈"
                    font.family: root.font
                    font.pixelSize: 20
                    color: root.theme.accentPrimary
                    visible: artImg.status !== Image.Ready
                }

                Image {
                    id: artImg
                    anchors.fill: parent
                    anchors.margins: 1
                    source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
                    sourceSize.width: 104
                    sourceSize.height: 104
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: root.player ? (root.player.trackTitle || "Unknown Title") : "Unknown Title"
                    font.family: root.font
                    font.pixelSize: 12
                    font.bold: true
                    color: root.theme.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.player ? (root.player.trackArtist || root.player.albumTitle || "Unknown Artist") : ""
                    font.family: root.font
                    font.pixelSize: 11
                    color: root.theme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Inline controls when compact
            Row {
                spacing: 4

                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: prevCompactMouse.containsMouse ? root.theme.bgHover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        font.family: root.font
                        font.pixelSize: 14
                        color: (root.player && root.player.canGoPrevious) ? root.theme.textPrimary : root.theme.textMuted
                    }
                    MouseArea {
                        id: prevCompactMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                    }
                }

                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: root.theme.accentPrimary
                    Text {
                        anchors.centerIn: parent
                        text: (root.player && root.player.isPlaying) ? "󰏤" : "󰐊"
                        font.family: root.font
                        font.pixelSize: 14
                        color: root.theme.bgBase
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player) root.player.togglePlaying()
                    }
                }

                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: nextCompactMouse.containsMouse ? root.theme.bgHover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        font.family: root.font
                        font.pixelSize: 14
                        color: (root.player && root.player.canGoNext) ? root.theme.textPrimary : root.theme.textMuted
                    }
                    MouseArea {
                        id: nextCompactMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player && root.player.canGoNext) root.player.next()
                    }
                }
            }
        }

        // Full playback controls row
        RowLayout {
            visible: !root.isCompact
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 14

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 30; Layout.preferredHeight: 30; radius: 15
                color: prevMouse.containsMouse ? root.theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.family: root.font
                    font.pixelSize: 16
                    color: (root.player && root.player.canGoPrevious) ? root.theme.textPrimary : root.theme.textMuted
                }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                }
            }

            Rectangle {
                Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 18
                color: root.theme.accentPrimary
                scale: playMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
                Text {
                    anchors.centerIn: parent
                    text: (root.player && root.player.isPlaying) ? "󰏤" : "󰐊"
                    font.family: root.font
                    font.pixelSize: 18
                    color: root.theme.bgBase
                }
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.player) root.player.togglePlaying()
                }
            }

            Rectangle {
                Layout.preferredWidth: 30; Layout.preferredHeight: 30; radius: 15
                color: nextMouse.containsMouse ? root.theme.bgHover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.family: root.font
                    font.pixelSize: 16
                    color: (root.player && root.player.canGoNext) ? root.theme.textPrimary : root.theme.textMuted
                }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.player && root.player.canGoNext) root.player.next()
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Seekbar
        RowLayout {
            visible: root.showSeek && root.trackLen > 0
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.formatTime(root.currentPos)
                font.family: root.font
                font.pixelSize: 10
                color: root.theme.textMuted
            }

            Rectangle {
                id: seekTrack
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: root.theme.bgSelected

                readonly property real progress: root.trackLen > 0
                    ? Math.max(0, Math.min(1, root.currentPos / root.trackLen))
                    : 0

                Rectangle {
                    width: parent.width * seekTrack.progress
                    height: parent.height
                    radius: parent.radius
                    color: root.theme.accentPrimary
                }

                MouseArea {
                    id: seekMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.player && root.player.canSeek && root.trackLen > 0
                    function seekTo(mouse) {
                        if (!root.player || !root.player.canSeek || seekTrack.width <= 0 || root.trackLen <= 0) return;
                        const x = mapToItem(seekTrack, mouse.x, 0).x;
                        const frac = Math.max(0, Math.min(1, x / seekTrack.width));
                        const target = frac * root.trackLen;
                        root.player.position = target;
                        root.currentPos = target;
                    }
                    onPressed: (mouse) => seekTo(mouse)
                    onPositionChanged: (mouse) => { if (pressed) seekTo(mouse); }
                    onClicked: (mouse) => seekTo(mouse)
                }
            }

            Text {
                text: root.formatTime(root.trackLen)
                font.family: root.font
                font.pixelSize: 10
                color: root.theme.textMuted
            }
        }
    }
}
