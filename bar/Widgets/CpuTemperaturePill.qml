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
  id: tempPill
  property bool isPinned: false
  readonly property int tempVal: parseInt(SystemInfo.temperature) || 0
  readonly property bool isAlert: Boolean(BarConfig.hwAlertEnabled) && (tempVal >= (BarConfig.hwAlertThreshold || 85))
  implicitHeight: hostContainer.isVert ? (tempVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (tempContent.implicitWidth + 14)
  height: implicitHeight
  width: implicitWidth
  scale: tempMouse.pressed ? 0.93 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: isAlert ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.28) : hostContainer.wBg("temp", tempHover.hovered || tempMouse.containsMouse || tempPill.isPinned)
  border.color: isAlert ? hostRoot.theme.accentRed : hostContainer.wBorder("temp")
  border.width: (isAlert || hostContainer.hasCustomColor("temp")) ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Temperature: " + SystemInfo.temperature

  HoverHandler { id: tempHover }

  PillIndicator {
    hostRoot: tempPill.hostRoot
    hostContainer: tempPill.hostContainer
    active: tempPill.isPinned || tempMouse.pressed
    hovered: tempHover.hovered || tempMouse.containsMouse
    accentColor: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("temp", hostRoot.theme.accentRed)
  }

  MouseArea {
    id: tempMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: tempPill.isPinned = !tempPill.isPinned
  }

  InfoPopup {
    target: tempPill
    barItem: hostContainer
    hovered: tempHover.hovered
    pinned: tempPill.isPinned
    theme: hostRoot.theme
    font: hostRoot.font
    title: "Temperature"
    icon: "󰔏"
    accent: hostContainer.wAccent("temp", hostRoot.theme.accentRed)
    script: "temp"
    barPosition: hostContainer.barPos
  }

  Row {
    id: tempContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "󰔏"
      visible: BarConfig.hwShowIcons !== false
      color: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("temp", hostRoot.theme.accentRed)
      font.pixelSize: 14
      font.family: hostRoot.font
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: SystemInfo.temperature
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Column {
    id: tempVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "󰔏"
      visible: BarConfig.hwShowIcons !== false
      color: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("temp", hostRoot.theme.accentRed)
      font.pixelSize: 13
      font.family: hostRoot.font
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: SystemInfo.temperature
      color: hostRoot.theme.textPrimary
      font.pixelSize: 9
      font.family: hostRoot.font
    }
  }
}
