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
import "../../ControlCenter/Components" as CCComponents
import "../Components"
import ".."

Rectangle {
  required property var hostRoot
  required property var hostContainer
  id: mediaPill
  readonly property var player: hostRoot.activePlayer
  readonly property bool hasMedia: player !== null && (player.trackTitle || player.identity)
  readonly property bool isPlaying: player !== null && player.playbackState === MprisPlaybackState.Playing
  property bool isPinned: false

  implicitHeight: hostContainer.isVert ? hostContainer.scaled(28) : (hostContainer.hidePill ? hostContainer.height : hostContainer.horizPillHeight)
  implicitWidth: hostContainer.isVert
    ? hostContainer.vertPillWidth
    : (hasMedia ? Math.min(200, mediaContent.implicitWidth + hostContainer.scaled(16)) : (mediaEmptyContent.implicitWidth + hostContainer.scaled(14)))
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
    active: mediaPill.isPlaying || mediaPill.isPinned || mediaMouse.pressed
    hovered: mediaMouse.containsMouse || mediaHover.hovered
    accentColor: hostContainer.wAccent("media", hostRoot.theme.accentPrimary)
  }

  HoverHandler { id: mediaHover }

  Item {
    id: mediaProvider
    visible: false
    width: 0
    height: 0
    property Item target: mediaPill
    property var barItem: hostContainer
    property var hostRoot: mediaPill.hostRoot
    property bool hovered: mediaHover.hovered || mediaMouse.containsMouse
    property bool pinned: mediaPill.isPinned
    property bool effectiveHovered: false
    readonly property bool isSharedCardHovered: Boolean(barItem && barItem.activeInfoProvider === mediaProvider && barItem.sharedInfoPopup && barItem.sharedInfoPopup.cardHovered)
    readonly property bool isDetailsActive: effectiveHovered || pinned || isSharedCardHovered
    property var theme: hostRoot.theme
    property string font: hostRoot.font
    property string title: "Media"
    property string icon: ""
    property color accent: hostContainer.wAccent("media", hostRoot.theme.accentPrimary)
    property bool hideHeader: true
    property int preferredWidth: 300
    property int preferredHeight: 0
    property var rows: []

    Timer {
      id: mediaCloseTimer
      interval: 150
      onTriggered: {
        if (!mediaProvider.hovered && !mediaProvider.isSharedCardHovered) {
          mediaProvider.effectiveHovered = false;
          if (hostContainer.activeInfoProvider === mediaProvider && !mediaProvider.pinned)
            hostContainer.activeInfoProvider = null;
        }
      }
    }
    onHoveredChanged: {
      if (hovered) { mediaCloseTimer.stop(); effectiveHovered = true; hostContainer.activeInfoProvider = mediaProvider; }
      else if (!isSharedCardHovered) mediaCloseTimer.restart();
    }
    onIsSharedCardHoveredChanged: {
      if (isSharedCardHovered) { mediaCloseTimer.stop(); effectiveHovered = true; }
      else if (!hovered) mediaCloseTimer.restart();
    }
    onPinnedChanged: {
      if (pinned) {
        const o = hostContainer.activeInfoProvider;
        if (o && o !== mediaProvider && o.target && o.target.isPinned !== undefined) o.target.isPinned = false;
        hostContainer.activeInfoProvider = mediaProvider;
      } else if (!hovered && !isSharedCardHovered && hostContainer.activeInfoProvider === mediaProvider) {
        hostContainer.activeInfoProvider = null;
      }
    }
    Component.onDestruction: {
      if (hostContainer.activeInfoProvider === mediaProvider) hostContainer.activeInfoProvider = null;
    }

    property Component contentComponent: Component {
      Item {
        id: mediaCardWrap
        readonly property bool showControl: mediaCard.hasMedia
        width: mediaProvider.preferredWidth
        implicitWidth: mediaProvider.preferredWidth
        implicitHeight: showControl ? mediaCard.implicitHeight : emptyMediaCard.implicitHeight

        CCComponents.MediaControl {
          id: mediaCard
          width: mediaProvider.preferredWidth
          theme: mediaProvider.theme
          font: mediaProvider.font
        }

        Rectangle {
          id: emptyMediaCard
          visible: !mediaCardWrap.showControl
          width: mediaProvider.preferredWidth
          implicitHeight: 56
          height: implicitHeight
          radius: 10
          color: Qt.rgba(mediaProvider.theme.textPrimary.r, mediaProvider.theme.textPrimary.g, mediaProvider.theme.textPrimary.b, 0.05)
          border.color: mediaProvider.theme.bgBorder
          border.width: 1

          RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
              text: "󰎆"
              font.family: mediaProvider.font
              font.pixelSize: 16
              color: mediaProvider.theme.textMuted
            }

            Text {
              text: "No media playing"
              font.family: mediaProvider.font
              font.pixelSize: 12
              color: mediaProvider.theme.textSecondary
            }
          }
        }
      }
    }
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
      font.pixelSize: hostContainer.scaled(13)
      font.family: hostRoot.font
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: mediaPill.player ? (mediaPill.player.trackTitle || mediaPill.player.identity || "Media") : ""
      color: hostRoot.theme.textPrimary
      font.pixelSize: hostContainer.scaled(11)
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
      font.pixelSize: hostContainer.scaled(13)
      font.family: hostRoot.font
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "No Media"
      color: hostRoot.theme.textMuted
      font.pixelSize: hostContainer.scaled(11)
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
    font.pixelSize: hostContainer.scaled(13)
    font.family: hostRoot.font
  }

  MouseArea {
    id: mediaMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        mediaPill.isPinned = !mediaPill.isPinned;
      } else if (mediaPill.player) {
        if (mouse.button === Qt.RightButton) mediaPill.player.next();
        else if (mouse.button === Qt.MiddleButton) mediaPill.player.togglePlaying();
      }
    }
  }
}
