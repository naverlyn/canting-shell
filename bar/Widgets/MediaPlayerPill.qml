import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Services.SystemTray
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick.Effects
import "../../ControlCenter"
import "../Components"
import ".."

Rectangle {
  required property var hostRoot
  required property var hostContainer
  id: mediaPill
  readonly property var player: hostRoot.activePlayer
  readonly property bool hasMedia: player !== null && (player.trackTitle || player.identity)
  readonly property bool isPlaying: player !== null && player.playbackState === MprisPlaybackState.Playing

  implicitHeight: hostContainer.isVert ? 28 : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert
    ? hostContainer.vertPillWidth
    : (hasMedia ? Math.min(200, mediaContent.implicitWidth + 16) : (mediaEmptyContent.implicitWidth + 14))
  height: implicitHeight
  width: implicitWidth
  scale: mediaMouse.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("media", mediaMouse.containsMouse)
  border.color: hostContainer.wBorder("media")
  border.width: hostContainer.hasCustomColor("media") ? 1 : 0
  clip: true
  Behavior on color { ColorAnimation { duration: 150 } }

  PillIndicator {
    hostRoot: mediaPill.hostRoot
    hostContainer: mediaPill.hostContainer
    active: mediaPill.isPlaying || mediaMouse.pressed
    hovered: mediaMouse.containsMouse
    accentColor: hostContainer.wAccent("media", hostRoot.theme.accentPrimary)
  }

  Row {
    id: mediaContent
    visible: !hostContainer.isVert && mediaPill.hasMedia
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: mediaPill.isPlaying ? "󰏤" : "󰐊"
      color: hostContainer.wAccent("media", hostRoot.theme.accentPrimary)
      font.pixelSize: 13
      font.family: hostRoot.font
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: mediaPill.player ? (mediaPill.player.trackTitle || mediaPill.player.identity || "Media") : ""
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
      elide: Text.ElideRight
      width: Math.min(implicitWidth, 160)
    }
  }

  Row {
    id: mediaEmptyContent
    visible: !hostContainer.isVert && !mediaPill.hasMedia
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "󰎆"
      color: hostContainer.hasCustomColor("media")
        ? hostContainer.wAccent("media", hostRoot.theme.textMuted)
        : hostRoot.theme.textMuted
      font.pixelSize: 13
      font.family: hostRoot.font
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "No Media"
      color: hostRoot.theme.textMuted
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Text {
    visible: hostContainer.isVert
    anchors.centerIn: parent
    text: mediaPill.hasMedia ? (mediaPill.isPlaying ? "󰏤" : "󰐊") : "󰎆"
    color: (mediaPill.hasMedia || hostContainer.hasCustomColor("media"))
      ? hostContainer.wAccent("media", hostRoot.theme.accentPrimary)
      : hostRoot.theme.textMuted
    font.pixelSize: 13
    font.family: hostRoot.font
  }

  MouseArea {
    id: mediaMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: (mouse) => {
      if (!mediaPill.player) return;
      if (mouse.button === Qt.LeftButton) mediaPill.player.togglePlaying();
      else if (mouse.button === Qt.RightButton) mediaPill.player.next();
      else if (mouse.button === Qt.MiddleButton) mediaPill.player.previous();
    }
  }
}
