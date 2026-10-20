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
  id: trayWidget
  implicitHeight: hostContainer.isVert ? Math.max(28, trayGrid.implicitHeight + 10) : 24
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : Math.max(24, trayGrid.implicitWidth + 8)
  height: implicitHeight
  width: implicitWidth
  radius: hostContainer.pillRadius
  Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  color: hostContainer.wBg("tray", trayHover.hovered)
  border.color: hostContainer.wBorder("tray")
  border.width: hostContainer.hasCustomColor("tray") ? 1 : 0
  Behavior on color { ColorAnimation { duration: 150 } }

  HoverHandler { id: trayHover }

  PillIndicator {
    hostRoot: trayWidget.hostRoot
    hostContainer: trayWidget.hostContainer
    active: false
    hovered: trayHover.hovered
    accentColor: hostContainer.wAccent("tray", hostRoot.theme.accentPrimary)
  }

  Grid {
    id: trayGrid
    anchors.centerIn: parent
    columns: hostContainer.isVert ? 1 : Math.max(1, trayRepeater.count)
    spacing: 2

    Repeater {
      id: trayRepeater
      model: SystemTray.items

      MouseArea {
        id: trayDelegate
        required property SystemTrayItem modelData

        Accessible.role: Accessible.Button
        Accessible.name: modelData.tooltipTitle || modelData.title || "System tray item"

        width: 24
        height: hostContainer.isVert ? 24 : Math.max(24, hostContainer.height)

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: (mouse) => {
          if (mouse.button === Qt.LeftButton) {
            modelData.activate()
          } else if (mouse.button === Qt.RightButton) {
            if (modelData.hasMenu) {
              menuAnchor.open()
            }
          } else if (mouse.button === Qt.MiddleButton) {
            modelData.secondaryActivate()
          }
        }

        IconImage {
          anchors.centerIn: parent
          source: trayDelegate.modelData.icon
          implicitSize: 16
        }

        QsMenuAnchor {
          id: menuAnchor
          menu: trayDelegate.modelData.menu

          anchor.window: trayDelegate.QsWindow.window
          anchor.adjustment: PopupAdjustment.Flip
          anchor.onAnchoring: {
            const window = trayDelegate.QsWindow.window;
            if (!window) return;
            const widgetRect = window.contentItem.mapFromItem(
              trayDelegate, 0, trayDelegate.height,
              trayDelegate.width, trayDelegate.height);
            menuAnchor.anchor.rect = widgetRect;
          }
        }
      }
    }
  }
}
