import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris
import ".."

Item {
  id: root

  required property var theme
  required property string font
  property color accent: theme.accentPrimary

  property int selectedPlayerIndex: 0

  readonly property var playerList: {
    const vals = Mpris.players.values;
    if (!vals || vals.length === 0) return [];
    const arr = [];
    for (let i = 0; i < vals.length; i++) {
      const p = vals[i];
      if (p && ((p.trackTitle && p.trackTitle.trim() !== "") || p.isPlaying || p.identity)) {
        arr.push(p);
      }
    }
    return arr;
  }

  readonly property var player: {
    const list = playerList;
    if (list.length === 0) return null;
    if (selectedPlayerIndex >= 0 && selectedPlayerIndex < list.length) {
      return list[selectedPlayerIndex];
    }
    const playing = list.find(p => p.isPlaying && p.trackTitle && p.trackTitle.trim() !== "");
    return playing || list[0];
  }

  readonly property bool hasMedia: player !== null && ((player.trackTitle && player.trackTitle.trim() !== "") || player.isPlaying)
  readonly property bool isPlaying: player !== null && player.isPlaying
  property real currentPos: player ? player.position : 0
  readonly property real trackLen: (player && player.length > 0) ? player.length : 0

  implicitHeight: hasMedia ? mediaCol.implicitHeight : emptyBox.implicitHeight
  height: implicitHeight

  function formatTime(seconds) {
    if (!seconds || seconds < 0 || isNaN(seconds)) return "0:00";
    const totalSec = Math.floor(seconds);
    const mins = Math.floor(totalSec / 60);
    const secs = totalSec % 60;
    return mins + ":" + (secs < 10 ? "0" + secs : secs);
  }

  function formatRemaining(pos, len) {
    if (!len || len <= 0) return "-0:00";
    const rem = Math.max(0, len - pos);
    return "-" + formatTime(rem);
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

  // Active MPRIS Player Card
  ColumnLayout {
    id: mediaCol
    visible: root.hasMedia
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 12

    // Top row: Album Art + Track Info + Live Mini Cava Waveform
    RowLayout {
      Layout.fillWidth: true
      spacing: 12

      // Rounded Album Art
      Rectangle {
        id: artContainer
        Layout.preferredWidth: 56
        Layout.preferredHeight: 56
        radius: 13
        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.07)
        border.color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.14)
        border.width: 1
        clip: true

        Rectangle {
          id: artMask
          anchors.fill: parent
          radius: 13
          visible: false
          layer.enabled: true
          layer.smooth: true
        }

        Item {
          anchors.fill: parent
          anchors.margins: 1
          layer.enabled: artImg.status === Image.Ready
          layer.smooth: true
          layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: artMask
            maskThresholdMin: 0.4
            maskSpreadAtMin: 0.3
          }

          Image {
            id: artImg
            anchors.fill: parent
            source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
            sourceSize.width: 128
            sourceSize.height: 128
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true
            visible: status === Image.Ready
          }
        }

        Text {
          anchors.centerIn: parent
          visible: artImg.status !== Image.Ready
          text: "󰎈"
          font.family: root.font
          font.pixelSize: 24
          color: root.accent
        }
      }

      // Title, Artist, Player badge
      ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 2

        Text {
          text: root.player ? (root.player.trackTitle || "Unknown Title") : ""
          font.family: root.font
          font.pixelSize: 13
          font.bold: true
          color: root.theme.textPrimary
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Text {
          text: root.player ? (root.player.trackArtist || root.player.albumTitle || root.player.identity || "Unknown Artist") : ""
          font.family: root.font
          font.pixelSize: 11
          color: root.theme.textSecondary
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        // Player switcher pill when multiple players exist
        Row {
          visible: root.playerList.length > 1
          spacing: 6
          Layout.topMargin: 2

          Rectangle {
            width: playerChipRow.implicitWidth + 12
            height: 18
            radius: 9
            color: playerChipHover.hovered
              ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
              : Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08)
            Behavior on color { ColorAnimation { duration: 120 } }

            HoverHandler { id: playerChipHover }

            Row {
              id: playerChipRow
              anchors.centerIn: parent
              spacing: 4
              Text {
                text: root.player && root.player.identity ? root.player.identity : "Player"
                font.family: root.font
                font.pixelSize: 9
                font.bold: true
                color: root.accent
              }
              Text {
                text: (root.selectedPlayerIndex + 1) + "/" + root.playerList.length
                font.family: root.font
                font.pixelSize: 9
                color: root.theme.textMuted
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.selectedPlayerIndex = (root.selectedPlayerIndex + 1) % root.playerList.length
            }
          }
        }
      }
    }

    // Seekbar row
    RowLayout {
      visible: root.trackLen > 0
      Layout.fillWidth: true
      spacing: 8

      Text {
        text: root.formatTime(root.currentPos)
        font.family: root.font
        font.pixelSize: 10
        color: root.theme.textMuted
        Layout.preferredWidth: 32
      }

      Rectangle {
        id: seekTrack
        Layout.fillWidth: true
        Layout.preferredHeight: seekHover.hovered || seekMouse.pressed ? 6 : 4
        radius: height / 2
        color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.16)
        Behavior on Layout.preferredHeight { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        HoverHandler { id: seekHover }

        readonly property real progress: root.trackLen > 0
          ? Math.max(0, Math.min(1, root.currentPos / root.trackLen))
          : 0

        Rectangle {
          width: parent.width * seekTrack.progress
          height: parent.height
          radius: parent.radius
          color: root.theme.textPrimary
        }

        MouseArea {
          id: seekMouse
          anchors.fill: parent
          anchors.margins: -8
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
        text: root.formatRemaining(root.currentPos, root.trackLen)
        font.family: root.font
        font.pixelSize: 10
        color: root.theme.textMuted
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: 36
      }
    }

    // Transport Controls
    RowLayout {
      Layout.fillWidth: true
      spacing: 18

      Item { Layout.fillWidth: true }

      Rectangle {
        Layout.preferredWidth: 34
        Layout.preferredHeight: 34
        radius: 17
        color: prevHover.hovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12) : "transparent"
        scale: prevMouse.pressed ? 0.88 : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }
        Behavior on color { ColorAnimation { duration: 120 } }

        HoverHandler { id: prevHover }

        Text {
          anchors.centerIn: parent
          text: "󰒮"
          font.family: root.font
          font.pixelSize: 18
          color: (root.player && root.player.canGoPrevious) ? root.theme.textPrimary : root.theme.textMuted
        }

        MouseArea {
          id: prevMouse
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
        }
      }

      Rectangle {
        Layout.preferredWidth: 42
        Layout.preferredHeight: 42
        radius: 21
        color: root.accent
        scale: playMouse.pressed ? 0.90 : (playHover.hovered ? 1.05 : 1.0)
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

        HoverHandler { id: playHover }

        Text {
          anchors.centerIn: parent
          text: root.isPlaying ? "󰏤" : "󰐊"
          font.family: root.font
          font.pixelSize: 20
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
        Layout.preferredWidth: 34
        Layout.preferredHeight: 34
        radius: 17
        color: nextHover.hovered ? Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.12) : "transparent"
        scale: nextMouse.pressed ? 0.88 : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }
        Behavior on color { ColorAnimation { duration: 120 } }

        HoverHandler { id: nextHover }

        Text {
          anchors.centerIn: parent
          text: "󰒭"
          font.family: root.font
          font.pixelSize: 18
          color: (root.player && root.player.canGoNext) ? root.theme.textPrimary : root.theme.textMuted
        }

        MouseArea {
          id: nextMouse
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: if (root.player && root.player.canGoNext) root.player.next()
        }
      }

      Item { Layout.fillWidth: true }
    }
  }

  // Empty State
  Rectangle {
    id: emptyBox
    visible: !root.hasMedia
    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: 96
    height: implicitHeight
    radius: 12
    color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.04)
    border.color: Qt.rgba(root.theme.textPrimary.r, root.theme.textPrimary.g, root.theme.textPrimary.b, 0.08)
    border.width: 1

    ColumnLayout {
      anchors.centerIn: parent
      spacing: 6

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "󰎆"
        font.family: root.font
        font.pixelSize: 24
        color: root.theme.textMuted
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "No media playing"
        font.family: root.font
        font.pixelSize: 12
        font.bold: true
        color: root.theme.textSecondary
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Start Spotify, browser audio, or any MPRIS player"
        font.family: root.font
        font.pixelSize: 10
        color: root.theme.textMuted
      }
    }
  }
}
