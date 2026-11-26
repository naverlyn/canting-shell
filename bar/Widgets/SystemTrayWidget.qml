import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Services.SystemTray
import "../Components"
import ".."

Rectangle {
  required property var hostRoot
  required property var hostContainer
  id: trayWidget
  implicitHeight: hostContainer.isVert ? Math.max(hostContainer.scaled(28), trayGrid.implicitHeight + 10) : (hostContainer.hidePill ? hostContainer.height : hostContainer.horizPillHeight)
  implicitWidth: hostContainer.isVert ? hostContainer.vertPillWidth : Math.max(hostContainer.horizPillHeight, trayGrid.implicitWidth + 8)
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

        width: hostContainer.scaled(24)
        height: hostContainer.isVert ? hostContainer.scaled(24) : Math.max(hostContainer.horizPillHeight, hostContainer.height)

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
          implicitSize: hostContainer.scaled(16)
        }

        QsMenuAnchor {
          id: menuAnchor
          menu: trayDelegate.modelData.menu

          anchor.window: trayDelegate.QsWindow.window
          // Open away from the bar edge so the menu never runs off-screen.
          anchor.edges: {
            switch (hostContainer.barPos) {
              case "bottom": return Edges.Top | Edges.Left;
              case "left": return Edges.Right | Edges.Top;
              case "right": return Edges.Left | Edges.Top;
              default: return Edges.Bottom | Edges.Left;
            }
          }
          anchor.gravity: {
            switch (hostContainer.barPos) {
              case "bottom": return Edges.Top | Edges.Right;
              case "left": return Edges.Right | Edges.Bottom;
              case "right": return Edges.Left | Edges.Bottom;
              default: return Edges.Bottom | Edges.Right;
            }
          }
          anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
          anchor.onAnchoring: {
            const window = trayDelegate.QsWindow.window;
            if (!window) return;
            menuAnchor.anchor.rect = window.contentItem.mapFromItem(
              trayDelegate, 0, 0, trayDelegate.width, trayDelegate.height);
          }
        }
      }
    }
  }
}
