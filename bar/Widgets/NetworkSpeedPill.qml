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
  id: netPill
  property bool isPinned: false
  implicitHeight: hostContainer.isVert ? (netVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (netRow.implicitWidth + 16)
  height: implicitHeight
  width: implicitWidth
  scale: netMouse.pressed ? 0.93 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("network", netHover.hovered || netMouse.containsMouse || netPill.isPinned)
  border.color: hostContainer.wBorder("network")
  border.width: hostContainer.hasCustomColor("network") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Network Speed: Down " + SystemInfo.networkDownSpeed + ", Up " + SystemInfo.networkUpSpeed

  HoverHandler { id: netHover }

  PillIndicator {
    hostRoot: netPill.hostRoot
    hostContainer: netPill.hostContainer
    active: netPill.isPinned || netMouse.pressed
    hovered: netHover.hovered || netMouse.containsMouse
    accentColor: hostContainer.wAccent("network", hostRoot.theme.accentCyan)
  }

  MouseArea {
    id: netMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: netPill.isPinned = !netPill.isPinned
  }

  InfoPopup {
    target: netPill
    barItem: hostContainer
    hovered: netHover.hovered
    pinned: netPill.isPinned
    theme: hostRoot.theme
    font: hostRoot.font
    title: "Network (" + SystemInfo.networkInfo + ")"
    icon: "󰓅"
    accent: hostContainer.wAccent("network", hostRoot.theme.accentCyan)
    script: "net"
    barPosition: hostContainer.barPos
  }

  Row {
    id: netRow
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 8

    // Download Indicator
    Row {
      spacing: 4
      visible: BarConfig.showNetDown || !BarConfig.showNetUp
      anchors.verticalCenter: parent.verticalCenter

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰇚"
        color: hostContainer.wAccent("network", hostRoot.theme.accentCyan ?? hostRoot.theme.accentGreen)
        font.pixelSize: 13
        font.family: hostRoot.font
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: BarConfig.netCompact ? SystemInfo.networkDownCompact : SystemInfo.networkDownSpeed
        color: hostRoot.theme.textPrimary
        font.pixelSize: 11
        font.family: hostRoot.font
      }
    }

    // Upload Indicator
    Row {
      spacing: 4
      visible: BarConfig.showNetUp
      anchors.verticalCenter: parent.verticalCenter

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰕒"
        color: hostContainer.wAccent("network", hostRoot.theme.accentOrange ?? hostRoot.theme.accentPrimary)
        font.pixelSize: 13
        font.family: hostRoot.font
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: BarConfig.netCompact ? SystemInfo.networkUpCompact : SystemInfo.networkUpSpeed
        color: hostRoot.theme.textPrimary
        font.pixelSize: 11
        font.family: hostRoot.font
      }
    }
  }

  Column {
    id: netVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      visible: BarConfig.showNetDown || !BarConfig.showNetUp
      anchors.horizontalCenter: parent.horizontalCenter
      text: "↓" + SystemInfo.networkDownCompact
      color: hostContainer.wAccent("network", hostRoot.theme.accentCyan ?? hostRoot.theme.accentGreen)
      font.pixelSize: 9
      font.family: hostRoot.font
    }
    Text {
      visible: BarConfig.showNetUp
      anchors.horizontalCenter: parent.horizontalCenter
      text: "↑" + SystemInfo.networkUpCompact
      color: hostContainer.wAccent("network", hostRoot.theme.accentOrange ?? hostRoot.theme.accentPrimary)
      font.pixelSize: 9
      font.family: hostRoot.font
    }
  }
}
