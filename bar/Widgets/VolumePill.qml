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
  id: volPill
  readonly property var sinkAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
  property bool isPinned: false
  readonly property var srcAudio: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null
  readonly property bool isMuted: sinkAudio ? sinkAudio.muted : false
  readonly property int volPct: {
    if (!sinkAudio) return 0;
    if (sinkAudio.volumes && sinkAudio.volumes.length >= 2) {
      return Math.round(Math.max(sinkAudio.volumes[0], sinkAudio.volumes[1]) * 100);
    }
    return Math.round(sinkAudio.volume * 100);
  }

  implicitHeight: hostContainer.isVert ? (volVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (volContent.implicitWidth + 14)
  height: implicitHeight
  width: implicitWidth
  scale: volMouse.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("volume", volHover.hovered || volMouse.containsMouse || volPill.isPinned)
  border.color: hostContainer.wBorder("volume")
  border.width: hostContainer.hasCustomColor("volume") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Volume: " + volPct + "%"

  HoverHandler { id: volHover }

  function setVol(audio, v) {
    if (!audio) return;
    v = Math.max(0.0, Math.min(1.0, v));
    if (audio.volumes && audio.volumes.length >= 2) {
      const vl = audio.volumes[0], vr = audio.volumes[1], m = Math.max(vl, vr);
      audio.volumes = m > 0.001 ? [v * (vl / m), v * (vr / m)] : [v, v];
    } else {
      audio.volume = v;
    }
    if (audio.muted && v > 0) audio.muted = false;
  }
  function curVol(audio) {
    if (!audio) return 0;
    if (audio.volumes && audio.volumes.length >= 2) return Math.max(audio.volumes[0], audio.volumes[1]);
    return audio.volume;
  }

  Item {
    id: volProvider
    visible: false
    width: 0
    height: 0
    property Item target: volPill
    property Item barItem: hostContainer
    property var hostRoot: volPill.hostRoot
    property bool hovered: volHover.hovered || volMouse.containsMouse
    property bool pinned: volPill.isPinned
    property bool effectiveHovered: false
    readonly property bool isSharedCardHovered: Boolean(barItem && barItem.activeInfoProvider === volProvider && barItem.sharedInfoPopup && barItem.sharedInfoPopup.cardHovered)
    readonly property bool isDetailsActive: effectiveHovered || pinned || isSharedCardHovered
    property var theme: hostRoot.theme
    property string font: hostRoot.font
    property string title: "Audio"
    property string icon: ""
    property color accent: hostContainer.wAccent("volume", hostRoot.theme.accentPrimary)
    property bool hideHeader: true
    property int preferredWidth: 260
    property int preferredHeight: 112
    property var rows: []

    Timer {
      id: volCloseTimer
      interval: 150
      onTriggered: {
        if (!volProvider.hovered && !volProvider.isSharedCardHovered) {
          volProvider.effectiveHovered = false;
          if (hostContainer.activeInfoProvider === volProvider && !volProvider.pinned)
            hostContainer.activeInfoProvider = null;
        }
      }
    }
    onHoveredChanged: {
      if (hovered) { volCloseTimer.stop(); effectiveHovered = true; hostContainer.activeInfoProvider = volProvider; }
      else if (!isSharedCardHovered) volCloseTimer.restart();
    }
    onIsSharedCardHoveredChanged: {
      if (isSharedCardHovered) { volCloseTimer.stop(); effectiveHovered = true; }
      else if (!hovered) volCloseTimer.restart();
    }
    onPinnedChanged: {
      if (pinned) {
        const o = hostContainer.activeInfoProvider;
        if (o && o !== volProvider && o.target && o.target.isPinned !== undefined) o.target.isPinned = false;
        hostContainer.activeInfoProvider = volProvider;
      } else if (!hovered && !isSharedCardHovered && hostContainer.activeInfoProvider === volProvider) {
        hostContainer.activeInfoProvider = null;
      }
    }
    Component.onDestruction: {
      if (hostContainer.activeInfoProvider === volProvider) hostContainer.activeInfoProvider = null;
    }

    property Component contentComponent: Component {
      ColumnLayout {
        id: volCard
        spacing: 12
        Repeater {
          model: [
            { kind: "out", label: "Speaker" },
            { kind: "in", label: "Microphone" }
          ]
          delegate: ColumnLayout {
            id: audioRow
            required property var modelData
            readonly property var aud: modelData.kind === "out" ? volPill.sinkAudio : volPill.srcAudio
            readonly property bool muted: aud ? aud.muted : true
            readonly property real val: aud ? volPill.curVol(aud) : 0
            readonly property var th: volProvider.theme
            Layout.fillWidth: true
            spacing: 6

            Text {
              text: audioRow.modelData.label
              font.family: volProvider.font
              font.pixelSize: 11
              font.bold: true
              color: audioRow.th.textSecondary
              Layout.fillWidth: true
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 10

              Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 7
                color: audioRow.muted
                  ? Qt.rgba(audioRow.th.accentRed.r, audioRow.th.accentRed.g, audioRow.th.accentRed.b, 0.18)
                  : Qt.rgba(audioRow.th.textPrimary.r, audioRow.th.textPrimary.g, audioRow.th.textPrimary.b, muteMouse.containsMouse ? 0.1 : 0.06)
                Behavior on color { ColorAnimation { duration: 140 } }
                Text {
                  anchors.centerIn: parent
                  text: audioRow.modelData.kind === "out"
                    ? (audioRow.muted ? "󰝟" : "󰕾")
                    : (audioRow.muted ? "󰍭" : "󰍬")
                  font.family: volProvider.font
                  font.pixelSize: 15
                  color: audioRow.muted ? audioRow.th.accentRed : audioRow.th.textPrimary
                }
                MouseArea {
                  id: muteMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: if (audioRow.aud) audioRow.aud.muted = !audioRow.aud.muted
                }
              }

              Rectangle {
                id: sliderBg
                Layout.fillWidth: true
                Layout.preferredHeight: 8
                radius: 4
                color: Qt.rgba(audioRow.th.textPrimary.r, audioRow.th.textPrimary.g, audioRow.th.textPrimary.b, 0.18)

                Rectangle {
                  id: sliderFill
                  height: parent.height
                  radius: 4
                  width: Math.min(parent.width, parent.width * audioRow.val)
                  color: audioRow.th.accentPrimary
                  Behavior on width {
                    enabled: !sliderMouse.pressed
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                  }
                }
                Rectangle {
                  width: 14
                  height: 14
                  radius: 7
                  y: (parent.height - height) / 2
                  x: Math.max(0, Math.min(sliderBg.width - width, sliderFill.width - (width / 2)))
                  color: audioRow.th.textPrimary
                }
                MouseArea {
                  id: sliderMouse
                  anchors.fill: parent
                  anchors.topMargin: -8
                  anchors.bottomMargin: -8
                  cursorShape: Qt.PointingHandCursor
                  onPressed: (m) => volPill.setVol(audioRow.aud, m.x / width)
                  onPositionChanged: (m) => { if (pressed) volPill.setVol(audioRow.aud, m.x / width) }
                  onWheel: (w) => volPill.setVol(audioRow.aud, audioRow.val + (w.angleDelta.y > 0 ? 0.05 : -0.05))
                }
              }

              Text {
                text: audioRow.aud ? (audioRow.muted ? "Muted" : Math.round(audioRow.val * 100) + "%") : "0%"
                font.family: volProvider.font
                font.pixelSize: 11
                font.bold: true
                color: audioRow.th.textSecondary
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
              }
            }
          }
        }
      }
    }
  }

  PillIndicator {
    hostRoot: volPill.hostRoot
    hostContainer: volPill.hostContainer
    active: volMouse.pressed || volPill.isPinned
    hovered: volMouse.containsMouse
    accentColor: volPill.isMuted
      ? hostRoot.theme.accentRed
      : hostContainer.wAccent("volume", hostRoot.theme.accentPrimary)
  }

  Row {
    id: volContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: volPill.isMuted ? "󰝟" : (volPill.volPct >= 60 ? "󰕾" : (volPill.volPct > 0 ? "󰖀" : "󰕿"))
      color: volPill.isMuted
        ? hostRoot.theme.accentRed
        : hostContainer.wAccent("volume", hostRoot.theme.accentPrimary)
      font.pixelSize: 14
      font.family: hostRoot.font
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: volPill.isMuted ? "Muted" : (volPill.volPct + "%")
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Column {
    id: volVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: volPill.isMuted ? "󰝟" : (volPill.volPct >= 60 ? "󰕾" : (volPill.volPct > 0 ? "󰖀" : "󰕿"))
      color: volPill.isMuted
        ? hostRoot.theme.accentRed
        : hostContainer.wAccent("volume", hostRoot.theme.accentPrimary)
      font.pixelSize: 13
      font.family: hostRoot.font
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: volPill.isMuted ? "Mute" : (volPill.volPct + "%")
      color: hostRoot.theme.textPrimary
      font.pixelSize: 9
      font.family: hostRoot.font
    }
  }

  MouseArea {
    id: volMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) {
        if (volPill.sinkAudio) volPill.sinkAudio.muted = !volPill.sinkAudio.muted;
      } else {
        volPill.isPinned = !volPill.isPinned;
      }
    }
    onWheel: (wheel) => {
      if (volPill.sinkAudio) {
        let step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
        if (volPill.sinkAudio.volumes && volPill.sinkAudio.volumes.length >= 2) {
          const vl = volPill.sinkAudio.volumes[0];
          const vr = volPill.sinkAudio.volumes[1];
          const maxV = Math.max(vl, vr);
          const targetMax = Math.max(0.0, Math.min(1.0, (maxV > 0.001 ? maxV : volPill.sinkAudio.volume) + step));
          if (maxV > 0.001) {
            volPill.sinkAudio.volumes = [targetMax * (vl / maxV), targetMax * (vr / maxV)];
          } else {
            volPill.sinkAudio.volumes = [targetMax, targetMax];
          }
        } else {
          volPill.sinkAudio.volume = Math.max(0.0, Math.min(1.0, volPill.sinkAudio.volume + step));
        }
      }
    }
  }
}
