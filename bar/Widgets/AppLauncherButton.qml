import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../Components"
import ".."

Rectangle {
  required property var hostRoot
  required property var hostContainer
  required property var hostWindow
  required property var hostScope
  id: appGridButton
  readonly property bool isImageIcon: BarConfig.isAppGridImage(BarConfig.appGridIcon)
  implicitHeight: hostContainer.isVert ? hostContainer.scaled(28) : (hostContainer.hidePill ? hostContainer.height : hostContainer.horizPillHeight)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : Math.max(hostContainer.scaled(28), (isImageIcon ? hostContainer.scaled(16) : appGridIconTxt.implicitWidth) + hostContainer.scaled(14))
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
    id: appGridIconTxt
    anchors.centerIn: parent
    visible: !appGridButton.isImageIcon
    text: BarConfig.appGridIcon || "󰀻"
    color: hostContainer.wAccent("appGrid", hostRoot.theme.accentPrimary)
    font.pixelSize: hostContainer.scaled(14)
    font.family: hostRoot.font
  }

  Image {
    id: appGridIconImg
    anchors.centerIn: parent
    visible: appGridButton.isImageIcon
    width: hostContainer.scaled(16)
    height: hostContainer.scaled(16)
    source: appGridButton.isImageIcon ? BarConfig.appGridImageSource(BarConfig.appGridIcon) : ""
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
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
      const baseEdge = hostContainer.barEdgeOffset !== undefined
        ? hostContainer.barEdgeOffset
        : ((hostContainer.isFloating ? 6 : 0) + hostScope.barThickness);
      appGridProc.command = [
        "qs", "ipc", "call", "appgrid", "toggleAt",
        hostContainer.barPos, String(normX), String(normY), String(baseEdge)
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
