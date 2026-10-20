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
  color: hostContainer.wBg("volume", volMouse.containsMouse)
  border.color: hostContainer.wBorder("volume")
  border.width: hostContainer.hasCustomColor("volume") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Volume: " + volPct + "%"

  PillIndicator {
    hostRoot: volPill.hostRoot
    hostContainer: volPill.hostContainer
    active: volMouse.pressed
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
      if (volPill.sinkAudio) {
        volPill.sinkAudio.muted = !volPill.sinkAudio.muted;
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
