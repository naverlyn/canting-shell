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
  required property var hostWindow
  required property var hostScope
  id: controlCenterButton
  implicitHeight: hostContainer.isVert ? 28 : (hostContainer.hidePill ? hostContainer.height : 24)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : 28
  height: implicitHeight
  width: implicitWidth
  scale: controlCenterArea.pressed ? 0.92 : 1.0
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("controlCenter", controlCenterArea.containsMouse || (controlCenterLoader.item && controlCenterLoader.item.visible))
  border.color: hostContainer.wBorder("controlCenter")
  border.width: hostContainer.hasCustomColor("controlCenter") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }
  Accessible.role: Accessible.Button
  Accessible.name: "Control Center"

  PillIndicator {
    hostRoot: controlCenterButton.hostRoot
    hostContainer: controlCenterButton.hostContainer
    active: (controlCenterLoader.item && controlCenterLoader.item.visible) || controlCenterArea.pressed
    hovered: controlCenterArea.containsMouse
    accentColor: hostContainer.wAccent("controlCenter", hostRoot.theme.accentPrimary)
  }

  Text {
    id: ccIcon
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -1
    text: ""
    color: ((controlCenterLoader.item && controlCenterLoader.item.visible) || hostContainer.hasCustomColor("controlCenter"))
      ? hostContainer.wAccent("controlCenter", hostRoot.theme.accentPrimary)
      : hostRoot.theme.textPrimary
    font.pixelSize: 12
    font.family: hostRoot.font
  }

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: hostContainer.wAccent("controlCenter", hostRoot.theme.accentPrimary)
    opacity: (hostContainer.activeStyle !== "underline" && (controlCenterArea.containsMouse || (controlCenterLoader.item && controlCenterLoader.item.visible))) ? 0.16 : 0.0
    Behavior on opacity {
      NumberAnimation { duration: 150 }
    }
  }

  MouseArea {
    id: controlCenterArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (!controlCenterLoader.active) {
        controlCenterLoader.active = true;
      } else if (controlCenterLoader.item) {
        controlCenterLoader.item.visible = !controlCenterLoader.item.visible;
      }
    }
  }

  Loader {
    id: controlCenterLoader
    active: false
    sourceComponent: Component {
      ControlCenter {
        theme: hostRoot.theme
        font: hostRoot.font
        anchorTarget: controlCenterButton
        barPosition: hostContainer.barPos
        barThickness: hostScope.barThickness
        barFloating: hostScope.isFloating
        barWindowWidth: hostWindow.width
        barWindowHeight: hostWindow.height
        Component.onCompleted: visible = true
      }
    }
  }
}
