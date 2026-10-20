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
  id: diskButton
  property bool isPinned: false
  readonly property int diskVal: parseInt(SystemInfo.diskUsage) || 0
  readonly property bool isAlert: Boolean(BarConfig.hwAlertEnabled) && (diskVal >= (BarConfig.hwAlertThreshold || 85))
  implicitHeight: hostContainer.isVert ? (diskVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (diskContent.implicitWidth + 14)
  height: implicitHeight
  width: implicitWidth
  scale: diskMouseArea.pressed ? 0.93 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: isAlert ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.28) : hostContainer.wBg("disk", diskMouseArea.containsMouse || diskButton.isPinned)
  border.color: isAlert ? hostRoot.theme.accentRed : hostContainer.wBorder("disk")
  border.width: (isAlert || hostContainer.hasCustomColor("disk")) ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }

  Accessible.role: Accessible.Button
  Accessible.name: "/ (" + SystemInfo.diskUsage + ")"

  HoverHandler { id: diskHover }

  PillIndicator {
    hostRoot: diskButton.hostRoot
    hostContainer: diskButton.hostContainer
    active: diskButton.isPinned || diskMouseArea.pressed
    hovered: diskHover.hovered || diskMouseArea.containsMouse
    accentColor: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("disk", hostRoot.theme.accentPrimary)
  }

  MouseArea {
    id: diskMouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: diskButton.isPinned = !diskButton.isPinned
  }

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: hostContainer.wAccent("disk", hostRoot.theme.accentPrimary)
    opacity: (hostContainer.activeStyle !== "underline" && diskMouseArea.containsMouse) ? 0.15 : 0.0
    Behavior on opacity { NumberAnimation { duration: 150 } }
  }

  Row {
    id: diskContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: ""
      visible: BarConfig.hwShowIcons !== false
      color: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("disk", hostRoot.theme.accentPrimary)
      font.pixelSize: 14
      font.family: hostRoot.font
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "" + SystemInfo.diskUsage + ""
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Column {
    id: diskVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: ""
      visible: BarConfig.hwShowIcons !== false
      color: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("disk", hostRoot.theme.accentPrimary)
      font.pixelSize: 13
      font.family: hostRoot.font
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: SystemInfo.diskUsage
      color: hostRoot.theme.textPrimary
      font.pixelSize: 9
      font.family: hostRoot.font
    }
  }

  InfoPopup {
    target: diskButton
    barItem: hostContainer
    hovered: diskMouseArea.containsMouse
    pinned: diskButton.isPinned
    theme: hostRoot.theme
    font: hostRoot.font
    title: "Disk"
    icon: "\uf0a0"
    accent: hostContainer.wAccent("disk", hostRoot.theme.accentPrimary)
    script: "disk"
    barPosition: hostContainer.barPos
  }
}
