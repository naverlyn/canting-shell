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
  id: cpuPill
  property bool isPinned: false
  readonly property int cpuVal: parseInt(SystemInfo.cpuUsage) || 0
  readonly property bool isAlert: Boolean(BarConfig.hwAlertEnabled) && (cpuVal >= (BarConfig.hwAlertThreshold || 85))
  implicitHeight: hostContainer.isVert ? (cpuVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (cpuContent.implicitWidth + 14)
  height: implicitHeight
  width: implicitWidth
  scale: cpuMouse.pressed ? 0.93 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: isAlert ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.28) : hostContainer.wBg("cpu", cpuHover.hovered || cpuMouse.containsMouse || cpuPill.isPinned)
  border.color: isAlert ? hostRoot.theme.accentRed : hostContainer.wBorder("cpu")
  border.width: (isAlert || hostContainer.hasCustomColor("cpu")) ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "CPU: " + SystemInfo.cpuUsage

  HoverHandler { id: cpuHover }

  PillIndicator {
    hostRoot: cpuPill.hostRoot
    hostContainer: cpuPill.hostContainer
    active: cpuPill.isPinned || cpuMouse.pressed
    hovered: cpuHover.hovered || cpuMouse.containsMouse
    accentColor: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("cpu", hostRoot.theme.accentOrange)
  }

  MouseArea {
    id: cpuMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: cpuPill.isPinned = !cpuPill.isPinned
  }

  InfoPopup {
    target: cpuPill
    barItem: hostContainer
    hovered: cpuHover.hovered
    pinned: cpuPill.isPinned
    theme: hostRoot.theme
    font: hostRoot.font
    title: "CPU"
    icon: "󰻠"
    accent: hostContainer.wAccent("cpu", hostRoot.theme.accentOrange)
    script: "cpu"
    barPosition: hostContainer.barPos
  }

  Row {
    id: cpuContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "󰻠"
      visible: BarConfig.hwShowIcons !== false
      color: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("cpu", hostRoot.theme.accentOrange)
      font.pixelSize: 14
      font.family: hostRoot.font
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: SystemInfo.cpuUsage
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Column {
    id: cpuVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "󰻠"
      visible: BarConfig.hwShowIcons !== false
      color: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("cpu", hostRoot.theme.accentOrange)
      font.pixelSize: 13
      font.family: hostRoot.font
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: SystemInfo.cpuUsage
      color: hostRoot.theme.textPrimary
      font.pixelSize: 9
      font.family: hostRoot.font
    }
  }
}
