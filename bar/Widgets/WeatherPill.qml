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
  id: weatherWidget
  property bool isPinned: false
  implicitHeight: hostContainer.isVert ? 28 : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : (weatherContent.implicitWidth + 16)
  height: implicitHeight
  width: implicitWidth
  scale: weatherMouse.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("weather", weatherHover.hovered || weatherMouse.containsMouse || weatherWidget.isPinned)
  border.color: hostContainer.wBorder("weather")
  border.width: hostContainer.hasCustomColor("weather") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Weather: " + SystemInfo.weatherInfo

  HoverHandler { id: weatherHover }

  PillIndicator {
    hostRoot: weatherWidget.hostRoot
    hostContainer: weatherWidget.hostContainer
    active: weatherWidget.isPinned || weatherMouse.pressed
    hovered: weatherHover.hovered || weatherMouse.containsMouse
    accentColor: hostContainer.wAccent("weather", hostRoot.theme.accentCyan)
  }

  Row {
    id: weatherContent
    visible: !hostContainer.isVert
    anchors.centerIn: parent
    spacing: 6

    Text {
      id: weatherText
      anchors.verticalCenter: parent.verticalCenter
      text: SystemInfo.weatherInfo
      color: hostContainer.hasCustomColor("weather")
        ? hostContainer.wAccent("weather", hostRoot.theme.textPrimary)
        : hostRoot.theme.textPrimary
      font.pixelSize: 11
      font.family: hostRoot.font
    }
  }

  Text {
    visible: hostContainer.isVert
    anchors.centerIn: parent
    text: "󰖐"
    color: hostContainer.wAccent("weather", hostRoot.theme.accentCyan)
    font.pixelSize: 14
    font.family: hostRoot.font
  }

  MouseArea {
    id: weatherMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      weatherWidget.isPinned = !weatherWidget.isPinned;
      SystemInfo.refreshWeather();
    }
  }

  WeatherPopup {
    id: weatherPopup
    target: weatherWidget
    barItem: hostContainer
    hovered: weatherHover.hovered
    pinned: weatherWidget.isPinned
    theme: hostRoot.theme
    font: hostRoot.font
    location: BarConfig.weatherLocation || "Bekasi"
    accent: hostContainer.wAccent("weather", hostRoot.theme.accentCyan)
    barPosition: hostContainer.barPos
    onPinToggled: weatherWidget.isPinned = !weatherWidget.isPinned
  }
}
