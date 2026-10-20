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
  required property var hostWindow
  required property var hostScope
  id: appGridButton
  implicitHeight: hostContainer.isVert ? 28 : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : 28
  height: implicitHeight
  width: implicitWidth
  scale: appGridMouse.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("appGrid", appGridMouse.containsMouse)
  border.color: hostContainer.wBorder("appGrid")
  border.width: hostContainer.hasCustomColor("appGrid") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Applications"

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: hostContainer.wAccent("appGrid", hostRoot.theme.accentPrimary)
    opacity: (hostContainer.activeStyle !== "underline" && appGridMouse.containsMouse) ? 0.15 : 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }
  }

  PillIndicator {
    hostRoot: appGridButton.hostRoot
    hostContainer: appGridButton.hostContainer
    active: appGridMouse.pressed
    hovered: appGridMouse.containsMouse
    accentColor: hostContainer.wAccent("appGrid", hostRoot.theme.accentPrimary)
  }

  Text {
    anchors.centerIn: parent
    text: "󰀻"
    color: hostContainer.wAccent("appGrid", hostRoot.theme.accentPrimary)
    font.pixelSize: 14
    font.family: hostRoot.font
  }

  MouseArea {
    id: appGridMouse
    anchors.fill: parent
    anchors.topMargin: -hostContainer.vHitPadding
    anchors.bottomMargin: -hostContainer.vHitPadding
    anchors.leftMargin: -hostContainer.hHitPadding
    anchors.rightMargin: -hostContainer.hHitPadding
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      const pt = appGridButton.mapToItem(null, appGridButton.width / 2, appGridButton.height / 2);
      const winW = Math.max(1, hostWindow.width);
      const winH = Math.max(1, hostWindow.height);
      const normX = (pt.x / winW).toFixed(3);
      const normY = (pt.y / winH).toFixed(3);
      const clearance = hostContainer.isVert
        ? ((hostScope.isFloating ? 6 : 0) + hostScope.barThickness + 16)
        : ((hostScope.isFloating ? 6 : 0) + hostScope.barThickness);
      appGridProc.command = [
        "qs", "ipc", "call", "appgrid", "toggleAt",
        hostContainer.barPos, String(normX), String(normY), String(clearance)
      ];
      appGridProc.running = true;
    }
  }

  Process {
    id: appGridProc
    command: ["qs", "ipc", "call", "appgrid", "toggle"]
    running: false
  }
}
