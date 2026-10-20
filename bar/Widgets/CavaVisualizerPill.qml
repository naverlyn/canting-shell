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
  id: cavaPill
  readonly property bool hasAudio: CavaService.hasAudio
  readonly property bool autoHide: BarConfig.cavaAutoHide
  readonly property bool isVert: hostContainer.isVert

  visible: !autoHide || hasAudio || cavaMouse.containsMouse

  implicitHeight: isVert ? Math.max(28, (cavaVertCol ? cavaVertCol.implicitHeight + 10 : 28)) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: isVert
    ? hostContainer.vertPillWidth
    : (cavaHorizRow.implicitWidth + 14)
  height: implicitHeight
  width: implicitWidth
  scale: cavaMouse.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("cava", cavaMouse.containsMouse || hasAudio)
  border.color: hostContainer.wBorder("cava")
  border.width: hostContainer.hasCustomColor("cava") ? 1 : 0
  clip: true
  Behavior on color { ColorAnimation { duration: 150 } }

  PillIndicator {
    hostRoot: cavaPill.hostRoot
    hostContainer: cavaPill.hostContainer
    active: cavaPill.hasAudio || cavaMouse.pressed
    hovered: cavaMouse.containsMouse
    accentColor: hostContainer.wAccent("cava", hostRoot.theme.accentPrimary)
  }

  // Horizontal layout
  Row {
    id: cavaHorizRow
    visible: !cavaPill.isVert
    anchors.centerIn: parent
    spacing: 6

    // Bars mode (smooth rounded equalizer bars)
    Row {
      visible: BarConfig.cavaStyle !== "glyphs"
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2
      height: 16

      Repeater {
        model: CavaService.values
        Rectangle {
          required property int modelData
          required property int index

          width: 3
          height: Math.max(2, Math.round((modelData / 100) * 16))
          radius: 1.5
          color: hostContainer.wAccent("cava", hostRoot.theme.accentPrimary)
          anchors.bottom: (BarConfig.cavaStyle === "line") ? undefined : parent.bottom
          anchors.verticalCenter: (BarConfig.cavaStyle === "line") ? parent.verticalCenter : undefined

          Behavior on height {
            NumberAnimation {
              duration: 50
              easing.type: Easing.OutQuad
            }
          }
        }
      }
    }

    // Unicode glyphs mode
    Text {
      visible: BarConfig.cavaStyle === "glyphs"
      anchors.verticalCenter: parent.verticalCenter
      text: CavaService.glyphText
      font.family: hostRoot.font
      font.pixelSize: 11
      color: hostContainer.wAccent("cava", hostRoot.theme.accentPrimary)
    }
  }

  // Vertical bar layout (when bar is on Left or Right)
  Column {
    id: cavaVertCol
    visible: cavaPill.isVert
    anchors.centerIn: parent
    spacing: 2

    Repeater {
      model: Math.min((BarConfig.cavaBars || 8), CavaService.values.length)
      Rectangle {
        required property int index
        readonly property int val: (CavaService.values && CavaService.values.length > index) ? CavaService.values[index] : 0
        height: 2
        width: Math.max(2, Math.round((val / 100) * 18))
        radius: 1
        color: hostContainer.wAccent("cava", hostRoot.theme.accentPrimary)
        anchors.horizontalCenter: parent.horizontalCenter

        Behavior on width {
          NumberAnimation {
            duration: 50
            easing.type: Easing.OutQuad
          }
        }
      }
    }
  }

  MouseArea {
    id: cavaMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        const styles = ["bars", "glyphs", "line"];
        const curIdx = styles.indexOf(BarConfig.cavaStyle || "bars");
        const next = styles[(curIdx + 1) % styles.length];
        BarConfig.cavaStyle = next;
        BarConfig.saveConfig();
      } else if (mouse.button === Qt.RightButton) {
        const modes = ["compact", "medium", "wide"];
        const curIdx = modes.indexOf(BarConfig.cavaMode || "compact");
        const next = modes[(curIdx + 1) % modes.length];
        BarConfig.setCavaMode(next);
      }
    }
  }
}
