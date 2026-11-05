import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import ".."

Item {
    id: mediaRoot

    property var theme: DefaultTheme {}
    property string font: "JetBrainsMono Nerd Font"

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

    visible: LockscreenConfig.showMedia && hasMedia
    implicitWidth: 320
    implicitHeight: 74

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: Qt.rgba(mediaRoot.theme.bgSurface.r, mediaRoot.theme.bgSurface.g, mediaRoot.theme.bgSurface.b, 0.75)
        border.width: 1
        border.color: mediaRoot.theme.bgBorder

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // Track Art / Icon
            Rectangle {
                width: 48
                height: 48
                radius: 10
                color: mediaRoot.theme.bgBase
                clip: true

                Image {
                    anchors.fill: parent
                    source: (mediaRoot.activePlayer && mediaRoot.activePlayer.trackArtUrl) ? mediaRoot.activePlayer.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !mediaRoot.activePlayer || !mediaRoot.activePlayer.trackArtUrl
                    text: "󰎆"
                    font.family: mediaRoot.font
                    font.pixelSize: 22
                    color: mediaRoot.theme.accentPrimary
                }
            }

            // Track Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: (mediaRoot.activePlayer && mediaRoot.activePlayer.trackTitle) ? mediaRoot.activePlayer.trackTitle : "Unknown Title"
                    font.family: mediaRoot.font
                    font.pixelSize: 13
                    font.bold: true
                    color: mediaRoot.theme.textPrimary
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: (mediaRoot.activePlayer && mediaRoot.activePlayer.trackArtist) ? mediaRoot.activePlayer.trackArtist : "Unknown Artist"
                    font.family: mediaRoot.font
                    font.pixelSize: 11
                    color: mediaRoot.theme.textSecondary
                    elide: Text.ElideRight
                }
            }

            // Media Controls
            RowLayout {
                spacing: 4

                // Previous Button
                Item {
                    width: 30
                    height: 30
                    enabled: mediaRoot.activePlayer && mediaRoot.activePlayer.canGoPrevious

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        font.family: mediaRoot.font
                        font.pixelSize: 16
                        color: parent.enabled ? mediaRoot.theme.textPrimary : mediaRoot.theme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer.previous()
                    }
                }

                // Play / Pause Button
                Item {
                    width: 34
                    height: 34
                    enabled: mediaRoot.activePlayer && mediaRoot.activePlayer.canTogglePlaying

                    Rectangle {
                        anchors.fill: parent
                        radius: 17
                        color: mediaRoot.theme.accentPrimary

                        Text {
                            anchors.centerIn: parent
                            text: (mediaRoot.activePlayer && mediaRoot.activePlayer.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                            font.family: mediaRoot.font
                            font.pixelSize: 15
                            color: mediaRoot.theme.bgBase
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer.togglePlaying()
                    }
                }

                // Next Button
                Item {
                    width: 30
                    height: 30
                    enabled: mediaRoot.activePlayer && mediaRoot.activePlayer.canGoNext

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        font.family: mediaRoot.font
                        font.pixelSize: 16
                        color: parent.enabled ? mediaRoot.theme.textPrimary : mediaRoot.theme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer.next()
                    }
                }
            }
        }
    }
}
