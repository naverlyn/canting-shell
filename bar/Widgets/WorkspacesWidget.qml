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

Item {
  required property var hostRoot
  required property var hostContainer
  id: wsContainer
  implicitWidth: wsGrid.implicitWidth
  implicitHeight: hostContainer.isVert ? wsGrid.implicitHeight : (hostContainer.hidePill ? hostContainer.height : 24)
  width: implicitWidth
  height: hostContainer.isVert ? implicitHeight : hostContainer.height

  function formatWsLabel(wsId, style) {
    const s = style !== undefined ? style : BarConfig.workspaceStyle;
    if (s === "roman") {
      const roman = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];
      const n = parseInt(wsId) || 0;
      return (n > 0 && n < roman.length) ? roman[n] : String(wsId);
    }
    if (s === "dot") {
      return "•";
    }
    return String(wsId);
  }

  Grid {
    id: wsGrid
    anchors.centerIn: parent
    columns: hostContainer.isVert ? 1 : Math.max(1, wsRepeater.count)
    spacing: 4
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter

    Repeater {
      id: wsRepeater
      model: Hyprland.workspaces

      Rectangle {
        id: wsPill
        required property var modelData
        property bool urgentBlink: false

        Accessible.role: Accessible.Button
        Accessible.name: "Workspace " + modelData.id + (modelData.focused ? ", active" : "") + (modelData.urgent ? ", urgent" : "")

        width: hostContainer.isVert ? hostContainer.vertPillWidth : (modelData.focused ? 32 : 24)
        implicitWidth: width
        height: hostContainer.isVert ? (modelData.focused ? 30 : 22) : (hostContainer.hidePill ? hostContainer.height : 24)
        implicitHeight: height
        scale: wsMouse.pressed ? 0.90 : 1.0
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        radius: hostContainer.pillRadius
        Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        color: modelData.focused
          ? (hostContainer.activeStyle === "underline"
              ? (hostContainer.hidePill ? "transparent" : hostRoot.theme.bgSurface)
              : (hostContainer.activeStyle === "both"
                  ? (hostContainer.hasCustomColor("workspaces")
                      ? hostContainer.wBg("workspaces", true)
                      : hostRoot.theme.bgSelected)
                  : hostContainer.wAccent("workspaces", hostRoot.theme.accentPrimary)))
          : (modelData.urgent && urgentBlink
            ? hostRoot.theme.accentRed
            : (hostContainer.activeStyle === "underline"
                ? (hostContainer.hidePill ? "transparent" : hostRoot.theme.bgSurface)
                : hostContainer.wBg("workspaces", wsMouse.containsMouse)))
        border.color: !modelData.focused && hostContainer.hasCustomColor("workspaces")
          ? hostContainer.wBorder("workspaces")
          : "transparent"
        border.width: (!modelData.focused && hostContainer.hasCustomColor("workspaces")) ? 1 : 0

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        SequentialAnimation {
          loops: Animation.Infinite
          running: wsPill.modelData.urgent && !wsPill.modelData.focused

          PropertyAction { target: wsPill; property: "urgentBlink"; value: true }
          PauseAnimation { duration: 500 }
          PropertyAction { target: wsPill; property: "urgentBlink"; value: false }
          PauseAnimation { duration: 500 }

          onStopped: wsPill.urgentBlink = false
        }

        PillIndicator {
          hostRoot: wsContainer.hostRoot
          hostContainer: wsContainer.hostContainer
          active: wsPill.modelData.focused
          hovered: wsMouse.containsMouse
          accentColor: hostContainer.wAccent("workspaces", hostRoot.theme.accentPrimary)
        }

        Text {
          anchors.centerIn: parent
          text: {
            const s = BarConfig.workspaceStyle || "index";
            const id = wsPill.modelData.id;
            if (s === "roman") {
              const roman = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];
              const n = parseInt(id) || 0;
              return (n > 0 && n < roman.length) ? roman[n] : String(id);
            }
            if (s === "dot") {
              return "•";
            }
            return String(id);
          }
          color: wsPill.modelData.focused
            ? (hostContainer.activeStyle === "pill"
                ? hostRoot.theme.bgBase
                : hostContainer.wAccent("workspaces", hostRoot.theme.accentPrimary))
            : (wsMouse.containsMouse
                ? hostRoot.theme.textPrimary
                : (hostContainer.hasCustomColor("workspaces")
                    ? hostContainer.wAccent("workspaces", hostRoot.theme.textPrimary)
                    : hostRoot.theme.textSecondary))
          font.pixelSize: 11
          font.family: hostRoot.font
          font.bold: wsPill.modelData.focused
          Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
          id: wsMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: wsPill.modelData.activate()
          onWheel: wheel => {
            if (BarConfig.workspaceScrollSwitch === false) return;
            if (wheel.angleDelta.y > 0) {
              Hyprland.dispatch("workspace e-1");
            } else if (wheel.angleDelta.y < 0) {
              Hyprland.dispatch("workspace e+1");
            }
          }
        }
      }
    }
  }
}
