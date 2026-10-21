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
  id: winTitleWidget
  readonly property int vertMaxHeight: 220
  readonly property int vertCalcHeight: titleMeasureText.implicitWidth + 32
  implicitHeight: hostContainer.isVert
    ? (titleMeasureText.text !== "" ? Math.max(36, Math.min(vertMaxHeight, vertCalcHeight)) : 0)
    : (hostContainer.hidePill ? hostContainer.height : 24)
  height: implicitHeight
  readonly property string curSec: BarConfig.getWidgetSection("windowTitle")
  readonly property real availableCenterSpace: curSec === "center"
    ? Math.max(60, Math.min(360, hostContainer.width / Math.max(2, hostContainer.effectivePanels.length) - 24))
    : 240
  implicitWidth: hostContainer.isVert
    ? (titleMeasureText.text !== "" ? hostContainer.vertPillWidth : 0)
    : (curSec === "center"
      ? (titleText.text !== "" ? Math.max(40, Math.min(titleText.implicitWidth + 24, availableCenterSpace)) : 0)
      : (titleText.text !== "" ? Math.max(40, Math.min(titleText.implicitWidth + 24, 240)) : 0))
  width: implicitWidth
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("windowTitle", false)
  border.color: hostContainer.wBorder("windowTitle")
  border.width: (titleText.text !== "" && hostContainer.hasCustomColor("windowTitle")) ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  clip: true

  HoverHandler { id: titleHover }

  PillIndicator {
    hostRoot: winTitleWidget.hostRoot
    hostContainer: winTitleWidget.hostContainer
    active: false
    hovered: titleHover.hovered
    accentColor: hostContainer.wAccent("windowTitle", hostRoot.theme.accentPrimary)
  }

  Text {
    id: titleMeasureText
    visible: false
    text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
    font.pixelSize: 11
    font.family: hostRoot.font
  }

  Text {
    id: titleText
    visible: !hostContainer.isVert
    Accessible.role: Accessible.StaticText
    Accessible.name: "Active window: " + text
    text: titleMeasureText.text
    color: hostContainer.hasCustomColor("windowTitle")
      ? hostContainer.wAccent("windowTitle", hostRoot.theme.textPrimary)
      : hostRoot.theme.textPrimary
    font.pixelSize: 13
    font.family: hostRoot.font
    elide: Text.ElideRight
    width: Math.min(implicitWidth, parent.width - 16)
    anchors.centerIn: parent
  }

  Item {
    id: vertContent
    visible: hostContainer.isVert && titleMeasureText.text !== ""
    anchors.centerIn: parent
    width: parent.height
    height: parent.width
    rotation: 90

    Row {
      anchors.centerIn: parent
      spacing: 6

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        color: hostContainer.wAccent("windowTitle", hostRoot.theme.accentPrimary)
        font.pixelSize: 12
        font.family: hostRoot.font
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: titleMeasureText.text
        color: hostContainer.hasCustomColor("windowTitle")
          ? hostContainer.wAccent("windowTitle", hostRoot.theme.textPrimary)
          : hostRoot.theme.textPrimary
        font.pixelSize: 11
        font.family: hostRoot.font
        elide: Text.ElideRight
        width: Math.max(20, vertContent.width - 28)
      }
    }
  }
}
