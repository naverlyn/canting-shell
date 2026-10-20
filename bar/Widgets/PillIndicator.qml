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

Item {
    required property var hostRoot
    required property var hostContainer
  id: indRoot
  anchors.fill: parent
  property bool active: false
  property bool hovered: false
  property color accentColor: hostRoot.theme.accentPrimary

  // Active indicator underline (horizontal bar)
  Rectangle {
    visible: (hostContainer.activeStyle === "underline" || hostContainer.activeStyle === "both") && !hostContainer.isVert
    anchors.bottom: parent.bottom
    anchors.bottomMargin: hostContainer.hidePill ? 2 : 1
    anchors.horizontalCenter: parent.horizontalCenter
    width: (indRoot.active || indRoot.hovered) ? Math.max(8, parent.width - 8) : 0
    height: 2
    radius: 1
    color: indRoot.active ? indRoot.accentColor : hostRoot.theme.textMuted
    opacity: indRoot.active ? 1.0 : (indRoot.hovered ? 0.9 : 0.0)
    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 150 } }
    Behavior on color { ColorAnimation { duration: 150 } }
  }

  // Active indicator vertical bar line (vertical bar)
  Rectangle {
    visible: (hostContainer.activeStyle === "underline" || hostContainer.activeStyle === "both") && hostContainer.isVert
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: hostContainer.barPos === "right" ? parent.left : undefined
    anchors.right: hostContainer.barPos === "left" ? parent.right : undefined
    anchors.leftMargin: 1
    anchors.rightMargin: 1
    width: 2
    height: (indRoot.active || indRoot.hovered) ? Math.max(8, parent.height - 8) : 0
    radius: 1
    color: indRoot.active ? indRoot.accentColor : hostRoot.theme.textMuted
    opacity: indRoot.active ? 1.0 : (indRoot.hovered ? 0.9 : 0.0)
    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 150 } }
    Behavior on color { ColorAnimation { duration: 150 } }
  }
}
