import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Io
import "../Components"
import ".."

Rectangle {
  required property var hostRoot
  required property var hostContainer
  id: gpuPill
  property bool isPinned: false
  readonly property int gpuVal: parseInt(SystemInfo.gpuUsage) || 0
  readonly property int gpuTempVal: parseInt(SystemInfo.gpuTemp) || 0
  readonly property bool isAlert: Boolean(BarConfig.hwAlertEnabled) && (
    gpuVal >= (BarConfig.hwAlertThreshold || 85) ||
    gpuTempVal >= (BarConfig.hwAlertThreshold || 85)
  )
  readonly property string displayLabel: {
    if (BarConfig.gpuShowTemp && SystemInfo.gpuTemp && SystemInfo.gpuTemp !== "N/A" && SystemInfo.gpuTemp !== "0°C") {
      return SystemInfo.gpuUsage + " · " + SystemInfo.gpuTemp;
    }
    return SystemInfo.gpuUsage;
  }

  implicitHeight: hostContainer.isVert ? (gpuVertCol.implicitHeight + 12) : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (gpuContent.implicitWidth + 14)
  height: implicitHeight
  width: implicitWidth
  scale: gpuMouse.pressed ? 0.93 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: isAlert ? hostRoot.withAlpha(hostRoot.theme.accentRed, 0.28) : hostContainer.wBg("gpu", gpuHover.hovered || gpuMouse.containsMouse || gpuPill.isPinned)
  border.color: isAlert ? hostRoot.theme.accentRed : hostContainer.wBorder("gpu")
  border.width: (isAlert || hostContainer.hasCustomColor("gpu")) ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "GPU: " + gpuPill.displayLabel

  HoverHandler { id: gpuHover }

  PillIndicator {
    hostRoot: gpuPill.hostRoot
    hostContainer: gpuPill.hostContainer
    active: gpuPill.isPinned || gpuMouse.pressed
    hovered: gpuHover.hovered || gpuMouse.containsMouse
    accentColor: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("gpu", hostRoot.theme.accentGreen)
  }

  MouseArea {
    id: gpuMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: gpuPill.isPinned = !gpuPill.isPinned
  }

  InfoPopup {
    target: gpuPill
    barItem: hostContainer
    hovered: gpuHover.hovered || gpuMouse.containsMouse
    pinned: gpuPill.isPinned
    theme: hostRoot.theme
    font: hostRoot.font
    title: "GPU"
    icon: "󰢮"
    summaryText: SystemInfo.gpuUsage + (SystemInfo.gpuTemp && SystemInfo.gpuTemp !== "N/A" && SystemInfo.gpuTemp !== "0°C" ? " · " + SystemInfo.gpuTemp : "")
    accent: hostContainer.wAccent("gpu", hostRoot.theme.accentGreen)
    script: "gpu"
    barPosition: hostContainer.barPos
  }

  Row {
    id: gpuContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "󰢮"
      visible: BarConfig.hwShowIcons !== false
      color: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("gpu", hostRoot.theme.accentGreen)
      font.pixelSize: 14
      font.family: hostRoot.font
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: gpuPill.displayLabel
      color: hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Column {
    id: gpuVertCol
    visible: hostContainer.isVert
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "󰢮"
      visible: BarConfig.hwShowIcons !== false
      color: isAlert ? hostRoot.theme.accentRed : hostContainer.wAccent("gpu", hostRoot.theme.accentGreen)
      font.pixelSize: 13
      font.family: hostRoot.font
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: SystemInfo.gpuUsage
      color: hostRoot.theme.textPrimary
      font.pixelSize: 9
      font.family: hostRoot.font
    }
  }
}
