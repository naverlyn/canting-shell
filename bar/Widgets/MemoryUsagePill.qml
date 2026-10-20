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
  id: memPill
  property bool isPinned: false
  readonly property int memVal: parseInt(SystemInfo.memoryUsage) || 0
  readonly property bool isAlert: Boolean(BarConfig.hwAlertEnabled) && (memVal >= (BarConfig.hwAlertThreshold || 85))
  implicitHeight: hostContainer.isVert ? (memVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (memContent.implicitWidth + 14)
  height: implicitHeight
  width: implicitWidth
  scale: memMouse.pressed ? 0.93 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: isAlert ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.28) : hostContainer.wBg("memory", memHover.hovered || memMouse.containsMouse || memPill.isPinned)
  border.color: isAlert ? hostRoot.theme.accentRed : hostContainer.wBorder("memory")
  border.width: (isAlert || hostContainer.hasCustomColor("memory")) ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Memory Usage: " + SystemInfo.memoryUsage

  HoverHandler { id: memHover }

  PillIndicator {
    hostRoot: memPill.hostRoot
    hostContainer: memPill.hostContainer
    active: memPill.isPinned || memMouse.pressed
    hovered: memHover.hovered || memMouse.containsMouse
    accentColor: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("memory", hostRoot.theme.accentGreen ?? hostRoot.theme.accentPrimary)
  }

  MouseArea {
    id: memMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: memPill.isPinned = !memPill.isPinned
  }

  InfoPopup {
    target: memPill
    barItem: hostContainer
    hovered: memHover.hovered
    pinned: memPill.isPinned
    theme: hostRoot.theme
    font: hostRoot.font
    title: "Memory"
    icon: "\uf2db"
    accent: hostContainer.wAccent("memory", hostRoot.theme.accentPrimary)
    script: "mem"
    barPosition: hostContainer.barPos
  }

  Row {
    id: memContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: ""
      visible: BarConfig.hwShowIcons !== false
      color: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("memory", hostRoot.theme.accentPrimary)
      font.pixelSize: 14
      font.family: hostRoot.font
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: SystemInfo.memoryUsage
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Column {
    id: memVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: ""
      visible: BarConfig.hwShowIcons !== false
      color: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("memory", hostRoot.theme.accentPrimary)
      font.pixelSize: 13
      font.family: hostRoot.font
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: SystemInfo.memoryUsage
      color: hostRoot.theme.textPrimary
      font.pixelSize: 9
      font.family: hostRoot.font
    }
  }
}
