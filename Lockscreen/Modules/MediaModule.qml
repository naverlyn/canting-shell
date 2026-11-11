import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import ".."

Item {
    id: root

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"
    property var moduleData: ({})
    property bool previewMode: false
    property real scaleFactor: 1.0

    readonly property bool isCompact: !moduleData || moduleData.displayMode !== "full"
    readonly property bool showCard: (moduleData && moduleData.showCard !== undefined) ? Boolean(moduleData.showCard) : true

    readonly property var activePlayer: {
        const players = Mpris.players.values;
        if (!players || players.length === 0) return null;
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }
        return players[0];
    }

    readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle !== "" || activePlayer.trackArtist !== "")

    property real currentPos: activePlayer ? activePlayer.position : 0
    readonly property real trackLen: (activePlayer && activePlayer.length > 0) ? activePlayer.length : 0

    function formatTime(seconds) {
        if (!seconds || seconds < 0 || isNaN(seconds)) return "0:00";
        const totalSec = Math.floor(seconds);
        const mins = Math.floor(totalSec / 60);
        const secs = totalSec % 60;
        return mins + ":" + (secs < 10 ? "0" + secs : secs);
    }

    Timer {
        interval: 1000
        running: !root.isCompact && root.activePlayer !== null && root.activePlayer.playbackState === MprisPlaybackState.Playing
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.activePlayer) {
                root.activePlayer.positionChanged();
                root.currentPos = root.activePlayer.position;
            }
        }
    }

    implicitWidth: isCompact
        ? Math.max(140, Math.round(320 * root.scaleFactor))
        : Math.max(180, Math.round(320 * root.scaleFactor))

    implicitHeight: isCompact
        ? Math.max(34, Math.round(74 * root.scaleFactor))
        : Math.max(130, Math.round(230 * root.scaleFactor))

    Rectangle {
        anchors.fill: parent
        radius: Math.max(8, Math.round(16 * root.scaleFactor))
        color: root.showCard
            ? Qt.rgba(root.theme.bgSurface.r, root.theme.bgSurface.g, root.theme.bgSurface.b, 0.78)
            : "transparent"
        border.width: root.showCard ? 1 : 0
        border.color: root.theme.bgBorder

        // -------------------------------------------------------------
        // 1. COMPACT MEDIA PLAYER (Horizontal Pill Layout)
        // -------------------------------------------------------------
        RowLayout {
            visible: root.isCompact
            anchors.fill: parent
            anchors.margins: Math.max(4, Math.round(10 * root.scaleFactor))
            spacing: Math.max(4, Math.round(10 * root.scaleFactor))

            // Track Art / Icon
            Rectangle {
                width: Math.max(22, Math.round(48 * root.scaleFactor))
                height: width
                radius: Math.max(4, Math.round(10 * root.scaleFactor))
                color: root.theme.bgBase
                clip: true

                Image {
                    anchors.fill: parent
                    source: (root.activePlayer && root.activePlayer.trackArtUrl) ? root.activePlayer.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.activePlayer || !root.activePlayer.trackArtUrl
                    text: "󰎆"
                    font.family: root.font
                    font.pixelSize: Math.max(11, Math.round(22 * root.scaleFactor))
                    color: root.theme.accentPrimary
                }
            }

            // Track Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: (root.activePlayer && root.activePlayer.trackTitle) ? root.activePlayer.trackTitle : "No Media Playing"
                    font.family: root.font
                    font.pixelSize: Math.max(8, Math.round(13 * root.scaleFactor))
                    font.bold: true
                    color: root.theme.textPrimary
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: (root.activePlayer && root.activePlayer.trackArtist) ? root.activePlayer.trackArtist : "MPRIS Player"
                    font.family: root.font
                    font.pixelSize: Math.max(7, Math.round(11 * root.scaleFactor))
                    color: root.theme.textSecondary
                    elide: Text.ElideRight
                }
            }

            // Controls
            RowLayout {
                spacing: Math.max(2, Math.round(4 * root.scaleFactor))

                // Previous
                Rectangle {
                    width: Math.max(16, Math.round(28 * root.scaleFactor))
                    height: width
                    radius: width / 2
                    color: prevCompactHover.hovered ? root.theme.bgHover : "transparent"
                    HoverHandler { id: prevCompactHover }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        font.family: root.font
                        font.pixelSize: Math.max(9, Math.round(14 * root.scaleFactor))
                        color: (root.activePlayer && root.activePlayer.canGoPrevious) ? root.theme.textPrimary : root.theme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer && root.activePlayer.canGoPrevious) root.activePlayer.previous()
                    }
                }

                // Play / Pause Circle
                Rectangle {
                    width: Math.max(20, Math.round(34 * root.scaleFactor))
                    height: width
                    radius: width / 2
                    color: root.theme.accentPrimary
                    scale: playCompactMouse.pressed ? 0.94 : (playCompactHover.hovered ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    HoverHandler { id: playCompactHover }

                    Text {
                        anchors.centerIn: parent
                        text: (root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                        font.family: root.font
                        font.pixelSize: Math.max(10, Math.round(15 * root.scaleFactor))
                        color: root.theme.bgBase
                    }

                    MouseArea {
                        id: playCompactMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
                    }
                }

                // Next
                Rectangle {
                    width: Math.max(16, Math.round(28 * root.scaleFactor))
                    height: width
                    radius: width / 2
                    color: nextCompactHover.hovered ? root.theme.bgHover : "transparent"
                    HoverHandler { id: nextCompactHover }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        font.family: root.font
                        font.pixelSize: Math.max(9, Math.round(14 * root.scaleFactor))
                        color: (root.activePlayer && root.activePlayer.canGoNext) ? root.theme.textPrimary : root.theme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer && root.activePlayer.canGoNext) root.activePlayer.next()
                    }
                }
            }
        }

        // -------------------------------------------------------------
        // 2. FULL MEDIA PLAYER (Detailed Card Layout like Control Center)
        // -------------------------------------------------------------
        ColumnLayout {
            visible: !root.isCompact
            anchors.fill: parent
            anchors.margins: Math.max(6, Math.round(12 * root.scaleFactor))
            spacing: Math.max(4, Math.round(8 * root.scaleFactor))

            // Track Title & Artist (Centered)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: (root.activePlayer && root.activePlayer.trackTitle) ? root.activePlayer.trackTitle : "No Media Playing"
                    font.family: root.font
                    font.pixelSize: Math.max(9, Math.round(13 * root.scaleFactor))
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    color: root.theme.textPrimary
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: (root.activePlayer && root.activePlayer.trackArtist) ? root.activePlayer.trackArtist : "MPRIS Player"
                    font.family: root.font
                    font.pixelSize: Math.max(8, Math.round(11 * root.scaleFactor))
                    horizontalAlignment: Text.AlignHCenter
                    color: root.theme.textSecondary
                    elide: Text.ElideRight
                }
            }

            // Center Album Art
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: Math.max(40, Math.round(80 * root.scaleFactor))
                height: width
                radius: Math.max(6, Math.round(10 * root.scaleFactor))
                color: root.theme.bgBase
                border.color: root.theme.bgBorder
                border.width: 1
                clip: true

                Text {
                    anchors.centerIn: parent
                    text: "󰎈"
                    font.family: root.font
                    font.pixelSize: Math.max(16, Math.round(32 * root.scaleFactor))
                    color: root.theme.textMuted
                    visible: albumArtFullImg.status !== Image.Ready
                }

                Image {
                    id: albumArtFullImg
                    anchors.fill: parent
                    source: (root.activePlayer && root.activePlayer.trackArtUrl) ? root.activePlayer.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }

            // Seek Bar + Timestamps
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Item {
                    id: fullSeekBar
                    Layout.fillWidth: true
                    height: Math.max(8, Math.round(12 * root.scaleFactor))

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: Math.max(2, Math.round(4 * root.scaleFactor))
                        radius: height / 2
                        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.18)

                        Rectangle {
                            height: parent.height
                            radius: height / 2
                            width: {
                                if (root.trackLen <= 0) return 0;
                                const ratio = Math.max(0, Math.min(1, root.currentPos / root.trackLen));
                                return parent.width * ratio;
                            }
                            color: root.theme.accentPrimary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.activePlayer !== null && root.trackLen > 0
                        onPressed: (mouse) => seekTo(mouse.x)
                        onPositionChanged: (mouse) => { if (pressed) seekTo(mouse.x); }
                        function seekTo(mouseX) {
                            if (root.activePlayer && root.trackLen > 0) {
                                const ratio = Math.max(0, Math.min(1, mouseX / fullSeekBar.width));
                                const targetPos = ratio * root.trackLen;
                                root.currentPos = targetPos;
                                if (root.activePlayer.canSeek) {
                                    root.activePlayer.position = targetPos;
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.formatTime(root.currentPos)
                        font.family: root.font
                        font.pixelSize: Math.max(7, Math.round(9 * root.scaleFactor))
                        color: root.theme.textMuted
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.formatTime(root.trackLen)
                        font.family: root.font
                        font.pixelSize: Math.max(7, Math.round(9 * root.scaleFactor))
                        color: root.theme.textMuted
                    }
                }
            }

            // Transport Controls (Prev, Play/Pause Circle, Next)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Math.max(8, Math.round(16 * root.scaleFactor))

                // Prev
                Rectangle {
                    width: Math.max(18, Math.round(30 * root.scaleFactor))
                    height: width
                    radius: width / 2
                    color: prevFullHover.hovered ? root.theme.bgHover : "transparent"
                    HoverHandler { id: prevFullHover }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        font.family: root.font
                        font.pixelSize: Math.max(10, Math.round(16 * root.scaleFactor))
                        color: (root.activePlayer && root.activePlayer.canGoPrevious) ? root.theme.textPrimary : root.theme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer && root.activePlayer.canGoPrevious) root.activePlayer.previous()
                    }
                }

                // Play / Pause Circle
                Rectangle {
                    width: Math.max(22, Math.round(36 * root.scaleFactor))
                    height: width
                    radius: width / 2
                    color: root.theme.accentPrimary
                    scale: playFullMouse.pressed ? 0.94 : (playFullHover.hovered ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    HoverHandler { id: playFullHover }

                    Text {
                        anchors.centerIn: parent
                        text: (root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                        font.family: root.font
                        font.pixelSize: Math.max(11, Math.round(16 * root.scaleFactor))
                        color: root.theme.bgBase
                    }

                    MouseArea {
                        id: playFullMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
                    }
                }

                // Next
                Rectangle {
                    width: Math.max(18, Math.round(30 * root.scaleFactor))
                    height: width
                    radius: width / 2
                    color: nextFullHover.hovered ? root.theme.bgHover : "transparent"
                    HoverHandler { id: nextFullHover }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        font.family: root.font
                        font.pixelSize: Math.max(10, Math.round(16 * root.scaleFactor))
                        color: (root.activePlayer && root.activePlayer.canGoNext) ? root.theme.textPrimary : root.theme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.activePlayer && root.activePlayer.canGoNext) root.activePlayer.next()
                    }
                }
            }
        }
    }
}
