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
  id: idlePill
  readonly property bool isActive: SystemInfo.idleInhibited

  implicitHeight: hostContainer.isVert ? 28 : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : 28
  height: implicitHeight
  width: implicitWidth
  scale: idleMouse.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("idleInhibitor", idleMouse.containsMouse || idlePill.isActive)
  border.color: hostContainer.activeStyle === "underline"
    ? "transparent"
    : (idlePill.isActive
      ? hostContainer.wAccent("idleInhibitor", hostRoot.theme.accentOrange ?? hostRoot.theme.accentPrimary)
      : hostContainer.wBorder("idleInhibitor"))
  border.width: (hostContainer.activeStyle !== "underline" && (idlePill.isActive || hostContainer.hasCustomColor("idleInhibitor"))) ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Behavior on border.color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: idlePill.isActive ? "Idle Inhibitor: Active" : "Idle Inhibitor: Inactive"

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: hostContainer.wAccent("idleInhibitor", hostRoot.theme.accentOrange ?? hostRoot.theme.accentPrimary)
    opacity: (hostContainer.activeStyle !== "underline") ? (idlePill.isActive ? 0.18 : (idleMouse.containsMouse ? 0.12 : 0.0)) : 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }
  }

  PillIndicator {
    hostRoot: idlePill.hostRoot
    hostContainer: idlePill.hostContainer
    active: idlePill.isActive || idleMouse.pressed
    hovered: idleMouse.containsMouse
    accentColor: hostContainer.wAccent("idleInhibitor", hostRoot.theme.accentOrange ?? hostRoot.theme.accentPrimary)
  }

  Text {
    anchors.centerIn: parent
    text: idlePill.isActive ? "" : ""
    color: idlePill.isActive
      ? hostContainer.wAccent("idleInhibitor", hostRoot.theme.accentOrange ?? hostRoot.theme.accentPrimary)
      : (hostContainer.hasCustomColor("idleInhibitor")
        ? hostContainer.wAccent("idleInhibitor", hostRoot.theme.textPrimary)
        : hostRoot.theme.textPrimary)
    font.pixelSize: 13
    font.family: hostRoot.font
  }

  MouseArea {
    id: idleMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: SystemInfo.toggleIdleInhibitor()
  }
}
