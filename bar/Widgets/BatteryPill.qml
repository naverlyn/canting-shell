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
  id: batPill
  implicitHeight: hostContainer.isVert ? (batVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (batContent.implicitWidth + 14)
  height: implicitHeight
  width: implicitWidth
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("battery", batHover.hovered)
  border.color: hostContainer.wBorder("battery")
  border.width: hostContainer.hasCustomColor("battery") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.StaticText
  Accessible.name: "Battery: " + SystemInfo.batteryLevel

  HoverHandler { id: batHover }

  PillIndicator {
    hostRoot: batPill.hostRoot
    hostContainer: batPill.hostContainer
    active: false
    hovered: batHover.hovered
    accentColor: hostContainer.wAccent("battery", hostRoot.theme.accentGreen ?? hostRoot.theme.accentPrimary)
  }

  Row {
    id: batContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: SystemInfo.batteryIcon
      color: hostContainer.hasCustomColor("battery")
        ? hostContainer.wAccent("battery", hostRoot.theme.accentPrimary)
        : (SystemInfo.batteryCharging
          ? hostRoot.theme.accentGreen
          : (SystemInfo.batteryLevelRaw <= (BarConfig.batteryLowThreshold || 20) ? hostRoot.theme.accentRed : hostRoot.theme.accentPrimary))
      font.pixelSize: 13
      font.family: hostRoot.font
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: BarConfig.batteryShowPercentage !== false
      text: SystemInfo.batteryLevel
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Column {
    id: batVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: SystemInfo.batteryIcon
      color: hostContainer.hasCustomColor("battery")
        ? hostContainer.wAccent("battery", hostRoot.theme.accentPrimary)
        : (SystemInfo.batteryCharging
          ? hostRoot.theme.accentGreen
          : (SystemInfo.batteryLevelRaw <= (BarConfig.batteryLowThreshold || 20) ? hostRoot.theme.accentRed : hostRoot.theme.accentPrimary))
      font.pixelSize: 13
      font.family: hostRoot.font
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: BarConfig.batteryShowPercentage !== false
      text: SystemInfo.batteryLevel
      color: hostRoot.theme.textPrimary
      font.pixelSize: 9
      font.family: hostRoot.font
    }
  }
}
